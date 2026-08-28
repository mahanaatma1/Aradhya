import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'temple_models.dart';

final templesProvider = FutureProvider<List<Temple>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('temples', orderBy: 'id');
  return rows.map(Temple.fromRow).toList();
});

/// Great-circle distance in km (TM-02). 187 temples is small enough to rank
/// in memory rather than reach for a spatial index — the same reasoning
/// `AskRepository` gives for scoring `qa_pairs` in Dart instead of SQL.
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// The nearest other temples to [templeId], by real coordinates rather than
/// the hand-written `nearbyTemples` free text some legacy rows carry (which
/// is prose, not a route to anything, and absent on rows that never had it
/// written). Temples without both coordinates are skipped on both ends —
/// silently, since distance to an unknown point is not a fact to state.
final nearbyTemplesProvider =
    FutureProvider.family<List<(Temple, double)>, int>((ref, templeId) async {
  final all = await ref.watch(templesProvider.future);
  Temple? origin;
  for (final t in all) {
    if (t.id == templeId) {
      origin = t;
      break;
    }
  }
  if (origin == null || origin.lat == null || origin.lon == null) {
    return const [];
  }
  final withDist = <(Temple, double)>[];
  for (final t in all) {
    if (t.id == templeId || t.lat == null || t.lon == null) continue;
    withDist.add(
        (t, _haversineKm(origin.lat!, origin.lon!, t.lat!, t.lon!)));
  }
  withDist.sort((a, b) => a.$2.compareTo(b.$2));
  return withDist.take(5).toList();
});

/// The most common primary tags, for the filter chips (kept short so the bar
/// stays usable across 187 temples with many niche tags).
final templeFiltersProvider = FutureProvider<List<String>>((ref) async {
  final temples = await ref.watch(templesProvider.future);
  final counts = <String, int>{};
  for (final tmp in temples) {
    for (final tag in tmp.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(8).map((e) => e.key).toList();
});
