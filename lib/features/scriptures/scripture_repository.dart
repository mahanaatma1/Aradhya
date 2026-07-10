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

  Future<List<ScriptureSection>> sections(int bookId) async {
    final rows = await db.query(
      'scripture_sections',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'order_no, id',
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
    final rows = await db.raw.query(
      'scripture_sections',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'order_no, id',
      limit: limit,
      offset: offset,
    );
    return rows.map(ScriptureSection.fromRow).toList();
  }
}
