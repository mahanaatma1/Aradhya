import 'package:go_router/go_router.dart';

import '../../features/devotional/devotional_models.dart';
import '../../features/devotional/devotional_providers.dart';
import '../../features/devotional/lyrics_list_screen.dart';
import '../../features/devotional/lyrics_reader_screen.dart';
import '../../features/devotional/mantra_reader_screen.dart';
import '../../features/devotional/mantras_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/gyan/entity_detail_screen.dart';
import '../../features/gyan/family_tree_screen.dart';
import '../../features/gyan/knowledge_graph_screen.dart';
import '../../features/gyan/entity_list_screen.dart';
import '../../features/ask/ask_screen.dart';
import '../../features/dharma/dharma_hub_screen.dart';
import '../../features/dharma/dharma_scenario_screen.dart';
import '../../features/festivals/festival_detail_screen.dart';
import '../../features/festivals/festivals_screen.dart';
import '../../features/gyan/gyan_hub_screen.dart';
import '../../features/vidya/vidya_screen.dart';
import '../../features/vidya/vidya_topic_screen.dart';
import '../../features/cosmology/srishty_screen.dart';
import '../../features/cosmology/yuga_screen.dart';
import '../../features/mandir/mandir_screen.dart';
import '../../features/narrative/kurukshetra_screen.dart';
import '../../features/narrative/mahabharata_timeline_screen.dart';
import '../../features/narrative/ramayana_journey_screen.dart';
import '../../features/narrative/scene_screen.dart';
import '../../features/journal/journal_editor_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/journey/journey_detail_screen.dart';
import '../../features/journey/journey_list_screen.dart';
import '../../features/hubs/jyotish_hub_screen.dart';
import '../../features/hubs/profile_screen.dart';
import '../../features/hubs/sources_screen.dart';
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
import '../../features/sadhana/sadhana_hub_screen.dart';
import '../../features/quiz/quiz_play_screen.dart';
import '../../features/quiz/riddles_screen.dart';
import '../../features/quiz/trivia_screen.dart';
import '../../features/scriptures/scripture_books_screen.dart';
import '../../features/scriptures/scriptures_list_screen.dart';
import '../../features/search/result_loader.dart';
import '../../features/search/search_screen.dart';
import '../../features/scriptures/section_reader_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stories/stories_screen.dart';
import '../../features/stories/story_models.dart';
import '../../features/stories/story_reader_screen.dart';
import '../../features/temples/temple_detail_screen.dart';
import '../../features/temples/temple_models.dart';
import '../../features/temples/collection_screen.dart';
import '../../features/temples/passport_pages.dart';
import '../../features/temples/passport_screen.dart';
import '../../features/temples/temples_screen.dart';
import '../shell/nav_scaffold.dart';

/// Whether the user has completed onboarding. Set from prefs in `main()` before
/// the app builds, and again when onboarding finishes.
bool gOnboarded = false;

/// Which verse of the book to open at.
///
/// `extra` carries it for in-app pushes, but `extra` does not survive a deep
/// link, so the search index emits `?v=<index>` instead. The router read only
/// `extra`, which meant every one of the 27,890 indexed verses opened its
/// chapter at verse one — the result was always the right book and the wrong
/// line. Both forms are accepted now, with `extra` winning when both are set.
int _verseIndex(GoRouterState state) {
  if (state.extra is int) return state.extra as int;
  return int.tryParse(state.uri.queryParameters['v'] ?? '') ?? 0;
}

int _intParam(GoRouterState state, String key) =>
    int.tryParse(state.pathParameters[key] ?? '') ?? 0;

/// `?id=` for routes reachable both in-app (with `extra`) and from a search
/// result or deep link (id only). Returns null when absent.
int? _idQuery(GoRouterState state) =>
    int.tryParse(state.uri.queryParameters['id'] ?? '');

