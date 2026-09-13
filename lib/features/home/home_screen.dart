import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../mandir/mandir_models.dart';
import '../sadhana/sadhana_models.dart' show kPractices;
import '../sadhana/sadhana_providers.dart'
    show practicesDoneTodayProvider, sadhanaByDayProvider;
import '../../core/providers/app_providers.dart';
import '../../core/user/reading_progress.dart';
import '../../core/user/streak.dart';
import '../../core/user/user_prefs.dart' show dayStamp;
import '../../shared/currency_icons.dart';
import '../../shared/reference_art.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/stitched_border.dart';
import '../astrology/astrology_data.dart' show signNames;
import '../cosmos/cosmos_content.dart' show cGocharThemes, cVerdictLabels;
import '../cosmos/cosmos_providers.dart';
import '../cosmos/daily_cosmos.dart';
import '../cosmos/rashi_glyphs.dart';
import '../panchang/festivals.dart';
import '../panchang/panchang_providers.dart';
import '../quiz/quiz_providers.dart';
import '../scriptures/scripture_models.dart' show Scripture;
import '../scriptures/scripture_providers.dart';
import '../widgets/home_widgets.dart';
import '../../shared/widgets/daily_quote_card.dart';
import '../../shared/widgets/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Count today's visit toward the streak, once, after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).pingToday();
      // Keep any pinned home-screen widgets fresh (best-effort).
      ref.read(verseOfTheDayProvider.future).then((_) {
        if (mounted) refreshHomeWidgets(ref);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final verse = ref.watch(verseOfTheDayProvider);
    final hi = ref.watch(isHindiProvider);

    // Resolve scripture ids by slug so a Home card opens that scripture's
    // chapters directly (falls back to the list if not loaded yet).
    final scriptures = ref.watch(scripturesProvider).asData?.value;
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

    // Re-render the home-screen widgets when the language changes so their
    // labels + verse switch to the new language too.
    ref.listen(localeProvider, (previous, next) {
      if (previous != next) refreshHomeWidgets(ref);
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top bar — stays put while the content below scrolls.
            const _Header(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Daily quote (with change / save / share).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: verse.when(
                // Keep the current verse visible while shuffling to another —
                // otherwise the card flashes the skeleton on every "Change".
                skipLoadingOnReload: true,
                data: (q) => q == null
                    ? const SizedBox.shrink()
                    : DailyQuoteCard(quote: q),
                loading: () => const SkeletonCard(height: 150),
                error: (e, _) => _ErrorNote(message: '$e', hi: hi),
              ),
            ),

            // ---- Room 1: Today — the time-sensitive, date-driven cards.
            // Grouped under one label because all four answer the same
            // question ("what's happening right now?"), where before they
            // were five separately-titled cards indistinguishable from
            // everything else on the page.
            _RoomLabel(hi ? 'आज' : 'Today', dot: AppColors.deityRose),

            // Upcoming / today's festival (only when one is near).
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _FestivalBanner(),
            ),

            // Panchang teaser.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _PanchangCard(),
            ),

            // Daily Rashifal teaser — glance at the selected sign's day.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _RashifalCard(),
            ),

            // Mandir — the day's shrine, before the learning tiles.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _MandirCard(hi: hi),
            ),

            // Sadhana — today's practice, one tap from the daily view.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _SadhanaCard(hi: hi),
            ),

            // ---- Room 2: Explore & Learn — discretionary, mood-driven.
            // Nothing here is time-bound, so it reads as an open invitation
            // rather than a checklist, distinct from Today's urgency.
            _RoomLabel(hi ? 'अभ्यास और ज्ञान' : 'Explore & Learn',
                dot: AppColors.dharmaPurple),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _EngageTile(
                    coverImage: quizBg,
                    title: hi ? 'प्रश्नोत्तरी' : 'Quiz',
                    color: AppColors.sacredGreen,
                    onTap: () => context.push('/quiz/play'),
                  ),
                  _EngageTile(
                    image: japaBadge,
                    title: hi ? 'जप' : 'Japa',
                    color: const Color(0xFFD26A2E),
                    onTap: () => context.push('/japa'),
                  ),
                  _EngageTile(
                    title: hi ? 'प्राणायाम' : 'Breathing',
                    color: const Color(0xFF3E7C8C),
                    onTap: () => context.push('/breathing'),
                  ),
                  _EngageTile(
                    title: hi ? 'पहेलियाँ' : 'Riddles',
                    color: AppColors.dharmaPurple,
                    onTap: () => context.push('/riddles'),
                  ),
                ],
              ),
            ),

            // Did You Know? — a rotating trivia fact with reshuffle.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: _DidYouKnowCard(),
            ),

            // Personality — Discover Your Soul Path.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: _SoulPathCard(
                hi: hi,
                onTap: () => context.push('/personality'),
              ),
            ),

            // Explore Gyan is intentionally NOT here — it already has its own
            // bottom-nav tab (see NavScaffold), so a second full rail on Home
            // was pure duplication, not a second way in.

            // Continue reading — the single most direct path back into the
            // exact verse someone left off at, rather than making them
            // re-navigate scripture -> book -> page. Absent entirely until
            // at least one book has been opened, so a first-run Home never
            // shows a hollow "0% read" card.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: _ContinueReadingCard(),
            ),

            // ---- Room 3: Scriptures & Wisdom — the app's actual library.
            // Previously five unrelated cards (scriptures, mantras/aartis,
            // puja vidhi, habits, stories) each announced by their own small
            // heading or none at all; now one room, sub-headed per shelf.
            _RoomLabel(hi ? 'ग्रंथ और ज्ञान' : 'Scriptures & Wisdom',
                dot: AppColors.terracotta),
            _SectionTitle(hi ? 'ग्रंथ' : 'Scriptures'),
            _ScriptureCarousel(
              hi: hi,
              scriptures: [
                _ScriptureSpec(
                  title: hi ? 'भगवद्गीता' : 'Bhagavad Gita',
                  kicker: hi ? '18 अध्याय · 701 श्लोक' : '18 chapters · 701 verses',
                  subtitle: hi
                      ? 'श्रीकृष्ण द्वारा अर्जुन को दिए कालजयी उपदेश जानें'
                      : "Krishna's timeless teachings to Arjuna",
                  image: scriptureImage('gita'),
                  color: AppColors.gold,
                  onTap: () => openScripture('bhagavad-gita'),
                ),
                _ScriptureSpec(
                  title: hi ? 'रामायण' : 'Ramayana',
                  kicker: hi ? '7 काण्ड' : '7 kandas',
                  subtitle: hi
                      ? 'धर्म की इस महागाथा में श्रीराम की यात्रा'
                      : "Rama's journey through this epic of dharma",
                  image: scriptureImage('ramayana'),
                  color: AppColors.terracotta,
                  onTap: () => openScripture('valmiki-ramayana'),
                ),
                _ScriptureSpec(
                  title: hi ? 'उपनिषद्' : 'Upanishads',
                  kicker: hi ? 'गूढ़ ज्ञान' : 'Deep wisdom',
                  subtitle: hi
                      ? 'सरल भाषा में उपनिषदों का गहन ज्ञान'
                      : 'Deep wisdom, in plain modern language',
                  image: scriptureImage('upanishads'),
                  color: AppColors.sacredGreen,
                  onTap: () => openScripture('upanishads'),
                ),
              ],
            ),

            // Mantras · Aartis — a shelf inside Scriptures & Wisdom, not its
            // own room: downgraded from a full _SectionTitle to a subtler
            // in-room heading so the room reads as one place, not five.
            _SubShelfLabel(hi ? 'आध्यात्मिक ज्ञान' : 'Spiritual Enlightenment'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _EnlightenCard(
                      icon: Icons.self_improvement_rounded,
                      artwork: Image.asset(mantrasImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColors.dharmaPurple,
                              child: Icon(Icons.self_improvement_rounded,
                                  color: Colors.white, size: 34))),
                      title: hi ? 'मंत्र' : 'Mantras',
                      subtitle: hi ? 'पवित्र जाप' : 'Sacred chants',
                      color: AppColors.dharmaPurple,
                      onTap: () => context.push('/mantras'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EnlightenCard(
                      icon: Icons.local_fire_department_rounded,
                      artwork: Image.asset(aartisImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColors.terracotta,
                              child: Icon(Icons.local_fire_department_rounded,
                                  color: Colors.white, size: 34))),
                      title: hi ? 'आरती' : 'Aartis',
                      subtitle: hi ? 'भक्ति गान' : 'Devotional songs',
                      color: AppColors.terracotta,
                      onTap: () => context.push('/aartis'),
                    ),
                  ),
                ],
              ),
            ),

            // Puja Vidhi.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: _WideCard(
                icon: Icons.local_fire_department_outlined,
                title: hi ? 'पूजा विधि' : 'Puja Vidhi',
                subtitle: hi
                    ? 'त्योहार • व्रत • संस्कार • चरण-दर-चरण'
                    : 'Festivals • Vrat • Sanskaras • Step-by-step',
                color: AppColors.gold,
                bg: AppColors.gold.withValues(alpha: 0.12),
                onTap: () => context.push('/puja'),
              ),
            ),

            // Habits (its own card, as in the reference).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _WideCard(
                icon: Icons.checklist_rtl_rounded,
                title: hi ? 'आदतें' : 'Habits',
                subtitle:
                    hi ? 'छोटी चुनौतियाँ, बड़ा बदलाव' : 'Small challenges, big change',
                color: AppColors.terracotta,
                bg: Theme.of(context).colorScheme.surface,
                onTap: () => context.push('/habits'),
              ),
            ),

            // Stories — color-coded emotion tiles. Another shelf, same room.
            _SubShelfLabel(hi ? 'कथाएँ' : 'Stories'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  for (final e in _emotions)
                    _StoryTile(
                      label: hi ? e.hi : e.en,
                      en: e.en,
                      color: e.color,
                      onTap: () =>
                          context.push('/katha', extra: e.en.toLowerCase()),
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

/// A color-coded emotion for the Stories grid.
class _Emotion {
  final String en;
  final String hi;
  final Color color;
  const _Emotion(this.en, this.hi, this.color);
}

const _emotions = <_Emotion>[
  _Emotion('Anger', 'क्रोध', Color(0xFFC0392B)),
  _Emotion('Joy', 'आनंद', Color(0xFFDDA000)),
  _Emotion('Peace', 'शांति', Color(0xFF2E8B8B)),
  _Emotion('Love', 'प्रेम', Color(0xFFD9748C)),
  _Emotion('Fear', 'भय', Color(0xFF4A4A8A)),
  _Emotion('Faith', 'श्रद्धा', Color(0xFF5E8C74)),
];

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final streak = ref.watch(streakProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              AppLogo(size: 34),
              SizedBox(width: 10),
              AppWordmark(fontSize: 24),
            ],
          ),
          Row(
            children: [
              // Universal search. Home is the natural "everything" surface, and
              // this keeps search off the tab bar, which is already tight with
              // Hindi labels.
              IconButton(
                icon: const Icon(Icons.search_rounded),
                color: scheme.primary,
                visualDensity: VisualDensity.compact,
                tooltip: ref.watch(isHindiProvider) ? 'खोजें' : 'Search',
                onPressed: () => context.push('/search'),
              ),
              _Pill(
                icon: Icons.local_fire_department_rounded,
                text: '${streak.days}',
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              _Pill(
                leading: const KamalIcon(size: 15),
                text: '${streak.kamal}',
                color: AppColors.deityRose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String text;
  final Color color;
  const _Pill(
      {this.icon, this.leading, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

/// A centered terracotta serif section title, as on the reference home.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A small uppercase room label — "Today" / "Explore & Learn" / "Scriptures
/// & Wisdom" — with a colored dot naming that room's own accent. Unlike
/// [_SectionTitle] (which announces one card, e.g. "Scriptures"), this marks
/// the start of a *group* of otherwise unrelated cards so the long Home
/// scroll reads as a few rooms instead of one flat list.
class _RoomLabel extends StatelessWidget {
  final String text;
  final Color dot;
  const _RoomLabel(this.text, {required this.dot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet in-room heading — "Mantras · Aartis", "Stories" — for a shelf
/// that lives inside a room already announced by [_RoomLabel]. Smaller and
/// left-aligned rather than [_SectionTitle]'s centered display type, so it
/// reads as "still the same room, next shelf" instead of a new section.
class _SubShelfLabel extends StatelessWidget {
  final String text;
  const _SubShelfLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// A big color-coded tile for the Engage & Learn grid.
class _EngageTile extends StatelessWidget {
  final String? image; // badge art in the corner
  final String? coverImage; // full-bleed background art
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _EngageTile(
      {this.image,
      this.coverImage,
      required this.title,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: cover image, or the color gradient.
              if (coverImage != null)
                Image.asset(coverImage!,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => ColoredBox(color: color))
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, Color.lerp(color, Colors.black, 0.28)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              // Scrim so white text reads on any art.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              // Badge art (only in the non-cover style) in the corner.
              if (coverImage == null && image != null)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Image.asset(image!,
                      height: 78,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
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

/// A scripture row card: the illustration sits on the left, framed by the
/// signature dashed "stitched" border on its outer edge, with the title and a
/// one-line description on the right.
/// One scripture's carousel-card content — a plain data holder so
/// [_ScriptureCarousel] can lay all three out identically.
class _ScriptureSpec {
  final String title;
  final String kicker;
  final String subtitle;
  final String? image;
  final Color color;
  final VoidCallback onTap;
  const _ScriptureSpec({
    required this.title,
    required this.kicker,
    required this.subtitle,
    this.image,
    required this.color,
    required this.onTap,
  });
}

/// The app's three headline scriptures as a swipeable, full-bleed carousel
/// with a dot pager — replaces three stacked list rows, which buried Ramayana
/// and Upanishads below the fold and gave none of the three room to feel like
/// the centrepiece texts they are.
class _ScriptureCarousel extends StatefulWidget {
  final bool hi;
  final List<_ScriptureSpec> scriptures;
  const _ScriptureCarousel({required this.hi, required this.scriptures});

  @override
  State<_ScriptureCarousel> createState() => _ScriptureCarouselState();
}

class _ScriptureCarouselState extends State<_ScriptureCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.82);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.scriptures.length,
            itemBuilder: (context, i) {
              final s = widget.scriptures[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 16 : 8,
                  right: i == widget.scriptures.length - 1 ? 16 : 8,
                ),
                child: _ScriptureSlide(spec: s),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.scriptures.length, (i) {
            final active = (_page.round() == i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active
                    ? widget.scriptures[i].color
                    : widget.scriptures[i].color.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ScriptureSlide extends StatelessWidget {
  final _ScriptureSpec spec;
  const _ScriptureSlide({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: spec.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: spec.color,
            image: spec.image == null
                ? null
                : DecorationImage(
                    image: AssetImage(spec.image!),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.kicker.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(spec.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Mantras/Aartis illustrated-style card.
class _EnlightenCard extends StatelessWidget {
  final IconData icon;

  /// Custom vector illustration filling the card's art slot (falls back to
  /// [icon] on a gradient if null).
  final Widget? artwork;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _EnlightenCard(
      {required this.icon,
      this.artwork,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 92,
                  width: double.infinity,
                  child: artwork ??
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            color.withValues(alpha: 0.9),
                            Color.lerp(color, Colors.black, 0.3)!,
                          ]),
                        ),
                        child: Icon(icon, color: Colors.white, size: 34),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.6))),
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

/// A full-width card (Puja Vidhi, Habits).
class _WideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _WideCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurface.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The featured "Discover Your Soul Path" personality-test card.
/// An invitation to the personality quiz, not a settings-style row — the
/// gradient, the large serif title and the pill CTA are meant to read like
/// the opener screen of the quiz itself, so tapping in feels like starting
/// something rather than merely navigating.
class _SoulPathCard extends StatelessWidget {
  final bool hi;
  final VoidCallback onTap;
  const _SoulPathCard({required this.hi, required this.onTap});

  static const _questionCount = 8;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.dharmaPurple, Color(0xFF3B2A63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // A faint oversized glyph bleeding off the corner — the same
              // "quiet ornament" trick the app already uses on hero cards,
              // so this reads as a considered surface, not a flat banner.
              Positioned(
                right: -8,
                bottom: -14,
                child: Opacity(
                  opacity: 0.12,
                  child: Text('☾',
                      style: TextStyle(
                          fontSize: 92,
                          fontFamily: AppFonts.display,
                          color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        (hi
                                ? 'व्यक्तित्व · 2 मिनट'
                                : 'Personality · 2 min')
                            .toUpperCase(),
                        style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.72))),
                    const SizedBox(height: 6),
                    Text(
                        hi
                            ? 'अपना आध्यात्मिक\nमार्ग जानें'
                            : 'Discover Your\nSoul Path',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            height: 1.15,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                        hi
                            ? 'त्रिगुण पर आधारित 8 प्रश्न'
                            : '8 questions, rooted in the three gunas',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.78))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            _questionCount,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            hi
                                ? '$_questionCount प्रश्न'
                                : '$_questionCount questions',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hi ? 'शुरू करें' : 'Begin',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: Colors.white)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
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

/// A "Did You Know?" card cycling trivia facts, with a reshuffle button.
class _DidYouKnowCard extends ConsumerStatefulWidget {
  const _DidYouKnowCard();

  @override
  ConsumerState<_DidYouKnowCard> createState() => _DidYouKnowCardState();
}

class _DidYouKnowCardState extends ConsumerState<_DidYouKnowCard> {
  int _i = 0;

  /// How many progress dots to draw. Capped rather than one-per-fact: with
  /// hundreds of trivia rows, a literal dot per fact would be meaningless
  /// noise — this just signals "there's a deck here, keep tapping."
  static const _maxDots = 5;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final trivia = ref.watch(triviaProvider);
    final scheme = Theme.of(context).colorScheme;

    final fact = trivia.maybeWhen(
      data: (facts) =>
          facts.isEmpty ? null : facts[_i % facts.length].text(hi),
      orElse: () => null,
    );
    final count = trivia.maybeWhen(data: (f) => f.length, orElse: () => 0);
    final dots = count < _maxDots ? count : _maxDots;

    return StitchedCard(
      background: scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHighest
          : AppColors.kraft2,
      stitchColor: AppColors.terracotta.withValues(alpha: 0.4),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(hi ? 'क्या आप जानते हैं?' : 'DID YOU KNOW',
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracotta.withValues(alpha: 0.9))),
                ],
              ),
              if (dots > 1)
                Row(
                  children: List.generate(
                    dots,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i == _i % dots
                              ? AppColors.terracotta
                              : AppColors.terracotta.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fact ?? (hi ? 'रोचक तथ्य लोड हो रहे…' : 'Loading facts…'),
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 16.5,
                height: 1.42,
                color: scheme.onSurface.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: count == 0
                    ? null
                    : () => setState(() => _i = (_i + 1) % count),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hi ? 'अगला तथ्य' : 'Next fact',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.terracotta)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 15, color: AppColors.terracotta),
                    ],
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

class _StoryTile extends StatelessWidget {
  final String label;
  final String en;
  final Color color;
  final VoidCallback onTap;
  const _StoryTile(
      {required this.label,
      required this.en,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = emotionImage(en);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null)
                  Image.asset(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                // Scrim so the label stays legible over the art.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.72),
                        color.withValues(alpha: 0.30),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
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

/// Today's Panchang — a clean, single-column card: date + masa/paksha header,
/// a Tithi/Nakshatra/Yoga/Karana grid, sunrise/sunset, Rahu Kaal, and two
/// actions (View Panchang · Full Calendar). All values computed on-device.
class _PanchangCard extends ConsumerWidget {
  const _PanchangCard();

  static const _accent = AppColors.terracotta; // brass — this room's color

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
  static Color _ink(ColorScheme s) => s.onSurface;
  static Color _label(ColorScheme s) => s.onSurface.withValues(alpha: 0.5);
  static Color _muted(ColorScheme s) => s.onSurface.withValues(alpha: 0.4);
  static Color _dash(ColorScheme s) => s.onSurface.withValues(alpha: 0.14);

  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthsHi = [
    'जन', 'फ़र', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुल', 'अग', 'सित', 'अक्तू', 'नव', 'दिस'
  ];

  static String _time(DateTime? d) {
    if (d == null) return '—';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final p = ref.watch(panchangProvider);
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;

    final waxing = p.paksha.en.toLowerCase().contains('shukla');
    final moonPhase = waxing
        ? (hi ? 'शुक्ल पक्ष' : 'Waxing')
        : (hi ? 'कृष्ण पक्ष' : 'Waning');
    dynamic rahu;
    for (final m in p.muhurats) {
      if (m.name.en.toLowerCase().contains('rahu')) {
        rahu = m;
        break;
      }
    }

    return StitchedCard(
      background: _bg(scheme),
      stitchColor: _accent.withValues(alpha: 0.45),
      radius: 20,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header: date + day + masa · paksha ----
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${now.day}',
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${hi ? p.vara(true) : _weekdaysEn[now.weekday - 1]}, ${(hi ? _monthsHi : _monthsEn)[now.month - 1]} ${now.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: _ink(scheme))),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                              waxing
                                  ? Icons.nightlight_round
                                  : Icons.dark_mode,
                              size: 15,
                              color: const Color(0xFFCB9B3E)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                '${p.month(hi)} · ${p.paksha(hi)} ($moonPhase)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.5, color: _label(scheme))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _DashedLine(color: _dash(scheme)),
            // Tithi leads as the hero fact — that's the one thing a reader
            // actually opens this card to check ("what day is it, for
            // fasting/puja purposes") — everything else demotes beneath it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: waxing
                          ? const [
                              Color(0xFFFCEFD8),
                              Color(0xFFE8B98A),
                              Color(0xFF9C5A28)
                            ]
                          : [
                              scheme.onSurface.withValues(alpha: 0.5),
                              scheme.onSurface.withValues(alpha: 0.28),
                              scheme.onSurface.withValues(alpha: 0.16),
                            ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.tithi.current(hi),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: _ink(scheme))),
                      Text(
                          '${p.tithi.endTime == null ? (hi ? 'पूरे दिन' : 'all day') : '${hi ? 'तक ' : 'till '}${_time(p.tithi.endTime)}'} · ${p.nakshatra.current(hi)} ${hi ? 'नक्षत्र' : 'nakshatra'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: _label(scheme))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // A sunrise-to-sunset day bar with Rahu Kaal marked as a hazard
            // zone — a window a reader can *see*, not decode from a label.
            _DayBar(
              scheme: scheme,
              hi: hi,
              sunrise: p.sunrise,
              sunset: p.sunset,
              rahuStart: rahu?.start,
              rahuEnd: rahu?.end,
            ),
            const SizedBox(height: 10),
            if (rahu != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 14, color: scheme.error),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                        '${hi ? 'राहु काल' : 'Rahu Kaal'} ${_time(rahu.start)}–${_time(rahu.end)} — ${hi ? 'नई शुरुआत से बचें' : 'avoid new beginnings'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: scheme.error)),
                  ),
                ],
              ),
            _DashedLine(color: _dash(scheme)),
            // Yoga · Karana · Add-to-widget — demoted to a compact strip.
            Row(children: [
              _element(scheme, hi ? 'योग' : 'Yoga', p.yoga, hi),
              _element(scheme, hi ? 'करण' : 'Karana', p.karana, hi),
              _widgetOption(scheme, hi, () => pinPanchangWidget(ref)),
            ]),
            const SizedBox(height: 14),
            // ---- Actions ----
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.wb_sunny_outlined,
                    label: hi ? 'पंचांग देखें' : 'View Panchang',
                    onTap: () => context.push('/panchang'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.calendar_month_rounded,
                    label: hi ? 'पूर्ण कैलेंडर' : 'Full Calendar',
                    onTap: () => context.push('/calendar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _element(ColorScheme s, String label, dynamic el, bool hi) =>
      _cell(
        s,
        label,
        el.current(hi),
        el.endTime == null
            ? (hi ? 'पूरे दिन' : 'all day')
            : '${hi ? 'तक ' : 'till '}${_time(el.endTime)}',
      );

  /// A labelled cell — LABEL / value / optional sub-line.
  static Widget _cell(ColorScheme s, String label, String value, String? sub) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: _label(s))),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: _ink(s))),
            if (sub != null && sub.isNotEmpty)
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: _muted(s))),
          ],
        ),
      );

  /// The "add to home-screen widget" slot (shown beside sunrise/sunset).
  static Widget _widgetOption(ColorScheme s, bool hi, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.widgets_rounded, size: 14, color: _accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(hi ? 'विजेट' : 'WIDGET',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: _label(s))),
                ),
              ]),
              const SizedBox(height: 2),
              Text(hi ? 'होम पर जोड़ें' : 'Add to home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
            ],
          ),
        ),
      );

  static Widget _actionBtn(
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      Material(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: _accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: _accent)),
                ),
              ],
            ),
          ),
        ),
      );
}

