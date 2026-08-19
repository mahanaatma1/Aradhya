import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/visited.dart';
import '../../shared/widgets/source_chip.dart';
import '../related/related_rail.dart';
import 'temple_map.dart';
import 'temple_models.dart';
import 'visit_sheet.dart';
import 'temple_style.dart';

/// One anchored section of the detail page.
class _Section {
  final String id;
  final String label;
  final Widget child;
  const _Section(this.id, this.label, this.child);
}

/// Temple detail — reference-styled visitor guide with a tinted hero, quick
/// facts, and a sticky pill tab bar that scroll-spies the sections below and
/// auto-scrolls to a section when its pill is tapped.
class TempleDetailScreen extends ConsumerStatefulWidget {
  final Temple temple;
  const TempleDetailScreen({super.key, required this.temple});

  @override
  ConsumerState<TempleDetailScreen> createState() =>
      _TempleDetailScreenState();
}

class _TempleDetailScreenState extends ConsumerState<TempleDetailScreen> {
  final _controller = ScrollController();
  final _keys = <String, GlobalKey>{
    'about': GlobalKey(),
    'timings': GlobalKey(),
    'travel': GlobalKey(),
    'festivals': GlobalKey(),
  };
  static const _barHeight = 52.0;
  int _active = 0;
  List<String> _order = const [];

