import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/reference_art.dart';

/// A color-coded emotion for the Stories grid.
class StoryEmotion {
  final String en;
  final String hi;
  final Color color;
  const StoryEmotion(this.en, this.hi, this.color);
}

const storyEmotions = <StoryEmotion>[
  StoryEmotion('Anger', 'क्रोध', Color(0xFFC0392B)),
  StoryEmotion('Joy', 'आनंद', Color(0xFFDDA000)),
  StoryEmotion('Peace', 'शांति', Color(0xFF2E8B8B)),
  StoryEmotion('Love', 'प्रेम', Color(0xFFD9748C)),
  StoryEmotion('Fear', 'भय', Color(0xFF4A4A8A)),
  StoryEmotion('Faith', 'श्रद्धा', Color(0xFF5E8C74)),
];

class StoryTile extends StatelessWidget {
  final String label;
  final String en;
  final Color color;
  final VoidCallback onTap;
  const StoryTile({super.key, required this.label,
      required this.en,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = emotionImage(en);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null)
                  Image.asset(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
                // Scrim so the label stays legible over the art.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.72),
                        color.withValues(alpha: 0.30),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
