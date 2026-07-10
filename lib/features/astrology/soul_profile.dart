import 'astro_chart.dart';
import 'astrology_providers.dart';

/// Soul Profile computations — Jaimini chara karakas (Atmakaraka, Darakaraka),
/// Karakamsa, Ishta Devata, plus numerology and lucky attributes. All derived
/// from the chart / birth data; descriptions are our own.

// 7 chara-karaka planets (Sun..Saturn).
const _karakaPlanets = [
  'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'
];

const _signLord = [
  'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
  'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'
];

/// Ishta-devata deity for the indicating planet (classical associations).
const ishtaDevataByPlanet = <String, String>{
  'sun': 'Lord Shiva / Rama',
  'moon': 'Lord Krishna / Goddess Parvati',
  'mars': 'Lord Hanuman / Kartikeya',
  'mercury': 'Lord Vishnu',
  'jupiter': 'Lord Vishnu / Dattatreya',
  'venus': 'Goddess Lakshmi',
  'saturn': 'Lord Hanuman / Shani',
  'rahu': 'Goddess Durga',
  'ketu': 'Lord Ganesha',
};

/// Traditional beej mantras (public-domain Sanskrit).
const beejMantraByPlanet = <String, String>{
  'sun': 'ॐ ह्रां ह्रीं ह्रौं सः सूर्याय नमः',
  'moon': 'ॐ श्रां श्रीं श्रौं सः चन्द्राय नमः',
  'mars': 'ॐ क्रां क्रीं क्रौं सः भौमाय नमः',
  'mercury': 'ॐ ब्रां ब्रीं ब्रौं सः बुधाय नमः',
  'jupiter': 'ॐ ग्रां ग्रीं ग्रौं सः गुरवे नमः',
  'venus': 'ॐ द्रां द्रीं द्रौं सः शुक्राय नमः',
  'saturn': 'ॐ प्रां प्रीं प्रौं सः शनैश्चराय नमः',
  'rahu': 'ॐ भ्रां भ्रीं भ्रौं सः राहवे नमः',
  'ketu': 'ॐ स्रां स्रीं स्रौं सः केतवे नमः',
};

const _mulankPlanet = {
  1: 'sun', 2: 'moon', 3: 'jupiter', 4: 'rahu', 5: 'mercury',
  6: 'venus', 7: 'ketu', 8: 'saturn', 9: 'mars'
};

const _luckyDay = {
  'sun': 'Sunday', 'moon': 'Monday', 'mars': 'Tuesday', 'mercury': 'Wednesday',
  'jupiter': 'Thursday', 'venus': 'Friday', 'saturn': 'Saturday',
  'rahu': 'Saturday', 'ketu': 'Tuesday'
};
const _luckyColor = {
  'sun': 'Saffron, Orange, Gold', 'moon': 'White, Cream, Silver',
  'mars': 'Red, Coral', 'mercury': 'Green', 'jupiter': 'Yellow, Gold',
  'venus': 'White, Pink', 'saturn': 'Blue, Black', 'rahu': 'Smoky Grey',
  'ketu': 'Brown, Grey'
};
const _luckyMetal = {
  'sun': 'Gold', 'moon': 'Silver', 'mars': 'Copper', 'mercury': 'Bronze',
  'jupiter': 'Gold', 'venus': 'Silver', 'saturn': 'Iron', 'rahu': 'Lead',
  'ketu': 'Mixed'
};
const _luckyGem = {
  'sun': 'Ruby (Manik)', 'moon': 'Pearl (Moti)', 'mars': 'Red Coral (Moonga)',
  'mercury': 'Emerald (Panna)', 'jupiter': 'Yellow Sapphire (Pukhraj)',
  'venus': 'Diamond (Heera)', 'saturn': 'Blue Sapphire (Neelam)',
  'rahu': 'Hessonite (Gomed)', 'ketu': "Cat's Eye (Lehsunia)"
};

