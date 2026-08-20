import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../features/temples/passport_providers.dart';
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
    _backfill();
  }

  /// Temples marked visited before `temple_visits` existed live only in prefs,
  /// so the passport -- which reads the table -- never saw them. Copy anything
  /// the set knows about and the table does not, once, on first read.
  Future<void> _backfill() async {
    if (state.isEmpty) return;
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('temple_visits', columns: ['temple_id']);
      final known = {for (final r in rows) r['temple_id'] as int};
      final missing = state.difference(known);
      if (missing.isEmpty) return;
      final batch = db.raw.batch();
      for (final id in missing) {
        batch.insert(
          'temple_visits',
          {'temple_id': id, 'visited_at': null},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      _ref.invalidate(visitRecordsProvider);
    } catch (e) {
      debugPrint('VisitedController: backfill failed ($e)');
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

    // The passport reads temple_visits through this provider. Without the
    // invalidation it kept showing the list from app start, so a temple marked
    // visited never appeared in the visit log until a restart.
    _ref.invalidate(visitRecordsProvider);
  }
}

final visitedProvider =
    StateNotifierProvider<VisitedController, Set<int>>(
        (ref) => VisitedController(ref));
