import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../mandir/mandir_models.dart';
import '../../../shared/widgets/stitched_border.dart';

/// Home entry to the shrine. Says whether the offering window is open, because
/// that is the only thing about the Mandir that changes hour to hour.
class MandirCard extends StatelessWidget {
  final bool hi;
  const MandirCard({super.key, required this.hi});

  @override
  Widget build(BuildContext context) {
    final free = MandirWindows.isFree();
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/mandir'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A251F), Color(0xFF241713)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(
          foregroundPainter: StitchedBorderPainter(
            color: const Color(0xFFE8B347).withValues(alpha: 0.45),
            radius: 13,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              // A living diya rather than a static temple icon — a warm glow
              // when the offering window is open, dimmed when it is not, so
              // the one thing that actually changes hour to hour is visible
              // before a reader even reads the caption.
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (free)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFFE8B347).withValues(alpha: 0.35),
                            const Color(0xFFE8B347).withValues(alpha: 0),
                          ]),
                        ),
                      ),
                    Text('🪔',
                        style: TextStyle(
                            fontSize: 28,
                            color: free
                                ? null
                                : Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hi ? 'मंदिर' : 'Mandir',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: Color(0xFFFCEFE2))),
                    const SizedBox(height: 3),
                    Text(
                      free
                          ? (hi
                              ? 'अर्पण का समय खुला है'
                              : 'The offering window is open')
                          : (hi ? 'दर्शन करें' : 'Visit the shrine'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: free
                            ? const Color(0xFFE8B347)
                            : const Color(0xFFFCEFE2).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE6C34A)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
