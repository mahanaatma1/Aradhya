import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/core/providers/app_providers.dart';
import 'package:divyavaani/features/ask/ask_providers.dart';
import 'package:divyavaani/features/gyan/entity_models.dart';
import 'package:divyavaani/features/gyan/entity_providers.dart';
import 'package:divyavaani/features/narrative/narrative_models.dart';
import 'package:divyavaani/features/narrative/narrative_providers.dart';
import 'package:divyavaani/features/narrative/scene_screen.dart';
import 'package:divyavaani/features/related/related_models.dart';
import 'package:divyavaani/features/related/related_rail.dart';

/// SC-10/11/16. The event page, and the promise it makes about its own shape.
///
/// Two things are being defended here. The first is the fixed order — a reader
/// who has seen one event should know where to look on every other one, so the
/// order is asserted by measured position, not by presence. The second is that
/// **a block with nothing in it does not appear at all**: almost none of the
/// Story Cards prose is written yet, and a page of empty labelled panels would
/// promise what is not there.

Map<String, Object?> _row(int id, Map<String, Object?> over) => {
      'id': id,
      'slug': 'scene-$id',
      'epic': 'ramayana',
      'recension': 'valmiki',
      'sequence_no': id,
      'title_en': 'The bow is drawn',
      'title_hi': 'धनुष उठाया जाता है',
      'short_description_en': 'A blurb, which is a fragment and not a summary.',
      'short_description_hi': 'एक परिचय, जो अंश है, सारांश नहीं।',
      'primary_source_name': 'Valmiki Ramayana',
      'primary_source_ref': '1.67',
      ...over,
    };

/// The shape almost every shipped row actually has: a blurb, an old long
/// description, an old one-line lesson, and none of the Story Cards prose.
const _sparse = <String, Object?>{
  'long_description_en': 'The older long description, standing in for a story.',
  'lesson_en': 'Strength is not the same as worth.',
};

/// Everything filled, which is what the page is designed for.
const _full = <String, Object?>{
  'book_no': 2,
  // Deliberately wrong, and deliberately ignored: the shipped labels disagree
  // with themselves across authoring batches, so the crumb reads the roster.
  'book_label_en': 'Book Two',
  'arc_title_en': 'The Boon and the Exile',
  'arc_title_hi': 'वरदान और वनवास',
  'quick_summary_en': 'A summary written as a summary.',
  'quick_summary_hi': 'सारांश के रूप में लिखा गया सारांश।',
  'story_en': 'The narrative proper, at the length these run to.',
  'story_hi': 'कथा स्वयं, उतनी लंबाई में जितनी ये होती हैं।',
  'key_moments_en': '["The bow is brought out.","It is drawn.","It breaks."]',
  'key_moments_hi': '["धनुष लाया जाता है।","वह उठाया जाता है।","वह टूट जाता है।"]',
  'reflection_en': 'What did the breaking of it cost?',
  'reflection_hi': 'उसके टूटने की क्या कीमत चुकाई गई?',
  'themes': '["dharma","court-intrigue"]',
  'place_entity_id': 500,
  'lesson_en': 'Strength is not the same as worth.',
};

NarrativeNode _node(int id, Map<String, Object?> over) =>
    NarrativeNode.fromRow(_row(id, over));

final _place = Entity.fromRow(const {
  'id': 500,
  'slug': 'mithila',
  'kind': 'place',
  'title_en': 'Mithila',
  'title_hi': 'मिथिला',
  'short_description_en': 'The kingdom of Janaka.',
  'short_description_hi': 'जनक का राज्य।',
});

