import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/components/components.dart' hide AsyncView;
import '../../ui/tokens/tokens.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/visited.dart';
import '../../shared/widgets/async_view.dart';
import 'temple_illustrations.dart';
import 'temple_map.dart';
import 'temple_models.dart';
import 'temple_providers.dart';

/// A curated directory filter (label + a test over a temple's tags).
class _Filter {
  final String en;
  final String hi;
  final IconData icon;
  final bool Function(Temple)? test; // null = All
  const _Filter(this.en, this.hi, this.icon, this.test);
}

final _filters = <_Filter>[
  const _Filter('All', 'सभी', Icons.apps_rounded, null),
  _Filter('Char Dham', 'चार धाम', Icons.terrain_rounded,
      (t) => t.tags.any((x) => x.contains('char_dham'))),
  _Filter('Jyotirlingas', 'ज्योतिर्लिंग', Icons.local_fire_department_rounded,
      (t) => t.tags.any((x) => x.contains('jyotirlinga'))),
  _Filter('Shakti Peethas', 'शक्ति पीठ', Icons.auto_awesome_rounded,
      (t) => t.tags.any((x) => x.contains('shakti'))),
  _Filter('Healing', 'रोगनाशक', Icons.healing_rounded,
      (t) => t.tags.any((x) => x.contains('healing') || x.contains('ailment'))),
];

/// Yatra — the temple directory. A rotating featured hero up top, then a
/// refined single-column editorial list — every card now carries a drawn
/// temple silhouette (per architecture family) instead of a flat tint.
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

    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        bottom: false,
        child: AsyncView(
          value: temples,
          isEmpty: (l) => l.isEmpty,
          emptyMessage: hi ? 'कोई मंदिर नहीं' : 'No temples',
          loading: const SkeletonTempleCards(),
          builder: (list) {
            final q = _query.trim().toLowerCase();
            final active = _filters[_filterIdx];
            final searching = q.isNotEmpty || _visitedOnly || _filterIdx != 0;
            final filtered = list.where((t) {
              final matchFilter = active.test == null || active.test!(t);
              final matchVisited = !_visitedOnly || visited.contains(t.id);
              // Hindi fields are matched too: the filter used to check only
              // the English name, deity, state and district, so a user reading
              // the app in Hindi could see "केदारनाथ मंदिर" on screen and get
              // no result typing it.
              final matchQuery = q.isEmpty ||
                  t.nameEn.toLowerCase().contains(q) ||
                  (t.nameHi ?? '').toLowerCase().contains(q) ||
                  (t.deityEn ?? '').toLowerCase().contains(q) ||
                  (t.deityHi ?? '').toLowerCase().contains(q) ||
                  (t.state ?? '').toLowerCase().contains(q) ||
                  (t.district ?? '').toLowerCase().contains(q);
              return matchFilter && matchVisited && matchQuery;
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(count: list.length, hi: hi),
                ),

                // The rotating featured hero is a "look what's here" surface,
                // not a filter result — hidden the moment the user starts
                // narrowing the list, so it never competes with what they
                // actually asked for.
                if (!searching && list.isNotEmpty)
                  SliverToBoxAdapter(child: _FeaturedCarousel(hi: hi, all: list)),

                SliverToBoxAdapter(child: _SearchBar(
                  hi: hi,
                  onChanged: (v) => setState(() => _query = v),
                )),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: SurfaceCard(
                      padding: EdgeInsets.zero,
                      radius: Radii.md,
                      child: NavRow(
                        title: hi ? 'मेरी यात्रा' : 'My Yatra',
                        subtitle: hi ? 'दर्शन किए मंदिर और संग्रह' : 'Visits and collections',
                        leading: Icon(Icons.temple_hindu_rounded, color: context.colors.accent),
                        onTap: () => context.push('/passport'),
                      ),
                    ),
                  ),
                ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Eyebrow(
                      hi
                          ? '${filtered.length} मंदिर'
                          : '${filtered.length} ${filtered.length == 1 ? 'temple' : 'temples'}',
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      title: hi ? 'कुछ नहीं मिला' : 'Nothing found',
                      body: hi ? 'कोई और नाम या फ़िल्टर आज़माएँ' : 'Try another name or filter',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, i) => _EnteringTile(
                        index: i,
                        child: _TempleCard(
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
    showAppSnack(context, 'Could not open the map for this temple',
        kind: NoticeKind.warning);
  }
}

/// A one-shot fade + rise entrance for a list tile, staggered by [index] so
/// the directory feels like it is settling into place rather than snapping
/// in — the "no animation" flatness this redesign specifically moved away
/// from. Runs once per tile (keyed by temple identity via the list's own
/// keys), not on every rebuild, since [AnimatedList]-style re-triggering on
/// every filter change would fight the user's own scrolling.
class _EnteringTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _EnteringTile({required this.index, required this.child});

  @override
  State<_EnteringTile> createState() => _EnteringTileState();
}

class _EnteringTileState extends State<_EnteringTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _rise = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // Stagger capped at 8 tiles' worth of delay — beyond that the list is
    // long enough that a fixed per-item delay would make row 40 wait nearly
    // four seconds to appear on screen even though it was visible instantly.
    final delay = Duration(milliseconds: 40 * math.min(widget.index, 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _rise, child: widget.child),
    );
  }
}

