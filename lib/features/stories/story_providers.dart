import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'story_models.dart';

final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('stories', orderBy: 'id');
  return rows.map(Story.fromRow).toList();
});

/// Vrat kathas, ordered by title.
///
/// This table has always been in the bundled database but nothing read it — the
/// `/katha` route served `stories`, so 57 kathas shipped invisibly.
final kathasProvider = FutureProvider<List<Story>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('kathas', orderBy: 'title_en');
  return rows.map(Story.fromKathaRow).toList();
});

/// Deity chips for the katha filter, ordered by how many kathas each has.
///
/// Derived rather than hardcoded, because the underlying `deity` column is
/// messy free text and a fixed list would silently drop anything that did not
/// match.
///
/// Two deliberate compromises, both visible in the raw data:
///
///  1. **Only deities with [_minKathas] or more get a chip.** Ungated, 24 chips
///     appear and 13 of them hold a single katha — a filter row that filters
///     nothing. The remainder are reachable through the "Other" chip.
///
///  2. **Epithets are not yet resolved to one deity.** `Damodara`, `Narayan`,
///     `Purushottam`, `Trivikrama`, `Vamana`, `Padmanabha` and `Satyanarayan`
///     are all names of Vishnu, so his true count is ~28 rather than 18 and
///     those appear as separate one-off entries. Collapsing them needs the
///     cited `entity_aliases` table from Phase 2 — guessing the mapping here,
///     in a UI provider, is exactly the kind of unsourced assertion the content
///     rules exist to prevent.
final kathaDeitiesProvider = FutureProvider<List<String>>((ref) async {
  final counts = await ref.watch(kathaDeityCountsProvider.future);
  final names = counts.entries
      .where((e) => e.value >= _minKathas)
      .map((e) => e.key)
      .toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return names;
});

/// Raw counts per primary deity, before the chip threshold is applied.
final kathaDeityCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final kathas = await ref.watch(kathasProvider.future);
  final counts = <String, int>{};
  for (final k in kathas) {
    final d = k.primaryDeity;
    if (d != null) counts[d] = (counts[d] ?? 0) + 1;
  }
  return counts;
});

/// Below this, a deity is folded into "Other" rather than getting its own chip.
const _minKathas = 2;
