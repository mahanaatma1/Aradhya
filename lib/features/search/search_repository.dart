import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import 'search_fold.dart';
import 'search_models.dart';

/// Queries the inverted index in `gyan.sqlite`.
///
/// Every table is qualified `gyan.*`. Unqualified names would still resolve —
/// SQLite falls through to attached databases when `main` has no such table —
/// but only by accident: the day `content.sqlite` gains a `search_docs` of its
/// own, every query here would silently switch to the wrong one.
///
/// Storage shape is deliberately hidden behind this class: it is a plain
/// B-tree index today because FTS5 availability varies across Android system
/// SQLite builds. If `minSdk` ever rises far enough to depend on FTS5, only
/// this file changes.
class SearchRepository {
  SearchRepository(this._db);

  final Database _db;

  /// Field weights. **Must mirror `content/tools/index.py`'s F_* constants** —
  /// a title match should always outrank a body match for the same term.
  static const _weightSql =
      'CASE k.field WHEN 0 THEN 10 WHEN 1 THEN 8 WHEN 2 THEN 4 '
      'WHEN 3 THEN 3 ELSE 1 END';

  /// Kinds excluded from general search. Cities exist for the birth-place
  /// picker; 4,276 of them would swamp every other result.
  static const _hiddenKinds = ["'city'"];

  /// The shortest thing that can be searched for.
  ///
  /// One character matches too much to be worth ranking, so single-character
  /// queries are dropped before they reach the index. Named because it is not
  /// only a guard: anything that *offers* a query — the curated "Try" row, a
  /// spelling correction — has to respect the same floor, or it offers a word
  /// the search cannot honour. That is how "ॐ" came to be a chip that returned
  /// "Nothing found".
  static const minQueryLength = 2;

  /// Search across everything.
  ///
  /// [kind] restricts to one `search_docs.kind`. [includeHidden] is used by the
  /// city picker to reach the rows general search hides.
  ///
  /// Multi-word queries are AND-ed: every word must match the document, which
  /// is what makes "hanuman chalisa" narrower than either word alone.
  Future<List<SearchHit>> search(
    String query, {
    String? kind,
    int limit = 40,
    bool includeHidden = false,
  }) async {
    final words = _queryWords(query);
    if (words.isEmpty) return const [];

    // Arguments MUST be appended in the order their `?` appears in the SQL
    // text — SQLite binds positionally, not by which clause they belong to.
    // Building them out of order silently binds the wrong values and returns
    // nonsense rather than an error.
    final args = <Object?>[];

    // The query is DRIVEN by the first word's postings rather than by a scan of
    // search_docs. One word is normally very selective, so this touches a few
    // hundred rows instead of all 32,597 documents.
    final driveOrs = <String>[];
    for (final v in words.first) {
      // Prefix match as a range scan over the term dictionary — which is why
      // prefixes are never stored, only looked up.
      driveOrs.add('(t.token >= ? AND t.token < ?)');
      args.add(v);
      args.add('$v\u{10FFFF}');
    }

    // Remaining words are AND-ed as membership tests, so "hanuman chalisa" is
    // narrower than either word alone.
    final andClauses = <String>[];
    for (final variants in words.skip(1)) {
      final ors = <String>[];
      for (final v in variants) {
        ors.add('(t2.token >= ? AND t2.token < ?)');
        args.add(v);
        args.add('$v\u{10FFFF}');
      }
      andClauses.add('''
        d.doc_id IN (
          SELECT k2.doc_id FROM gyan.search_terms t2
          JOIN gyan.search_tokens k2 ON k2.term_id = t2.id
          WHERE ${ors.join(' OR ')}
        )''');
    }

    if (kind != null) {
      andClauses.add('d.kind = ?');
      args.add(kind);
    } else if (!includeHidden) {
      andClauses.add('d.kind NOT IN (${_hiddenKinds.join(',')})');
    }

    final sql = '''
      SELECT d.doc_id, d.src, d.kind, d.ref_table, d.ref_id,
             d.title_en, d.title_hi, d.subtitle_en, d.subtitle_hi,
             d.snippet_en, d.snippet_hi, d.route,
             SUM($_weightSql) * d.boost AS score
      FROM gyan.search_terms t
      JOIN gyan.search_tokens k ON k.term_id = t.id
      JOIN gyan.search_docs   d ON d.doc_id  = k.doc_id
      WHERE (${driveOrs.join(' OR ')})
        ${andClauses.isEmpty ? '' : 'AND ${andClauses.join(' AND ')}'}
      GROUP BY d.doc_id
      ORDER BY score DESC, LENGTH(d.title_en) ASC
      LIMIT ?
    ''';
    args.add(limit);

    try {
      final rows = await _db.rawQuery(sql, args);
      return rows.map(SearchHit.fromRow).toList();
    } catch (e) {
      debugPrint('SearchRepository: query failed ($e)');
      return const [];
    }
  }

