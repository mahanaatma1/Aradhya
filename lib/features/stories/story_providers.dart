import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'story_models.dart';

final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.stories ORDER BY order_no, id',
  );
  return rows.map(Story.fromRow).toList();
});

/// Vrat kathas, ordered by title.
///
/// Reads `gyan.kathas` (158 rows), not the Ishvarvaani fixture's 57. Every
/// festival in `gyan.festivals` has one, and each carries its own fast
/// instructions, key moments and sources — none of which the fixture had.
final kathasProvider = FutureProvider<List<Story>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery(
    'SELECT * FROM gyan.kathas ORDER BY title_en',
  );
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

/// Stories and kathas as one collection, stories first (ST-01).
///
/// A merge of the two lists, not a third table: each [Story] already carries
/// [Story.kind], so the combined list can still be split, filtered or tagged
/// by kind without a second query. Ordering keeps stories (already ordered by
/// `id`, roughly narrative/curated order) ahead of kathas (already ordered by
/// title) rather than interleaving them, since a shuffled combined order
/// would make "browse everything" read as random rather than categorised.
final allStoriesProvider = FutureProvider<List<Story>>((ref) async {
  final stories = await ref.watch(storiesProvider.future);
  final kathas = await ref.watch(kathasProvider.future);
  return [...stories, ...kathas];
});
