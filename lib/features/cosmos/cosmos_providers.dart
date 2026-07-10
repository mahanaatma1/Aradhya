import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/user/user_prefs.dart';
import '../astrology/astro_planets.dart';
import '../astrology/astrology_providers.dart';
import '../astrology/soul_profile.dart';
import '../astrology/yogas_doshas.dart';
import '../panchang/panchang_engine.dart';
import '../panchang/panchang_providers.dart';
import 'daily_cosmos.dart';

/// Today's transit Moon rashi (0..11) — drives the classic 12-sign horoscope
/// (needs no birth details).
final transitMoonRashiProvider = Provider<int>((ref) {
  final grahas = computeGrahas(DateTime.now().toUtc());
  return grahas.firstWhere((g) => g.key == 'moon').rashi;
});

/// The moon-sign the user reads the 12-Rashi horoscope for (persisted).
/// Defaults to their own Moon sign if they have a chart, else Aries.
final selectedRashiProvider = StateProvider<int>((ref) {
  final saved = ref.read(sharedPrefsProvider).getInt(PrefKeys.rashi);
  if (saved != null) return saved;
  return ref.read(chartProvider)?.byKey('moon').graha.rashi ?? 0;
});

/// Today's personalized reading, or null when the user has no birth chart yet.
/// Recomputes from live transits + today's panchang (at the user's current
/// location) whenever the chart/location changes — so it stays "today".
final cosmosProvider = Provider<DailyCosmos?>((ref) {
  final chart = ref.watch(chartProvider);
  final birth = ref.watch(birthDetailsProvider);
  if (chart == null || birth == null) return null;

  final loc = ref.watch(effectiveLocationProvider);
  final amanta = ref.watch(amantaSystemProvider);
  final now = DateTime.now();

  // Today's panchang for the user's CURRENT location (independent of the date
  // the Panchang screen may be browsing).
  final panchang = computePanchang(
    date: now,
    lat: loc.lat,
    lonEast: loc.lon,
    tzOffset: now.timeZoneOffset,
    amanta: amanta,
  );

  final transits = computeGrahas(now.toUtc());
  final soul = computeSoulProfile(chart, birth);
  final doshas = detectDoshas(chart, nowUtc: now.toUtc());

  return buildDailyCosmos(
    chart: chart,
    birth: birth,
    transits: transits,
    panchang: panchang,
    soul: soul,
    doshas: doshas,
    now: now,
  );
});
