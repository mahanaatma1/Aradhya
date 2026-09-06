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
    for (final f in [
      'lineage',
      'teaching',
      'dynasty',
      'epic',
      'text',
      'place'
    ]) {
      expect(RelLabels.familyLabel(f, true).isNotEmpty, isTrue);
      expect(RelLabels.familyLabel(f, false).isNotEmpty, isTrue);
      expect(RelLabels.familyLabel(f, true),
          isNot(RelLabels.familyLabel(f, false)));
    }
  });

  // Mirrors `REL_INVERSE` in content/tools/validate.py, which is the single
  // definition of the relation vocabulary -- it is a plain dict and not a SQL
  // CHECK, so it grows without a migration and nothing downstream is forced to
  // notice. `parent_of` is included even though it is not a key there: it is
  // the materialised inverse of `child_of`, so it reaches the screen and needs
  // a label like any other.
  const vocabulary = [
    'appears_in', 'associated_with', 'authored', 'authored_by', 'child_of',
    'consort_of', 'contains', 'disciple_of', 'father_of', 'features',
    'guru_of', 'has_incarnation', 'has_member', 'has_mount', 'has_part',
    'has_symbol', 'incarnation_of', 'killed', 'killed_by', 'located_in',
    'member_of', 'mentioned_in', 'mentions', 'mother_of', 'mount_of',
    'parent_of', 'part_of', 'related_to', 'ruled', 'ruled_by', 'sibling_of',
    'spouse_of', 'symbol_of', 'wielded_by', 'wields', 'worshipped_at',
    'worships',
  ];

  test('every relation type in the vocabulary has a Hindi label', () {
    // Tested against the FALLBACK, not against the English label. The fallback
    // returns the rel_type with its underscores opened out -- ASCII, English
    // word order -- so a type missing from the Hindi table renders English text
    // inside a Hindi screen. Comparing `of(t, true)` to `of(t, false)` looks
    // like the same check and is not: with an English label present and the
    // Hindi one missing the two strings still differ, and the test passes while
    // the screen is wrong. Verified by removing the labels again: this
    // formulation catches it, the en-vs-hi one did not.
    //
    // This is the real defect it guards. `member_of` and `has_member` were
    // added to the vocabulary, to gyan.sql and to validate.py for FT-01's
    // dynasty work, and not here, so Rama's Ikshvaku edge read "member of" to a
    // Hindi reader. Devanagari can never equal the ASCII fallback, which makes
    // the test exact rather than a heuristic.
    final english = [
      for (final t in vocabulary)
        if (RelLabels.of(t, true) == t.replaceAll('_', ' ')) t,
    ];
    expect(english, isEmpty,
        reason: 'no Hindi label, so a Hindi screen shows English: $english');
  });

  test('every relation type in the vocabulary has an English label', () {
    // Case-sensitive on purpose: 'Ruled' is a label and 'ruled' is the
    // fallback, and lower-casing to compare would flag the labelled type.
    final raw = [
      for (final t in vocabulary)
        if (RelLabels.of(t, false) == t.replaceAll('_', ' ')) t,
    ];
    expect(raw, isEmpty, reason: 'unlabelled, showing the rel_type: $raw');
  });

  test('a dynasty is not a parent', () {
    // `member_of` used to fall through to 'general', which put Rama's Ikshvaku
    // membership in the same bucket as an untyped `related_to`. Filing it under
    // 'lineage' instead would be the opposite error -- the type exists
    // precisely because no genealogical relation meant "belongs to a house".
    expect(rel('member_of').family, 'dynasty');
    expect(rel('has_member').family, 'dynasty');
    expect(rel('member_of').family, isNot(rel('father_of').family));
  });
}
