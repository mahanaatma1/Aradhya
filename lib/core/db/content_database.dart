import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError, debugPrint;
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../platform/platform_bridge.dart';

/// Thrown before a first-launch copy when the device cannot hold the
/// inflated database. Surfaced as a bilingual "not enough storage" screen.
class InsufficientStorageException implements Exception {
  final int needed;
  final int free;
  const InsufficientStorageException({required this.needed, required this.free});

  int get shortfallMb =>
      ((needed * 1.1 + 20 * 1024 * 1024 - free) / (1024 * 1024)).ceil();

  @override
  String toString() =>
      'InsufficientStorageException(need ${needed >> 20} MB, free ${free >> 20} MB)';
}

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
  static const gyanAssetVersion = '1.0.0+20260912.2861beb'; // BUILD_STAMP:gyan

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
      // sqflite's `openReadOnlyDatabase` is single-instance per path: if the
      // native connection for `contentPath` is still alive from a previous
      // `open()` (the app process survives across what looks like a fresh
      // launch — Android keeps it around unless force-stopped, and hot
      // restart during development does the same), this call returns that
      // *same* connection, which already has `gyan` attached. Attaching it
      // again throws "database gyan is already in use" and — because this
      // whole block is deliberately degrade-not-crash — every gyan-backed
      // feature (festivals, search, related content, the whole Gyan hub)
      // then silently goes empty with nothing in the UI explaining why.
      // Checking first makes re-opening idempotent instead of failing.
      final already = await db.rawQuery('PRAGMA database_list');
      final hasGyan =
          already.any((row) => (row['name'] as String?) == 'gyan');
      if (hasGyan) {
        attached = true;
      } else {
        final gyanPath = await _materialise(
          dir: dir.path,
          asset: _gyanAsset,
          fileName: _gyanFile,
          version: gyanAssetVersion,
        );
        await db.execute('ATTACH DATABASE ? AS gyan', [gyanPath]);
        attached = true;
      }
    } catch (e) {
      debugPrint('ContentDatabase: gyan.sqlite unavailable ($e)');
    }

    return ContentDatabase._(db, gyanAttached: attached);
  }

  /// Progress of the current first-launch copy, 0..1. Emits nothing when no
  /// copy is running; the splash shows a ring while it is.
  static Stream<double> get progress => _progress.stream;
  static final _progress = StreamController<double>.broadcast();

  /// Copies a bundled asset into [dir] if it is missing or its version marker
  /// does not match, and returns the on-disk path.
  ///
  /// The gzip is inflated in a worker isolate and streamed straight to disk,
  /// so the peak allocation is the compressed asset (~10 MB), not the 37 MB
  /// database. Free space is checked first; the file is written as `.part`
  /// and renamed, and the marker is written last, so an interrupted copy just
  /// runs again instead of trusting a half-written file.
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
    if (await file.exists() && cached == version) return dest;

    ByteData data;
    var gzipped = true;
    try {
      data = await rootBundle.load('$asset.gz');
    } on FlutterError {
      data = await rootBundle.load(asset);
      gzipped = false;
    }
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final inflated = gzipped ? gzipInflatedSize(bytes) : bytes.length;

    final free = await PlatformBridge.freeDiskBytes(dir);
    if (free != null && free < inflated * 1.1 + 20 * 1024 * 1024) {
      throw InsufficientStorageException(needed: inflated, free: free);
    }

    final part = File('$dest.part');
    if (await part.exists()) await part.delete();
    final transfer = TransferableTypedData.fromList([bytes]);
    _progress.add(0);
    final poll = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (await part.exists()) {
        _progress.add(((await part.length()) / inflated).clamp(0.0, 0.99));
      }
    });
    try {
      await Isolate.run(() => _inflateToFile(transfer, part.path, gzipped));
    } finally {
      poll.cancel();
    }
    await part.rename(dest);
    await marker.writeAsString(version);
    _progress.add(1);
    return dest;
  }

  static Future<void> _inflateToFile(
      TransferableTypedData transfer, String path, bool gzipped) async {
    final data = transfer.materialize().asUint8List();
    final sink = File(path).openWrite();
    if (!gzipped) {
      sink.add(data);
      await sink.close();
      return;
    }
    const chunk = 256 * 1024;
    final chunks = <List<int>>[
      for (var i = 0; i < data.length; i += chunk)
        Uint8List.sublistView(
            data, i, i + chunk > data.length ? data.length : i + chunk),
    ];
    await Stream<List<int>>.fromIterable(chunks)
        .transform(gzip.decoder)
        .pipe(sink);
  }

  /// The uncompressed size a gzip stream declares (ISIZE, last four bytes,
  /// little-endian; exact for anything under 4 GB).
  static int gzipInflatedSize(Uint8List gz) {
    if (gz.length < 4) return gz.length;
    final n = gz.length;
    return gz[n - 4] | (gz[n - 3] << 8) | (gz[n - 2] << 16) | (gz[n - 1] << 24);
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
