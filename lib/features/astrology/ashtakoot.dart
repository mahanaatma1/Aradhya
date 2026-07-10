import 'astro_chart.dart';

/// Ashtakoot Guna Milan — the classical 36-point Vedic compatibility test.
/// Pure rule logic computed from each person's Moon (rashi + nakshatra) plus a
/// Manglik (Mangal Dosha) comparison from the full charts. Readings live in
/// milan_interpretations.dart (our own text).

// ---- Reference tables ----

// Varna rank by moon rashi (1 = Shudra .. 4 = Brahmin). 0 = Aries.
const _varnaByRashi = [3, 2, 1, 4, 3, 2, 1, 4, 3, 2, 1, 4];

// Vashya category by rashi: 0 Nara, 1 Vanchar, 2 Chatushpad, 3 Jalachar, 4 Keet.
const _vashyaCat = [2, 2, 0, 3, 1, 0, 0, 4, 0, 3, 0, 3];
// Vashya points [boyCat][girlCat], max 2.
const _vashyaMatrix = [
  [2.0, 0.5, 1.0, 1.0, 1.0], // Nara
  [1.0, 2.0, 0.0, 1.0, 1.0], // Vanchar
  [1.0, 0.0, 2.0, 1.0, 1.0], // Chatushpad
  [1.0, 1.0, 1.0, 2.0, 0.0], // Jalachar
  [1.0, 1.0, 1.0, 0.0, 2.0], // Keet
];

// Yoni animal by nakshatra (0..26). Animal index 0..13.
const _yoniByNak = [
  0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9,
  8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1
];
// Enemy yoni pairs (0 points).
const _yoniEnemies = {
  '7-9', '9-7', // Cow / Tiger
  '0-8', '8-0', // Horse / Buffalo
  '1-13', '13-1', // Elephant / Lion
  '4-10', '10-4', // Dog / Deer
  '3-12', '12-3', // Serpent / Mongoose
  '11-2', '2-11', // Monkey / Sheep
  '5-6', '6-5', // Cat / Rat
};

// Gana by nakshatra: 0 Deva, 1 Manushya, 2 Rakshasa.
const _ganaByNak = [
  0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2,
  0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0
];
// Gana points [ganaA][ganaB], symmetric, max 6.
const _ganaMatrix = [
  [6.0, 6.0, 1.0], // Deva
  [6.0, 6.0, 0.0], // Manushya
  [1.0, 0.0, 6.0], // Rakshasa
];

// Nadi by nakshatra: 0 Aadi (Vata), 1 Madhya (Pitta), 2 Antya (Kapha).
const _nadiByNak = [
  0, 1, 2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1,
  2, 2, 1, 0, 0, 1, 2, 2, 1, 0, 0, 1, 2
];

// Lord of each rashi.
const _signLord = [
  'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
  'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'
];
const _friends = {
  'sun': {'moon', 'mars', 'jupiter'},
  'moon': {'sun', 'mercury'},
  'mars': {'sun', 'moon', 'jupiter'},
  'mercury': {'sun', 'venus'},
  'jupiter': {'sun', 'moon', 'mars'},
  'venus': {'mercury', 'saturn'},
  'saturn': {'mercury', 'venus'},
};
const _enemies = {
  'sun': {'venus', 'saturn'},
  'moon': <String>{},
  'mars': {'mercury'},
  'mercury': {'moon'},
  'jupiter': {'mercury', 'venus'},
  'venus': {'sun', 'moon'},
  'saturn': {'sun', 'moon', 'mars'},
};
// Graha Maitri points [relAtoB][relBtoA]; rel 0 friend, 1 neutral, 2 enemy.
const _gmMatrix = [
  [5.0, 4.0, 0.5],
  [4.0, 3.0, 1.0],
  [0.5, 1.0, 0.0],
];

// ---- Result model ----

class KootScore {
  final String key; // 'varna' ..
  final String name; // 'Varna'
  final double got;
  final double max;
  const KootScore(this.key, this.name, this.got, this.max);
}

class PersonMilan {
  final String name;
  final int rashi; // moon sign 0..11
  final int nakshatra; // 0..26
  final int nakPada; // 1..4
  final int yoni; // 0..13
  final int varnaRank; // 1..4
  final int gana; // 0..2
  final int nadi; // 0..2
  final bool manglik;
  const PersonMilan({
    required this.name,
    required this.rashi,
    required this.nakshatra,
    required this.nakPada,
    required this.yoni,
    required this.varnaRank,
    required this.gana,
    required this.nadi,
    required this.manglik,
  });
}

