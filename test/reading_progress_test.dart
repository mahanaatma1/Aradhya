// Verifies the reader -> database write path for reading progress.
//
// The interesting properties are not "does it insert" but the ones that are
// easy to get subtly wrong and hard to notice:
//
//   * re-opening a book must not create a second row
//   * paging BACKWARDS must not reduce how much has been read
//   * a percentage must never appear before sections_total is known
//   * finishing a book must stamp completed_at exactly once
//
// Runs the same SQL that ReadingProgressController issues, against the real
// schema, on sqflite_common_ffi.

import 'dart:io';

import 'package:divyavaani/core/db/user_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mirrors `ReadingProgressController.recordSection`.
Future<void> record(
  Database db, {
  required int bookId,
  int? scriptureId,
  required int sectionIndex,
  required int sectionsTotal,
  DateTime? at,
}) async {
  final now = (at ?? DateTime.now()).millisecondsSinceEpoch;

  final existing = await db.query('reading_progress',
      where: 'book_id = ?', whereArgs: [bookId], limit: 1);
  final prev = existing.isEmpty ? null : existing.first;

  final prevRead = (prev?['sections_read'] as int?) ?? 0;
  // High-water mark: paging back through a chapter you have already read must
  // not undo the progress.
  final read = sectionIndex + 1 > prevRead ? sectionIndex + 1 : prevRead;

  final total =
      sectionsTotal > 0 ? sectionsTotal : ((prev?['sections_total'] as int?) ?? 0);
  final completed = (prev?['completed_at'] as int?) ??
      (total > 0 && read >= total ? now : null);

  await db.insert(
    'reading_progress',
    {
      'book_id': bookId,
      'scripture_id': scriptureId ?? prev?['scripture_id'],
      'last_section_idx': sectionIndex,
      'sections_total': total,
      'sections_read': read,
      'last_read_at': now,
      'completed_at': completed,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<Map<String, Object?>?> progressFor(Database db, int bookId) async {
  final rows = await db.query('reading_progress',
      where: 'book_id = ?', whereArgs: [bookId], limit: 1);
  return rows.isEmpty ? null : rows.first;
}

int percentOf(Map<String, Object?> row) {
  final total = (row['sections_total'] as int?) ?? 0;
  final read = (row['sections_read'] as int?) ?? 0;
  if (total <= 0) return 0;
  return ((read / total).clamp(0.0, 1.0) * 100).round();
}

var _dbSeq = 0;

/// A genuinely fresh database per test.
///
/// `inMemoryDatabasePath` is shared by the ffi factory, so successive opens
/// return the SAME database and the schema is applied twice — every test after
/// the first then fails with "table bookmarks already exists".
Future<Database> freshDb() async {
  final dir = await Directory.systemTemp.createTemp('aradhya-progress-');
  final path = '${dir.path}/u${_dbSeq++}.db';
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(version: kUserSchemaVersion),
  );
  for (final stmt in kUserSchemaV1) {
    await db.execute(stmt);
  }
  return db;
}

void main() {
  sqfliteFfiInit();

  setUp(() => databaseFactory = databaseFactoryFfi);

  test('the first open records a position', () async {
    final db = await freshDb();
    await record(db, bookId: 1, scriptureId: 1, sectionIndex: 0, sectionsTotal: 47);

    final p = await progressFor(db, 1);
    expect(p, isNotNull);
    expect(p!['last_section_idx'], 0);
    expect(p['sections_total'], 47);
    expect(p['sections_read'], 1);
    expect(p['completed_at'], isNull);
    await db.close();
  });

  test('re-opening the same book updates, never duplicates', () async {
    final db = await freshDb();
    for (final i in [0, 5, 12, 30]) {
      await record(db,
          bookId: 1, scriptureId: 1, sectionIndex: i, sectionsTotal: 47);
    }
    final rows = await db.query('reading_progress', where: 'book_id = 1');
    expect(rows.length, 1,
        reason: 'book_id is the primary key — a second row would make '
            '"continue reading" ambiguous');
    expect(rows.first['last_section_idx'], 30);
    await db.close();
  });

  test('paging backwards keeps the high-water mark', () async {
    final db = await freshDb();
    await record(db, bookId: 2, sectionIndex: 20, sectionsTotal: 30);
    expect((await progressFor(db, 2))!['sections_read'], 21);

    // Re-reading an earlier verse should move the cursor but not the progress.
    await record(db, bookId: 2, sectionIndex: 3, sectionsTotal: 30);
    final p = await progressFor(db, 2);
    expect(p!['last_section_idx'], 3, reason: 'the cursor follows the reader');
    expect(p['sections_read'], 21,
        reason: 'progress must not go backwards when re-reading');
    await db.close();
  });

  test('no percentage is shown until the total is known', () async {
    final db = await freshDb();
    // A migrated row has last_section_idx but sections_total = 0, because the
    // old prefs scheme never stored a total.
    await db.insert('reading_progress', {
      'book_id': 9,
      'last_section_idx': 31,
      'sections_total': 0,
      'sections_read': 31,
      'last_read_at': 0,
    });
    expect(percentOf((await progressFor(db, 9))!), 0,
        reason: 'showing "3100%" or a fake number is worse than showing none');

    // Opening the book backfills the total, and only then is a percent real.
    await record(db, bookId: 9, sectionIndex: 31, sectionsTotal: 62);
    expect(percentOf((await progressFor(db, 9))!), 52);
    await db.close();
  });

  test('reaching the last verse marks the book complete, once', () async {
    final db = await freshDb();
    await record(db, bookId: 3, sectionIndex: 45, sectionsTotal: 47);
    expect((await progressFor(db, 3))!['completed_at'], isNull);

    await record(db,
        bookId: 3,
        sectionIndex: 46,
        sectionsTotal: 47,
        at: DateTime(2026, 8, 8, 10));
    final done = await progressFor(db, 3);
    final firstStamp = done!['completed_at'] as int?;
    expect(firstStamp, isNotNull);
    expect(percentOf(done), 100);

    // Re-reading a finished book must not move the completion date.
    await record(db,
        bookId: 3,
        sectionIndex: 2,
        sectionsTotal: 47,
        at: DateTime(2026, 12, 1));
    expect((await progressFor(db, 3))!['completed_at'], firstStamp,
        reason: 'the date a book was finished should not change');
    await db.close();
  });

  test('several books are tracked independently', () async {
    final db = await freshDb();
    await record(db, bookId: 1, scriptureId: 1, sectionIndex: 10, sectionsTotal: 47);
    await record(db, bookId: 5, scriptureId: 1, sectionIndex: 2, sectionsTotal: 20);
    await record(db, bookId: 88, scriptureId: 3, sectionIndex: 0, sectionsTotal: 77);

    final all = await db.query('reading_progress', orderBy: 'book_id');
    expect(all.length, 3);
    expect(percentOf(all[0]), 23);
    expect(percentOf(all[1]), 15);
    expect(all[2]['scripture_id'], 3);
    await db.close();
  });

  test('the most recent book is identifiable for "Continue reading"', () async {
    final db = await freshDb();
    await record(db,
        bookId: 1, sectionIndex: 10, sectionsTotal: 47, at: DateTime(2026, 8, 1));
    await record(db,
        bookId: 5, sectionIndex: 2, sectionsTotal: 20, at: DateTime(2026, 8, 7));
    await record(db,
        bookId: 9, sectionIndex: 1, sectionsTotal: 30, at: DateTime(2026, 8, 3));

    final recent = await db.query('reading_progress',
        orderBy: 'last_read_at DESC', limit: 1);
    expect(recent.first['book_id'], 5);
    await db.close();
  });
}
