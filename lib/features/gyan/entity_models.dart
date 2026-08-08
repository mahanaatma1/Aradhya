import 'dart:convert';

/// A named thing in the knowledge graph: a deity, sage, weapon, symbol, place…
///
/// One table backs five presentations (Knowledge Graph, Family Tree, Rishis,
/// Astras, Symbols) because they are all *"a named thing with descriptions,
/// aliases, citations, and typed links to other named things"*. Modelling them
/// separately would guarantee drift — a sage entered twice would eventually
/// disagree with itself.
class Entity {
  final int id;
  final String slug;

  /// 'deity' | 'rishi' | 'weapon' | 'symbol' | 'place' | 'concept' | …
  final String kind;

  final String titleEn;
  final String? titleHi;

  /// Devanagari Sanskrit — deliberately distinct from [titleHi], which is
  /// Hindi. Conflating them would render Sanskrit where Hindi belongs.
  final String? titleSa;
  final String? titleIast;

  final String? category;
  final String descEn;
  final String? descHi;
  final String? longEn;
  final String? longHi;
  final String? region;
  final String? tradition;
  final List<String> tags;

  /// Kind-specific fields, validated at build time against
  /// `content/schema/kinds/entity.schema.json`.
  final Map<String, dynamic> props;

  final String? imageAsset;

  /// The Unicode character for symbols that have one (ॐ).
  final String? glyph;

  /// 1 (major) … 5 (minor). Drives search boost and list tiering.
  final int importance;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;
  final String verificationStatus;

  const Entity({
    required this.id,
    required this.slug,
    required this.kind,
    required this.titleEn,
    required this.descEn,
    this.titleHi,
    this.titleSa,
    this.titleIast,
    this.category,
    this.descHi,
    this.longEn,
    this.longHi,
    this.region,
    this.tradition,
    this.tags = const [],
    this.props = const {},
    this.imageAsset,
    this.glyph,
    this.importance = 3,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
    this.verificationStatus = 'unverified',
  });

