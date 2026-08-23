import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/features/narrative/narrative_models.dart';
import 'package:divyavaani/features/narrative/narrative_providers.dart';
import 'package:divyavaani/features/narrative/story_mode_view.dart';
import 'package:divyavaani/features/narrative/story_structure.dart';

/// SC-12/14/15. What a reader is told by the shelf of books, and whether the
/// telling survives Hindi.
///
/// `story_structure_test.dart` proves the grouping is right. This proves the
/// screen says what the grouping found: an empty kanda admits it and does not
/// pretend to open, a teaching parva is badged, a section with only a sub-view
/// is not called empty, and none of it overflows on a narrow phone in the
/// longer, taller script.

/// A row as sqflite hands it over.
///
/// Titles are deliberately long in both scripts: a two-word title never
/// overflows anything, and these cards are a spine, a column and a chevron in
/// one Row.
Map<String, Object?> _row(int id, int book, Map<String, Object?> over) => {
      'id': id,
      'slug': 'scene-$id',
      'epic': 'ramayana',
      'recension': 'valmiki',
      'sequence_no': id,
      'book_no': book,
      'title_en': 'Scene $id, and the long name it was given',
      'title_hi': 'प्रसंग $id, और उसे दिया गया लंबा नाम',
      'short_description_en':
          'A blurb of the length these actually run to, which is two lines.',
      'short_description_hi':
          'इतनी लंबाई का एक परिचय, जितना ये वास्तव में होते हैं, दो पंक्तियों का।',
      ...over,
    };

NarrativeNode _node(int id, int book, [Map<String, Object?> over = const {}]) =>
    NarrativeNode.fromRow(_row(id, book, over));

/// One event in every section of an epic, each in a titled arc.
List<NarrativeNode> _oneEach(String epic, int sections) => [
      for (var i = 1; i <= sections; i++)
        _node(i, i, {
          'epic': epic,
          'arc_slug': 'arc-$i',
          'arc_no': i,
          'arc_title_en': 'The arc that runs through section $i',
          'arc_title_hi': 'खंड $i से होकर जाने वाला प्रसंग-समूह',
        }),
    ];

/// The eighteen parvas do not fit the default 800×600 surface, and a lazy list
/// only builds what fits — so the surface is made tall. The *width* stays a real
/// phone's, because that is the axis overflow happens on.
Future<ProviderContainer> pumpStory(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  double height = 4200,
  bool dark = false,
  ProviderContainer? container,
}) async {
  final c = container ?? ProviderContainer();
  if (container == null) addTearDown(c.dispose);
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: child),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

StoryModeView _view(
  String epic,
  List<NarrativeNode> scenes, {
  bool hindi = false,
  Widget? Function(EpicSection)? sectionExtra,
  Widget header = const SizedBox.shrink(),
  bool hideEmpty = false,
}) =>
    StoryModeView(
      epic: epic,
      scenes: scenes,
      hindi: hindi,
      header: header,
      sectionExtra: sectionExtra,
      hideEmpty: hideEmpty,
    );

