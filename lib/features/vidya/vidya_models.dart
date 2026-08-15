/// A topic from the classical disciplines.
///
/// Two fields are load-bearing and neither is decoration. [caution] is NOT NULL
/// in the schema — validate.py fails the build without it, which is the §4.15
/// medical-advice rule enforced in the pipeline rather than in a review
/// checklist. [modernStatus] labels the claim honestly, including when the
/// honest label is `contested`.
class VidyaTopic {
  final int id;
  final String slug;

  /// 'ayurveda' | 'jyotisha' | 'shulba' | 'yoga' | 'vyakarana' | 'chandas'
  final String discipline;

  final String titleEn;
  final String? titleHi;
  final String descEn;
  final String? descHi;
  final String? longEn;
  final String? longHi;
  final String? useEn;
  final String? useHi;

  /// Required. A card must never render without it.
  final String cautionEn;
  final String? cautionHi;

  /// 'corroborated' | 'partially_corroborated' | 'not_evaluated' | 'contested'
  final String modernStatus;

  final String? tagsRaw;
  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  const VidyaTopic({
    required this.id,
    required this.slug,
    required this.discipline,
    required this.titleEn,
    required this.descEn,
    required this.cautionEn,
    required this.modernStatus,
    this.titleHi,
    this.descHi,
    this.longEn,
    this.longHi,
    this.useEn,
    this.useHi,
    this.cautionHi,
    this.tagsRaw,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory VidyaTopic.fromRow(Map<String, Object?> r) => VidyaTopic(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        discipline: (r['discipline'] as String?) ?? 'ayurveda',
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        longEn: r['long_description_en'] as String?,
        longHi: r['long_description_hi'] as String?,
        useEn: r['practical_use_en'] as String?,
        useHi: r['practical_use_hi'] as String?,
        cautionEn: (r['caution_en'] as String?) ?? '',
        cautionHi: r['caution_hi'] as String?,
        modernStatus: (r['modern_status'] as String?) ?? 'not_evaluated',
        tagsRaw: r['tags'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String desc(bool hi) =>
      (hi && (descHi?.isNotEmpty ?? false)) ? descHi! : descEn;
  String? long(bool hi) =>
      (hi && (longHi?.isNotEmpty ?? false)) ? longHi : longEn;
  String? use(bool hi) => (hi && (useHi?.isNotEmpty ?? false)) ? useHi : useEn;
  String caution(bool hi) =>
      (hi && (cautionHi?.isNotEmpty ?? false)) ? cautionHi! : cautionEn;

  /// True when this topic can legally render. Asserted in debug builds — a
  /// vidya card without its caution is a bug, not a styling choice.
  bool get hasCaution => cautionEn.trim().isNotEmpty;
}

/// The disciplines, in the order the tabs show them.
const vidyaDisciplines = <(String, String, String)>[
  ('ayurveda', 'Ayurveda', 'आयुर्वेद'),
  ('jyotisha', 'Jyotisha', 'ज्योतिष'),
  ('shulba', 'Ganita', 'गणित'),
  ('yoga', 'Yoga', 'योग'),
  ('vyakarana', 'Bhasha', 'भाषा'),
  ('chandas', 'Chandas', 'छंद'),
];

/// Deliberately unglamorous colours. The point of the chip is that the reader
/// sees at a glance how well supported a claim is, not that it looks good.
const modernStatusLabels = <String, (String, String)>{
  'corroborated': ('Corroborated', 'प्रमाणित'),
  'partially_corroborated': ('Partly corroborated', 'आंशिक प्रमाणित'),
  'not_evaluated': ('Not evaluated', 'अपरीक्षित'),
  'contested': ('Contested', 'विवादित'),
};

/// One plain line explaining what the label means, shown on the detail page so
/// the chip is never left to be interpreted on its own.
const modernStatusExplain = <String, (String, String)>{
  'corroborated': (
    'Independent evidence supports this.',
    'स्वतंत्र प्रमाण इसका समर्थन करते हैं।'
  ),
  'partially_corroborated': (
    'Parts of this are supported; other parts are not established.',
    'इसके कुछ अंश समर्थित हैं; अन्य स्थापित नहीं हैं।'
  ),
  'not_evaluated': (
    'This has not been tested by modern research, which is not the same as '
        'being false.',
    'आधुनिक शोध ने इसे परखा नहीं है — इसका अर्थ असत्य होना नहीं है।'
  ),
  'contested': (
    'This is disputed, or the evidence does not support it as stated.',
    'यह विवादित है, अथवा प्रमाण इसे इस रूप में समर्थन नहीं करते।'
  ),
};
