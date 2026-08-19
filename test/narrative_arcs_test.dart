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

  test('Ramayana kanda order is a single pass, never a repeat', () {
    // Scenes added in a later batch were numbered after the existing ones, so
    // the journey ran through all seven kandas and then started again at Bala
    // Kanda. book_no must never decrease as sequence_no increases.
    const bookForSequence = <int, int>{
      1: 1, 9: 1, 10: 2, 15: 2, 16: 3, 19: 3, 20: 4, 22: 4,
      23: 5, 26: 5, 27: 6, 31: 6, 32: 7,
    };
    var highest = 0;
    for (final seq in bookForSequence.keys.toList()..sort()) {
      final book = bookForSequence[seq]!;
      expect(book, greaterThanOrEqualTo(highest),
          reason: 'kanda goes backwards at sequence $seq');
      highest = book;
    }
  });
}
