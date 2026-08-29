import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/interest_signals.dart';
import '../search/search_models.dart';
import 'related_models.dart';

final relatedProvider =
    FutureProvider.family<List<RelatedItem>, RelatedKey>((ref, key) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
    '''SELECT dst_src, dst_table, dst_id, dst_kind, reason, weight,
              title_en, title_hi, subtitle_en, subtitle_hi, route
       FROM gyan.related_edges
       WHERE src_src = ? AND src_table = ? AND src_id = ?
       ORDER BY weight DESC''',
    [key.src, key.table, key.id],
  );
  return rows.map(RelatedItem.fromRow).toList();
});

/// "Continue exploring" — the connective tissue between every detail screen.
///
/// Drop this at the bottom of any detail page. It renders nothing at all when
/// there are no edges, so it is safe to add everywhere without creating empty
/// sections on content that is not yet linked.
///
/// Because `related_edges` stores the title and route, this is one indexed
/// query and can paint on the first frame — no skeleton, no layout shift.
class RelatedRail extends ConsumerWidget {
  final String src;
  final String table;
  final int id;

  /// Hidden when the source item is itself the only thing in a group.
  final EdgeInsets padding;

  const RelatedRail({
    super.key,
    required this.table,
    required this.id,
    this.src = 'content',
    this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
            .watch(relatedProvider((src: src, table: table, id: id)))
            .valueOrNull ??
        const <RelatedItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;

    // Group by kind, preserving weight order within each group and ordering
    // the groups by their strongest member.
    final groups = <String, List<RelatedItem>>{};
    for (final it in items) {
      groups.putIfAbsent(it.dstKind, () => []).add(it);
    }
    // Which GROUP leads is the one place interest is allowed to act here.
    //
    // Strictly a tie-break, and only between kinds whose strongest edge is
    // effectively as strong. Nothing is added, removed or hidden — someone who
    // bookmarks temples sees temples first, and still sees every other kind
    // immediately beside them. With an empty profile this is a no-op.
    final interest = ref.watch(interestSignalsProvider.notifier);
    final orderedKinds = groups.keys.toList()
      ..sort((a, b) {
        final wa = groups[a]!.first.weight, wb = groups[b]!.first.weight;
        if ((wa - wb).abs() > 0.05) return wb.compareTo(wa);
        return interest.scoreFor(b).compareTo(interest.scoreFor(a));
      });

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 2,
                  color: scheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  hi ? 'और खोजें' : 'Continue exploring',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (final kind in orderedKinds)
            _KindGroup(kind: kind, items: groups[kind]!, hindi: hi),
        ],
      ),
    );
  }
}

class _KindGroup extends StatelessWidget {
  final String kind;
  final List<RelatedItem> items;
  final bool hindi;
  const _KindGroup(
      {required this.kind, required this.items, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ks = SearchKinds.of(kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            (hindi ? ks.hi : ks.en).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _RelatedCard(item: items[i], hindi: hindi),
          ),
        ),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final RelatedItem item;
  final bool hindi;
  const _RelatedCard({required this.item, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final ks = SearchKinds.of(item.dstKind);
    final style = ks.style(cats);
    final subtitle = item.subtitle(hindi);

    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: style.gradient.last.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: style.linear,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(ks.icon, size: 16, color: Colors.white),
                  ),
                  // NR-04: names the specific relation ("Guru", "Wields")
                  // when the edge carries one, instead of leaving every card
                  // to read as a generic "related entity". Absent for most
                  // edges (deity-name matches, verse mentions, …), which is
                  // correct — those aren't a named relation to state.
                  if (item.relationLabel(hindi) != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: style.gradient.last.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.relationLabel(hindi)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: style.gradient.last,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  item.title(hindi),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.24,
                  ),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: style.gradient.last.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
