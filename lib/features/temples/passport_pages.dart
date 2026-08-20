import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'passport_providers.dart';
import 'passport_sections.dart';
import 'passport_stamp.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC08A2E);
const _ink = Color(0xFF3A2A18);

/// The whole journey, oldest visit at the bottom.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final visited = ref.watch(visitedTemplesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'यात्रा वृत्तांत' : 'Yatra Journey')),
      body: visited.isEmpty
          ? Center(
              child: Text(hi ? 'अभी कोई यात्रा नहीं' : 'No visits yet',
                  style: TextStyle(color: _accent.withValues(alpha: 0.8))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: [
                Text(
                  hi
                      ? '${visited.length} दर्शन'
                      : '${visited.length} darshan recorded',
                  style: TextStyle(
                    fontSize: 12,
                    color: _accent.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                JourneyTimeline(entries: visited, hindi: hi),
              ],
            ),
    );
  }
}

/// Every collection, with how much of each is done.
class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'संग्रह' : 'Collections')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          for (final c in kCollections) _CollectionRow(collection: c, hindi: hi),
        ],
      ),
    );
  }
}

/// One collection row.
///
/// The count reads "visited / in the tradition". Where the app holds more
/// temples carrying a tag than the tradition names -- Char Dham is the usual
/// case, since the term covers both the Himalayan four and the national four
/// -- the extra is spelled out rather than left as a nonsensical 5 of 4.
class _CollectionRow extends ConsumerWidget {
  final Collection collection;
  final bool hindi;
  const _CollectionRow({required this.collection, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list =
        ref.watch(collectionProvider(collection.tag)).valueOrNull ?? const [];
    final held = list.length;
    final done = list.where((e) => e.visited).length;
    final canonical = collection.canonical;
    final complete = canonical > 0 && done >= canonical;
    final extra = held > canonical ? held - canonical : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StitchedCard(
        radius: 16,
        background: complete ? _gold.withValues(alpha: 0.12) : kPaper,
        stitchColor: _gold.withValues(alpha: complete ? 0.8 : 0.45),
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/passport/${collection.tag}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title(hindi),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hindi
                        ? '$done / $canonical दर्शन'
                        : '$done / $canonical visited',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _accent.withValues(alpha: 0.9),
                    ),
                  ),
                  if (extra > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      hindi
                          ? '$canonical पारंपरिक + $extra अन्य दर्शन'
                          : '$canonical traditional + $extra additional darshan',
                      style: TextStyle(
                        fontSize: 11,
                        color: _accent.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (complete) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 14, color: _gold),
                        const SizedBox(width: 4),
                        Text(
                          hindi ? 'पूर्ण' : 'Completed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: _accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// Every milestone, earned and not.
class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'उपलब्धियाँ' : 'Milestones')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          Text(
            hi
                ? 'हर उपलब्धि एक वास्तविक पहली बार है — कोई अंक नहीं।'
                : 'Each one marks a real first. There are no points here.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: _accent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          const MilestoneRail(),
        ],
      ),
    );
  }
}
