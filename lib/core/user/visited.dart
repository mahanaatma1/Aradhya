import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/user_database.dart';
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
    final wasVisited = next.contains(id);
    wasVisited ? next.remove(id) : next.add(id);
    state = next;

    // The set alone could never answer "when did I visit Kedarnath?" — the
    // Yatra history needs a date, so marking a visit now records one.
    final db = _ref.read(userDatabaseProvider);
    if (db != null) {
      try {
        if (wasVisited) {
          await db.raw
              .delete('temple_visits', where: 'temple_id = ?', whereArgs: [id]);
        } else {
          await db.raw.insert(
            'temple_visits',
            {
              'temple_id': id,
              'visited_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (e) {
        debugPrint('VisitedController: write failed ($e)');
      }
    }

    final p = _ref.read(sharedPrefsProvider);
    await p.setString(PrefKeys.templesVisited, jsonEncode(next.toList()));
  }
}

final visitedProvider =
    StateNotifierProvider<VisitedController, Set<int>>(
        (ref) => VisitedController(ref));
