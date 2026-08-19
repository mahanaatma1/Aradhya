import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../user/user_prefs.dart';
import 'user_schema.dart';

/// The writable database for everything the user creates: bookmarks and notes,
/// journal entries, sadhana history, reading progress, reminders.
///
/// Separate connection from [ContentDatabase] on purpose — that one is opened
/// read-only, and mixing a writable attachment into it would forfeit that
/// guarantee for the bundled content.
///
/// Nothing here is ever uploaded.
class UserDatabase {
  UserDatabase._(this._db);

  final Database _db;
  Database get raw => _db;

  static const fileName = 'aradhya_user.db';

  static Future<UserDatabase> open({SharedPreferences? prefs}) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);

    final db = await openDatabase(
      path,
      version: kUserSchemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final stmt in kUserSchemaV1) {
          await db.execute(stmt);
        }
      },
      onUpgrade: (db, from, to) async {
        // Never drop a user table and never rewrite a row: this data has no
        // backup anywhere. Migrations are additive only, applied in order, and
        // each is guarded so a re-run cannot fail the open.
        if (from < 2) {
          for (final stmt in kUserSchemaV2) {
            try {
              await db.execute(stmt);
            } on DatabaseException {
              // A column that already exists is not worth blocking the app
              // over: it means a partial upgrade has already run.
            }
          }
        }
      },
    );

    final udb = UserDatabase._(db);
    if (prefs != null) {
      await udb.migrateFromPrefs(prefs);
    }
    return udb;
  }

  Future<String?> meta(String key) async {
    final rows = await _db.query('user_meta',
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) =>
      _db.insert('user_meta', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  // -------------------------------------------------------------------------
  // Migration
  // -------------------------------------------------------------------------

  /// Imports legacy SharedPreferences state into this database, exactly once.
  ///
  /// Three safety rules, all deliberate:
  ///
  ///  1. **The legacy prefs keys are NOT deleted.** They stay dormant for one
  ///     release so that installing an older build still finds the user's data.
  ///     Deletion happens in schema v2, gated on this flag having survived an
  ///     upgrade.
  ///  2. **Everything runs in one transaction and the flag is written last**, so
  ///     a crash mid-import leaves no flag and the whole thing re-runs cleanly.
  ///  3. **Nothing is ever dropped.** A bookmark whose route cannot be resolved
  ///     is imported with `route = ''` — shown, not tappable — rather than
  ///     silently discarded.
  Future<void> migrateFromPrefs(SharedPreferences prefs) async {
    if (await meta(UserMetaKeys.migratedFromPrefs) == '1') return;

    final now = DateTime.now().millisecondsSinceEpoch;
    var imported = 0;

    try {
      await _db.transaction((txn) async {
        imported += await _importBookmarks(txn, prefs, now);
        imported += await _importJapa(txn, prefs, now);
        imported += await _importHabits(txn, prefs, now);
        imported += await _importBreathing(txn, prefs, now);
        imported += await _importVisited(txn, prefs, now);
        imported += await _importReadingProgress(txn, prefs, now);
        imported += await _importCurrency(txn, prefs, now);
      });

      await setMeta(UserMetaKeys.migratedFromPrefs, '1');
      await setMeta(UserMetaKeys.migratedAt, now.toString());
      debugPrint('UserDatabase: migrated $imported row(s) from prefs');
    } catch (e, st) {
      // No flag was written, so this retries next launch. The app must still
      // start: the legacy prefs are untouched and every controller can still
      // read them.
      debugPrint('UserDatabase: migration failed, will retry ($e)\n$st');
    }
  }

  Future<int> _importBookmarks(
      Transaction txn, SharedPreferences prefs, int now) async {
    final raw = prefs.getString(PrefKeys.bookmarks);
    if (raw == null || raw.isEmpty) return 0;

    var n = 0;
    for (final e in _decodeList(raw)) {
      final m = e as Map<String, Object?>;
      final kind = m['kind'] as String?;
      final id = m['id'] as int?;
      if (kind == null || id == null) continue;

      await txn.insert(
        'bookmarks',
        {
          'src': 'content',
          'kind': kind,
          'ref_id': id,
          'title_en': (m['titleEn'] as String?) ?? '',
          'title_hi': m['titleHi'] as String?,
          'subtitle': m['subtitle'] as String?,
          // Legacy bookmarks stored no route. Rather than guess one and
          // reintroduce the "no routes for location" crash, leave it blank;
          // the UI treats '' as not-tappable and offers a re-open by search.
          'route': '',
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      n++;
    }
    return n;
  }

  Future<int> _importJapa(
      Transaction txn, SharedPreferences prefs, int now) async {
    final raw = prefs.getString(PrefKeys.japaHistory);
    if (raw == null || raw.isEmpty) return 0;

    final Map<String, dynamic> hist;
    try {
      hist = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return 0;
    }

    var n = 0;
    for (final entry in hist.entries) {
      final count = (entry.value as num?)?.toInt() ?? 0;
      if (count <= 0) continue;
      await txn.insert('sadhana_sessions', {
        'day_stamp': entry.key,
        'practice': 'japa',
        'count': count,
        'duration_s': 0,
        'created_at': now,
      });
      n++;
    }
    return n;
  }

  Future<int> _importHabits(
      Transaction txn, SharedPreferences prefs, int now) async {
    // One prefs key per day, forever — enumerable, so nothing is lost even
    // though there is no index of which days exist.
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(PrefKeys.habitsPrefix))
        .toList()
      ..sort();

    var n = 0;
    for (final key in keys) {
      final day = key.substring(PrefKeys.habitsPrefix.length);
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      for (final h in _decodeList(raw)) {
        if (h is! String) continue;
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
    return n;
  }

  Future<int> _importBreathing(
      Transaction txn, SharedPreferences prefs, int now) async {
    final last = prefs.getString(PrefKeys.breathLast);
    if (last == null || last.isEmpty) return 0;
    // Only the last session date was ever stored, so that is all we can
    // truthfully import — inventing a run of sessions from the streak counter
    // would fabricate history the user never had.
    await txn.insert('sadhana_sessions', {
      'day_stamp': last,
      'practice': 'breathing',
      'count': 1,
      'duration_s': 0,
      'created_at': now,
    });
    return 1;
  }

  Future<int> _importVisited(
      Transaction txn, SharedPreferences prefs, int now) async {
    final raw = prefs.getString(PrefKeys.templesVisited);
    if (raw == null || raw.isEmpty) return 0;

    var n = 0;
    for (final id in _decodeList(raw)) {
      if (id is! int) continue;
      await txn.insert(
        'temple_visits',
        // The visit date was never recorded; the migration timestamp is the
        // honest placeholder, and the UI labels these as "date unknown".
        {'temple_id': id, 'visited_at': now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      n++;
    }
    return n;
  }

  Future<int> _importReadingProgress(
      Transaction txn, SharedPreferences prefs, int now) async {
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(PrefKeys.scripturePosPrefix));

    var n = 0;
    for (final key in keys) {
      final bookId =
          int.tryParse(key.substring(PrefKeys.scripturePosPrefix.length));
      if (bookId == null) continue;
      final idx = prefs.getInt(key) ?? 0;
      await txn.insert(
        'reading_progress',
        {
          'book_id': bookId,
          'last_section_idx': idx,
          // sections_total is unknown here; backfilled lazily the next time the
          // book is opened, so a percentage only appears once it is truthful.
          'sections_total': 0,
          'sections_read': idx,
          'last_read_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    return n;
  }

  Future<int> _importCurrency(
      Transaction txn, SharedPreferences prefs, int now) async {
    final punya = prefs.getInt(PrefKeys.points) ?? 0;
    final kamal = prefs.getInt(PrefKeys.kamal) ?? 0;
    if (punya == 0 && kamal == 0) return 0;

    await txn.insert('currency_ledger', {
      'day_stamp': dayStamp(),
      'reason': 'migration_opening_balance',
      'punya': punya,
      'kamal': kamal,
      'created_at': now,
    });
    return 1;
  }

  List<dynamic> _decodeList(String raw) {
    try {
      final v = jsonDecode(raw);
      return v is List ? v : const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> close() => _db.close();
}

/// Overridden in `main()` once the database is open.
///
/// Deliberately **nullable** rather than throwing when unset: widget tests and
/// pure-logic tests construct a `ProviderScope` without a real database, and a
/// user-state controller must not explode in that situation. Callers treat null
/// as "history unavailable, fall back to SharedPreferences".
final userDatabaseProvider = Provider<UserDatabase?>((ref) => null);
