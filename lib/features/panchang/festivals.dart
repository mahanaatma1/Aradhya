import 'panchang_engine.dart';
import 'panchang_names.dart';

/// A festival / vrat detected on a day, derived purely from the tithi.
class FestivalHit {
  final NamePair name;
  final bool major; // Ekadashi / Purnima / Amavasya get a stronger marker
  final NamePair? desc; // one-line bilingual description (for the detail sheet)
  const FestivalHit(this.name, this.major, {this.desc});
}

const _ekadashiDesc = NamePair(
    'The 11th-tithi fasting day devoted to Lord Vishnu.',
    'भगवान विष्णु को समर्पित ग्यारहवीं तिथि का व्रत।');
const _purnimaDesc = NamePair(
    'The full-moon day — auspicious for worship and vrat.',
    'पूर्णिमा — पूजा और व्रत के लिए शुभ दिन।');
const _amavasyaDesc = NamePair(
    'The new-moon day — for ancestors and remembrance.',
    'अमावस्या — पितरों के स्मरण का दिन।');

/// A few Amavasyas with well-known names (keyed by purnimanta month).
const _amavasyaSpecial = <int, NamePair>{
  6: NamePair('Sarva Pitru Amavasya', 'सर्व पितृ अमावस्या'),
  10: NamePair('Mauni Amavasya', 'मौनी अमावस्या'),
};

/// Recurring vrats that aren't Ekadashi/Purnima/Amavasya (those are named by
/// month in [festivalFor]). Returns null for other tithis.
FestivalHit? festivalForTithi(int tithiIdx) {
  switch (tithiIdx) {
    case 3: // Shukla Chaturthi
      return const FestivalHit(
          NamePair('Vinayaka Chaturthi', 'विनायक चतुर्थी'), false,
          desc: NamePair('The monthly Ganesha vrat on the waxing fourth.',
              'शुक्ल पक्ष की चतुर्थी का मासिक गणेश व्रत।'));
    case 18: // Krishna Chaturthi
      return const FestivalHit(
          NamePair('Sankashti Chaturthi', 'संकष्टी चतुर्थी'), false,
          desc: NamePair('Ganesha vrat on the waning fourth to remove obstacles.',
              'विघ्न हरने हेतु कृष्ण चतुर्थी का गणेश व्रत।'));
    case 12: // Shukla Trayodashi
    case 27: // Krishna Trayodashi
      return const FestivalHit(NamePair('Pradosh Vrat', 'प्रदोष व्रत'), false,
          desc: NamePair('The twilight vrat for Lord Shiva on the thirteenth.',
              'त्रयोदशी को भगवान शिव का प्रदोष व्रत।'));
    case 7: // Shukla Ashtami
      return const FestivalHit(NamePair('Durga Ashtami', 'दुर्गा अष्टमी'), false,
          desc: NamePair('Monthly worship of Goddess Durga on the eighth.',
              'अष्टमी को माँ दुर्गा की मासिक पूजा।'));
  }
  return null;
}

// Named festivals keyed by (purnimantaMonth * 30 + tithiIndex).
// Month: 0=Chaitra..11=Phalguna. Tithi: 0=Shukla Pratipada..14=Purnima,
// 15=Krishna Pratipada..29=Amavasya. (Purnimanta / North-Indian convention.)
FestivalHit _f(String en, String hi, String dEn, String dHi) =>
    FestivalHit(NamePair(en, hi), true, desc: NamePair(dEn, dHi));
