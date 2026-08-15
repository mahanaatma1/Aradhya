import 'astro.dart';
import 'panchang_names.dart';

/// One panchang element with its current value, end time, and the next value.
class PElement {
  final NamePair current;
  final NamePair? next;
  final DateTime? endTime; // local; null => lasts the whole day
  const PElement(this.current, this.next, this.endTime);
}

/// An auspicious / inauspicious window during the day.
class Muhurat {
  final NamePair name;
  final DateTime start;
  final DateTime end;
  final bool auspicious;
  const Muhurat(this.name, this.start, this.end, this.auspicious);
}

class Panchang {
  final DateTime date;
  final double lat, lon;
  final PElement tithi, nakshatra, yoga, karana;
  final NamePair paksha, vara, month;
  final DateTime? sunrise, sunset, moonrise, moonset;
  final List<Muhurat> muhurats;

  /// The named Ekadashi (e.g. Nirjala) when today's tithi is Ekadashi, else null.
  final NamePair? ekadashi;

  const Panchang({
    required this.date,
    required this.lat,
    required this.lon,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.paksha,
    required this.vara,
    required this.month,
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
    this.muhurats = const [],
    this.ekadashi,
  });
}

// Day divided into 8 parts (sunrise→sunset); which part each period falls in,
// indexed by weekday 0=Sun..6=Sat (standard values).
const _rahuPart = [8, 2, 7, 5, 6, 4, 3];
const _yamaPart = [5, 4, 3, 2, 1, 7, 6];
const _gulikaPart = [7, 6, 5, 4, 3, 2, 1];

List<Muhurat> _muhurats(DateTime sunrise, DateTime sunset, int wday) {
  final dayMs = sunset.difference(sunrise).inMilliseconds;
  if (dayMs <= 0) return const [];
  final part = dayMs ~/ 8;
  DateTime seg(int oneBasedPart) =>
      sunrise.add(Duration(milliseconds: (oneBasedPart - 1) * part));

  final midday = sunrise.add(Duration(milliseconds: dayMs ~/ 2));
  final muhurtaMs = dayMs ~/ 15; // one muhurta of daytime

  final out = <Muhurat>[
    Muhurat(mRahu, seg(_rahuPart[wday]),
        seg(_rahuPart[wday]).add(Duration(milliseconds: part)), false),
    Muhurat(mYamaganda, seg(_yamaPart[wday]),
        seg(_yamaPart[wday]).add(Duration(milliseconds: part)), false),
    Muhurat(mGulika, seg(_gulikaPart[wday]),
        seg(_gulikaPart[wday]).add(Duration(milliseconds: part)), false),
    Muhurat(mBrahma, sunrise.subtract(const Duration(minutes: 96)),
        sunrise.subtract(const Duration(minutes: 48)), true),
  ];

  // Abhijit muhurat is traditionally void on Wednesday (wday 3), so we omit it.
  if (wday != 3) {
    out.add(Muhurat(
        mAbhijit,
        midday.subtract(Duration(milliseconds: muhurtaMs ~/ 2)),
        midday.add(Duration(milliseconds: muhurtaMs ~/ 2)),
        true));
  }
  return out;
}

double _rev(double x) {
  x = x % 360;
  return x < 0 ? x + 360 : x;
}

int _tithiIdx(DateTime utc) {
  final d = dayNumber(utc);
  return (_rev(moonLongitude(d) - sunLongitude(d)) / 12).floor();
}

/// Tithi index (0..29) prevailing around sunrise on a local calendar date —
/// lightweight (no rise/set scan) for marking festivals across a month.
int dayTithiIndex(DateTime date, Duration tz) {
  final refLocal = DateTime(date.year, date.month, date.day, 6);
  return _tithiIdx(refLocal.subtract(tz));
}

double _elong(DateTime utc) {
  final d = dayNumber(utc);
  return _rev(moonLongitude(d) - sunLongitude(d));
}

