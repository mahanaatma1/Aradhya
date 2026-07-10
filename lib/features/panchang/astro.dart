import 'dart:math' as math;

/// Low-precision sun & moon positions (Paul Schlyter's method) — pure Dart,
/// no ephemeris files. Accurate to ~1–2 arcminutes, ample for panchang
/// (tithi / nakshatra / yoga / karana) and rise/set times.

double _rev(double x) {
  x = x % 360.0;
  return x < 0 ? x + 360 : x;
}

const _deg = math.pi / 180.0;
double _sin(double d) => math.sin(d * _deg);
double _cos(double d) => math.cos(d * _deg);
double _atan2(double y, double x) => math.atan2(y, x) / _deg;
double _asin(double x) => math.asin(x.clamp(-1.0, 1.0)) / _deg;

/// Day number since 2000 Jan 0.0 UT (fractional).
double dayNumber(DateTime utc) {
  final y = utc.year, m = utc.month, day = utc.day;
  final ut = utc.hour + utc.minute / 60.0 + utc.second / 3600.0;
  final d = 367 * y -
      (7 * (y + ((m + 9) ~/ 12))) ~/ 4 +
      (275 * m) ~/ 9 +
      day -
      730530;
  return d + ut / 24.0;
}

class EclPos {
  final double lon; // ecliptic longitude, degrees (tropical)
  final double lat; // ecliptic latitude, degrees
  const EclPos(this.lon, this.lat);
}

class EquPos {
  final double ra; // right ascension, degrees
  final double dec; // declination, degrees
  const EquPos(this.ra, this.dec);
}

double _obliquity(double d) => 23.4393 - 3.563e-7 * d;

/// Sun mean longitude (used for sidereal time) and true ecliptic longitude.
class _Sun {
  final double meanLon; // Ls
  final double trueLon;
  final double meanAnom; // Ms
  const _Sun(this.meanLon, this.trueLon, this.meanAnom);
}

_Sun _sun(double d) {
  final w = 282.9404 + 4.70935e-5 * d;
  final e = 0.016709 - 1.151e-9 * d;
  final m = _rev(356.0470 + 0.9856002585 * d);
  final ea = m + (180 / math.pi) * e * _sin(m) * (1 + e * _cos(m));
  final x = _cos(ea) - e;
  final y = _sin(ea) * math.sqrt(1 - e * e);
  final v = _atan2(y, x);
  final lon = _rev(v + w);
  return _Sun(_rev(w + m), lon, m);
}

/// Sun tropical ecliptic longitude.
double sunLongitude(double d) => _sun(d).trueLon;

/// Moon geocentric ecliptic position with the main perturbations.
EclPos moonPosition(double d) {
  final n = _rev(125.1228 - 0.0529538083 * d);
  const i = 5.1454;
  final w = _rev(318.0634 + 0.1643573223 * d);
  const a = 60.2666;
  const e = 0.054900;
  final m = _rev(115.3654 + 13.0649929509 * d);

  // eccentric anomaly (iterate)
  double ea = m + (180 / math.pi) * e * _sin(m) * (1 + e * _cos(m));
  for (var k = 0; k < 5; k++) {
    ea = ea - (ea - (180 / math.pi) * e * _sin(ea) - m) / (1 - e * _cos(ea));
  }
  final x = a * (_cos(ea) - e);
  final y = a * math.sqrt(1 - e * e) * _sin(ea);
  final r = math.sqrt(x * x + y * y);
  final v = _atan2(y, x);

  final xe = r * (_cos(n) * _cos(v + w) - _sin(n) * _sin(v + w) * _cos(i));
  final ye = r * (_sin(n) * _cos(v + w) + _cos(n) * _sin(v + w) * _cos(i));
  final ze = r * _sin(v + w) * _sin(i);
  double lon = _atan2(ye, xe);
  double lat = _atan2(ze, math.sqrt(xe * xe + ye * ye));

  // perturbations
  final s = _sun(d);
  final ms = s.meanAnom;
  final ls = s.meanLon;
  final mm = m;
  final lm = _rev(n + w + m);
  final dd = _rev(lm - ls); // elongation
  final f = _rev(lm - n); // argument of latitude

  lon += -1.274 * _sin(mm - 2 * dd) +
      0.658 * _sin(2 * dd) -
      0.186 * _sin(ms) -
      0.059 * _sin(2 * mm - 2 * dd) -
      0.057 * _sin(mm - 2 * dd + ms) +
      0.053 * _sin(mm + 2 * dd) +
      0.046 * _sin(2 * dd - ms) +
      0.041 * _sin(mm - ms) -
      0.035 * _sin(dd) -
      0.031 * _sin(mm + ms) -
      0.015 * _sin(2 * f - 2 * dd) +
      0.011 * _sin(mm - 4 * dd);
  lat += -0.173 * _sin(f - 2 * dd) -
      0.055 * _sin(mm - f - 2 * dd) -
      0.046 * _sin(mm + f - 2 * dd) +
      0.033 * _sin(f + 2 * dd) +
      0.017 * _sin(2 * mm + f);

  return EclPos(_rev(lon), lat);
}

