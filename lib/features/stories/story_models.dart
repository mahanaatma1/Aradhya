class Story {
  final int id;
  final String titleEn;
  final String? titleHi;
  final List<String> emotions;
  final String? bodyEn;
  final String? bodyHi;

  const Story({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.emotions = const [],
    this.bodyEn,
    this.bodyHi,
  });

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