/// A sunrise-to-sunset bar with Rahu Kaal shaded on it as a hazard zone —
/// turns "avoid this window" into something seen at a glance rather than a
/// time range that has to be read and mentally placed in the day.
class _DayBar extends StatelessWidget {
  final ColorScheme scheme;
  final bool hi;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? rahuStart;
  final DateTime? rahuEnd;

  const _DayBar({
    required this.scheme,
    required this.hi,
    required this.sunrise,
    required this.sunset,
    required this.rahuStart,
    required this.rahuEnd,
  });

  static String _time(DateTime? d) {
    if (d == null) return '—';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context) {
    final rise = sunrise ?? DateTime.now();
    final set = sunset ?? rise.add(const Duration(hours: 12));
    final totalMin = set.difference(rise).inMinutes.clamp(1, 24 * 60);
    double frac(DateTime? d) {
      if (d == null) return 0;
      return (d.difference(rise).inMinutes / totalMin).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hi ? 'सूर्योदय ${_time(sunrise)}' : 'Sunrise ${_time(sunrise)}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            Text(hi ? 'सूर्यास्त ${_time(sunset)}' : 'Sunset ${_time(sunset)}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(colors: [
                        AppColors.terracottaBright,
                        const Color(0xFFF4D9A8),
                        const Color(0xFFF4D9A8),
                        scheme.onSurface.withValues(alpha: 0.35),
                      ]),
                    ),
                  ),
                  if (rahuStart != null && rahuEnd != null)
                    Positioned(
                      left: (frac(rahuStart) * w).clamp(0, w - 4),
                      width:
                          ((frac(rahuEnd) - frac(rahuStart)) * w).clamp(4, w),
                      top: -2,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _bg(scheme), width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
}

/// A one-glance daily Rashifal teaser for the reader's selected moon sign —
/// sign glyph, today's star rating and the one-line Chandra-gochar reading.
/// Taps through to the full Rashifal tab. Computed on-device (no birth data).
class _RashifalCard extends ConsumerWidget {
  const _RashifalCard();

