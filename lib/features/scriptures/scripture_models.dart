// Data models for the scriptures feature, mirroring the `content.sqlite`
// tables: scriptures → scripture_books → scripture_sections.

class Scripture {
  final int id;
  final String nameEn;
  final String? nameHi;
  final String slug;
  final String? cover;

  const Scripture({
    required this.id,
    required this.nameEn,
    this.nameHi,
    required this.slug,
    this.cover,
  });

  factory Scripture.fromRow(Map<String, Object?> r) => Scripture(
        id: r['id'] as int,
        nameEn: r['name_en'] as String,
        nameHi: r['name_hi'] as String?,
        slug: r['slug'] as String,
        cover: r['cover'] as String?,
      );

  String name(bool hi) => (hi && (nameHi?.isNotEmpty ?? false)) ? nameHi! : nameEn;
}

class ScriptureBook {
  final int id;
  final int scriptureId;
  final String titleEn;
  final String? titleHi;
  final String? subtitleEn;
  final String? subtitleHi;
  final String slug;

  const ScriptureBook({
    required this.id,
    required this.scriptureId,
    required this.titleEn,
    this.titleHi,
    this.subtitleEn,
    this.subtitleHi,
    required this.slug,
  });

  factory ScriptureBook.fromRow(Map<String, Object?> r) => ScriptureBook(
        id: r['id'] as int,
        scriptureId: r['scripture_id'] as int,
        titleEn: r['title_en'] as String,
        titleHi: r['title_hi'] as String?,
        subtitleEn: r['subtitle_en'] as String?,
        subtitleHi: r['subtitle_hi'] as String?,
        slug: r['slug'] as String,
      );

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? subtitle(bool hi) =>
      (hi && (subtitleHi?.isNotEmpty ?? false)) ? subtitleHi : subtitleEn;
}

class ScriptureSection {
  final int id;
  final int bookId;
  final String number;
  final String? bodyEn;
  final String? bodyHi;
  final String? sanskrit;
  final String? transliteration;
  final String? commentaryEn;
  final String? commentaryHi;

  const ScriptureSection({
    required this.id,
    required this.bookId,
    required this.number,
    this.bodyEn,
    this.bodyHi,
    this.sanskrit,
    this.transliteration,
    this.commentaryEn,
    this.commentaryHi,
  });

  factory ScriptureSection.fromRow(Map<String, Object?> r) => ScriptureSection(
        id: r['id'] as int,
        bookId: r['book_id'] as int,
        number: (r['number'] ?? '').toString(),
        bodyEn: r['body_en'] as String?,
        bodyHi: r['body_hi'] as String?,
        sanskrit: r['sanskrit'] as String?,
        transliteration: r['transliteration'] as String?,
        commentaryEn: r['commentary_en'] as String?,
        commentaryHi: r['commentary_hi'] as String?,
      );

  String? body(bool hi) => (hi && (bodyHi?.isNotEmpty ?? false)) ? bodyHi : bodyEn;
  String? commentary(bool hi) =>
      (hi && (commentaryHi?.isNotEmpty ?? false)) ? commentaryHi : commentaryEn;
}

/// One Sanskrit word from the Word meaning tab (RD-02), from `gyan.word_meanings`.
class WordMeaning {
  final String sanskrit;
  final String meaningEn;
  final String? meaningHi;

  const WordMeaning({
    required this.sanskrit,
    required this.meaningEn,
    this.meaningHi,
  });

  factory WordMeaning.fromRow(Map<String, Object?> r) => WordMeaning(
        sanskrit: r['sanskrit'] as String,
        meaningEn: r['meaning_en'] as String,
        meaningHi: r['meaning_hi'] as String?,
      );

  String meaning(bool hi) =>
      (hi && (meaningHi?.isNotEmpty ?? false)) ? meaningHi! : meaningEn;
}
