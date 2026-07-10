import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'astro_chart.dart';

class City {
  final String name;
  final String state;
  final double lat;
  final double lon;
  final double utcOffset;
  const City(this.name, this.state, this.lat, this.lon, this.utcOffset);
  String get label => state.isEmpty ? name : '$name, $state';
}

class BirthDetails {
  final String name;
  final DateTime dob; // local civil date-time at the birth place
  final double lat;
  final double lon;
  final double utcOffset; // hours (e.g. 5.5 for IST)
  final String place;
  const BirthDetails({
    required this.name,
    required this.dob,
    required this.lat,
    required this.lon,
    required this.utcOffset,
    required this.place,
  });

  DateTime get utc =>
      dob.subtract(Duration(minutes: (utcOffset * 60).round()));

  Map<String, Object?> toJson() => {
        'name': name,
        'dob': dob.toIso8601String(),
        'lat': lat,
        'lon': lon,
        'utcOffset': utcOffset,
        'place': place,
      };

  factory BirthDetails.fromJson(Map<String, Object?> j) => BirthDetails(
        name: (j['name'] ?? '') as String,
        dob: DateTime.parse(j['dob'] as String),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        utcOffset: (j['utcOffset'] as num).toDouble(),
        place: (j['place'] ?? '') as String,
      );
}

/// The current birth details. Hydrated from local storage at startup so the
/// personalized Kundli/Rashifal survives an app restart; null until the user
/// first submits the form. Persisted in [BirthFormScreen._submit].
final birthDetailsProvider = StateProvider<BirthDetails?>((ref) {
  final raw = ref.read(sharedPrefsProvider).getString(PrefKeys.birthDetails);
  if (raw == null) return null;
  try {
    return BirthDetails.fromJson(jsonDecode(raw) as Map<String, Object?>);
  } catch (_) {
    return null;
  }
});

/// City search over the bundled 4276-city table.
final citySearchProvider =
    FutureProvider.family<List<City>, String>((ref, query) async {
  final q = query.trim();
  if (q.length < 2) return const [];
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query(
    'cities',
    where: 'name LIKE ?',
    whereArgs: ['$q%'],
    orderBy: 'name',
    limit: 30,
  );
  return rows
      .map((r) => City(
            (r['name'] ?? '') as String,
            (r['state'] ?? '') as String,
            (r['lat'] as num).toDouble(),
            (r['lon'] as num).toDouble(),
            (r['utc_offset'] as num?)?.toDouble() ?? 5.5,
          ))
      .toList();
});

/// The computed chart for the current birth details (null if none yet).
final chartProvider = Provider<BirthChart?>((ref) {
  final b = ref.watch(birthDetailsProvider);
  if (b == null) return null;
  return computeChart(b.utc, b.lat, b.lon);
});
