import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'cosmology_models.dart';

/// Nodes of one track, in their given order.
final cosmologyTrackProvider =
    FutureProvider.family<List<CosmologyNode>, String>((ref, track) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.cosmology_nodes WHERE track = ? ORDER BY order_no',
    [track],
  );
  return rows.map(CosmologyNode.fromRow).toList();
});

final cosmologyNodeProvider =
    FutureProvider.family<CosmologyNode?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.cosmology_nodes WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : CosmologyNode.fromRow(rows.first);
});

/// The four yugas, longest first — which is also their traditional order.
final yugasProvider = FutureProvider<List<CosmologyNode>>(
    (ref) => ref.watch(cosmologyTrackProvider('yuga').future));

/// Time units from a mahayuga up to the life of Brahma, each nesting in the
/// next. Used by the "zoom out" section of the Yuga Explorer.
final timeCyclesProvider = FutureProvider<List<CosmologyNode>>(
    (ref) => ref.watch(cosmologyTrackProvider('time_cycle').future));
