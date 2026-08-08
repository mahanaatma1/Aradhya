/// Query-time text folding for universal search.
///
///     THIS IS A MIRROR OF content/tools/common.py :: fold_variants
///
/// The search index is built in Python at content-build time; queries are
/// folded here at runtime. If the two implementations diverge, the app produces
/// tokens the index does not contain and search silently returns nothing — a
/// failure with no error message anywhere.
///
/// `test/search_fold_test.dart` pins them together against
/// `test/fixtures/fold_fixtures.json`, which Python generates. Change the rules
/// in one place and that test fails until the other is updated.
///
/// Deliberately dependency-free: no packages, no transliteration library. The
/// Devanagari-to-IAST expansion that *does* need a real library happens once at
/// build time and is stored as alias rows, so the app never transliterates.
library;

/// IAST / ISO-15919 to the plain-ASCII spellings people actually type.
///
/// Non-ASCII characters only, on purpose: mapping `c` to `ch` would be closer
/// to popular transliteration but would also turn "concept" into "chonchept",
/// and this runs over English text too.
const Map<String, String> _iastMap = {
  'ā': 'a',
  'ī': 'i',
  'ū': 'u',
  'ṛ': 'ri', // kṛṣṇa -> krishna
  'ṝ': 'ri',
  'ḷ': 'li',
  'ḹ': 'li',
  'ṃ': 'm',
  'ṁ': 'm',
  'ḥ': 'h',
  'ñ': 'n',
  'ṅ': 'n',
  'ṇ': 'n',
  'ṭ': 't',
  'ḍ': 'd',
  'ś': 'sh',
  'ṣ': 'sh',
  'é': 'e', 'è': 'e', 'ê': 'e',
  'á': 'a', 'à': 'a', 'â': 'a',
  'í': 'i', 'ì': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u',
  'ç': 'c',
};

/// Precomposed Latin letters that carry a combining mark, mapped to their base.
///
/// Dart has no `unicodedata`, so the NFKD-and-strip-marks step from the Python
/// side is expressed as an explicit table. It only needs to cover characters
/// that can actually appear in the corpus or a query — Latin with diacritics.
/// Devanagari is never decomposed, because its matras *are* combining marks and
/// stripping them would destroy the word.
const Map<String, String> _stripMarks = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ă': 'a', 'ą': 'a',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'ď': 'd', 'đ': 'd', 'ḍ': 'd',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ě': 'e', 'ę': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ṅ': 'n', 'ṇ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o',
  'ř': 'r', 'ṛ': 'r', 'ṝ': 'r',
  'ś': 's', 'š': 's', 'ş': 's', 'ṣ': 's',
  'ť': 't', 'ṭ': 't',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
  'ṁ': 'm', 'ṃ': 'm',
  'ḥ': 'h',
  'ḷ': 'l', 'ḹ': 'l',
};

final RegExp _devanagari = RegExp(r'[ऀ-ॿ]');
final RegExp _tokenSplit = RegExp(r'[^0-9A-Za-zÀ-ɏḀ-ỿऀ-ॿ]+');
final RegExp _nonToken = RegExp(r'[^0-9a-zऀ-ॿ]+');

bool hasDevanagari(String s) => _devanagari.hasMatch(s);

String _applyMap(String s, Map<String, String> map) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    b.write(map[ch] ?? ch);
  }
  return b.toString();
}

/// Fold one token into the 1-2 forms that are indexed.
///
/// Devanagari is preserved verbatim (only zero-width joiners removed), so a
/// Hindi query hits the Hindi token exactly.
///
/// Latin yields up to two variants so both common spellings hit:
///
///     'kṛṣṇa'   -> ['krishna', 'krsna']
///     'Krishna' -> ['krishna']
///
/// The first is the mapped form (ṛ→ri, ṣ→sh); the second is the naive
/// mark-stripped form, for people who type the diacritic-free spelling.
List<String> foldVariants(String s) {
  if (s.isEmpty) return const [];
  final trimmed = s.trim();
  if (trimmed.isEmpty) return const [];

  if (hasDevanagari(trimmed)) {
    // ZWJ/ZWNJ vary by keyboard and must not create distinct tokens.
    final cleaned = trimmed
        .replaceAll('‌', '')
        .replaceAll('‍', '')
        .toLowerCase()
        .replaceAll(_nonToken, '');
    return cleaned.isEmpty ? const [] : [cleaned];
  }

  final lowered = trimmed.toLowerCase();
  final mapped =
      _applyMap(_applyMap(lowered, _iastMap), _stripMarks).replaceAll(_nonToken, '');
  final naive = _applyMap(lowered, _stripMarks).replaceAll(_nonToken, '');

  final out = <String>[];
  for (final v in [mapped, naive]) {
    if (v.isNotEmpty && !out.contains(v)) out.add(v);
  }
  return out;
}

/// The single primary folded form.
String fold(String s) {
  final v = foldVariants(s);
  return v.isEmpty ? '' : v.first;
}

/// Split free text into folded tokens, preserving order, de-duplicated.
List<String> tokenize(String text) {
  if (text.isEmpty) return const [];
  final out = <String>[];
  final seen = <String>{};
  for (final raw in text.split(_tokenSplit)) {
    if (raw.isEmpty) continue;
    for (final v in foldVariants(raw)) {
      if (v.length < 2 || seen.contains(v)) continue;
      seen.add(v);
      out.add(v);
    }
  }
  return out;
}
