import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Guards against content silently disappearing from the shipped database.
///
/// This exists because it already happened: `extract.py --promote` regenerates
/// core.jsonl from content/curation/, and prose that had been written directly
/// into core.jsonl was wiped by a promote run done for an unrelated reason.
/// Twenty-two enriched entities dropped to five and nothing failed -- the build
/// was green, validate was clean, and the app just quietly got thinner.
///
/// Floors, not exact counts, so adding content never breaks the test.
void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    final path = '${Directory.current.path}/assets/db/gyan.sqlite';
    db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(readOnly: true));
  });

  tearDownAll(() async => db.close());

  Future<int> count(String sql) async {
    final rows = await db.rawQuery(sql);
    return (rows.first.values.first as int?) ?? 0;
  }

  test('entity prose has not regressed', () async {
    expect(await count('SELECT COUNT(*) FROM entities WHERE '
        'long_description_en IS NOT NULL AND long_description_hi IS NOT NULL'),
        greaterThanOrEqualTo(27));
  });

  test('both epics keep their scenes and their detail', () async {
    expect(await count(
        "SELECT COUNT(*) FROM narrative_nodes WHERE epic='ramayana'"),
        greaterThanOrEqualTo(32));
    expect(await count(
        "SELECT COUNT(*) FROM narrative_nodes WHERE epic='mahabharata'"),
        greaterThanOrEqualTo(47));
    expect(await count('SELECT COUNT(*) FROM narrative_nodes WHERE '
        'long_description_en IS NOT NULL'), greaterThanOrEqualTo(61));
  });

  test('everything user-facing is bilingual', () async {
    for (final t in ['entities', 'festivals', 'narrative_nodes',
                     'cosmology_nodes', 'vidya_topics']) {
      expect(await count('SELECT COUNT(*) FROM $t WHERE title_hi IS NULL '
          "OR title_hi = ''"), 0,
          reason: '$t has rows with no Hindi title');
    }
  });

  test('the graph keeps its density', () async {
    expect(await count('SELECT COUNT(*) FROM entities'), greaterThanOrEqualTo(500));
    expect(await count('SELECT COUNT(*) FROM relations'), greaterThanOrEqualTo(570));
    expect(await count('SELECT COUNT(*) FROM related_edges'), greaterThanOrEqualTo(2900));
  });
}
