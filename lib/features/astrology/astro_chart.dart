import 'dart:math' as math;

import '../panchang/astro.dart' show dayNumber, ayanamsa;
import 'astro_planets.dart';
import 'sweph_ephemeris.dart';

/// A computed birth chart: Lagna, planet placements, houses, and D9 (Navamsa).

const _d2r = math.pi / 180.0;
double _rev(double x) => (x % 360 + 360) % 360;
double _sin(double d) => math.sin(d * _d2r);
double _cos(double d) => math.cos(d * _d2r);
double _tan(double d) => math.tan(d * _d2r);
double _atan2(double y, double x) => math.atan2(y, x) / _d2r;

double _sunMeanLon(double d) =>
    _rev((282.9404 + 4.70935e-5 * d) + (356.0470 + 0.9856002585 * d));

/// Tropical Ascendant (Lagna) longitude for a birth instant + place.
double _ascendantTropical(double d, double latDeg, double lonEast) {
  final gmst0 = _rev(_sunMeanLon(d) + 180);
  final ut = (d - d.floorToDouble()) * 24.0;
  final lst = _rev(gmst0 + 15.04107 * ut + lonEast); // RAMC, degrees
  final eps = 23.4393 - 3.563e-7 * d;
  final asc = _atan2(
    _cos(lst),
    -(_sin(lst) * _cos(eps) + _tan(latDeg) * _sin(eps)),
  );
  return _rev(asc);
}

/// Navamsa (D9) sign index (0..11) for a sidereal longitude.
int navamsaSign(double sidereal) => (sidereal / (10 / 3)).floor() % 12;

class PlacedGraha {
  final Graha graha;
  final int house; // 1..12 (whole-sign from Lagna)
  final int navamsa; // 0..11 sign index in D9
  const PlacedGraha(this.graha, this.house, this.navamsa);
}

class BirthChart {
  final double lagnaSidereal;
  final int lagnaRashi; // 0..11
  final List<PlacedGraha> grahas;
  final double ayanamsaDeg;
  const BirthChart({
    required this.lagnaSidereal,
    required this.lagnaRashi,
    required this.grahas,
    required this.ayanamsaDeg,
  });

  double get lagnaDegInSign => lagnaSidereal - lagnaRashi * 30;
  PlacedGraha byKey(String k) => grahas.firstWhere((g) => g.graha.key == k);
}

/// One planet's placement in a divisional chart (D1 or D9).
class ChartPlacement {
  final String key;
  final int sign; // 0..11
  final bool retro;
  const ChartPlacement(this.key, this.sign, this.retro);
}

/// A renderable chart (Rashi D1 or Navamsa D9): the Lagna sign + placements.
class ChartView {
  final int lagnaSign;
  final List<ChartPlacement> placements;
  const ChartView(this.lagnaSign, this.placements);

  /// Whole-sign house (1..12) a sign falls in for this chart's Lagna.
  int houseOf(int sign) => ((sign - lagnaSign) % 12 + 12) % 12 + 1;
}

extension ChartViews on BirthChart {
  ChartView get rashiView => ChartView(
        lagnaRashi,
        [
          for (final p in grahas)
            ChartPlacement(p.graha.key, p.graha.rashi, p.graha.retrograde)
        ],
      );

  ChartView get navamsaView => ChartView(
        navamsaSign(lagnaSidereal),
        [
          for (final p in grahas)
            ChartPlacement(p.graha.key, p.navamsa, p.graha.retrograde)
        ],
      );
}

/// Build the full chart. [birthUtc] is the UTC birth instant; [lat]/[lonEast]
/// the birth place (degrees, east positive). Whole-sign house system (Vedic).
BirthChart computeChart(DateTime birthUtc, double lat, double lonEast) {
  final d = dayNumber(birthUtc);
  final ayan = ayanamsa(d);
  // Swiss Ephemeris ascendant when available (matches planet positions), else
  // the built-in approximation.
  final ascSid = swephAscSidereal(birthUtc, lat, lonEast) ??
      _rev(_ascendantTropical(d, lat, lonEast) - ayan);
  final lagnaRashi = (ascSid / 30).floor() % 12;

  final placed = <PlacedGraha>[];
  for (final g in computeGrahas(birthUtc)) {
    final house = ((g.rashi - lagnaRashi) % 12 + 12) % 12 + 1;
    placed.add(PlacedGraha(g, house, navamsaSign(g.sidereal)));
  }

  return BirthChart(
    lagnaSidereal: ascSid,
    lagnaRashi: lagnaRashi,
    grahas: placed,
    ayanamsaDeg: ayan,
  );
}
