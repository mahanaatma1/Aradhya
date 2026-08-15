import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/reading_progress.dart';
import 'scripture_providers.dart';

/// "Your reading" block on the You tab (P3-15).
class YourReadingSection extends ConsumerWidget {
  const YourReadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final progressMap = ref.watch(readingProgressProvider);
    if (progressMap.isEmpty) return const SizedBox.shrink();

    final stats = ref.read(readingProgressProvider.notifier).stats();
    final scriptures = ref.watch(scripturesProvider).asData?.value ?? [];
    final scheme = Theme.of(context).colorScheme;

    String scriptureName(int id) {
      for (final s in scriptures) {
        if (s.id == id) return s.name(hi);
      }
      return hi ? 'ग्रंथ' : 'Scripture';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hi ? 'आपका पाठ' : 'YOUR READING',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${stats.totalVersesRead}',
                        label: hi ? 'श्लोक पढ़े' : 'Verses read',
                        icon: Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        value: '${stats.dayStreak}',
                        label: hi ? 'पाठ की श्रृंखला' : 'Reading streak',
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                  ],
                ),
                if (stats.byScripture.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final row in stats.byScripture.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  scriptureName(row.scriptureId),
                                  style: const TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                row.versesTotal > 0
                                    ? '${(row.fraction * 100).round()}%'
                                    : '${row.versesRead}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: row.versesTotal > 0 ? row.fraction : null,
                              minHeight: 4,
                              backgroundColor:
                                  scheme.outline.withValues(alpha: 0.15),
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/scriptures'),
                    child: Text(hi ? 'ग्रंथ खोलें' : 'Open scriptures'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatTile(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
