import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/visited.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/skeleton.dart';
import 'temple_map.dart';
import 'temple_models.dart';
import 'temple_providers.dart';
import 'temple_style.dart';

/// A curated directory filter (label + a test over a temple's tags).
class _Filter {
  final String en;
  final String hi;
  final bool Function(Temple)? test; // null = All
  const _Filter(this.en, this.hi, this.test);
}

final _filters = <_Filter>[
  const _Filter('All', 'सभी', null),
  _Filter('Char Dham', 'चार धाम',
      (t) => t.tags.any((x) => x.contains('char_dham'))),
  _Filter('Jyotirlingas', 'ज्योतिर्लिंग',
      (t) => t.tags.any((x) => x.contains('jyotirlinga'))),
  _Filter('Shakti Peethas', 'शक्ति पीठ',
      (t) => t.tags.any((x) => x.contains('shakti'))),
  _Filter('Healing', 'रोगनाशक',
      (t) => t.tags.any((x) => x.contains('healing') || x.contains('ailment'))),
];

/// Yatra — the temple directory. Custom header, pill search, curated filters
/// and rotating-tint cards, matching the reference app.
class TemplesScreen extends ConsumerStatefulWidget {
  const TemplesScreen({super.key});

  @override
  ConsumerState<TemplesScreen> createState() => _TemplesScreenState();
}

