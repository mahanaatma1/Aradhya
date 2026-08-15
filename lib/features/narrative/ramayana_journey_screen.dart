import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';

/// The Ramayana as a walked path.
///
/// Deliberately not a chapter list: the Ramayana is a journey with a direction,
/// and reading it as a route down a page carries that better than a table of
/// contents. Scenes alternate either side of a dashed track — the same stitched
/// motif used throughout the app.
class RamayanaJourneyScreen extends ConsumerWidget {
  const RamayanaJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scenes = ref.watch(epicScenesProvider('ramayana'));
    final progress = ref.watch(epicProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'रामायण यात्रा' : 'Ramayana Journey'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AsyncView(
        value: scenes,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई दृश्य नहीं' : 'No scenes yet',
        builder: (list) {
          final next = ref.read(epicProgressProvider.notifier).nextIn(list);
          final done = list.where((s) => progress.contains(s.id)).length;

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
                itemCount: list.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _Header(done: done, total: list.length, hindi: hi);
                  }
                  final scene = list[i - 1];
                  final prev = i >= 2 ? list[i - 2] : null;
                  final newKanda = prev?.bookNo != scene.bookNo;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (newKanda)
                        _KandaBanner(
                            label: scene.bookLabel(hi) ?? '', hindi: hi),
                      _SceneRow(
                        scene: scene,
                        hindi: hi,
                        read: progress.contains(scene.id),
                        isNext: next?.id == scene.id,
                        left: (i - 1).isEven,
                        isLast: i == list.length,
                      ),
                    ],
                  );
                },
              ),
              if (next != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/gyan/scene/${next.id}'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 19),
                      label: Text(done == 0
                          ? (hi ? 'यात्रा आरंभ करें' : 'Begin the journey')
                          : (hi ? 'जारी रखें' : 'Continue')),
                    ),
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
  final int done;
  final int total;
  final bool hindi;
  const _Header(
      {required this.done, required this.total, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hindi
                ? 'वाल्मीकि रामायण के सात कांड, दृश्य दर दृश्य।'
                : 'The seven kandas of the Valmiki Ramayana, scene by scene.',
            style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.68)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 5,
              backgroundColor: scheme.outline.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF8A6A4F)),
            ),
          ),
          const SizedBox(height: 5),
          Text('$done / $total ${hindi ? "दृश्य" : "scenes"}',
              style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _KandaBanner extends StatelessWidget {
  final String label;
  final bool hindi;
  const _KandaBanner({required this.label, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFF8A6A4F).withValues(alpha: 0.35))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF8A6A4F),
              ),
            ),
          ),
          Expanded(
              child: Container(
                  height: 1,
                  color: const Color(0xFF8A6A4F).withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

/// One scene, offset to one side of the dashed path.
class _SceneRow extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  final bool read;
  final bool isNext;
  final bool left;
  final bool isLast;

  const _SceneRow({
    required this.scene,
    required this.hindi,
    required this.read,
    required this.isNext,
    required this.left,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cast = ref.watch(sceneCastProvider(scene.id)).valueOrNull ?? const [];
    final scheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF8A6A4F);

    final card = _SceneCard(
      scene: scene,
      hindi: hindi,
      read: read,
      isNext: isNext,
      cast: cast,
    );

    final node = Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: read ? accent : Colors.transparent,
            border: Border.all(
              color: read || isNext
                  ? accent
                  : scheme.outline.withValues(alpha: 0.45),
              width: isNext && !read ? 2.2 : 1.4,
            ),
          ),
          child: read
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
        if (!isLast)
          // The dashed track between scenes — the stitched motif, vertical.
          SizedBox(
            width: 20,
            height: 54,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: read
                    ? accent.withValues(alpha: 0.6)
                    : scheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: left
            ? [Expanded(child: card), const SizedBox(width: 10), node,
                const SizedBox(width: 10), const Spacer()]
            : [const Spacer(), const SizedBox(width: 10), node,
                const SizedBox(width: 10), Expanded(child: card)],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const dash = 4.0, gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _SceneCard extends StatelessWidget {
  final NarrativeNode scene;
  final bool hindi;
  final bool read;
  final bool isNext;
  final List<CastMember> cast;

  const _SceneCard({
    required this.scene,
    required this.hindi,
    required this.read,
    required this.isNext,
    required this.cast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF8A6A4F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/gyan/scene/${scene.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: read
                ? AppColors.kraft.withValues(alpha: 0.5)
                : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNext
                  ? accent.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.18),
              width: isNext ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${scene.sequenceNo}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: accent.withValues(alpha: 0.8))),
              const SizedBox(height: 3),
              Text(
                scene.title(hindi),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                scene.desc(hindi),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              if (cast.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    for (final c in cast.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(c.title(hindi),
                            style: const TextStyle(
                                fontSize: 10, color: accent)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
