import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'temple_models.dart';

/// The reference app tints temple cards with a rotating gold→rose→teal palette
/// by position. Ids are sequential and the list is ordered by id, so keying the
/// tint off `id` reproduces that rotation exactly (Dwarka gold, Badrinath rose,
/// Jagannath teal) while staying stable between the list and the detail screen.
const _rotation = <Color>[
  AppColors.gold,
  AppColors.deityRose,
  AppColors.sacredGreen,
];

Color templeTint(Temple t) => _rotation[(t.id - 1) % _rotation.length];

/// A semantic colour for a category chip (Char Dham→green, Moksha/Jyotirlinga→
/// gold, Shakti→rose, Healing→blue, else neutral ink).
Color tagChipColor(String tag, ColorScheme scheme) {
  final t = tag.toLowerCase();
  if (t.contains('healing') || t.contains('ailment')) return const Color(0xFF3E6DA8);
  if (t.contains('shakti')) return AppColors.deityRose;
  if (t.contains('char_dham')) return AppColors.sacredGreen;
  if (t.contains('jyotirlinga') || t.contains('moksha') || t.contains('divya')) {
    return const Color(0xFF9A7233);
  }
  return scheme.onSurface.withValues(alpha: 0.6);
}

/// A soft, tag-coloured chip used on cards and the detail hero.
class TagChip extends StatelessWidget {
  final String tag;
  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = tagChipColor(tag, scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(tagLabel(tag),
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: c)),
    );
  }
}
