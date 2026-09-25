import '../../core/db/content_database.dart';
import 'scripture_models.dart';

/// Read-only data access for the scriptures feature.
class ScriptureRepository {
  final ContentDatabase db;
  const ScriptureRepository(this.db);

  Future<List<Scripture>> scriptures() async {
    final rows = await db.query('scriptures', orderBy: 'order_no, id');
    return rows.map(Scripture.fromRow).toList();
  }

  Future<Scripture?> scriptureBySlug(String slug) async {
    final rows =
        await db.query('scriptures', where: 'slug = ?', whereArgs: [slug], limit: 1);
    return rows.isEmpty ? null : Scripture.fromRow(rows.first);
  }

  Future<List<ScriptureBook>> books(int scriptureId) async {
    final rows = await db.query(
      'scripture_books',
      where: 'scripture_id = ?',
      whereArgs: [scriptureId],
      orderBy: 'order_no, id',
    );
    return rows.map(ScriptureBook.fromRow).toList();
  }

  Future<ScriptureBook?> book(int bookId) async {
    final rows = await db.query('scripture_books',
        where: 'id = ?', whereArgs: [bookId], limit: 1);
    return rows.isEmpty ? null : ScriptureBook.fromRow(rows.first);
  }

  /// RG-01: a verse we have rewritten reads from `gyan.scripture_overrides`;
  /// the fixture's translation and commentary show only where no rewrite
  /// exists yet. Sanskrit and transliteration always come from the fixture.
  String get _sectionSelect => db.gyanAttached
      ? '''
        SELECT s.id, s.book_id, s.number, s.sanskrit, s.transliteration,
               COALESCE(o.body_en, s.body_en) AS body_en,
               COALESCE(o.body_hi, s.body_hi) AS body_hi,
               CASE WHEN o.section_id IS NULL THEN s.commentary_en
                    ELSE o.commentary_en END AS commentary_en,
               CASE WHEN o.section_id IS NULL THEN s.commentary_hi
                    ELSE o.commentary_hi END AS commentary_hi
        FROM scripture_sections s
        LEFT JOIN gyan.scripture_overrides o ON o.section_id = s.id'''
      : 'SELECT * FROM scripture_sections s';

  Future<List<ScriptureSection>> sections(int bookId) async {
    final rows = await db.raw.rawQuery(
      '$_sectionSelect WHERE s.book_id = ? ORDER BY s.order_no, s.id',
      [bookId],
    );
    return rows.map(ScriptureSection.fromRow).toList();
  }

  /// Number of verses/sections in a book (for pagination).
  Future<int> sectionCount(int bookId) async {
    final rows = await db.raw.rawQuery(
      'SELECT COUNT(*) AS c FROM scripture_sections WHERE book_id = ?',
      [bookId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// One page of sections, ordered, using SQL LIMIT/OFFSET so we never load a
  /// whole kanda (Ramayana books run to thousands of shlokas) into memory.
  Future<List<ScriptureSection>> sectionsPage(
    int bookId, {
    required int limit,
    required int offset,
  }) async {
    final rows = await db.raw.rawQuery(
      '$_sectionSelect WHERE s.book_id = ? ORDER BY s.order_no, s.id '
      'LIMIT ? OFFSET ?',
      [bookId, limit, offset],
    );
    return rows.map(ScriptureSection.fromRow).toList();
  }
}
