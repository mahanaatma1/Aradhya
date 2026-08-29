import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../related/related_models.dart';
import '../related/related_rail.dart' show relatedProvider;
import '../search/search_models.dart';

/// Entity page's own presentation of `related_edges` — named vertical
/// sections ("Stories", "Temples", "Mantras", …) instead of `RelatedRail`'s
/// horizontal scroller. Reads the exact same `relatedProvider` and
/// `related_edges` data as every other screen that uses `RelatedRail`; only
/// the layout differs, so nothing here can show a connection the rail
/// wouldn't also show, and vice versa.
///
/// The entity page is the one place in the app meant to read as a person's
/// or deity's full profile — "Krishna: his stories, his temples, his
/// mantras" — rather than a card carousel of loosely-related content, which
/// is the right shape for a festival or a temple's own "continue exploring"
/// footer but flattens an entity page into one more content card.
class EntityRelatedSections extends ConsumerWidget {
  final int entityId;
  const EntityRelatedSections({super.key, required this.entityId});

  /// Section order: narrative and worship content first (what someone came
  /// to an entity page to find), reference/graph content last.
  static const _order = <String>[
    'story', 'scene', 'katha', 'temple', 'puja', 'mantra', 'aarti',
    'chalisa', 'shloka', 'festival', 'entity',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
            .watch(relatedProvider(
                (src: 'gyan', table: 'entities', id: entityId)))
            .valueOrNull ??
        const <RelatedItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;

    final groups = <String, List<RelatedItem>>{};
    for (final it in items) {
      (groups[it.dstKind] ??= []).add(it);
    }
    final orderedKinds = [
      for (final k in _order) if (groups.containsKey(k)) k,
      // Any kind not in the curated order still shows, just last, so a new
      // dst_kind added to relate.py later is never silently dropped here.
      for (final k in groups.keys) if (!_order.contains(k)) k,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final kind in orderedKinds)
            _NamedSection(
              kind: kind,
              items: groups[kind]!,
              hindi: hi,
              scheme: scheme,
              cats: cats,
            ),
        ],
      ),
    );
  }
}

class _NamedSection extends StatelessWidget {
  final String kind;
  final List<RelatedItem> items;
  final bool hindi;
  final ColorScheme scheme;
  final CategoryColors cats;
  const _NamedSection({
    required this.kind,
    required this.items,
    required this.hindi,
    required this.scheme,
    required this.cats,
  });

  /// Rows shown before folding the rest behind a "show more" — a profile
  /// section should read as a list, not force a reader to scroll past
  /// forty temples to reach the next heading.
  static const _visible = 4;

  @override
  Widget build(BuildContext context) {
    final ks = SearchKinds.of(kind);
    final style = ks.style(cats);
    return _CollapsibleSection(
      title: hindi ? ks.hi : ks.en,
      icon: ks.icon,
      accent: style.gradient.last,
      count: items.length,
      visible: _visible,
      children: [
        for (final it in items) _EntryRow(item: it, hindi: hindi),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final int count;
  final int visible;
  final List<Widget> children;
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.count,
    required this.visible,
    required this.children,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shown = _expanded
        ? widget.children
        : widget.children.take(widget.visible).toList();
    final hidden = widget.children.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.accent),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...shown,
          if (hidden > 0)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _expanded = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '+$hidden',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final RelatedItem item;
  final bool hindi;
  const _EntryRow({required this.item, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = item.subtitle(hindi);
    final label = item.relationLabel(hindi);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title(hindi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                ],
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded,
                size: 17, color: scheme.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
