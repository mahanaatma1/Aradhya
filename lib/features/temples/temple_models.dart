import 'dart:convert';

/// A festival celebrated at a temple.
class TempleFestival {
  final String nameEn;
  final String? nameHi;
  final String? noteEn;
  final String? noteHi;
  const TempleFestival(this.nameEn, this.nameHi, this.noteEn, this.noteHi);

  String name(bool hi) => (hi && (nameHi?.isNotEmpty ?? false)) ? nameHi! : nameEn;
  String? note(bool hi) => (hi && (noteHi?.isNotEmpty ?? false)) ? noteHi : noteEn;
}

/// A scheduled aarti (name + time).
class TempleAarti {
  final String time; // "06:30"
  final String nameEn;
  final String? nameHi;
  const TempleAarti(this.time, this.nameEn, this.nameHi);

  String name(bool hi) => (hi && (nameHi?.isNotEmpty ?? false)) ? nameHi! : nameEn;
}

/// A temple in the Yatra directory. Typed columns cover the essentials; the
/// richer visitor info (address, timings, travel, festivals…) is parsed from
/// the bundled `data` JSON blob.
class Temple {
  final int id;
  final String nameEn;
  final String? nameHi;
  final String? deityEn;
  final String? deityHi;
  final String? locationEn;
  final String? significanceEn;
  final String? significanceHi;
  final List<String> tags;
  final String? state;
  final String? district;
  final double? lat;
  final double? lon;

  // Parsed from the data JSON.
  final String? mapsLink;
  final String? altNamesEn;
  final String? altNamesHi;
  final String? addressEn;
  final String? addressHi;
  final String? hoursEn;
  final String? hoursHi;
  final String? darshanEn;
  final String? darshanHi;
  final String? entryFeeEn;
  final String? entryFeeHi;
  final String? dressCodeEn;
  final String? dressCodeHi;
  final String? bestSeasonEn;
  final String? bestSeasonHi;
  final String? weatherEn;
  final String? weatherHi;
  final String? architectureEn;
  final String? architectureHi;
  final String? foundingEraEn;
  final String? foundingEraHi;
  final String? airportName;
  final int? airportKm;
  final String? railwayName;
  final int? railwayKm;
  final String? busStandName;
  final int? busStandKm;
  final String? localTransportEn;
  final String? localTransportHi;
  final String? parkingEn;
  final String? parkingHi;
  final String? nearbyEn;
  final String? nearbyHi;
  final String? bestTimeEn;
  final String? bestTimeHi;
  final String? photographyEn;
  final String? photographyHi;
  final String? website;
  final String? helpline;
  final List<TempleAarti> aartiSchedule;
  final List<TempleFestival> festivals;

  const Temple({
    required this.id,
    required this.nameEn,
    this.nameHi,
    this.deityEn,
    this.deityHi,
    this.locationEn,
    this.significanceEn,
    this.significanceHi,
    this.tags = const [],
    this.state,
    this.district,
    this.lat,
    this.lon,
    this.mapsLink,
    this.altNamesEn,
    this.altNamesHi,
    this.addressEn,
    this.addressHi,
    this.hoursEn,
    this.hoursHi,
    this.darshanEn,
    this.darshanHi,
    this.entryFeeEn,
    this.entryFeeHi,
    this.dressCodeEn,
    this.dressCodeHi,
    this.bestSeasonEn,
    this.bestSeasonHi,
    this.weatherEn,
    this.weatherHi,
    this.architectureEn,
    this.architectureHi,
    this.foundingEraEn,
    this.foundingEraHi,
    this.airportName,
    this.airportKm,
    this.railwayName,
    this.railwayKm,
    this.busStandName,
    this.busStandKm,
    this.localTransportEn,
    this.localTransportHi,
    this.parkingEn,
    this.parkingHi,
    this.nearbyEn,
    this.nearbyHi,
    this.bestTimeEn,
    this.bestTimeHi,
    this.photographyEn,
    this.photographyHi,
    this.website,
    this.helpline,
    this.aartiSchedule = const [],
    this.festivals = const [],
  });

