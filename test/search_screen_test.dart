import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/core/providers/app_providers.dart';
import 'package:divyavaani/core/user/user_prefs.dart';
import 'package:divyavaani/features/search/search_models.dart';
import 'package:divyavaani/features/search/search_providers.dart';
import 'package:divyavaani/features/search/search_screen.dart';

/// SR-01/SR-02/SR-03. What the search screen does with what the index gives it.
///
/// The repository tests already run the real SQL against the real index; these
/// are about the three decisions above it that data alone cannot settle:
///
///   * a result list that is 883 verses and four temples must not read as a
///     list of verses (SR-01),
///   * the "Try" row has to survive the database being absent (SR-02),
///   * and a miss should offer the correction rather than only regret (SR-03).
///
/// Every provider is overridden, so nothing here opens a database — the point
/// is the screen's own arithmetic, not the query's.

SearchHit _hit(int id, String kind, String title, {double score = 10}) =>
    SearchHit(
      docId: id,
      src: 'gyan',
      kind: kind,
      refTable: kind,
      refId: id,
      titleEn: title,
      titleHi: 'हिन्दी $title',
      route: '/gyan/entity/$id',
      score: score,
    );

/// A result set shaped like the real one for "hanuman": a wall of verses with a
/// handful of everything else scattered through it. Scores descend, because the
/// repository returns them that way and the grouping relies on it.
List<SearchHit> _mixed() {
  final hits = <SearchHit>[
    _hit(1, 'temple', 'Hanuman Mandir', score: 100),
    _hit(2, 'aarti', 'Hanuman Aarti', score: 90),
  ];
  for (var i = 0; i < 12; i++) {
    hits.add(_hit(100 + i, 'shloka', 'Verse $i', score: 80.0 - i));
  }
  hits.add(_hit(3, 'mantra', 'Hanuman Mantra', score: 20));
  return hits;
}

