import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/user_database.dart';
import 'interest_signals.dart';
import 'user_prefs.dart';

/// A saved item pointing back to any content screen. Content is never
/// duplicated — only the id is stored, and the body is re-fetched on open.
class Bookmark {
  /// Which database the id belongs to: `content` (legacy) or `gyan` (new).
  final String src;

  /// 'aarti' | 'chalisa' | 'mantra' | 'story' | 'temple' | 'shloka' | 'entity' …
  final String kind;
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? subtitle;

  /// The deep link to reopen this item, resolved **when the bookmark is
  /// created** rather than when it is tapped.
  ///
  /// This is the structural fix for the crash where the bookmarks screen pushed
  /// `/scriptures/book/<id>` — a path that was never registered — and landed
  /// the user on GoRouter's error page. Building the route at save time means a
  /// mistake surfaces on the screen that owns the content and knows its ids.
  ///
  /// Empty string means "not navigable": rows imported from SharedPreferences
  /// had no route, and losing the bookmark would be worse than showing it as
  /// non-tappable.
  final String route;

  /// The user's private note. Never leaves the device.
  final String? note;
  final List<String> tags;
  final DateTime? createdAt;

  const Bookmark({
    required this.kind,
    required this.id,
    required this.titleEn,
    this.src = 'content',
    this.titleHi,
    this.subtitle,
    this.route = '',
    this.note,
    this.tags = const [],
    this.createdAt,
  });

  String get uid => '$src:$kind:$id';
  bool get isNavigable => route.isNotEmpty;

  /// `note: null` cannot mean "clear it" — that is also what an untouched
  /// argument looks like — so clearing is asked for explicitly. Without
  /// [clearNote] a reader who deleted their note watched the words come back:
  /// the database row was blanked but the in-memory copy kept the old text
  /// until the next launch.
  Bookmark copyWith({
    String? note,
    bool clearNote = false,
    List<String>? tags,
    String? route,
  }) =>
      Bookmark(
        src: src,
        kind: kind,
        id: id,
        titleEn: titleEn,
        titleHi: titleHi,
        subtitle: subtitle,
        route: route ?? this.route,
        note: clearNote ? null : (note ?? this.note),
        tags: tags ?? this.tags,
        createdAt: createdAt,
      );

  /// Legacy prefs shape. Deliberately unchanged so an older build can still
  /// read the mirror written by [BookmarksController].
  Map<String, Object?> toJson() => {
        'kind': kind,
        'id': id,
        'titleEn': titleEn,
        'titleHi': titleHi,
        'subtitle': subtitle,
      };

  factory Bookmark.fromJson(Map<String, Object?> j) => Bookmark(
        kind: j['kind'] as String,
        id: j['id'] as int,
        titleEn: j['titleEn'] as String,
        titleHi: j['titleHi'] as String?,
        subtitle: j['subtitle'] as String?,
      );

  factory Bookmark.fromRow(Map<String, Object?> r) => Bookmark(
        src: (r['src'] as String?) ?? 'content',
        kind: r['kind'] as String,
        id: r['ref_id'] as int,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        subtitle: r['subtitle'] as String?,
        route: (r['route'] as String?) ?? '',
        note: r['note'] as String?,
        tags: _decodeTags(r['tags'] as String?),
        createdAt: r['created_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      );

  static List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }
}

class BookmarksController extends StateNotifier<List<Bookmark>> {
  BookmarksController(this._ref) : super(const []) {
    // Synchronous seed so the Bookmarks screen paints without a spinner…
    final p = _ref.read(sharedPrefsProvider);
    final raw = p.getString(PrefKeys.bookmarks);
    if (raw != null) {
      try {
        state = (jsonDecode(raw) as List)
            .map((e) => Bookmark.fromJson(e as Map<String, Object?>))
            .toList();
      } catch (_) {
        state = const [];
      }
    }
    // …then replace it with the database, which carries notes, tags and routes.
    _hydrateFromDb();
  }

  final Ref _ref;

