import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/narrative/narrative_models.dart';

/// The arc ranges are hand-written against sequence_no, so inserting scenes
/// silently mislabels them -- which is exactly what happened when the path
/// grew from twenty scenes to twenty-nine and every arc after the first was
/// wrong. This pins the invariants that make the bands meaningful.
void main() {
  test('arcs are contiguous and non-overlapping', () {
    final arcs = MahabharataArcs.arcs;
    for (var i = 0; i < arcs.length; i++) {
      expect(arcs[i].$3, lessThanOrEqualTo(arcs[i].$4),
          reason: '${arcs[i].$1} starts after it ends');
      if (i > 0) {
        expect(arcs[i].$3, arcs[i - 1].$4 + 1,
            reason: 'gap or overlap before ${arcs[i].$1}');
      }
    }
  });

  test('every scene in the path falls inside an arc', () {
    final last = MahabharataArcs.arcs.last.$4;
    for (var seq = 1; seq <= 29; seq++) {
      expect(MahabharataArcs.arcFor(seq), isNotNull,
          reason: 'sequence $seq has no arc');
    }
    expect(last, greaterThanOrEqualTo(29),
        reason: 'the final arc must cover the whole path');
  });

  test('war days are outside the arc range', () {
    // Days occupy 101..118. If an arc ever reached them, battle days would be
    // drawn into the main narrative path.
    expect(MahabharataArcs.arcFor(101), isNull);
    expect(MahabharataArcs.arcFor(118), isNull);
  });
}
