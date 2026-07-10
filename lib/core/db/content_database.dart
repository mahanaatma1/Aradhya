import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opens the read-only content database that ships bundled in the app.
///
/// The asset cannot be opened directly, so on first launch we copy it into the
/// app's documents directory, then open it read-only. When the bundled content
/// version changes we overwrite the cached copy.
class ContentDatabase {
  ContentDatabase._(this._db);

  final Database _db;
  Database get raw => _db;

  static const _assetPath = 'assets/db/content.sqlite';
  static const _fileName = 'content.sqlite';

  /// Bump this whenever the bundled `content.sqlite` changes so the cached
  /// copy on device is refreshed. Mirrors `meta.content_version`.
  static const assetVersion = '0.4.2-devfixture-native';

  static Future<ContentDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, _fileName);
    final file = File(dest);
    final marker = File('$dest.version');

    final cachedVersion =
        await marker.exists() ? await marker.readAsString() : '';

    // (Re)copy the bundled asset if missing or the version changed.
    if (!await file.exists() || cachedVersion != assetVersion) {
      final ByteData data = await rootBundle.load(_assetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
      await marker.writeAsString(assetVersion);
    }

    final db = await openReadOnlyDatabase(dest);
    return ContentDatabase._(db);
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
}
