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
  final String? bodyEn;
  final String? bodyHi;
  final StoryKind kind;

  /// Deities this katha is told for. Empty for [StoryKind.story].
  final List<String> deities;

  const Story({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.emotions = const [],
    this.bodyEn,
    this.bodyHi,
    this.kind = StoryKind.story,
    this.deities = const [],
  });

  bool get isKatha => kind == StoryKind.katha;

  /// The chip this katha is filed under — the first deity named.
  String? get primaryDeity => deities.isEmpty ? null : deities.first;

  /// A `kathas` row. Ids are offset so a katha and a story can never collide in
  /// bookmarks, the search index, or `extra` payloads.
  factory Story.fromKathaRow(Map<String, Object?> r) => Story(
        id: kathaIdOffset + (r['id'] as int),
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        bodyEn: r['body_en'] as String?,
        bodyHi: r['body_hi'] as String?,
        kind: StoryKind.katha,
        deities: _parseDeities(r['deity'] as String?),
      );

  static const kathaIdOffset = 500000;

  /// The `deity` column is free text listing several figures, e.g.
  /// `"Lord Vishnu (Satyanarayan), Lord Shiva & Goddess Parvati, Moon God"`.
  /// Honorifics and parentheticals are stripped so the filter chips stay short
  /// enough to read — 51 distinct raw values collapse to a usable handful.
  static List<String> _parseDeities(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[,&]'))
        .map((part) => part
            .replaceAll(RegExp(r'\([^)]*\)'), '')
            .replaceAll(RegExp(r'^\s*(Lord|Goddess|Shree|Sri|Shri)\s+',
                caseSensitive: false), '')
            .trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  factory Story.fromRow(Map<String, Object?> r) {
    final raw = (r['emotions'] as String?) ?? '';
    final tags = raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    return Story(
      id: r['id'] as int,
      titleEn: (r['title_en'] ?? '') as String,
      titleHi: r['title_hi'] as String?,
      emotions: tags,
      bodyEn: r['body_en'] as String?,
      bodyHi: r['body_hi'] as String?,
    );
  }

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? body(bool hi) => (hi && (bodyHi?.isNotEmpty ?? false)) ? bodyHi : bodyEn;
}
