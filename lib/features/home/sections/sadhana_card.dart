import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../sadhana/sadhana_models.dart' show kPractices;
import '../../sadhana/sadhana_providers.dart'
    show practicesDoneTodayProvider, sadhanaByDayProvider;
import '../../../core/user/user_prefs.dart' show dayStamp;
import '../../../shared/widgets/stitched_border.dart';

/// Home entry to the Sadhana hub. Says how many of today's practices are
/// done, because that is the one number a daily-practice tracker should lead
/// with — not a streak, which frames the whole thing as a score to protect.
class SadhanaCard extends ConsumerWidget {
  final bool hi;
  const SadhanaCard({super.key, required this.hi});

  static const _accent = AppColors.sacredGreen; // sage — this room's color
  static const _ring = Color(0xFF8FDDDF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(practicesDoneTodayProvider).valueOrNull ?? 0;
    final byDay = ref.watch(sadhanaByDayProvider).valueOrNull ?? const {};
    final total = kPractices.length;
    final today = dayStamp();
    final doneKeys = {
      for (final e in byDay.entries)
        if ((e.value[today] ?? 0) > 0) e.key,
    };
    final nextUp = [
      for (final p in kPractices)
        if (!doneKeys.contains(p.key)) p.label(hi),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/sadhana'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F5D6B), Color(0xFF16323C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomPaint(
          foregroundPainter: StitchedBorderPainter(
            color: _accent.withValues(alpha: 0.45),
            radius: 13,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              // A real ring showing done/total, not a static icon.
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: const AlwaysStoppedAnimation(_ring),
                      ),
                    ),
                    Text('$done/$total',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFFCEFE2))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hi ? 'आज का अभ्यास' : "Today's practice",
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Color(0xFFFCEFE2))),
                    const SizedBox(height: 7),
                    // A dot per practice — done ones filled — instead of a
                    // sentence spelling out the same count in words.
                    Row(
                      children: [
                        for (final p in kPractices)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: doneKeys.contains(p.key)
                                    ? _ring
                                    : Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextUp.isEmpty
                          ? (hi ? 'सभी अभ्यास पूर्ण 🎉' : 'All done today 🎉')
                          : '${hi ? 'शेष' : 'Next'}: ${nextUp.join(' · ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFFFCEFE2).withValues(alpha: 0.72)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8FDDDF)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
