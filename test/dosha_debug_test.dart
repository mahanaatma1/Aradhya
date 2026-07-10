import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/astrology/astro_chart.dart';
import 'package:divyavaani/features/astrology/astro_planets.dart';
import 'package:divyavaani/features/astrology/sweph_ephemeris.dart';
import 'package:divyavaani/features/astrology/yogas_doshas.dart';

/// Prints exactly which doshas fire for a birth chart, and separates the
/// birth-fixed ones from the transit-based Sade Sati.
void main() {
  // >>>>>>>> EDIT THESE TO YOUR BIRTH DETAILS <<<<<<<<
  const year = 2001, month = 7, day = 23;
  const hour = 4, minute = 38; // local birth time (24h)
  const lat = 25.1764, lon = 86.0943; // birth place (Lakhisarai, Bihar)
  const tz = Duration(hours: 5, minutes: 30); // IST
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  const signs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra',
    'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  test('dosha diagnostic', () async {
    // Swiss Ephemeris only loads when its native lib is on the path (real app
    // build); headless `flutter test` falls back to the Schlyter model.
    await initSwephEphemeris();
    // ignore: avoid_print
    print('Swiss Ephemeris active: $swephReady');
    // Build birthUtc the way the app does: a NON-UTC DateTime holding UTC
    // values (local birth time minus the timezone offset).
    final birthUtc = DateTime(year, month, day, hour, minute).subtract(tz);
    final chart = computeChart(birthUtc, lat, lon);

    final lagnaDeg = chart.lagnaSidereal - chart.lagnaRashi * 30;
    // ignore: avoid_print
    print('=== CHART (Lagna = ${signs[chart.lagnaRashi]} '
        '${lagnaDeg.toStringAsFixed(2)}°) ===');
    final navLagna = navamsaSign(chart.lagnaSidereal);
    // ignore: avoid_print
    print('Navamsa Lagna = ${signs[navLagna]}');
    for (final p in chart.grahas) {
      final navHouse = (p.navamsa - navLagna + 12) % 12 + 1;
      // ignore: avoid_print
      print('  ${p.graha.key.padRight(8)} '
          'sign=${signs[p.graha.rashi].padRight(11)} '
          'deg=${p.graha.degInSign.toStringAsFixed(2).padLeft(6)} '
          'D9=${signs[p.navamsa].padRight(11)} D9house=$navHouse');
    }
    final yogas = detectYogas(chart);
    // ignore: avoid_print
    print('YOGAS (${yogas.length}): '
        '${yogas.map((y) => '${y.type}@h${y.house}${y.planets}').join(', ')}');

    final moon = chart.byKey('moon');
    final mars = chart.byKey('mars');

    // Birth-fixed doshas: pass a fixed "now == birth" so Sade Sati is judged
    // against the natal Saturn (it will only fire if Saturn was in 12/1/2 at
    // birth — i.e. essentially never a surprise), isolating what changes.
    final today = detectDoshas(chart); // uses DateTime.now() → live transit

    // Current Saturn transit vs natal Moon (the Sade Sati driver).
    final satNow = computeGrahas(
      DateTime.now().toUtc(),
    ).firstWhere((g) => g.key == 'saturn').rashi;
    final diff = (satNow - moon.graha.rashi + 12) % 12;

    // ignore: avoid_print
    print('=== DOSHA DIAGNOSTIC ===');
    // ignore: avoid_print
    print(
      'Moon rashi=${moon.graha.rashi}  Mars house=${mars.house} '
      'rashi=${mars.graha.rashi}',
    );
    // ignore: avoid_print
    print(
      'Current Saturn rashi=$satNow  → from Moon=$diff '
      '(Sade Sati fires when 11, 0 or 1)',
    );
    // ignore: avoid_print
    print(
      'DOSHAS NOW (${today.length}): '
      '${today.map((d) => d.type + (d.severity.isEmpty ? '' : '(${d.severity})')).join(', ')}',
    );
    for (final d in today) {
      // ignore: avoid_print
      print(
        '  - ${d.type}'
        '${d.type == 'sadesati' ? '  <-- TRANSIT-BASED (changes with the date)' : '  (birth-fixed)'}',
      );
    }
  });
}
