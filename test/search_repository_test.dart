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

  group('the "Try" row comes from the corpus (SR-02)', () {
    test('every term is a major entity, in both languages', () async {
      final terms = await repo.curatedTerms();
      expect(terms.length, 8, reason: 'the row asks for eight');
      for (final t in terms) {
        expect(t.en, isNotEmpty);
        expect(t.hi, isNotNull,
            reason: 'a Hindi reader must not be shown a Latin chip: ${t.en}');
        expect(t.hi, isNotEmpty);
      }
    });

    test('every term actually finds something', () async {
      // The failure this guards is the quiet one: a chip that looks like an
      // invitation and returns "Nothing found" when tapped. Both spellings are
      // checked, because the chip submits whichever the reader can see.
      for (final t in await repo.curatedTerms()) {
        expect(await repo.search(t.en, limit: 1), isNotEmpty,
            reason: '"${t.en}" is offered but finds nothing');
        expect(await repo.search(t.hi!, limit: 1), isNotEmpty,
            reason: '"${t.hi}" is offered but finds nothing');
      }
    });

    test('the row is a spread of kinds, not eight deities', () async {
      // importance alone would hand back thirteen deities before the first
      // hero — the round-robin is the whole point of the method.
      final terms = await repo.curatedTerms();
      final kinds = <String>{};
      for (final t in terms) {
        final row = await db.rawQuery(
            'SELECT kind FROM gyan.entities WHERE title_en = ? LIMIT 1',
            [t.en]);
        kinds.add(row.first['kind'] as String);
      }
      expect(kinds.length, greaterThanOrEqualTo(4),
          reason: 'got only $kinds across eight chips');
    });

    test('the order is stable, so the row does not reshuffle', () async {
      final a = await repo.curatedTerms();
      final b = await repo.curatedTerms();
      expect([for (final t in a) t.en], [for (final t in b) t.en]);
    });
  });

  group('one edit away (SR-03)', () {
    test('a dropped letter is corrected', () async {
      // "hanumn" — the sort of miss a thumb makes on a phone keyboard.
      final s = await repo.spellingSuggestions('hanumn');
      expect(s, contains('hanuman'));
    });

    test('a doubled letter is corrected', () async {
      expect(await repo.spellingSuggestions('krishnaa'), contains('krishna'));
    });

    test('a wrong letter is corrected', () async {
      expect(await repo.spellingSuggestions('shivx'), contains('shiva'));
    });

    test('the most-used correction is offered first', () async {
      // Ranked by how many documents hold the term, so the suggestion is the
      // word most likely meant rather than whichever the dictionary reached
      // first. Without the ordering this returns something valid but arbitrary.
      final s = await repo.spellingSuggestions('ram');
      expect(s, isNotEmpty);
      final counts = <String, int>{};
      for (final token in s) {
        counts[token] = (await repo.search(token, limit: 5000)).length;
      }
      expect(counts[s.first], counts.values.reduce((a, b) => a > b ? a : b),
          reason: 'the head of $s is not the most widely used of them');
    });

    test('a correct spelling is never "corrected"', () async {
      // Nothing is suggested when the word is already in the dictionary,
      // because the caller only asks after a miss — and a suggestion identical
      // to what was typed reads as the app malfunctioning.
      expect(await repo.spellingSuggestions('hanuman'),
          isNot(contains('hanuman')));
    });

    test('a first-letter typo is not corrected, and says so by returning none',
        () async {
      // The documented limit. Candidates are bounded to the same first letter,
      // which is what keeps this to a few hundred rows instead of all 20,227
      // terms on every failed keystroke.
      expect(await repo.spellingSuggestions('janumam'), isEmpty);
    });

    test('two edits away is not a correction', () async {
      expect(await repo.spellingSuggestions('hanxmxn'), isEmpty);
    });

    test('multi-word and very short queries are left alone', () async {
      // A multi-word query almost never returns nothing, and correcting one
      // word of several is a different problem.
      expect(await repo.spellingSuggestions('hanumn chalisa'), isEmpty);
      expect(await repo.spellingSuggestions('ab'), isEmpty);
      expect(await repo.spellingSuggestions(''), isEmpty);
    });

    test('every correction offered actually finds something', () async {
      // A suggestion is drawn from the term dictionary, so it must have at
      // least one posting. If this ever fails, the dictionary and the postings
      // have diverged.
      for (final q in ['hanumn', 'krishnaa', 'shivx', 'gitaa']) {
        for (final s in await repo.spellingSuggestions(q)) {
          expect(await repo.search(s, limit: 1), isNotEmpty,
              reason: '"$q" suggested "$s", which finds nothing');
        }
      }
    });
  });
}
