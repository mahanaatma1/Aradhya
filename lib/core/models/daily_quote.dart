/// A verse-of-the-day entry, read from `gyan.quotes`.
///
/// The fixture split this across two tables: `daily_quotes` (3 rows, with
/// Sanskrit) and `quotes` (1,000, without). Reading only the first repeated the
/// verse on a three-day cycle; reading only the second dropped the Sanskrit.
/// `gyan.quotes` is one table of 1,000 where every row is bilingual and 672
/// carry the Devanagari, so the merge is no longer needed.
class DailyQuote {
  final int id;
  final String? sanskrit;
  final String? transliteration;
  final String en;
  final String? hi;
  final String? sourceEn;
  final String? sourceHi;

  /// '2.47' for a scripture verse, null for a saying or a teaching.
  final String? verseRef;

  const DailyQuote({
    required this.id,
    this.sanskrit,
    this.transliteration,
    required this.en,
    this.hi,
    this.sourceEn,
    this.sourceHi,
    this.verseRef,
  });

  factory DailyQuote.fromRow(Map<String, Object?> row) => DailyQuote(
        id: row['id'] as int,
        sanskrit: row['sanskrit'] as String?,
        transliteration: row['iast'] as String?,
        en: (row['text_en'] ?? '') as String,
        hi: row['text_hi'] as String?,
        sourceEn: row['source_title_en'] as String?,
        sourceHi: row['source_title_hi'] as String?,
        verseRef: row['verse_ref'] as String?,
      );

  /// Body/source in the requested language, falling back to English.
  String text(bool hindi) => (hindi && (hi?.isNotEmpty ?? false)) ? hi! : en;
  String? source(bool hindi) {
    final name = (hindi && (sourceHi?.isNotEmpty ?? false)) ? sourceHi : sourceEn;
    if (name == null || name.isEmpty) return null;
    return (verseRef?.isNotEmpty ?? false) ? '$name $verseRef' : name;
  }
}