/// The rotating "Featured" hero — a large, immersive card for one temple at a
/// time, auto-advancing with a dot pager, in front of the editorial list.
/// Picks from Char Dham / Jyotirlinga / Shakti Peetha temples first (the
/// directory's own curated tiers) so the rotation always leads with
/// something notable rather than an arbitrary row.
class _FeaturedCarousel extends StatefulWidget {
  final bool hi;
  final List<Temple> all;
  const _FeaturedCarousel({required this.hi, required this.all});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.88);
  late final List<Temple> _featured = _pick(widget.all);
  double _page = 0;
  Timer? _timer;

  static List<Temple> _pick(List<Temple> all) {
    bool tier(Temple t) => t.tags.any((x) =>
        x.contains('char_dham') ||
        x.contains('jyotirlinga') ||
        x.contains('shakti'));
    final curated = all.where(tier).toList();
    final pool = curated.length >= 5 ? curated : all;
    return pool.length <= 8 ? pool : pool.take(8).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients || _featured.length < 2) return;
      final next = (_controller.page ?? 0).round() + 1;
      _controller.animateToPage(
        next % _featured.length,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_featured.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _featured.length,
            itemBuilder: (context, i) {
              final delta = (i - _page).abs().clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 16 : 8,
                  right: i == _featured.length - 1 ? 16 : 8,
                ),
                child: Transform.scale(
                  scale: 1 - delta * 0.06,
                  child: Opacity(
                    opacity: 1 - delta * 0.35,
                    child: _FeaturedSlide(
                        temple: _featured[i],
                        hi: widget.hi,
                        onTap: () =>
                            context.push('/temple', extra: _featured[i])),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featured.length, (i) {
            final activeI = _page.round() == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: activeI ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: activeI
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _FeaturedSlide extends StatelessWidget {
  final Temple temple;
  final bool hi;
  final VoidCallback onTap;
  const _FeaturedSlide(
      {required this.temple, required this.hi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final archetype = TempleArchetype.of(temple);
    final sky = templeSkyColors(temple);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TempleIllustration(archetype: archetype, colors: sky),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text((hi ? 'विशेष' : 'FEATURED').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFF6EE))),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temple.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(tagLabel(temple.primaryTag).toUpperCase(),
                          style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.78))),
                    ),
                  Text(temple.name(hi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Color(0xFFFFF6EE))),
                  if (temple.place.isNotEmpty || temple.locationEn != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.place_rounded,
                              size: 14, color: Color(0xFFFBE6D6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                                temple.place.isNotEmpty
                                    ? temple.place
                                    : (temple.locationEn ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFFBE6D6))),
                          ),
                        ],
                      ),
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

