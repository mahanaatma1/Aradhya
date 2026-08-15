import '../../core/user/bookmarks.dart';
import '../search/search_fold.dart';

/// Whether [b] matches a free-text query over title, note and tags.
///
/// Uses the same fold rules as universal search so "krishna" finds notes
/// mentioning "Kṛṣṇa".
bool bookmarkMatchesQuery(Bookmark b, String query, {required bool hindi}) {
  final words = _queryWords(query);
  if (words.isEmpty) return true;

  final blob = [
    hindi ? (b.titleHi ?? b.titleEn) : b.titleEn,
    b.subtitle,
    b.note,
    ...b.tags,
  ].whereType<String>().where((s) => s.isNotEmpty).join('\n');

  if (blob.isEmpty) return false;

  final hay = foldVariants(blob.toLowerCase());
  return words.every((variants) =>
      variants.any((v) => hay.any((h) => h.contains(v))));
}

List<List<String>> _queryWords(String query) {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];
  final out = <List<String>>[];
  for (final raw in trimmed.split(RegExp(r'\s+'))) {
    final variants = foldVariants(raw).where((v) => v.length >= 2).toList();
    if (variants.isNotEmpty) out.add(variants);
  }
  return out;
}