  Temple get t => widget.temple;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_order.length < 2 || !mounted) return;
    final line = MediaQuery.of(context).padding.top + _barHeight + 8;
    var active = 0;
    for (var i = 0; i < _order.length; i++) {
      final ctx = _keys[_order[i]]!.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= line) {
        active = i;
      } else {
        break;
      }
    }
    if (active != _active) setState(() => _active = active);
  }

  void _goto(int i) {
    final ctx = _keys[_order[i]]!.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final dy = box.localToGlobal(Offset.zero).dy;
    final topPad = MediaQuery.of(context).padding.top;
    final target = (_controller.offset + dy - topPad - _barHeight)
        .clamp(0.0, _controller.position.maxScrollExtent);
    setState(() => _active = i);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final visited = ref.watch(visitedProvider).contains(t.id);
    final scheme = Theme.of(context).colorScheme;
    final tint = templeTint(t);
    final hasMap = (t.mapsLink != null && t.mapsLink!.isNotEmpty) ||
        (t.lat != null && t.lon != null);

    final sections = _sections(context, hi);
    _order = sections.map((s) => s.id).toList();
    final activeClamped = _active.clamp(0, sections.isEmpty ? 0 : sections.length - 1);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    if (hasMap)
                      _RoundBtn(
                        icon: Icons.ios_share_rounded,
                        color: scheme.secondary,
                        onTap: () => _openMap(context, t),
                      ),
                    // A visit is worth more than a tick. Once marked, offer
                    // the note and rating the passport can show.
                    if (visited) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => showVisitSheet(context, ref, t.id, hi),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(hi
                            ? 'यात्रा का विवरण जोड़ें'
                            : 'Add a note to this visit'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: _Hero(temple: t, tint: tint, hi: hi, hasMap: hasMap),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _QuickFacts(temple: t, hi: hi),
              ),
            ),

            // Sticky scroll-spy pill bar
            if (sections.length > 1)
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  height: _barHeight,
                  labels: sections.map((s) => s.label).toList(),
                  active: activeClamped,
                  onTap: _goto,
                  background: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),

            // Sections (all rendered, anchored by key)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in sections)
                      KeyedSubtree(key: _keys[s.id], child: s.child),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(visitedProvider.notifier).toggle(t.id),
                      icon: Icon(visited
                          ? Icons.check_circle_rounded
                          : Icons.add_location_alt_outlined),
                      label: Text(visited
                          ? (hi ? 'गए हुए के रूप में चिह्नित ✓' : 'Marked as visited ✓')
                          : (hi ? 'गए हुए के रूप में चिह्नित करें' : 'Mark as visited')),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            visited ? scheme.secondary : scheme.primary,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Precomputed links to this temple's aarti, chalisa, mantras, puja
            // vidhi and vrat kathas. Renders nothing when the temple has no
            // edges, so it is safe on every screen.
            SliverToBoxAdapter(
              child: RelatedRail(table: 'temples', id: t.id),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Build the ordered, data-driven sections. Each `child` starts with its
  /// heading so the anchor key aligns to the heading top.
  List<_Section> _sections(BuildContext context, bool hi) {
    final out = <_Section>[];

    if (t.significance(hi) != null || t.deity(hi) != null) {
      out.add(_Section(
        'about',
        hi ? 'परिचय' : 'About',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(hi ? 'परिचय' : 'About'),
            if (t.significance(hi) != null)
              _ProseCard(
                  title: hi ? 'मंदिर के बारे में' : 'About the temple',
                  text: t.significance(hi)!,
                  hi: hi),
            _InfoCard(title: hi ? 'मुख्य तथ्य' : 'Key facts', rows: [
              if (t.deity(hi) != null) (hi ? 'देवता' : 'Deity', t.deity(hi)!),
              if (t.altNames(hi) != null)
                (hi ? 'अन्य नाम' : 'Also known as', t.altNames(hi)!),
              if (t.foundingEra(hi) != null)
                (hi ? 'स्थापना' : 'Founded / built', t.foundingEra(hi)!),
              if (t.architecture(hi) != null)
                (hi ? 'वास्तुकला' : 'Architecture', t.architecture(hi)!),
            ]),
            // These citations were already shipping inside `temples.data` on
            // all 187 rows and were being parsed away. Official domains
            // (.gov.in, .nic.in, tourism boards) are ranked first.
            if (t.sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SourceChip(
                  hindi: hi,
                  sourceName: hi ? 'संदर्भ' : 'References',
                  sourceRef: '${t.sources.length}',
                  sourceUrl: t.rankedSources.first,
                  otherUrls: t.rankedSources.skip(1).toList(),
                  licenseNote: t.confidence == null
                      ? null
                      : (hi
                          ? 'डेटा विश्वसनीयता: ${t.confidence}'
                          : 'Data confidence: ${t.confidence}'),
                ),
              ),
            ],
          ],
        ),
      ));
    }

    if (t.hours(hi) != null ||
        t.darshan(hi) != null ||
        t.aartiSchedule.isNotEmpty) {
      out.add(_Section(
        'timings',
        hi ? 'समय' : 'Timings',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(hi ? 'समय' : 'Timings'),
            if (t.hours(hi) != null || t.darshan(hi) != null)
              _InfoCard(title: hi ? 'समय' : 'Timings', rows: [
                if (t.darshan(hi) != null)
                  (hi ? 'दर्शन' : 'Darshan', t.darshan(hi)!),
                if (t.hours(hi) != null)
                  (hi ? 'मंदिर खुला' : 'Temple open', t.hours(hi)!),
              ]),
            if (t.aartiSchedule.isNotEmpty)
              _AartiCard(schedule: t.aartiSchedule, hi: hi),
            if (t.bestSeason(hi) != null ||
                t.bestTime(hi) != null ||
                t.weather(hi) != null)
              _InfoCard(title: hi ? 'कब जाएँ' : 'When to go', rows: [
                if (t.bestSeason(hi) != null)
                  (hi ? 'सर्वोत्तम समय' : 'Best season', t.bestSeason(hi)!),
                if (t.bestTime(hi) != null)
                  (hi ? 'दिन का समय' : 'Best time of day', t.bestTime(hi)!),
                if (t.weather(hi) != null)
                  (hi ? 'मौसम' : 'Weather', t.weather(hi)!),
              ]),
            _goodToKnow(context, hi),
          ],
        ),
      ));
    }

    if (t.website != null || t.helpline != null) {
      out.add(_Section(
        'links',
        hi ? 'लिंक' : 'Links',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(hi ? 'लिंक' : 'Links'),
            _LinksCard(
                website: t.website, helpline: t.helpline, hi: hi),
          ],
        ),
      ));
    }

    if (t.address(hi) != null ||
        t.airportName != null ||
        t.railwayName != null ||
        t.busStandName != null ||
        t.nearby(hi) != null) {
      out.add(_Section(
        'travel',
        hi ? 'यात्रा' : 'Travel',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(hi ? 'यात्रा' : 'Travel'),
            _InfoCard(title: hi ? 'पहुँचना' : 'Getting there', rows: [
              if (t.railwayName != null)
                (
                  hi ? 'निकटतम रेलवे' : 'Nearest railway',
                  '${t.railwayName}${t.railwayKm != null ? ' · ~${t.railwayKm} km' : ''}'
                ),
              if (t.airportName != null)
                (
                  hi ? 'निकटतम हवाई अड्डा' : 'Nearest airport',
                  '${t.airportName}${t.airportKm != null ? ' · ~${t.airportKm} km' : ''}'
                ),
              if (t.busStandName != null)
                (
                  hi ? 'बस स्टैंड' : 'Bus stand',
                  '${t.busStandName}${t.busStandKm != null ? ' · ~${t.busStandKm} km' : ''}'
                ),
              if (t.localTransport(hi) != null)
                (hi ? 'स्थानीय परिवहन' : 'Local transport', t.localTransport(hi)!),
              if (t.parking(hi) != null)
                (hi ? 'पार्किंग' : 'Parking', t.parking(hi)!),
            ]),
            if (t.address(hi) != null ||
                t.nearby(hi) != null ||
                (t.lat != null && t.lon != null))
              _InfoCard(title: hi ? 'स्थान' : 'Location', rows: [
                if (t.address(hi) != null)
                  (hi ? 'पता' : 'Address', t.address(hi)!),
                if (t.nearby(hi) != null)
                  (hi ? 'आस-पास' : 'Nearby', t.nearby(hi)!),
                if (t.lat != null && t.lon != null)
                  (
                    hi ? 'निर्देशांक' : 'Coordinates',
                    '${t.lat!.toStringAsFixed(4)}, ${t.lon!.toStringAsFixed(4)}'
                  ),
              ]),
          ],
        ),
      ));
    }

    if (t.festivals.isNotEmpty) {
      out.add(_Section(
        'festivals',
        hi ? 'उत्सव' : 'Festivals',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(hi ? 'उत्सव' : 'Festivals'),
            for (final f in t.festivals)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: _cardDeco(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name(hi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                    if (f.note(hi) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(f.note(hi)!,
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.72))),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ));
    }

    return out;
  }

  Widget _goodToKnow(BuildContext context, bool hi) {
    final rows = <(String, String)>[
      if (t.entryFee(hi) != null)
        (hi ? 'प्रवेश शुल्क' : 'Entry / fees', t.entryFee(hi)!),
      if (t.dressCode(hi) != null) (hi ? 'वेशभूषा' : 'Dress code', t.dressCode(hi)!),
      if (t.photography(hi) != null)
        (hi ? 'फ़ोटोग्राफ़ी' : 'Photography', t.photography(hi)!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((hi ? 'जानने योग्य' : 'Good to know').toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: scheme.onSurface,
                      fontFamily: hi ? AppFonts.devanagari : AppFonts.body),
                  children: [
                    TextSpan(
                        text: '${r.$1}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: r.$2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final List<String> labels;
  final int active;
  final void Function(int) onTap;
  final Color background;
  _TabBarDelegate({
    required this.height,
    required this.labels,
    required this.active,
    required this.onTap,
    required this.background,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: background,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Center(
          child: _TabPill(
            label: labels[i],
            selected: i == active,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.active != active ||
      old.labels.length != labels.length ||
      old.background != background;
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.7))),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 22)),
    );
  }
}

BoxDecoration _cardDeco(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4)),
    ],
  );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: color ?? scheme.onSurface),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Temple temple;
  final Color tint;
  final bool hi;
  final bool hasMap;
  const _Hero(
      {required this.temple,
      required this.tint,
      required this.hi,
      required this.hasMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.temple_hindu_rounded,
                    color: Color(0xFFFFF8EF), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(temple.name(hi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 1.1)),
                    if (temple.deity(hi) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(temple.deity(hi)!,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tint)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: tint, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        temple.place.isNotEmpty
                            ? temple.place
                            : (temple.locationEn ?? ''),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMap)
                FilledButton(
                  onPressed: () => _openMap(context, temple),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Text(hi ? 'नक्शे में खोलें' : 'Open in Maps',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (temple.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in temple.tags.take(4)) TagChip(tag: tag)
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickFacts extends StatelessWidget {
  final Temple temple;
  final bool hi;
  const _QuickFacts({required this.temple, required this.hi});

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[];
    final year = establishedYear(temple.foundingEraEn);
    if (year != null) facts.add((hi ? 'स्थापना' : 'Established', year));
    if (temple.entryFee(hi) != null) {
      final free = temple.entryFeeEn?.toLowerCase().contains('free') ?? false;
      facts.add((
        hi ? 'प्रवेश' : 'Entry',
        free ? (hi ? 'नि:शुल्क' : 'Free') : (hi ? 'सशुल्क' : 'Paid')
      ));
    }
    final season = shortSeason(temple.bestSeasonEn);
    if (season != null) facts.add((hi ? 'सर्वोत्तम' : 'Best time', season));
    if (facts.isEmpty && temple.state != null) {
      facts.add((hi ? 'राज्य' : 'State', temple.state!));
    }
    if (facts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _FactTile(label: facts[i].$1, value: facts[i].$2)),
        ],
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  final String label;
  final String value;
  const _FactTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 6),
          for (var i = 0; i < visible.length; i++) ...[
            Divider(color: scheme.outline.withValues(alpha: 0.14)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(visible[i].$1,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(visible[i].$2,
                        style: const TextStyle(fontSize: 15, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ProseCard extends StatelessWidget {
  final String title;
  final String text;
  final bool hi;
  const _ProseCard(
      {required this.title, required this.text, required this.hi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 10),
          Text(text,
              style: TextStyle(
                  fontSize: 15.5,
                  height: 1.55,
                  fontFamily: hi ? AppFonts.devanagari : AppFonts.body)),
        ],
      ),
    );
  }
}

/// Aarti schedule — a gold time on the left, aarti name on the right.
class _AartiCard extends StatelessWidget {
  final List<TempleAarti> schedule;
  final bool hi;
  const _AartiCard({required this.schedule, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: _cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'आरती अनुसूची' : 'Aarti Schedule',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 6),
          for (final a in schedule) ...[
            Divider(color: scheme.outline.withValues(alpha: 0.14)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(a.time,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: scheme.secondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.name(hi),
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Official links — tappable website and helpline rows.
class _LinksCard extends StatelessWidget {
  final String? website;
  final String? helpline;
  final bool hi;
  const _LinksCard(
      {required this.website, required this.helpline, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(String label, String value, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5, color: scheme.secondary)),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: scheme.secondary),
              ],
            ),
          ),
        );

    final children = <Widget>[];
    if (website != null) {
      children.add(row(hi ? 'वेबसाइट' : 'Official website', website!,
          () => launchExternal(website!)));
    }
    if (helpline != null) {
      if (children.isNotEmpty) {
        children.add(Divider(color: scheme.outline.withValues(alpha: 0.14)));
      }
      children.add(row(hi ? 'हेल्पलाइन' : 'Helpline', helpline!,
          () => launchExternal('tel:$helpline')));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: _cardDeco(context),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

Future<void> _openMap(BuildContext context, Temple t) async {
  final ok = await openTempleMap(t);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open the map')));
  }
}
