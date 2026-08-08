import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../search/search_models.dart';
import 'journey_models.dart';
import 'journey_providers.dart';

/// One journey, as a vertical stepped path.
///
/// Steps are **not locked**. Progress is shown, the next step is offered, and
/// every step stays open — someone who came to read the Gita today should not
/// have to earn it. The pull is "you are 4 of 12 in", never "you may not
/// proceed".
class JourneyDetailScreen extends ConsumerWidget {
  final int pathId;
  const JourneyDetailScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final paths = ref.watch(learningPathsProvider).valueOrNull ?? const [];
    final path = paths.where((p) => p.id == pathId).firstOrNull;
    final stepsAsync = ref.watch(pathStepsProvider(pathId));
    final progress = ref.watch(pathProgressProvider);
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final accent = cats.scriptures.gradient.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(path?.title(hi) ?? (hi ? 'यात्रा' : 'Journey')),
        actions: [
          if (progress.any((e) => e.$1 == pathId))
            IconButton(
              tooltip: hi ? 'प्रगति रीसेट करें' : 'Reset progress',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () =>
                  ref.read(pathProgressProvider.notifier).clearPath(pathId),
            ),
        ],
      ),
      body: AsyncView(
        value: stepsAsync,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'इस यात्रा में कोई चरण नहीं' : 'No steps in this journey',
        builder: (steps) {
          final done = progress.where((e) => e.$1 == pathId).length;
          final next = ref
              .read(pathProgressProvider.notifier)
              .nextStep(pathId, steps);

          return Column(
            children: [
              if (path != null)
                _Header(path: path, hindi: hi, done: done, total: steps.length,
                    accent: accent),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  itemCount: steps.length,
                  itemBuilder: (context, i) {
                    final s = steps[i];
                    final isDone = progress.contains((pathId, s.stepNo));
                    return _StepTile(
                      step: s,
                      hindi: hi,
                      isDone: isDone,
                      isNext: s.stepNo == next,
                      isLast: i == steps.length - 1,
                      accent: accent,
                      onOpen: () {
                        // Marked on open rather than on some proof of reading.
                        // Anything stricter would be guessing, and a journey is
                        // a reading list, not an exam.
                        ref
                            .read(pathProgressProvider.notifier)
                            .markDone(pathId, s.stepNo);
                        context.push(s.route);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final LearningPath path;
  final bool hindi;
  final int done;
  final int total;
  final Color accent;
  const _Header({
    required this.path,
    required this.hindi,
    required this.done,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(path.desc(hindi),
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.72))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              backgroundColor: scheme.outline.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hindi ? '$done / $total चरण पूर्ण' : '$done of $total steps done',
            style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final PathStep step;
  final bool hindi;
  final bool isDone;
  final bool isNext;
  final bool isLast;
  final Color accent;
  final VoidCallback onOpen;

  const _StepTile({
    required this.step,
    required this.hindi,
    required this.isDone,
    required this.isNext,
    required this.isLast,
    required this.accent,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final ks = SearchKinds.of(step.kind);
    final blurb = step.blurb(hindi);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The path spine: filled node when done, ringed when next.
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? accent : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? accent
                        : (isNext
                            ? accent
                            : scheme.outline.withValues(alpha: 0.4)),
                    width: isNext && !isDone ? 2.2 : 1.4,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: Colors.white)
                    : Center(
                        child: Text('${step.stepNo}',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isNext
                                    ? accent
                                    : scheme.onSurface
                                        .withValues(alpha: 0.55)))),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: isDone
                        ? accent.withValues(alpha: 0.45)
                        : scheme.outline.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNext
                          ? accent.withValues(alpha: 0.45)
                          : scheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(ks.icon,
                              size: 14,
                              color: ks
                                  .style(cats)
                                  .gradient
                                  .last
                                  .withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Text(
                            (hindi ? ks.hi : ks.en).toUpperCase(),
                            style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.45)),
                          ),
                          const Spacer(),
                          if (step.estMinutes != null)
                            Text(
                              '${step.estMinutes} ${hindi ? 'मिनट' : 'min'}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.45)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.title(hindi),
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.22,
                        ),
                      ),
                      if (blurb != null && blurb.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          blurb,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurface.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
