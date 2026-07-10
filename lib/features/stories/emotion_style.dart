import 'package:flutter/material.dart';

/// Visual identity + bilingual label for a story emotion tag.
class EmotionStyle {
  final String key;
  final String en;
  final String hi;
  final Color color;
  final IconData icon;
  const EmotionStyle(this.key, this.en, this.hi, this.color, this.icon);

  static const _all = <EmotionStyle>[
    EmotionStyle('anger', 'Anger', 'क्रोध', Color(0xFFC65B52), Icons.local_fire_department_rounded),
    EmotionStyle('joy', 'Joy', 'आनंद', Color(0xFFE0A82E), Icons.wb_sunny_rounded),
    EmotionStyle('fear', 'Fear', 'भय', Color(0xFF31507A), Icons.nightlight_rounded),
    EmotionStyle('peace', 'Peace', 'शांति', Color(0xFF3E9E9E), Icons.spa_rounded),
    EmotionStyle('faith', 'Faith', 'आस्था', Color(0xFF4C9A6E), Icons.volunteer_activism_rounded),
    EmotionStyle('love', 'Love', 'प्रेम', Color(0xFFC7607F), Icons.favorite_rounded),
  ];

  static EmotionStyle of(String key) {
    final k = key.trim().toLowerCase();
    for (final e in _all) {
      if (e.key == k) return e;
    }
    // graceful fallback for any other tag (courage, wisdom, devotion…)
    final label = key.isEmpty ? 'Other' : key[0].toUpperCase() + key.substring(1);
    return EmotionStyle(k, label, label, const Color(0xFF8A6D3B), Icons.auto_stories_rounded);
  }

  static List<EmotionStyle> get known => _all;
}
