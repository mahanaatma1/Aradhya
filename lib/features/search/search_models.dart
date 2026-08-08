import 'package:flutter/material.dart';

import '../../app/theme/category_colors.dart';

/// One row of the universal search index.
///
/// Everything needed to render a result — title, subtitle, snippet and the
/// deep link — is denormalized into `search_docs`, so a result list is one
/// indexed query with no joins and no N+1 lookups.
class SearchHit {
  final int docId;

  /// Which database the id belongs to: `content` (legacy) or `gyan`.
  final String src;

  /// 'temple' | 'mantra' | 'shloka' | 'entity' | 'city' | 'katha' | …
  final String kind;
  final String refTable;
  final int refId;

  final String titleEn;
  final String? titleHi;
  final String? subtitleEn;
  final String? subtitleHi;
  final String? snippetEn;
  final String? snippetHi;

  /// Resolved at index time and validated against the real router, so tapping
  /// a result can never land on the "no routes for location" page.
  final String route;

  final double score;

  const SearchHit({
    required this.docId,
    required this.src,
    required this.kind,
    required this.refTable,
    required this.refId,
    required this.titleEn,
    required this.route,
    required this.score,
    this.titleHi,
    this.subtitleEn,
    this.subtitleHi,
    this.snippetEn,
    this.snippetHi,
  });

  factory SearchHit.fromRow(Map<String, Object?> r) => SearchHit(
        docId: r['doc_id'] as int,
        src: r['src'] as String,
        kind: r['kind'] as String,
        refTable: r['ref_table'] as String,
        refId: r['ref_id'] as int,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        subtitleEn: r['subtitle_en'] as String?,
        subtitleHi: r['subtitle_hi'] as String?,
        snippetEn: r['snippet_en'] as String?,
        snippetHi: r['snippet_hi'] as String?,
        route: (r['route'] as String?) ?? '',
        score: (r['score'] as num?)?.toDouble() ?? 0,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? subtitle(bool hi) =>
      (hi && (subtitleHi?.isNotEmpty ?? false)) ? subtitleHi : subtitleEn;
  String? snippet(bool hi) =>
      (hi && (snippetHi?.isNotEmpty ?? false)) ? snippetHi : snippetEn;
}

/// Presentation for each `search_docs.kind`: label, glyph and tile colour.
///
/// Keyed by the same strings the Python indexer writes, so adding a kind means
/// adding it in both places — [SearchKinds.of] falls back rather than throwing,
/// so a new kind appearing before its styling is a cosmetic gap, not a crash.
class SearchKindStyle {
  final String en;
  final String hi;
  final IconData icon;
  final CategoryStyle Function(CategoryColors) style;
  const SearchKindStyle(this.en, this.hi, this.icon, this.style);
}

class SearchKinds {
  SearchKinds._();

  static const _map = <String, SearchKindStyle>{
    'shloka': SearchKindStyle(
        'Verses', 'श्लोक', Icons.menu_book_rounded, _scriptures),
    'temple':
        SearchKindStyle('Temples', 'मंदिर', Icons.temple_hindu_rounded, _temples),
    'mantra':
        SearchKindStyle('Mantras', 'मंत्र', Icons.graphic_eq_rounded, _mantras),
    'aarti': SearchKindStyle('Aartis', 'आरती', Icons.local_fire_department_rounded,
        _aartis),
    'chalisa': SearchKindStyle(
        'Chalisa', 'चालीसा', Icons.auto_stories_rounded, _aartis),
    'story':
        SearchKindStyle('Stories', 'कहानियाँ', Icons.auto_stories_rounded, _katha),
    'katha': SearchKindStyle(
        'Vrat Katha', 'व्रत कथा', Icons.local_fire_department_rounded, _katha),
    'puja': SearchKindStyle(
        'Puja Vidhi', 'पूजा विधि', Icons.spa_rounded, _panchang),
    'entity':
        SearchKindStyle('Gyan', 'ज्ञान', Icons.hub_rounded, _gyan),
    'festival': SearchKindStyle(
        'Festivals', 'पर्व', Icons.celebration_rounded, _panchang),
    'scene': SearchKindStyle('Epics', 'महाकाव्य', Icons.timeline_rounded, _epics),
    'city': SearchKindStyle('Places', 'स्थान', Icons.place_rounded, _temples),
  };

  static SearchKindStyle of(String kind) =>
      _map[kind] ??
      const SearchKindStyle('Other', 'अन्य', Icons.article_rounded, _gyan);

  /// Filter-chip order. Cities are deliberately absent: they exist for the
  /// birth-place picker, not for browsing, and would drown the chip row.
  static const chipOrder = <String>[
    'shloka', 'temple', 'mantra', 'aarti', 'chalisa',
    'story', 'katha', 'puja', 'entity', 'festival', 'scene',
  ];

  static CategoryStyle _scriptures(CategoryColors c) => c.scriptures;
  static CategoryStyle _temples(CategoryColors c) => c.temples;
  static CategoryStyle _mantras(CategoryColors c) => c.mantras;
  static CategoryStyle _aartis(CategoryColors c) => c.aartis;
  static CategoryStyle _katha(CategoryColors c) => c.katha;
  static CategoryStyle _panchang(CategoryColors c) => c.panchang;
  static CategoryStyle _gyan(CategoryColors c) => c.gyan;
  static CategoryStyle _epics(CategoryColors c) => c.epics;
}
