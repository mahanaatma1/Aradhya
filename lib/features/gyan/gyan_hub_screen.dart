import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import 'gyan_modules.dart';
import 'gyan_motifs.dart';

/// One thematic cluster of modules, each getting its own animated
/// horizontal rail rather than every module sitting in one flat grid.
/// Grouping is presentation-only — [gyanModules] stays the single source of
/// truth for what a module *is*; this only decides where it is *shown*.
class _Cluster {
  final String titleEn;
  final String titleHi;
  final String taglineEn;
  final String taglineHi;
  final Color accent;
  final List<String> moduleIds;
  const _Cluster(this.titleEn, this.titleHi, this.taglineEn, this.taglineHi,
      this.accent, this.moduleIds);
}

const _clusters = <_Cluster>[
  _Cluster(
    'Epics & Time',
    'महाकाव्य और काल',
    'The great stories, and the ages they unfold in',
    'महान कथाएँ, और वे युग जिनमें वे घटित हुईं',
    Color(0xFF8A6A4F),
    ['ramayana', 'mahabharata', 'yuga'],
  ),
  _Cluster(
    'Sages & Lineage',
    'ऋषि और वंशावली',
    'Who taught whom, and how it all connects',
    'किसने किसे सिखाया, और सब कैसे जुड़ा है',
    Color(0xFF6C5A9C),
    ['rishis', 'lineage', 'graph'],
  ),
  _Cluster(
    'Cosmos & Symbols',
    'सृष्टि और प्रतीक',
    'The shape of creation, and its sacred marks',
    'सृष्टि का स्वरूप, और उसके पवित्र चिह्न',
    Color(0xFF4E3F78),
    ['srishty', 'astras', 'symbols', 'vidya'],
  ),
  _Cluster(
    'Practice & Reflection',
    'साधना और चिंतन',
    'Bring it into today',
    'इसे आज में उतारें',
    Color(0xFFD9748C),
    ['dharma', 'festivals', 'ask'],
  ),
];

/// The home for all Gyan modules.
///
/// A pushed route rather than a tab: the bottom bar is already tight with five
/// Hindi labels, and promoting Gyan is a deliberate later step (merging Rashifal
/// into Astrology) that should land on its own revertible commit.
///
/// Tiles come from [gyanModules], so adding a module updates this grid, the
/// search filter chips and the content pipeline's module list at once. Layout
/// clusters them by theme ([_clusters]) purely for display.
class GyanHubScreen extends ConsumerWidget {
  const GyanHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;

    // journey is the hub's own "start here" rail above, so it is never
    // listed again inside a themed cluster.
    final clustered = {for (final c in _clusters) ...c.moduleIds};
    final leftover = gyanModules
        .where((m) => m.id != 'journey' && !clustered.contains(m.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'ज्ञान' : 'Gyan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _LivingHero(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _StartHereCard(hi: hi),
          ),
          const SizedBox(height: 6),
          for (var c = 0; c < _clusters.length; c++)
            _ClusterRail(
              cluster: _clusters[c],
              cats: cats,
              hi: hi,
              railIndex: c,
            ),
          if (leftover.isNotEmpty)
            _ClusterRail(
              cluster: _Cluster(
                'More',
                'और',
                'Everything else, for now',
                'फ़िलहाल बाकी सब',
                AppColors.terracotta,
                [for (final m in leftover) m.id],
              ),
              cats: cats,
              hi: hi,
              railIndex: _clusters.length,
            ),
        ],
      ),
    );
  }
}

class _StartHereCard extends StatelessWidget {
  final bool hi;
  const _StartHereCard({required this.hi});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF3E7F8E);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/journey'),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: teal.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, size: 22, color: teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hi ? 'यहाँ से शुरू करें' : 'Start here',
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4552))),
                  const SizedBox(height: 2),
                  Text(
                    hi
                        ? 'दस निर्देशित यात्राएँ — जो पहले से यहाँ है, उसी में से चुनी हुई'
                        : 'Ten guided journeys, curated from what is already here',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: teal),
          ],
        ),
      ),
    );
  }
}

/// The hub's banner — no longer a flat static gradient block. A slow drifting
/// glow behind the title and a gently breathing lotus watermark keep the
/// surface visibly alive the instant the screen opens, before the user has
/// touched anything.
class _LivingHero extends StatefulWidget {
  const _LivingHero();

