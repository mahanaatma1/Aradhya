import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'narrative_models.dart';

/// Every scene of one epic, in narrative order.
///
/// War days are excluded: they are a sub-view of the Mahabharata, and folding
/// eighteen of them into the main timeline would bury the twenty events that
/// carry the story.
final epicScenesProvider =
    FutureProvider.family<List<NarrativeNode>, String>((ref, epic) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    "SELECT * FROM gyan.narrative_nodes "
    "WHERE epic = ? AND (tags IS NULL OR tags NOT LIKE '%war-day%') "
    "ORDER BY sequence_no",
    [epic],
  );
  return rows.map(NarrativeNode.fromRow).toList();
});

/// The eighteen days of Kurukshetra, in order.
final warDaysProvider = FutureProvider<List<NarrativeNode>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    "SELECT * FROM gyan.narrative_nodes "
    "WHERE epic = 'mahabharata' AND tags LIKE '%war-day%' "
    "ORDER BY sequence_no",
  );
  return rows.map(NarrativeNode.fromRow).toList();
});

/// Which Kaurava commander led on a given day, read from the `commander:` tag.
///
/// Stored as a tag rather than a column because it is the only per-day fact
/// that groups days, and a column on narrative_nodes would be null for every
/// scene that is not a war day.
String commanderOf(NarrativeNode day) {
  final m = RegExp(r'commander:([a-z]+)').firstMatch(day.tagsRaw ?? '');
  return m?.group(1) ?? '';
}

final sceneByIdProvider =
    FutureProvider.family<NarrativeNode?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.narrative_nodes WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : NarrativeNode.fromRow(rows.first);
});

/// The figures in a scene, joined to their entities so each is tappable.
final sceneCastProvider =
    FutureProvider.family<List<CastMember>, int>((ref, nodeId) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery('''
    SELECT c.entity_id, c.role, e.title_en, e.title_hi, e.kind
    FROM gyan.narrative_cast c
    JOIN gyan.entities e ON e.id = c.entity_id
    WHERE c.node_id = ?
    ORDER BY CASE c.role
               WHEN 'protagonist' THEN 0
               WHEN 'antagonist'  THEN 1
               ELSE 2 END,
             e.importance
  ''', [nodeId]);
  return rows.map(CastMember.fromRow).toList();
});

/// Scenes the reader has opened, so the path can show what has been walked.
///
/// Stored as reading progress against a synthetic book id per epic — reusing
/// the table the scripture reader already uses rather than inventing a second
/// progress store for the same idea.
class EpicProgress extends StateNotifier<Set<int>> {
  EpicProgress(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('sadhana_sessions',
          where: "practice = 'scene'", columns: ['meta']);
      final ids = <int>{};
      for (final r in rows) {
        final m = RegExp(r'"scene"\s*:\s*(\d+)')
            .firstMatch((r['meta'] as String?) ?? '');
        final id = int.tryParse(m?.group(1) ?? '');
        if (id != null) ids.add(id);
      }
      if (mounted) state = ids;
    } catch (_) {
      // Progress is a nicety here; the epics read fine without it.
    }
  }

  bool isRead(int sceneId) => state.contains(sceneId);

  Future<void> markRead(int sceneId) async {
    if (state.contains(sceneId)) return;
    state = {...state, sceneId};
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.insert('sadhana_sessions', {
        'day_stamp': dayStamp(),
        'practice': 'scene',
        'count': 1,
        'duration_s': 0,
        'meta': '{"scene":$sceneId}',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Already reflected in memory; a failed write only loses the record.
    }
  }

  int readCountIn(List<NarrativeNode> scenes) =>
      scenes.where((s) => state.contains(s.id)).length;

  /// First unread scene, for the "Continue" pill.
  NarrativeNode? nextIn(List<NarrativeNode> scenes) {
    for (final s in scenes) {
      if (!state.contains(s.id)) return s;
    }
    return null;
  }
}

final epicProgressProvider =
    StateNotifierProvider<EpicProgress, Set<int>>((ref) => EpicProgress(ref));
