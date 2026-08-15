/// A dilemma the texts actually pose.
///
/// There is no score and no correct answer. Choices carry a `guna` tag, which
/// describes a quality of action, not a mark — the reference doc is explicit
/// that this is reflection, not moral authority, and the UI never renders a
/// tick or a cross.
class DharmaScenario {
  final int id;
  final String slug;
  final String titleEn;
  final String? titleHi;

  /// 'family' | 'duty' | 'truth' | 'war' | 'wealth'
  final String category;

  /// 1 (approachable) .. 3 (genuinely hard)
  final int difficulty;

  final String contextEn;
  final String? contextHi;
  final String reflectionEn;
  final String? reflectionHi;

  /// Mandatory. validate.py refuses a scenario without one.
  final String? disclaimerEn;
  final String? disclaimerHi;

  final int? basedOnNodeId;
  final String? tagsRaw;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  const DharmaScenario({
    required this.id,
    required this.slug,
    required this.titleEn,
    required this.category,
    required this.difficulty,
    required this.contextEn,
    required this.reflectionEn,
    this.titleHi,
    this.contextHi,
    this.reflectionHi,
    this.disclaimerEn,
    this.disclaimerHi,
    this.basedOnNodeId,
    this.tagsRaw,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory DharmaScenario.fromRow(Map<String, Object?> r) => DharmaScenario(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        category: (r['category'] as String?) ?? 'duty',
        difficulty: (r['difficulty'] as int?) ?? 2,
        contextEn: (r['context_en'] as String?) ?? '',
        contextHi: r['context_hi'] as String?,
        reflectionEn: (r['reflection_en'] as String?) ?? '',
        reflectionHi: r['reflection_hi'] as String?,
        disclaimerEn: r['disclaimer_en'] as String?,
        disclaimerHi: r['disclaimer_hi'] as String?,
        basedOnNodeId: r['based_on_node_id'] as int?,
        tagsRaw: r['tags'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String context(bool hi) =>
      (hi && (contextHi?.isNotEmpty ?? false)) ? contextHi! : contextEn;
  String reflection(bool hi) =>
      (hi && (reflectionHi?.isNotEmpty ?? false)) ? reflectionHi! : reflectionEn;
  String? disclaimer(bool hi) =>
      (hi && (disclaimerHi?.isNotEmpty ?? false)) ? disclaimerHi : disclaimerEn;
}

class DharmaChoice {
  final int id;
  final int scenarioId;
  final String choiceKey; // 'A'..'D'
  final String labelEn;
  final String? labelHi;
  final String consequenceEn;
  final String? consequenceHi;

  /// 'sattva' | 'rajas' | 'tamas', or null. A quality, never a grade.
  final String? guna;
  final int orderNo;

  const DharmaChoice({
    required this.id,
    required this.scenarioId,
    required this.choiceKey,
    required this.labelEn,
    required this.consequenceEn,
    required this.orderNo,
    this.labelHi,
    this.consequenceHi,
    this.guna,
  });

  factory DharmaChoice.fromRow(Map<String, Object?> r) => DharmaChoice(
        id: r['id'] as int,
        scenarioId: (r['scenario_id'] as int?) ?? 0,
        choiceKey: (r['choice_key'] as String?) ?? 'A',
        labelEn: (r['label_en'] as String?) ?? '',
        labelHi: r['label_hi'] as String?,
        consequenceEn: (r['consequence_en'] as String?) ?? '',
        consequenceHi: r['consequence_hi'] as String?,
        guna: r['guna'] as String?,
        orderNo: (r['order_no'] as int?) ?? 0,
      );

  String label(bool hi) =>
      (hi && (labelHi?.isNotEmpty ?? false)) ? labelHi! : labelEn;
  String consequence(bool hi) => (hi && (consequenceHi?.isNotEmpty ?? false))
      ? consequenceHi!
      : consequenceEn;
}

/// The five categories, with their bilingual labels.
const dharmaCategories = <(String, String, String)>[
  ('duty', 'Duty', 'कर्तव्य'),
  ('truth', 'Truth', 'सत्य'),
  ('family', 'Family', 'परिवार'),
  ('war', 'War', 'युद्ध'),
  ('wealth', 'Wealth', 'अर्थ'),
];

/// What a guna describes — stated in the UI so the tag is never mistaken for
/// a score.
const gunaLabels = <String, (String, String)>{
  'sattva': ('Sattva — clarity, restraint', 'सत्त्व — स्पष्टता, संयम'),
  'rajas': ('Rajas — drive, attachment', 'रजस् — गति, आसक्ति'),
  'tamas': ('Tamas — inertia, avoidance', 'तमस् — जड़ता, टालना'),
};