final Map<int, FestivalHit> _named = {
  0 * 30 + 15: _f('Holi', 'होली',
      'Festival of colours celebrating the triumph of good over evil.',
      'रंगों का त्योहार — बुराई पर अच्छाई की जीत।'),
  0 * 30 + 8: _f('Ram Navami', 'राम नवमी',
      'The birth of Lord Rama.', 'भगवान श्रीराम का जन्मोत्सव।'),
  0 * 30 + 14: _f('Hanuman Jayanti', 'हनुमान जयंती',
      'The birth of Lord Hanuman.', 'हनुमान जी का जन्मोत्सव।'),
  1 * 30 + 2: _f('Akshaya Tritiya', 'अक्षय तृतीया',
      'A highly auspicious day for new beginnings.',
      'नए कार्यों के लिए अति शुभ दिन।'),
  1 * 30 + 14: _f('Buddha Purnima', 'बुद्ध पूर्णिमा',
      'The birth of Gautam Buddha.', 'गौतम बुद्ध का जन्मोत्सव।'),
  3 * 30 + 1: _f('Rath Yatra', 'रथ यात्रा',
      "Jagannath's grand chariot festival at Puri.",
      'पुरी में भगवान जगन्नाथ की भव्य रथ यात्रा।'),
  3 * 30 + 14: _f('Guru Purnima', 'गुरु पूर्णिमा',
      "A day to honour one's guru and teachers.",
      'गुरु के सम्मान और आभार का दिन।'),
  4 * 30 + 2: _f('Hariyali Teej', 'हरियाली तीज',
      'A monsoon festival for Goddess Parvati, kept by women.',
      'पार्वती का सावन पर्व, स्त्रियों द्वारा मनाया जाता है।'),
  4 * 30 + 4: _f('Nag Panchami', 'नाग पंचमी',
      'Worship of the serpent deities.', 'नाग देवताओं की पूजा।'),
  4 * 30 + 14: _f('Raksha Bandhan', 'रक्षाबंधन',
      'Celebrating the bond of brothers and sisters.',
      'भाई-बहन के स्नेह और रक्षा का पर्व।'),
  5 * 30 + 3: _f('Ganesh Chaturthi', 'गणेश चतुर्थी',
      'The birth of Lord Ganesha.', 'भगवान गणेश का जन्मोत्सव।'),
  5 * 30 + 13: _f('Anant Chaturdashi', 'अनंत चतुर्दशी',
      'Worship of Vishnu; the day of Ganesh immersion.',
      'विष्णु पूजा; गणेश विसर्जन का दिन।'),
  5 * 30 + 22: _f('Janmashtami', 'जन्माष्टमी',
      'The birth of Lord Krishna.', 'भगवान श्रीकृष्ण का जन्मोत्सव।'),
  6 * 30 + 0: _f('Navratri', 'नवरात्रि',
      'Nine nights devoted to Goddess Durga.', 'माँ दुर्गा को समर्पित नौ रातें।'),
  6 * 30 + 9: _f('Dussehra', 'दशहरा',
      'The victory of Rama over Ravana.', 'रावण पर श्रीराम की विजय।'),
  6 * 30 + 14: _f('Sharad Purnima', 'शरद पूर्णिमा',
      'The harvest full moon — the night of nectar.',
      'शरद पूर्णिमा — अमृत की रात।'),
  7 * 30 + 18: _f('Karva Chauth', 'करवा चौथ',
      "Wives' fast for their husband's long life.",
      'पति की दीर्घायु हेतु सुहागिनों का व्रत।'),
  7 * 30 + 27: _f('Dhanteras', 'धनतेरस',
      'The start of Diwali — wealth and Dhanvantari.',
      'दिवाली का आरंभ — धन और धन्वंतरि पूजा।'),
  7 * 30 + 29: _f('Diwali', 'दिवाली',
      'The festival of lights and Lakshmi puja.',
      'दीपों का पर्व और लक्ष्मी पूजा।'),
  7 * 30 + 0: _f('Govardhan Puja', 'गोवर्धन पूजा',
      'Worship of Govardhan hill and Lord Krishna.',
      'गोवर्धन पर्वत और श्रीकृष्ण की पूजा।'),
  7 * 30 + 1: _f('Bhai Dooj', 'भाई दूज',
      'Sisters bless their brothers for a long life.',
      'बहनें भाइयों की दीर्घायु का आशीर्वाद देती हैं।'),
  7 * 30 + 5: _f('Chhath Puja', 'छठ पूजा',
      'Worship of the Sun-god on the riverbanks.',
      'नदी घाट पर सूर्य देव की पूजा।'),
  7 * 30 + 14: _f('Kartik Purnima', 'कार्तिक पूर्णिमा',
      'A sacred full moon — Dev Deepawali.',
      'पवित्र पूर्णिमा — देव दीपावली।'),
  10 * 30 + 4: _f('Vasant Panchami', 'वसंत पंचमी',
      "Worship of Saraswati and spring's arrival.",
      'सरस्वती पूजा और वसंत का आगमन।'),
  11 * 30 + 14: _f('Holika Dahan', 'होलिका दहन',
      'The bonfire on the eve of Holi.',
      'होली की पूर्व संध्या का होलिका दहन।'),
  11 * 30 + 28: _f('Maha Shivratri', 'महाशिवरात्रि',
      'The great night of Lord Shiva.', 'भगवान शिव की महान रात्रि।'),
};

