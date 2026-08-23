import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/narrative/narrative_models.dart';
import 'package:divyavaani/features/narrative/story_structure.dart';

/// A row as sqflite hands it over, with only the columns a caller supplies.
Map<String, Object?> _row(int id, Map<String, Object?> over) => {
      'id': id,
      'slug': 'scene-$id',
      'epic': 'ramayana',
      'recension': 'valmiki',
      'sequence_no': id,
      'title_en': 'Scene $id',
      'short_description_en': 'A blurb.',
      ...over,
    };

NarrativeNode _node(int id, Map<String, Object?> over) =>
    NarrativeNode.fromRow(_row(id, over));

List<StorySection> _story(String epic, List<NarrativeNode> nodes) =>
    buildStory(epic, nodes);

StorySection _sectionNo(List<StorySection> s, int no) =>
    s.firstWhere((x) => x.section.no == no);

void main() {
  group('the canonical roster', () {
    test('the Ramayana has its seven kandas, in order', () {
      expect(ramayanaSections.length, 7);
      expect(
        ramayanaSections.map((s) => s.no),
        [1, 2, 3, 4, 5, 6, 7],
        reason: 'section numbers are the grouping key and must be dense',
      );
      expect(ramayanaSections.last.titleEn, 'Uttara Kanda');
    });

    test('the Mahabharata has all eighteen parvas, in order', () {
      expect(mahabharataSections.length, 18);
      expect(mahabharataSections.map((s) => s.no),
          List.generate(18, (i) => i + 1));
    });

    test('every section has both languages', () {
      for (final s in [...ramayanaSections, ...mahabharataSections]) {
        expect(s.titleEn, isNotEmpty, reason: 'section ${s.no}');
        expect(s.titleHi, isNotEmpty, reason: 'section ${s.no}');
        expect(s.title(true), s.titleHi);
        expect(s.title(false), s.titleEn);
      }
    });

    test('Uttara Kanda carries the tradition note in both languages (SC-15)',
        () {
      final uttara = ramayanaSections.firstWhere((s) => s.no == 7);
      expect(uttara.noteEn, isNotNull);
      expect(uttara.noteHi, isNotNull);
      // The note must be about what traditions hold, not a verdict of ours.
      expect(uttara.noteEn, contains('differ'));
      expect(uttara.teaching, isFalse);
    });

    test('Shanti and Anushasana are marked as teachings (SC-14)', () {
      final teaching =
          mahabharataSections.where((s) => s.teaching).map((s) => s.no).toList();
      expect(teaching, [12, 13]);
      for (final no in teaching) {
        expect(_sectionOf(no).noteEn, isNotNull,
            reason: 'a reader is told why parva $no looks different');
      }
    });

    test('no other section claims to be a teaching', () {
      expect(ramayanaSections.any((s) => s.teaching), isFalse);
    });

    test('sectionsFor picks the epic, and defaults rather than throwing', () {
      expect(sectionsFor('mahabharata'), same(mahabharataSections));
      expect(sectionsFor('ramayana'), same(ramayanaSections));
      expect(sectionsFor('something-else'), same(ramayanaSections));
    });
  });

  group('buildStory groups without losing anything', () {
    test('events land in the section their book_no names', () {
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1}),
        _node(2, const {'book_no': 1}),
        _node(3, const {'book_no': 2}),
      ]);
      expect(_sectionNo(story, 1).eventCount, 2);
      expect(_sectionNo(story, 2).eventCount, 1);
      expect(_sectionNo(story, 3).eventCount, 0);
    });

    test('a section with no events still appears, and says it is empty', () {
      // The live case: nothing is written in the Uttara Kanda, and a
      // six-kanda Ramayana would be wrong (SC-15).
      final story = _story('ramayana', [_node(1, const {'book_no': 1})]);
      expect(story.length, 7);
      final uttara = _sectionNo(story, 7);
      expect(uttara.isEmpty, isTrue);
      expect(uttara.arcs, isEmpty);
      expect(uttara.note(false), isNotNull,
          reason: 'the empty state still carries the tradition note');
    });

    test('grouping is on book_no, never on the label', () {
      // Book 1 is spelled two ways in the shipped data. Grouping on the label
      // would draw the same kanda twice.
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1, 'book_label_hi': 'बाल कांड'}),
        _node(2, const {'book_no': 1, 'book_label_hi': 'बालकांड'}),
      ]);
      expect(story.where((s) => !s.isEmpty).length, 1);
      expect(_sectionNo(story, 1).eventCount, 2);
      expect(_sectionNo(story, 1).title(true), 'बाल कांड',
          reason: 'the label comes from the roster, not from whichever row won');
    });

    test('an event with an unknown book_no is kept, not dropped', () {
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1}),
        _node(2, const {'book_no': 99, 'book_label_en': 'Some Appendix'}),
      ]);
      expect(_totalEvents(story), 2, reason: 'no content may vanish silently');
      final extra = story.firstWhere((s) => s.unlisted);
      expect(extra.section.titleEn, 'Some Appendix');
      expect(extra.eventCount, 1);
      expect(story.indexOf(extra), story.length - 1,
          reason: 'unplaced content sits after the canonical sections');
    });

    test('an event with no book_no at all is kept', () {
      final story = _story('ramayana', [_node(1, const {})]);
      expect(_totalEvents(story), 1);
      expect(story.any((s) => s.unlisted && s.eventCount == 1), isTrue);
    });

    test('unlisted sections are ordered, with the null book last', () {
      final story = _story('ramayana', [
        _node(1, const {}),
        _node(2, const {'book_no': 40}),
        _node(3, const {'book_no': 30}),
      ]);
      final unlisted =
          story.where((s) => s.unlisted).map((s) => s.section.no).toList();
      expect(unlisted, [30, 40, 0]);
    });

    test('nothing in yields every section, all empty', () {
      final story = _story('mahabharata', const []);
      expect(story.length, 18);
      expect(_totalEvents(story), 0);
      expect(story.every((s) => s.isEmpty), isTrue);
    });
  });

  group('arcs inside a section', () {
    test('events group by arc and arcs sort by arc_no', () {
      final story = _story('ramayana', [
        // Deliberately out of arc order in the row list.
        _node(1, const {
          'book_no': 2,
          'arc_slug': 'the-exile',
          'arc_no': 2,
          'arc_title_en': 'The Exile',
        }),
        _node(2, const {
          'book_no': 2,
          'arc_slug': 'the-boon',
          'arc_no': 1,
          'arc_title_en': 'The Boon',
        }),
        _node(3, const {
          'book_no': 2,
          'arc_slug': 'the-exile',
          'arc_no': 2,
          'arc_title_en': 'The Exile',
        }),
      ]);
      final arcs = _sectionNo(story, 2).arcs;
      expect(arcs.map((a) => a.slug), ['the-boon', 'the-exile']);
      expect(arcs.first.events.map((e) => e.id), [2]);
      expect(arcs.last.events.map((e) => e.id), [1, 3],
          reason: 'within an arc, the order the rows arrived in is kept');
    });

    test('an arc reads its title from its first event, in either language', () {
      final story = _story('ramayana', [
        _node(1, const {
          'book_no': 1,
          'arc_slug': 'a',
          'arc_no': 1,
          'arc_title_en': 'The Boon',
          'arc_title_hi': 'वरदान',
        }),
      ]);
      final arc = _sectionNo(story, 1).arcs.single;
      expect(arc.title(false), 'The Boon');
      expect(arc.title(true), 'वरदान');
    });

    test('events with no arc collect into one untitled arc', () {
      // The shape of every row written before SC-02.
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1}),
        _node(2, const {'book_no': 1}),
      ]);
      final arcs = _sectionNo(story, 1).arcs;
      expect(arcs.length, 1);
      expect(arcs.single.slug, '');
      expect(arcs.single.title(false), isNull);
      expect(arcs.single.events.length, 2);
    });

    test('arced and un-arced events in one section both survive', () {
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1}),
        _node(2, const {'book_no': 1, 'arc_slug': 'a', 'arc_no': 3}),
      ]);
      expect(_sectionNo(story, 1).eventCount, 2);
      expect(_sectionNo(story, 1).arcs.length, 2);
    });

    test('eventCount counts across arcs', () {
      final story = _story('ramayana', [
        _node(1, const {'book_no': 1, 'arc_slug': 'a', 'arc_no': 1}),
        _node(2, const {'book_no': 1, 'arc_slug': 'b', 'arc_no': 2}),
        _node(3, const {'book_no': 1, 'arc_slug': 'b', 'arc_no': 2}),
      ]);
      expect(_sectionNo(story, 1).eventCount, 3);
      expect(_sectionNo(story, 1).isEmpty, isFalse);
    });
  });

  group('a section forwards what the roster says', () {
    test('teaching and note come through to the rendered section', () {
      final story = _story('mahabharata', [_node(1, const {'book_no': 12})]);
      final shanti = _sectionNo(story, 12);
      expect(shanti.teaching, isTrue);
      expect(shanti.note(false), contains('Teachings rather than events'));
      expect(shanti.note(true), isNotNull);
      expect(shanti.title(false), 'Shanti Parva');
    });

    test('a section with no note returns null rather than an empty string', () {
      final story = _story('mahabharata', [_node(1, const {'book_no': 1})]);
      expect(_sectionNo(story, 1).note(false), isNull);
      expect(_sectionNo(story, 1).note(true), isNull);
    });
  });
}

EpicSection _sectionOf(int no) =>
    mahabharataSections.firstWhere((s) => s.no == no);

int _totalEvents(List<StorySection> story) =>
    story.fold(0, (n, s) => n + s.eventCount);
