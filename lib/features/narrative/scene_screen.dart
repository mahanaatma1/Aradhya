import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import '../related/related_rail.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';

/// One scene, shared by both epics.
///
/// The Ramayana journey and the Mahabharata timeline are two presentations of
/// the same table, so they open the same detail screen — one implementation to
/// keep correct, and a scene looks the same wherever you arrived from.
class SceneScreen extends ConsumerStatefulWidget {
  final int sceneId;
  const SceneScreen({super.key, required this.sceneId});

  @override
  ConsumerState<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends ConsumerState<SceneScreen> {
  @override
  void initState() {
    super.initState();
    // Opening a scene marks it read. Anything stricter would be guessing at
    // whether someone finished reading, and this is a story, not a course.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(epicProgressProvider.notifier).markRead(widget.sceneId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final value = ref.watch(sceneByIdProvider(widget.sceneId));

    return Scaffold(
      body: AsyncView(
        value: value,
        isEmpty: (s) => s == null,
        emptyMessage: hi ? 'यह दृश्य नहीं मिला' : 'Scene not found',
        builder: (scene) => _Body(scene: scene!, hindi: hi),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  const _Body({required this.scene, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cast = ref.watch(sceneCastProvider(scene.id)).valueOrNull ?? const [];
    final siblings =
        ref.watch(epicScenesProvider(scene.epic)).valueOrNull ?? const [];

    final idx = siblings.indexWhere((s) => s.id == scene.id);
    final prev = idx > 0 ? siblings[idx - 1] : null;
    final next =
        idx >= 0 && idx < siblings.length - 1 ? siblings[idx + 1] : null;

    final lesson = scene.lesson(hindi);
    final long = scene.long(hindi);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 150,
          backgroundColor: const Color(0xFF4A3220),
          foregroundColor: const Color(0xFFFFF8EF),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8A6A4F), Color(0xFF4A3220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${scene.bookLabel(hindi) ?? ""}  ·  ${scene.sequenceNo}',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldBright.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.title(hindi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 25,
                        height: 1.12,
                        color: Color(0xFFFFF8EF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scene.desc(hindi),
                    style: const TextStyle(fontSize: 16.5, height: 1.6)),
                if (long != null && long.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(long,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.62,
                          color:
                              scheme.onSurface.withValues(alpha: 0.82))),
                ],
                if (lesson != null && lesson.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _LessonPanel(text: lesson, hindi: hindi),
                ],
                const SizedBox(height: 16),
                SourceChip(
                  hindi: hindi,
                  sourceName: scene.sourceName,
                  sourceRef: scene.sourceRef,
                  sourceUrl: scene.sourceUrl,
                  lastVerifiedAt: scene.lastVerifiedAt,
                ),
                if (cast.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    hindi ? 'पात्र' : 'WHO IS HERE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in cast)
                        _CastChip(member: c, hindi: hindi),
                    ],
                  ),
                ],
                if (scene.scriptureSectionId != null) ...[
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/search?q=${scene.titleEn}'),
                    icon: const Icon(Icons.menu_book_rounded, size: 17),
                    label: Text(hindi ? 'मूल पाठ पढ़ें' : 'Read the passage'),
                  ),
                ],
                const SizedBox(height: 22),
                _PrevNext(prev: prev, next: next, hindi: hindi),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RelatedRail(
              src: 'gyan', table: 'narrative_nodes', id: scene.id),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

/// The reflection, set apart from the narration.
///
/// Kept visually distinct for the same reason the entity screen separates
/// symbolism from description: a reader should be able to tell what the text
/// says from what it is being taken to mean.
class _LessonPanel extends StatelessWidget {
  final String text;
  final bool hindi;
  const _LessonPanel({required this.text, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.kraft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hindi ? 'इस प्रसंग से' : 'FROM THIS SCENE',
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A6A2E),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.accent,
              fontSize: 16,
              height: 1.55,
              color: AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CastChip extends StatelessWidget {
  final CastMember member;
  final bool hindi;
  const _CastChip({required this.member, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLead = member.role == 'protagonist';

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/gyan/entity/${member.entityId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isLead
              ? const Color(0xFF8A6A4F).withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLead
                ? const Color(0xFF8A6A4F).withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          member.title(hindi),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isLead ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PrevNext extends StatelessWidget {
  final NarrativeNode? prev;
  final NarrativeNode? next;
  final bool hindi;
  const _PrevNext({required this.prev, required this.next, required this.hindi});

  @override
  Widget build(BuildContext context) {
    if (prev == null && next == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (prev != null)
          Expanded(
            child: _NavCard(
              scene: prev!,
              hindi: hindi,
              label: hindi ? 'पिछला' : 'Previous',
              alignEnd: false,
            ),
          ),
        if (prev != null && next != null) const SizedBox(width: 10),
        if (next != null)
          Expanded(
            child: _NavCard(
              scene: next!,
              hindi: hindi,
              label: hindi ? 'अगला' : 'Next',
              alignEnd: true,
            ),
          ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final NarrativeNode scene;
  final bool hindi;
  final String label;
  final bool alignEnd;

  const _NavCard({
    required this.scene,
    required this.hindi,
    required this.label,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      // `pushReplacement` so walking an epic does not build a stack thirty
      // scenes deep that Back has to unwind one at a time.
      onTap: () => context.pushReplacement('/gyan/scene/${scene.id}'),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.45))),
            const SizedBox(height: 3),
            Text(
              scene.title(hindi),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