  static const _accent = AppColors.dharmaPurple; // violet — this room's color

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
  static Color _ink(ColorScheme s) => s.onSurface;
  static Color _label(ColorScheme s) => s.onSurface.withValues(alpha: 0.5);

  /// A coarse 1-5 star read straight off the same [Verdict] the badge used
  /// to show as text — no invented precision, just that tone made visual.
  static int _stars(Verdict v) => switch (v) {
        Verdict.favourable => 4,
        Verdict.mixed => 3,
        Verdict.challenging => 2,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final moonRashi = ref.watch(transitMoonRashiProvider);
    final rashi = ref.watch(selectedRashiProvider);
    final house = gocharHouseFrom(rashi, moonRashi);
    final verdict = rashiVerdict(house);
    final line = cGocharThemes[house - 1].call(hi);
    final vColor = switch (verdict) {
      Verdict.favourable => AppColors.sacredGreen,
      Verdict.mixed => AppColors.gold,
      Verdict.challenging => AppColors.terracotta,
    };
    final stars = _stars(verdict);

    return StitchedCard(
      background: _bg(scheme),
      stitchColor: _accent.withValues(alpha: 0.45),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, _accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: RashiGlyph(index: rashi, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The verdict itself leads — that's the one thing a
                    // reader actually wants to know at a glance.
                    Text(cVerdictLabels[verdict.index].call(hi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: vColor)),
                    const SizedBox(height: 2),
                    Text(
                        hi
                            ? '${signNames[rashi].call(hi)} के लिए · आज'
                            : 'for ${signNames[rashi].call(hi)} · today',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: _label(scheme))),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 15,
                          color: i < stars
                              ? const Color(0xFFD9A441)
                              : _label(scheme),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(line,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: _ink(scheme).withValues(alpha: 0.82))),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.push('/cosmos'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hi ? 'पूर्ण विवरण' : 'Full reading',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _accent)),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: _accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact banner for today's or an upcoming festival (within ~20 days).
/// Hidden when nothing is near. Taps open the festival detail sheet.
class _FestivalBanner extends ConsumerWidget {
  const _FestivalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final tz = DateTime.now().timeZoneOffset;
    final next = nextFestival(DateTime.now(), tz, withinDays: 20);
    if (next == null) return const SizedBox.shrink();