/// Festival for a day: a specific named festival if one matches, else the
/// month-named Ekadashi / Purnima / Amavasya, else a generic monthly vrat.
/// [aMonth] = amanta month (names Ekadashis); [pMonth] = purnimanta month
/// (keys the named table + Purnima/Amavasya month names).
FestivalHit? festivalFor(int tithiIdx, int pMonth, int aMonth,
    {bool adhika = false}) {
  // In an adhika (leap) month the dated festivals are not observed — they
  // belong to the nija month that follows. Only the fortnightly vrats and the
  // month's own Ekadashi/Purnima/Amavasya occur, and the Ekadashis take their
  // own names rather than the nija month's.
  if (adhika) return _adhikaFestivalFor(tithiIdx);

  final named = _named[pMonth * 30 + tithiIdx];
  if (named != null) return named;
  switch (tithiIdx) {
    case 10: // Shukla Ekadashi
      // Shukla paksha is unambiguous — both conventions agree on the month.
      final e = ekadashiShukla[aMonth];
      return FestivalHit(
          NamePair('${e.en} Ekadashi', '${e.hi} एकादशी'), true,
          desc: _ekadashiDesc);
    case 25: // Krishna Ekadashi
      // Named by the PURNIMANTA month, not the amanta one. The traditional
      // names pair each month's two Ekadashis — Ashadha gets Yogini (krishna)
      // and Devshayani (shukla) — and that pairing only holds under
      // purnimanta, where krishna paksha precedes shukla within a month.
      final e = ekadashiKrishna[pMonth];
      return FestivalHit(
          NamePair('${e.en} Ekadashi', '${e.hi} एकादशी'), true,
          desc: _ekadashiDesc);
    case 14: // Purnima
      final m = monthNames[pMonth];
      return FestivalHit(
          NamePair('${m.en} Purnima', '${m.hi} पूर्णिमा'), true,
          desc: _purnimaDesc);
    case 29: // Amavasya
      final s = _amavasyaSpecial[pMonth];
      if (s != null) return FestivalHit(s, true, desc: _amavasyaDesc);
      final m = monthNames[pMonth];
      return FestivalHit(
          NamePair('${m.en} Amavasya', '${m.hi} अमावस्या'), true,
          desc: _amavasyaDesc);
  }
  return festivalForTithi(tithiIdx);
}

