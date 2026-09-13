import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../shared/currency_icons.dart';
import '../../shared/reference_art.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/daily_quote_card.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';
import '../panchang/panchang_providers.dart';
import '../scriptures/scripture_models.dart' show Scripture;
import '../scriptures/scripture_providers.dart';
import '../widgets/home_widgets.dart';
import 'sections/continue_reading_card.dart';
import 'sections/did_you_know_card.dart';
import 'sections/festival_banner.dart';
import 'sections/mandir_card.dart';
import 'sections/panchang_card.dart';
import 'sections/rashifal_card.dart';
import 'sections/sadhana_card.dart';
import 'sections/scripture_carousel.dart';
import 'sections/soul_path_card.dart';
import 'sections/story_tiles.dart';

/// Home: a festival-sky hero with the day's greeting, then the verse of the
/// day and three rooms — Today (date-driven), Practice & Play, and the
/// library. Sections are separate files under `sections/`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).pingToday();
      ref.read(verseOfTheDayProvider.future).then((_) {
        if (mounted) refreshHomeWidgets(ref);
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cats = context.categories;
    final hi = ref.watch(isHindiProvider);
    final verse = ref.watch(verseOfTheDayProvider);
    final scriptures = ref.watch(scripturesProvider).asData?.value;

    ref.listen(localeProvider, (previous, next) {
      if (previous != next) refreshHomeWidgets(ref);
    });

    void openScripture(String slug) {
      int? id;
      for (final s in scriptures ?? const <Scripture>[]) {
        if (s.slug == slug) {
          id = s.id;
          break;
        }
      }
      context.push(id != null ? '/scriptures/$id' : '/scriptures');
    }

    return AppScaffold(
      controller: _scroll,
      bottomPadding: 110,
      slivers: [
        SliverToBoxAdapter(child: _HomeHero(scroll: _scroll)),

        SliverPage(gap: Space.x3, children: [
          const SizedBox(height: Space.x1),
          Reveal(
            child: verse.when(
              skipLoadingOnReload: true,
              data: (q) => q == null ? const SizedBox.shrink() : DailyQuoteCard(quote: q),
              loading: () => const SkeletonCard(height: 150),
              error: (e, _) => ErrorState(message: '$e'),
            ),
          ),
        ]),

        // ---- Today ----
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: hi ? 'आज' : 'Today',
            title: hi ? 'आज का दिन' : 'Your day',
            accent: c.lotus,
          ),
        ),
        SliverPage(children: [
          const Reveal(index: 1, child: FestivalBanner()),
          const Reveal(index: 2, child: PanchangCard()),
          const Reveal(index: 3, child: RashifalCard()),
          Reveal(index: 4, child: MandirCard(hi: hi)),
          Reveal(index: 5, child: SadhanaCard(hi: hi)),
        ]),

        // ---- Practice & play ----
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: hi ? 'अभ्यास और खेल' : 'Practice & play',
            title: hi ? 'आज कुछ नया' : 'Something for today',
            accent: c.info,
          ),
        ),
        SliverPadding(
          padding: Insets.page,
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x3,
            childAspectRatio: 1.45 / MediaQuery.textScalerOf(context).scale(1),
            children: [
              TileCard(
                label: hi ? 'प्रश्नोत्तरी' : 'Quiz',
                sublabel: hi ? 'पौराणिक प्रश्न' : 'Pauranik prashna',
                style: cats.quiz,
                motif: const Icon(Icons.psychology_alt_rounded),
                onTap: () => context.push('/quiz/play'),
              ),
              TileCard(
                label: hi ? 'जप' : 'Japa',
                sublabel: hi ? 'माला · १०८' : 'Mala · 108',
                style: cats.mantras,
                motif: const Icon(Icons.radio_button_checked_rounded),
                onTap: () => context.push('/japa'),
              ),
              TileCard(
                label: hi ? 'प्राणायाम' : 'Breathe',
                sublabel: hi ? '५ मिनट' : '5 minutes',
                style: cats.sadhana,
                motif: const Icon(Icons.air_rounded),
                onTap: () => context.push('/breathing'),
              ),
              TileCard(
                label: hi ? 'पहेलियाँ' : 'Riddles',
                sublabel: hi ? 'बूझो तो जानें' : 'Guess the answer',
                style: cats.personality,
                motif: const Icon(Icons.lightbulb_rounded),
                onTap: () => context.push('/riddles'),
              ),
            ],
          ),
        ),
        SliverPage(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, 0),
          children: [
            const DidYouKnowCard(),
            SoulPathCard(hi: hi, onTap: () => context.push('/personality')),
            const ContinueReadingCard(),
          ],
        ),

        // ---- Library ----
        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: hi ? 'ग्रंथ और ज्ञान' : 'Scriptures & wisdom',
            title: hi ? 'ग्रंथ' : 'Scriptures',
            accent: c.accent,
            trailing: GhostButton(
              label: hi ? 'सभी' : 'All',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push('/scriptures'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: Space.x3),
            child: ScriptureCarousel(
              hi: hi,
              scriptures: [
                ScriptureSpec(
                  title: hi ? 'भगवद्गीता' : 'Bhagavad Gita',
                  kicker: hi ? '18 अध्याय · 701 श्लोक' : '18 chapters · 701 verses',
                  subtitle: hi
                      ? 'श्रीकृष्ण द्वारा अर्जुन को दिए कालजयी उपदेश जानें'
                      : "Krishna's timeless teachings to Arjuna",
                  image: scriptureImage('gita'),
                  color: cats.scriptures.start,
                  onTap: () => openScripture('bhagavad-gita'),
                ),
                ScriptureSpec(
                  title: hi ? 'रामायण' : 'Ramayana',
                  kicker: hi ? '7 काण्ड' : '7 kandas',
                  subtitle: hi
                      ? 'धर्म की इस महागाथा में श्रीराम की यात्रा'
                      : "Rama's journey through this epic of dharma",
                  image: scriptureImage('ramayana'),
                  color: cats.epics.start,
                  onTap: () => openScripture('valmiki-ramayana'),
                ),
                ScriptureSpec(
                  title: hi ? 'उपनिषद्' : 'Upanishads',
                  kicker: hi ? 'गूढ़ ज्ञान' : 'Deep wisdom',
                  subtitle: hi
                      ? 'सरल भाषा में उपनिषदों का गहन ज्ञान'
                      : 'Deep wisdom, in plain modern language',
                  image: scriptureImage('upanishads'),
                  color: cats.gyan.start,
                  onTap: () => openScripture('upanishads'),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: hi ? 'साधना' : 'Devotion',
            title: hi ? 'मंत्र और आरती' : 'Mantras & aartis',
            accent: c.flame,
          ),
        ),
        SliverPage(children: [
          Row(children: [
            Expanded(
              child: ArtCard(
                asset: mantrasImage,
                title: hi ? 'मंत्र' : 'Mantras',
                subtitle: hi ? 'पवित्र जाप' : 'Sacred chants',
                onTap: () => context.push('/mantras'),
              ),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: ArtCard(
                asset: aartisImage,
                title: hi ? 'आरती' : 'Aartis',
                subtitle: hi ? 'भक्ति गान' : 'Devotional songs',
                onTap: () => context.push('/aartis'),
              ),
            ),
          ]),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              NavRow(
                title: hi ? 'पूजा विधि' : 'Puja Vidhi',
                subtitle: hi
                    ? 'त्योहार · व्रत · संस्कार · चरण-दर-चरण'
                    : 'Festivals · vrat · sanskaras · step by step',
                leading: Icon(Icons.local_fire_department_outlined, color: c.flame),
                onTap: () => context.push('/puja'),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'आदतें' : 'Habits',
                subtitle: hi ? 'छोटी चुनौतियाँ, बड़ा बदलाव' : 'Small challenges, big change',
                leading: Icon(Icons.checklist_rtl_rounded, color: c.tulsi),
                onTap: () => context.push('/habits'),
              ),
            ]),
          ),
        ]),

        SliverToBoxAdapter(
          child: SectionHeader(
            eyebrow: hi ? 'कथाएँ' : 'Stories',
            title: hi ? 'भाव से चुनें' : 'Pick a feeling',
            accent: c.lotus,
          ),
        ),
        SliverPadding(
          padding: Insets.page,
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x3,
            childAspectRatio: 2.3 / MediaQuery.textScalerOf(context).scale(1),
            children: [
              for (final e in storyEmotions)
                TileCard(
                  label: hi ? e.hi : e.en,
                  style: CategoryStyle([e.color, Color.lerp(e.color, Palette.plum900, .45)!]),
                  motif: Icon(_emotionIcon(e.en)),
                  minHeight: 0,
                  onTap: () => context.push('/katha', extra: e.en.toLowerCase()),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _emotionIcon(String en) => switch (en.toLowerCase()) {
        'anger' => Icons.whatshot_rounded,
        'joy' => Icons.wb_sunny_rounded,
        'peace' => Icons.spa_rounded,
        'love' => Icons.favorite_rounded,
        'fear' => Icons.nights_stay_rounded,
        _ => Icons.auto_awesome_rounded,
      };
}

/// The festival-sky hero: brand row, greeting, today's tithi line and the
/// one action that matters at this hour. Parallax-drifts as the page scrolls.
class _HomeHero extends ConsumerWidget {
  const _HomeHero({required this.scroll});
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final hi = ref.watch(isHindiProvider);
    final name = ref.watch(userNameProvider);
    final streak = ref.watch(streakProvider);
    final p = ref.watch(panchangProvider);
    final dark = context.isDarkTheme;
    final m = MotionScope.of(context);

    final hour = DateTime.now().hour;
    final (greetEn, greetHi) = hour < 12
        ? ('Good morning', 'शुभ प्रभात')
        : hour < 17
            ? ('Good afternoon', 'नमस्ते')
            : ('Good evening', 'शुभ संध्या');
    final who = name.trim().isEmpty ? (hi ? 'भक्त' : 'devotee') : name.trim();
    final sky = dark ? ColorTokens.dark.skyGradient : c.skyGradient;
    final onSky = dark ? c.inkOnDeep : Colors.white;

    final tithi = '${p.tithi.current(hi)} · ${p.nakshatra.current(hi)} · ${p.paksha(hi)}';

    return AnimatedBuilder(
      animation: scroll,
      builder: (context, child) {
        final off = scroll.hasClients ? scroll.offset : 0.0;
        // Sky drifts at half speed and stretches when pulled down.
        final drift = m.parallax ? off * 0.4 : 0.0;
        final stretch = off < 0 ? -off : 0.0;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.xl)),
          child: SizedBox(
            height: 300 + stretch,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(0, drift - stretch * .5),
                  child: ShaderSurface(
                    id: ShaderId.utsavSky,
                    colors: sky,
                    params: const [0.25],
                    fallback: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: sky,
                        ),
                      ),
                    ),
                    child: const BandhaniDots(opacity: .14),
                  ),
                ),
                Positioned.fill(
                  child: ParticleField(
                    emitters: [
                      if (dark) Emitters.stars(color: c.inkOnDeep, rate: 2),
                      Emitters.petals(rate: 2, color: c.gold),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _SkylinePainter(color: dark ? c.canvasDeep : Palette.vermilion700.withValues(alpha: .55))),
                ),
                child!,
              ],
            ),
          ),
        );
      },
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, Space.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const AppLogo(size: 40),
                const SizedBox(width: Space.x2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 24,
                      height: 1,
                      color: onSky,
                    ),
                    children: [
                      TextSpan(text: Brand.nameHead),
                      TextSpan(text: Brand.nameTail, style: TextStyle(color: c.gold)),
                    ],
                  ),
                ),
                const Spacer(),
                IconCircleButton(
                  icon: Icons.search_rounded,
                  tooltip: hi ? 'खोजें' : 'Search',
                  size: 40,
                  background: Colors.white.withValues(alpha: .18),
                  color: onSky,
                  onPressed: () => context.push('/search'),
                ),
                const SizedBox(width: Space.x2),
                _HeroPill(
                  icon: const Icon(Icons.local_fire_department_rounded, size: 16),
                  text: '${streak.days}',
                  onSky: onSky,
                ),
                const SizedBox(width: Space.x1),
                _HeroPill(
                  icon: KamalIcon(size: 15, color: onSky),
                  text: '${streak.kamal}',
                  onSky: onSky,
                ),
              ]),
              const Spacer(),
              Reveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(tithi, color: onSky.withValues(alpha: .85)),
                    const SizedBox(height: Space.x1),
                    ScriptText(
                      hi ? '$greetHi, $who' : '$greetEn, $who',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontFamilyFallback: AppFonts.fallback,
                        fontSize: 32,
                        height: 1.12,
                        color: onSky,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.x3),
                    PrimaryButton(
                      label: hi ? 'आज का दीया जलाएँ' : "Light today's diya",
                      icon: Icons.local_fire_department_rounded,
                      gradient: false,
                      onPressed: () => context.push('/mandir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text, required this.onSky});
  final Widget icon;
  final String text;
  final Color onSky;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Space.x3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: Radii.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(data: IconThemeData(color: onSky, size: 16), child: icon),
          const SizedBox(width: Space.x1),
          Text(text,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onSky,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// A temple skyline silhouette along the hero's bottom edge.
class _SkylinePainter extends CustomPainter {
  const _SkylinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h;
    final p = Path()..moveTo(0, base);
    // Repeating shikhara profile scaled to the width.
    const units = [
      (0.00, 0.78, 0.06), (0.06, 0.62, 0.08), (0.14, 0.70, 0.05), (0.19, 0.50, 0.10),
      (0.29, 0.72, 0.06), (0.35, 0.58, 0.09), (0.44, 0.66, 0.05), (0.49, 0.44, 0.12),
      (0.61, 0.70, 0.06), (0.67, 0.56, 0.08), (0.75, 0.74, 0.05), (0.80, 0.52, 0.10),
      (0.90, 0.68, 0.06), (0.96, 0.80, 0.04),
    ];
    for (final (x, top, ww) in units) {
      final x0 = x * w, x1 = (x + ww) * w, y = base - (1 - top) * h * 0.42;
      p.lineTo(x0, y + 6);
      p.lineTo(x0 + (x1 - x0) / 2, y);
      p.lineTo(x1, y + 6);
    }
    p
      ..lineTo(w, base)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SkylinePainter old) => old.color != color;
}
