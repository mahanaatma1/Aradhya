import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_prefs.dart';

/// Daily-streak + the two currencies.
/// - [punya]: lifetime merit — earned by every practice, never spent. A score.
/// - [kamal]: a spendable wallet — earned alongside punya, spent on Mandir
///   offerings outside the free offering windows.
class StreakState {
  final int days;
  final int punya;
  final int kamal;
  const StreakState(
      {required this.days, required this.punya, required this.kamal});
}

class StreakController extends StateNotifier<StreakState> {
  StreakController(this._ref)
      : super(const StreakState(days: 0, punya: 0, kamal: 0)) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final p = _ref.read(sharedPrefsProvider);
    state = StreakState(
      days: p.getInt(PrefKeys.streakCount) ?? 0,
      punya: p.getInt(PrefKeys.points) ?? 0,
      // Seed a little Kamal for existing users so offerings work day one.
      kamal: p.getInt(PrefKeys.kamal) ?? 10,
    );
  }

  /// Call on app open / first activity of the session. Rolls the streak
  /// forward for a new day, resets it if a day was missed, and awards currency.
  Future<void> pingToday() async {
    final p = _ref.read(sharedPrefsProvider);
    final last = p.getString(PrefKeys.streakLast) ?? '';
    final today = dayStamp();
    if (last == today) return; // already counted today

    final gap = dayGap(last, today);
    final newDays = (gap == 1) ? state.days + 1 : 1;

    await p.setString(PrefKeys.streakLast, today);
    await p.setInt(PrefKeys.streakCount, newDays);
    state = StreakState(days: newDays, punya: state.punya, kamal: state.kamal);
    await earn(5); // 5 punya + 5 kamal per active day
  }

  /// Earn currency for an in-app achievement (quiz, japa mala, habit, daily
  /// visit…). Both merit (punya) and wallet (kamal) go up together.
  Future<void> earn(int n) async {
    final p = _ref.read(sharedPrefsProvider);
    final punya = state.punya + n;
    final kamal = state.kamal + n;
    await p.setInt(PrefKeys.points, punya);
    await p.setInt(PrefKeys.kamal, kamal);
    state = StreakState(days: state.days, punya: punya, kamal: kamal);
  }

  /// Backwards-compatible alias — earns both currencies.
  Future<void> addPoints(int n) => earn(n);

  /// Spend Kamal (Mandir offerings). Returns false and changes nothing if the
  /// balance is insufficient. Punya (merit) is never spent.
  Future<bool> spendKamal(int n) async {
    if (state.kamal < n) return false;
    final p = _ref.read(sharedPrefsProvider);
    final kamal = state.kamal - n;
    await p.setInt(PrefKeys.kamal, kamal);
    state = StreakState(days: state.days, punya: state.punya, kamal: kamal);
    return true;
  }
}

final streakProvider =
    StateNotifierProvider<StreakController, StreakState>(
        (ref) => StreakController(ref));
