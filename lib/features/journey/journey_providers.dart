import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';
import 'journey_models.dart';

final learningPathsProvider = FutureProvider<List<LearningPath>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.learning_paths ORDER BY order_no',
  );
  return rows.map(LearningPath.fromRow).toList();
});

final pathStepsProvider =
    FutureProvider.family<List<PathStep>, int>((ref, pathId) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.path_steps WHERE path_id = ? ORDER BY step_no',
    [pathId],
  );
  return rows.map(PathStep.fromRow).toList();
});

/// Completed `(pathId, stepNo)` pairs.
///
/// Progress is a **record, not a gate**. Steps stay open regardless: gating
/// scripture behind a progress mechanic is the wrong register for this app —
/// someone who opens it wanting to read the Gita today should be able to.
class PathProgress extends StateNotifier<Set<(int, int)>> {
  PathProgress(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('path_progress');
      if (!mounted) return;
      state = {
        for (final r in rows) (r['path_id'] as int, r['step_no'] as int),
      };
    } catch (e) {
      debugPrint('PathProgress: load failed ($e)');
    }
  }

  bool isDone(int pathId, int stepNo) => state.contains((pathId, stepNo));

  int completedIn(int pathId) =>
      state.where((e) => e.$1 == pathId).length;

  /// First incomplete step, or null when the path is finished.
  int? nextStep(int pathId, List<PathStep> steps) {
    for (final s in steps) {
      if (!isDone(pathId, s.stepNo)) return s.stepNo;
    }
    return null;
  }

  Future<void> markDone(int pathId, int stepNo) async {
    if (isDone(pathId, stepNo)) return;
    state = {...state, (pathId, stepNo)};
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.insert(
        'path_progress',
        {
          'path_id': pathId,
          'step_no': stepNo,
          'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('PathProgress: write failed ($e)');
    }
  }

  Future<void> clearPath(int pathId) async {
    state = {...state}..removeWhere((e) => e.$1 == pathId);
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw
          .delete('path_progress', where: 'path_id = ?', whereArgs: [pathId]);
    } catch (e) {
      debugPrint('PathProgress: clear failed ($e)');
    }
  }
}

final pathProgressProvider =
    StateNotifierProvider<PathProgress, Set<(int, int)>>(
        (ref) => PathProgress(ref));
