import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';

/// The featured "Discover Your Soul Path" personality-test card.
/// An invitation to the personality quiz, not a settings-style row — the
/// gradient, the large serif title and the pill CTA are meant to read like
/// the opener screen of the quiz itself, so tapping in feels like starting
/// something rather than merely navigating.
class SoulPathCard extends StatelessWidget {
  final bool hi;
  final VoidCallback onTap;
  const SoulPathCard({super.key, required this.hi, required this.onTap});

  static const _questionCount = 8;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.dharmaPurple, Color(0xFF3B2A63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // A faint oversized glyph bleeding off the corner — the same
              // "quiet ornament" trick the app already uses on hero cards,
              // so this reads as a considered surface, not a flat banner.
              Positioned(
                right: -8,
                bottom: -14,
                child: Opacity(
                  opacity: 0.12,
                  child: Text('☾',
                      style: TextStyle(
                          fontSize: 92,
                          fontFamily: AppFonts.display,
                          color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        (hi
                                ? 'व्यक्तित्व · 2 मिनट'
                                : 'Personality · 2 min')
                            .toUpperCase(),
                        style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.72))),
                    const SizedBox(height: 6),
                    Text(
                        hi
                            ? 'अपना आध्यात्मिक\nमार्ग जानें'
                            : 'Discover Your\nSoul Path',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            height: 1.15,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                        hi
                            ? 'त्रिगुण पर आधारित 8 प्रश्न'
                            : '8 questions, rooted in the three gunas',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.78))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            _questionCount,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            hi
                                ? '$_questionCount प्रश्न'
                                : '$_questionCount questions',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hi ? 'शुरू करें' : 'Begin',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: Colors.white)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