/// Gyan's module routes.
///
/// Hoisted out of the router literal so the Gyan branch of the shell stays
/// readable. Paths are relative to `/gyan`, exactly as before the promotion —
/// no deep link changes.
final List<RouteBase> _gyanRoutes = <RouteBase>[
      // One detail screen for every entity kind — deity, rishi, astra,
      // symbol, place. Search results and related-rail cards land here.
      GoRoute(
        path: 'graph',
        builder: (c, s) => KnowledgeGraphScreen(
            focusId: int.tryParse(s.uri.queryParameters['id'] ?? '')),
      ),
      // Lineage is a PROJECTION of relations, not its own dataset — the
      // route takes an optional root and offers a picker without one.
      GoRoute(
        path: 'lineage',
        builder: (c, s) => FamilyTreeScreen(
            rootId: int.tryParse(s.uri.queryParameters['id'] ?? '')),
      ),
      GoRoute(
        path: 'vidya',
        builder: (c, s) => const VidyaScreen(),
        routes: [
          GoRoute(
            path: ':topicId',
            builder: (c, s) =>
                VidyaTopicScreen(topicId: _intParam(s, 'topicId')),
          ),
        ],
      ),
      GoRoute(path: 'srishty', builder: (c, s) => const SrishtyScreen()),
      GoRoute(path: 'yuga', builder: (c, s) => const YugaScreen()),

      // Two presentations of one table; both open the same scene screen.
      GoRoute(
        path: 'ramayana',
        builder: (c, s) => const RamayanaJourneyScreen(),
      ),
      GoRoute(
        path: 'mahabharata',
        builder: (c, s) => const MahabharataTimelineScreen(),
        routes: [
          GoRoute(
            path: 'kurukshetra',
            builder: (c, s) => const KurukshetraScreen(),
          ),
        ],
      ),
      GoRoute(
        path: 'scene/:sceneId',
        builder: (c, s) => SceneScreen(sceneId: _intParam(s, 'sceneId')),
      ),
      GoRoute(
        path: 'entity/:entityId',
        builder: (c, s) =>
            EntityDetailScreen(entityId: _intParam(s, 'entityId')),
      ),
      // The encyclopedias: same data, same navigation, kind-specific layout.
      GoRoute(
        path: 'rishis',
        builder: (c, s) => const EntityListScreen(
            kind: 'rishi', titleEn: 'Rishis', titleHi: 'ऋषि'),
      ),
      GoRoute(
        path: 'astras',
        builder: (c, s) => const EntityListScreen(
            kind: 'weapon', titleEn: 'Ancient Astras', titleHi: 'प्राचीन अस्त्र'),
      ),
      GoRoute(
        path: 'symbols',
        builder: (c, s) => const EntityListScreen(
            kind: 'symbol', titleEn: 'Symbols', titleHi: 'प्रतीक'),
      ),
      GoRoute(
        path: 'deities',
        builder: (c, s) => const EntityListScreen(
            kind: 'deity', titleEn: 'Deities', titleHi: 'देवता'),
      ),
];

