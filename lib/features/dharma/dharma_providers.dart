import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'dharma_models.dart';

final dharmaScenariosProvider =
    FutureProvider<List<DharmaScenario>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.dharma_scenarios ORDER BY difficulty, title_en');
  return rows.map(DharmaScenario.fromRow).toList();
});

final dharmaScenarioProvider =
    FutureProvider.family<DharmaScenario?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.dharma_scenarios WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : DharmaScenario.fromRow(rows.first);
});

final dharmaChoicesProvider =
    FutureProvider.family<List<DharmaChoice>, int>((ref, scenarioId) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.dharma_choices WHERE scenario_id = ? ORDER BY order_no',
      [scenarioId]);
  return rows.map(DharmaChoice.fromRow).toList();
});

/// The scenario of the day.
///
/// Day-of-year modulo, so it is stable for a whole day and needs no storage —
/// the same trick the verse of the day uses.
final dharmaOfTheDayProvider = FutureProvider<DharmaScenario?>((ref) async {
  final all = await ref.watch(dharmaScenariosProvider.future);
  if (all.isEmpty) return null;
  final now = DateTime.now();
  final doy = now.difference(DateTime(now.year, 1, 1)).inDays;
  return all[doy % all.length];
});

/// Which scenarios have been reflected on.
///
/// A dharma reflection IS a journal entry — the plan makes 4.11 and 4.17 share
/// one history rather than inventing a second store for the same idea.
class DharmaProgress extends StateNotifier<Set<int>> {
  DharmaProgress(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('journal_entries',
          where: 'prompt_id IS NOT NULL AND tags LIKE ?',
          whereArgs: ['%dharma%'],
          columns: ['prompt_id']);
      final ids = <int>{};
      for (final r in rows) {
        final id = r['prompt_id'] as int?;
        if (id != null) ids.add(id);
      }
      if (mounted) state = ids;
    } catch (_) {
      // Progress is a nicety; the scenarios read fine without it.
    }
  }

  bool isDone(int scenarioId) => state.contains(scenarioId);

  int doneIn(List<DharmaScenario> list) =>
      list.where((s) => state.contains(s.id)).length;

  /// Records a reflection as a journal entry.
  ///
  /// The chosen option is stored as part of the body, not as a result: there is
  /// nothing to be right about, so there is no answer key to save.
  Future<void> record(DharmaScenario s, DharmaChoice c,
      {required bool hindi}) async {
    state = {...state, s.id};
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    final now = DateTime.now();
    try {
      await db.raw.insert('journal_entries', {
        'day_stamp': dayStamp(),
        'prompt_id': s.id,
        'prompt_text': s.title(hindi),
        'body': c.label(hindi),
        'tags': 'dharma',
        'is_private': 1,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
    } catch (_) {
      // Already reflected in memory; a failed write only loses the record.
    }
  }
}

final dharmaProgressProvider =
    StateNotifierProvider<DharmaProgress, Set<int>>((ref) => DharmaProgress(ref));