  @override
  State<_LivingHero> createState() => _LivingHeroState();
}

class _LivingHeroState extends State<_LivingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3E7F8E), Color(0xFF1D4552)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // A slow-drifting glow — the thing that makes the hero read as
            // "alive" the instant the screen opens, before any tap.
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value * 2 * math.pi;
                return Positioned(
                  right: -40 + math.cos(t) * 14,
                  top: -30 + math.sin(t) * 10,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldBright.withValues(alpha: 0.14),
                    ),
                  ),
                );
              },
            ),
            // A breathing lotus watermark, low-corner, reusing the same
            // hand-drawn motif vocabulary the tiles use rather than a photo.
            Positioned(
              right: -10,
              bottom: -14,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final breathe =
                      0.9 + 0.1 * math.sin(_c.value * 2 * math.pi);
                  return Transform.scale(
                    scale: breathe,
                    child: GyanMotif(
                      moduleId: 'symbols',
                      color: Colors.white.withValues(alpha: 0.1),
                      size: 108,
                      watermark: true,
                    ),
                  );
                },
              ),
            ),
            const _HeroText(),
          ],
        ),
      ),
    );
  }
}

class _HeroText extends ConsumerWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(isHindiProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang ? 'ज्ञान' : 'GYAN',
            style: const TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.goldBright)),
        const SizedBox(height: 6),
        Text(lang ? 'सनातन का संसार' : 'The world of Sanatan',
            style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1.08,
                color: Color(0xFFFCEFE2))),
        const SizedBox(height: 8),
        Text(
          lang
              ? 'देव · ऋषि · अस्त्र · प्रतीक · महाकाव्य · सृष्टि'
              : 'Deities · Sages · Astras · Symbols · Epics · Cosmos',
          style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: const Color(0xFFFCEFE2).withValues(alpha: 0.82)),
        ),
      ],
    );
  }
}

/// One themed rail: a small colored heading, then a horizontally-scrolling
/// row of module cards that enter with a staggered rise-and-fade the first
/// time the rail becomes visible, rather than every tile snapping onto
/// screen at once. Each rail keeps its own [VisibilityDetector]-free trigger
/// (a one-shot [TweenAnimationBuilder] gated by [_railIndex]'s delay) so
/// scrolling the long hub page still feels like it's revealing something,
/// all the way down — not just a one-time splash at the very top.
class _ClusterRail extends StatefulWidget {
  final _Cluster cluster;
  final CategoryColors cats;
  final bool hi;
  final int railIndex;
  const _ClusterRail({
    required this.cluster,
    required this.cats,
    required this.hi,
    required this.railIndex,
  });

  @override
  State<_ClusterRail> createState() => _ClusterRailState();
}

class _ClusterRailState extends State<_ClusterRail> {
  final _key = GlobalKey();
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // The hub body is a plain ListView (not .builder), so every rail mounts
    // on the very first frame regardless of scroll position — this delay is
    // what turns that into a visible top-to-bottom cascade rather than every
    // rail's tiles entering at once. Capped at 4 rails' worth so a long hub
    // never makes the last rail wait an odd amount just because it's last.
    final delay = Duration(milliseconds: 90 * math.min(widget.railIndex, 4));
    Future.delayed(delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      for (final id in widget.cluster.moduleIds)
        if (gyanModuleById(id) != null) gyanModuleById(id)!,
    ];
    if (modules.isEmpty) return const SizedBox.shrink();
    final shipped = modules.where((m) => m.shipped).length;

