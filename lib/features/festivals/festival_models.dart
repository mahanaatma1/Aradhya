/// A festival as stored: the RULE, never a date.
///
/// The tradition fixes a lunar month, a paksha and a tithi (or, for a handful,
/// a solar ingress). The date those resolve to moves every year and differs by
/// location, so storing a date would be wrong by the next release. The panchang
/// engine already in the app resolves the rule instead.
class Festival {
  final int id;
  final String slug;
  final String titleEn;
  final String? titleHi;
  final String? titleSa;

  /// 'major' | 'vrat' | 'jayanti' | 'regional'
  final String category;

  /// Purnimanta lunar month name, lowercased ('kartika'), or null for solar.
  final String? lunarMonth;

  /// 'shukla' | 'krishna' | null
  final String? paksha;

  /// 1..15 within the paksha.
  final int? tithi;

  /// Free text for the festivals the sun fixes rather than the moon.
  final String? solarRule;

  /// Comma-separated region keys. NOT NULL by schema: several of these fall on
  /// different tithis, or carry different names, in different parts of India,
  /// and a list that flattens that is wrong for most of its readers.
  final String region;
  final String? tradition;

  final int? deityEntityId;
  final int? storyNodeId;

  final String descEn;
  final String? descHi;
  final String? ritualEn;
  final String? ritualHi;
  final String? fastEn;
  final String? fastHi;
  final String? tagsRaw;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  const Festival({
    required this.id,
    required this.slug,
    required this.titleEn,
    required this.category,
    required this.region,
    required this.descEn,
    this.titleHi,
    this.titleSa,
    this.lunarMonth,
    this.paksha,
    this.tithi,
    this.solarRule,
    this.tradition,
    this.deityEntityId,
    this.storyNodeId,
    this.descHi,
    this.ritualEn,
    this.ritualHi,
    this.fastEn,
    this.fastHi,
    this.tagsRaw,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory Festival.fromRow(Map<String, Object?> r) => Festival(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        titleSa: r['title_sa'] as String?,
        category: (r['category'] as String?) ?? 'major',
        lunarMonth: r['lunar_month'] as String?,
        paksha: r['paksha'] as String?,
        tithi: r['tithi'] as int?,
        solarRule: r['solar_rule'] as String?,
        region: (r['region'] as String?) ?? 'pan-india',
        tradition: r['tradition'] as String?,
        deityEntityId: r['deity_entity_id'] as int?,
        storyNodeId: r['story_node_id'] as int?,
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        ritualEn: r['ritual_summary_en'] as String?,
        ritualHi: r['ritual_summary_hi'] as String?,
        fastEn: r['fast_rules_en'] as String?,
        fastHi: r['fast_rules_hi'] as String?,
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
  String? ritual(bool hi) =>
      (hi && (ritualHi?.isNotEmpty ?? false)) ? ritualHi : ritualEn;
  String? fast(bool hi) =>
      (hi && (fastHi?.isNotEmpty ?? false)) ? fastHi : fastEn;

  bool get isSolar => solarRule != null && lunarMonth == null;

  /// Regions this festival is kept in, as display-ready keys.
  List<String> get regions =>
      region.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  bool get isPanIndia => regions.contains('pan-india');
}

/// A festival resolved to an actual date for a given year and location.
class ResolvedFestival {
  final Festival festival;
  final DateTime date;

  const ResolvedFestival(this.festival, this.date);

  int daysFrom(DateTime today) =>
      DateTime(date.year, date.month, date.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
}