const _luckyDayHi = {
  'sun': 'रविवार', 'moon': 'सोमवार', 'mars': 'मंगलवार', 'mercury': 'बुधवार',
  'jupiter': 'गुरुवार', 'venus': 'शुक्रवार', 'saturn': 'शनिवार',
  'rahu': 'शनिवार', 'ketu': 'मंगलवार'
};
const _luckyColorHi = {
  'sun': 'केसरिया, नारंगी, स्वर्ण', 'moon': 'श्वेत, क्रीम, रजत',
  'mars': 'लाल, मूंगा', 'mercury': 'हरा', 'jupiter': 'पीला, स्वर्ण',
  'venus': 'श्वेत, गुलाबी', 'saturn': 'नीला, काला', 'rahu': 'धूम्र स्लेटी',
  'ketu': 'भूरा, स्लेटी'
};
const _luckyMetalHi = {
  'sun': 'सोना', 'moon': 'चांदी', 'mars': 'तांबा', 'mercury': 'कांस्य',
  'jupiter': 'सोना', 'venus': 'चांदी', 'saturn': 'लोहा', 'rahu': 'सीसा',
  'ketu': 'मिश्र धातु'
};
const _luckyGemHi = {
  'sun': 'माणिक्य (मानिक)', 'moon': 'मोती', 'mars': 'मूंगा',
  'mercury': 'पन्ना', 'jupiter': 'पुखराज',
  'venus': 'हीरा', 'saturn': 'नीलम',
  'rahu': 'गोमेद', 'ketu': 'लहसुनिया'
};

/// Functional benefic planets for each Lagna sign (0=Aries..11=Pisces).
const _functionalBenefics = <List<String>>[
  ['sun', 'moon', 'mars', 'jupiter'], // Aries
  ['sun', 'saturn', 'mercury', 'venus'], // Taurus
  ['mercury', 'venus', 'saturn'], // Gemini
  ['sun', 'moon', 'mars', 'jupiter'], // Cancer
  ['sun', 'mars', 'jupiter'], // Leo
  ['mercury', 'venus'], // Virgo
  ['saturn', 'mercury', 'venus'], // Libra
  ['sun', 'moon', 'mars', 'jupiter'], // Scorpio
  ['sun', 'mars', 'jupiter'], // Sagittarius
  ['venus', 'saturn', 'mercury'], // Capricorn
  ['venus', 'saturn', 'mercury'], // Aquarius
  ['moon', 'mars', 'jupiter'], // Pisces
];
const _naturalOrder = [
  'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'
];

int _reduce(int n) {
  while (n > 9) {
    var s = 0;
    while (n > 0) {
      s += n % 10;
      n ~/= 10;
    }
    n = s;
  }
  return n;
}

// Chaldean numerology letter values.
const _chaldean = {
  'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 8, 'g': 3, 'h': 5, 'i': 1,
  'j': 1, 'k': 2, 'l': 3, 'm': 4, 'n': 5, 'o': 7, 'p': 8, 'q': 1, 'r': 2,
  's': 3, 't': 4, 'u': 6, 'v': 6, 'w': 6, 'x': 5, 'y': 1, 'z': 7,
};

class SoulProfile {
  final String atmakaraka; // planet key
  final String darakaraka;
  final int karakamsaSign; // 0..11
  final int ishtaSign; // 12th from karakamsa
  final List<String> ishtaPlanets;
  final String ishtaDevata;
  final String ishtaMantra;
  final int mulank; // 1..9
  final int bhagyank;
  final int nameNumber;
  final String rulingPlanet;
  final String luckyDay, luckyColor, luckyMetal, luckyGem;
  final String luckyDayHi, luckyColorHi, luckyMetalHi, luckyGemHi;
  final List<int> friendlySigns; // 0..11 (houses 2,4,7)
  final List<int> goodLagnaSigns; // 0..11 (houses 4,7,9,11)
  final List<String> goodPlanets;
  final String luckMantra;
  final List<int> goodYears;
  final List<int> luckyNumbers;
  const SoulProfile({
    required this.atmakaraka,
    required this.darakaraka,
    required this.karakamsaSign,
    required this.ishtaSign,
    required this.ishtaPlanets,
    required this.ishtaDevata,
    required this.ishtaMantra,
    required this.mulank,
    required this.bhagyank,
    required this.nameNumber,
    required this.rulingPlanet,
    required this.luckyDay,
    required this.luckyColor,
    required this.luckyMetal,
    required this.luckyGem,
    required this.luckyDayHi,
    required this.luckyColorHi,
    required this.luckyMetalHi,
    required this.luckyGemHi,
    required this.friendlySigns,
    required this.goodLagnaSigns,
    required this.goodPlanets,
    required this.luckMantra,
    required this.goodYears,
    required this.luckyNumbers,
  });
}

