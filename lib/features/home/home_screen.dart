import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../gyan/gyan_home_section.dart';
import '../mandir/mandir_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
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

            // Upcoming / today's festival (only when one is near).
            const _FestivalBanner(),

            // Panchang teaser.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _PanchangCard(),
            ),

            // Daily Rashifal teaser — glance at the selected sign's day.
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _RashifalCard(),
            ),

            // Mandir — the day's shrine, before the learning tiles.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _MandirCard(hi: hi),
            ),

            // Engage & Learn — Quiz · Japa · Breathing · Riddles.
            _SectionTitle(hi ? 'अभ्यास और ज्ञान' : 'Engage & Learn'),
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

            // Explore Gyan — entry point to the 14 knowledge modules.
            const GyanHomeSection(),

            // Scriptures — one per row, each opening its chapters directly.
            _SectionTitle(hi ? 'ग्रंथ' : 'Scriptures'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  _ScriptureCard(
                    title: hi ? 'भगवद्गीता' : 'Bhagavad Gita',
                    subtitle: hi
                        ? 'श्रीकृष्ण द्वारा अर्जुन को दिए कालजयी उपदेश जानें'
                        : 'Discover the timeless teachings of Krishna to Arjuna',
                    image: scriptureImage('gita'),
                    color: AppColors.gold,
                    onTap: () => openScripture('bhagavad-gita'),
                  ),
                  const SizedBox(height: 12),
                  _ScriptureCard(
                    title: hi ? 'रामायण' : 'Ramayana',
                    subtitle: hi
                        ? 'धर्म की इस महागाथा में श्रीराम की यात्रा के साथ चलें'
                        : 'Follow the journey of Rama in this epic tale of dharma',
                    image: scriptureImage('ramayana'),
                    color: AppColors.terracotta,
                    onTap: () => openScripture('valmiki-ramayana'),
                  ),
                  const SizedBox(height: 12),
                  _ScriptureCard(
                    title: hi ? 'उपनिषद्' : 'Upanishads',
                    subtitle: hi
                        ? 'उपनिषदों के गूढ़ ज्ञान की गहराइयों में उतरें'
                        : 'Dive into the profound wisdom of the Upanishads',
                    image: scriptureImage('upanishads'),
                    color: AppColors.sacredGreen,
                    onTap: () => openScripture('upanishads'),
                  ),
                ],
              ),
            ),

            // Spiritual Enlightenment — Mantras · Aartis.
            _SectionTitle(hi ? 'आध्यात्मिक ज्ञान' : 'Spiritual Enlightenment'),
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

            // Stories — color-coded emotion tiles.
            _SectionTitle(hi ? 'कथाएँ' : 'Stories'),
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
  _Emotion('Love', 'प्रेम', Color(0xFF9C2950)),
  _Emotion('Fear', 'भय', Color(0xFF4A4A8A)),
  _Emotion('Faith', 'श्रद्धा', Color(0xFF25533F)),
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
class _ScriptureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final Color color;
  final VoidCallback onTap;
  const _ScriptureCard(
      {required this.title,
      required this.subtitle,
      this.image,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Light, per-scripture tint (each card a different soft colour).
            color: Color.alphaBlend(
                color.withValues(alpha: 0.13), scheme.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Illustration on the left. The stitched border is drawn on the
              // outer edge (inset ~2) while the image is padded inwards, so the
              // stitch frames the picture instead of sitting over it. Its colour
              // matches the "Scriptures" heading (theme primary).
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  foregroundPainter: StitchedBorderPainter(
                    color: scheme.primary,
                    inset: 2,
                    radius: 14,
                    strokeWidth: 1.4,
                    dash: 4.5,
                    gap: 3.5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: image != null
                          ? Image.asset(image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  ColoredBox(color: color))
                          : ColoredBox(color: color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title + one-line description on the right.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: scheme.onSurface.withValues(alpha: 0.6),
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
class _SoulPathCard extends StatelessWidget {
  final bool hi;
  final VoidCallback onTap;
  const _SoulPathCard({required this.hi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5A2EA8), Color(0xFF3B2A63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          hi
                              ? 'अपना आध्यात्मिक मार्ग जानें'
                              : 'Discover Your Soul Path',
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                          hi
                              ? 'व्यक्तित्व परीक्षण · 8 प्रश्न'
                              : 'Personality test · 8 questions',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
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

    return StitchedCard(
      background: AppColors.kraft2,
      stitchColor: AppColors.terracotta.withValues(alpha: 0.4),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'क्या आप जानते हैं?' : 'DID YOU KNOW?',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta.withValues(alpha: 0.9))),
          const SizedBox(height: 8),
          Text(
            fact ?? (hi ? 'रोचक तथ्य लोड हो रहे…' : 'Loading facts…'),
            style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                fontFamily: hi ? AppFonts.devanagari : AppFonts.body,
                color: scheme.onSurface.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.terracotta.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: count == 0
                    ? null
                    : () => setState(() => _i = (_i + 1) % count),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.autorenew_rounded,
                          size: 16, color: AppColors.terracotta),
                      const SizedBox(width: 6),
                      Text(hi ? 'बदलें' : 'Change',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.terracotta)),
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

  static const _bg = Color(0xFFF5EEE1);
  static const _accent = Color(0xFFBE5A24);
  static const _ink = Color(0xFF3A2A20);
  static const _label = Color(0xFF9C8B79);
  static const _muted = Color(0xFFAD9C89);

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

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
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
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: _ink)),
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
                                style: const TextStyle(
                                    fontSize: 12.5, color: _label)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const _DashedLine(color: Color(0xFFCBBBA0)),
            // Tithi · Nakshatra · Yoga on one line.
            Row(children: [
              _element(hi ? 'तिथि' : 'Tithi', p.tithi, hi),
              _element(hi ? 'नक्षत्र' : 'Nakshatra', p.nakshatra, hi),
              _element(hi ? 'योग' : 'Yoga', p.yoga, hi),
            ]),
            const SizedBox(height: 14),
            // Karana · Rahu Kaal on one line (Rahu Kaal gets half the width).
            Row(children: [
              _element(hi ? 'करण' : 'Karana', p.karana, hi),
              _cell(
                hi ? 'राहु काल' : 'Rahu Kaal',
                rahu == null
                    ? '—'
                    : '${_time(rahu.start)}–${_time(rahu.end)}',
                null,
              ),
            ]),
            const _DashedLine(color: Color(0xFFCBBBA0)),
            // Sunrise · Sunset · Add-to-widget.
            Row(children: [
              _stat(Icons.wb_sunny_rounded, hi ? 'सूर्योदय' : 'Sunrise',
                  _time(p.sunrise)),
              _stat(Icons.wb_twilight_rounded, hi ? 'सूर्यास्त' : 'Sunset',
                  _time(p.sunset)),
              _widgetOption(hi, () => pinPanchangWidget(ref)),
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

  static Widget _element(String label, dynamic el, bool hi) => _cell(
        label,
        el.current(hi),
        el.endTime == null
            ? (hi ? 'पूरे दिन' : 'all day')
            : '${hi ? 'तक ' : 'till '}${_time(el.endTime)}',
      );

  /// A labelled cell — LABEL / value / optional sub-line.
  static Widget _cell(String label, String value, String? sub) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: _label)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: _ink)),
            if (sub != null && sub.isNotEmpty)
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: _muted)),
          ],
        ),
      );

  /// The "add to home-screen widget" slot (shown beside sunrise/sunset).
  static Widget _widgetOption(bool hi, VoidCallback onTap) => Expanded(
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
                      style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: _label)),
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

  static Widget _stat(IconData icon, String label, String value,
          {bool small = false}) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: _accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: _label)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: small ? 12 : 14,
                    color: _ink)),
          ],
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

