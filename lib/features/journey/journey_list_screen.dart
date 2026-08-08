import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'journey_models.dart';
import 'journey_providers.dart';

/// Guided paths — the answer to "where do I start?".
///
/// Everything else in the app is lookup: it assumes you already know what to
/// search for. This is the one surface that assumes you do not.
class JourneyListScreen extends ConsumerWidget {
  const JourneyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final paths = ref.watch(learningPathsProvider);
    final progress = ref.watch(pathProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'ज्ञान यात्रा' : 'Knowledge Journeys')),
      body: AsyncView(
        value: paths,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई यात्रा नहीं' : 'No journeys yet',
        builder: (list) {
          // In-progress paths float to the top: resuming is the common case
          // once someone has started anything.
          final counts = {
            for (final p in list)
              p.id: progress.where((e) => e.$1 == p.id).length,
          };
          final sorted = [...list]..sort((a, b) {
              final aStarted = (counts[a.id] ?? 0) > 0;
              final bStarted = (counts[b.id] ?? 0) > 0;
              if (aStarted != bStarted) return aStarted ? -1 : 1;
              return a.orderNo.compareTo(b.orderNo);
            });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              if (i == 0) return _Intro(hi: hi);
              final p = sorted[i - 1];
              return _PathCard(
                path: p,
                hindi: hi,
                completed: counts[p.id] ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final bool hi;
  const _Intro({required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        hi
            ? 'हर यात्रा उन्हीं पाठों की एक क्रमबद्ध सूची है जो ऐप में पहले से हैं। कोई चरण बंद नहीं — क्रम सुझाव है, नियम नहीं।'
            : 'Each journey is an ordered reading list over content already in the app. Nothing is locked — the order is a suggestion, not a rule.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: scheme.onSurface.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _PathCard extends ConsumerWidget {
  final LearningPath path;
  final bool hindi;
  final int completed;
  const _PathCard({
    required this.path,
    required this.hindi,
    required this.completed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final accent = cats.scriptures.gradient.last;

    final steps = ref.watch(pathStepsProvider(path.id)).valueOrNull ?? const [];
    final total = steps.length;
    final pct = total == 0 ? 0.0 : completed / total;
    final started = completed > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/journey/${path.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: started
                  ? accent.withValues(alpha: 0.45)
                  : scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LevelChip(label: path.levelLabel(hindi), accent: accent),
                const SizedBox(width: 8),
                if (total > 0)
                  Text(
                    hindi ? '$total चरण' : '$total steps',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                if (path.estMinutes != null) ...[
                  const SizedBox(width: 8),
                  Text('· ${path.estMinutes} ${hindi ? 'मिनट' : 'min'}',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
                const Spacer(),
                if (total > 0)
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 3,
                          backgroundColor:
                              scheme.outline.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                        Text('$completed',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              path.title(hindi),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              path.desc(hindi),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            if (started && completed < total) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    hindi
                        ? 'जारी रखें — चरण ${completed + 1} / $total'
                        : 'Continue — step ${completed + 1} of $total',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: accent),
                  ),
                ],
              ),
            ],
            if (total > 0 && completed == total) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFF25533F)),
                  const SizedBox(width: 6),
                  Text(hindi ? 'पूर्ण' : 'Completed',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF25533F))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final Color accent;
  const _LevelChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: accent)),
      );
}
