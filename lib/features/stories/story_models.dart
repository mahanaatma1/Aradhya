import 'dart:convert';

/// Which table a [Story] came from.
///
/// The two are genuinely different kinds of content and are filtered
/// differently, but they render identically, so they share one model and one
/// reader screen rather than duplicating both.
enum StoryKind {
  /// `stories` — moral tales, tagged by emotion.
  story,

  /// `kathas` — vrat kathas (Ekadashi, Satyanarayan, Santoshi Mata…), tagged by
  /// deity. 57 rows that were shipping in the database but had no screen: the
  /// `/katha` route rendered `stories` instead, so none of them were reachable.
  katha,
}

class Story {
  final int id;
  final String titleEn;
  final String? titleHi;
  final List<String> emotions;

  /// Hindi labels for [emotions], same order and length. Populated from
  /// `gyan.stories.emotions_hi`, which the loader keeps parallel.
  final List<String> emotionsHi;
  final String? bodyEn;
  final String? bodyHi;
  final StoryKind kind;

  /// Deities this katha is told for. Empty for [StoryKind.story].
  final List<String> deities;

  /// Hindi labels for [deities], same order and length.
  final List<String> deitiesHi;

  const Story({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.emotions = const [],
    this.emotionsHi = const [],
    this.bodyEn,
    this.bodyHi,
    this.kind = StoryKind.story,
    this.deities = const [],
    this.deitiesHi = const [],
  });

  bool get isKatha => kind == StoryKind.katha;

  /// The chip this katha is filed under — the first deity named.
  String? get primaryDeity => deities.isEmpty ? null : deities.first;

  /// Chip labels in the reader's language, falling back to English where the
  /// Hindi list is absent or a different length than its English twin.
  List<String> chipLabels(bool hi) =>
      (hi && deitiesHi.length == deities.length) ? deitiesHi : deities;

  List<String> emotionLabels(bool hi) =>
      (hi && emotionsHi.length == emotions.length) ? emotionsHi : emotions;

  /// A `gyan.kathas` row. Ids are offset so a katha and a story can never
  /// collide in bookmarks, the search index, or `extra` payloads.
  factory Story.fromKathaRow(Map<String, Object?> r) => Story(
        id: kathaIdOffset + (r['id'] as int),
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        bodyEn: r['body_en'] as String?,
        bodyHi: r['body_hi'] as String?,
        kind: StoryKind.katha,
        deities: _jsonList(r['deity_en'] as String?),
        deitiesHi: _jsonList(r['deity_hi'] as String?),
      );

  static const kathaIdOffset = 500000;

  /// `deity_en` / `deity_hi` are JSON arrays in `gyan.kathas`, already split
  /// and already free of honorifics.
  ///
  /// The fixture shipped one English-only free-text column instead
  /// (`"Lord Vishnu (Satyanarayan), Lord Shiva & Goddess Parvati"`), which had
  /// to be parsed apart here and left a Hindi reader looking at English filter
  /// chips. Both problems are fixed in the data rather than in this parser.
  static List<String> _jsonList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
      }
    } on FormatException {
      // A malformed cell should empty one chip row, not crash the screen.
    }
    return const [];
  }

  /// A `gyan.stories` row.
  factory Story.fromRow(Map<String, Object?> r) => Story(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        emotions: _jsonList(r['emotions_en'] as String?),
        emotionsHi: _jsonList(r['emotions_hi'] as String?),
        bodyEn: r['body_en'] as String?,
        bodyHi: r['body_hi'] as String?,
      );

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? body(bool hi) => (hi && (bodyHi?.isNotEmpty ?? false)) ? bodyHi : bodyEn;
}
