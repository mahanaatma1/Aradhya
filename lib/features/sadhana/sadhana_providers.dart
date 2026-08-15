import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../core/db/user_database.dart';
import '../../core/user/user_prefs.dart';
import 'sadhana_models.dart';

/// Per-day totals for every practice, from one query.
///
/// `sadhana_sessions` is append-only — the japa screen inserts a row per tap,
/// habits insert one per tick — so the hub aggregates rather than reading any
/// per-feature state. That is what lets japa, breathing, habits and mandir all
/// appear in one history without any of them knowing about the others.
final sadhanaByDayProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  final db = ref.watch(userDatabaseProvider);
  if (db == null) return const {};
  try {
    final rows = await db.raw.rawQuery('''
      SELECT practice, day_stamp, SUM(count) AS n
      FROM sadhana_sessions
      GROUP BY practice, day_stamp
    ''');
    final out = <String, Map<String, int>>{};
    for (final r in rows) {
      final practice = (r['practice'] as String?) ?? '';
      // Habits are collapsed into one series: the hub shows "habits" as a
      // single practice, and six rows there would just duplicate the habits
      // screen.
      final key = practice.startsWith('habit:') ? 'habits' : practice;
      final day = (r['day_stamp'] as String?) ?? '';
      final n = (r['n'] as num?)?.toInt() ?? 0;
      out.putIfAbsent(key, () => <String, int>{});
      out[key]![day] = (out[key]![day] ?? 0) + n;
    }
    return out;
  } catch (e) {
    debugPrint('sadhanaByDayProvider: $e');
    return const {};
  }
});

/// Summary for one practice.
final practiceSummaryProvider =
    FutureProvider.family<PracticeSummary, String>((ref, key) async {
  final all = await ref.watch(sadhanaByDayProvider.future);
  final byDay = all[key] ?? const <String, int>{};
  return PracticeSummary(
    key: key,
    byDay: byDay,
    todayCount: byDay[dayStamp()] ?? 0,
    lifetimeCount: byDay.values.fold(0, (a, b) => a + b),
    currentStreak: currentStreakOf(byDay),
    longestStreak: longestStreakOf(byDay),
  );
});

/// Days with any activity across ALL practices — the combined heatmap.
final sadhanaAllDaysProvider = FutureProvider<Map<String, int>>((ref) async {
  final all = await ref.watch(sadhanaByDayProvider.future);
  final out = <String, int>{};
  for (final byDay in all.values) {
    byDay.forEach((day, n) {
      if (n > 0) out[day] = (out[day] ?? 0) + n;
    });
  }
  return out;
});

/// How many distinct practices were done today — drives the today ring.
final practicesDoneTodayProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(sadhanaByDayProvider.future);
  final today = dayStamp();
  var n = 0;
  for (final byDay in all.values) {
    if ((byDay[today] ?? 0) > 0) n++;
  }
  return n;
});

final sadhanaGoalsProvider =
    FutureProvider<Map<String, SadhanaGoal>>((ref) async {
  final db = ref.watch(userDatabaseProvider);
  if (db == null) return const {};
  try {
    final rows = await db.raw.query('sadhana_goals');
    return {
      for (final r in rows)
        (r['practice'] as String? ?? ''): SadhanaGoal.fromRow(r),
    };
  } catch (e) {
    debugPrint('sadhanaGoalsProvider: $e');
    return const {};
  }
});

/// Sets or clears a per-practice target.
///
/// Takes [WidgetRef] because it is invoked from the hub's goal dialog. `Ref`
/// would only be right inside a provider body.
Future<void> setSadhanaGoal(
  WidgetRef ref, {
  required String practice,
  int? targetCount,
}) async {
  final db = ref.read(userDatabaseProvider);
  if (db == null) return;
  try {
    if (targetCount == null || targetCount <= 0) {
      await db.raw.delete('sadhana_goals',
          where: 'practice = ?', whereArgs: [practice]);
    } else {
      await db.raw.insert(
        'sadhana_goals',
        {'practice': practice, 'target_count': targetCount, 'active': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    ref.invalidate(sadhanaGoalsProvider);
  } catch (e) {
    debugPrint('setSadhanaGoal: $e');
  }
}

/// Consecutive days ending today or yesterday.
///
/// Yesterday counts so that a streak is not declared broken at 00:01 before
/// the user has had any chance to practise — the japa screen has always
/// behaved this way and the hub must agree with it.
int currentStreakOf(Map<String, int> byDay) {
  if (byDay.isEmpty) return 0;
  final today = DateTime.now();
  var cursor = (byDay[dayStamp(today)] ?? 0) > 0
      ? today
      : today.subtract(const Duration(days: 1));
  if ((byDay[dayStamp(cursor)] ?? 0) <= 0) return 0;

  var streak = 0;
  while ((byDay[dayStamp(cursor)] ?? 0) > 0) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int longestStreakOf(Map<String, int> byDay) {
  final days = byDay.entries
      .where((e) => e.value > 0)
      .map((e) => _parse(e.key))
      .whereType<DateTime>()
      .toList()
    ..sort();
  if (days.isEmpty) return 0;

  var best = 1, run = 1;
  for (var i = 1; i < days.length; i++) {
    if (days[i].difference(days[i - 1]).inDays == 1) {
      run++;
      if (run > best) best = run;
    } else if (days[i] != days[i - 1]) {
      run = 1;
    }
  }
  return best;
}

DateTime? _parse(String stamp) {
  final p = stamp.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}
