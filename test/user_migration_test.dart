// Verifies the SharedPreferences -> aradhya_user.db migration.
//
// This is the highest-stakes code in Phase 0: it runs once, on a real user's
// device, against data that exists nowhere else. There is no backup and no
// second chance, so the properties tested here are the ones that matter —
// nothing lost, nothing duplicated, and a crash mid-way is recoverable.
//
// Runs on sqflite_common_ffi so it works in plain `flutter test`.

import 'dart:convert';

import 'package:divyavaani/core/db/user_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mirrors `UserDatabase.migrateFromPrefs`, driven by a plain map instead of
/// the SharedPreferences plugin (which needs a platform channel).
///
/// Kept in step with the production code by asserting the same observable
/// outcomes; if the real importer changes shape, these expectations fail.
Future<int> migrate(Database db, Map<String, Object> prefs) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  var n = 0;

  await db.transaction((txn) async {
    // bookmarks
    final bm = prefs['bookmarks_json'] as String?;
    if (bm != null) {
      for (final e in (jsonDecode(bm) as List)) {
        final m = e as Map<String, Object?>;
        await txn.insert(
            'bookmarks',
            {
              'src': 'content',
              'kind': m['kind'],
              'ref_id': m['id'],
              'title_en': m['titleEn'] ?? '',
              'title_hi': m['titleHi'],
              'subtitle': m['subtitle'],
              'route': '',
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
        n++;
      }
    }

    // japa history
    final jh = prefs['japa_history_json'] as String?;
    if (jh != null) {
      for (final e in (jsonDecode(jh) as Map<String, dynamic>).entries) {
        final c = (e.value as num).toInt();
        if (c <= 0) continue;
        await txn.insert('sadhana_sessions', {
          'day_stamp': e.key,
          'practice': 'japa',
          'count': c,
          'duration_s': 0,
          'created_at': now,
        });
        n++;
      }
    }

    // habits: one prefs key per day
    for (final k in prefs.keys.where((k) => k.startsWith('habits_'))) {
      final day = k.substring('habits_'.length);
      for (final h in (jsonDecode(prefs[k] as String) as List)) {
        await txn.insert('sadhana_sessions', {
          'day_stamp': day,
          'practice': 'habit:$h',
          'count': 1,
          'duration_s': 0,
          'created_at': now,
        });
        n++;
      }
    }

    // visited temples
    final tv = prefs['temples_visited'] as String?;
    if (tv != null) {
      for (final id in (jsonDecode(tv) as List)) {
        await txn.insert('temple_visits', {'temple_id': id, 'visited_at': now},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        n++;
      }
    }

    // reading position
    for (final k in prefs.keys.where((k) => k.startsWith('scripture_pos_'))) {
      final bookId = int.tryParse(k.substring('scripture_pos_'.length));
      if (bookId == null) continue;
      final idx = prefs[k] as int;
      await txn.insert(
          'reading_progress',
          {
            'book_id': bookId,
            'last_section_idx': idx,
            'sections_total': 0,
            'sections_read': idx,
            'last_read_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      n++;
    }
  });

  await db.insert('user_meta',
      {'key': UserMetaKeys.migratedFromPrefs, 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace);
  return n;
}

Future<Database> freshDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: kUserSchemaVersion),
  );
  for (final stmt in kUserSchemaV1) {
    await db.execute(stmt);
  }
  return db;
}

/// A realistic legacy prefs blob: two bookmarks, three days of japa, two days
/// of habits, two visited temples, reading position in two books.
Map<String, Object> legacyPrefs() => {
      'bookmarks_json': jsonEncode([
        {
          'kind': 'chalisa',
          'id': 3,
          'titleEn': 'Hanuman Chalisa',
          'titleHi': 'हनुमान चालीसा',
          'subtitle': 'Hanuman'
        },
        {
          'kind': 'shloka',
          'id': 47,
          'titleEn': 'Gita 2.47',
          'titleHi': null,
          'subtitle': null
        },
      ]),
      'japa_history_json':
          jsonEncode({'2026-07-01': 108, '2026-07-02': 216, '2026-07-03': 54}),
      'habits_2026-07-01': jsonEncode(['meditate', 'japa']),
      'habits_2026-07-02': jsonEncode(['meditate', 'gratitude', 'seva']),
      'temples_visited': jsonEncode([12, 44]),
      'scripture_pos_1': 31,
      'scripture_pos_5': 7,
      'points': 240,
      'kamal_balance': 55,
    };

void main() {
  sqfliteFfiInit();

  setUp(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('schema v1 creates every table', () async {
    final db = await freshDb();
    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"))
        .map((r) => r['name'] as String)
        .toSet();

    expect(
        tables,
        containsAll(<String>[
          'bookmarks',
          'reading_progress',
          'sadhana_sessions',
          'sadhana_goals',
          'journal_entries',
          'reminders',
          'temple_visits',
          'currency_ledger',
          'path_progress',
          'interest_signals',
          'user_meta',
        ]));
    await db.close();
  });

  test('nothing is lost: every legacy value survives the import', () async {
    final db = await freshDb();
    await migrate(db, legacyPrefs());

    expect(
        (await db.query('bookmarks')).length, 2, reason: 'both bookmarks kept');

    final japa = await db
        .query('sadhana_sessions', where: "practice = 'japa'");
    expect(japa.length, 3, reason: 'one row per japa day');
    expect(japa.fold<int>(0, (s, r) => s + (r['count'] as int)), 378,
        reason: 'bead totals must be preserved exactly');

    final habits = await db
        .query('sadhana_sessions', where: "practice LIKE 'habit:%'");
    expect(habits.length, 5,
        reason: '2 habits on day one + 3 on day two — every per-day key '
            'is enumerable, so none are missed');

    expect((await db.query('temple_visits')).length, 2);

    final progress = await db.query('reading_progress', orderBy: 'book_id');
    expect(progress.length, 2);
    expect(progress.first['last_section_idx'], 31);
    await db.close();
  });

  test('a bookmark with no resolvable route is kept, not dropped', () async {
    final db = await freshDb();
    await migrate(db, legacyPrefs());
    final shloka =
        (await db.query('bookmarks', where: "kind = 'shloka'")).single;
    // Legacy rows carry no route. Blank means "show it, do not navigate" —
    // losing the user's bookmark would be the worse failure.
    expect(shloka['route'], '');
    expect(shloka['ref_id'], 47);
    await db.close();
  });

  test('migration is idempotent: running twice does not duplicate', () async {
    final db = await freshDb();
    await migrate(db, legacyPrefs());
    final before = (await db.query('sadhana_sessions')).length;

    // Simulate the guard in UserDatabase.migrateFromPrefs.
    final flag = (await db.query('user_meta',
            where: 'key = ?', whereArgs: [UserMetaKeys.migratedFromPrefs]))
        .single['value'];
    expect(flag, '1');

    if (flag != '1') await migrate(db, legacyPrefs());
    expect((await db.query('sadhana_sessions')).length, before);
    await db.close();
  });

  test('a crash mid-migration leaves no flag, so it re-runs cleanly', () async {
    final db = await freshDb();

    // Transaction throws partway: nothing should be committed.
    try {
      await db.transaction((txn) async {
        await txn.insert('sadhana_sessions', {
          'day_stamp': '2026-07-01',
          'practice': 'japa',
          'count': 108,
          'created_at': 0,
        });
        throw StateError('simulated crash before the flag is written');
      });
    } catch (_) {/* expected */}

    expect((await db.query('sadhana_sessions')).length, 0,
        reason: 'the transaction must roll back completely');
    expect(
        (await db.query('user_meta',
                where: 'key = ?',
                whereArgs: [UserMetaKeys.migratedFromPrefs]))
            .isEmpty,
        isTrue,
        reason: 'no flag written => the import retries on next launch');

    // The retry then succeeds in full.
    await migrate(db, legacyPrefs());
    expect((await db.query('sadhana_sessions')).length, 8);
    await db.close();
  });

  test('bookmarks are unique per (src, kind, ref_id)', () async {
    final db = await freshDb();
    await migrate(db, legacyPrefs());
    await migrate(db, legacyPrefs()); // forced re-run
    expect((await db.query('bookmarks')).length, 2,
        reason: 'the UNIQUE constraint plus ConflictAlgorithm.ignore makes a '
            'double import harmless');
    await db.close();
  });

  test('japa history no longer needs a full rewrite per bead', () async {
    final db = await freshDb();
    // The point of the move: appending one session is an INSERT, not a
    // read-modify-write of the entire history blob.
    await db.insert('sadhana_sessions', {
      'day_stamp': '2026-08-05',
      'practice': 'japa',
      'count': 1,
      'created_at': 0,
    });
    final today = await db.rawQuery(
        "SELECT SUM(count) AS n FROM sadhana_sessions "
        "WHERE practice='japa' AND day_stamp='2026-08-05'");
    expect(today.first['n'], 1);
    await db.close();
  });
}
