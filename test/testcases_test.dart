// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:divyavaani/features/astrology/astro_chart.dart';
import 'package:divyavaani/features/astrology/vimshottari.dart';
import 'package:divyavaani/features/astrology/ashtakoot.dart';
import 'package:divyavaani/features/panchang/panchang_names.dart';

const _signs = [
  'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra',
  'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
];

class TC {
  final String name;
  final int y, mo, d, h, mi;
  final String place;
  final double lat, lon, off;
  const TC(this.name, this.y, this.mo, this.d, this.h, this.mi, this.place,
      this.lat, this.lon, this.off);

  DateTime get utc => DateTime.utc(y, mo, d, h, mi)
      .subtract(Duration(minutes: (off * 60).round()));
  BirthChart get chart => computeChart(utc, lat, lon);
}

const cases = <TC>[
  TC('P1', 1990, 1, 15, 8, 30, 'Delhi', 28.6139, 77.2090, 5.5),
  TC('P2', 1985, 6, 21, 14, 45, 'Mumbai', 19.0760, 72.8777, 5.5),
  TC('P3', 1978, 11, 2, 23, 15, 'Kolkata', 22.5726, 88.3639, 5.5),
  TC('P4', 1995, 3, 30, 6, 5, 'Chennai', 13.0827, 80.2707, 5.5),
  TC('P5', 2000, 9, 9, 18, 20, 'Bengaluru', 12.9716, 77.5946, 5.5),
  TC('P6', 1988, 12, 25, 11, 0, 'Hyderabad', 17.3850, 78.4867, 5.5),
  TC('P7', 1972, 7, 7, 3, 40, 'Jaipur', 26.9124, 75.7873, 5.5),
  TC('P8', 1993, 2, 14, 21, 50, 'Lucknow', 26.8467, 80.9462, 5.5),
  TC('P9', 2002, 10, 19, 9, 25, 'Ahmedabad', 23.0225, 72.5714, 5.5),
  TC('P10', 1965, 5, 5, 16, 10, 'Pune', 18.5204, 73.8567, 5.5),
];

void main() {
  test('10 single-chart test cases', () {
    final f = DateFormat('d MMM yyyy');
    for (final c in cases) {
      final ch = c.chart;
      final moon = ch.byKey('moon').graha;
      final moonSid = moon.sidereal;
      final cd = currentDasha(c.utc, moonSid, DateTime.utc(2026, 7, 7));
      final asc = ch.lagnaDegInSign;
      final planets = [
        for (final k in [
          'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn',
          'rahu', 'ketu'
        ])
          '${k[0].toUpperCase()}${k.substring(1, 2)}:${_signs[ch.byKey(k).graha.rashi].substring(0, 3)}${ch.byKey(k).graha.retrograde ? '(R)' : ''}'
      ].join('  ');
      print('=== ${c.name}: ${c.y}-${c.mo.toString().padLeft(2, '0')}-'
          '${c.d.toString().padLeft(2, '0')} '
          '${c.h.toString().padLeft(2, '0')}:${c.mi.toString().padLeft(2, '0')} '
          '${c.place} (${c.lat}, ${c.lon}) ===');
      print('  Lagna: ${_signs[ch.lagnaRashi]} '
          '${asc.floor()}°${((asc - asc.floor()) * 60).floor()}\'');
      print('  Moon:  ${_signs[moon.rashi]}  '
          'Nak: ${nakshatraNames[moon.nakshatra].en} (Pada ${moon.nakPada})');
      print('  $planets');
      print('  Dasha: ${cd.maha.lord.toUpperCase()} '
          '(${f.format(cd.maha.start)} -> ${f.format(cd.maha.end)}), '
          'Antar ${cd.antar.lord}');
    }
  });

  test('10 Kundli Milan test cases', () {
    final pairs = <(TC, TC)>[
      (cases[0], cases[1]),
      (cases[2], cases[3]),
      (cases[4], cases[5]),
      (cases[6], cases[7]),
      (cases[8], cases[9]),
      (cases[0], cases[3]),
      (cases[1], cases[4]),
      (cases[2], cases[5]),
      (cases[7], cases[8]),
      (cases[6], cases[9]),
    ];
    var i = 1;
    for (final (a, b) in pairs) {
      final m = computeMilan(a.name, a.chart, b.name, b.chart);
      final scores = m.koots.map((k) => '${k.name} ${_num(k.got)}').join(', ');
      print('=== Milan $i: ${a.name} (groom) x ${b.name} (bride) ===');
      print('  ${a.name}: Moon ${_signs[m.a.rashi]} / '
          '${nakshatraNames[m.a.nakshatra].en}  | '
          '${b.name}: Moon ${_signs[m.b.rashi]} / '
          '${nakshatraNames[m.b.nakshatra].en}');
      print('  $scores');
      print('  TOTAL: ${_num(m.total)} / 36   '
          'Manglik: ${a.name}=${m.a.manglik}, ${b.name}=${m.b.manglik}');
      i++;
    }
  });
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