Future<ProviderContainer> pumpSearch(
  WidgetTester tester, {
  List<SearchHit> hits = const [],
  Map<String, int> counts = const {},
  List<String> didYouMean = const [],
  List<CuratedTerm>? curated,
  String query = 'hanuman',
  bool hindi = false,
  double width = 400,
  double height = 1400,
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    if (hindi) localeProvider.overrideWith((ref) => const Locale('hi')),
    searchResultsProvider.overrideWith((ref) async => hits),
    searchCountsProvider.overrideWith((ref) async => counts),
    didYouMeanProvider.overrideWith((ref) async => didYouMean),
    searchIndexStaleProvider.overrideWith((ref) async => false),
    if (curated != null)
      curatedTermsProvider.overrideWith((ref) async => curated),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: systemScale,
        maxScaleFactor: systemScale,
        child: child!,
      ),
      home: SearchScreen(initialQuery: query),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('results are grouped by kind (SR-01)', () {
    testWidgets('each kind gets a heading', (tester) async {
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      for (final label in ['Temples', 'Aartis', 'Verses', 'Mantras']) {
        expect(find.text(label), findsOneWidget,
            reason: '$label has matches but no heading');
      }
    });

    testWidgets('the best-scoring kind leads', (tester) async {
      // Groups inherit the order of the hits, which arrive score-ordered — so
      // the kind holding the single best result is the one a reader sees first.
      // A HashMap here would put them in whatever order hashing produced.
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      final temple = tester.getTopLeft(find.text('Temples')).dy;
      final verses = tester.getTopLeft(find.text('Verses')).dy;
      final mantra = tester.getTopLeft(find.text('Mantras')).dy;
      expect(temple, lessThan(verses));
      expect(verses, lessThan(mantra));
    });

    testWidgets('no one kind can bury the others', (tester) async {
      // The whole reason for grouping. Twelve verses were returned; four are
      // shown, so the mantra below them stays reachable without scrolling past
      // a wall. Without the cap the tail of the list is unreachable in practice.
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      expect(find.textContaining('Verse '), findsNWidgets(4));
      expect(find.text('Hanuman Mantra'), findsOneWidget);
    });

    testWidgets('"See all" carries the true count, not the page size',
        (tester) async {
      // 883 is what the index holds; 12 is what this page of results contains.
      // Showing 12 would tell the reader the corpus is far smaller than it is.
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      expect(find.text('See all 883'), findsOneWidget);
    });

    testWidgets('a kind that fits entirely offers no "See all"',
        (tester) async {
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      // One temple, one shown — there is nothing further to see.
      expect(find.text('See all 1'), findsNothing);
    });

    testWidgets('"See all" selects that kind', (tester) async {
      final container = await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      await tester.tap(find.text('See all 883'));
      await tester.pumpAndSettle();
      expect(container.read(searchKindProvider), 'shloka',
          reason: 'it must land on the same view the chip opens');
    });

    testWidgets('choosing a kind returns a flat list, not one group',
        (tester) async {
      // Narrowing is already done, so grouping a single kind would add a
      // heading and a cap for no gain — and the cap would hide results the
      // reader explicitly asked to see.
      final container = await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1});
      container.read(searchKindProvider.notifier).state = 'shloka';
      await tester.pumpAndSettle();
      expect(find.textContaining('See all'), findsNothing);
      expect(find.textContaining('Verse '), findsNWidgets(12),
          reason: 'all twelve returned verses, uncapped');
    });

    testWidgets('headings are Hindi in Hindi', (tester) async {
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1},
          hindi: true);
      expect(find.text('श्लोक'), findsOneWidget);
      expect(find.text('मंदिर'), findsOneWidget);
      expect(find.text('सभी 883 देखें'), findsOneWidget);
    });

    testWidgets('a group whose count is missing still renders', (tester) async {
      // countsByKind is a second, separately-debounced query, so it can be
      // absent for a frame. Falling back to the page length keeps the heading
      // honest about what is on screen rather than showing a bare label or 0.
      await pumpSearch(tester, hits: _mixed(), counts: const {});
      expect(find.text('Verses'), findsOneWidget);
      expect(find.text('See all 12'), findsOneWidget);
    });

    testWidgets('grouping holds at 2x on a narrow phone', (tester) async {
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'temple': 1, 'aarti': 1, 'shloka': 883, 'mantra': 1},
          width: 320,
          height: 3000,
          systemScale: 2.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('the "Try" row (SR-02)', () {
    testWidgets('terms come from the database', (tester) async {
      await pumpSearch(tester,
          query: '',
          curated: const [(en: 'Krishna', hi: 'कृष्ण'), (en: 'Sita', hi: 'सीता')]);
      expect(find.text('TRY'), findsOneWidget);
      expect(find.text('Krishna'), findsOneWidget);
      expect(find.text('Sita'), findsOneWidget);
    });

    testWidgets('a Hindi reader gets Devanagari chips', (tester) async {
      // The chip submits what it displays, and both spellings fold to the same
      // documents — so showing Latin to a Hindi reader is needless, not broken.
      await pumpSearch(tester,
          query: '',
          hindi: true,
          curated: const [(en: 'Krishna', hi: 'कृष्ण')]);
      expect(find.text('कृष्ण'), findsOneWidget);
      expect(find.text('Krishna'), findsNothing);
    });

    testWidgets('tapping a term searches it', (tester) async {
      final container = await pumpSearch(tester,
          query: '', curated: const [(en: 'Krishna', hi: 'कृष्ण')]);
      await tester.tap(find.text('Krishna'));
      await tester.pumpAndSettle();
      expect(container.read(searchQueryProvider), 'Krishna');
    });

    testWidgets('the row is never empty, even with no database',
        (tester) async {
      // curatedTermsProvider is left un-overridden, so it tries to open the
      // real DB and fails in a widget test — exactly the shape of a first
      // launch before the asset is unpacked. The hardcoded list must show.
      await pumpSearch(tester, query: '');
      expect(find.text('TRY'), findsOneWidget);
      expect(find.text('Hanuman'), findsOneWidget);
    });
  });

  group('did you mean (SR-03)', () {
    testWidgets('a miss offers the correction', (tester) async {
      await pumpSearch(tester,
          query: 'hanumn', hits: const [], didYouMean: const ['hanuman']);
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('Did you mean'), findsOneWidget);
      expect(find.text('hanuman'), findsOneWidget);
    });

    testWidgets('tapping the correction runs it', (tester) async {
      final container = await pumpSearch(tester,
          query: 'hanumn', hits: const [], didYouMean: const ['hanuman']);
      await tester.tap(find.text('hanuman'));
      await tester.pumpAndSettle();
      expect(container.read(searchQueryProvider), 'hanuman');
      expect(container.read(recentSearchesProvider), contains('hanuman'),
          reason: 'a correction the reader accepted is a search they made');
    });

    testWidgets('a miss with no correction still explains itself',
        (tester) async {
      // Most misses have no near neighbour. The advice that was always here
      // must not disappear when the suggestion does.
      await pumpSearch(tester, query: 'zzzzqqq', hits: const []);
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('Did you mean'), findsNothing);
      expect(find.textContaining('Check the spelling'), findsOneWidget);
    });

    testWidgets('nothing is suggested when results were found', (tester) async {
      await pumpSearch(tester,
          hits: _mixed(),
          counts: {'shloka': 883},
          didYouMean: const ['hanuman']);
      expect(find.text('Did you mean'), findsNothing);
    });

    testWidgets('Hindi', (tester) async {
      await pumpSearch(tester,
          query: 'हनुमन',
          hindi: true,
          hits: const [],
          didYouMean: const ['हनुमान']);
      expect(find.text('कुछ नहीं मिला'), findsOneWidget);
      expect(find.text('क्या आपका मतलब था'), findsOneWidget);
    });
  });
}
