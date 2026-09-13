import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

import 'temple_models.dart';

/// Opens a temple's location in the device's map app / browser.
///
/// A `geo:` (or Apple `maps://`) intent goes first: any installed map app,
/// including offline ones, can answer it without a network round-trip. The
/// curated web link and a plain search URL are fallbacks.
Future<bool> openTempleMap(Temple t) async {
  final candidates = <Uri>[];
  if (t.lat != null && t.lon != null) {
    final q = Uri.encodeComponent('${t.lat},${t.lon}(${t.name})');
    candidates.add(Platform.isIOS
        ? Uri.parse(
            'maps://?ll=${t.lat},${t.lon}&q=${Uri.encodeComponent(t.name(false))}')
        : Uri.parse('geo:${t.lat},${t.lon}?q=$q'));
  }
  if (t.mapsLink != null && t.mapsLink!.isNotEmpty) {
    candidates.add(Uri.parse(t.mapsLink!));
  }
  if (t.lat != null && t.lon != null) {
    candidates.add(Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${t.lat},${t.lon}'));
  }
  for (final uri in candidates) {
    if (await canLaunchUrl(uri)) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    }
  }
  return false;
}

/// Opens an arbitrary URL (temple website, tel:, etc.) externally.
Future<bool> launchExternal(String raw) async {
  final uri = Uri.parse(raw);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
