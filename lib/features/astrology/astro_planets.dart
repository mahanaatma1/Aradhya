import 'dart:math' as math;

import '../panchang/astro.dart' show dayNumber, ayanamsa;
import 'sweph_ephemeris.dart';

/// Geocentric sidereal (Lahiri) positions of the nine grahas, computed with
/// Paul Schlyter's orbital-element method (≈1 arcminute) — pure Dart, no
/// ephemeris files. Enough to place every planet in the correct rashi,
/// nakshatra, degree and house for a Vedic kundli.

const _d2r = math.pi / 180.0;
double _rev(double x) => (x % 360 + 360) % 360;
double _sin(double d) => math.sin(d * _d2r);
double _cos(double d) => math.cos(d * _d2r);
double _atan2(double y, double x) => math.atan2(y, x) / _d2r;

class Graha {
  final String key; // 'sun','moon','mars',...
  final double tropical; // geocentric tropical ecliptic longitude
  final double sidereal; // tropical - ayanamsa (Lahiri)
  final bool retrograde;
  const Graha(this.key, this.tropical, this.sidereal, this.retrograde);

  int get rashi => (sidereal / 30).floor() % 12; // 0=Aries..11=Pisces
  double get degInSign => sidereal - rashi * 30;
  int get nakshatra => (sidereal / (360 / 27)).floor() % 27;
  int get nakPada => ((sidereal % (360 / 27)) / (360 / 108)).floor() + 1;
}

// Heliocentric rectangular ecliptic coordinates of a planet (Schlyter).
({double x, double y, double z}) _helio(
    double n, double i, double w, double a, double e, double m) {
  var ea = m + (180 / math.pi) * e * _sin(m) * (1 + e * _cos(m));
  for (var k = 0; k < 6; k++) {
    ea = ea - (ea - (180 / math.pi) * e * _sin(ea) - m) / (1 - e * _cos(ea));
  }
  final xv = a * (_cos(ea) - e);
  final yv = a * math.sqrt(1 - e * e) * _sin(ea);
  final v = _atan2(yv, xv);
  final r = math.sqrt(xv * xv + yv * yv);
  final x = r * (_cos(n) * _cos(v + w) - _sin(n) * _sin(v + w) * _cos(i));
  final y = r * (_sin(n) * _cos(v + w) + _cos(n) * _sin(v + w) * _cos(i));
  final z = r * _sin(v + w) * _sin(i);
  return (x: x, y: y, z: z);
}

// Sun geocentric rectangular (= negative of Earth heliocentric) + longitude.
({double x, double y, double lon, double r}) _sunRect(double d) {
  final w = 282.9404 + 4.70935e-5 * d;
  final e = 0.016709 - 1.151e-9 * d;
  final m = _rev(356.0470 + 0.9856002585 * d);
  var ea = m + (180 / math.pi) * e * _sin(m) * (1 + e * _cos(m));
  ea = ea - (ea - (180 / math.pi) * e * _sin(ea) - m) / (1 - e * _cos(ea));
  final xv = _cos(ea) - e;
  final yv = math.sqrt(1 - e * e) * _sin(ea);
  final v = _atan2(yv, xv);
  final r = math.sqrt(xv * xv + yv * yv);
  final lon = _rev(v + w);
  return (x: r * _cos(lon), y: r * _sin(lon), lon: lon, r: r);
}

double _planetGeoLon(double d, String key) {
  final s = _sunRect(d);
  late double n, i, w, a, e, m;
  switch (key) {
    case 'mercury':
      n = 48.3313 + 3.24587e-5 * d;
      i = 7.0047 + 5.00e-8 * d;
      w = 29.1241 + 1.01444e-5 * d;
      a = 0.387098;
      e = 0.205635 + 5.59e-10 * d;
      m = _rev(168.6562 + 4.0923344368 * d);
    case 'venus':
      n = 76.6799 + 2.46590e-5 * d;
      i = 3.3946 + 2.75e-8 * d;
      w = 54.8910 + 1.38374e-5 * d;
      a = 0.723330;
      e = 0.006773 - 1.302e-9 * d;
      m = _rev(48.0052 + 1.6021302244 * d);
    case 'mars':
      n = 49.5574 + 2.11081e-5 * d;
      i = 1.8497 - 1.78e-8 * d;
      w = 286.5016 + 2.92961e-5 * d;
      a = 1.523688;
      e = 0.093405 + 2.516e-9 * d;
      m = _rev(18.6021 + 0.5240207766 * d);
    case 'jupiter':
      n = 100.4542 + 2.76854e-5 * d;
      i = 1.3030 - 1.557e-7 * d;
      w = 273.8777 + 1.64505e-5 * d;
      a = 5.20256;
      e = 0.048498 + 4.469e-9 * d;
      m = _rev(19.8950 + 0.0830853001 * d);
    case 'saturn':
      n = 113.6634 + 2.38980e-5 * d;
      i = 2.4886 - 1.081e-7 * d;
      w = 339.3939 + 2.97661e-5 * d;
      a = 9.55475;
      e = 0.055546 - 9.499e-9 * d;
      m = _rev(316.9670 + 0.0334442282 * d);
    default:
      return 0;
  }
  final p = _helio(n, i, w, a, e, m);
  var lon = _rev(_atan2(p.y + s.y, p.x + s.x));

  // Major perturbations of Jupiter & Saturn (Schlyter).
  if (key == 'jupiter' || key == 'saturn') {
    final mj = _rev(19.8950 + 0.0830853001 * d);
    final ms = _rev(316.9670 + 0.0334442282 * d);
    if (key == 'jupiter') {
      lon += -0.332 * _sin(2 * mj - 5 * ms - 67.6) -
          0.056 * _sin(2 * mj - 2 * ms + 21) +
          0.042 * _sin(3 * mj - 5 * ms + 21) -
          0.036 * _sin(mj - 2 * ms) +
          0.022 * _cos(mj - ms) +
          0.023 * _sin(2 * mj - 3 * ms + 52) -
          0.016 * _sin(mj - 5 * ms - 69);
    } else {
      lon += 0.812 * _sin(2 * mj - 5 * ms - 67.6) -
          0.229 * _cos(2 * mj - 4 * ms - 2) +
          0.119 * _sin(mj - 2 * ms - 3) +
          0.046 * _sin(2 * mj - 6 * ms - 69) +
          0.014 * _sin(mj - 3 * ms + 32);
    }
  }
  return _rev(lon);
}

