import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/user_database.dart';

/// A local, resettable interest profile.
///
/// Scoped deliberately small, and the scope is the point. This may influence
/// the ORDER of discovery — which rail comes first, which of two equally
/// weighted related items leads, which theme today's journal prompt takes.
///
/// It must never influence which scriptures, verses, deities or traditions are
/// *available or visible*. Narrowing what a person is exposed to based on tap
/// behaviour is an engagement loop borrowed from a domain where it belongs,
/// and this is not that domain. The library stays whole; only the shelf order
/// moves. If that distinction ever gets blurred, delete the feature.
///
/// Never leaves the device — the same posture as the journal.
class InterestSignals extends StateNotifier<Map<String, double>> {
  InterestSignals(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  /// What each interaction is worth. Opening something is weak evidence;
  /// bookmarking it is strong. Nothing here is worth enough that a handful of
  /// taps can dominate the profile.
  static const openWeight = 1.0;
  static const dwellWeight = 2.0;
  static const bookmarkWeight = 5.0;
  static const journeyStepWeight = 3.0;
  static const quizWeight = 1.0;

  /// Applied once a day. Interests drift instead of ossifying: something you
  /// cared about a year ago should not still be steering the app today.
  static const dailyDecay = 0.98;

  Future<void> _load() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await _decayIfDue(db);
      final rows = await db.raw.query('interest_signals');
      final m = <String, double>{};
      for (final r in rows) {
        final t = r['topic'] as String?;
        if (t == null) continue;
        m[t] = (r['score'] as num?)?.toDouble() ?? 0;
      }
      if (mounted) state = m;
    } catch (_) {
      // The app must be fully usable with this table empty or unreadable.
    }
  }

  /// Multiplies every score by [dailyDecay] once per calendar day.
  ///
  /// Done in SQL in one statement rather than row by row, and guarded by a
  /// stamp in user_meta so a chatty session cannot decay the profile ten times.
  Future<void> _decayIfDue(UserDatabase db) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.raw.query('user_meta',
        where: 'key = ?', whereArgs: ['interest_decay_on']);
    final last = rows.isEmpty ? null : rows.first['value'] as String?;
    if (last == today) return;
    await db.raw.rawUpdate(
        'UPDATE interest_signals SET score = score * ?', [dailyDecay]);
    await db.raw.insert(
        'user_meta', {'key': 'interest_decay_on', 'value': today},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  double scoreFor(String topic) => state[topic] ?? 0;

  /// Order [items] by interest, strongest first, keeping the original order
  /// among items we know nothing about.
  ///
  /// Stable by construction: with an empty table this returns the input
  /// unchanged, which is the behaviour the app must be fully usable under.
  List<T> rank<T>(List<T> items, String Function(T) topicOf) {
    if (state.isEmpty) return items;
    final indexed = items.indexed.toList();
    indexed.sort((a, b) {
      final d = scoreFor(topicOf(b.$2)).compareTo(scoreFor(topicOf(a.$2)));
      return d != 0 ? d : a.$1.compareTo(b.$1);
    });
    return indexed.map((e) => e.$2).toList();
  }

  /// True when [topic] is one of the few the ordering actually reacted to —
  /// used to decide whether a rail owes the reader a "why am I seeing this".
  bool isInfluential(String topic) => scoreFor(topic) >= bookmarkWeight;

  Future<void> record(String topic, double weight) async {
    if (topic.isEmpty || weight <= 0) return;
    final next = scoreFor(topic) + weight;
    state = {...state, topic: next};
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.insert(
        'interest_signals',
        {
          'topic': topic,
          'score': next,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // In memory is enough for this session; the signal is not precious.
    }
  }

  /// Empties the profile. Required, and must actually empty the table rather
  /// than hide it — a reset that only clears the view is a lie.
  Future<void> reset() async {
    state = const {};
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.delete('interest_signals');
      await db.raw.delete('user_meta',
          where: 'key = ?', whereArgs: ['interest_decay_on']);
    } catch (_) {
      // Nothing to clear.
    }
  }
}

final interestSignalsProvider =
    StateNotifierProvider<InterestSignals, Map<String, double>>(
        (ref) => InterestSignals(ref));