class MilanResult {
  final PersonMilan a;
  final PersonMilan b;
  final List<KootScore> koots;
  final double total; // out of 36
  const MilanResult(this.a, this.b, this.koots, this.total);

  bool get manglikMismatch => a.manglik != b.manglik;
  KootScore koot(String key) => koots.firstWhere((k) => k.key == key);
}

// ---- Computation ----

int _rel(String from, String to) {
  if (_friends[from]!.contains(to)) return 0;
  if (_enemies[from]!.contains(to)) return 2;
  return 1;
}

bool _isManglik(BirthChart c) {
  const houses = {1, 2, 4, 7, 8, 12};
  final mars = c.byKey('mars');
  final moon = c.byKey('moon');
  final fromLagna = mars.house;
  final fromMoon = ((mars.graha.rashi - moon.graha.rashi) % 12 + 12) % 12 + 1;
  return houses.contains(fromLagna) || houses.contains(fromMoon);
}

double _varna(int boyRank, int girlRank) => boyRank >= girlRank ? 1.0 : 0.0;

double _vashya(int boyRashi, int girlRashi) =>
    _vashyaMatrix[_vashyaCat[boyRashi]][_vashyaCat[girlRashi]];

double _taraOne(int fromNak, int toNak) {
  final count = ((toNak - fromNak + 27) % 27) + 1;
  final rem = count % 9;
  // Vipat (3), Pratyari (5), Naidhana (7) are inauspicious.
  final bad = rem == 3 || rem == 5 || rem == 7;
  return bad ? 0.0 : 1.5;
}

double _yoni(int nakA, int nakB) {
  final ya = _yoniByNak[nakA], yb = _yoniByNak[nakB];
  if (ya == yb) return 4.0;
  if (_yoniEnemies.contains('$ya-$yb')) return 0.0;
  return 2.0;
}

double _grahaMaitri(int rashiA, int rashiB) {
  final la = _signLord[rashiA], lb = _signLord[rashiB];
  if (la == lb) return 5.0;
  return _gmMatrix[_rel(la, lb)][_rel(lb, la)];
}

double _gana(int ganaA, int ganaB) => _ganaMatrix[ganaA][ganaB];

double _bhakoot(int rashiA, int rashiB) {
  final d = (rashiB - rashiA + 12) % 12;
  // 2/12 (d 1,11), 6/8 (d 5,7), 5/9 (d 4,8) → dosha.
  const dosha = {1, 11, 5, 7, 4, 8};
  return dosha.contains(d) ? 0.0 : 7.0;
}

double _nadi(int nakA, int nakB) => _nadiByNak[nakA] == _nadiByNak[nakB] ? 0.0 : 8.0;

PersonMilan _person(String name, BirthChart c) {
  final moon = c.byKey('moon').graha;
  return PersonMilan(
    name: name,
    rashi: moon.rashi,
    nakshatra: moon.nakshatra,
    nakPada: moon.nakPada,
    yoni: _yoniByNak[moon.nakshatra],
    varnaRank: _varnaByRashi[moon.rashi],
    gana: _ganaByNak[moon.nakshatra],
    nadi: _nadiByNak[moon.nakshatra],
    manglik: _isManglik(c),
  );
}

/// Full Ashtakoot match. Side A is treated as the groom for the (mildly
/// direction-sensitive) Varna and Tara koots.
MilanResult computeMilan(
    String nameA, BirthChart chartA, String nameB, BirthChart chartB) {
  final a = _person(nameA, chartA);
  final b = _person(nameB, chartB);

  final koots = <KootScore>[
    KootScore('varna', 'Varna', _varna(a.varnaRank, b.varnaRank), 1),
    KootScore('vashya', 'Vashya', _vashya(a.rashi, b.rashi), 2),
    KootScore('tara', 'Tara',
        _taraOne(a.nakshatra, b.nakshatra) + _taraOne(b.nakshatra, a.nakshatra), 3),
    KootScore('yoni', 'Yoni', _yoni(a.nakshatra, b.nakshatra), 4),
    KootScore('maitri', 'Graha Maitri', _grahaMaitri(a.rashi, b.rashi), 5),
    KootScore('gana', 'Gana', _gana(a.gana, b.gana), 6),
    KootScore('bhakoot', 'Bhakoot', _bhakoot(a.rashi, b.rashi), 7),
    KootScore('nadi', 'Nadi', _nadi(a.nakshatra, b.nakshatra), 8),
  ];
  final total = koots.fold<double>(0, (s, k) => s + k.got);
  return MilanResult(a, b, koots, total);
}