/// Mean lunar node (Rahu), tropical longitude.
double _rahuTropical(double d) => _rev(125.1228 - 0.0529538083 * d);

/// Moon geocentric tropical longitude (reuse the panchang moon model here would
/// couple features; recompute the main terms locally for the kundli).
double _moonTropical(double d) {
  final n = _rev(125.1228 - 0.0529538083 * d);
  const i = 5.1454;
  final w = _rev(318.0634 + 0.1643573223 * d);
  const a = 60.2666, e = 0.054900;
  final m = _rev(115.3654 + 13.0649929509 * d);
  var ea = m + (180 / math.pi) * e * _sin(m) * (1 + e * _cos(m));
  for (var k = 0; k < 6; k++) {
    ea = ea - (ea - (180 / math.pi) * e * _sin(ea) - m) / (1 - e * _cos(ea));
  }
  final x = a * (_cos(ea) - e);
  final y = a * math.sqrt(1 - e * e) * _sin(ea);
  final v = _atan2(y, x);
  final r = math.sqrt(x * x + y * y);
  final xe = r * (_cos(n) * _cos(v + w) - _sin(n) * _sin(v + w) * _cos(i));
  final ye = r * (_sin(n) * _cos(v + w) + _cos(n) * _sin(v + w) * _cos(i));
  var lon = _atan2(ye, xe);
  // main perturbations
  final ws = 282.9404 + 4.70935e-5 * d;
  final ms = _rev(356.0470 + 0.9856002585 * d);
  final ls = _rev(ws + ms);
  final lm = _rev(n + w + m), dd = _rev(lm - ls);
  final f = _rev(lm - n); // argument of latitude
  lon += -1.274 * _sin(m - 2 * dd) +
      0.658 * _sin(2 * dd) -
      0.186 * _sin(ms) -
      0.059 * _sin(2 * m - 2 * dd) -
      0.057 * _sin(m - 2 * dd + ms) +
      0.053 * _sin(m + 2 * dd) +
      0.046 * _sin(2 * dd - ms) +
      0.041 * _sin(m - ms) -
      0.035 * _sin(dd) -
      0.031 * _sin(m + ms) -
      0.015 * _sin(2 * f - 2 * dd) +
      0.011 * _sin(m - 4 * dd);
  return _rev(lon);
}

double _sunTropical(double d) => _sunRect(d).lon;

/// Compute all nine grahas for a UTC birth instant. Uses Swiss Ephemeris when
/// available (arc-second precision), else the Schlyter approximation below.
List<Graha> computeGrahas(DateTime birthUtc) {
  final sw = swephGrahas(birthUtc);
  if (sw != null) {
    return [
      for (final g in sw) Graha(g.key, g.tropical, g.sidereal, g.retro),
    ];
  }

  final d = dayNumber(birthUtc);
  final ayan = ayanamsa(d);
  double sid(double trop) => _rev(trop - ayan);

  // retrograde: compare geocentric longitude a little before/after
  bool retro(String key) {
    final dd = 0.5;
    final before = _planetGeoLon(d - dd, key);
    final after = _planetGeoLon(d + dd, key);
    var delta = after - before;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta < 0;
  }

  final rahuT = _rahuTropical(d);
  return [
    Graha('sun', _sunTropical(d), sid(_sunTropical(d)), false),
    Graha('moon', _moonTropical(d), sid(_moonTropical(d)), false),
    for (final k in ['mars', 'mercury', 'jupiter', 'venus', 'saturn'])
      Graha(k, _planetGeoLon(d, k), sid(_planetGeoLon(d, k)), retro(k)),
    Graha('rahu', rahuT, sid(rahuT), true),
    Graha('ketu', _rev(rahuT + 180), sid(_rev(rahuT + 180)), true),
  ];
}
