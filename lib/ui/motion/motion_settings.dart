import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/platform/platform_bridge.dart';
import '../../core/user/user_prefs.dart';

/// The user's motion preference (Profile → Motion).
enum MotionLevel { full, reduced, off }

/// Runtime device class. Decides particle counts, shaders, parallax, blur.
enum PerfTier { low, mid, high }

/// Everything a motion primitive needs to know, resolved once per frame tree
/// by [MotionScope] from system reduced-motion ∪ user level ∪ device tier.
@immutable
class MotionSettings {
  final bool reduce;
  final MotionLevel level;
  final PerfTier tier;
  final bool particles;
  final bool shaders;
  final bool parallax;
  final bool tilt;
  final bool blur;
  final bool ambient;
  final int maxParticles;
  final double durationScale;
  final int ambientFps;

  const MotionSettings({
    required this.reduce,
    required this.level,
    required this.tier,
    required this.particles,
    required this.shaders,
    required this.parallax,
    required this.tilt,
    required this.blur,
    required this.ambient,
    required this.maxParticles,
    required this.durationScale,
    required this.ambientFps,
  });

  static MotionSettings resolve({
    required bool systemReduce,
    required MotionLevel level,
    required PerfTier tier,
  }) {
    final off = systemReduce || level == MotionLevel.off;
    final reduced = level == MotionLevel.reduced;
    if (off) {
      return MotionSettings(
        reduce: true,
        level: MotionLevel.off,
        tier: tier,
        particles: false,
        shaders: false,
        parallax: false,
        tilt: false,
        blur: false,
        ambient: false,
        maxParticles: 0,
        durationScale: 0.6,
        ambientFps: 0,
      );
    }
    final high = tier == PerfTier.high, low = tier == PerfTier.low;
    return MotionSettings(
      reduce: false,
      level: level,
      tier: tier,
      particles: !reduced,
      shaders: !reduced && !low,
      parallax: !reduced && !low,
      tilt: !reduced && high,
      blur: !reduced && high,
      ambient: !reduced,
      maxParticles: reduced ? 0 : (high ? 400 : (low ? 40 : 200)),
      durationScale: 1.0,
      ambientFps: reduced ? 0 : (high ? 60 : (low ? 4 : 30)),
    );
  }

  /// Everything on: the default for widget tests and previews.
  static const full = MotionSettings(
    reduce: false,
    level: MotionLevel.full,
    tier: PerfTier.high,
    particles: true,
    shaders: true,
    parallax: true,
    tilt: true,
    blur: true,
    ambient: true,
    maxParticles: 400,
    durationScale: 1.0,
    ambientFps: 60,
  );

  Duration scale(Duration d) => reduce
      ? Duration(milliseconds: (d.inMilliseconds * durationScale).round())
      : d;

  @override
  bool operator ==(Object other) =>
      other is MotionSettings &&
      other.reduce == reduce &&
      other.level == level &&
      other.tier == tier &&
      other.maxParticles == maxParticles;

  @override
  int get hashCode => Object.hash(reduce, level, tier, maxParticles);
}

class MotionLevelController extends StateNotifier<MotionLevel> {
  MotionLevelController(this._prefs) : super(_read(_prefs));
  final SharedPreferences _prefs;
  static const _key = PrefKeys.motionLevel;

  static MotionLevel _read(SharedPreferences p) => switch (p.getString(_key)) {
        'reduced' => MotionLevel.reduced,
        'off' => MotionLevel.off,
        _ => MotionLevel.full,
      };

  Future<void> set(MotionLevel level) async {
    state = level;
    await _prefs.setString(_key, level.name);
  }
}

final motionLevelProvider =
    StateNotifierProvider<MotionLevelController, MotionLevel>(
        (ref) => MotionLevelController(ref.watch(sharedPrefsProvider)));

/// Device tier: static signals first, refined once by the splash benchmark
/// and persisted per build so we only re-measure after an update.
class PerfTierController extends StateNotifier<PerfTier> {
  PerfTierController(this._prefs) : super(_read(_prefs)) {
    if (_prefs.getString(_keyBuild) != _build) _detect();
  }

  final SharedPreferences _prefs;
  static const _key = PrefKeys.perfTier;
  static const _keyBuild = PrefKeys.perfTierBuild;
  static const _build = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');

  static PerfTier _read(SharedPreferences p) => switch (p.getString(_key)) {
        'low' => PerfTier.low,
        'high' => PerfTier.high,
        _ => PerfTier.mid,
      };

  Future<void> _detect() async {
    final info = await PlatformBridge.deviceInfo();
    if (info == null) return;
    await set(classify(info));
  }

  static PerfTier classify(DeviceInfo d) {
    if (d.isLowRamDevice || d.totalGb < 3 || d.cores <= 4 || d.sdkInt < 26) {
      return PerfTier.low;
    }
    if (d.totalGb >= 6 && d.cores >= 8 && d.sdkInt >= 31) return PerfTier.high;
    return PerfTier.mid;
  }

  Future<void> set(PerfTier tier) async {
    state = tier;
    await _prefs.setString(_key, tier.name);
    await _prefs.setString(_keyBuild, _build);
  }

  /// Called by the splash benchmark with the p95 frame time it observed.
  Future<void> refineFromFrames(Duration p95) async {
    if (p95 > const Duration(milliseconds: 24) && state != PerfTier.low) {
      await set(PerfTier.values[state.index - 1]);
    } else if (p95 < const Duration(milliseconds: 10) &&
        state == PerfTier.mid) {
      await set(PerfTier.high);
    }
  }
}

final perfTierProvider = StateNotifierProvider<PerfTierController, PerfTier>(
    (ref) => PerfTierController(ref.watch(sharedPrefsProvider)));