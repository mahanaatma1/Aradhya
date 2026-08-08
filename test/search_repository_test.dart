// Runs SearchRepository's real SQL against the real bundled index.
//
// This exists because of a bug that no amount of reading caught: SQLite binds
// `?` positionally in SQL-TEXT order, and the first version of `search()`
// appended the scoring arguments last while their placeholders sat first in the
// SELECT clause. The query ran without error and returned confident nonsense.
//
// Unit-testing the query builder in isolation would not have found it. Only
// executing the SQL against real data does.

import 'dart:io';

import 'package:divyavaani/features/search/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  final gyan = File('assets/db/gyan.sqlite');
  final content = File('assets/db/content.sqlite');

  late Database db;
  late SearchRepository repo;

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    // Mirror production exactly: content.sqlite is `main`, gyan is ATTACHed.
    // Testing against gyan alone would not catch an unqualified table name.
    // Absolute paths: sqflite_common_ffi resolves relative ones against its
    // own databases directory, not the repo root.
    db = await databaseFactoryFfi.openDatabase(content.absolute.path,
        options: OpenDatabaseOptions(readOnly: true));
    await db.execute("ATTACH DATABASE ? AS gyan", [gyan.absolute.path]);
    repo = SearchRepository(db);
  });

  tearDownAll(() async {
    try {
      await db.close();
    } catch (_) {/* setUpAll may have failed before db was assigned */}
  });

  test('the index is actually populated', () async {
    final n = (await db.rawQuery('SELECT COUNT(*) c FROM gyan.search_docs'))
        .first['c'] as int;
    expect(n, greaterThan(30000),
        reason: 'run: py -m content.tools.build');
  });

  group('scripts and spellings converge', () {
    test('krishna / कृष्ण / kṛṣṇa reach the same top result', () async {
      final a = await repo.search('krishna', limit: 3);
      final b = await repo.search('कृष्ण', limit: 3);
      final c = await repo.search('kṛṣṇa', limit: 3);

      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(c, isNotEmpty);
      expect(a.first.docId, b.first.docId,
          reason: 'Devanagari must reach the same document as English');
      expect(a.first.docId, c.first.docId,
          reason: 'IAST must reach the same document as English');
    });

    test('hanuman finds temples, an aarti and a chalisa', () async {
      final hits = await repo.search('hanuman', limit: 20);
      final kinds = hits.map((h) => h.kind).toSet();
      expect(kinds, contains('temple'));
      expect(kinds.intersection({'aarti', 'chalisa'}), isNotEmpty);
    });
  });

  group('ranking', () {
    test('scores descend', () async {
      final hits = await repo.search('shiva', limit: 15);
      expect(hits.length, greaterThan(3));
      for (var i = 1; i < hits.length; i++) {
        expect(hits[i].score, lessThanOrEqualTo(hits[i - 1].score));
      }
    });

    test('a title match outranks a body-only match', () async {
      // Field weights: title 10, body 1. If argument binding is wrong these
      // scores collapse and the order goes arbitrary.
      final hits = await repo.search('kedarnath', limit: 5);
      expect(hits.first.titleEn.toLowerCase(), contains('kedarnath'));
    });
  });

  group('multi-word queries are AND-ed', () {
    test('two words are narrower than one', () async {
      final one = await repo.search('hanuman', limit: 100);
      final two = await repo.search('hanuman chalisa', limit: 100);
      expect(two.length, lessThan(one.length));
      expect(two, isNotEmpty, reason: 'the AND must not eliminate everything');
    });
  });

  group('city search — the G6 fix', () {
    test('substring match finds Navi Mumbai from "mumbai"', () async {
      final cities = await repo.searchCities('mumbai', limit: 20);
      final names = cities.map((c) => c.titleEn).toList();
      expect(names, contains('Mumbai'));
      expect(names.any((n) => n.contains('Navi Mumbai')), isTrue,
          reason: 'the old `name LIKE \'q%\'` could never reach this');
    });

    test('cities are hidden from general search', () async {
      final general = await repo.search('mumbai', limit: 40);
      expect(general.every((h) => h.kind != 'city'), isTrue,
          reason: '4,276 cities would swamp every other result');
    });
  });

  group('filters and guards', () {
    test('kind filter restricts results', () async {
      final hits = await repo.search('rama', kind: 'shloka', limit: 10);
      expect(hits, isNotEmpty);
      expect(hits.every((h) => h.kind == 'shloka'), isTrue);
    });

    test('counts by kind agree with the filtered result set', () async {
      final counts = await repo.countsByKind('hanuman');
      expect(counts, isNotEmpty);
      for (final kind in counts.keys) {
        // The limit has to exceed the largest bucket or this compares a
        // truncated page against a full count: "hanuman" alone matches 883
        // verses, because the term appears in many translated bodies.
        final hits = await repo.search('hanuman', kind: kind, limit: 5000);
        expect(hits.length, counts[kind],
            reason: 'chip count for "$kind" disagrees with its result list');
      }
    });

    test('every hit carries a usable route', () async {
      final hits = await repo.search('shiva', limit: 30);
      for (final h in hits) {
        expect(h.route, startsWith('/'),
            reason: 'a result that cannot navigate is worse than no result');
      }
    });

    test('short and empty queries return nothing rather than everything',
        () async {
      expect(await repo.search(''), isEmpty);
      expect(await repo.search('a'), isEmpty);
      expect(await repo.search('   '), isEmpty);
      expect(await repo.search('!!!'), isEmpty);
    });

    test('a query matching nothing returns empty, not an error', () async {
      expect(await repo.search('zzzzqqqqxxxx'), isEmpty);
    });
  });
}
