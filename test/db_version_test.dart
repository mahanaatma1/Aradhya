// Guards against the class of bug where a bundled database and the Dart const
// that gates its refresh drift apart.
//
// This is not hypothetical: `assetVersion` read '0.4.2-devfixture-native' while
// content.sqlite's meta said '0.4.0-devfixture-native'. The consequence is
// silent and nasty — the on-device copy is never refreshed after a content
// change, so users keep reading stale content with no error anywhere.
//
// Runs against the asset files directly (not through sqflite/Flutter), so it
// works in a plain `flutter test` with no device or plugin registration.

import 'dart:io';

import 'package:divyavaani/core/db/content_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal SQLite reader: pulls one value out of a `meta(key, value)` table
/// without a sqflite dependency.
///
/// Parsing enough of the file format to walk B-trees would be absurd here, so
/// this shells out to the `sqlite3` CLI when available and skips otherwise —
/// the check is valuable in CI and on dev machines, and a missing CLI must not
/// turn into a false failure.
String? _metaValue(String dbPath, String key) {
  final result = Process.runSync('sqlite3', [
    '-readonly',
    dbPath,
    "SELECT value FROM meta WHERE key='$key' LIMIT 1;",
  ]);
  if (result.exitCode != 0) return null;
  final out = (result.stdout as String).trim();
  return out.isEmpty ? null : out;
}

bool get _hasSqlite3 {
  try {
    return Process.runSync('sqlite3', ['-version']).exitCode == 0;
  } catch (_) {
    return false;
  }
}

void main() {
  group('bundled DB versions match their Dart constants', () {
    test('assets exist', () {
      expect(File('assets/db/content.sqlite').existsSync(), isTrue,
          reason: 'the legacy content database must be bundled');
      expect(File('assets/db/gyan.sqlite').existsSync(), isTrue,
          reason: 'run: py -m content.tools.build');
    });

    test('content.sqlite meta.content_version == ContentDatabase.assetVersion',
        () {
      if (!_hasSqlite3) {
        markTestSkipped('sqlite3 CLI not on PATH');
        return;
      }
      final actual = _metaValue('assets/db/content.sqlite', 'content_version');
      expect(actual, isNotNull,
          reason: 'content.sqlite has no meta.content_version row');
      expect(actual, ContentDatabase.assetVersion,
          reason: 'Version drift: the on-device copy would never be refreshed '
              'after a content change. Fix the const, or rebuild the DB.');
    });

    test('gyan.sqlite meta.content_version == ContentDatabase.gyanAssetVersion',
        () {
      if (!_hasSqlite3) {
        markTestSkipped('sqlite3 CLI not on PATH');
        return;
      }
      final actual = _metaValue('assets/db/gyan.sqlite', 'content_version');
      expect(actual, isNotNull,
          reason: 'gyan.sqlite has no meta.content_version row');
      expect(actual, ContentDatabase.gyanAssetVersion,
          reason: 'build.py stamps both the DB and the Dart const; they are '
              'out of sync. Re-run: py -m content.tools.build');
    });

    test('gyan.sqlite is not left in WAL mode', () {
      if (!_hasSqlite3) {
        markTestSkipped('sqlite3 CLI not on PATH');
        return;
      }
      // A WAL database cannot be opened read-only on device without write
      // access to its -shm sidecar, so the app would fail to open it at all.
      final mode = Process.runSync('sqlite3', [
        '-readonly',
        'assets/db/gyan.sqlite',
        'PRAGMA journal_mode;',
      ]);
      expect((mode.stdout as String).trim().toLowerCase(), isNot('wal'),
          reason: 'build.py must finish with PRAGMA journal_mode=DELETE');
    });

    test('the search index was built against the bundled content.sqlite', () {
      if (!_hasSqlite3) {
        markTestSkipped('sqlite3 CLI not on PATH');
        return;
      }
      final indexed =
          _metaValue('assets/db/gyan.sqlite', 'indexed_content_version');
      if (indexed == null || indexed.isEmpty) {
        markTestSkipped('no search index built yet');
        return;
      }
      final actual = _metaValue('assets/db/content.sqlite', 'content_version');
      expect(indexed, actual,
          reason: 'Stale index (Risk 2): legacy search results would deep-link '
              'to wrong or missing rows. Rebuild gyan.sqlite.');
    });
  });
}
