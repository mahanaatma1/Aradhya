import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';

/// One pilgrimage collection: a named set of temples the tradition groups.
///
/// Derived from `temples.category`, which is a comma-separated tag list, so a
/// temple can belong to several collections at once -- Somnath is both a
/// jyotirlinga and a coastal pilgrimage, and the data already says so.
class Collection {
  final String tag;
  final String titleEn;
  final String titleHi;

  /// How many the tradition counts. Shown beside how many the app holds, so a
  /// partial set is visible as partial rather than passing for complete.
  final int canonical;

  const Collection(this.tag, this.titleEn, this.titleHi, this.canonical);

  String title(bool hi) => hi ? titleHi : titleEn;
}

/// Only sets with a fixed traditional membership. Shakti Peethas are included
/// even though their count is disputed (51 or 108 depending on the list), and
/// that disagreement is stated rather than resolved.
const kCollections = <Collection>[
  Collection('jyotirlinga', '12 Jyotirlinga', 'द्वादश ज्योतिर्लिंग', 12),
  Collection('char_dham', 'Char Dham', 'चार धाम', 4),
  Collection('panchkedar', 'Panch Kedar', 'पंच केदार', 5),
  Collection('pancha_bhoota', 'Pancha Bhoota Sthalam', 'पंच भूत स्थल', 5),
  Collection('moksha_puri', 'Sapta Moksha Puri', 'सप्त मोक्षपुरी', 7),
  Collection('shaktipeeth', 'Shakti Peethas', 'शक्तिपीठ', 51),
];

/// A temple in a collection, with whether it has been visited.
class PassportEntry {
  final int templeId;
  final String nameEn;
  final String? nameHi;
  final String? state;
  final DateTime? visitedAt;
  final String? note;
  final int? rating;

  final bool _visited;

  const PassportEntry({
    required this.templeId,
    required this.nameEn,
    this.nameHi,
    this.state,
    this.visitedAt,
    this.note,
    this.rating,
    bool visited = false,
  }) : _visited = visited;

  /// Whether a visit is on record.
  ///
  /// A date always implies a visit. The flag exists for the other direction: a
  /// visit backfilled from the old prefs-only set has no date -- it happened,
  /// we just never wrote down when.
  bool get visited => _visited || visitedAt != null;
  String name(bool hi) => (hi && (nameHi?.isNotEmpty ?? false)) ? nameHi! : nameEn;
}

/// Every visit on record, keyed by temple.
///
/// Read from `USER_DB`. Kept separate from the temple rows because one lives
/// in a bundled read-only database and the other is the user's own.
final visitRecordsProvider =
    FutureProvider<Map<int, PassportEntry>>((ref) async {
  final db = ref.watch(userDatabaseProvider);
  if (db == null) return const {};
  try {
    final rows = await db.raw.query('temple_visits');
    return {
      for (final r in rows)
        (r['temple_id'] as int): PassportEntry(
          templeId: r['temple_id'] as int,
          nameEn: '',
          visited: true,
          visitedAt: switch (r['visited_at'] as int?) {
            null || 0 => null,
            final ms => DateTime.fromMillisecondsSinceEpoch(ms),
          },
          note: r['note'] as String?,
          rating: r['rating'] as int?,
        ),
    };
  } catch (_) {
    // A passport that cannot load must not take the temples screen with it.
    return const {};
  }
});

/// The temples of one collection, in order, marked with any visit.
final collectionProvider =
    FutureProvider.family<List<PassportEntry>, String>((ref, tag) async {
  final content = await ref.watch(contentDbProvider.future);
  final visits = await ref.watch(visitRecordsProvider.future);

  final rows = await content.raw.rawQuery(
    'SELECT id, name_en, name_hi, state FROM temples '
    'WHERE category LIKE ? ORDER BY name_en',
    ['%$tag%'],
  );

  return [
    for (final r in rows)
      () {
        final id = r['id'] as int;
        final v = visits[id];
        return PassportEntry(
          templeId: id,
          nameEn: (r['name_en'] as String?) ?? '',
          nameHi: r['name_hi'] as String?,
          state: r['state'] as String?,
          visited: v != null,
          visitedAt: v?.visitedAt,
          note: v?.note,
          rating: v?.rating,
        );
      }(),
  ];
});

/// Everywhere visited, most recent first — the passport's own list, including
/// temples that belong to no collection.
final visitedTemplesProvider = FutureProvider<List<PassportEntry>>((ref) async {
  final content = await ref.watch(contentDbProvider.future);
  final visits = await ref.watch(visitRecordsProvider.future);
  if (visits.isEmpty) return const [];

  final ids = visits.keys.join(',');
  final rows = await content.raw.rawQuery(
      'SELECT id, name_en, name_hi, state FROM temples WHERE id IN ($ids)');

  final out = [
    for (final r in rows)
      () {
        final id = r['id'] as int;
        final v = visits[id]!;
        return PassportEntry(
          templeId: id,
          nameEn: (r['name_en'] as String?) ?? '',
          nameHi: r['name_hi'] as String?,
          state: r['state'] as String?,
          visited: true,
          visitedAt: v.visitedAt,
          note: v.note,
          rating: v.rating,
        );
      }(),
  ];
  out.sort((a, b) {
    final da = a.visitedAt, db_ = b.visitedAt;
    if (da == null && db_ == null) return a.nameEn.compareTo(b.nameEn);
    if (da == null) return 1;
    if (db_ == null) return -1;
    return db_.compareTo(da);
  });
  return out;
});

/// Records or updates what a visit meant.
///
/// Deliberately separate from `VisitedController`, which owns the simple
/// visited/not-visited toggle used on the temple list. This writes the detail
/// without changing that contract.
class PassportController {
  const PassportController(this._ref);
  final Ref _ref;

  Future<void> save(int templeId,
      {DateTime? visitedAt, String? note, int? rating}) async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.insert(
        'temple_visits',
        {
          'temple_id': templeId,
          'visited_at':
              (visitedAt ?? DateTime.now()).millisecondsSinceEpoch,
          'note': note,
          'rating': rating,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _ref.invalidate(visitRecordsProvider);
    } catch (_) {
      // Nothing to do: the row simply is not written, and the UI still shows
      // what is on disk rather than a lie about what was saved.
    }
  }

  Future<void> remove(int templeId) async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.delete('temple_visits',
          where: 'temple_id = ?', whereArgs: [templeId]);
      _ref.invalidate(visitRecordsProvider);
    } catch (_) {
      // Already gone.
    }
  }
}

final passportControllerProvider =
    Provider((ref) => PassportController(ref));