  factory Entity.fromRow(Map<String, Object?> r) => Entity(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        kind: (r['kind'] as String?) ?? 'concept',
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        titleSa: r['title_sa'] as String?,
        titleIast: r['title_iast'] as String?,
        category: r['category'] as String?,
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        longEn: r['long_description_en'] as String?,
        longHi: r['long_description_hi'] as String?,
        region: r['region'] as String?,
        tradition: r['tradition'] as String?,
        tags: _list(r['tags']),
        props: _map(r['props']),
        imageAsset: r['image_asset'] as String?,
        glyph: r['glyph'] as String?,
        importance: (r['importance'] as int?) ?? 3,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
        verificationStatus:
            (r['verification_status'] as String?) ?? 'unverified',
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String desc(bool hi) =>
      (hi && (descHi?.isNotEmpty ?? false)) ? descHi! : descEn;
  String? long(bool hi) => (hi && (longHi?.isNotEmpty ?? false)) ? longHi : longEn;

  /// The line under the title: `कृष्णः · kṛṣṇa`, omitting whichever is absent.
  String? scriptLine() {
    final parts = [
      if (titleSa != null && titleSa!.isNotEmpty) titleSa!,
      if (titleIast != null && titleIast!.isNotEmpty) titleIast!,
    ];
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  static List<String> _list(Object? v) {
    if (v is! String || v.isEmpty) return const [];
    try {
      return (jsonDecode(v) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is! String || v.isEmpty) return const {};
    try {
      final d = jsonDecode(v);
      return d is Map<String, dynamic> ? d : const {};
    } catch (_) {
      return const {};
    }
  }
}

/// One typed edge out of an entity, already resolved to its target's name.
class EntityRelation {
  final String relType;
  final int dstId;
  final String dstSlug;
  final String dstTitleEn;
  final String? dstTitleHi;
  final String dstKind;
  final String? tradition;
  final String confidence;

  const EntityRelation({
    required this.relType,
    required this.dstId,
    required this.dstSlug,
    required this.dstTitleEn,
    required this.dstKind,
    this.dstTitleHi,
    this.tradition,
    this.confidence = 'high',
  });

  factory EntityRelation.fromRow(Map<String, Object?> r) => EntityRelation(
        relType: (r['rel_type'] as String?) ?? 'related_to',
        dstId: (r['dst_id'] as int?) ?? 0,
        dstSlug: (r['slug'] as String?) ?? '',
        dstTitleEn: (r['title_en'] as String?) ?? '',
        dstTitleHi: r['title_hi'] as String?,
        dstKind: (r['kind'] as String?) ?? 'concept',
        tradition: r['tradition'] as String?,
        confidence: (r['confidence'] as String?) ?? 'high',
      );

  String dstTitle(bool hi) =>
      (hi && (dstTitleHi?.isNotEmpty ?? false)) ? dstTitleHi! : dstTitleEn;

  /// Which section of the detail screen this edge belongs under.
  String get family => switch (relType) {
        'father_of' || 'mother_of' || 'child_of' || 'parent_of' ||
        'spouse_of' || 'sibling_of' || 'consort_of' =>
          'lineage',
        'guru_of' || 'disciple_of' => 'teaching',
        'wields' || 'wielded_by' || 'killed' || 'killed_by' ||
        'incarnation_of' || 'has_incarnation' || 'mount_of' || 'has_mount' =>
          'epic',
        'authored' || 'authored_by' || 'appears_in' || 'features' ||
        'mentioned_in' || 'mentions' =>
          'text',
        'located_in' || 'contains' || 'ruled_by' || 'ruled' ||
        'worshipped_at' || 'worships' =>
          'place',
        _ => 'general',
      };
}

/// Human labels for the relation vocabulary, in both languages.
///
/// Kept beside the model rather than in the database: these are UI strings, and
/// the vocabulary is small enough that a missing label should be a visible
/// fallback rather than a build failure.
class RelLabels {
  RelLabels._();

  static const _en = <String, String>{
    'father_of': 'Father of', 'mother_of': 'Mother of',
    'child_of': 'Child of', 'parent_of': 'Parent of',
    'spouse_of': 'Spouse', 'sibling_of': 'Sibling',
    'consort_of': 'Consort', 'guru_of': 'Teacher of',
    'disciple_of': 'Student of', 'wields': 'Wields',
    'wielded_by': 'Wielded by', 'killed': 'Slew', 'killed_by': 'Slain by',
    'incarnation_of': 'Avatara of', 'has_incarnation': 'Appears as',
    'mount_of': 'Mount of', 'has_mount': 'Mount',
    'authored': 'Composed', 'authored_by': 'Composed by',
    'appears_in': 'Appears in', 'features': 'Features',
    'mentioned_in': 'Mentioned in', 'mentions': 'Mentions',
    'located_in': 'Located in', 'contains': 'Contains',
    'ruled_by': 'Ruled by', 'ruled': 'Ruled',
    'worshipped_at': 'Worshipped at', 'worships': 'Worships',
    'related_to': 'Related to', 'symbol_of': 'Symbol of',
    'has_symbol': 'Symbol', 'associated_with': 'Associated with',
    'part_of': 'Part of', 'has_part': 'Includes',
  };

  static const _hi = <String, String>{
    'father_of': 'पिता', 'mother_of': 'माता',
    'child_of': 'संतान', 'parent_of': 'जनक',
    'spouse_of': 'जीवनसाथी', 'sibling_of': 'भाई-बहन',
    'consort_of': 'सहचर', 'guru_of': 'गुरु',
    'disciple_of': 'शिष्य', 'wields': 'आयुध',
    'wielded_by': 'धारक', 'killed': 'वध किया', 'killed_by': 'वध हुआ',
    'incarnation_of': 'अवतार', 'has_incarnation': 'अवतार रूप',
    'mount_of': 'वाहन', 'has_mount': 'वाहन',
    'authored': 'रचना', 'authored_by': 'रचयिता',
    'appears_in': 'उल्लेख', 'features': 'पात्र',
    'mentioned_in': 'वर्णित', 'mentions': 'वर्णन',
    'located_in': 'स्थित', 'contains': 'समाहित',
    'ruled_by': 'शासक', 'ruled': 'शासन',
    'worshipped_at': 'पूजित', 'worships': 'पूजा',
    'related_to': 'संबंधित', 'symbol_of': 'प्रतीक',
    'has_symbol': 'चिह्न', 'associated_with': 'संबद्ध',
    'part_of': 'अंश', 'has_part': 'सम्मिलित',
  };

  static String of(String relType, bool hi) =>
      (hi ? _hi[relType] : _en[relType]) ??
      relType.replaceAll('_', ' ');

  static String familyLabel(String family, bool hi) => switch (family) {
        'lineage' => hi ? 'परिवार' : 'Family',
        'teaching' => hi ? 'गुरु-शिष्य' : 'Teaching',
        'epic' => hi ? 'महाकाव्य' : 'In the epics',
        'text' => hi ? 'ग्रंथ' : 'Texts',
        'place' => hi ? 'स्थान' : 'Places',
        _ => hi ? 'अन्य' : 'Related',
      };
}

/// Display metadata per entity kind.
class EntityKinds {
  EntityKinds._();

  static const labelsEn = <String, String>{
    'deity': 'Deity', 'avatar': 'Avatara', 'rishi': 'Rishi', 'king': 'King',
    'asura': 'Asura', 'human': 'Figure', 'place': 'Place', 'river': 'River',
    'mountain': 'Mountain', 'scripture': 'Scripture', 'festival': 'Festival',
    'weapon': 'Astra', 'symbol': 'Symbol', 'concept': 'Concept',
    'dynasty': 'Dynasty', 'yuga': 'Yuga', 'loka': 'Loka', 'vidya': 'Vidya',
  };

  static const labelsHi = <String, String>{
    'deity': 'देवता', 'avatar': 'अवतार', 'rishi': 'ऋषि', 'king': 'राजा',
    'asura': 'असुर', 'human': 'पात्र', 'place': 'स्थान', 'river': 'नदी',
    'mountain': 'पर्वत', 'scripture': 'ग्रंथ', 'festival': 'पर्व',
    'weapon': 'अस्त्र', 'symbol': 'प्रतीक', 'concept': 'तत्त्व',
    'dynasty': 'वंश', 'yuga': 'युग', 'loka': 'लोक', 'vidya': 'विद्या',
  };

  static String label(String kind, bool hi) =>
      (hi ? labelsHi[kind] : labelsEn[kind]) ?? kind;
}
