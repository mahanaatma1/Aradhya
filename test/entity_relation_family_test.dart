import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/gyan/entity_models.dart';

EntityRelation rel(String type) => EntityRelation(
      relType: type,
      dstId: 1,
      dstSlug: 'x',
      dstTitleEn: 'X',
      dstKind: 'deity',
    );

void main() {
  test('every relation type lands in a named family, not a catch-all', () {
    expect(rel('father_of').family, 'lineage');
    expect(rel('spouse_of').family, 'lineage');
    expect(rel('guru_of').family, 'teaching');
    expect(rel('disciple_of').family, 'teaching');
    expect(rel('wields').family, 'epic');
    expect(rel('incarnation_of').family, 'epic');
    expect(rel('appears_in').family, 'text');
    expect(rel('located_in').family, 'place');
  });

  test('an unknown relation type still groups rather than vanishing', () {
    // The vocabulary is meant to grow; a new type must not drop off the screen.
    final f = rel('bestowed_boon_on').family;
    expect(f.isNotEmpty, isTrue);
    expect(RelLabels.familyLabel(f, false).isNotEmpty, isTrue);
  });

  test('a relation label falls back to readable text, never a raw key', () {
    expect(RelLabels.of('father_of', false), isNot(contains('_')));
    expect(RelLabels.of('some_new_edge', false), 'some new edge');
  });

  test('family labels are bilingual', () {
    for (final f in ['lineage', 'teaching', 'epic', 'text', 'place']) {
      expect(RelLabels.familyLabel(f, true).isNotEmpty, isTrue);
      expect(RelLabels.familyLabel(f, false).isNotEmpty, isTrue);
      expect(RelLabels.familyLabel(f, true),
          isNot(RelLabels.familyLabel(f, false)));
    }
  });
}