  /// Result counts per kind, for the filter chips.
  Future<Map<String, int>> countsByKind(String query) async {
    final words = _queryWords(query);
    if (words.isEmpty) return const {};

    // Same positional-binding rule as `search`: append args in SQL-text order.
    final args = <Object?>[];
    final driveOrs = <String>[];
    for (final v in words.first) {
      driveOrs.add('(t.token >= ? AND t.token < ?)');
      args.add(v);
      args.add('$v\u{10FFFF}');
    }

    final andClauses = <String>[];
    for (final variants in words.skip(1)) {
      final ors = <String>[];
      for (final v in variants) {
        ors.add('(t2.token >= ? AND t2.token < ?)');
        args.add(v);
        args.add('$v\u{10FFFF}');
      }
      andClauses.add('''
        d.doc_id IN (
          SELECT k2.doc_id FROM gyan.search_terms t2
          JOIN gyan.search_tokens k2 ON k2.term_id = t2.id
          WHERE ${ors.join(' OR ')}
        )''');
    }

    try {
      final rows = await _db.rawQuery('''
        SELECT d.kind, COUNT(DISTINCT d.doc_id) AS n
        FROM gyan.search_terms t
        JOIN gyan.search_tokens k ON k.term_id = t.id
        JOIN gyan.search_docs   d ON d.doc_id  = k.doc_id
        WHERE (${driveOrs.join(' OR ')})
          ${andClauses.isEmpty ? '' : 'AND ${andClauses.join(' AND ')}'}
          AND d.kind NOT IN (${_hiddenKinds.join(',')})
        GROUP BY d.kind
      ''', args);
      return {
        for (final r in rows) r['kind'] as String: (r['n'] as int),
      };
    } catch (e) {
      debugPrint('SearchRepository: counts failed ($e)');
      return const {};
    }
  }

  /// City lookup for the birth-place picker.
  ///
  /// Replaces `WHERE name LIKE 'q%'`, which was prefix-only and so could never
  /// find "Navi Mumbai" from "mumbai".
  Future<List<SearchHit>> searchCities(String query, {int limit = 30}) =>
      search(query, kind: 'city', limit: limit, includeHidden: true);

  /// The empty-state "Try" terms, taken from the entities the corpus itself
  /// marks as major (`importance = 1`, 38 rows) rather than from a list kept by
  /// hand in Dart. A hand-kept list goes stale silently: it named "Ekadashi"
  /// and "Gita" while the knowledge graph had grown its own answer to
  /// "what matters here".
  ///
  /// Round-robined across `kind` because importance alone would hand back
  /// thirteen deities before the first hero: the point of the row is to show
  /// the *reach* of the index — a deity, a hero, a scripture, a concept — not
  /// to rank gods. Kind order is fixed so the row does not reshuffle between
  /// launches.
  Future<List<CuratedTerm>> curatedTerms({int limit = 8}) async {
    try {
      final rows = await _db.rawQuery('''
        SELECT kind, title_en, title_hi
        FROM gyan.entities
        WHERE importance = 1
        ORDER BY kind, id
      ''');

      final byKind = <String, List<CuratedTerm>>{};
      for (final r in rows) {
        final en = (r['title_en'] as String?) ?? '';
        final hi = r['title_hi'] as String?;
        // Offered only if it works in BOTH languages: the chip submits whichever
        // spelling the reader can see, so a term searchable in one and not the
        // other is a "Nothing found" waiting to happen — "Om" / "ॐ", whose
        // single Devanagari glyph is below [minQueryLength], was exactly that.
        if (en.length < minQueryLength) continue;
        if (hi == null || hi.length < minQueryLength) continue;
        (byKind[r['kind'] as String] ??= []).add((en: en, hi: hi));
      }

      // Anything not named here still appears, just after the kinds that are —
      // a new entity kind must never be able to empty this row.
      const preferred = [
        'deity', 'human', 'scripture', 'concept', 'symbol', 'weapon', 'rishi',
      ];
      final kinds = [
        ...preferred.where(byKind.containsKey),
        ...byKind.keys.where((k) => !preferred.contains(k)),
      ];

      final out = <CuratedTerm>[];
      for (var round = 0; out.length < limit; round++) {
        var took = false;
        for (final k in kinds) {
          final bucket = byKind[k]!;
          if (round >= bucket.length) continue;
          out.add(bucket[round]);
          took = true;
          if (out.length >= limit) break;
        }
        if (!took) break;
      }
      return out;
    } catch (e) {
      debugPrint('SearchRepository: curatedTerms failed ($e)');
      return const [];
    }
  }