double moonLongitude(double d) => moonPosition(d).lon;

/// Lahiri (Chitrapaksha) ayanamsa in degrees.
double ayanamsa(double d) => 23.853 + 0.0139601 * (d / 365.25);

EquPos _toEqu(double d, EclPos p) {
  final o = _obliquity(d);
  final xg = _cos(p.lon) * _cos(p.lat);
  final yg = _sin(p.lon) * _cos(p.lat);
  final zg = _sin(p.lat);
  final xe = xg;
  final ye = yg * _cos(o) - zg * _sin(o);
  final ze = yg * _sin(o) + zg * _cos(o);
  return EquPos(_rev(_atan2(ye, xe)), _atan2(ze, math.sqrt(xe * xe + ye * ye)));
}

EquPos sunEqu(double d) => _toEqu(d, EclPos(sunLongitude(d), 0));
EquPos moonEqu(double d) => _toEqu(d, moonPosition(d));

/// Local sidereal time in degrees.
double _lst(double d, double lonEast) {
  final gmst0 = _rev(_sun(d).meanLon + 180);
  final ut = (d - d.floorToDouble()) * 24.0; // fractional day → hours
  return _rev(gmst0 + 15.04107 * ut + lonEast);
}

/// Altitude (degrees) of a body at [utc] for observer (lat, lonEast).
double _altitude(DateTime utc, EquPos Function(double) equ, double lat,
    double lonEast) {
  final d = dayNumber(utc);
  final p = equ(d);
  final ha = _rev(_lst(d, lonEast) - p.ra);
  final sinAlt =
      _sin(lat) * _sin(p.dec) + _cos(lat) * _cos(p.dec) * _cos(ha);
  return _asin(sinAlt);
}

/// Rise/set for a body on a given local day by scanning altitude crossings.
/// Returns (rise, set) as local DateTimes (may be null near poles / no event).
({DateTime? rise, DateTime? set}) riseSet({
  required DateTime localMidnight,
  required Duration tzOffset,
  required EquPos Function(double) equ,
  required double lat,
  required double lonEast,
  double horizon = -0.833,
}) {
  DateTime? rise, set;
  double? prevAlt;
  const stepMin = 4;
  for (var i = 0; i <= 24 * 60; i += stepMin) {
    final local = localMidnight.add(Duration(minutes: i));
    final utc = local.subtract(tzOffset);
    final alt = _altitude(utc, equ, lat, lonEast) - horizon;
    if (prevAlt != null) {
      if (prevAlt < 0 && alt >= 0 && rise == null) {
        rise = _refine(localMidnight.add(Duration(minutes: i - stepMin)),
            localMidnight.add(Duration(minutes: i)), tzOffset, equ, lat, lonEast, horizon, true);
      } else if (prevAlt >= 0 && alt < 0 && set == null) {
        set = _refine(localMidnight.add(Duration(minutes: i - stepMin)),
            localMidnight.add(Duration(minutes: i)), tzOffset, equ, lat, lonEast, horizon, false);
      }
    }
    prevAlt = alt;
  }
  return (rise: rise, set: set);
}

DateTime _refine(DateTime a, DateTime b, Duration tz, EquPos Function(double) equ,
    double lat, double lonEast, double horizon, bool rising) {
  for (var k = 0; k < 12; k++) {
    final mid = a.add(Duration(seconds: b.difference(a).inSeconds ~/ 2));
    final alt = _altitude(mid.subtract(tz), equ, lat, lonEast) - horizon;
    final up = alt >= 0;
    if (up == rising) {
      b = mid;
    } else {
      a = mid;
    }
  }
  return a.add(Duration(seconds: b.difference(a).inSeconds ~/ 2));
}
