import 'package:go_router/go_router.dart';

import '../../features/devotional/devotional_models.dart';
import '../../features/devotional/devotional_providers.dart';
import '../../features/devotional/lyrics_list_screen.dart';
import '../../features/devotional/lyrics_reader_screen.dart';
import '../../features/devotional/mantra_reader_screen.dart';
import '../../features/devotional/mantras_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/hubs/jyotish_hub_screen.dart';
import '../../features/hubs/profile_screen.dart';
import '../../features/astrology/ashtakoot.dart';
import '../../features/astrology/birth_form_screen.dart';
import '../../features/astrology/kundli_screen.dart';
import '../../features/astrology/milan_result_screen.dart';
import '../../features/astrology/milan_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/breathing/breathing_screen.dart';
import '../../features/cosmos/cosmos_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/japa/japa_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/personality/personality_screen.dart';
import '../../features/panchang/calendar_screen.dart';
import '../../features/panchang/panchang_screen.dart';
import '../../features/puja/puja_detail_screen.dart';
import '../../features/puja/puja_list_screen.dart';
import '../../features/puja/puja_models.dart';
import '../../features/quiz/quiz_hub_screen.dart';
import '../../features/quiz/quiz_play_screen.dart';
import '../../features/quiz/riddles_screen.dart';
import '../../features/quiz/trivia_screen.dart';
import '../../features/scriptures/scripture_books_screen.dart';
import '../../features/scriptures/scriptures_list_screen.dart';
import '../../features/scriptures/section_reader_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stories/stories_screen.dart';
import '../../features/stories/story_models.dart';
import '../../features/stories/story_reader_screen.dart';
import '../../features/temples/temple_detail_screen.dart';
import '../../features/temples/temple_models.dart';
import '../../features/temples/temples_screen.dart';
import '../shell/nav_scaffold.dart';

/// Whether the user has completed onboarding. Set from prefs in `main()` before
/// the app builds, and again when onboarding finishes.
bool gOnboarded = false;

int _intParam(GoRouterState state, String key) =>
    int.tryParse(state.pathParameters[key] ?? '') ?? 0;

/// App router: a persistent 5-tab shell (Home · Rashifal · Astrology · Yatra · You)
/// with all content opening as full-screen routes over the nav bar.
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final loc = state.uri.path;
    if (loc == '/splash') return null; // splash decides where to go next
    final atOnboarding = loc == '/onboarding';
    if (!gOnboarded && !atOnboarding) return '/onboarding';
    if (gOnboarded && atOnboarding) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => NavScaffold(navShell: navShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/cosmos', builder: (c, s) => const CosmosScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/jyotish', builder: (c, s) => const JyotishHubScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/temples', builder: (c, s) => const TemplesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/you', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),

    // ---- Content routes (pushed over the shell) ----

    // Scriptures
    GoRoute(
      path: '/scriptures',
      builder: (context, state) => const ScripturesListScreen(),
      routes: [
        GoRoute(
          path: ':scriptureId',
          builder: (context, state) =>
              ScriptureBooksScreen(scriptureId: _intParam(state, 'scriptureId')),
          routes: [
            GoRoute(
              path: 'book/:bookId',
              builder: (context, state) => SectionReaderScreen(
                bookId: _intParam(state, 'bookId'),
                initialIndex: state.extra is int ? state.extra as int : 0,
              ),
            ),
          ],
        ),
      ],
    ),

    // Devotional
    GoRoute(
        path: '/aartis',
        builder: (c, s) => const LyricsListScreen(kind: LyricsKind.aartis)),
    GoRoute(
        path: '/chalisa',
        builder: (c, s) => const LyricsListScreen(kind: LyricsKind.chalisas)),
    GoRoute(path: '/mantras', builder: (c, s) => const MantrasListScreen()),
    GoRoute(
        path: '/read-lyrics',
        builder: (c, s) {
          final (item, kind) = s.extra as (DevotionalItem, LyricsKind);
          return LyricsReaderScreen(item: item, kind: kind);
        }),
    GoRoute(
        path: '/read-mantra',
        builder: (c, s) => MantraReaderScreen(mantra: s.extra as Mantra)),

    // Stories — optional initial emotion filter passed via `extra`.
    GoRoute(
        path: '/katha',
        builder: (c, s) =>
            StoriesScreen(initialEmotion: s.extra as String?)),
    GoRoute(
        path: '/read-story',
        builder: (c, s) => StoryReaderScreen(story: s.extra as Story)),

    // Panchang
    GoRoute(path: '/panchang', builder: (c, s) => const PanchangScreen()),
    GoRoute(path: '/calendar', builder: (c, s) => const CalendarScreen()),

    // Astrology — birth form first, then the kundli
    GoRoute(path: '/astrology', builder: (c, s) => const BirthFormScreen()),
    GoRoute(path: '/astrology/kundli', builder: (c, s) => const KundliScreen()),
    GoRoute(
      path: '/astrology/milan',
      builder: (c, s) => const MilanScreen(),
      routes: [
        GoRoute(
          path: 'result',
          builder: (c, s) =>
              MilanResultScreen(result: s.extra as MilanResult),
        ),
      ],
    ),

    // Quiz (also reachable from the Play tab)
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizHubScreen(),
      routes: [
        GoRoute(path: 'play', builder: (c, s) => const QuizPlayScreen()),
        GoRoute(path: 'trivia', builder: (c, s) => const TriviaScreen()),
      ],
    ),
    GoRoute(path: '/riddles', builder: (c, s) => const RiddlesScreen()),

    // Personality — spiritual archetype test
    GoRoute(path: '/personality', builder: (c, s) => const PersonalityScreen()),

    // Daily practice
    GoRoute(path: '/japa', builder: (c, s) => const JapaScreen()),
    GoRoute(path: '/breathing', builder: (c, s) => const BreathingScreen()),
    GoRoute(path: '/habits', builder: (c, s) => const HabitsScreen()),

    // Bookmarks
    GoRoute(path: '/bookmarks', builder: (c, s) => const BookmarksScreen()),

    // Yatra — temple detail (the directory lives in the Yatra tab)
    GoRoute(
        path: '/temple',
        builder: (c, s) => TempleDetailScreen(temple: s.extra as Temple)),

    // Puja Vidhi
    GoRoute(path: '/puja', builder: (c, s) => const PujaListScreen()),
    GoRoute(
        path: '/puja-detail',
        builder: (c, s) => PujaDetailScreen(puja: s.extra as PujaVidhi)),
  ],
);
