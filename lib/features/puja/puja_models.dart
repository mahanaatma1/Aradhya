import 'dart:convert';

/// A puja vidhi (ritual guide), read from `gyan.puja_vidhi`.
///
/// Three things changed when this moved off the Ishvarvaani fixture, and all
/// three are visible in this class:
///
///  1. **It is bilingual.** The fixture had `items_en`, `vidhi_en` and
///     `benefits_en` with no Hindi columns at all — the Hindi existed only
///     inside a `data` JSON blob nothing read, so a Hindi reader got English
///     ritual steps. Every field here now has a `_hi` twin.
///  2. **Lists are JSON, not newline-delimited text.** Splitting on `\n` meant
///     a step could never contain a line break.
///  3. **Mantras are structured.** The fixture stored one mantra as a
///     Python-dict-ish string that had to be pulled apart with a regex; this
///     table stores a JSON array of `{sanskrit, iast, en, hi}`, so a rite can
///     carry more than one and no parsing is guessed.
class PujaVidhi {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deityEn;
  final String? deityHi;
  final String? categoryEn;
  final String? categoryHi;
  final String? whenEn;
  final String? whenHi;
  final String? durationEn;
  final String? durationHi;
  final String? preparationEn;
  final String? preparationHi;
  final List<String> itemsEn;
  final List<String> itemsHi;
  final List<String> vidhiEn;
  final List<String> vidhiHi;
  final List<PujaMantra> mantras;
  final String? benefitsEn;
  final String? benefitsHi;
  final String? significanceEn;
  final String? significanceHi;
  final String? commonMistakesEn;
  final String? commonMistakesHi;
  final String? regionalVariationsEn;
  final String? regionalVariationsHi;

  /// Soft link into `gyan.festivals`. Null where the rite is not tied to a
  /// dated festival (Griha Pravesh, Bhumi Puja, Rudrabhishek…).
  final String? festivalSlug;

  const PujaVidhi({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.deityEn,
    this.deityHi,
    this.categoryEn,
    this.categoryHi,
    this.whenEn,
    this.whenHi,
    this.durationEn,
    this.durationHi,
    this.preparationEn,
    this.preparationHi,
    this.itemsEn = const [],
    this.itemsHi = const [],
    this.vidhiEn = const [],
    this.vidhiHi = const [],
    this.mantras = const [],
    this.benefitsEn,
    this.benefitsHi,
    this.significanceEn,
    this.significanceHi,
    this.commonMistakesEn,
    this.commonMistakesHi,
    this.regionalVariationsEn,
    this.regionalVariationsHi,
    this.festivalSlug,
  });

  factory PujaVidhi.fromRow(Map<String, Object?> r) => PujaVidhi(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        deityEn: _joinList(r['deity_en'] as String?),
        deityHi: _joinList(r['deity_hi'] as String?),
        categoryEn: r['category_en'] as String?,
        categoryHi: r['category_hi'] as String?,
        whenEn: r['when_en'] as String?,
        whenHi: r['when_hi'] as String?,
        durationEn: r['duration_en'] as String?,
        durationHi: r['duration_hi'] as String?,
        preparationEn: r['preparation_en'] as String?,
        preparationHi: r['preparation_hi'] as String?,
        itemsEn: _list(r['items_en'] as String?),
        itemsHi: _list(r['items_hi'] as String?),
        vidhiEn: _list(r['vidhi_en'] as String?),
        vidhiHi: _list(r['vidhi_hi'] as String?),
        mantras: PujaMantra.listFrom(r['key_mantras'] as String?),
        benefitsEn: r['benefits_en'] as String?,
        benefitsHi: r['benefits_hi'] as String?,
        significanceEn: r['significance_en'] as String?,
        significanceHi: r['significance_hi'] as String?,
        commonMistakesEn: r['common_mistakes_en'] as String?,
        commonMistakesHi: r['common_mistakes_hi'] as String?,
        regionalVariationsEn: r['regional_variations_en'] as String?,
        regionalVariationsHi: r['regional_variations_hi'] as String?,
        festivalSlug: r['festival_slug'] as String?,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? whenText(bool hi) =>
      (hi && (whenHi?.isNotEmpty ?? false)) ? whenHi : whenEn;
  String? deity(bool hi) =>
      (hi && (deityHi?.isNotEmpty ?? false)) ? deityHi : deityEn;
  String? category(bool hi) =>
      (hi && (categoryHi?.isNotEmpty ?? false)) ? categoryHi : categoryEn;
  String? duration(bool hi) =>
      (hi && (durationHi?.isNotEmpty ?? false)) ? durationHi : durationEn;
  String? preparation(bool hi) =>
      (hi && (preparationHi?.isNotEmpty ?? false)) ? preparationHi : preparationEn;
  String? benefits(bool hi) =>
      (hi && (benefitsHi?.isNotEmpty ?? false)) ? benefitsHi : benefitsEn;
  String? significance(bool hi) =>
      (hi && (significanceHi?.isNotEmpty ?? false)) ? significanceHi : significanceEn;
  String? commonMistakes(bool hi) =>
      (hi && (commonMistakesHi?.isNotEmpty ?? false))
          ? commonMistakesHi
          : commonMistakesEn;
  String? regionalVariations(bool hi) =>
      (hi && (regionalVariationsHi?.isNotEmpty ?? false))
          ? regionalVariationsHi
          : regionalVariationsEn;

  /// The Hindi list is used only when it is the same length as the English
  /// one. A mismatch means a step would silently go missing, and showing the
  /// complete English list is better than showing an incomplete Hindi one.
  List<String> items(bool hi) =>
      (hi && itemsHi.length == itemsEn.length) ? itemsHi : itemsEn;
  List<String> steps(bool hi) =>
      (hi && vidhiHi.length == vidhiEn.length) ? vidhiHi : vidhiEn;

  static List<String> _list(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } on FormatException {
      // Tolerate the fixture's newline-delimited form so a stale row renders
      // rather than disappearing.
      return raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String? _joinList(String? raw) {
    final parts = _list(raw);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// One mantra attached to a rite: the Devanagari, its romanisation, and a
/// translation in both languages.
class PujaMantra {
  final String? sanskrit;
  final String? iast;
  final String? en;
  final String? hi;

  const PujaMantra({this.sanskrit, this.iast, this.en, this.hi});

  String? translation(bool showHi) =>
      (showHi && (hi?.isNotEmpty ?? false)) ? hi : en;

  static List<PujaMantra> listFrom(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().map((m) {
        return PujaMantra(
          sanskrit: m['sanskrit'] as String?,
          iast: m['iast'] as String?,
          en: m['en'] as String?,
          hi: m['hi'] as String?,
        );
      }).toList();
    } on FormatException {
      return const [];
    }
  }
}
