// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:divyavaani/features/astrology/astro_planets.dart';
import 'package:divyavaani/features/astrology/astro_chart.dart';
import 'package:divyavaani/features/astrology/vimshottari.dart';
import 'package:divyavaani/features/astrology/soul_profile.dart';
import 'package:divyavaani/features/astrology/ashtakoot.dart';
import 'package:divyavaani/features/astrology/astrology_providers.dart';

void main() {
  const signs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra',
    'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  test('9 grahas match reference chart (Tushar, 2001-07-23 04:52 IST)', () {
    // 04:52 IST Lakhisarai → UTC
    final birthUtc = DateTime.utc(2001, 7, 22, 23, 22);
    final grahas = {for (final g in computeGrahas(birthUtc)) g.key: g};

    String fmt(Graha g) {
      final deg = g.degInSign;
      final d = deg.floor();
      final m = ((deg - d) * 60).floor();
      final s = ((((deg - d) * 60) - m) * 60).round();
      return '${signs[g.rashi]} $d°$m\'$s"${g.retrograde ? ' R' : ''}';
    }

    // Reference (Ishvarvaani, Lahiri):
    final expected = {
      'sun': 'Cancer', 'moon': 'Leo', 'mars': 'Scorpio', 'mercury': 'Gemini',
      'jupiter': 'Gemini', 'venus': 'Taurus', 'saturn': 'Taurus',
      'rahu': 'Gemini', 'ketu': 'Sagittarius',
    };
    for (final e in expected.entries) {
      print('${e.key.padRight(8)} ours=${fmt(grahas[e.key]!).padRight(22)} '
          'ref-sign=${e.value}');
    }
    for (final e in expected.entries) {
      expect(signs[grahas[e.key]!.rashi], e.value, reason: e.key);
    }
  });

  test('Lagna + houses match reference chart', () {
    final birthUtc = DateTime.utc(2001, 7, 22, 23, 22);
    final chart = computeChart(birthUtc, 25.1726, 86.0947); // Lakhisarai
    final deg = chart.lagnaDegInSign;
    print('Lagna: ${signs[chart.lagnaRashi]} '
        '${deg.floor()}°${((deg - deg.floor()) * 60).floor()}\'  '
        '(ref: Cancer 1°59\')');
    for (final p in chart.grahas) {
      print('${p.graha.key.padRight(8)} house ${p.house}  D9 ${signs[p.navamsa]}');
    }
    expect(signs[chart.lagnaRashi], 'Cancer');
    // Reference: Sun H1, Moon H2, Mars H5, Mercury H12, Jupiter H12,
    // Venus H11, Saturn H11, Rahu H12, Ketu H6.
    expect(chart.byKey('sun').house, 1);
    expect(chart.byKey('moon').house, 2);
    expect(chart.byKey('mars').house, 5);
    expect(chart.byKey('venus').house, 11);
    expect(chart.byKey('ketu').house, 6);
  });

  test('Vimshottari dasha matches reference dates', () {
    final birthUtc = DateTime.utc(2001, 7, 22, 23, 22);
    final chart = computeChart(birthUtc, 25.1726, 86.0947);
    final moonSid = chart.byKey('moon').graha.sidereal;
    final at = DateTime.utc(2026, 7, 6);
    final cd = currentDasha(birthUtc, moonSid, at);
    final f = DateFormat('d MMM yyyy');
    print('Maha  ${cd.maha.lord}  ${f.format(cd.maha.start)} -> ${f.format(cd.maha.end)}');
    print('Antar ${cd.antar.lord}  ${f.format(cd.antar.start)} -> ${f.format(cd.antar.end)}');
    print('Praty ${cd.pratyantar.lord}  ${f.format(cd.pratyantar.start)} -> ${f.format(cd.pratyantar.end)}');
    // Reference: Sun MD 2025→2031, Rahu AD, Saturn PD.
    expect(cd.maha.lord, 'sun');
    expect(cd.antar.lord, 'rahu');
    expect(cd.pratyantar.lord, 'saturn');
  });

  test('Soul profile computes karakas + numerology', () {
    final birthUtc = DateTime.utc(2001, 7, 22, 23, 22);
    final chart = computeChart(birthUtc, 25.1726, 86.0947);
    final birth = BirthDetails(
        name: 'Tushar',
        dob: DateTime(2001, 7, 23, 4, 52),
        lat: 25.1726,
        lon: 86.0947,
        utcOffset: 5.5,
        place: 'Lakhisarai');
    final s = computeSoulProfile(chart, birth);
    const signs2 = [
      'Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio',
      'Sagittarius','Capricorn','Aquarius','Pisces'
    ];
    print('Ishta=${s.ishtaDevata}');
    print('LuckyDay=${s.luckyDay}');
    print('LuckyColour=${s.luckyColor}  Stone=${s.luckyGem}  Metal=${s.luckyMetal}');
    print('GoodYears=${s.goodYears}  NameNum=${s.nameNumber}');
    print('GoodPlanets=${s.goodPlanets}');
    print('FriendlySigns=${s.friendlySigns.map((i) => signs2[i]).toList()}');
    print('GoodLagna=${s.goodLagnaSigns.map((i) => signs2[i]).toList()}');
    expect(s.mulank, 5);
    expect(s.luckyGem, contains('Ruby'));
    expect(s.luckyDay, 'Sunday, Monday, Tuesday, Thursday');
    expect(s.goodYears, [14, 23, 32, 41, 50]);
    expect(s.goodPlanets, ['sun', 'moon', 'mars', 'jupiter']);
    expect(s.friendlySigns.map((i) => signs2[i]).toList(),
        ['Leo', 'Libra', 'Capricorn']);
    expect(s.goodLagnaSigns.map((i) => signs2[i]).toList(),
        ['Libra', 'Capricorn', 'Pisces', 'Taurus']);
  });

  test('Ashtakoot Milan matches reference (Tushar × Rami)', () {
    // Tushar: 2001-07-23 04:52 IST, Lakhisarai.
    final tushar = computeChart(
        DateTime.utc(2001, 7, 22, 23, 22), 25.1726, 86.0947);
    // Rami: 2001-12-11 00:00 IST, Bhagalpur → 2001-12-10 18:30 UTC.
    final rami =
        computeChart(DateTime.utc(2001, 12, 10, 18, 30), 25.29, 87.07);

    final m = computeMilan('Tushar', tushar, 'Rami', rami);
    print('Tushar moon: ${signs[m.a.rashi]}  nak ${m.a.nakshatra}');
    print('Rami   moon: ${signs[m.b.rashi]}  nak ${m.b.nakshatra}');
    for (final k in m.koots) {
      print('${k.name.padRight(14)} ${k.got} / ${k.max}');
    }
    print('TOTAL ${m.total} / 36');
    print('Manglik: a=${m.a.manglik} b=${m.b.manglik}');

    // Tushar's Moon is Leo / Magha (verified against chart above).
    expect(signs[m.a.rashi], 'Leo');
    expect(m.a.nakshatra, 9); // Magha

    // Individually verified against the Ishvarvaani reference screenshot:
    expect(m.koot('varna').got, 1.0);
    expect(m.koot('tara').got, 1.5);
    expect(m.koot('yoni').got, 2.0);
    expect(m.koot('maitri').got, 0.0);
    expect(m.koot('bhakoot').got, 7.0);
    expect(m.koot('nadi').got, 8.0);
    expect(m.total, greaterThan(0));
    expect(m.total, lessThanOrEqualTo(36));
  });
}