class _Header extends StatelessWidget {
  final int count;
  final bool hi;
  const _Header({required this.count, required this.hi});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, Space.x3),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: c.goldGradient),
              borderRadius: Radii.rMd,
              boxShadow: context.elevation.rest,
            ),
            child: const Icon(Icons.temple_hindu_rounded, color: Palette.plum900, size: 28),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScriptText(hi ? 'मंदिर निर्देशिका' : 'Temple Directory',
                    style: tt.headlineSmall?.copyWith(color: c.ink)),
                ScriptText(
                  hi ? '$count मंदिर · भारत भर में' : '$count temples · across India',
                  style: tt.bodySmall?.copyWith(color: c.inkFaint),
                ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AppSearchField(
        onChanged: onChanged,
        hint: hi ? 'मंदिर, देवता, स्थान खोजें…' : 'Search temples, deities, locations…',
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
    return ChipRow(
      children: [
        for (var i = 0; i < _filters.length; i++)
          ChoiceChipX(
            label: hi ? _filters[i].hi : _filters[i].en,
            icon: _filters[i].icon,
            selected: i == selected && !visitedOnly,
            tint: context.colors.gold,
            onTap: () => onSelect(i),
          ),
        ChoiceChipX(
          label: hi ? 'गए हुए' : 'Visited',
          icon: Icons.check_circle_outline_rounded,
          selected: visitedOnly,
          tint: context.colors.tulsi,
          onTap: onVisited,
        ),
      ],
    );
  }
}

/// Editorial temple card: a drawn architecture-family illustration fills the
/// cover, with category + Visited pills and the name overlaid, then a
/// quick-facts strip (Established · Entry · Best time) and a location footer.
class _TempleCard extends StatefulWidget {
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

  @override
  State<_TempleCard> createState() => _TempleCardState();
}

class _TempleCardState extends State<_TempleCard> {
  bool _pressed = false;

  List<(String, String)> _facts() {
    final t = widget.temple;
    final hi = widget.hi;
    final out = <(String, String)>[];
    final y = establishedYear(t.foundingEraEn);
    if (y != null) out.add((hi ? 'स्थापना' : 'Established', y));
    if (t.entryFee(hi) != null) {
      final free = t.entryFeeEn?.toLowerCase().contains('free') ?? false;
      out.add((hi ? 'प्रवेश' : 'Entry',
          free ? (hi ? 'नि:शुल्क' : 'Free') : (hi ? 'सशुल्क' : 'Paid')));
    }
    final s = shortSeason(t.bestSeasonEn);
    if (s != null) out.add((hi ? 'सर्वोत्तम' : 'Best time', s));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.temple;
    final hi = widget.hi;
    final scheme = Theme.of(context).colorScheme;
    final archetype = TempleArchetype.of(t);
    final sky = templeSkyColors(t);
    final facts = _facts();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.982 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover — a real drawn silhouette per architecture family,
                // not a flat tint behind a generic icon.
                SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TempleIllustration(archetype: archetype, colors: sky),
                      if (t.tags.isNotEmpty)
                        Positioned(
                          left: 14,
                          top: 14,
                          child: _CoverPill(text: tagLabel(t.primaryTag)),
                        ),
                      Positioned(
                        right: 12,
                        top: 11,
                        child: _VisitedPill(
                            visited: widget.visited,
                            hi: hi,
                            onTap: widget.onToggleVisited,
                            onCover: true),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name(hi),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                    height: 1.12,
                                    color: Color(0xFFFFF6EE))),
                            if (t.deity(hi) != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(t.deity(hi)!,
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
                          Expanded(
                              child: _FactCell(
                                  label: facts[i].$1, value: facts[i].$2)),
                        ],
                      ],
                    ),
                  ),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outline.withValues(alpha: 0.14)),

                // Location + actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                  child: Row(
                    children: [
                      Icon(Icons.place_rounded, size: 18, color: AppColors.gold),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          t.place.isNotEmpty ? t.place : (t.locationEn ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onMap,
                        icon:
                            Icon(Icons.map_rounded, size: 18, color: AppColors.gold),
                        label: Text(hi ? 'नक्शा' : 'Map',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
