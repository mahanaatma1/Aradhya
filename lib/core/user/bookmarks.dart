import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_prefs.dart';

/// A saved item pointing back to any content screen. [route] + [extraId] let
/// the Bookmarks screen re-open the source; content is re-fetched by id.
class Bookmark {
  final String kind; // 'aarti' | 'chalisa' | 'mantra' | 'story' | 'temple'
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? subtitle;

  const Bookmark({
    required this.kind,
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.subtitle,
  });

  String get uid => '$kind:$id';

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
}

class BookmarksController extends StateNotifier<List<Bookmark>> {
  BookmarksController(this._ref) : super(const []) {
    final p = _ref.read(sharedPrefsProvider);
    final raw = p.getString(PrefKeys.bookmarks);
    if (raw != null) {
      state = (jsonDecode(raw) as List)
          .map((e) => Bookmark.fromJson(e as Map<String, Object?>))
          .toList();
    }
  }

  final Ref _ref;

  bool contains(String uid) => state.any((b) => b.uid == uid);

  Future<void> toggle(Bookmark b) async {
    final exists = contains(b.uid);
    state = exists
        ? state.where((x) => x.uid != b.uid).toList()
        : [b, ...state];
    await _persist();
  }

  Future<void> _persist() async {
    final p = _ref.read(sharedPrefsProvider);
    await p.setString(
        PrefKeys.bookmarks, jsonEncode(state.map((b) => b.toJson()).toList()));
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, List<Bookmark>>(
        (ref) => BookmarksController(ref));
