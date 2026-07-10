import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:divyavaani/features/astrology/astro_chart.dart';
import 'package:divyavaani/features/astrology/astro_planets.dart';
import 'package:divyavaani/features/astrology/sweph_ephemeris.dart';
import 'package:divyavaani/features/astrology/yogas_doshas.dart';

/// Runs the birth-chart diagnostic ON THE DEVICE so the native Swiss Ephemeris
/// library actually loads (headless `flutter test` cannot load libsweph.so and
/// falls back to the Schlyter model). Output is printed to the test console.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // >>>>>>>> BIRTH DETAILS <<<<<<<<
  const year = 2001, month = 7, day = 23;
  const hour = 4, minute = 38; // local birth time (24h)
  const lat = 25.1764, lon = 86.0943; // Lakhisarai, Bihar
  const tz = Duration(hours: 5, minutes: 30); // IST
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  const signs = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra',
    'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  testWidgets('kundli diagnostic (sweph on device)', (tester) async {
    await initSwephEphemeris();
    debugPrint('SWEPH_READY=$swephReady  err=$swephError');

    final birthUtc = DateTime(year, month, day, hour, minute).subtract(tz);
    final chart = computeChart(birthUtc, lat, lon);

    final lagnaDeg = chart.lagnaSidereal - chart.lagnaRashi * 30;
    final navLagna = navamsaSign(chart.lagnaSidereal);
    debugPrint('LAGNA=${signs[chart.lagnaRashi]} '
        '${lagnaDeg.toStringAsFixed(2)}  NAV_LAGNA=${signs[navLagna]}');

    for (final p in chart.grahas) {
      final navHouse = (p.navamsa - navLagna + 12) % 12 + 1;
      final house = (p.graha.rashi - chart.lagnaRashi + 12) % 12 + 1;
      debugPrint('P ${p.graha.key.padRight(8)} '
          'sign=${signs[p.graha.rashi].padRight(11)} '
          'deg=${p.graha.degInSign.toStringAsFixed(2).padLeft(6)} '
          'H=$house  D9=${signs[p.navamsa].padRight(11)} D9H=$navHouse');
    }

    final yogas = detectYogas(chart);
    final yogaStr = yogas.map((y) => '${y.type}@h${y.house}${y.planets}').join(', ');
    debugPrint('YOGAS(${yogas.length})=$yogaStr');

    final today = detectDoshas(chart);
    final moon = chart.byKey('moon');
    final satNow = computeGrahas(DateTime.now().toUtc())
        .firstWhere((g) => g.key == 'saturn')
        .rashi;
    final diff = (satNow - moon.graha.rashi + 12) % 12;
    debugPrint('SAT_NOW=${signs[satNow]} fromMoon=$diff '
        '(SadeSati when 11/0/1)');
    final doshaStr = today
        .map((d) => d.type + (d.severity.isEmpty ? '' : '(${d.severity})'))
        .join(', ');
    debugPrint('DOSHAS(${today.length})=$doshaStr');

    expect(swephReady, isTrue,
        reason: 'Swiss Ephemeris did not load on the device');
  });
}