/// Festivals within an adhika (intercalary) month.
///
/// Its two Ekadashis have their own names — Padmini in the waxing fortnight,
/// Parama in the waning — and they are the reason a leap month is also called
/// Purushottama Maasa. The Purnima and Amavasya carry the Adhika prefix so the
/// month is never confused with the nija one bearing the same name.
FestivalHit? _adhikaFestivalFor(int tithiIdx) {
  switch (tithiIdx) {
    case 10:
      return const FestivalHit(
          NamePair('Padmini Ekadashi', 'पद्मिनी एकादशी'), true,
          desc: NamePair(
              'The Ekadashi of the waxing fortnight of the adhika month.',
              'अधिक मास के शुक्ल पक्ष की एकादशी।'));
    case 25:
      return const FestivalHit(
          NamePair('Parama Ekadashi', 'परमा एकादशी'), true,
          desc: NamePair(
              'The Ekadashi of the waning fortnight of the adhika month.',
              'अधिक मास के कृष्ण पक्ष की एकादशी।'));
    case 14:
      return const FestivalHit(
          NamePair('Adhika Purnima', 'अधिक पूर्णिमा'), true,
          desc: _purnimaDesc);
    case 29:
      return const FestivalHit(
          NamePair('Adhika Amavasya', 'अधिक अमावस्या'), true,
          desc: _amavasyaDesc);
  }
  return festivalForTithi(tithiIdx);
}

/// Session cache: computing a month's festivals runs a new-moon scan per day,
/// which is far too heavy to redo every time a month scrolls back into view.
/// The result is a pure function of (year, month, tz), so we memoize it.
final Map<String, Map<int, FestivalHit>> _monthCache = {};

/// Festivals for every day of a month, keyed by day-of-month. Uses the tithi
/// prevailing at each sunrise + the purnimanta lunar month, and catches
/// "kshaya" tithis (a festival tithi that begins after one sunrise and ends
/// before the next) by assigning it to the day it occurred on. Memoized.
Map<int, FestivalHit> monthFestivals(int year, int month, Duration tz) {
  final key = '$year-$month-${tz.inMinutes}';
  final cached = _monthCache[key];
  if (cached != null) return cached;

  final days = DateTime(year, month + 1, 0).day;
  final tithi = <int, int>{};
  final pmonth = <int, int>{};
  final amonth = <int, int>{};
  final adhika = <int, bool>{};
  for (var d = 1; d <= days; d++) {
    final date = DateTime(year, month, d);
    tithi[d] = dayTithiIndex(date, tz);
    final lm = lunarMonth(date, tz);
    pmonth[d] = lm.purnimanta;
    amonth[d] = lm.amanta;
    adhika[d] = lm.adhika;
  }
  final out = <int, FestivalHit>{};
  for (var d = 1; d <= days; d++) {
    // A vriddhi tithi spans two sunrises and so appears on two consecutive
    // days. The vrat is observed once: skip the second day, unless the first
    // fell in the previous calendar month and is therefore not ours to skip.
    if (d > 1 && tithi[d] == tithi[d - 1]) continue;
    final f = festivalFor(tithi[d]!, pmonth[d]!, amonth[d]!,
        adhika: adhika[d]!);
    if (f != null) out[d] = f;
  }
  for (var d = 1; d < days; d++) {
    final a = tithi[d]!, b = tithi[d + 1]!;
    if ((a + 2) % 30 == b) {
      final f = festivalFor((a + 1) % 30, pmonth[d]!, amonth[d]!,
          adhika: adhika[d]!);
      if (f != null) out.putIfAbsent(d, () => f);
    }
  }
  _monthCache[key] = out;
  return out;
}

/// The festival on a specific day, if any (uses the memoized month scan).
FestivalHit? festivalOnDay(DateTime date, Duration tz) =>
    monthFestivals(date.year, date.month, tz)[date.day];

/// A dated festival — used by the Home banner and the widget.
class DatedFestival {
  final DateTime date;
  final FestivalHit hit;
  const DatedFestival(this.date, this.hit);
  int get daysAway =>
      date.difference(DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day)).inDays;
}

/// The next festival on/after [from] within [withinDays], or null. Prefers a
/// "major" festival if both a minor and a major fall on the very first day.
DatedFestival? nextFestival(DateTime from, Duration tz, {int withinDays = 30}) {
  final start = DateTime(from.year, from.month, from.day);
  for (var i = 0; i <= withinDays; i++) {
    final d = start.add(Duration(days: i));
    final f = festivalOnDay(d, tz);
    if (f != null) return DatedFestival(d, f);
  }
  return null;
}