void main() {
  group('the shelf builds, in both scripts', () {
    for (final (epic, count) in [('ramayana', 7), ('mahabharata', 18)]) {
      for (final hi in [false, true]) {
        testWidgets('$epic renders every section, hindi=$hi', (tester) async {
          await pumpStory(
            tester,
            _view(epic, _oneEach(epic, count), hindi: hi),
            height: 6400,
          );
          expect(tester.takeException(), isNull);
          final last = sectionsFor(epic).last;
          expect(find.text(last.title(hi)), findsOneWidget,
              reason: 'the last section must be laid out, not just counted');
        });
      }
    }

    testWidgets('Hindi survives the narrowest phone', (tester) async {
      // 320 dp is the floor this app targets, and Devanagari is the taller,
      // longer script — if a card is going to overflow, it does so here.
      await pumpStory(
        tester,
        _view('mahabharata', _oneEach('mahabharata', 18), hindi: true),
        width: 320,
        height: 7200,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dark theme keeps its warm panels', (tester) async {
      // The spine, the badge and the tradition note all pick a colour off
      // brightness. This walks that branch.
      await pumpStory(
        tester,
        _view('mahabharata', _oneEach('mahabharata', 18), hindi: true),
        dark: true,
        height: 7200,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the parent keeps its header, as the first item',
        (tester) async {
      await pumpStory(
        tester,
        _view('ramayana', _oneEach('ramayana', 7),
            header: const Text('PROGRESS HEADER')),
      );
      expect(find.text('PROGRESS HEADER'), findsOneWidget);
    });
  });

  group('what a section admits to', () {
    testWidgets('a section with nothing written says so, and will not open',
        (tester) async {
      await pumpStory(tester, _view('ramayana', [_node(1, 1)]));

      // Six of the seven kandas hold nothing.
      expect(find.text('No events yet'), findsNWidgets(6));
      // And only the one that holds something offers a chevron.
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      await tester.tap(find.text('Uttara Kanda'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget,
          reason: 'tapping an empty section must not open anything');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Uttara Kanda carries its note even while empty (SC-15)',
        (tester) async {
      await pumpStory(tester, _view('ramayana', [_node(1, 1)]));
      expect(find.text('IN THE TRADITION'), findsOneWidget);
      expect(
        find.textContaining('differ', findRichText: true),
        findsOneWidget,
        reason: 'the note states what traditions hold, not a verdict of ours',
      );
    });

    testWidgets('a teaching parva is badged and explained (SC-14)',
        (tester) async {
      await pumpStory(
        tester,
        _view('mahabharata', _oneEach('mahabharata', 18)),
        height: 6400,
      );
      // Shanti and Anushasana, and nothing else.
      expect(find.text('Teachings, not events'), findsNWidgets(2));
      expect(find.text('IN THE TRADITION'), findsNWidgets(2));
      expect(find.textContaining('1 teaching'), findsNWidgets(2),
          reason: 'a discourse is counted as a teaching, not an event');
    });

    testWidgets('a subtitle counts events, arcs, and what has been read',
        (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(epicProgressProvider.notifier).markRead(2);

      await pumpStory(
        tester,
        _view('ramayana', [_node(1, 1), _node(2, 1), _node(3, 1)]),
        container: c,
      );
      expect(find.textContaining('3 events'), findsOneWidget);
      expect(find.textContaining('1 read'), findsOneWidget);
    });
  });

  group('opening and closing', () {
    testWidgets('the section holding the next unread event starts open',
        (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      // The whole Bala Kanda is read; the next unread event is in Ayodhya.
      await c.read(epicProgressProvider.notifier).markRead(1);

      await pumpStory(
        tester,
        _view('ramayana', [_node(1, 1), _node(2, 2)]),
        container: c,
      );
      expect(find.textContaining('Scene 2'), findsOneWidget,
          reason: 'you land on what you came back for');
      expect(find.textContaining('Scene 1'), findsNothing,
          reason: 'the finished kanda stays collapsed');
    });

    testWidgets('with nothing read, the first section that has content opens',
        (tester) async {
      await pumpStory(tester, _view('ramayana', [_node(9, 3)]));
      expect(find.textContaining('Scene 9'), findsOneWidget);
    });

    testWidgets('a section opens and closes on tap', (tester) async {
      await pumpStory(tester, _view('ramayana', [_node(1, 1), _node(2, 2)]));
      // Bala Kanda is seeded open; Ayodhya is not.
      expect(find.textContaining('Scene 2'), findsNothing);

      await tester.tap(find.text('Ayodhya Kanda'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Scene 2'), findsOneWidget);

      await tester.tap(find.text('Ayodhya Kanda'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Scene 2'), findsNothing);
    });
  });

  group('the shelf under a filter (SC-13)', () {
    // Two different reasons a section can hold nothing, and they must not be
    // reported the same way. Unfiltered, an empty kanda is content we have not
    // written and saying so is the point (SC-15). Filtered, it is empty because
    // the reader narrowed the list — calling that unwritten would be a lie about
    // the data.
    testWidgets('an excluded section is left out, not called empty',
        (tester) async {
      await pumpStory(
        tester,
        _view('ramayana', [_node(1, 3)], hideEmpty: true),
      );
      expect(find.text('No events yet'), findsNothing);
      expect(find.text('Aranya Kanda'), findsOneWidget);
      expect(find.text('Bala Kanda'), findsNothing);
      // And its own note goes with it: a tradition note about a section the
      // reader has filtered away has nothing to annotate.
      expect(find.text('IN THE TRADITION'), findsNothing);
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('unfiltered, the same shelf still admits what it lacks',
        (tester) async {
      await pumpStory(tester, _view('ramayana', [_node(1, 3)]));
      expect(find.text('No events yet'), findsNWidgets(6));
      expect(find.text('IN THE TRADITION'), findsOneWidget);
    });

    testWidgets('a filter that matches nothing says so, and how to undo it',
        (tester) async {
      // Reachable when the data moves under a held filter. The header alone,
      // with no word about why, reads as a broken screen.
      await pumpStory(
        tester,
        _view('ramayana', const [], hideEmpty: true,
            header: const Text('PROGRESS HEADER')),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('PROGRESS HEADER'), findsOneWidget);
      expect(find.textContaining('No events under this choice'), findsOneWidget);
      expect(find.text('No events yet'), findsNothing);
    });

    testWidgets('the nothing-matched note survives Hindi at 320 dp',
        (tester) async {
      await pumpStory(
        tester,
        _view('mahabharata', const [], hindi: true, hideEmpty: true),
        width: 320,
        height: 800,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('कोई प्रसंग नहीं'), findsOneWidget);
    });

    testWidgets('surviving sections keep their real counts', (tester) async {
      // The subtitle counts what is in front of the reader. Under a filter that
      // is the filtered number, which is the only number that matches the rows
      // below it.
      await pumpStory(
        tester,
        _view('ramayana', [_node(1, 5), _node(2, 5)], hideEmpty: true),
      );
      expect(find.textContaining('2 events'), findsOneWidget);
      expect(find.text('Sundara Kanda'), findsOneWidget);
    });
  });

  group('a section whose content is a sub-view', () {
    // The live case is the eighteen days of Kurukshetra, which sit in a parva
    // the epic list deliberately leaves out. Ramayana kanda 7 stands in for it
    // here because the shape is what matters: no events of its own, one link.
    Widget? extraOn7(EpicSection s) =>
        s.no == 7 ? const Text('THE DAYS, BY COMMANDER') : null;

    testWidgets('does not call itself empty, and does open', (tester) async {
      await pumpStory(
        tester,
        _view('ramayana', _oneEach('ramayana', 6), sectionExtra: extraOn7),
      );
      expect(find.text('No events yet'), findsNothing,
          reason: 'a section with a sub-view to offer is not an empty section');
      // Six sections with events, plus the seventh with only the sub-view.
      expect(find.byIcon(Icons.expand_more_rounded), findsNWidgets(7));

      expect(find.text('THE DAYS, BY COMMANDER'), findsNothing);
      await tester.tap(find.text('Uttara Kanda'));
      await tester.pumpAndSettle();
      expect(find.text('THE DAYS, BY COMMANDER'), findsOneWidget);
    });

    testWidgets('sits below the arcs of a section that also has events',
        (tester) async {
      await pumpStory(
        tester,
        _view('ramayana', [_node(1, 7)], sectionExtra: extraOn7),
      );
      // Section 7 is seeded open because it holds the only unread event.
      expect(find.text('THE DAYS, BY COMMANDER'), findsOneWidget);
      expect(find.textContaining('Scene 1'), findsOneWidget);
      expect(find.textContaining('1 event'), findsOneWidget,
          reason: 'the events it does have are still counted honestly');
    });
  });
}
