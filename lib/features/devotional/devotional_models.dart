import 'dart:convert';

// Models for devotional content: aartis, chalisas (lyrics) and mantras.
//
// These read `gyan.devotional_lyrics` and `gyan.mantras`. The devotional text
// itself was always public domain -- the Hanuman Chalisa is Tulsidas c.1600 --
// so what changed is the transcription, and the translation/summary/guidance
// prose, which is ours.

/// A lyrics-based item (aarti or chalisa).
class DevotionalItem {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deity;
  final String? deityHi;
  final String? lyricsEn;
  final String? lyricsHi;

  const DevotionalItem({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.deity,
    this.deityHi,
    this.lyricsEn,
    this.lyricsHi,
  });

  factory DevotionalItem.fromRow(Map<String, Object?> r) => DevotionalItem(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        deity: _first(r['deity_en'] as String?),
        deityHi: _first(r['deity_hi'] as String?),
        lyricsEn: r['lyrics_en'] as String?,
        lyricsHi: r['lyrics_hi'] as String?,
      );

  /// `deity_en` / `deity_hi` on these two tables are plain comma-separated
  /// strings ("Krishna, Rama"), not JSON arrays like the katha and puja
  /// tables. Both shapes are handled so neither renders as raw punctuation,
  /// and the card shows the first name either way.
  static String? _first(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    if (t.startsWith('[')) {
      try {
        final d = jsonDecode(t);
        if (d is List && d.isNotEmpty) return '${d.first}'.trim();
        return null;
      } on FormatException {
        // Fall through and read it as plain text.
      }
    }
    final first = t.split(',').first.trim();
    return first.isEmpty ? null : first;
  }

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? lyrics(bool hi) => (hi && (lyricsHi?.isNotEmpty ?? false)) ? lyricsHi : lyricsEn;
  String? deityLabel(bool hi) => (hi && (deityHi?.isNotEmpty ?? false)) ? deityHi : deity;
}

/// A mantra / stotra with sanskrit, transliteration, meaning and guidance.
class Mantra {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deity;
  final String? deityHi;
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
    this.deityHi,
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
        deity: DevotionalItem._first(r['deity_en'] as String?),
        deityHi: DevotionalItem._first(r['deity_hi'] as String?),
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
  String? deityLabel(bool hi) =>
      (hi && (deityHi?.isNotEmpty ?? false)) ? deityHi : deity;
}
