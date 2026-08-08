import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/user_database.dart';
import 'streak.dart';
import 'user_prefs.dart';

/// Japa mala counter state. [beads] runs 0..[mala] for the current round; each
/// full round increments [malas]. [today]/[total] and per-day [history] persist
/// across sessions and drive the streak + heatmap (mirrors Ishvarvaani's
/// getTodayJapa / getJapaStreak / JapaHeatmap model).
class JapaState {
  final int beads;
  final int malas;
  final int today;
  final int total;
  final int currentStreak;
  final int longestStreak;

  /// dayStamp (`YYYY-MM-DD`) -> japa count on that day. Powers the heatmap.
  final Map<String, int> history;

  const JapaState({
    required this.beads,
    required this.malas,
    required this.today,
    required this.total,
    required this.currentStreak,
    required this.longestStreak,
    required this.history,
  });

  JapaState copyWith({
    int? beads,
    int? malas,
    int? today,
    int? total,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? history,
  }) =>
      JapaState(
        beads: beads ?? this.beads,
        malas: malas ?? this.malas,
        today: today ?? this.today,
        total: total ?? this.total,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        history: history ?? this.history,
      );
}

class JapaController extends StateNotifier<JapaState> {
  JapaController(this._ref)
      : super(const JapaState(
          beads: 0,
          malas: 0,
          today: 0,
          total: 0,
          currentStreak: 0,
          longestStreak: 0,
          history: {},
        )) {
    _load();
    _hydrateFromDb();
  }

  final Ref _ref;

  /// One mala = 108 beads.
  static const mala = 108;

  /// Beads counted since the prefs history blob was last written. The blob is
  /// only a rollback safety net now, so it is flushed once per completed mala
  /// instead of once per bead.
  int _unflushed = 0;

  /// Set the moment the user counts anything. Used to suppress a late-arriving
  /// database hydrate that would otherwise clobber those counts. See
  /// [_hydrateFromDb].
  bool _countedSinceStart = false;

  void _load() {
    final p = _ref.read(sharedPrefsProvider);
    final history = _readHistory(p);
    state = JapaState(
      beads: 0,
      malas: p.getInt(PrefKeys.japaMalas) ?? 0,
      today: history[dayStamp()] ?? 0,
      total: p.getInt(PrefKeys.japaLifetime) ?? 0,
      currentStreak: _currentStreak(history),
      longestStreak: _longestStreak(history),
      history: history,
    );
  }

  /// Replaces the seeded prefs history with the database's version, which is
  /// authoritative once the migration has run. Silent no-op when the database
  /// is unavailable (tests, or a failed open) — the prefs seed still works.
  ///
  /// Bails out if the user has already counted beads while the query was in
  /// flight. Without that guard the result would overwrite `today`/`history`
  /// with a snapshot taken *before* those taps, and the on-screen counter would
  /// visibly jump backwards — the beads are safely in the database either way,
  /// but showing a user their count going down is unacceptable in a japa app.
  Future<void> _hydrateFromDb() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.rawQuery(
        "SELECT day_stamp, SUM(count) AS n FROM sadhana_sessions "
        "WHERE practice = 'japa' GROUP BY day_stamp",
      );
      if (rows.isEmpty || !mounted || _countedSinceStart) return;
      final history = <String, int>{
        for (final r in rows)
          r['day_stamp'] as String: (r['n'] as num?)?.toInt() ?? 0,
      };
      state = state.copyWith(
        today: history[dayStamp()] ?? 0,
        history: history,
        currentStreak: _currentStreak(history),
        longestStreak: _longestStreak(history),
      );
    } catch (e) {
      debugPrint('JapaController: history hydrate failed ($e)');
    }
  }

  Map<String, int> _readHistory(SharedPreferences p) {
    final raw = p.getString(PrefKeys.japaHistory);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Advance one bead.
  Future<void> advance() => addCounts(1);

  /// Add [n] chants at once — used by the bead tap (n=1), the + button, and
  /// "log offline japa". Rolls completed malas over, records against today's
  /// history, rewards each mala, and recomputes streaks.
  Future<void> addCounts(int n) async {
    if (n <= 0) return;
    _countedSinceStart = true;
    final p = _ref.read(sharedPrefsProvider);
    final today = dayStamp();

    final total = state.total + n;
    final todayCount = (state.history[today] ?? 0) + n;
    final history = Map<String, int>.from(state.history)..[today] = todayCount;

    var beads = state.beads + n;
    var malas = state.malas;
    while (beads >= mala) {
      beads -= mala;
      malas += 1;
    }
    final malasGained = malas - state.malas;
    if (malasGained > 0) {
      await p.setInt(PrefKeys.japaMalas, malas);
      await _ref
          .read(streakProvider.notifier)
          .addPoints(10 * malasGained); // reward each completed mala
    }

    await p.setInt(PrefKeys.japaLifetime, total);

    // Append-only row per tap. This is the whole point of moving off prefs:
    // `shared_preferences` rewrites its entire XML file on every `apply()`, so
    // storing the growing history blob there meant a full-file write per bead —
    // 108 of them for a single mala.
    final db = _ref.read(userDatabaseProvider);
    if (db != null) {
      try {
        await db.raw.insert('sadhana_sessions', {
          'day_stamp': today,
          'practice': 'japa',
          'count': n,
          'duration_s': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint('JapaController: session insert failed ($e)');
      }
    }

    // The legacy blob stays in sync coarsely, so rolling back to a previous
    // build keeps whole malas. Flushing per mala rather than per bead keeps the
    // rollback safety net without reintroducing the write amplification.
    _unflushed += n;
    if (db == null || malasGained > 0 || _unflushed >= mala) {
      await p.setString(PrefKeys.japaHistory, jsonEncode(history));
      _unflushed = 0;
    }

    state = state.copyWith(
      beads: beads,
      malas: malas,
      today: todayCount,
      total: total,
      currentStreak: _currentStreak(history),
      longestStreak: _longestStreak(history),
      history: history,
    );
  }

  /// Reset the current round's beads (does not touch history or totals).
  void resetRound() => state = state.copyWith(beads: 0);

  /// Days with any japa, counting back from today (or yesterday) while
  /// consecutive.
  static int _currentStreak(Map<String, int> history) {
    if (history.isEmpty) return 0;
    final today = dayStamp();
    // The streak is alive if there's japa today or yesterday.
    var cursor = (history[today] ?? 0) > 0
        ? today
        : dayStamp(DateTime.now().subtract(const Duration(days: 1)));
    if ((history[cursor] ?? 0) <= 0) return 0;
    var streak = 0;
    var day = _parseStamp(cursor);
    while (day != null && (history[dayStamp(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive days with japa across all history.
  static int _longestStreak(Map<String, int> history) {
    final days = history.entries
        .where((e) => e.value > 0)
        .map((e) => _parseStamp(e.key))
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (days.isEmpty) return 0;
    var best = 1, run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  static DateTime? _parseStamp(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}

final japaProvider =
    StateNotifierProvider<JapaController, JapaState>(
        (ref) => JapaController(ref));