  /// Set on the first user edit, so a late-arriving hydrate cannot overwrite it
  /// with a snapshot taken before that edit.
  bool _touched = false;

  bool contains(String uid) => state.any((b) => b.uid == uid);

  /// Convenience for call sites that only know kind + id.
  bool has(String kind, int id, {String src = 'content'}) =>
      contains('$src:$kind:$id');

  Future<void> _hydrateFromDb() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('bookmarks', orderBy: 'created_at DESC');
      if (!mounted || _touched) return;
      state = rows.map(Bookmark.fromRow).toList();
    } catch (e) {
      debugPrint('BookmarksController: hydrate failed ($e)');
    }
  }

  Future<void> toggle(Bookmark b) async {
    _touched = true;
    final exists = contains(b.uid);
    state =
        exists ? state.where((x) => x.uid != b.uid).toList() : [b, ...state];

    // Bookmarking is the strongest interest signal there is — it is the one
    // action where someone says "keep this". Only on add: removing a bookmark
    // is not evidence of dislike, just of tidying.
    if (!exists) {
      _ref
          .read(interestSignalsProvider.notifier)
          .record(b.kind, InterestSignals.bookmarkWeight);
    }

    final db = _ref.read(userDatabaseProvider);
    if (db != null) {
      try {
        if (exists) {
          await db.raw.delete('bookmarks',
              where: 'src = ? AND kind = ? AND ref_id = ?',
              whereArgs: [b.src, b.kind, b.id]);
        } else {
          final now = DateTime.now().millisecondsSinceEpoch;
          await db.raw.insert(
            'bookmarks',
            {
              'src': b.src,
              'kind': b.kind,
              'ref_id': b.id,
              'title_en': b.titleEn,
              'title_hi': b.titleHi,
              'subtitle': b.subtitle,
              'route': b.route,
              'note': b.note,
              'tags': b.tags.isEmpty ? null : jsonEncode(b.tags),
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (e) {
        debugPrint('BookmarksController: write failed ($e)');
      }
    }
    await _persistLegacy();
  }

  /// Attach or replace the private note on an existing bookmark.
  Future<void> setNote(String uid, String? note) async {
    _touched = true;
    final idx = state.indexWhere((b) => b.uid == uid);
    if (idx < 0) return;
    final b = state[idx];
    final trimmed = note?.trim();
    final next = trimmed == null || trimmed.isEmpty ? null : trimmed;
    state = [...state]..[idx] =
        b.copyWith(note: next, clearNote: next == null);

    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.update(
        'bookmarks',
        {'note': next, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'src = ? AND kind = ? AND ref_id = ?',
        whereArgs: [b.src, b.kind, b.id],
      );
    } catch (e) {
      debugPrint('BookmarksController: note write failed ($e)');
    }
  }

  /// Replace the tag list on an existing bookmark.
  Future<void> setTags(String uid, List<String> tags) async {
    _touched = true;
    final idx = state.indexWhere((b) => b.uid == uid);
    if (idx < 0) return;
    final b = state[idx];
    final cleaned = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    state = [...state]..[idx] = b.copyWith(tags: cleaned);

    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      await db.raw.update(
        'bookmarks',
        {
          'tags': cleaned.isEmpty ? null : jsonEncode(cleaned),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'src = ? AND kind = ? AND ref_id = ?',
        whereArgs: [b.src, b.kind, b.id],
      );
    } catch (e) {
      debugPrint('BookmarksController: tags write failed ($e)');
    }
  }

  /// Keeps the pre-migration prefs key in step for one release, so installing
  /// an older build still finds the user's bookmarks. Notes, tags and routes
  /// are deliberately absent — the old format has no room for them, and
  /// inventing one would break the old build's parser.
  Future<void> _persistLegacy() async {
    final p = _ref.read(sharedPrefsProvider);
    await p.setString(
        PrefKeys.bookmarks, jsonEncode(state.map((b) => b.toJson()).toList()));
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, List<Bookmark>>(
        (ref) => BookmarksController(ref));
