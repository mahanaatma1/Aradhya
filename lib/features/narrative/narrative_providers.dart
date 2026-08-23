import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'narrative_models.dart';

/// War days are a sub-view of the Mahabharata: eighteen near-identical rows that
/// would bury the twenty events carrying the story. Every query behind the epic
/// screens leaves them out the same way, so the predicate is written once — and
/// the facet counts cannot drift from the list they describe.
///
/// Assumes `narrative_nodes` is aliased `n`.
const _notWarDay = "(n.tags IS NULL OR n.tags NOT LIKE '%war-day%')";

/// Every scene of one epic, in narrative order.
final epicScenesProvider =
    FutureProvider.family<List<NarrativeNode>, String>((ref, epic) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    "SELECT n.* FROM gyan.narrative_nodes n "
    "WHERE n.epic = ? AND $_notWarDay "
    "ORDER BY n.sequence_no",
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

/// One value a reader can cut an epic by: a character, or a place, with the
/// events it covers (SC-13).
///
/// The node ids travel with the label rather than a bare count, so the chip's
/// number and the list it filters to come from the same fact. A chip that says
/// eighteen and then shows twelve is worse than no chip.
class EpicFacetValue {
  final int entityId;
  final String titleEn;
  final String? titleHi;
  final Set<int> nodeIds;

  const EpicFacetValue({
    required this.entityId,
    required this.titleEn,
    required this.nodeIds,
    this.titleHi,
  });

  String title(bool hindi) =>
      (hindi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
}

/// Folds `(entity, node)` pairs into one value per entity, most-present first.
///
/// Ordered by how many events the value covers, then alphabetically: forty-five
/// figures appear in the Ramayana, and a reader looking for Rama should not swipe
/// past thirty walk-on parts to reach him. The alphabetical tiebreak keeps the
/// row from reshuffling between builds.
List<EpicFacetValue> _foldFacet(List<Map<String, Object?>> rows) {
  final nodes = <int, Set<int>>{};
  final names = <int, (String, String?)>{};
  for (final r in rows) {
    final entity = r['entity_id'] as int?;
    final node = r['node_id'] as int?;
    if (entity == null || node == null) continue;
    nodes.putIfAbsent(entity, () => <int>{}).add(node);
    names[entity] ??= ((r['title_en'] as String?) ?? '', r['title_hi'] as String?);
  }

  final out = <EpicFacetValue>[
    for (final e in nodes.entries)
      // An entity with no English title has no label to put on a chip. It is not
      // dropped from the epic — only from this row.
      if (names[e.key]!.$1.isNotEmpty)
        EpicFacetValue(
          entityId: e.key,
          titleEn: names[e.key]!.$1,
          titleHi: names[e.key]!.$2,
          nodeIds: e.value,
        ),
  ];
  out.sort((a, b) {
    final byCount = b.nodeIds.length.compareTo(a.nodeIds.length);
    return byCount != 0 ? byCount : a.titleEn.compareTo(b.titleEn);
  });
  return out;
}

/// The figures of one epic, each with the events they appear in (SC-13).
///
/// The inverse of [sceneCastProvider]: that one asks who is in a scene, this asks
/// which scenes someone is in.
final epicCastFacetProvider =
    FutureProvider.family<List<EpicFacetValue>, String>((ref, epic) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery('''
    SELECT c.entity_id, c.node_id, e.title_en, e.title_hi
    FROM gyan.narrative_cast c
    JOIN gyan.entities e ON e.id = c.entity_id
    JOIN gyan.narrative_nodes n ON n.id = c.node_id
    WHERE n.epic = ? AND $_notWarDay
  ''', [epic]);
  return _foldFacet(rows);
});

/// The places of one epic, each with the events set there (SC-13).
///
/// Sparser than the cast by a long way — most events carry no place yet, which is
/// RM-02's job to finish. The chip row states the shortfall rather than presenting
/// a handful of places as though they were the whole geography.
final epicPlaceFacetProvider =
    FutureProvider.family<List<EpicFacetValue>, String>((ref, epic) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery('''
    SELECT e.id AS entity_id, n.id AS node_id, e.title_en, e.title_hi
    FROM gyan.narrative_nodes n
    JOIN gyan.entities e ON e.id = n.place_entity_id
    WHERE n.epic = ? AND $_notWarDay
  ''', [epic]);
  return _foldFacet(rows);
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
