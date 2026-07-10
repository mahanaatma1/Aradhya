import '../panchang/panchang_names.dart' show NamePair;

/// The 12 rashis (zodiac signs), 0 = Aries.
const signNames = <NamePair>[
  NamePair('Aries', 'मेष'), NamePair('Taurus', 'वृषभ'),
  NamePair('Gemini', 'मिथुन'), NamePair('Cancer', 'कर्क'),
  NamePair('Leo', 'सिंह'), NamePair('Virgo', 'कन्या'),
  NamePair('Libra', 'तुला'), NamePair('Scorpio', 'वृश्चिक'),
  NamePair('Sagittarius', 'धनु'), NamePair('Capricorn', 'मकर'),
  NamePair('Aquarius', 'कुम्भ'), NamePair('Pisces', 'मीन'),
];

class PlanetInfo {
  final String short; // 2-letter chart code
  final NamePair name;
  const PlanetInfo(this.short, this.name);
}

/// Display info for each graha key.
const planetInfo = <String, PlanetInfo>{
  'sun': PlanetInfo('Su', NamePair('Sun', 'सूर्य')),
  'moon': PlanetInfo('Mo', NamePair('Moon', 'चंद्र')),
  'mars': PlanetInfo('Ma', NamePair('Mars', 'मंगल')),
  'mercury': PlanetInfo('Me', NamePair('Mercury', 'बुध')),
  'jupiter': PlanetInfo('Ju', NamePair('Jupiter', 'गुरु')),
  'venus': PlanetInfo('Ve', NamePair('Venus', 'शुक्र')),
  'saturn': PlanetInfo('Sa', NamePair('Saturn', 'शनि')),
  'rahu': PlanetInfo('Ra', NamePair('Rahu', 'राहु')),
  'ketu': PlanetInfo('Ke', NamePair('Ketu', 'केतु')),
};

/// Order used in the planetary-positions table.
const planetOrder = [
  'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu'
];

String degMinSec(double degInSign) {
  final d = degInSign.floor();
  final mF = (degInSign - d) * 60;
  final m = mF.floor();
  final s = ((mF - m) * 60).round();
  return "$d°$m'$s\"";
}
