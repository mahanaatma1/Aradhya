import 'dart:convert';

/// One node of the Puranic cosmology: a creation stage, a loka, a yuga, or a
/// unit of cosmic time.
///
/// Four tracks share one table because they are the same shape — an ordered,
/// optionally nested description with a citation — and because the Yuga
/// Explorer and the Srishty Universe are two views of one cosmology, not two
/// datasets.
class CosmologyNode {
  final int id;
  final String slug;

  /// 'creation' | 'loka' | 'time_cycle' | 'yuga'
  final String track;

  final int? parentId;
  final int orderNo;

  final String titleEn;
  final String? titleHi;
  final String? titleSa;

  final String descEn;
  final String? descHi;
  final String? longEn;
  final String? longHi;

  /// TEXT, not a number: a kalpa is 4,320,000,000 years and the life of Brahma
  /// is 311 trillion — past what an int64 can hold once multiplied out.
  final String? durationYears;

  final Map<String, dynamic> attributes;
  final int? entityId;
  final String? tradition;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  const CosmologyNode({
    required this.id,
    required this.slug,
    required this.track,
    required this.orderNo,
    required this.titleEn,
    required this.descEn,
    this.parentId,
    this.titleHi,
    this.titleSa,
    this.descHi,
    this.longEn,
    this.longHi,
    this.durationYears,
    this.attributes = const {},
    this.entityId,
    this.tradition,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory CosmologyNode.fromRow(Map<String, Object?> r) => CosmologyNode(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        track: (r['track'] as String?) ?? 'loka',
        parentId: r['parent_id'] as int?,
        orderNo: (r['order_no'] as int?) ?? 0,
        titleEn: (r['title_en'] as String?) ?? '',
        titleHi: r['title_hi'] as String?,
        titleSa: r['title_sa'] as String?,
        descEn: (r['short_description_en'] as String?) ?? '',
        descHi: r['short_description_hi'] as String?,
        longEn: r['long_description_en'] as String?,
        longHi: r['long_description_hi'] as String?,
        durationYears: r['duration_years'] as String?,
        attributes: _map(r['attributes']),
        entityId: r['entity_id'] as int?,
        tradition: r['tradition'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
      );

  String title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi! : titleEn;
  String desc(bool hi) =>
      (hi && (descHi?.isNotEmpty ?? false)) ? descHi! : descEn;
  String? long(bool hi) => (hi && (longHi?.isNotEmpty ?? false)) ? longHi : longEn;

  /// 'upper' | 'lower' for lokas; null otherwise.
  String? get band => attributes['band'] as String?;

  /// The age the tradition places the present in.
  bool get isPresent => attributes['present'] == true;

  /// Dharma as a fraction, e.g. [3, 4] for Treta.
  (int, int)? get dharmaRatio {
    final v = attributes['dharma_ratio'];
    if (v is List && v.length == 2) {
      final a = (v[0] as num?)?.toInt();
      final b = (v[1] as num?)?.toInt();
      if (a != null && b != null && b != 0) return (a, b);
    }
    return null;
  }

  /// Duration as a double for proportional layout, or null when unparseable.
  double? get durationValue {
    final raw = durationYears?.replaceAll(',', '').trim();
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
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

/// Track labels.
class CosmologyTracks {
  CosmologyTracks._();

  static const order = ['creation', 'loka', 'time_cycle'];

  static String label(String track, bool hi) => switch (track) {
        'creation' => hi ? 'सृष्टि' : 'Creation',
        'loka' => hi ? 'लोक' : 'Lokas',
        'time_cycle' => hi ? 'काल' : 'Time',
        'yuga' => hi ? 'युग' : 'Yugas',
        _ => track,
      };
}
