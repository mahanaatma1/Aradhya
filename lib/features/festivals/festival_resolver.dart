import '../panchang/astro.dart';
import '../panchang/panchang_engine.dart';
import '../panchang/panchang_names.dart';
import 'festival_models.dart';

/// Turns a stored festival RULE into a real date.
///
/// Nothing is fetched. The rule is what the tradition fixes; the date it lands
/// on is computed here from the same engine that draws the Panchang screen, so
/// the two can never disagree with each other.
class FestivalResolver {
  final Duration tz;
  const FestivalResolver(this.tz);

  static final _monthIndex = <String, int>{
    for (var i = 0; i < monthNames.length; i++)
      monthNames[i].en.toLowerCase(): i,
    // The corpus writes 'ashwin'; the engine's table says 'Ashwina'.
    'ashwin': 6,
  };

  /// Tithi index 0..29 for a paksha + tithi-within-paksha pair.
  static int? _tithiIndex(String? paksha, int? tithi) {
    if (paksha == null || tithi == null || tithi < 1 || tithi > 15) return null;
    return paksha == 'shukla' ? tithi - 1 : 15 + tithi - 1;
  }

  /// Sidereal rashi of the sun at noon on [date], 0 = Aries.
  int _sunRashi(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day, 12)
        .subtract(tz);
    final d = dayNumber(utc);
    var lon = (sunLongitude(d) - ayanamsa(d)) % 360;
    if (lon < 0) lon += 360;
    return (lon / 30).floor() % 12;
  }

  /// Every occurrence of [f] between [from] and [from] + [withinDays].
  ///
  /// A window rather than a single answer, because a rule can legitimately
  /// resolve more than once in a long window — and, for a monthly rule such as
  /// the Shravan Mondays, is meant to.
  List<DateTime> occurrences(Festival f, DateTime from, {int withinDays = 400}) {
    final out = <DateTime>[];
    final start = DateTime(from.year, from.month, from.day);

    if (f.isSolar) {
      final target = _solarTargetRashi(f.solarRule!);
      if (target == null) return out;
      var prev = _sunRashi(start.subtract(const Duration(days: 1)));
      for (var i = 0; i <= withinDays; i++) {
        final day = start.add(Duration(days: i));
        final r = _sunRashi(day);
        // The festival is the day the sun enters the sign, not every day it
        // spends there.
        if (r == target && prev != target) out.add(day);
        prev = r;
      }
      return out;
    }

    final month = _monthIndex[(f.lunarMonth ?? '').toLowerCase()];
    final wantTithi = _tithiIndex(f.paksha, f.tithi);
    if (month == null) return out;

    // A rule with a month but no tithi is a recurring weekday observance
    // (the Shravan Mondays). Match every such weekday inside the month.
    if (wantTithi == null) {
      final weekday = _weekdayFromRule(f.solarRule);
      if (weekday == null) return out;
      for (var i = 0; i <= withinDays; i++) {
        final day = start.add(Duration(days: i));
        if (day.weekday != weekday) continue;
        final lm = lunarMonth(day, tz);
        if (lm.adhika) continue;
        if (lm.purnimanta == month) out.add(day);
      }
      return out;
    }

    var lastTithi = -1;
    for (var i = 0; i <= withinDays; i++) {
      final day = start.add(Duration(days: i));
      final t = dayTithiIndex(day, tz);
      // A vriddhi tithi spans two sunrises. The observance is one day.
      if (t == lastTithi) continue;
      lastTithi = t;
      if (t != wantTithi) continue;
      final lm = lunarMonth(day, tz);
      // Dated festivals are kept in the nija month, never the intercalary one.
      if (lm.adhika) continue;
      if (lm.purnimanta == month) out.add(day);
    }
    return out;
  }

  /// The next occurrence of [f] on or after [from], or null within the window.
  DateTime? next(Festival f, DateTime from, {int withinDays = 400}) {
    final all = occurrences(f, from, withinDays: withinDays);
    return all.isEmpty ? null : all.first;
  }

  /// Resolve a whole list and sort by date. Festivals whose rule does not
  /// resolve inside the window are dropped rather than shown undated.
  List<ResolvedFestival> resolveAll(List<Festival> list, DateTime from,
      {int withinDays = 400}) {
    final out = <ResolvedFestival>[];
    for (final f in list) {
      final d = next(f, from, withinDays: withinDays);
      if (d != null) out.add(ResolvedFestival(f, d));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  static int? _solarTargetRashi(String rule) {
    final r = rule.toLowerCase();
    if (r.contains('makara') || r.contains('capricorn')) return 9;
    if (r.contains('mesha') || r.contains('aries')) return 0;
    // Onam is fixed by a nakshatra inside a solar month; that needs its own
    // rule and is deliberately not guessed at here.
    return null;
  }

  static int? _weekdayFromRule(String? rule) {
    if (rule == null) return null;
    const days = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    final r = rule.toLowerCase();
    for (final e in days.entries) {
      if (r.contains(e.key)) return e.value;
    }
    return null;
  }
}