/// Refine a new-moon (elongation 360→0) crossing within [aUtc, bUtc].
DateTime _newMoonNear(DateTime aUtc, DateTime bUtc) {
  var a = aUtc, b = bUtc;
  for (var k = 0; k < 28; k++) {
    final m = a.add(Duration(seconds: b.difference(a).inSeconds ~/ 2));
    if (_elong(m) > 180) {
      a = m;
    } else {
      b = m;
    }
  }
  return b;
}

/// The most recent new moon (amavasya end) at or before [refUtc].
/// Daily scan (elongation drops ~12°/day) then bisect — fast enough to call
/// per calendar day.
DateTime lastNewMoon(DateTime refUtc) {
  final start = refUtc.subtract(const Duration(days: 31));
  var prev = _elong(start);
  var result = start;
  for (var i = 1; i <= 31; i++) {
    final t = start.add(Duration(days: i));
    if (t.isAfter(refUtc)) break;
    final e = _elong(t);
    if (prev > 300 && e < 60) {
      result = _newMoonNear(t.subtract(const Duration(days: 1)), t);
    }
    prev = e;
  }
  return result;
}

/// Amanta & purnimanta lunar-month index (0=Chaitra .. 11=Phalguna) for a date.
/// Amanta = named by the solar month entered within the amavasya-to-amavasya
/// month; purnimanta shifts the waning (Krishna) fortnight to the next month.
({int amanta, int purnimanta, bool adhika}) lunarMonth(
    DateTime date, Duration tz) {
  // Reference at ~sunrise (06:00) so the paksha matches the day's tithi used
  // for festivals; otherwise a Purnima ending mid-morning would flip the month.
  final refUtc = DateTime(date.year, date.month, date.day, 6).subtract(tz);
  final nm = lastNewMoon(refUtc);
  final rashi = _sunRashiAt(nm);
  final amanta = (rashi + 1) % 12;
  final krishna = _tithiIdx(refUtc) >= 15;

  // An adhika (intercalary) month is a lunation in which the sun enters no
  // new rashi at all — no sankranti falls between this new moon and the next,
  // so the month takes the same name as the one that follows it. This is why
  // a month can appear to "stick": that is the leap month, not a failure to
  // advance. Festivals are observed in the nija (true) month, so the caller
  // needs to know which of the two it is looking at.
  final next = _newMoonAfter(nm);
  final adhika = _sunRashiAt(next) == rashi;

  return (
    amanta: amanta,
    purnimanta: krishna ? (amanta + 1) % 12 : amanta,
    adhika: adhika,
  );
}

/// Sidereal rashi (0=Aries) of the sun at [utc].
int _sunRashiAt(DateTime utc) {
  final d = dayNumber(utc);
  return (_rev(sunLongitude(d) - ayanamsa(d)) / 30).floor() % 12;
}

/// The first new moon strictly after [nm]. A synodic month is ~29.53 days, so
/// searching from +20 days always lands before the next one.
DateTime _newMoonAfter(DateTime nm) {
  final probe = nm.add(const Duration(days: 34));
  final found = lastNewMoon(probe);
  return found.isAfter(nm.add(const Duration(days: 1)))
      ? found
      : nm.add(const Duration(days: 30));
}

int _naksIdx(DateTime utc) {
  final d = dayNumber(utc);
  final sid = _rev(moonLongitude(d) - ayanamsa(d));
  return (sid / (360 / 27)).floor();
}

int _yogaIdx(DateTime utc) {
  final d = dayNumber(utc);
  final a = ayanamsa(d);
  final sum = _rev(_rev(sunLongitude(d) - a) + _rev(moonLongitude(d) - a));
  return (sum / (360 / 27)).floor();
}

int _karanaIdx(DateTime utc) {
  final d = dayNumber(utc);
  return (_rev(moonLongitude(d) - sunLongitude(d)) / 6).floor();
}

NamePair _karanaName(int half) {
  if (half <= 0) return karanaKimstughna;
  if (half >= 57) return karanaFixedEnd[(half - 57).clamp(0, 2)];
  return karanaMovable[(half - 1) % 7];
}