    return Padding(
      key: _key,
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                      color: widget.cluster.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hi
                            ? widget.cluster.titleHi
                            : widget.cluster.titleEn,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 17),
                      ),
                      Text(
                        widget.hi
                            ? widget.cluster.taglineHi
                            : widget.cluster.taglineEn,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (shipped < modules.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      widget.hi
                          ? '$shipped/${modules.length} खुला'
                          : '$shipped/${modules.length} available',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 172,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: modules.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: i == modules.length - 1 ? 0 : 12),
                child: _EnteringModuleTile(
                  shown: _shown,
                  delayMs: 60 * i,
                  child: _ModuleTile(
                    module: modules[i],
                    cats: widget.cats,
                    hi: widget.hi,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-shot fade + rise + scale entrance, staggered within its rail so
/// tiles visibly cascade in left-to-right rather than the whole row
/// appearing at once — the concrete answer to "don't make this just a box,
/// I want animation here".
class _EnteringModuleTile extends StatefulWidget {
  final bool shown;
  final int delayMs;
  final Widget child;
  const _EnteringModuleTile(
      {required this.shown, required this.delayMs, required this.child});

  @override
  State<_EnteringModuleTile> createState() => _EnteringModuleTileState();
}

class _EnteringModuleTileState extends State<_EnteringModuleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  bool _started = false;

  @override
  void didUpdateWidget(covariant _EnteringModuleTile old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  @override
  void initState() {
    super.initState();
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || !widget.shown) return;
    _started = true;
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
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
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final rise = Tween(begin: const Offset(0.08, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    final scale = Tween(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: fade.value,
        child: FractionalTranslation(
          translation: rise.value,
          child: Transform.scale(scale: scale.value, child: child),
        ),
      ),
      child: widget.child,
    );
  }
}

/// A single module card inside a rail — a fixed-width tile (rather than the
/// old 2-col grid cell) so it can sit in a horizontally-scrolling row. Press
/// feedback is a spring-like squeeze-and-settle rather than a flat scale, and
/// the module's own [GyanMotif] glyph does a small rotate-in on press so the
/// tile visibly responds rather than just going slightly smaller.
class _ModuleTile extends StatefulWidget {
  final GyanModule module;
  final CategoryColors cats;
  final bool hi;
  const _ModuleTile({
    required this.module,
    required this.cats,
    required this.hi,
  });

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  GyanModule get module => widget.module;
  CategoryColors get cats => widget.cats;
  bool get hi => widget.hi;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = module.style(cats);
    final scheme = Theme.of(context).colorScheme;
    final enabled = module.shipped;

    final gradient = enabled
        ? style.linear
        : LinearGradient(colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          ]);
    final fg = enabled ? const Color(0xFFFFF8EF) : scheme.onSurface;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: () => _press.reverse(),
      onTapUp: (_) => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          // A squeeze that overshoots slightly on release (spring-like)
          // instead of a linear scale down-and-back, and the whole tile
          // tilts a couple of degrees under the finger — small, but enough
          // that this reads as responding, not just dimming.
          final t = _press.value;
          final squeeze = 1 - 0.05 * math.sin(t * math.pi);
          final tilt = -0.012 * math.sin(t * math.pi);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0009)
              ..rotateZ(tilt)
              ..scaleByDouble(squeeze, squeeze, squeeze, 1),
            child: child,
          );
        },
        child: SizedBox(
          width: 148,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: enabled
                  ? () => context.push(module.route)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(hi
                              ? '${module.titleHi} — जल्द आ रहा है'
                              : '${module.titleEn} — coming soon'),
                        ),
                      ),
              child: Container(
                height: 172,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  border: enabled
                      ? null
                      : Border.all(color: scheme.outline.withValues(alpha: 0.2)),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                              color: style.gradient.last.withValues(alpha: 0.24),
                              blurRadius: 12,
                              offset: const Offset(0, 5))
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    if (enabled)
                      Positioned(
                        right: -22,
                        bottom: -18,
                        child: GyanMotif(
                          moduleId: module.id,
                          color: Colors.white.withValues(alpha: 0.16),
                          size: 104,
                          watermark: true,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _press,
                            builder: (context, child) => Transform.rotate(
                              // The glyph chip spins a quarter turn in and
                              // back on tap — the module's own visible
                              // "acknowledged" cue, distinct from the tile's
                              // squeeze.
                              angle: _press.value * math.pi / 10,
                              child: child,
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (enabled ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: enabled ? 0.22 : 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: GyanMotif(
                                  moduleId: module.id,
                                  color: fg.withValues(alpha: enabled ? 1 : 0.55),
                                  size: 23,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            module.title(hi),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              height: 1.15,
                              color: fg.withValues(alpha: enabled ? 1 : 0.75),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            module.blurb(hi),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: fg.withValues(alpha: enabled ? 0.9 : 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