/// The page is taller than the default 800×600 surface and its slivers are
/// lazy, so the surface is made tall. The *width* stays a real phone's, because
/// that is the axis a Row overflows on.
Future<void> pumpScene(
  WidgetTester tester, {
  required Map<int, NarrativeNode?> scenes,
  int open = 1,
  bool hindi = false,
  List<CastMember> cast = const [],
  ({int bookId, int index})? verseLocation,
  Entity? place,
  double width = 380,
  double height = 3000,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      isHindiProvider.overrideWithValue(hindi),
      sceneByIdProvider.overrideWith((ref, id) => scenes[id]),
      sceneCastProvider.overrideWith((ref, id) => cast),
      entityByIdProvider.overrideWith((ref, id) => place),
      verseLocationProvider.overrideWith((ref, id) => verseLocation),
      // The rail has its own tests; here it must simply not reach a database.
      relatedProvider.overrideWith((ref, key) => const <RelatedItem>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: SceneScreen(sceneId: open),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Where a label sits on the page, for asserting order rather than presence.
double _dy(WidgetTester tester, String label) =>
    tester.getTopLeft(find.text(label)).dy;

void main() {
  group('the order of the page is fixed (SC-10)', () {
    testWidgets('every block, top to bottom, in the documented order',
        (tester) async {
      await pumpScene(
        tester,
        scenes: {
          1: _node(1, {..._full, 'prev_node_id': 0, 'next_node_id': 2}),
          0: _node(0, const {'title_en': 'What came before'}),
          2: _node(2, const {'title_en': 'What comes next'}),
        },
        cast: const [
          CastMember(entityId: 11, titleEn: 'Rama', kind: 'deity',
              role: 'protagonist'),
        ],
        place: _place,
        height: 3600,
      );
      expect(tester.takeException(), isNull);

      const order = [
        'IN SHORT',
        'THE STORY',
        'KEY MOMENTS',
        'TO REFLECT ON',
        'WHO IS HERE',
        'WHERE',
        'THEMES',
        'THE ORIGINAL TEXT',
        'PREVIOUS',
        'NEXT',
      ];
      for (final label in order) {
        expect(find.text(label), findsOneWidget, reason: 'block "$label"');
      }
      for (var i = 1; i < order.length; i++) {
        expect(_dy(tester, order[i]), greaterThan(_dy(tester, order[i - 1])),
            reason: '"${order[i]}" must sit below "${order[i - 1]}"');
      }
    });

    testWidgets('the crumb names the section from the roster, not the row',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, _full)});
      // book_no 2 is the Ayodhya Kanda. The row says "Book Two"; the row is
      // not the authority.
      expect(find.textContaining('Ayodhya Kanda'), findsOneWidget);
      expect(find.textContaining('Book Two'), findsNothing);
      // And the arc rides beside it.
      expect(find.textContaining('The Boon and the Exile'), findsOneWidget);
    });
  });

  group('a block with nothing in it does not appear', () {
    testWidgets('the shape that actually ships: a blurb, a long text, a lesson',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, _sparse)});
      expect(tester.takeException(), isNull);

      // No summary is written, so the label is not shown — but the blurb is,
      // unlabelled, because calling a fragment a summary would overstate it.
      expect(find.text('IN SHORT'), findsNothing);
      expect(
        find.text('A blurb, which is a fragment and not a summary.'),
        findsOneWidget,
      );

      // The old columns stand in, through the model's fallbacks.
      expect(find.text('THE STORY'), findsOneWidget);
      expect(find.text('TO REFLECT ON'), findsOneWidget);
      expect(find.text('Think about it'), findsOneWidget);

      // Nothing is written for these, so nothing is labelled.
      expect(find.text('KEY MOMENTS'), findsNothing);
      expect(find.text('WHO IS HERE'), findsNothing);
      expect(find.text('WHERE'), findsNothing);
      expect(find.text('THEMES'), findsNothing);
    });

    testWidgets('a row with only a title and a blurb shows only those',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, const {})});
      expect(tester.takeException(), isNull);
      for (final label in [
        'IN SHORT', 'THE STORY', 'KEY MOMENTS', 'TO REFLECT ON',
        'WHO IS HERE', 'WHERE', 'THEMES',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      // The citation is not conditional. It never is, anywhere in this app.
      expect(find.text('THE ORIGINAL TEXT'), findsOneWidget);
      expect(find.textContaining('Valmiki Ramayana'), findsWidgets);
    });

    testWidgets('a place whose entity is missing claims nothing',
        (tester) async {
      // The id points at a row that is not there — which is the state during
      // the lookup too.
      await pumpScene(
        tester,
        scenes: {1: _node(1, const {'place_entity_id': 999})},
        place: null,
      );
      expect(find.text('WHERE'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the original text (SC-11)', () {
    testWidgets('offers the passage only once a section id resolves',
        (tester) async {
      await pumpScene(
        tester,
        scenes: {1: _node(1, const {'scripture_section_id': 4242})},
        verseLocation: (bookId: 7, index: 13),
      );
      expect(find.text('Read this passage'), findsOneWidget);
    });

    testWidgets('an id that resolves to nothing offers no button',
        (tester) async {
      // A button that landed on a search box would be a promise the page
      // cannot keep.
      await pumpScene(
        tester,
        scenes: {1: _node(1, const {'scripture_section_id': 4242})},
        verseLocation: null,
      );
      expect(find.text('THE ORIGINAL TEXT'), findsOneWidget);
      expect(find.text('Read this passage'), findsNothing);
    });

    testWidgets('no section id at all, and the citation still stands',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, _sparse)});
      expect(find.text('Read this passage'), findsNothing);
      expect(find.text('THE ORIGINAL TEXT'), findsOneWidget);
    });
  });

  group('where to go next (SC-16)', () {
    testWidgets('neighbours come from the denormalised ids', (tester) async {
      await pumpScene(
        tester,
        scenes: {
          1: _node(1, {..._sparse, 'prev_node_id': 8, 'next_node_id': 9}),
          8: _node(8, const {'title_en': 'The earlier event'}),
          9: _node(9, const {'title_en': 'The later event'}),
        },
      );
      expect(find.text('The earlier event'), findsOneWidget);
      expect(find.text('The later event'), findsOneWidget);
      expect(_dy(tester, 'NEXT'), greaterThan(_dy(tester, 'PREVIOUS')));
    });

    testWidgets('an id pointing at nothing shows nothing for that side',
        (tester) async {
      await pumpScene(
        tester,
        scenes: {
          1: _node(1, {..._sparse, 'prev_node_id': 404, 'next_node_id': 9}),
          9: _node(9, const {'title_en': 'The later event'}),
          404: null,
        },
      );
      expect(find.text('PREVIOUS'), findsNothing);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('the first and last events show no paging at all',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, _sparse)});
      expect(find.text('PREVIOUS'), findsNothing);
      expect(find.text('NEXT'), findsNothing);
    });
  });

  group('themes', () {
    testWidgets('a known slug is translated, an unknown one is not a slug',
        (tester) async {
      await pumpScene(tester, scenes: {1: _node(1, _full)}, hindi: true,
          height: 3600);
      expect(find.text('धर्म'), findsOneWidget);
      expect(find.text('Court Intrigue'), findsOneWidget,
          reason: 'an untranslated theme reads as words, never as court-intrigue');
    });

    testWidgets('malformed JSON in a content column shows no themes',
        (tester) async {
      await pumpScene(
        tester,
        scenes: {1: _node(1, const {'themes': '{not a list'})},
      );
      expect(tester.takeException(), isNull);
      expect(find.text('THEMES'), findsNothing);
    });
  });

  group('Hindi', () {
    testWidgets('the full page survives the narrowest phone', (tester) async {
      // 320 dp, and the taller, longer script. If a Row on this page is going
      // to overflow, it does so here.
      await pumpScene(
        tester,
        scenes: {
          1: _node(1, {..._full, 'prev_node_id': 8, 'next_node_id': 9}),
          8: _node(8, const {'title_en': 'Before', 'title_hi': 'पहले'}),
          9: _node(9, const {'title_en': 'After', 'title_hi': 'आगे'}),
        },
        cast: const [
          CastMember(entityId: 11, titleEn: 'Rama', titleHi: 'राम',
              kind: 'deity', role: 'protagonist'),
        ],
        place: _place,
        hindi: true,
        width: 320,
        height: 4200,
      );
      expect(tester.takeException(), isNull);
      // And it is genuinely in Hindi, not English with a Hindi locale.
      expect(find.text('कथा'), findsOneWidget);
      expect(find.text('विचार के लिए'), findsOneWidget);
      expect(find.text('इस पर विचार करें'), findsOneWidget);
    });
  });

  group('a scene that is not there', () {
    testWidgets('says so rather than rendering an empty page', (tester) async {
      await pumpScene(tester, scenes: const {1: null});
      expect(find.text('Scene not found'), findsOneWidget);
    });
  });
}