  factory Temple.fromRow(Map<String, Object?> r) {
    final rawCat = (r['category'] as String?) ?? '';
    final tags = rawCat
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    Map<String, Object?> data = const {};
    final rawData = r['data'];
    if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, Object?>) data = decoded;
      } catch (_) {}
    }

    String? en(String key) => _lang(data[key], 'en');
    String? hi(String key) => _lang(data[key], 'hi');

    // timings.{hours,darshan}
    final timings = data['timings'];
    String? tim(String sub, String lang) => (timings is Map)
        ? _lang((timings)[sub], lang)
        : null;
    // visitInfo.{entryFee,dressCode}
    final visit = data['visitInfo'];
    String? vis(String sub, String lang) =>
        (visit is Map) ? _lang((visit)[sub], lang) : null;
    // travel.{airport,railway}
    final travel = data['travel'];
    ({String? name, int? km}) leg(String sub) {
      if (travel is! Map) return (name: null, km: null);
      final node = travel[sub];
      if (node is! Map) return (name: null, km: null);
      final nm = _lang(node['name'], 'en');
      final km = node['distanceKm'];
      return (name: nm, km: km is num ? km.toInt() : null);
    }

    final air = leg('airport');
    final rail = leg('railway');
    final bus = leg('busStand');
    String? trav(String sub, String lang) =>
        (travel is Map) ? _lang(travel[sub], lang) : null;

    // timings.aarti (schedule) + timings.bestTimeOfDay
    final aartiList = <TempleAarti>[];
    if (timings is Map && timings['aarti'] is List) {
      for (final a in timings['aarti'] as List) {
        if (a is Map) {
          aartiList.add(TempleAarti(
            (a['time'] ?? '').toString(),
            _lang(a['name'], 'en') ?? '',
            _lang(a['name'], 'hi'),
          ));
        }
      }
    }

    // links.{website,helpline}
    final links = data['links'];
    String? link(String key) =>
        (links is Map && links[key] is String) ? links[key] as String : null;

    final festList = <TempleFestival>[];
    final rawFest = data['festivals'];
    if (rawFest is List) {
      for (final f in rawFest) {
        if (f is Map) {
          festList.add(TempleFestival(
            _lang(f['name'], 'en') ?? '',
            _lang(f['name'], 'hi'),
            _lang(f['note'], 'en'),
            _lang(f['note'], 'hi'),
          ));
        }
      }
    }

    return Temple(
      id: r['id'] as int,
      nameEn: (r['name_en'] ?? '') as String,
      nameHi: r['name_hi'] as String?,
      deityEn: r['deity_en'] as String?,
      deityHi: r['deity_hi'] as String?,
      locationEn: r['location_en'] as String?,
      significanceEn: r['significance_en'] as String?,
      significanceHi: r['significance_hi'] as String?,
      tags: tags,
      state: r['state'] as String?,
      district: r['district'] as String?,
      lat: (r['lat'] as num?)?.toDouble(),
      lon: (r['lon'] as num?)?.toDouble(),
      mapsLink: data['link'] as String?,
      altNamesEn: en('altNames'),
      altNamesHi: hi('altNames'),
      addressEn: en('address'),
      addressHi: hi('address'),
      hoursEn: tim('hours', 'en'),
      hoursHi: tim('hours', 'hi'),
      darshanEn: tim('darshan', 'en'),
      darshanHi: tim('darshan', 'hi'),
      entryFeeEn: vis('entryFee', 'en'),
      entryFeeHi: vis('entryFee', 'hi'),
      dressCodeEn: vis('dressCode', 'en'),
      dressCodeHi: vis('dressCode', 'hi'),
      bestSeasonEn: en('bestSeason'),
      bestSeasonHi: hi('bestSeason'),
      weatherEn: en('weatherNote'),
      weatherHi: hi('weatherNote'),
      architectureEn: en('architecture'),
      architectureHi: hi('architecture'),
      foundingEraEn: en('foundingEra'),
      foundingEraHi: hi('foundingEra'),
      airportName: air.name,
      airportKm: air.km,
      railwayName: rail.name,
      railwayKm: rail.km,
      busStandName: bus.name,
      busStandKm: bus.km,
      localTransportEn: trav('localTransport', 'en'),
      localTransportHi: trav('localTransport', 'hi'),
      parkingEn: trav('parking', 'en'),
      parkingHi: trav('parking', 'hi'),
      nearbyEn: en('nearbyTemples'),
      nearbyHi: hi('nearbyTemples'),
      bestTimeEn: tim('bestTimeOfDay', 'en'),
      bestTimeHi: tim('bestTimeOfDay', 'hi'),
      photographyEn: vis('photographyNote', 'en'),
      photographyHi: vis('photographyNote', 'hi'),
      website: link('website'),
      helpline: link('helpline'),
      aartiSchedule: aartiList,
      festivals: festList,
    );
  }

  String name(bool hi) => (hi && (nameHi?.isNotEmpty ?? false)) ? nameHi! : nameEn;
  String? deity(bool hi) =>
      (hi && (deityHi?.isNotEmpty ?? false)) ? deityHi : deityEn;
  String? significance(bool hi) =>
      (hi && (significanceHi?.isNotEmpty ?? false))
          ? significanceHi
          : significanceEn;
  String? altNames(bool hi) =>
      (hi && (altNamesHi?.isNotEmpty ?? false)) ? altNamesHi : altNamesEn;
  String? address(bool hi) =>
      (hi && (addressHi?.isNotEmpty ?? false)) ? addressHi : addressEn;
  String? hours(bool hi) =>
      (hi && (hoursHi?.isNotEmpty ?? false)) ? hoursHi : hoursEn;
  String? darshan(bool hi) =>
      (hi && (darshanHi?.isNotEmpty ?? false)) ? darshanHi : darshanEn;
  String? entryFee(bool hi) =>
      (hi && (entryFeeHi?.isNotEmpty ?? false)) ? entryFeeHi : entryFeeEn;
  String? dressCode(bool hi) =>
      (hi && (dressCodeHi?.isNotEmpty ?? false)) ? dressCodeHi : dressCodeEn;
  String? bestSeason(bool hi) =>
      (hi && (bestSeasonHi?.isNotEmpty ?? false)) ? bestSeasonHi : bestSeasonEn;
  String? weather(bool hi) =>
      (hi && (weatherHi?.isNotEmpty ?? false)) ? weatherHi : weatherEn;
  String? architecture(bool hi) =>
      (hi && (architectureHi?.isNotEmpty ?? false))
          ? architectureHi
          : architectureEn;
  String? foundingEra(bool hi) =>
      (hi && (foundingEraHi?.isNotEmpty ?? false))
          ? foundingEraHi
          : foundingEraEn;
  String? localTransport(bool hi) =>
      (hi && (localTransportHi?.isNotEmpty ?? false))
          ? localTransportHi
          : localTransportEn;
  String? parking(bool hi) =>
      (hi && (parkingHi?.isNotEmpty ?? false)) ? parkingHi : parkingEn;
  String? nearby(bool hi) =>
      (hi && (nearbyHi?.isNotEmpty ?? false)) ? nearbyHi : nearbyEn;
  String? bestTime(bool hi) =>
      (hi && (bestTimeHi?.isNotEmpty ?? false)) ? bestTimeHi : bestTimeEn;
  String? photography(bool hi) =>
      (hi && (photographyHi?.isNotEmpty ?? false))
          ? photographyHi
          : photographyEn;

  /// A short "District, State" line for cards.
  String get place =>
      [district, state].where((e) => e != null && e.isNotEmpty).join(', ');

  /// The primary classification tag (first listed).
  String get primaryTag => tags.isEmpty ? 'other' : tags.first;
}

