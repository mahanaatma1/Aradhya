import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/features/narrative/epic_explore.dart';
import 'package:divyavaani/features/narrative/narrative_models.dart';
import 'package:divyavaani/features/narrative/narrative_providers.dart';
import 'package:divyavaani/features/narrative/story_structure.dart';

/// SC-13. The Explore row: four ways into an epic, and the arithmetic behind the
/// numbers on the chips.
///
/// The counts are the thing worth defending. A chip that says "Kurukshetra 26"
/// and opens onto eight events is a chip the reader catches, and the only reason
/// they would ever disagree is a count taken from the table instead of from the
/// list on screen. So every count here is asserted against a hand-built list, and
/// one case deliberately hands the scope an entity covering an event the screen
/// is not showing.

Map<String, Object?> _row(int id, Map<String, Object?> over) => {
      'id': id,
      'slug': 'scene-$id',
      'epic': 'ramayana',
      'recension': 'valmiki',
      'sequence_no': id,
      'title_en': 'Scene $id, and the long name it was given',
      'title_hi': 'प्रसंग $id, और उसे दिया गया लंबा नाम',
      'short_description_en': 'A blurb of the length these actually run to.',
      'short_description_hi': 'इतनी लंबाई का एक परिचय, जितना ये वास्तव में होते हैं।',
      ...over,
    };

NarrativeNode _node(int id, int book, String arc, [int? arcNo]) =>
    NarrativeNode.fromRow(_row(id, {
      'book_no': book,
      'arc_slug': arc,
      'arc_no': arcNo ?? 1,
      'arc_title_en': 'The arc called $arc',
      'arc_title_hi': '$arc नामक खंड',
    }));

/// A row from before SC-02: no arc at all. These are what the arc facet's gap
/// line is counting.
NarrativeNode _arcless(int id, int book) =>
    NarrativeNode.fromRow(_row(id, {'book_no': book}));

EpicFacetValue _facetValue(int id, String en, String? hi, Set<int> nodes) =>
    EpicFacetValue(
        entityId: id,
        titleEn: en,
        titleHi: hi,
        nodeIds: nodes,
        firstSequence: 0);

/// Two kandas, three arcs, five events — small enough to count by hand.
final _five = [
  _node(1, 1, 'birth', 1),
  _node(2, 1, 'birth', 1),
  _node(3, 1, 'bow', 2),
  _node(4, 2, 'exile', 1),
  _node(5, 2, 'exile', 1),
];

ExploreScope _scope({
  List<NarrativeNode>? all,
  ExploreBy facet = ExploreBy.book,
  String? value,
  bool hindi = false,
  List<EpicFacetValue> cast = const [],
  List<EpicFacetValue> places = const [],
  String epic = 'ramayana',
}) =>
    ExploreScope.of(
      epic: epic,
      all: all ?? _five,
      facet: facet,
      value: value,
      hindi: hindi,
      cast: cast,
      places: places,
    );

List<int> _ids(ExploreScope s) => s.events.map((e) => e.id).toList();

