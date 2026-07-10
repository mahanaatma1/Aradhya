import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_prefs.dart';

/// Set of temple ids the user has marked as visited (Yatra tracking).
class VisitedController extends StateNotifier<Set<int>> {
  VisitedController(this._ref) : super(const {}) {
    final p = _ref.read(sharedPrefsProvider);
    final raw = p.getString(PrefKeys.templesVisited);
    if (raw != null) {
      state = (jsonDecode(raw) as List).map((e) => e as int).toSet();
    }
  }

  final Ref _ref;

  Future<void> toggle(int id) async {
    final next = Set<int>.from(state);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    final p = _ref.read(sharedPrefsProvider);
    await p.setString(PrefKeys.templesVisited, jsonEncode(next.toList()));
  }
}

final visitedProvider =
    StateNotifierProvider<VisitedController, Set<int>>(
        (ref) => VisitedController(ref));
