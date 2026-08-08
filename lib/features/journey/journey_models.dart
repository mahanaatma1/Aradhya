/// A guided reading path.
///
/// A journey is a **curated playlist over content that already exists** — every
/// step points at a row in one of the two databases via `(src, ref_table,
/// ref_id)` and carries the route to open it. Authoring one costs a curation
/// decision and a one-line "why this step", not new prose.
class LearningPath {
  final int id;
  final String slug;
  final String titleEn;
  final String? titleHi;

  /// 'beginner' | 'core' | 'deeper'
  final String level;
  final String descEn;
  final String? descHi;
  final int? estMinutes;
  final String? coverAsset;
  final int orderNo;

  const LearningPath({
    required this.id,
    required this.slug,
    required this.titleEn,
    required this.level,
    required this.descEn,
    required this.orderNo,
    this.titleHi,
    this.descHi,
    this.estMinutes,
    this.coverAsset,
  });

  factory LearningPath.fromRow(Map<String, Object?> r) => LearningPath(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        level: (r['level'] as String?) ?? 'beginner',
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        estMinutes: r['est_minutes'] as int?,
        coverAsset: r['cover_asset'] as String?,
        orderNo: (r['order_no'] as int?) ?? 0,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String desc(bool hi) =>
      (hi && (descHi?.isNotEmpty ?? false)) ? descHi! : descEn;

  String levelLabel(bool hi) => switch (level) {
        'core' => hi ? 'मुख्य' : 'Core',
        'deeper' => hi ? 'गहन' : 'Deeper',
        _ => hi ? 'प्रारंभ' : 'Beginner',
      };
}

class PathStep {
  final int id;
  final int pathId;
  final int stepNo;
  final String titleEn;
  final String? titleHi;

  /// One line on why this step sits here — the only genuinely new writing a
  /// journey requires.
  final String? blurbEn;
  final String? blurbHi;

  final String src;
  final String refTable;
  final int refId;
  final String route;
  final int? estMinutes;
  final bool optional;

  const PathStep({
    required this.id,
    required this.pathId,
    required this.stepNo,
    required this.titleEn,
    required this.src,
    required this.refTable,
    required this.refId,
    required this.route,
    this.titleHi,
    this.blurbEn,
    this.blurbHi,
    this.estMinutes,
    this.optional = false,
  });

  factory PathStep.fromRow(Map<String, Object?> r) => PathStep(
        id: r['id'] as int,
        pathId: r['path_id'] as int,
        stepNo: r['step_no'] as int,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        blurbEn: r['blurb_en'] as String?,
        blurbHi: r['blurb_hi'] as String?,
        src: (r['src'] as String?) ?? 'content',
        refTable: (r['ref_table'] as String?) ?? '',
        refId: (r['ref_id'] as int?) ?? 0,
        route: (r['route'] as String?) ?? '',
        estMinutes: r['est_minutes'] as int?,
        optional: (r['optional'] as int?) == 1,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String? blurb(bool hi) =>
      (hi && (blurbHi?.isNotEmpty ?? false)) ? blurbHi : blurbEn;

  /// Maps a step to the glyph its content type uses elsewhere in the app, so a
  /// journey step and a search result for the same row look related.
  String get kind => switch (refTable) {
        'scripture_books' || 'scripture_sections' => 'shloka',
        'temples' => 'temple',
        'mantras' => 'mantra',
        'aartis' => 'aarti',
        'chalisas' => 'chalisa',
        'stories' => 'story',
        'kathas' => 'katha',
        'puja_vidhi' => 'puja',
        'entities' => 'entity',
        'festivals' => 'festival',
        'narrative_nodes' => 'scene',
        _ => 'story',
      };
}
