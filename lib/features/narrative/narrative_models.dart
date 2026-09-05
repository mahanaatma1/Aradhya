import 'dart:convert';

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

  // ---- Story Cards (SC-01) ------------------------------------------
  // Every field here is nullable. Scenes written before the migration carry
  // none of it, and the UI falls back to what they do have rather than
  // rendering an empty section.

  /// The middle level between a kanda/parva and an event.
  final String? arcSlug;
  final String? arcTitleEn;
  final String? arcTitleHi;
  final int? arcNo;

  /// The 30-second read. Distinct from [descEn], which is a card blurb and is
  /// often a fragment rather than a summary.
  final String? quickEn;
  final String? quickHi;

  /// The narrative proper.
  final String? storyEn;
  final String? storyHi;

  /// Raw JSON arrays of 3-6 beats, parsed only when the event page opens.
  final String? keyMomentsRawEn;
  final String? keyMomentsRawHi;

  /// A question, not a moral. [lessonEn] is the deprecated predecessor.
  final String? reflectionEn;
  final String? reflectionHi;

  /// Raw JSON array of theme slugs.
  final String? themesRaw;

  final String? illustrationAsset;

  /// Denormalised at build time, so paging costs no query. Chained within one
  /// (epic, recension) only -- a Valmiki scene never pages into another
  /// telling.
  final int? prevNodeId;
  final int? nextNodeId;

  /// NR-01: whether [sequenceNo] is a narrative order or a historical one.
  /// 'traditional' | 'disputed' | 'confirmed' -- see the column comment in
  /// `gyan.sql`. Defaults to 'traditional', which every scene authored so far
  /// actually is: an order the text hands down, not a dated event.
  final String chronologyConfidence;

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
    this.arcSlug,
    this.arcTitleEn,
    this.arcTitleHi,
    this.arcNo,
    this.quickEn,
    this.quickHi,
    this.storyEn,
    this.storyHi,
    this.keyMomentsRawEn,
    this.keyMomentsRawHi,
    this.reflectionEn,
    this.reflectionHi,
    this.themesRaw,
    this.illustrationAsset,
    this.prevNodeId,
    this.nextNodeId,
    this.chronologyConfidence = 'traditional',
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
        arcSlug: r['arc_slug'] as String?,
        arcTitleEn: r['arc_title_en'] as String?,
        arcTitleHi: r['arc_title_hi'] as String?,
        arcNo: r['arc_no'] as int?,
        quickEn: r['quick_summary_en'] as String?,
        quickHi: r['quick_summary_hi'] as String?,
        storyEn: r['story_en'] as String?,
        storyHi: r['story_hi'] as String?,
        keyMomentsRawEn: r['key_moments_en'] as String?,
        keyMomentsRawHi: r['key_moments_hi'] as String?,
        reflectionEn: r['reflection_en'] as String?,
        reflectionHi: r['reflection_hi'] as String?,
        themesRaw: r['themes'] as String?,
        illustrationAsset: r['illustration_asset'] as String?,
        prevNodeId: r['prev_node_id'] as int?,
        nextNodeId: r['next_node_id'] as int?,
        chronologyConfidence:
            (r['chronology_confidence'] as String?) ?? 'traditional',
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
  String? arcTitle(bool hi) =>
      (hi && (arcTitleHi?.isNotEmpty ?? false)) ? arcTitleHi : arcTitleEn;
  String? quickSummary(bool hi) =>
      (hi && (quickHi?.isNotEmpty ?? false)) ? quickHi : quickEn;

  /// The narrative body, falling back to the long description for scenes
  /// written before Story Cards existed.
  String? story(bool hi) {
    final s = (hi && (storyHi?.isNotEmpty ?? false)) ? storyHi : storyEn;
    return (s?.isNotEmpty ?? false) ? s : long(hi);
  }

  /// A question where one is written; otherwise the deprecated lesson, so an
  /// older scene still has something to say rather than showing nothing.
  String? reflection(bool hi) {
    final r =
        (hi && (reflectionHi?.isNotEmpty ?? false)) ? reflectionHi : reflectionEn;
    return (r?.isNotEmpty ?? false) ? r : lesson(hi);
  }

  List<String> keyMoments(bool hi) {
    final raw =
        (hi && (keyMomentsRawHi?.isNotEmpty ?? false))
            ? keyMomentsRawHi
            : keyMomentsRawEn;
    return _stringList(raw);
  }

  List<String> get themes => _stringList(themesRaw);

  static List<String> _stringList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final v = jsonDecode(raw);
      if (v is List) {
        return [
          for (final x in v)
            if (x is String && x.isNotEmpty) x,
        ];
      }
    } on FormatException {
      // Malformed JSON in a content column must not take the screen down.
    }
    return const [];
  }
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
