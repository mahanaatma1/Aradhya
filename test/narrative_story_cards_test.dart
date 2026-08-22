import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/narrative/narrative_models.dart';

/// A row as sqflite hands it over, with only the columns a caller supplies.
Map<String, Object?> row(Map<String, Object?> over) => {
      'id': 1,
      'slug': 'scene',
      'epic': 'ramayana',
      'recension': 'valmiki',
      'sequence_no': 1,
      'title_en': 'A scene',
      'short_description_en': 'A blurb.',
      ...over,
    };

void main() {
  group('Story Cards fields are additive', () {
    test('a scene written before the migration still parses', () {
      // Every Story Cards column is absent here, which is exactly the shape of
      // the 79 scenes that existed before SC-01.
      final n = NarrativeNode.fromRow(row(const {}));
      expect(n.arcSlug, isNull);
      expect(n.quickSummary(false), isNull);
      expect(n.keyMoments(false), isEmpty);
      expect(n.themes, isEmpty);
      expect(n.prevNodeId, isNull);
      expect(n.nextNodeId, isNull);
    });

    test('story falls back to the long description', () {
      final n = NarrativeNode.fromRow(row(const {
        'long_description_en': 'The older prose.',
      }));
      expect(n.story(false), 'The older prose.',
          reason: 'an older scene must still read as a story');

      final w = NarrativeNode.fromRow(row(const {
        'long_description_en': 'The older prose.',
        'story_en': 'The new narrative.',
      }));
      expect(w.story(false), 'The new narrative.');
    });

    test('reflection falls back to the deprecated lesson', () {
      final n = NarrativeNode.fromRow(row(const {
        'lesson_en': 'Duty above comfort.',
      }));
      expect(n.reflection(false), 'Duty above comfort.');

      final w = NarrativeNode.fromRow(row(const {
        'lesson_en': 'Duty above comfort.',
        'reflection_en': 'What does keeping a hard promise cost?',
      }));
      expect(w.reflection(false), 'What does keeping a hard promise cost?',
          reason: 'the question wins over the moral wherever one exists');
    });
  });

  group('JSON columns', () {
    test('key moments and themes parse', () {
      final n = NarrativeNode.fromRow(row(const {
        'key_moments_en': '["Kaikeyi asks","Rama accepts","They depart"]',
        'themes': '["dharma","sacrifice"]',
      }));
      expect(n.keyMoments(false), ['Kaikeyi asks', 'Rama accepts', 'They depart']);
      expect(n.themes, ['dharma', 'sacrifice']);
    });

    test('malformed JSON yields an empty list, never an exception', () {
      // A bad content column must not take the screen down with it.
      final n = NarrativeNode.fromRow(row(const {
        'key_moments_en': '{not json',
        'themes': 'null',
      }));
      expect(n.keyMoments(false), isEmpty);
      expect(n.themes, isEmpty);
    });

    test('non-string entries are dropped rather than stringified', () {
      final n = NarrativeNode.fromRow(row(const {'themes': '["dharma",7,null]'}));
      expect(n.themes, ['dharma']);
    });
  });

  group('bilingual selection', () {
    test('Hindi is used when present and falls back when not', () {
      final n = NarrativeNode.fromRow(row(const {
        'quick_summary_en': 'Rama accepts exile.',
        'quick_summary_hi': 'राम वनवास स्वीकार करते हैं।',
        'story_en': 'English body.',
      }));
      expect(n.quickSummary(true), 'राम वनवास स्वीकार करते हैं।');
      expect(n.quickSummary(false), 'Rama accepts exile.');
      // No Hindi story, so Hindi readers still get something.
      expect(n.story(true), 'English body.');
    });

    test('an empty Hindi string counts as absent, not as content', () {
      final n = NarrativeNode.fromRow(row(const {
        'arc_title_en': 'The Exile',
        'arc_title_hi': '',
      }));
      expect(n.arcTitle(true), 'The Exile');
    });
  });
}
