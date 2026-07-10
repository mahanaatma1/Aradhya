import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'panchang_engine.dart';

class PanchangLocation {
  final double lat;
  final double lon;
  final String name;
  final bool isGps;
  const PanchangLocation(this.lat, this.lon, this.name, {this.isGps = false});
}

/// Selected calendar date (defaults to today). Time component is ignored.
final panchangDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// First-of-month currently shown in the Full Calendar.
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month);
});

/// Manual fallback location (New Delhi) used until/unless GPS resolves.
final panchangLocationProvider = StateProvider<PanchangLocation>(
  (ref) => const PanchangLocation(28.6139, 77.2090, 'New Delhi'),
);

/// Lunar-month naming convention: false = Purnimanta (North India, default),
/// true = Amanta (South/West India).
final amantaSystemProvider = StateProvider<bool>((ref) => false);

/// Best-effort device GPS location. Returns null if permission denied or
/// location services are off (the manual fallback is used instead).
final deviceLocationProvider = FutureProvider<PanchangLocation?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return PanchangLocation(pos.latitude, pos.longitude, 'GPS Location',
        isGps: true);
  } catch (_) {
    return null;
  }
});

/// The location actually used: GPS if available, else the manual fallback.
final effectiveLocationProvider = Provider<PanchangLocation>((ref) {
  final gps = ref.watch(deviceLocationProvider).valueOrNull;
  return gps ?? ref.watch(panchangLocationProvider);
});

/// Computed panchang for the selected date + effective location.
final panchangProvider = Provider<Panchang>((ref) {
  final date = ref.watch(panchangDateProvider);
  final loc = ref.watch(effectiveLocationProvider);
  final amanta = ref.watch(amantaSystemProvider);
  return computePanchang(
    date: date,
    lat: loc.lat,
    lonEast: loc.lon,
    tzOffset: DateTime.now().timeZoneOffset,
    amanta: amanta,
  );
});
