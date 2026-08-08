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
