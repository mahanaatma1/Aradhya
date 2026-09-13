import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/router/app_router.dart';
import '../../core/db/content_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';

/// Launch: the lotus blooms over a festival night sky while the content
/// database is readied. Doubles as the shader warm-up and the frame-time
/// benchmark that refines the device tier. Routes on when both the bloom
/// and the database are done; a full phone gets a storage screen instead.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bloom = Duration(milliseconds: 2580);
  static const _hold = Duration(milliseconds: 3200);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _bloom)..forward();
  final _frames = <Duration>[];
  TimingsCallback? _timings;
  bool _held = false;
  bool _navigated = false;
  double? _copyProgress;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    unawaited(ShaderLibrary.warmUp());
    _timings = (timings) {
      for (final t in timings) {
        _frames.add(t.totalSpan);
      }
    };
    SchedulerBinding.instance.addTimingsCallback(_timings!);
    _progressSub = ContentDatabase.progress.listen((v) {
      if (mounted) setState(() => _copyProgress = v >= 1 ? null : v);
    });
    Future.delayed(_hold, () {
      if (!mounted) return;
      _held = true;
      _finishBenchmark();
      _maybeGo();
    });
  }

  void _finishBenchmark() {
    final cb = _timings;
    if (cb == null) return;
    SchedulerBinding.instance.removeTimingsCallback(cb);
    _timings = null;
    // Ignore the first frames (shader compile, image decode) and read p95.
    final samples = _frames.skip(20).toList()..sort();
    if (samples.length < 30) return;
    final p95 = samples[(samples.length * 0.95).floor()];
    unawaited(ref.read(perfTierProvider.notifier).refineFromFrames(p95));
  }

  void _maybeGo() {
    if (_navigated || !_held) return;
    final db = ref.read(contentDbProvider);
    if (!db.hasValue) return;
    _navigated = true;
    context.go(gOnboarded ? '/' : '/onboarding');
  }

  @override
  void dispose() {
    final cb = _timings;
    if (cb != null) SchedulerBinding.instance.removeTimingsCallback(cb);
    _progressSub?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final c = context.colors;
    final db = ref.watch(contentDbProvider);
    ref.listen(contentDbProvider, (_, next) {
      if (next.hasValue) _maybeGo();
    });

    final storageError = db.error is InsufficientStorageException
        ? db.error as InsufficientStorageException
        : null;

    return Scaffold(
      backgroundColor: c.canvasDeep,
      body: ShaderSurface(
        id: ShaderId.utsavSky,
        colors: ColorTokens.dark.skyGradient,
        params: const [0.35],
        fallback: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ColorTokens.dark.skyGradient,
            ),
          ),
        ),
        child: ParticleField(
          emitters: [
            Emitters.stars(color: ColorTokens.dark.inkOnDeep),
            Emitters.petals(rate: 3, color: ColorTokens.dark.gold),
          ],
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final v = _c.value;
                      final logoFade =
                          Curves.easeOut.transform((v / 0.25).clamp(0.0, 1.0));
                      final tileScale =
                          0.9 + 0.1 * Curves.easeOutCubic.transform(v);
                      final textT = ((v - 0.5) / 0.45).clamp(0.0, 1.0);
                      final textFade = Curves.easeOut.transform(textT);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: logoFade,
                            child: Transform.scale(
                              scale: tileScale,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: ElevationTokens.dark.glow,
                                ),
                                child: AppLogo(size: 124, bloom: v),
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.x8),
                          Opacity(
                            opacity: textFade,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - textFade)),
                              child: Column(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: hi
                                            ? AppFonts.devanagari
                                            : AppFonts.display,
                                        fontFamilyFallback: AppFonts.fallback,
                                        fontSize: 42,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: ColorTokens.dark.inkOnDeep,
                                      ),
                                      children: hi
                                          ? [TextSpan(text: Brand.nameHi)]
                                          : [
                                              TextSpan(text: Brand.nameHead),
                                              TextSpan(
                                                  text: Brand.nameTail,
                                                  style: TextStyle(
                                                      color: ColorTokens
                                                          .dark.gold)),
                                            ],
                                    ),
                                  ),
                                  const SizedBox(height: Space.x2),
                                  ScriptText(
                                    hi ? Brand.taglineHi : Brand.taglineEn,
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 16,
                                      color: ColorTokens.dark.inkOnDeep
                                          .withValues(alpha: .8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: Space.x8,
                  child: Center(
                    child: storageError != null
                        ? _StorageNotice(
                            error: storageError,
                            hi: hi,
                            onRetry: () => ref.invalidate(contentDbProvider),
                          )
                        : AnimatedOpacity(
                            duration: Motion.slow,
                            opacity: _copyProgress != null || (_held && !db.hasValue)
                                ? 1
                                : 0,
                            child: _Preparing(
                                progress: _copyProgress ?? 0, hi: hi),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({required this.progress, required this.hi});
  final double progress;
  final bool hi;

  @override
  Widget build(BuildContext context) {
    final ink = ColorTokens.dark.inkOnDeep;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          value: progress,
          size: 44,
          stroke: 4,
          color: ColorTokens.dark.gold,
          track: ink.withValues(alpha: .2),
          child: Text('${(progress * 100).round()}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: ink)),
        ),
        const SizedBox(height: Space.x2),
        ScriptText(
          hi ? 'आपकी लाइब्रेरी तैयार हो रही है…' : 'Preparing your library…',
          style: TextStyle(fontSize: 13, color: ink.withValues(alpha: .8)),
        ),
      ],
    );
  }
}

class _StorageNotice extends StatelessWidget {
  const _StorageNotice(
      {required this.error, required this.hi, required this.onRetry});
  final InsufficientStorageException error;
  final bool hi;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mb = error.shortfallMb;
    return Padding(
      padding: Insets.page,
      child: NoticeBanner(
        kind: NoticeKind.warning,
        text: hi
            ? 'पर्याप्त जगह नहीं है। लगभग $mb MB खाली करें और फिर कोशिश करें।'
            : 'Not enough storage. Free about $mb MB and try again.',
        action: GhostButton(
            label: hi ? 'फिर कोशिश करें' : 'Retry', onPressed: onRetry),
      ),
    );
  }
}
