// Models for devotional content: aartis, chalisas (lyrics) and mantras.

/// A lyrics-based item (aarti or chalisa).
class DevotionalItem {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deity;
  final String? lyricsEn;
  final String? lyricsHi;

  const DevotionalItem({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.deity,
    this.lyricsEn,
    this.lyricsHi,
  });

  factory DevotionalItem.fromRow(Map<String, Object?> r) => DevotionalItem(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        deity: r['deity'] as String?,
        lyricsEn: r['lyrics_en'] as String?,
        lyricsHi: r['lyrics_hi'] as String?,
      );

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? lyrics(bool hi) => (hi && (lyricsHi?.isNotEmpty ?? false)) ? lyricsHi : lyricsEn;
}

/// A mantra / stotra with sanskrit, transliteration, meaning and guidance.
class Mantra {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deity;
  final String? typeEn;
  final String? sanskrit;
  final String? iast;
  final String? translationEn;
  final String? translationHi;
  final String? summaryEn;
  final String? summaryHi;
  final String? howToChantEn;
  final String? howToChantHi;

  const Mantra({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.deity,
    this.typeEn,
    this.sanskrit,
    this.iast,
    this.translationEn,
    this.translationHi,
    this.summaryEn,
    this.summaryHi,
    this.howToChantEn,
    this.howToChantHi,
  });

  factory Mantra.fromRow(Map<String, Object?> r) => Mantra(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        deity: r['deity'] as String?,
        typeEn: r['type_en'] as String?,
        sanskrit: r['sanskrit'] as String?,
        iast: r['iast'] as String?,
        translationEn: r['translation_en'] as String?,
        translationHi: r['translation_hi'] as String?,
        summaryEn: r['summary_en'] as String?,
        summaryHi: r['summary_hi'] as String?,
        howToChantEn: r['how_to_chant_en'] as String?,
        howToChantHi: r['how_to_chant_hi'] as String?,
      );

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? translation(bool hi) =>
      (hi && (translationHi?.isNotEmpty ?? false)) ? translationHi : translationEn;
  String? summary(bool hi) =>
      (hi && (summaryHi?.isNotEmpty ?? false)) ? summaryHi : summaryEn;
  String? howToChant(bool hi) =>
      (hi && (howToChantHi?.isNotEmpty ?? false)) ? howToChantHi : howToChantEn;
}