/// Friendly numbers for each mulank/planet (numbers ruled by friendly planets).
const _friendlyNumbers = {
  'sun': [1, 2, 3, 9],
  'moon': [1, 2, 5, 7],
  'mars': [1, 3, 9],
  'mercury': [1, 5, 6],
  'jupiter': [1, 3, 5, 9],
  'venus': [5, 6, 8],
  'saturn': [5, 6, 8],
};

SoulProfile computeSoulProfile(BirthChart chart, BirthDetails birth) {
  // Chara karakas: highest degree-in-sign = Atmakaraka, lowest = Darakaraka.
  final degs = <String, double>{
    for (final k in _karakaPlanets) k: chart.byKey(k).graha.degInSign
  };
  final sorted = degs.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final ak = sorted.first.key;
  final dk = sorted.last.key;

  // Karakamsa = navamsa sign of the Atmakaraka; Ishta from 12th of it.
  final karakamsa = chart.byKey(ak).navamsa;
  final ishtaSign = (karakamsa + 11) % 12;
  // Real (non-node) planets sitting in the 12th-from-Karakamsa in the Navamsa
  // give the Ishta Devata; if only Rahu/Ketu are there (or it is empty), the
  // lord of that sign is taken instead.
  final realThere = [
    for (final p in chart.grahas)
      if (p.navamsa == ishtaSign && p.graha.key != 'rahu' && p.graha.key != 'ketu')
        p.graha.key
  ];
  final ishtaPlanet = realThere.isNotEmpty ? realThere.first : _signLord[ishtaSign];
  final ishtaPlanets = [ishtaPlanet];

  // Numerology.
  final mulank = _reduce(birth.dob.day);
  final bhagyank =
      _reduce(birth.dob.day + birth.dob.month + _reduce(birth.dob.year));
  var nameSum = 0;
  for (final ch in birth.name.toLowerCase().split('')) {
    nameSum += _chaldean[ch] ?? 0;
  }
  final nameNumber = nameSum == 0 ? 0 : _reduce(nameSum);
  final ruling = _mulankPlanet[mulank]!;

  // Good planets = the Lagna's functional benefics (in natural order); their
  // primary sets the lucky gem/metal/colour, and their days give the lucky days.
  final benefics = _functionalBenefics[chart.lagnaRashi];
  final goodPlanets = [
    for (final p in _naturalOrder)
      if (benefics.contains(p)) p
  ];
  final primary = goodPlanets.first;

  int houseSign(int h) => (chart.lagnaRashi + h - 1) % 12;
  // Friendly signs = houses 2/4/7; Good Lagna = houses 4/7/9/11 from Lagna.
  final friendlySigns = [houseSign(2), houseSign(4), houseSign(7)];
  final goodLagnaSigns = [houseSign(4), houseSign(7), houseSign(9), houseSign(11)];

  // Lucky numbers = the mulank + numbers ruled by friendly planets.
  final luckyNumbers = <int>{mulank, ...(_friendlyNumbers[ruling] ?? const [])}
      .toList()
    ..sort();

  // Good years = life-ages whose digit sum reduces to the Mulank (e.g. 14, 23…).
  final goodYears = <int>[];
  for (var age = 10; goodYears.length < 5; age++) {
    if (_reduce(age) == mulank) goodYears.add(age);
  }

  return SoulProfile(
    atmakaraka: ak,
    darakaraka: dk,
    karakamsaSign: karakamsa,
    ishtaSign: ishtaSign,
    ishtaPlanets: ishtaPlanets,
    ishtaDevata: ishtaDevataByPlanet[ishtaPlanet] ?? '—',
    ishtaMantra: beejMantraByPlanet[ishtaPlanet] ?? '',
    mulank: mulank,
    bhagyank: bhagyank,
    nameNumber: nameNumber,
    rulingPlanet: ruling,
    luckyDay: goodPlanets.map((p) => _luckyDay[p]!).join(', '),
    luckyColor: _luckyColor[primary]!,
    luckyMetal: _luckyMetal[primary]!,
    luckyGem: _luckyGem[primary]!,
    luckyDayHi: goodPlanets.map((p) => _luckyDayHi[p]!).join(', '),
    luckyColorHi: _luckyColorHi[primary]!,
    luckyMetalHi: _luckyMetalHi[primary]!,
    luckyGemHi: _luckyGemHi[primary]!,
    friendlySigns: friendlySigns,
    goodLagnaSigns: goodLagnaSigns,
    goodPlanets: goodPlanets,
    luckMantra: beejMantraByPlanet[primary] ?? '',
    goodYears: goodYears,
    luckyNumbers: luckyNumbers,
  );
}
