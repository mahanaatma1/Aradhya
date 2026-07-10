import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'temple_models.dart';

final templesProvider = FutureProvider<List<Temple>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('temples', orderBy: 'id');
  return rows.map(Temple.fromRow).toList();
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