  /// Terms within one edit of the query, for a "Did you mean" after a miss.
  ///
  /// Two deliberate limits, both of them the price of not scanning all 20,227
  /// terms on every failed keystroke:
  ///
  ///  * **Single-word queries only.** A multi-word query almost never returns
  ///    nothing — the AND has to eliminate everything — and correcting one word
  ///    of several is a different, harder problem.
  ///  * **The first character must be right.** Candidates are bounded by the
  ///    same first-character range scan the index is built for, so `hanumam`
  ///    reaches `hanuman` but `januman` never will.
  ///
  /// Ranked by how many documents each candidate appears in, so the correction
  /// offered is the one most likely to have been meant — not merely the first
  /// one the dictionary happens to hold.
  Future<List<String>> spellingSuggestions(String query, {int limit = 3}) async {
    final words = _queryWords(query);
    if (words.length != 1) return const [];

    // The primary folded form. Comparing folded-to-folded matters: the stored
    // tokens are folded, so an unfolded query word would differ from its own
    // spelling and every distance would come out one too high.
    final w = words.first.first;
    if (w.length < 3) return const [];

    try {
      final rows = await _db.rawQuery('''
        SELECT t.token AS token, COUNT(k.doc_id) AS n
        FROM gyan.search_terms t
        JOIN gyan.search_tokens k ON k.term_id = t.id
        WHERE t.token >= ? AND t.token < ?
          AND LENGTH(t.token) BETWEEN ? AND ?
        GROUP BY t.token
      ''', [w[0], '${w[0]}\u{10FFFF}', w.length - 1, w.length + 1]);

      final scored = <(String, int)>[];
      for (final r in rows) {
        final token = r['token'] as String;
        // Cannot happen while this is only called after a miss — a term in the
        // dictionary always has at least one posting — but a suggestion
        // identical to the query would read as the app malfunctioning.
        if (token == w) continue;
        if (_within1Edit(token, w)) scored.add((token, r['n'] as int));
      }
      scored.sort((a, b) => b.$2.compareTo(a.$2));
      return [for (final s in scored.take(limit)) s.$1];
    } catch (e) {
      debugPrint('SearchRepository: spellingSuggestions failed ($e)');
      return const [];
    }
  }

  /// True when [a] becomes [b] under at most one insertion, deletion or
  /// substitution. Bounded rather than a full Levenshtein table, because the
  /// only distance ever asked about is one — and this runs over several hundred
  /// candidates while someone is still typing.
  ///
  /// Compares UTF-16 code units, so a Devanagari vowel sign counts as its own
  /// edit. That is the right answer for a typo (a dropped मात्रा is a dropped
  /// keystroke) and the wrong one for a linguist.
  static bool _within1Edit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;

    if (a.length == b.length) {
      var diffs = 0;
      for (var i = 0; i < a.length; i++) {
        if (a.codeUnitAt(i) != b.codeUnitAt(i) && ++diffs > 1) return false;
      }
      return true;
    }

    // Lengths differ by one, so the longer must be the shorter with a single
    // character inserted somewhere. Walk both, allowing one skip.
    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    var i = 0, j = 0;
    var skipped = false;
    while (i < shorter.length && j < longer.length) {
      if (shorter.codeUnitAt(i) == longer.codeUnitAt(j)) {
        i++;
        j++;
      } else {
        if (skipped) return false;
        skipped = true;
        j++;
      }
    }
    return true;
  }

  /// Folded variants per query word, dropping words that fold to nothing.
  List<List<String>> _queryWords(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final out = <List<String>>[];
    for (final raw in trimmed.split(RegExp(r'\s+'))) {
      final variants = foldVariants(raw).where((v) => v.length >= 2).toList();
      if (variants.isNotEmpty) out.add(variants);
    }
    return out;
  }
}