class _TemplesScreenState extends ConsumerState<TemplesScreen> {
  String _query = '';
  int _filterIdx = 0;
  bool _visitedOnly = false;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final temples = ref.watch(templesProvider);
    final visited = ref.watch(visitedProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: AsyncView(
          value: temples,
          isEmpty: (l) => l.isEmpty,
          emptyMessage: hi ? 'कोई मंदिर नहीं' : 'No temples',
          loading: const SkeletonTempleCards(),
          builder: (list) {
            final q = _query.trim().toLowerCase();
            final active = _filters[_filterIdx];
            final filtered = list.where((t) {
              final matchFilter = active.test == null || active.test!(t);
              final matchVisited = !_visitedOnly || visited.contains(t.id);
              final matchQuery = q.isEmpty ||
                  t.nameEn.toLowerCase().contains(q) ||
                  (t.deityEn ?? '').toLowerCase().contains(q) ||
                  (t.state ?? '').toLowerCase().contains(q) ||
                  (t.district ?? '').toLowerCase().contains(q);
              return matchFilter && matchVisited && matchQuery;
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(count: list.length, hi: hi),
                ),
                SliverToBoxAdapter(child: _SearchBar(
                  hi: hi,
                  onChanged: (v) => setState(() => _query = v),
                )),
                SliverToBoxAdapter(
                  child: _FilterBar(
                    hi: hi,
                    selected: _filterIdx,
                    visitedOnly: _visitedOnly,
                    onSelect: (i) => setState(() => _filterIdx = i),
                    onVisited: () =>
                        setState(() => _visitedOnly = !_visitedOnly),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Text(hi ? 'कुछ नहीं मिला' : 'Nothing found',
                            style: TextStyle(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, i) => _TempleCard(
                        temple: filtered[i],
                        hi: hi,
                        visited: visited.contains(filtered[i].id),
                        onTap: () =>
                            context.push('/temple', extra: filtered[i]),
                        onToggleVisited: () => ref
                            .read(visitedProvider.notifier)
                            .toggle(filtered[i].id),
                        onMap: () => _openMap(context, filtered[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openMap(BuildContext context, Temple t) async {
  final ok = await openTempleMap(t);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the map for this temple')),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool hi;
  const _Header({required this.count, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: scheme.primary, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.temple_hindu_rounded,
                color: Color(0xFFFFF8EF), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hi ? 'मंदिर निर्देशिका' : 'Temple Directory',
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 24)),
                Text(
                    hi
                        ? '$count मंदिर · भारत भर में'
                        : '$count temples · across India',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool hi;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hi, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(28),
        color: scheme.surface,
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hi
                ? 'मंदिर, देवता, स्थान खोजें…'
                : 'Search temples, deities, locations…',
            prefixIcon: Icon(Icons.search_rounded, color: scheme.secondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final bool hi;
  final int selected;
  final bool visitedOnly;
  final ValueChanged<int> onSelect;
  final VoidCallback onVisited;
  const _FilterBar({
    required this.hi,
    required this.selected,
    required this.visitedOnly,
    required this.onSelect,
    required this.onVisited,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (var i = 0; i < _filters.length; i++)
            _Pill(
              label: hi ? _filters[i].hi : _filters[i].en,
              selected: i == selected && !visitedOnly,
              onTap: () => onSelect(i),
            ),
          _Pill(
            label: hi ? 'गए हुए' : 'Visited',
            selected: visitedOnly,
            onTap: onVisited,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? AppColors.gold : scheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? AppColors.gold
                : scheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFFFFF8EF)
                          : scheme.onSurface.withValues(alpha: 0.8))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Editorial-cover temple card: a full gradient cover with a temple-icon
/// watermark, category + Visited pills and the name overlaid, then a
/// quick-facts strip (Established · Entry · Best time) and a location footer.
class _TempleCard extends StatelessWidget {
  final Temple temple;
  final bool hi;
  final bool visited;
  final VoidCallback onTap;
  final VoidCallback onToggleVisited;
  final VoidCallback onMap;
  const _TempleCard({
    required this.temple,
    required this.hi,
    required this.visited,
    required this.onTap,
    required this.onToggleVisited,
    required this.onMap,
  });

  List<(String, String)> _facts() {
    final out = <(String, String)>[];
    final y = establishedYear(temple.foundingEraEn);
    if (y != null) out.add((hi ? 'स्थापना' : 'Established', y));
    if (temple.entryFee(hi) != null) {
      final free = temple.entryFeeEn?.toLowerCase().contains('free') ?? false;
      out.add((hi ? 'प्रवेश' : 'Entry',
          free ? (hi ? 'नि:शुल्क' : 'Free') : (hi ? 'सशुल्क' : 'Paid')));
    }
    final s = shortSeason(temple.bestSeasonEn);
    if (s != null) out.add((hi ? 'सर्वोत्तम' : 'Best time', s));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = templeTint(temple);
    final coverLight = Color.lerp(tint, Colors.white, 0.06)!;
    final coverDark = Color.lerp(tint, Colors.black, 0.5)!;
    final facts = _facts();

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.55, -0.85),
                          radius: 1.45,
                          colors: [coverLight, coverDark],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -22,
                    bottom: -34,
                    child: Icon(Icons.temple_hindu_rounded,
                        size: 188, color: Colors.white.withValues(alpha: 0.13)),
                  ),
                  if (temple.tags.isNotEmpty)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _CoverPill(text: tagLabel(temple.primaryTag)),
                    ),
                  Positioned(
                    right: 12,
                    top: 11,
                    child: _VisitedPill(
                        visited: visited,
                        hi: hi,
                        onTap: onToggleVisited,
                        onCover: true),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(temple.name(hi),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                height: 1.12,
                                color: Color(0xFFFFF6EE))),
                        if (temple.deity(hi) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(temple.deity(hi)!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFFFBE6D6))),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick-facts strip
            if (facts.isNotEmpty)
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < facts.length; i++) ...[
                      if (i > 0)
                        VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: scheme.outline.withValues(alpha: 0.14)),
                      Expanded(child: _FactCell(label: facts[i].$1, value: facts[i].$2)),
                    ],
                  ],
                ),
              ),
            Divider(
                height: 1, thickness: 1,
                color: scheme.outline.withValues(alpha: 0.14)),

            // Location + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 18, color: AppColors.gold),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      temple.place.isNotEmpty
                          ? temple.place
                          : (temple.locationEn ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onMap,
                    icon: Icon(Icons.map_rounded, size: 18, color: AppColors.gold),
                    label: Text(hi ? 'नक्शा' : 'Map',
                        style: const TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  final String label;
  final String value;
  const _FactCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: scheme.primary)),
          const SizedBox(height: 1),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _CoverPill extends StatelessWidget {
  final String text;
  const _CoverPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFF6EE))),
    );
  }
}

class _VisitedPill extends StatelessWidget {
  final bool visited;
  final bool hi;
  final VoidCallback onTap;
  final bool onCover;
  const _VisitedPill(
      {required this.visited,
      required this.hi,
      required this.onTap,
      this.onCover = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const cream = Color(0xFFFFF6EE);
    final Color bg, fg, border;
    if (onCover) {
      bg = visited ? cream : Colors.white.withValues(alpha: 0.14);
      fg = visited ? scheme.primary : cream;
      border = cream;
    } else {
      bg = visited ? scheme.primary : scheme.surface;
      fg = visited ? scheme.onPrimary : scheme.primary;
      border = scheme.primary;
    }
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border, width: 1.4)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visited) ...[
                Icon(Icons.check_rounded, size: 15, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                visited
                    ? (hi ? 'गए' : 'Visited')
                    : (hi ? 'चिह्नित करें' : 'Mark Visited'),
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
