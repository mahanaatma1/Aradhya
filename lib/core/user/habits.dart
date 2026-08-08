import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/user_database.dart';
import 'streak.dart';
import 'user_prefs.dart';

/// A daily spiritual practice the user can check off.
class Habit {
  final String key;
  final String labelEn;
  final String labelHi;
  final IconData icon;
  const Habit(this.key, this.labelEn, this.labelHi, this.icon);

  String label(bool hi) => hi ? labelHi : labelEn;
}

/// The fixed starter set of daily sadhana habits.
const kHabits = <Habit>[
  Habit('meditate', 'Meditation', 'ध्यान', Icons.self_improvement_rounded),
  Habit('scripture', 'Read scripture', 'शास्त्र पाठ', Icons.menu_book_rounded),
  Habit('japa', 'Japa / chanting', 'जप', Icons.grain_rounded),
  Habit('pranayama', 'Pranayama', 'प्राणायाम', Icons.air_rounded),
  Habit('gratitude', 'Gratitude', 'कृतज्ञता', Icons.favorite_rounded),
  Habit('seva', 'Seva / kindness', 'सेवा', Icons.volunteer_activism_rounded),
];

/// Today's completed habit keys.
class HabitsController extends StateNotifier<Set<String>> {
  HabitsController(this._ref) : super(const {}) {
    final p = _ref.read(sharedPrefsProvider);
    final raw = p.getString(PrefKeys.habitsPrefix + dayStamp());
    if (raw != null) {
      state = (jsonDecode(raw) as List).map((e) => e as String).toSet();
    }
  }

  final Ref _ref;

  Future<void> toggle(String key) async {
    final next = Set<String>.from(state);
    final wasDone = next.contains(key);
    if (wasDone) {
      next.remove(key);
    } else {
      next.add(key);
      await _ref.read(streakProvider.notifier).addPoints(2);
    }
    state = next;

    final today = dayStamp();

    // Durable history. The prefs scheme wrote one key per day *forever*, which
    // is an unbounded key-space leak; here a day is just rows, and the Sadhana
    // tracker can query across dates instead of enumerating preference keys.
    final db = _ref.read(userDatabaseProvider);
    if (db != null) {
      try {
        if (wasDone) {
          await db.raw.delete('sadhana_sessions',
              where: 'day_stamp = ? AND practice = ?',
              whereArgs: [today, 'habit:$key']);
        } else {
          await db.raw.insert('sadhana_sessions', {
            'day_stamp': today,
            'practice': 'habit:$key',
            'count': 1,
            'duration_s': 0,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        debugPrint('HabitsController: write failed ($e)');
      }
    }

    // Today's key is still mirrored so a rollback keeps the current day intact.
    final p = _ref.read(sharedPrefsProvider);
    await p.setString(PrefKeys.habitsPrefix + today, jsonEncode(next.toList()));
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsController, Set<String>>(
        (ref) => HabitsController(ref));