    final days = next.daysAway;
    final when = days <= 0
        ? (hi ? 'आज' : 'Today')
        : days == 1
            ? (hi ? 'कल' : 'Tomorrow')
            : DateFormat('d MMM').format(next.date);
    final heading = days <= 0
        ? (hi ? 'आज का पर्व' : "Today's Festival")
        : (hi ? 'आगामी पर्व' : 'Upcoming Festival');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Opens the Explorer rather than a one-off sheet: the same festival
        // leads that list, and from there the whole year is reachable.
        onTap: () => context.push('/festivals'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.secondary.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: CustomPaint(
            foregroundPainter: StitchedBorderPainter(
              color: scheme.primary.withValues(alpha: 0.4),
              radius: 13,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🪔', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(heading.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.55))),
                      const SizedBox(height: 2),
                      Text(next.hit.name(hi),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.15)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: scheme.primary)),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The signature dashed "stitched" divider — same motif as the Verse card.
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 1.6,
          width: double.infinity,
          child: CustomPaint(painter: _DashPainter(color)),
        ),
      );
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _ErrorNote extends StatelessWidget {
  final String message;
  final bool hi;
  const _ErrorNote({required this.message, required this.hi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(hi
          ? 'सामग्री लोड नहीं हो सकी:\n$message'
          : 'Could not load content:\n$message'),
    );
  }
}

/// Home entry to the shrine. Says whether the offering window is open, because
/// that is the only thing about the Mandir that changes hour to hour.
class _MandirCard extends StatelessWidget {
  final bool hi;
  const _MandirCard({required this.hi});

