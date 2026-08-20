import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/temples/passport_providers.dart';

/// PP-01..04. The passport is the one feature built entirely on data the user
/// created, so the guarantees worth pinning are about honesty rather than
/// layout: a partial collection must read as partial, and an entry must not
/// claim a visit it does not have.
void main() {
  test('collections declare what the tradition counts', () {
    for (final c in kCollections) {
      expect(c.canonical, greaterThan(0),
          reason: '${c.titleEn} must say how many the tradition counts');
      expect(c.titleHi.isNotEmpty, isTrue,
          reason: '${c.titleEn} needs a Hindi title');
      expect(c.tag.isNotEmpty, isTrue);
    }
  });

  test('the complete sets are declared with their real counts', () {
    int canonicalOf(String tag) =>
        kCollections.firstWhere((c) => c.tag == tag).canonical;
    expect(canonicalOf('jyotirlinga'), 12);
    expect(canonicalOf('panchkedar'), 5);
    expect(canonicalOf('pancha_bhoota'), 5);
    expect(canonicalOf('char_dham'), 4);
  });

  test('a date implies a visit, and a dated visit is a visit', () {
    const unvisited = PassportEntry(templeId: 1, nameEn: 'Somnath');
    expect(unvisited.visited, isFalse);

    final visited = PassportEntry(
        templeId: 1, nameEn: 'Somnath', visitedAt: DateTime(2026, 1, 1));
    expect(visited.visited, isTrue);
  });

  test('a visit backfilled from prefs counts even with no date recorded', () {
    // Temples marked visited before temple_visits existed carry no timestamp.
    // They still happened, and the passport has to show them.
    const dateless =
        PassportEntry(templeId: 1, nameEn: 'Somnath', visited: true);
    expect(dateless.visited, isTrue);
    expect(dateless.visitedAt, isNull);
  });

  test('names fall back to English rather than rendering empty', () {
    const noHindi = PassportEntry(templeId: 1, nameEn: 'Kedarnath');
    expect(noHindi.name(true), 'Kedarnath');

    const both = PassportEntry(
        templeId: 1, nameEn: 'Kedarnath', nameHi: 'केदारनाथ');
    expect(both.name(true), 'केदारनाथ');
    expect(both.name(false), 'Kedarnath');
  });
}
