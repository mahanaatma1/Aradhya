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

  /// A short, human label for *why* this edge exists — "Guru", "Wields" —
  /// when [reason] names a specific relation worth surfacing (NR-04). Most
  /// reasons are match-mechanism internals a reader shouldn't see verbatim
  /// (`deity:krishna`, `alias:vishnu`, `named_in_verse`); this returns null
  /// for all of those, so the card stays silent rather than showing jargon.
  String? relationLabel(bool hi) {
    if (!reason.startsWith('relation:')) return null;
    final rel = reason.substring('relation:'.length);
    final pair = _relationLabels[rel];
    if (pair == null) return null;
    return hi ? pair.$2 : pair.$1;
  }
}

/// English/Hindi labels for the `rel_type` vocabulary in
/// `content/tools/validate.py`'s `REL_INVERSE`. Only the types worth a
/// reader seeing on a related-content card are listed — generic ones
/// (`related_to`, `associated_with`) add no information over the card's
/// own kind glyph and are left out on purpose.
const _relationLabels = <String, (String, String)>{
  'father_of': ('Father of', 'के पिता'),
  'mother_of': ('Mother of', 'की माता'),
  'child_of': ('Child of', 'की संतान'),
  'spouse_of': ('Spouse of', 'के जीवनसाथी'),
  'sibling_of': ('Sibling of', 'के भाई-बहन'),
  'guru_of': ('Guru', 'गुरु'),
  'disciple_of': ('Disciple', 'शिष्य'),
  'wields': ('Wields', 'धारण करते हैं'),
  'wielded_by': ('Wielded by', 'द्वारा धारित'),
  'killed_by': ('Killed by', 'द्वारा वध'),
  'killed': ('Killed', 'का वध किया'),
  'incarnation_of': ('Incarnation of', 'का अवतार'),
  'has_incarnation': ('Avatar', 'अवतार'),
  'mount_of': ('Mount of', 'का वाहन'),
  'has_mount': ('Mount', 'वाहन'),
  'consort_of': ('Consort of', 'की अर्धांगिनी'),
  'authored': ('Author of', 'के रचयिता'),
  'authored_by': ('Authored by', 'द्वारा रचित'),
  'ruled_by': ('Ruled by', 'द्वारा शासित'),
  'ruled': ('Ruled', 'का शासन किया'),
  'worshipped_at': ('Worshipped here', 'यहाँ पूजित'),
  'worships': ('Worshipped deity', 'पूजित देवता'),
  'symbol_of': ('Symbol of', 'का प्रतीक'),
  'has_symbol': ('Symbol', 'प्रतीक'),
  'member_of': ('Member of', 'के सदस्य'),
  'has_member': ('Member', 'सदस्य'),
};

/// Identifies the item a rail is being built for.
typedef RelatedKey = ({String src, String table, int id});
