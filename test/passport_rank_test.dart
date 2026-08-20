import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/temples/passport_providers.dart';

void main() {
  test('the level ladder starts at one and climbs with darshan', () {
    expect(YatraRank.levelFor(0), 1);
    expect(YatraRank.forCount(0).titleEn, 'Yatri');
    expect(YatraRank.forCount(5).titleEn, 'Bhakt');
    expect(YatraRank.forCount(12).titleEn, 'Sadhak');
    expect(YatraRank.forCount(100).titleEn, 'Yatra Acharya');
    expect(YatraRank.next(100), isNull, reason: 'the ladder has a top');
  });

  test('a rank holds until the next threshold is actually reached', () {
    expect(YatraRank.forCount(4).titleEn, 'Yatri');
    expect(YatraRank.forCount(11).titleEn, 'Bhakt');
    expect(YatraRank.next(4)!.from, 5);
  });

  test('the passport number depends on the holder and nothing else', () {
    // It must not renumber itself as stamps are added.
    final a = PassportStats.number('Tushar');
    final b = PassportStats.number('Tushar');
    expect(a, b);
    expect(a, isNot(PassportStats.number('Someone Else')));
    expect(PassportStats.number('').isNotEmpty, isTrue);
  });

  test('stats read the visits rather than being stored beside them', () {
    final visited = [
      PassportEntry(
          templeId: 1,
          nameEn: 'Somnath',
          state: 'Gujarat',
          visitedAt: DateTime(2026, 3, 2)),
      PassportEntry(
          templeId: 2,
          nameEn: 'Kedarnath',
          state: 'Uttarakhand',
          visitedAt: DateTime(2024, 8, 9)),
      // Same state again: states must count distinctly.
      PassportEntry(
          templeId: 3,
          nameEn: 'Dwarka',
          state: 'Gujarat',
          visitedAt: DateTime(2025, 1, 1)),
    ];
    final s = PassportStats.of(visited);
    expect(s.darshan, 3);
    expect(s.states, 2);
    expect(s.sinceYear, 2024, reason: 'the earliest year, not the latest');
  });

  test('a dateless visit still counts but sets no start year', () {
    const visited = [
      PassportEntry(templeId: 1, nameEn: 'Somnath', visited: true),
    ];
    final s = PassportStats.of(visited);
    expect(s.darshan, 1);
    expect(s.sinceYear, isNull);
  });
}
