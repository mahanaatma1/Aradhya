import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/astrology/ashtakoot.dart';
import 'package:divyavaani/features/astrology/astro_chart.dart';

/// KM-01. Ashtakoot is directional: Varna compares the groom's rank against
/// the bride's with `>=`, so swapping the two charts is NOT a no-op. The app
/// asked for "Side 1" and "Side 2" and silently assumed Side 1 was the groom,
/// which meant the same couple could score differently depending on data-entry
/// order with nothing on screen to explain it.
///
/// These pin the direction so a refactor cannot quietly make it symmetric
/// again — or quietly make it asymmetric where it should not be.
void main() {
  // Two charts whose moon signs give different varna ranks. Chosen by rashi:
  // varna rank runs [3,2,1,4] repeating from Aries, so Aries(3) vs Gemini(1).
  BirthChart chartFor(DateTime utc) => computeChart(utc, 28.61, 77.21);
  final one = chartFor(DateTime.utc(1992, 5, 14, 2, 45));
  final two = chartFor(DateTime.utc(1995, 9, 21, 12, 10));

  test('role is carried through to the result', () {
    final asGroom = computeMilan('A', one, 'B', two, roleA: MilanRole.groom);
    final asBride = computeMilan('A', one, 'B', two, roleA: MilanRole.bride);
    expect(asGroom.roleA, MilanRole.groom);
    expect(asBride.roleA, MilanRole.bride);
    // groom/bride accessors resolve to the right chart either way
    expect(asGroom.groom.name, 'A');
    expect(asBride.groom.name, 'B');
    expect(asBride.bride.name, 'A');
  });

  test('the symmetric koots do not care about the role', () {
    final g = computeMilan('A', one, 'B', two, roleA: MilanRole.groom);
    final b = computeMilan('A', one, 'B', two, roleA: MilanRole.bride);
    for (final key in ['yoni', 'maitri', 'gana', 'bhakoot', 'nadi', 'vashya']) {
      expect(g.koot(key).got, b.koot(key).got,
          reason: '$key must not depend on which side is the groom');
    }
  });

  test('Varna reads groom-first, so the role decides its point', () {
    final g = computeMilan('A', one, 'B', two, roleA: MilanRole.groom);
    final b = computeMilan('A', one, 'B', two, roleA: MilanRole.bride);
    // Varna is 1 when groomRank >= brideRank, else 0. With unequal ranks the
    // two orderings must disagree; with equal ranks both are 1.
    final ranksEqual = g.a.varnaRank == g.b.varnaRank;
    if (ranksEqual) {
      expect(g.koot('varna').got, 1.0);
      expect(b.koot('varna').got, 1.0);
    } else {
      expect(g.koot('varna').got, isNot(b.koot('varna').got),
          reason: 'unequal varna ranks must score differently by direction');
    }
  });

  test('the total stays within the traditional 36', () {
    final g = computeMilan('A', one, 'B', two);
    expect(g.total, inInclusiveRange(0, 36));
  });
}
