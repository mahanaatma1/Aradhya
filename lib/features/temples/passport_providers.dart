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


/// What the passport says about the journey so far.
///
/// Derived, never stored: every field here is a reading of `temple_visits`, so
/// it cannot drift from the stamps on the page.
class PassportStats {
  final int darshan;
  final int states;
  final int? sinceYear;
  final int collectionsComplete;
  final int collectionsTotal;

  const PassportStats({
    required this.darshan,
    required this.states,
    required this.sinceYear,
    required this.collectionsComplete,
    required this.collectionsTotal,
  });

  static PassportStats of(List<PassportEntry> visited, {int complete = 0}) {
    final states = <String>{
      for (final e in visited)
        if ((e.state ?? '').trim().isNotEmpty) e.state!.trim(),
    };
    final years = [
      for (final e in visited)
        if (e.visitedAt != null) e.visitedAt!.year,
    ]..sort();
    return PassportStats(
      darshan: visited.length,
      states: states.length,
      sinceYear: years.isEmpty ? null : years.first,
      collectionsComplete: complete,
      collectionsTotal: kCollections.length,
    );
  }

  /// A stable document number. Derived from the holder and nothing else, so it
  /// does not change as stamps are added -- a passport number that renumbered
  /// itself every trip would not be one.
  static String number(String holder) {
    var h = 0;
    for (final unit in holder.isEmpty ? 'devotee'.codeUnits : holder.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return 'AR${(h % 9000000 + 1000000)}';
  }
}

/// The rank ladder. Titles are descriptive of the journey, not honours the app
/// is in any position to confer -- so they name what someone is doing, not what
/// they have become.
class YatraRank {
  final String titleEn;
  final String titleHi;
  final int from;

  const YatraRank(this.titleEn, this.titleHi, this.from);

  static const ladder = <YatraRank>[
    YatraRank('Yatri', 'यात्री', 0),
    YatraRank('Bhakt', 'भक्त', 5),
    YatraRank('Sadhak', 'साधक', 12),
    YatraRank('Tirtha Yatri', 'तीर्थ यात्री', 25),
    YatraRank('Tirtha Sevak', 'तीर्थ सेवक', 50),
    YatraRank('Yatra Acharya', 'यात्रा आचार्य', 100),
  ];

  /// One-based, because "Level 1" is where a journey starts, not level zero.
  static int levelFor(int n) => ladder.indexOf(forCount(n)) + 1;

  String title(bool hi) => hi ? titleHi : titleEn;

  static YatraRank forCount(int n) {
    var out = ladder.first;
    for (final r in ladder) {
      if (n >= r.from) out = r;
    }
    return out;
  }

  /// The next rung, or null at the top of the ladder.
  static YatraRank? next(int n) {
    for (final r in ladder) {
      if (r.from > n) return r;
    }
    return null;
  }
}

/// A milestone: something that happened on the journey, marked once.
///
/// Deliberately not points, coins or a leaderboard. Each one names a real
/// first -- a first darshan, a first state, a first dham -- so the reward for
/// a pilgrimage is the record of it, not a score attached to it.
class Milestone {
  final String id;
  final String titleEn;
  final String titleHi;
  final String blurbEn;
  final String blurbHi;
  final bool earned;

  const Milestone({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.blurbEn,
    required this.blurbHi,
    required this.earned,
  });

  String title(bool hi) => hi ? titleHi : titleEn;
  String blurb(bool hi) => hi ? blurbHi : blurbEn;
}

/// Every milestone, earned or not, in a fixed order.
///
/// Unearned ones are returned too: a milestone you cannot see is not something
/// to aim at.
final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final visited = await ref.watch(visitedTemplesProvider.future);
  final stats = PassportStats.of(visited);

  var jyotirlinga = 0;
  var dham = 0;
  var setsComplete = 0;
  for (final c in kCollections) {
    final list = await ref.watch(collectionProvider(c.tag).future);
    final done = list.where((e) => e.visited).length;
    if (list.isNotEmpty && done >= list.length) setsComplete++;
    if (c.tag == 'jyotirlinga') jyotirlinga = done;
    if (c.tag == 'char_dham') dham = done;
  }

  return [
    Milestone(
      id: 'first_darshan',
      titleEn: 'First Darshan',
      titleHi: 'प्रथम दर्शन',
      blurbEn: 'Your first pilgrimage recorded.',
      blurbHi: 'आपकी पहली यात्रा दर्ज हुई।',
      earned: stats.darshan >= 1,
    ),
    Milestone(
      id: 'first_state',
      titleEn: 'First State',
      titleHi: 'प्रथम राज्य',
      blurbEn: 'Your first state added to the passport.',
      blurbHi: 'पासपोर्ट में पहला राज्य जुड़ा।',
      earned: stats.states >= 1,
    ),
    Milestone(
      id: 'five_temples',
      titleEn: 'Five Darshans',
      titleHi: 'पाँच दर्शन',
      blurbEn: 'Five temples visited.',
      blurbHi: 'पाँच मंदिरों के दर्शन।',
      earned: stats.darshan >= 5,
    ),
    Milestone(
      id: 'first_dham',
      titleEn: 'First Dham',
      titleHi: 'प्रथम धाम',
      blurbEn: 'You have stood at one of the Char Dham.',
      blurbHi: 'आपने चार धाम में से एक के दर्शन किए।',
      earned: dham >= 1,
    ),
    Milestone(
      id: 'jyotirlinga_seeker',
      titleEn: 'Jyotirlinga Seeker',
      titleHi: 'ज्योतिर्लिंग साधक',
      blurbEn: 'Three of the twelve Jyotirlingas visited.',
      blurbHi: 'बारह ज्योतिर्लिंगों में से तीन के दर्शन।',
      earned: jyotirlinga >= 3,
    ),
    Milestone(
      id: 'pan_india',
      titleEn: 'Pan-India Yatri',
      titleHi: 'अखिल भारत यात्री',
      blurbEn: 'Temples visited across five states.',
      blurbHi: 'पाँच राज्यों में मंदिरों के दर्शन।',
      earned: stats.states >= 5,
    ),
    Milestone(
      id: 'set_complete',
      titleEn: 'A Set Complete',
      titleHi: 'एक संग्रह पूर्ण',
      blurbEn: 'Every temple in one traditional set.',
      blurbHi: 'एक पारंपरिक संग्रह के सभी मंदिर।',
      earned: setsComplete >= 1,
    ),
  ];
});

/// The states this journey has touched, most-visited first.
final visitedStatesProvider = FutureProvider<List<MapEntry<String, int>>>(
    (ref) async {
  final visited = await ref.watch(visitedTemplesProvider.future);
  final counts = <String, int>{};
  for (final e in visited) {
    final s = (e.state ?? '').trim();
    if (s.isEmpty) continue;
    counts[s] = (counts[s] ?? 0) + 1;
  }
  final out = counts.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return out;
});