void main() {
  group('by section, which is the default', () {
    test('offers no second row and filters nothing', () {
      final s = _scope();
      expect(s.choices, isEmpty,
          reason: 'the sections already group the epic in either mode');
      expect(_ids(s), [1, 2, 3, 4, 5]);
      expect(s.filtered, isFalse);
      expect(s.unassigned, 0,
          reason: 'every event is in a section, even an unwritten one');
    });

    test('the chip says what the tradition says, not what the column says', () {
      expect(ExploreBy.book.label(false, 'ramayana'), 'Kanda');
      expect(ExploreBy.book.label(false, 'mahabharata'), 'Parva');
      expect(ExploreBy.book.label(true, 'ramayana'), 'कांड');
      expect(ExploreBy.book.label(true, 'mahabharata'), 'पर्व');
    });
  });

  group('by arc', () {
    test('every arc in narrative order, counted', () {
      final s = _scope(facet: ExploreBy.arc);
      expect(s.choices.map((c) => c.key), ['birth', 'bow', 'exile'],
          reason: 'section order, then arc_no — which is narrative order');
      expect(s.choices.map((c) => c.count), [2, 1, 2]);
      expect(s.choices.first.label, 'The arc called birth');
    });

    test('picking one narrows to its events', () {
      final s = _scope(facet: ExploreBy.arc, value: 'exile');
      expect(_ids(s), [4, 5]);
      expect(s.filtered, isTrue);
    });

    test('Hindi labels come through', () {
      final s = _scope(facet: ExploreBy.arc, hindi: true);
      expect(s.choices.first.label, 'birth नामक खंड');
    });

    test('events with no arc are reported, not quietly dropped', () {
      final s = _scope(
        all: [..._five, _arcless(6, 2), _arcless(7, 2)],
        facet: ExploreBy.arc,
      );
      expect(s.choices.length, 3, reason: 'an unlabelled arc is not a filter');
      expect(s.total, 7);
      expect(s.unassigned, 2);
      expect(
        ExploreBy.arc.gap(2, 7, false),
        '2 of 7 events are not yet placed in an arc.',
      );
    });

    test('an arc written across two sections is one chip, not two', () {
      // Nothing in the shipped data does this. If it ever does, the failure to
      // prevent is two identical chips each filtering to half the arc.
      final s = _scope(
        all: [_node(1, 1, 'spans'), _node(2, 2, 'spans')],
        facet: ExploreBy.arc,
      );
      expect(s.choices.length, 1);
      expect(s.choices.single.count, 2);
      expect(_ids(_scope(
        all: [_node(1, 1, 'spans'), _node(2, 2, 'spans')],
        facet: ExploreBy.arc,
        value: 'spans',
      )), [1, 2]);
    });
  });

  group('by character', () {
    final cast = [
      _facetValue(11, 'Rama', 'राम', {1, 2, 3, 4, 5}),
      _facetValue(12, 'Sita', 'सीता', {4, 5}),
      _facetValue(13, 'Janaka', 'जनक', {3}),
    ];

    test('most-present first, so the name you want is not a long swipe away', () {
      final s = _scope(facet: ExploreBy.characters, cast: cast);
      expect(s.choices.map((c) => c.label), ['Rama', 'Sita', 'Janaka']);
      expect(s.choices.map((c) => c.count), [5, 2, 1]);
    });

    test('picking one narrows to their events, in narrative order', () {
      final s = _scope(facet: ExploreBy.characters, cast: cast, value: '12');
      expect(_ids(s), [4, 5]);
    });

    test('a count is of what is on screen, never of what is in the table', () {
      // Rama is recorded in a sixth event the epic screen does not show — the
      // shape a war day would have if one ever leaked past the query.
      final s = _scope(
        facet: ExploreBy.characters,
        cast: [_facetValue(11, 'Rama', 'राम', {1, 2, 3, 4, 5, 99})],
      );
      expect(s.choices.single.count, 5,
          reason: 'a chip promising six that opens onto five is a chip that lies');
      expect(_ids(_scope(
        facet: ExploreBy.characters,
        cast: [_facetValue(11, 'Rama', 'राम', {1, 2, 3, 4, 5, 99})],
        value: '11',
      )), [1, 2, 3, 4, 5]);
    });

    test('a figure who appears in nothing shown gets no chip', () {
      final s = _scope(
        facet: ExploreBy.characters,
        cast: [...cast, _facetValue(14, 'Shatrughna', 'शत्रुघ्न', {404})],
      );
      expect(s.choices.map((c) => c.label), isNot(contains('Shatrughna')));
    });

    test('events with nobody recorded are reported', () {
      final s = _scope(
        facet: ExploreBy.characters,
        cast: [_facetValue(11, 'Rama', 'राम', {1, 2})],
      );
      expect(s.unassigned, 3);
      expect(ExploreBy.characters.gap(3, 5, false),
          '3 of 5 events have no cast recorded yet.');
      expect(ExploreBy.characters.gap(3, 5, true), contains('पात्र'));
    });
  });

  group('by place, which is the sparse one', () {
    test('states the shortfall rather than presenting a partial geography', () {
      // The live proportion: seven places cover twenty-eight of sixty-one
      // events, and RM-02 is the task that closes it. A chip row that said
      // nothing would read as though it covered the whole epic.
      final s = _scope(
        facet: ExploreBy.places,
        places: [_facetValue(500, 'Mithila', 'मिथिला', {3})],
      );
      expect(s.choices.single.count, 1);
      expect(s.unassigned, 4);
      expect(ExploreBy.places.gap(33, 61, false),
          '33 of 61 events have no place recorded yet.');
      expect(ExploreBy.places.gap(33, 61, true), contains('स्थान'));
    });

    test('a filter still lands on exactly the events set there', () {
      final s = _scope(
        facet: ExploreBy.places,
        places: [_facetValue(500, 'Mithila', 'मिथिला', {3, 4})],
        value: '500',
      );
      expect(_ids(s), [3, 4]);
    });
  });

  group('a selection that no longer has a chip', () {
    test('shows nothing rather than silently reverting to everything', () {
      // The reader is holding a filter and the data moves under it. Quietly
      // showing all five would read as "this character is in every event".
      final s = _scope(facet: ExploreBy.characters, cast: const [], value: '11');
      expect(s.events, isEmpty);
      expect(s.filtered, isTrue);
    });

    test('an arc slug that is not there behaves the same way', () {
      expect(_scope(facet: ExploreBy.arc, value: 'no-such-arc').events, isEmpty);
    });
  });

  group('the key the shelf re-seeds on', () {
    test('changes with the axis and with the choice', () {
      final keys = {
        _scope().stateKey,
        _scope(facet: ExploreBy.arc).stateKey,
        _scope(facet: ExploreBy.arc, value: 'birth').stateKey,
        _scope(facet: ExploreBy.arc, value: 'bow').stateKey,
      };
      expect(keys.length, 4, reason: 'each is a different set of events');
    });
  });

  group('themes is absent on purpose', () {
    test('the enum offers four axes, and none of them is themes', () {
      // One narrative row in seventy-nine carries a theme. A fifth chip would be
      // a filter with nothing behind it; it arrives with the content.
      expect(ExploreBy.values.length, 4);
      expect(ExploreBy.values.map((f) => f.name), isNot(contains('themes')));
    });

    test('no two axes share a glyph, or a name with the view modes', () {
      final icons = ExploreBy.values.map((f) => f.icon).toSet();
      expect(icons.length, ExploreBy.values.length);
      expect(icons, isNot(contains(Icons.timeline_rounded)),
          reason: 'that icon is the Timeline mode toggle');
      expect(ExploreBy.values.map((f) => f.label(false, 'ramayana')),
          isNot(contains('Story')),
          reason: 'a chip and a view mode must not share a word');
    });
  });

  group('the arc roster is derived, unlike the section roster', () {
    test('an epic with no events offers no arcs', () {
      expect(allArcs('ramayana', const []), isEmpty);
      // Where sections do the opposite, on purpose (SC-15).
      expect(sectionsFor('ramayana').length, 7);
    });
  });

  group('the chip rows draw, in both scripts, on the narrowest phone', () {
    /// Both rows scroll horizontally and build lazily, so a chip past the right
    /// edge does not exist yet. Claims about *what is offered* get a wide surface
    /// so every chip is built; claims about *layout* get 320 dp, which is the
    /// floor this app targets and the axis these rows would fail on.
    Future<void> pump(WidgetTester tester, Widget child,
        {double width = 800, bool dark = false}) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      ));
      await tester.pumpAndSettle();
    }

    for (final hi in [false, true]) {
      testWidgets('the axis row offers all four, and reports a tap, hindi=$hi',
          (tester) async {
        ExploreBy? tapped;
        await pump(
          tester,
          ExploreByChips(
            epic: 'mahabharata',
            selected: ExploreBy.book,
            hindi: hi,
            onSelected: (f) => tapped = f,
          ),
        );
        expect(tester.takeException(), isNull);
        for (final f in ExploreBy.values) {
          expect(find.text(f.label(hi, 'mahabharata')), findsOneWidget,
              reason: 'the ${f.name} axis');
        }

        await tester.tap(find.text(ExploreBy.places.label(hi, 'mahabharata')));
        expect(tapped, ExploreBy.places);
      });

      testWidgets('the value row counts, selects, and clears, hindi=$hi',
          (tester) async {
        String? picked;
        var cleared = false;
        await pump(
          tester,
          FacetValueChips(
            choices: const [
              (key: '11', label: 'Rama', count: 18),
              (key: '12', label: 'Yudhishthira', count: 13),
            ],
            total: 61,
            selected: '11',
            hindi: hi,
            onSelected: (v) {
              picked = v;
              cleared = v == null;
            },
          ),
        );
        expect(tester.takeException(), isNull);
        // The count rides in the label: the row runs to forty-odd entries, and a
        // number is what makes the swipe worth taking.
        expect(find.text('Rama  18'), findsOneWidget);
        expect(find.text('${hi ? 'सब' : 'All'}  61'), findsOneWidget);

        await tester.tap(find.text('Yudhishthira  13'));
        expect(picked, '12');

        // Tapping what is already on clears it, the way every chip row here does.
        await tester.tap(find.text('Rama  18'));
        expect(cleared, isTrue);
      });

      testWidgets('both rows lay out at 320 dp, hindi=$hi', (tester) async {
        await pump(
          tester,
          Column(
            children: [
              ExploreByChips(
                epic: 'mahabharata',
                selected: ExploreBy.characters,
                hindi: hi,
                onSelected: (_) {},
              ),
              FacetValueChips(
                choices: const [
                  (key: '11', label: 'Yudhishthira', count: 13),
                  (key: '12', label: 'Dhritarashtra', count: 9),
                ],
                total: 61,
                selected: null,
                hindi: hi,
                onSelected: (_) {},
              ),
            ],
          ),
          width: 320,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the axis row keeps its warm accent in the dark theme',
        (tester) async {
      await pump(
        tester,
        ExploreByChips(
          epic: 'ramayana',
          selected: ExploreBy.characters,
          hindi: true,
          onSelected: (_) {},
        ),
        dark: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the gap line wraps rather than overflowing', (tester) async {
      await pump(
        tester,
        ExploreGapNote(
          text: ExploreBy.places.gap(33, 61, true),
          hindi: true,
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('स्थान'), findsOneWidget);
    });
  });
}
