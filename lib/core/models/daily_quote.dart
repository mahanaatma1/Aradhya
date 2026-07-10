/// A verse-of-the-day entry from the `daily_quotes` table.
class DailyQuote {
  final int id;
  final String? sanskrit;
  final String? transliteration;
  final String en;
  final String? hi;
  final String? sourceEn;
  final String? sourceHi;

  const DailyQuote({
    required this.id,
    this.sanskrit,
    this.transliteration,
    required this.en,
    this.hi,
    this.sourceEn,
    this.sourceHi,
  });

  factory DailyQuote.fromRow(Map<String, Object?> row) => DailyQuote(
        id: row['id'] as int,
        sanskrit: row['sanskrit'] as String?,
        transliteration: row['transliteration'] as String?,
        en: row['en'] as String,
        hi: row['hi'] as String?,
        sourceEn: row['source_en'] as String?,
        sourceHi: row['source_hi'] as String?,
      );

  /// Body/source in the requested language, falling back to English.
  String text(bool hindi) => (hindi && (hi?.isNotEmpty ?? false)) ? hi! : en;
  String? source(bool hindi) =>
      (hindi && (sourceHi?.isNotEmpty ?? false)) ? sourceHi : sourceEn;
}