/// Scan forward from [startLocal] to find when [idxFn] leaves [startIdx].
/// Returns the local transition time, or null if unchanged within ~28h.
DateTime? _findEnd(
    DateTime startLocal, Duration tz, int Function(DateTime) idxFn, int startIdx) {
  const stepMin = 6;
  DateTime prev = startLocal;
  for (var i = stepMin; i <= 28 * 60; i += stepMin) {
    final local = startLocal.add(Duration(minutes: i));
    if (idxFn(local.subtract(tz)) != startIdx) {
      // refine between prev and local
      var a = prev, b = local;
      for (var k = 0; k < 10; k++) {
        final mid = a.add(Duration(seconds: b.difference(a).inSeconds ~/ 2));
        if (idxFn(mid.subtract(tz)) == startIdx) {
          a = mid;
        } else {
          b = mid;
        }
      }
      return a.add(Duration(seconds: b.difference(a).inSeconds ~/ 2));
    }
    prev = local;
  }
  return null;
}

PElement _element(DateTime refLocal, Duration tz, int Function(DateTime) idxFn,
    List<NamePair> names) {
  final idx = idxFn(refLocal.subtract(tz));
  final end = _findEnd(refLocal, tz, idxFn, idx);
  final next = end == null
      ? null
      : names[idxFn(end.add(const Duration(minutes: 1)).subtract(tz)) % names.length];
  return PElement(names[idx % names.length], next, end);
}

/// Compute the panchang for a local calendar date at a location.
/// [amanta] selects the lunar-month naming convention (Amanta vs the default
/// North-Indian Purnimanta).
Panchang computePanchang({
  required DateTime date, // local date (time ignored)
  required double lat,
  required double lonEast,
  required Duration tzOffset,
  bool amanta = false,
}) {
  final midnight = DateTime(date.year, date.month, date.day);

  final sun = riseSet(
      localMidnight: midnight,
      tzOffset: tzOffset,
      equ: sunEqu,
      lat: lat,
      lonEast: lonEast,
      horizon: -0.833);
  final moon = riseSet(
      localMidnight: midnight,
      tzOffset: tzOffset,
      equ: moonEqu,
      lat: lat,
      lonEast: lonEast,
      horizon: 0.125);

  final refLocal = sun.rise ?? midnight.add(const Duration(hours: 6));
  final refUtc = refLocal.subtract(tzOffset);

  final tIdx = _tithiIdx(refUtc);
  final paksha = tIdx < 15 ? pakshaShukla : pakshaKrishna;
  final lm = lunarMonth(date, tzOffset);
  final lmonth = amanta ? lm.amanta : lm.purnimanta;

  // Named Ekadashi: tithi ordinal 11 in either paksha (index 10 or 25). The
  // name is keyed by the amanta month regardless of the display convention.
  final NamePair? ekadashi = tIdx == 10
      ? ekadashiShukla[lm.amanta]
      : tIdx == 25
          ? ekadashiKrishna[lm.amanta]
          : null;

  // Karana names come from the 0..59 half-tithi index, so handle separately.
  final kHalf = _karanaIdx(refUtc);
  final kEnd = _findEnd(refLocal, tzOffset, _karanaIdx, kHalf);
  final kNext = kEnd == null
      ? null
      : _karanaName(_karanaIdx(kEnd.add(const Duration(minutes: 1)).subtract(tzOffset)));

  return Panchang(
    date: midnight,
    lat: lat,
    lon: lonEast,
    tithi: _element(refLocal, tzOffset, _tithiIdx, tithiNames),
    nakshatra: _element(refLocal, tzOffset, _naksIdx, nakshatraNames),
    yoga: _element(refLocal, tzOffset, _yogaIdx, yogaNames),
    karana: PElement(_karanaName(kHalf), kNext, kEnd),
    paksha: paksha,
    vara: varaNames[midnight.weekday % 7],
    month: monthNames[lmonth],
    sunrise: sun.rise,
    sunset: sun.set,
    moonrise: moon.rise,
    moonset: moon.set,
    muhurats: (sun.rise != null && sun.set != null)
        ? _muhurats(sun.rise!, sun.set!, midnight.weekday % 7)
        : const [],
    ekadashi: ekadashi,
  );
}