/// App router: a persistent 5-tab shell (Home · Gyan · Astrology · Yatra · You)
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
        // Gyan is a shell branch; its module screens stay nested below.
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/gyan',
            builder: (c, s) => const GyanHubScreen(),
            routes: _gyanRoutes,
          ),
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

    // ---- Universal search ----
    // Pushed over the shell, not a tab: five tabs already crowd the Hindi
    // labels, and search is a verb rather than a destination. `?q=` lets home
    // widgets and future deep links open it pre-filled.
    GoRoute(
      path: '/search',
      builder: (context, state) =>
          SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
    ),

    // ---- Ask the Scriptures ----
    GoRoute(path: '/ask', builder: (c, s) => const AskScreen()),

    // ---- Dharma Decision Game ----
    // Sits beside /quiz but is not one: nothing here is scored, and no choice
    // is marked right or wrong.
    GoRoute(
      path: '/dharma',
      builder: (c, s) => const DharmaHubScreen(),
      routes: [
        GoRoute(
          path: 'play/:scenarioId',
          builder: (c, s) =>
              DharmaScenarioScreen(scenarioId: _intParam(s, 'scenarioId')),
        ),
      ],
    ),

    // ---- Pilgrimage Passport ----
    // Reads temple_visits, which the app has been writing since Phase 0 with
    // nowhere to show it.
    GoRoute(
      path: '/passport',
      builder: (c, s) => const PassportScreen(),
      routes: [
        // These must come before ':tag', which would otherwise swallow them.
        GoRoute(path: 'journey', builder: (c, s) => const JourneyScreen()),
        GoRoute(
            path: 'collections', builder: (c, s) => const CollectionsScreen()),
        GoRoute(
            path: 'milestones', builder: (c, s) => const MilestonesScreen()),
        GoRoute(
          path: ':tag',
          builder: (c, s) =>
              CollectionScreen(tag: s.pathParameters['tag'] ?? ''),
        ),
      ],
    ),

    // ---- Festival Explorer ----
    // Dates are computed from the stored rule by panchang_engine, never
    // fetched, so the list is correct for any year and any location.
    GoRoute(
      path: '/festivals',
      builder: (c, s) => const FestivalsScreen(),
      routes: [
        GoRoute(
          path: ':festivalId',
          builder: (c, s) =>
              FestivalDetailScreen(festivalId: _intParam(s, 'festivalId')),
        ),
      ],
    ),

    // Rashifal keeps its route for deep links and the Android home widget,
    // even though it no longer has a tab of its own.
    GoRoute(path: '/cosmos', builder: (c, s) => const CosmosScreen()),


    // ---- Karma Journal (personal — surfaced from You) ----
    GoRoute(
      path: '/journal',
      builder: (c, s) => const JournalScreen(),
      routes: [
        // `?prompt=` carries a question in from elsewhere — a scene's
        // reflection, via "Think about it".
        GoRoute(
          path: 'new',
          builder: (c, s) => JournalEditorScreen(
              seedPrompt: s.uri.queryParameters['prompt']),
        ),
        GoRoute(
          path: 'entry/:entryId',
          builder: (c, s) =>
              JournalEditorScreen(entryId: _intParam(s, 'entryId')),
        ),
      ],
    ),

    // ---- Knowledge Journeys ----
    // Curated paths over content that already exists, so this ships before any
    // new module does.
    GoRoute(
      path: '/journey',
      builder: (c, s) => const JourneyListScreen(),
      routes: [
        GoRoute(
          path: ':pathId',
          builder: (c, s) =>
              JourneyDetailScreen(pathId: _intParam(s, 'pathId')),
        ),
      ],
    ),

    // ---- Content routes (pushed over the shell) ----

    // Scriptures
    GoRoute(
      path: '/scriptures',
      builder: (context, state) => const ScripturesListScreen(),
      routes: [
        // Book-only deep link: `/scriptures/book/<bookId>`.
        //
        // Declared BEFORE ':scriptureId' so the literal segment wins the match.
        // Bookmarked shlokas store only a bookId — they were pushing this exact
        // path while the router knew nothing about it, which landed the user on
        // GoRouter's "no routes for location" error page. The reader only ever
        // needed bookId, so this is a real route rather than a redirect.
        GoRoute(
          path: 'book/:bookId',
          builder: (context, state) => SectionReaderScreen(
            bookId: _intParam(state, 'bookId'),
            initialIndex: _verseIndex(state),
          ),
        ),
        GoRoute(
          path: ':scriptureId',
          builder: (context, state) =>
              ScriptureBooksScreen(scriptureId: _intParam(state, 'scriptureId')),
          routes: [
            GoRoute(
              path: 'book/:bookId',
              builder: (context, state) => SectionReaderScreen(
                bookId: _intParam(state, 'bookId'),
                initialIndex: _verseIndex(state),
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
        final extra = s.extra;
        if (extra is (DevotionalItem, LyricsKind)) {
          return LyricsReaderScreen(item: extra.$1, kind: extra.$2);
        }
        final id = _idQuery(s);
        if (id == null) return const MissingItemScreen();
        final kind = s.uri.queryParameters['kind'] == 'chalisas'
            ? LyricsKind.chalisas
            : LyricsKind.aartis;
        return ResultLoader<DevotionalItem>(
          table: kind == LyricsKind.chalisas ? 'chalisas' : 'aartis',
          id: id,
          fromRow: DevotionalItem.fromRow,
          builder: (item) => LyricsReaderScreen(item: item, kind: kind),
        );
      },
    ),
    GoRoute(
      path: '/read-mantra',
      builder: (c, s) {
        final extra = s.extra;
        if (extra is Mantra) return MantraReaderScreen(mantra: extra);
        final id = _idQuery(s);
        if (id == null) return const MissingItemScreen();
        return ResultLoader<Mantra>(
          table: 'mantras',
          id: id,
          fromRow: Mantra.fromRow,
          builder: (m) => MantraReaderScreen(mantra: m),
        );
      },
    ),

    // Stories — optional initial emotion filter passed via `extra`.
    GoRoute(
        path: '/katha',
        builder: (c, s) =>
            StoriesScreen(initialEmotion: s.extra as String?)),
    GoRoute(
      path: '/read-story',
      builder: (c, s) {
        final extra = s.extra;
        if (extra is Story) return StoryReaderScreen(story: extra);
        final id = _idQuery(s);
        if (id == null) return const MissingItemScreen();
        final isKatha = s.uri.queryParameters['kind'] == 'katha';
        return ResultLoader<Story>(
          table: isKatha ? 'kathas' : 'stories',
          // Katha ids are offset in the index so they cannot collide with
          // story ids; undo that to reach the real row.
          id: isKatha ? id - Story.kathaIdOffset : id,
          fromRow: isKatha ? Story.fromKathaRow : Story.fromRow,
          builder: (st) => StoryReaderScreen(story: st),
        );
      },
    ),

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

    // Daily practice — the hub summarises these; each keeps its own route so
    // deep links and the Android home widgets continue to work.
    GoRoute(path: '/sadhana', builder: (c, s) => const SadhanaHubScreen()),
    // The home shrine — where Kamal finally has a sink beyond Rashifal.
    GoRoute(path: '/mandir', builder: (c, s) => const MandirScreen()),
    GoRoute(path: '/japa', builder: (c, s) => const JapaScreen()),
    GoRoute(path: '/breathing', builder: (c, s) => const BreathingScreen()),
    GoRoute(path: '/habits', builder: (c, s) => const HabitsScreen()),

    // Bookmarks
    GoRoute(path: '/bookmarks', builder: (c, s) => const BookmarksScreen()),

    // Sources — the OSM/ODbL and other licence attributions (TM-04).
    GoRoute(path: '/sources', builder: (c, s) => const SourcesScreen()),

    // Yatra — temple detail (the directory lives in the Yatra tab)
    GoRoute(
      path: '/temple',
      builder: (c, s) {
        final extra = s.extra;
        if (extra is Temple) return TempleDetailScreen(temple: extra);
        final id = _idQuery(s);
        if (id == null) return const MissingItemScreen();
        return ResultLoader<Temple>(
          table: 'temples',
          id: id,
          fromRow: Temple.fromRow,
          builder: (t) => TempleDetailScreen(temple: t),
        );
      },
    ),

    // Puja Vidhi
    GoRoute(path: '/puja', builder: (c, s) => const PujaListScreen()),
    GoRoute(
      path: '/puja-detail',
      builder: (c, s) {
        final extra = s.extra;
        if (extra is PujaVidhi) return PujaDetailScreen(puja: extra);
        final id = _idQuery(s);
        if (id == null) return const MissingItemScreen();
        return ResultLoader<PujaVidhi>(
          table: 'puja_vidhi',
          id: id,
          fromRow: PujaVidhi.fromRow,
          builder: (p) => PujaDetailScreen(puja: p),
        );
      },
    ),
  ],
);
