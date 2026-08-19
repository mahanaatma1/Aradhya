import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError, debugPrint;
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the read-only content databases that ship bundled in the app.
///
/// Assets cannot be opened by sqflite directly, so on first launch each one is
/// copied into the app's documents directory and then opened read-only. Each
/// database carries its own `.version` marker file, so bumping one does **not**
/// force a re-copy of the other — which matters because `content.sqlite` is
/// ~38 MB and `gyan.sqlite` is patched far more often.
///
/// Two databases, one connection:
///   * `main`  — `content.sqlite`, the legacy corpus (scriptures, temples,
///                mantras, quiz…). Never modified.
///   * `gyan`  — `gyan.sqlite`, all new licence-clean content plus the search
///                index and the related-content edges. ATTACHed, so a single
///                statement can join across both:
///                `SELECT … FROM gyan.search_docs d JOIN main.temples t …`
///
/// User-authored data does **not** live here — it belongs in the writable
/// `aradhya_user.db` on its own connection.
class ContentDatabase {
  ContentDatabase._(this._db, {required this.gyanAttached});

  final Database _db;
  Database get raw => _db;

  /// False when `gyan.sqlite` could not be copied or attached. Every Gyan
  /// feature must degrade gracefully rather than crash: the legacy app is
  /// fully functional without it.
  final bool gyanAttached;

  static const _contentAsset = 'assets/db/content.sqlite';
  static const _contentFile = 'content.sqlite';

  static const _gyanAsset = 'assets/db/gyan.sqlite';
  static const _gyanFile = 'gyan.sqlite';

  /// Content version of the bundled `content.sqlite`.
  /// MUST equal that DB's `meta.content_version` — asserted by
  /// test/db_version_test.dart.
  static const assetVersion = '0.4.1-devfixture-native';

  /// Version of the bundled `gyan.sqlite`. Rewritten automatically by
  /// `content/tools/build.py`; do not edit by hand, and keep the trailing
  /// marker comment intact — the build script matches on it.
  static const gyanAssetVersion = '1.0.0+20260819.cfee82c'; // BUILD_STAMP:gyan

  static Future<ContentDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();

    final contentPath = await _materialise(
      dir: dir.path,
      asset: _contentAsset,
      fileName: _contentFile,
      version: assetVersion,
    );

    final db = await openReadOnlyDatabase(contentPath);

    // Gyan is additive. If anything about it fails, log and carry on with the
    // legacy corpus rather than taking the whole app down.
    var attached = false;
    try {
      final gyanPath = await _materialise(
        dir: dir.path,
        asset: _gyanAsset,
        fileName: _gyanFile,
        version: gyanAssetVersion,
      );
      await db.execute('ATTACH DATABASE ? AS gyan', [gyanPath]);
      attached = true;
    } catch (e) {
      debugPrint('ContentDatabase: gyan.sqlite unavailable ($e)');
    }

    return ContentDatabase._(db, gyanAttached: attached);
  }

  /// Copies a bundled asset into [dir] if it is missing or its version marker
  /// does not match, and returns the on-disk path.
  static Future<String> _materialise({
    required String dir,
    required String asset,
    required String fileName,
    required String version,
  }) async {
    final dest = p.join(dir, fileName);
    final file = File(dest);
    final marker = File('$dest.version');

    final cached = await marker.exists() ? await marker.readAsString() : '';

    if (!await file.exists() || cached != version) {
      // Prefer a gzipped asset when one is bundled. SQLite files compress
      // about 4:1, which takes 55 MB of database out of the download without
      // changing anything on disk after the copy. Falls back to the plain
      // asset so a build that has not been compressed still works.
      Uint8List bytes;
      try {
        final gz = await rootBundle.load('$asset.gz');
        bytes = Uint8List.fromList(gzip.decode(
            gz.buffer.asUint8List(gz.offsetInBytes, gz.lengthInBytes)));
      } on FlutterError {
        final ByteData data = await rootBundle.load(asset);
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
      await file.writeAsBytes(bytes, flush: true);
      // Written last: a crash between the two leaves the marker stale and the
      // copy simply runs again, rather than trusting a half-written file.
      await marker.writeAsString(version);
    }
    return dest;
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) {
    return _db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// Reads a `meta` key from either database. Returns null when the requested
  /// database is not attached, so callers can degrade instead of throwing.
  Future<String?> metaValue(String key, {bool gyan = false}) async {
    if (gyan && !gyanAttached) return null;
    final table = gyan ? 'gyan.meta' : 'main.meta';
    final rows = await _db.rawQuery(
        'SELECT value FROM $table WHERE key = ? LIMIT 1', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// True when `gyan.sqlite`'s search index was built against a different
  /// `content.sqlite` than the one bundled here. Legacy search results may then
  /// deep-link to the wrong rows, so the UI shows a warning — it never crashes.
  Future<bool> isSearchIndexStale() async {
    if (!gyanAttached) return false;
    final indexed = await metaValue('indexed_content_version', gyan: true);
    if (indexed == null || indexed.isEmpty) return false;
    final actual = await metaValue('content_version');
    return actual != null && actual.isNotEmpty && indexed != actual;
  }
}
