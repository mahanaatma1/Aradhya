/// One precomputed recommendation edge.
///
/// Title, subtitle and route are denormalized into `related_edges` at build
/// time, so a whole rail renders from a single indexed query — no cross-database
/// join, no N+1, and no loading spinner on a detail screen.
class RelatedItem {
  final String dstSrc;
  final String dstTable;
  final int dstId;

  /// Drives the group header and glyph: 'temple' | 'aarti' | 'mantra' | …
  final String dstKind;

  /// Why this edge exists — 'deity:hanuman', 'relation:wields',
  /// 'emotion:faith'. Kept for debugging bad recommendations, which are far
  /// more visible to users than missing ones.
  final String reason;

  final double weight;
  final String titleEn;
  final String? titleHi;
  final String? subtitleEn;
  final String? subtitleHi;
  final String route;

  const RelatedItem({
    required this.dstSrc,
    required this.dstTable,
    required this.dstId,
    required this.dstKind,
    required this.reason,
    required this.weight,
    required this.titleEn,
    required this.route,
    this.titleHi,
    this.subtitleEn,
    this.subtitleHi,
  });

  factory RelatedItem.fromRow(Map<String, Object?> r) => RelatedItem(
        dstSrc: (r['dst_src'] as String?) ?? 'content',
        dstTable: (r['dst_table'] as String?) ?? '',
        dstId: (r['dst_id'] as int?) ?? 0,
        dstKind: (r['dst_kind'] as String?) ?? '',
        reason: (r['reason'] as String?) ?? '',
        weight: (r['weight'] as num?)?.toDouble() ?? 0,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        subtitleEn: r['subtitle_en'] as String?,
        subtitleHi: r['subtitle_hi'] as String?,
        route: (r['route'] as String?) ?? '',
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? subtitle(bool hi) =>
      (hi && (subtitleHi?.isNotEmpty ?? false)) ? subtitleHi : subtitleEn;
}

/// Identifies the item a rail is being built for.
typedef RelatedKey = ({String src, String table, int id});