  @override
  Widget build(BuildContext context) {
    final free = MandirWindows.isFree();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/mandir'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A251F), Color(0xFF241713)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(
          foregroundPainter: StitchedBorderPainter(
            color: const Color(0xFFE8B347).withValues(alpha: 0.45),
            radius: 13,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              // A living diya rather than a static temple icon — a warm glow
              // when the offering window is open, dimmed when it is not, so
              // the one thing that actually changes hour to hour is visible
              // before a reader even reads the caption.
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (free)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFFE8B347).withValues(alpha: 0.35),
                            const Color(0xFFE8B347).withValues(alpha: 0),
                          ]),
                        ),
                      ),
                    Text('🪔',
                        style: TextStyle(
                            fontSize: 28,
                            color: free
                                ? null
                                : Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hi ? 'मंदिर' : 'Mandir',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: Color(0xFFFCEFE2))),
                    const SizedBox(height: 3),
                    Text(
                      free
                          ? (hi
                              ? 'अर्पण का समय खुला है'
                              : 'The offering window is open')
                          : (hi ? 'दर्शन करें' : 'Visit the shrine'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: free
                            ? const Color(0xFFE8B347)
                            : const Color(0xFFFCEFE2).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE6C34A)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resumes at the exact verse someone left off at — the book title, a
/// progress bar, and a tap straight into `/scriptures/book/:id?v=:index`,
/// rather than making a returning reader retrace scripture -> book -> page
/// on their own. Reads the same `readingProgressProvider` the You tab's
/// `YourReadingSection` already aggregates from; this just surfaces its
/// single most useful row (the most recently read book) at the top of Home,
/// where a returning reader actually looks first.
class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final progress = ref.watch(readingProgressProvider);
    if (progress.isEmpty) return const SizedBox.shrink();
    final recent = ref.read(readingProgressProvider.notifier).mostRecent;
    if (recent == null) return const SizedBox.shrink();

    final book = ref.watch(scriptureBookProvider(recent.bookId)).valueOrNull;
    // The card names the book, so it stays hidden until that title has
    // actually loaded rather than showing "Continue reading" with nothing
    // to continue.
    if (book == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(
          '/scriptures/book/${recent.bookId}?v=${recent.lastSectionIdx}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7A4A1E), Color(0xFF4A2A10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Color(0xFFE6C34A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hi ? 'पढ़ना जारी रखें' : 'Continue reading',
                      style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE6C34A))),
                  const SizedBox(height: 2),
                  Text(book.title(hi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFFFCEFE2))),
                  if (recent.sectionsTotal > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: recent.fraction,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: const Color(0xFFE6C34A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hi
                          ? '${recent.percent}% पूर्ण'
                          : '${recent.percent}% complete',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFFFCEFE2).withValues(alpha: 0.75)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFE6C34A)),
          ],
        ),
      ),
    );
  }
}