/// A one-glance daily Rashifal teaser for the reader's selected moon sign —
/// sign glyph, today's star rating and the one-line Chandra-gochar reading.
/// Taps through to the full Rashifal tab. Computed on-device (no birth data).
class _RashifalCard extends ConsumerWidget {
  const _RashifalCard();

  static const _bg = Color(0xFFF3ECFA); // soft violet-cream (astrology accent)
  static const _accent = AppColors.dharmaPurple;
  static const _ink = Color(0xFF3A2A20);
  static const _label = Color(0xFF9C8B79);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
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

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: RashiGlyph(index: rashi, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        (hi ? 'आज का राशिफल' : "Today's Rashifal").toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: _label)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Flexible(
                        child: Text(signNames[rashi].call(hi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: _ink)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: vColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(cVerdictLabels[verdict.index].call(hi),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: vColor)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(line,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: _ink.withValues(alpha: 0.78))),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/cosmos'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hi ? 'और जानें' : 'Know more',
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
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Opens the Explorer rather than a one-off sheet: the same festival
        // leads that list, and from there the whole year is reachable.
        onTap: () => context.push('/festivals'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.secondary.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Text('🪔', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                  const SizedBox(height: 2),
                  Text(next.hit.name(hi),
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(when,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: scheme.primary)),
            ),
          ]),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6E1F10), Color(0xFF3A1608)],
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
              child: const Icon(Icons.temple_hindu_rounded,
                  color: Color(0xFFE6C34A), size: 24),
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
                          ? const Color(0xFF8FD6A8)
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
    );
  }
}
