import 'astro_chart.dart';
import 'astro_planets.dart';

/// Classical yoga & dosha detection from a birth chart. Pure rule logic; the
/// human-readable readings live in interpretations.dart (our own text).

// Ruling planet of each sign (0=Aries..11=Pisces).
const _signLord = [
  'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
  'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'
];

class DetectedYoga {
  final String type;
  final int house;
  final List<String> planets;
  const DetectedYoga(this.type, this.house, this.planets);
}

class DetectedDosha {
  final String type;
  final String severity; // '', 'low', 'medium', 'high', 'rising'/'peak'/'setting'
  final List<String> softening;
  const DetectedDosha(this.type, {this.severity = '', this.softening = const []});
}

int _houseSign(BirthChart c, int house) => (c.lagnaRashi + house - 1) % 12;
String _houseLord(BirthChart c, int house) => _signLord[_houseSign(c, house)];
bool _kendra(int house) => house == 1 || house == 4 || house == 7 || house == 10;

// Panch Mahapurusha: planet in own/exaltation sign AND in a kendra.
const _mahapurusha = <String, (String, Set<int>)>{
  'mars': ('ruchaka', {0, 7, 9}),
  'mercury': ('bhadra', {2, 5}),
  'jupiter': ('hamsa', {8, 11, 3}),
  'venus': ('malavya', {1, 6, 11}),
  'saturn': ('shasha', {9, 10, 6}),
};
// Debilitation sign of each planet (for Neecha Bhanga).
const _debil = <String, int>{
  'sun': 6, 'moon': 7, 'mars': 3, 'mercury': 11,
  'jupiter': 9, 'venus': 5, 'saturn': 0,
};

List<DetectedYoga> detectYogas(BirthChart chart) {
  final yogas = <DetectedYoga>[];
  final kendraLords = {for (final h in [1, 4, 7, 10]) _houseLord(chart, h)};
  final trikonaLords = {for (final h in [1, 5, 9]) _houseLord(chart, h)};

  final byHouse = <int, List<String>>{};
  for (final p in chart.grahas) {
    if (p.graha.key == 'rahu' || p.graha.key == 'ketu') continue;
    (byHouse[p.house] ??= []).add(p.graha.key);
  }

  // Panch Mahapurusha
  for (final e in _mahapurusha.entries) {
    final p = chart.byKey(e.key);
    if (_kendra(p.house) && e.value.$2.contains(p.graha.rashi)) {
      yogas.add(DetectedYoga(e.value.$1, p.house, [e.key]));
    }
  }

  // Raja Yoga: a kendra lord conjunct a trikona lord.
  byHouse.forEach((house, planets) {
    final k = planets.where(kendraLords.contains).toList();
    final t = planets.where(trikonaLords.contains).toList();
    for (final a in k) {
      for (final b in t) {
        if (a != b) {
          yogas.add(DetectedYoga('raja', house, [a, b]));
          return;
        }
      }
    }
  });

  final moon = chart.byKey('moon'), jup = chart.byKey('jupiter');
  final jupFromMoon = ((jup.graha.rashi - moon.graha.rashi) % 12 + 12) % 12 + 1;
  if ([1, 4, 7, 10].contains(jupFromMoon)) {
    yogas.add(DetectedYoga('gajakesari', jup.house, ['jupiter', 'moon']));
  }
  final sun = chart.byKey('sun'), mer = chart.byKey('mercury');
  if (sun.house == mer.house) {
    yogas.add(DetectedYoga('budhaditya', sun.house, ['sun', 'mercury']));
  }
  final mars = chart.byKey('mars');
  if (moon.house == mars.house) {
    yogas.add(DetectedYoga('chandramangal', moon.house, ['moon', 'mars']));
  }

  // Dhana Yoga: lords of 2 and 11 conjunct or in each other's houses.
  final l2 = _houseLord(chart, 2), l11 = _houseLord(chart, 11);
  if (l2 != l11) {
    final h2 = chart.byKey(l2).house, h11 = chart.byKey(l11).house;
    if (h2 == h11 || h2 == 11 || h11 == 2) {
      yogas.add(DetectedYoga('dhana', h2, [l2, l11]));
    }
  }

  // Vipreet Raja Yoga: a dusthana lord placed in a dusthana.
  for (final h in [6, 8, 12]) {
    final lord = _houseLord(chart, h);
    if ({6, 8, 12}.contains(chart.byKey(lord).house)) {
      yogas.add(DetectedYoga('vipreet', chart.byKey(lord).house, [lord]));
      break;
    }
  }

  // Neecha Bhanga Raja Yoga: a debilitated planet whose dispositor is in a kendra.
  for (final e in _debil.entries) {
    final p = chart.byKey(e.key);
    if (p.graha.rashi == e.value) {
      final dispositor = _signLord[e.value];
      if (_kendra(chart.byKey(dispositor).house)) {
        yogas.add(DetectedYoga('neechabhanga', p.house, [e.key]));
      }
    }
  }

  return yogas;
}

