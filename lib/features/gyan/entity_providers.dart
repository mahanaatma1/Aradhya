import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'entity_models.dart';

/// Entities of one kind, most important first.
///
/// `importance` ranks 1 (major) to 5 (minor), so a list of deities opens with
/// the ones a reader is looking for rather than alphabetically with a minor
/// gandharva.
final entitiesByKindProvider =
    FutureProvider.family<List<Entity>, String>((ref, kind) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.entities WHERE kind = ? '
    'ORDER BY importance ASC, title_en ASC',
    [kind],
  );
  return rows.map(Entity.fromRow).toList();
});

/// Every entity, for the graph and for pickers.
final allEntitiesProvider = FutureProvider<List<Entity>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.entities ORDER BY importance ASC, title_en ASC',
  );
  return rows.map(Entity.fromRow).toList();
});

final entityByIdProvider =
    FutureProvider.family<Entity?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw
      .rawQuery('SELECT * FROM gyan.entities WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : Entity.fromRow(rows.first);
});

/// Outbound edges, joined to their targets.
///
/// Only one direction is queried because `build.py` materialises the inverse of
/// every edge, so `src_id = ?` already sees the whole neighbourhood.
final entityRelationsProvider =
    FutureProvider.family<List<EntityRelation>, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery('''
    SELECT r.rel_type, r.dst_id, r.tradition, r.confidence,
           e.slug, e.title_en, e.title_hi, e.kind
    FROM gyan.relations r
    JOIN gyan.entities  e ON e.id = r.dst_id
    WHERE r.src_id = ?
    ORDER BY r.rel_type, e.importance, e.title_en
  ''', [id]);
  return rows.map(EntityRelation.fromRow).toList();
});

/// Aliases worth showing: the epithets and spellings, not the derived
/// transliterations already visible under the title.
final entityAliasesProvider =
    FutureProvider.family<List<String>, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    "SELECT alias FROM gyan.entity_aliases "
    "WHERE entity_id = ? AND alias_kind IN ('epithet','spelling','regional') "
    "ORDER BY alias_kind, alias",
    [id],
  );
  return rows.map((r) => r['alias'] as String).toList();
});

/// How many entities exist per kind — used to hide empty encyclopedia tiles.
final entityKindCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const {};
  final rows = await db.raw
      .rawQuery('SELECT kind, COUNT(*) n FROM gyan.entities GROUP BY kind');
  return {for (final r in rows) r['kind'] as String: r['n'] as int};
});
