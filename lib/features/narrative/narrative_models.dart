/// One scene of an epic.
///
/// `sequenceNo` is **narrative order only**. No absolute historical date is
/// claimed anywhere — the reference doc is explicit that the Mahabharata should
/// be presented in the order the story is told, not on a timeline of years.
class NarrativeNode {
  final int id;
  final String slug;

  /// 'ramayana' | 'mahabharata'
  final String epic;

  /// Which retelling this scene belongs to. Recensions are never mixed into a
  /// single sequence: a Valmiki scene and a Ramcharitmanas scene are different
  /// tellings, not two halves of one.
  final String recension;

  final String? bookLabelEn;
  final String? bookLabelHi;
  final int? bookNo;
  final int sequenceNo;

  final String titleEn;
  final String? titleHi;
  final String descEn;
  final String? descHi;
  final String? longEn;
  final String? longHi;

  /// The one line of reflection this scene carries, if any.
  final String? lessonEn;
  final String? lessonHi;

  final int? placeEntityId;
  final int? scriptureSectionId;
  final String? imageAsset;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  /// Raw JSON array as stored. Kept unparsed because the only consumers match
  /// substrings (`war-day`, `commander:`), and parsing on every row of a
  /// timeline to do that would be wasted work.
  final String? tagsRaw;

  const NarrativeNode({
    required this.id,
    required this.slug,
    required this.epic,
    required this.recension,
    required this.sequenceNo,
    required this.titleEn,
    required this.descEn,
    this.bookLabelEn,
    this.bookLabelHi,
    this.bookNo,
    this.titleHi,
    this.descHi,
    this.longEn,
    this.longHi,
    this.lessonEn,
    this.lessonHi,
    this.placeEntityId,
    this.scriptureSectionId,
    this.imageAsset,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
    this.tagsRaw,
  });

  factory NarrativeNode.fromRow(Map<String, Object?> r) => NarrativeNode(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        epic: (r['epic'] as String?) ?? 'ramayana',
        recension: (r['recension'] as String?) ?? 'valmiki',
        bookLabelEn: r['book_label_en'] as String?,
        bookLabelHi: r['book_label_hi'] as String?,
        bookNo: r['book_no'] as int?,
        sequenceNo: (r['sequence_no'] as int?) ?? 0,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        longEn: r['long_description_en'] as String?,
        longHi: r['long_description_hi'] as String?,
        lessonEn: r['lesson_en'] as String?,
        lessonHi: r['lesson_hi'] as String?,
        placeEntityId: r['place_entity_id'] as int?,
        scriptureSectionId: r['scripture_section_id'] as int?,
        imageAsset: r['image_asset'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
        tagsRaw: r['tags'] as String?,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String desc(bool hi) =>
      (hi && (descHi?.isNotEmpty ?? false)) ? descHi! : descEn;
  String? long(bool hi) => (hi && (longHi?.isNotEmpty ?? false)) ? longHi : longEn;
  String? lesson(bool hi) =>
      (hi && (lessonHi?.isNotEmpty ?? false)) ? lessonHi : lessonEn;
  String? bookLabel(bool hi) =>
      (hi && (bookLabelHi?.isNotEmpty ?? false)) ? bookLabelHi : bookLabelEn;
}

/// A figure appearing in a scene, already resolved to their entity.
class CastMember {
  final int entityId;
  final String titleEn;
  final String? titleHi;
  final String? role;
  final String kind;

  const CastMember({
    required this.entityId,
    required this.titleEn,
    required this.kind,
    this.titleHi,
    this.role,
  });

  factory CastMember.fromRow(Map<String, Object?> r) => CastMember(
        entityId: (r['entity_id'] as int?) ?? 0,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        role: r['role'] as String?,
        kind: (r['kind'] as String?) ?? 'human',
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
}

/// Narrative arcs for the Mahabharata timeline.
///
/// Grouping by parva alone gives eighteen bands, most of them battle days.
/// These four are how the story is actually remembered.
class MahabharataArcs {
  MahabharataArcs._();

  /// (labelEn, labelHi, firstSequence, lastSequence)
  // Ranges follow narrative_nodes.sequence_no and MUST be updated whenever
  // scenes are inserted -- they were written for a twenty-scene path and
  // silently mislabelled every arc once it grew to twenty-nine.
  static const arcs = <(String, String, int, int)>[
    ('The House Divided', 'विभाजित कुल', 1, 7),
    ('The Dice and the Exile', 'द्यूत और वनवास', 8, 16),
    ('The War', 'युद्ध', 17, 24),
    ('After', 'पश्चात्', 25, 40),
  ];

  static (String, String)? arcFor(int seq) {
    for (final (en, hi, from, to) in arcs) {
      if (seq >= from && seq <= to) return (en, hi);
    }
    return null;
  }
}