List<DetectedDosha> detectDoshas(BirthChart chart, {DateTime? nowUtc}) {
  final out = <DetectedDosha>[];
  final moon = chart.byKey('moon');
  final sun = chart.byKey('sun');
  final mars = chart.byKey('mars');
  final jup = chart.byKey('jupiter');
  final rahu = chart.byKey('rahu');
  final ketu = chart.byKey('ketu');

  // ---- Mangal Dosha ----
  const manglik = {1, 2, 4, 7, 8, 12};
  final fromLagna = mars.house;
  final fromMoon = ((mars.graha.rashi - moon.graha.rashi) % 12 + 12) % 12 + 1;
  final refs = <String>[];
  if (manglik.contains(fromLagna)) refs.add('lagna');
  if (manglik.contains(fromMoon)) refs.add('moon');
  if (refs.isNotEmpty) {
    final ms = mars.graha.rashi;
    final own = ms == 0 || ms == 7 || ms == 9;
    final soft = <String>[
      if (own) 'Mars is in its own or exaltation sign — the dosha is significantly softened.',
    ];
    final severity = own ? 'low' : (refs.length == 2 ? 'high' : 'medium');
    out.add(DetectedDosha('mangal', severity: severity, softening: soft));
  }

  // ---- Kaal Sarp Dosha: all 7 planets on one side of the Rahu–Ketu axis ----
  final rl = rahu.graha.sidereal;
  bool allBetween = true, allOther = true;
  for (final k in ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn']) {
    final d = (chart.byKey(k).graha.sidereal - rl + 360) % 360;
    if (!(d > 0 && d < 180)) allBetween = false;
    if (!(d > 180 && d < 360)) allOther = false;
  }
  if (allBetween || allOther) out.add(const DetectedDosha('kaalsarp'));

  // ---- Sade Sati: transit Saturn in 12th/1st/2nd from natal Moon ----
  final now = nowUtc ?? DateTime.now().toUtc();
  final satNow = computeGrahas(now).firstWhere((g) => g.key == 'saturn').rashi;
  final diff = (satNow - moon.graha.rashi + 12) % 12;
  if (diff == 11 || diff == 0 || diff == 1) {
    out.add(DetectedDosha('sadesati',
        severity: diff == 11 ? 'rising' : (diff == 0 ? 'peak' : 'setting')));
  }

  // ---- Kemadruma: no planet in 2nd/12th from the Moon ----
  // ...unless cancelled by Kemadruma Bhanga: a planet in a kendra (1/4/7/10)
  // FROM the Moon, or the Moon itself in a kendra from the Lagna. Without this
  // cancellation Kemadruma is heavily over-reported.
  final second = (moon.graha.rashi + 1) % 12;
  final twelfth = (moon.graha.rashi + 11) % 12;
  final around = chart.grahas.any((p) =>
      !['sun', 'moon', 'rahu', 'ketu'].contains(p.graha.key) &&
      (p.graha.rashi == second || p.graha.rashi == twelfth));
  if (!around) {
    final planetInKendraFromMoon = chart.grahas.any((p) {
      if (['moon', 'rahu', 'ketu'].contains(p.graha.key)) return false;
      final fromMoon = (p.graha.rashi - moon.graha.rashi + 12) % 12;
      return fromMoon == 0 || fromMoon == 3 || fromMoon == 6 || fromMoon == 9;
    });
    final bhanga = planetInKendraFromMoon || _kendra(moon.house);
    if (!bhanga) out.add(const DetectedDosha('kemadruma'));
  }

  // ---- Guru Chandal: Jupiter with Rahu or Ketu ----
  if (jup.house == rahu.house || jup.house == ketu.house) {
    out.add(const DetectedDosha('guruchandal'));
  }

  // ---- Shakata: Moon in 6/8/12 from Jupiter ----
  final moonFromJup = (moon.graha.rashi - jup.graha.rashi + 12) % 12;
  if ({5, 7, 11}.contains(moonFromJup)) out.add(const DetectedDosha('shakata'));

  // ---- Pitra: Sun with Rahu/Ketu/Saturn, or a malefic in the 9th ----
  final sat = chart.byKey('saturn');
  final ninth = chart.grahas.any((p) =>
      p.house == 9 && ['rahu', 'ketu', 'saturn'].contains(p.graha.key));
  if (sun.house == rahu.house ||
      sun.house == ketu.house ||
      sun.house == sat.house ||
      ninth) {
    out.add(const DetectedDosha('pitra'));
  }

  return out;
}