/// Read a bilingual `{en, hi}` node (or a plain string) for [lang].
String? _lang(Object? node, String lang) {
  if (node == null) return null;
  if (node is String) return node.isEmpty ? null : node;
  if (node is Map) {
    final v = node[lang] ?? node['en'];
    if (v is String) return v.isEmpty ? null : v;
  }
  return null;
}

/// A human label for a raw category tag ("char_dham" → "Char Dham").
String tagLabel(String tag) => tag
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Pull a concise "1559 CE" style year out of a founding-era paragraph.
String? establishedYear(String? era) {
  if (era == null) return null;
  final m = RegExp(r'(\d{3,4})\s*(BCE|CE|AD|BC)?', caseSensitive: false)
      .firstMatch(era);
  if (m == null) return null;
  final year = m.group(1);
  final suffix = m.group(2);
  return suffix != null ? '$year ${suffix.toUpperCase()}' : year;
}

const _months = {
  'january': 'Jan', 'february': 'Feb', 'march': 'Mar', 'april': 'Apr',
  'may': 'May', 'june': 'Jun', 'july': 'Jul', 'august': 'Aug',
  'september': 'Sep', 'october': 'Oct', 'november': 'Nov', 'december': 'Dec',
};

/// Turn "October to March" → "Oct–Mar"; falls back to the raw string.
String? shortSeason(String? season) {
  if (season == null) return null;
  final found = <String>[];
  for (final w in season.toLowerCase().split(RegExp(r'[^a-z]+'))) {
    final abbr = _months[w];
    if (abbr != null) found.add(abbr);
  }
  if (found.length >= 2) return '${found.first}–${found.last}';
  if (found.length == 1) return found.first;
  return season.length <= 12 ? season : null;
}
