import '../astrology/astro_chart.dart';
import '../astrology/astro_planets.dart';
import '../astrology/astrology_providers.dart' show BirthDetails;
import '../astrology/soul_profile.dart';
import '../astrology/vimshottari.dart';
import '../astrology/yogas_doshas.dart';
import '../panchang/panchang_engine.dart';

/// Overall tone of the day.
enum Verdict { favourable, mixed, challenging }

/// A fully-derived personalized daily reading. Built by the pure
/// [buildDailyCosmos] so it can be unit-tested without Flutter/providers.
class DailyCosmos {
  final Verdict verdict;
  final int score;

  final String mahaLord;
  final String antarLord;
  final DateTime antarEnd;

  /// Moon's transit house from the natal Moon (1..12) — Chandra gochar.
  final int gocharHouse;

  final List<Muhurat> favHours;
  final List<Muhurat> trickyHours;

  /// Sade Sati phase ('rising' | 'peak' | 'setting'), or null when inactive.
  final String? sadeSati;

  /// The chart's ruling planet (key for lucky colour/direction lookup).
  final String rulingPlanet;
  final int luckyNumber;
  final String luckyMantra;

  const DailyCosmos({
    required this.verdict,
    required this.score,
    required this.mahaLord,
    required this.antarLord,
    required this.antarEnd,
    required this.gocharHouse,
    required this.favHours,
    required this.trickyHours,
    required this.sadeSati,
    required this.rulingPlanet,
    required this.luckyNumber,
    required this.luckyMantra,
  });
}

const _weekdaysEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _benefics = {'jupiter', 'venus', 'mercury', 'moon'};
// Chandra-gochar houses (from the Moon) considered favourable.
const _goodGocharHouses = {1, 3, 6, 7, 10, 11};
// Tarabala groups (0=Janma..8): good = Sampat/Kshema/Sadhaka/Mitra/AtiMitra.
const _goodTara = {1, 3, 5, 7, 8};
const _badTara = {2, 4, 6}; // Vipat/Pratyak/Vadha

/// Build the day's reading from the natal chart, live transits, today's
/// panchang, the soul profile and detected doshas. Pure & deterministic in
/// [now] (used for dasha + weekday). No Flutter imports.
DailyCosmos buildDailyCosmos({
  required BirthChart chart,
  required BirthDetails birth,
  required List<Graha> transits,
  required Panchang panchang,
  required SoulProfile soul,
  required List<DetectedDosha> doshas,
  required DateTime now,
}) {
  final natalMoon = chart.byKey('moon').graha;
  final tMoon = transits.firstWhere((g) => g.key == 'moon');

  final gocharHouse = ((tMoon.rashi - natalMoon.rashi + 12) % 12) + 1;
  final tara = (((tMoon.nakshatra - natalMoon.nakshatra) % 27 + 27) % 27) % 9;

  final cd = currentDasha(birth.utc, natalMoon.sidereal, now);

  String? sadeSati;
  for (final d in doshas) {
    if (d.type == 'sadesati') {
      sadeSati = d.severity;
      break;
    }
  }

  // ---- Day verdict score ----
  var score = 0;
  score += _goodGocharHouses.contains(gocharHouse) ? 2 : -2;
  if (_goodTara.contains(tara)) {
    score += 2;
  } else if (_badTara.contains(tara)) {
    score -= 2;
  }
  if (sadeSati != null) score += (sadeSati == 'peak') ? -3 : -2;
  if (soul.luckyDay
      .toLowerCase()
      .contains(_weekdaysEn[now.weekday - 1].toLowerCase())) {
    score += 1;
  }
  score += _benefics.contains(cd.maha.lord) ? 1 : -1;

  final verdict = score >= 3
      ? Verdict.favourable
      : (score <= -3 ? Verdict.challenging : Verdict.mixed);

  final fav = <Muhurat>[];
  final tricky = <Muhurat>[];
  for (final m in panchang.muhurats) {
    (m.auspicious ? fav : tricky).add(m);
  }

  final mantra = soul.luckMantra.isNotEmpty ? soul.luckMantra : soul.ishtaMantra;

  return DailyCosmos(
    verdict: verdict,
    score: score,
    mahaLord: cd.maha.lord,
    antarLord: cd.antar.lord,
    antarEnd: cd.antar.end,
    gocharHouse: gocharHouse,
    favHours: fav,
    trickyHours: tricky,
    sadeSati: sadeSati,
    rulingPlanet: soul.rulingPlanet,
    luckyNumber: soul.luckyNumbers.isEmpty ? 1 : soul.luckyNumbers.first,
    luckyMantra: mantra,
  );
}

/// Chandra-gochar house (1..12) of the transit Moon from a given rashi (0..11)
/// — the basis of the classic 12-sign daily horoscope.
int gocharHouseFrom(int rashi, int transitMoonRashi) =>
    ((transitMoonRashi - rashi + 12) % 12) + 1;

/// A rashi's daily rating from the Moon's gochar house (traditional Chandra
/// gochar): 1/3/6/7/10/11 favour, 4/8/12 challenge, the rest are mixed.
Verdict rashiVerdict(int gocharHouse) {
  const good = {1, 3, 6, 7, 10, 11};
  const tough = {4, 8, 12};
  return good.contains(gocharHouse)
      ? Verdict.favourable
      : (tough.contains(gocharHouse) ? Verdict.challenging : Verdict.mixed);
}

/// A 1..5 star rating for a rashi from the Moon's gochar house.
int rashiScore(int gocharHouse) {
  const map = {
    10: 5, 11: 5, 1: 4, 3: 4, 6: 4, 7: 4,
    2: 3, 5: 3, 9: 3, 4: 2, 12: 2, 8: 1,
  };
  return map[gocharHouse] ?? 3;
}

/// Ruling planet of each rashi (0=Aries..11=Pisces) — drives lucky colour.
const rashiLords = [
  'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
  'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'
];

/// A lucky number for each rashi (from its lord's traditional number).
const rashiLuckyNumber = [9, 6, 5, 2, 1, 5, 6, 9, 3, 8, 8, 3];

/// Deterministically pick a variant index in `0..count-1` for a rashi's aspect
/// line on a given day. Seeded by the day + rashi + aspect so neighbouring
/// signs read differently and the text rotates day to day, while staying fully
/// reproducible (no RNG — `Math.random` would break offline determinism/tests).
int dailyVariant(int rashi, int aspect, DateTime day, int count) {
  if (count <= 1) return 0;
  final doy = day.difference(DateTime(day.year, 1, 1)).inDays; // 0..365
  var h = day.year * 1000 + doy;
  h = h * 131 + rashi;
  h = h * 131 + aspect;
  return (h % count + count) % count;
}

/// The next day (within 30) whose transit Moon sits in a favourable house AND
/// a good Tara from the natal Moon — the Kamal-gated "auspicious day" reveal.
DateTime? nextFavourableDay(BirthChart chart, DateTime from) {
  final natalMoon = chart.byKey('moon').graha;
  for (var i = 1; i <= 30; i++) {
    final day = DateTime(from.year, from.month, from.day)
        .add(Duration(days: i));
    final t = computeGrahas(DateTime(day.year, day.month, day.day, 12).toUtc());
    final tMoon = t.firstWhere((g) => g.key == 'moon');
    final house = ((tMoon.rashi - natalMoon.rashi + 12) % 12) + 1;
    final tara =
        (((tMoon.nakshatra - natalMoon.nakshatra) % 27 + 27) % 27) % 9;
    if (_goodGocharHouses.contains(house) && _goodTara.contains(tara)) {
      return day;
    }
  }
  return null;
}