/// Home entry to the Sadhana hub. Says how many of today's practices are
/// done, because that is the one number a daily-practice tracker should lead
/// with — not a streak, which frames the whole thing as a score to protect.
class _SadhanaCard extends ConsumerWidget {
  final bool hi;
  const _SadhanaCard({required this.hi});

  static const _accent = AppColors.sacredGreen; // sage — this room's color
  static const _ring = Color(0xFF8FDDDF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(practicesDoneTodayProvider).valueOrNull ?? 0;
    final byDay = ref.watch(sadhanaByDayProvider).valueOrNull ?? const {};
    final total = kPractices.length;
    final today = dayStamp();
    final doneKeys = {
      for (final e in byDay.entries)
        if ((e.value[today] ?? 0) > 0) e.key,
    };
    final nextUp = [
      for (final p in kPractices)
        if (!doneKeys.contains(p.key)) p.label(hi),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/sadhana'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F5D6B), Color(0xFF16323C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(
          foregroundPainter: StitchedBorderPainter(
            color: _accent.withValues(alpha: 0.45),
            radius: 13,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              // A real ring showing done/total, not a static icon.
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(_ring),
                      ),
                    ),
                    Text('$done/$total',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFFCEFE2))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hi ? 'आज का अभ्यास' : "Today's practice",
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Color(0xFFFCEFE2))),
                    const SizedBox(height: 7),
                    // A dot per practice — done ones filled — instead of a
                    // sentence spelling out the same count in words.
                    Row(
                      children: [
                        for (final p in kPractices)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: doneKeys.contains(p.key)
                                    ? _ring
                                    : Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextUp.isEmpty
                          ? (hi ? 'सभी अभ्यास पूर्ण 🎉' : 'All done today 🎉')
                          : '${hi ? 'शेष' : 'Next'}: ${nextUp.join(' · ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFFFCEFE2).withValues(alpha: 0.72)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8FDDDF)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
