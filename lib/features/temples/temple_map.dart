import 'package:url_launcher/url_launcher.dart';

import 'temple_models.dart';

/// Opens a temple's location in the device's map app / browser. Prefers the
/// curated Google-Maps link; falls back to a geo query from its coordinates.
Future<bool> openTempleMap(Temple t) async {
  final candidates = <Uri>[];
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
