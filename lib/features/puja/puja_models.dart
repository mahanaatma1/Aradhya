/// A puja vidhi (ritual guide).
class PujaVidhi {
  final int id;
  final String titleEn;
  final String? titleHi;
  final String? deity;
  final String? category;
  final String? whenEn;
  final String? whenHi;
  final String? itemsEn;
  final String? vidhiEn;
  final String? keyMantra;
  final String? benefitsEn;

  const PujaVidhi({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.deity,
    this.category,
    this.whenEn,
    this.whenHi,
    this.itemsEn,
    this.vidhiEn,
    this.keyMantra,
    this.benefitsEn,
  });

  factory PujaVidhi.fromRow(Map<String, Object?> r) => PujaVidhi(
        id: r['id'] as int,
        titleEn: (r['title_en'] ?? '') as String,
        titleHi: r['title_hi'] as String?,
        deity: r['deity'] as String?,
        category: r['category'] as String?,
        whenEn: r['when_en'] as String?,
        whenHi: r['when_hi'] as String?,
        itemsEn: r['items_en'] as String?,
        vidhiEn: r['vidhi_en'] as String?,
        keyMantra: r['key_mantra'] as String?,
        benefitsEn: r['benefits_en'] as String?,
      );

  String title(bool hi) => (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? whenText(bool hi) =>
      (hi && (whenHi?.isNotEmpty ?? false)) ? whenHi : whenEn;

  /// Newline-separated fields → a clean list of steps/items.
  List<String> get items => _lines(itemsEn);
  List<String> get steps => _lines(vidhiEn);

  static List<String> _lines(String? raw) => (raw ?? '')
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// The key mantra is stored as a Python-dict-ish string; pull out the
  /// Sanskrit line and English translation leniently, falling back to raw.
  ({String? sanskrit, String? translation}) get mantra {
    final raw = keyMantra;
    if (raw == null || raw.isEmpty) return (sanskrit: null, translation: null);
    String? grab(String key) {
      final m = RegExp("'$key'\\s*:\\s*'([^']*)'").firstMatch(raw);
      return m?.group(1);
    }

    final s = grab('sanskrit');
    final en = RegExp("'en'\\s*:\\s*'([^']*)'").firstMatch(raw)?.group(1);
    if (s == null && en == null) return (sanskrit: raw, translation: null);
    return (sanskrit: s, translation: en);
  }
}
