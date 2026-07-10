import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';

/// Direct Swiss Ephemeris check (needs sweph.dll on the load path) proving the
/// timezone handling: birthUtc built as local-birth-time minus offset, using
/// RAW fields (no .toUtc()), must give Moon ≈ Leo 6°40′ for Tushar's chart.
void main() {
  test('sweph moon position for the correct instant', () async {
    try {
      await Sweph.init(
          epheFilesPath: '${Directory.systemTemp.path}/sweph_ephe');
    } catch (e) {
      // ignore: avoid_print
      print('SWEPH not available in this env: $e');
      return; // skip when the native lib isn't on the path
    }
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);

    // 23 Jul 2001 04:52 IST → non-UTC DateTime holding UTC values (app style).
    final birthUtc = DateTime(2001, 7, 23, 4, 52)
        .subtract(const Duration(hours: 5, minutes: 30));
    final hours = birthUtc.hour + birthUtc.minute / 60 + birthUtc.second / 3600;
    final jd = Sweph.swe_julday(
        birthUtc.year, birthUtc.month, birthUtc.day, hours,
        CalendarType.SE_GREG_CAL);

    final flags = SwephFlag.SEFLG_SIDEREAL | SwephFlag.SEFLG_MOSEPH;
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
    final moonInLeo = moon.longitude - 120; // Leo starts at 120°

    // ignore: avoid_print
    print('Moon sidereal=${moon.longitude.toStringAsFixed(4)} '
        '(Leo ${moonInLeo.toStringAsFixed(4)}°)  '
        'Sun=${sun.longitude.toStringAsFixed(4)} (Cancer ${(sun.longitude - 90).toStringAsFixed(2)}°)');

    // Ishvarvaani: Moon Leo 6°40′27″ ≈ 6.674°, Sun Cancer 6°18′.
    expect(moonInLeo, closeTo(6.674, 0.05));
  });
}
