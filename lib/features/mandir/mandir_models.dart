import 'package:flutter/material.dart';

import '../../shared/reference_art.dart';

/// Something that can be offered at the home shrine.
class Offering {
  final String key;
  final String labelEn;
  final String labelHi;
  final IconData icon;

  /// Optional artwork; when null the icon is used.
  final String? image;

  /// Kamal charged **outside** the free windows. Inside them, every offering
  /// is free — see [MandirWindows].
  final int cost;

  final Color color;

  const Offering({
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.icon,
    required this.cost,
    required this.color,
    this.image,
  });

  String label(bool hi) => hi ? labelHi : labelEn;
}

final kOfferings = <Offering>[
  Offering(
    key: 'diya',
    labelEn: 'Diya',
    labelHi: 'दीया',
    icon: Icons.local_fire_department_rounded,
    image: diyaOnImage,
    cost: 2,
    color: const Color(0xFFE0762A),
  ),
  const Offering(
    key: 'flower',
    labelEn: 'Flower',
    labelHi: 'पुष्प',
    icon: Icons.local_florist_rounded,
    cost: 2,
    color: Color(0xFFC7567F),
  ),
  Offering(
    key: 'bhog',
    labelEn: 'Bhog',
    labelHi: 'भोग',
    icon: Icons.rice_bowl_rounded,
    image: bhogImage,
    cost: 3,
    color: const Color(0xFFB48B3E),
  ),
  const Offering(
    key: 'dhoop',
    labelEn: 'Incense',
    labelHi: 'धूप',
    icon: Icons.air_rounded,
    cost: 2,
    color: Color(0xFF3E7C8C),
  ),
];

/// The traditional windows for morning and evening worship.
///
/// Inside a window, offerings cost nothing — the app should never charge for
/// showing up at the hour the tradition actually asks you to. Kamal is a nudge
/// toward the rhythm, not a toll on devotion.
class MandirWindows {
  MandirWindows._();

  /// (startHour, endHour) in local time, end exclusive.
  static const morning = (4, 12);
  static const evening = (18, 21);

  static bool isFree([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    return (h >= morning.$1 && h < morning.$2) ||
        (h >= evening.$1 && h < evening.$2);
  }

  /// Which window is open now, or null.
  static String? openWindow([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h >= morning.$1 && h < morning.$2) return 'morning';
    if (h >= evening.$1 && h < evening.$2) return 'evening';
    return null;
  }

  /// When the next free window opens. Used to tell the user *when* to come
  /// back rather than only that they are too late.
  static DateTime nextOpening([DateTime? at]) {
    final now = at ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Durations built at runtime: record fields cannot be read in a const
    // expression.
    final candidates = [
      today.add(Duration(hours: morning.$1)),
      today.add(Duration(hours: evening.$1)),
      today.add(Duration(days: 1, hours: morning.$1)),
    ];
    return candidates.firstWhere((c) => c.isAfter(now));
  }
}
