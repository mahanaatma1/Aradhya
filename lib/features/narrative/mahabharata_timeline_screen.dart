import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';

/// The Mahabharata as a horizontal timeline.
///
/// Same table and same detail screen as the Ramayana journey — only the
/// presentation differs. The Ramayana is a journey with a direction, so it
/// reads as a path down the page; the Mahabharata is a chain of consequences
/// across four arcs, so it reads along one.
///
/// The band is **narrative order**, never dates. Placing these events on a
/// calendar would assert a chronology the sources do not support.
class MahabharataTimelineScreen extends ConsumerStatefulWidget {
  const MahabharataTimelineScreen({super.key});

  @override
  ConsumerState<MahabharataTimelineScreen> createState() =>
      _MahabharataTimelineScreenState();
}

class _MahabharataTimelineScreenState
    extends ConsumerState<MahabharataTimelineScreen> {
  String? _arcFilter;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scenes = ref.watch(epicScenesProvider('mahabharata'));
    final progress = ref.watch(epicProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'महाभारत कालक्रम' : 'Mahabharata Timeline'),
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
        emptyMessage: hi ? 'अभी कोई घटना नहीं' : 'No events yet',
        builder: (all) {
          final list = _arcFilter == null
              ? all
              : all
                  .where((s) =>
                      MahabharataArcs.arcFor(s.sequenceNo)?.$1 == _arcFilter)
                  .toList();

          return Column(
            children: [
              _ArcChips(
                selected: _arcFilter,
                hindi: hi,
                onSelected: (a) => setState(() => _arcFilter = a),
              ),
              _NarrativeOrderNote(hindi: hi),
              _EighteenDaysLink(hindi: hi),
              Expanded(
                child: _Band(
                  scenes: list,
                  hindi: hi,
                  read: progress,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// States plainly that this is story order, not history. The reference doc
/// asks for it, and a timeline invites exactly the wrong assumption otherwise.
class _NarrativeOrderNote extends StatelessWidget {
  final bool hindi;
  const _NarrativeOrderNote({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 13, color: scheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hindi
                  ? 'यह कथा-क्रम है, तिथि-क्रम नहीं।'
                  : 'This is narrative order, not a historical chronology.',
              style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcChips extends StatelessWidget {
  final String? selected;
  final bool hindi;
  final ValueChanged<String?> onSelected;

  const _ArcChips({
    required this.selected,
    required this.hindi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String? value, String label) {
      final on = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: (_) => onSelected(on ? null : value),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? scheme.primary : scheme.onSurface.withValues(alpha: .8),
          ),
          selectedColor: scheme.primary.withValues(alpha: 0.14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(null, hindi ? 'सब' : 'All'),
          for (final (en, hiLabel, _, _) in MahabharataArcs.arcs)
            chip(en, hindi ? hiLabel : en),
        ],
      ),
    );
  }
}

/// The horizontal spine, with arc bands above it.
class _Band extends StatelessWidget {
  final List<NarrativeNode> scenes;
  final bool hindi;
  final Set<int> read;

  const _Band(
      {required this.scenes, required this.hindi, required this.read});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8A6A4F);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: scenes.length,
      itemBuilder: (context, i) {
        final s = scenes[i];
        final arc = MahabharataArcs.arcFor(s.sequenceNo);
        final prevArc = i == 0
            ? null
            : MahabharataArcs.arcFor(scenes[i - 1].sequenceNo);
        final startsArc = arc != null && arc.$1 != prevArc?.$1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (startsArc)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 6),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    (hindi ? arc.$2 : arc.$1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            _EventCard(
              scene: s,
              hindi: hindi,
              read: read.contains(s.id),
              isLast: i == scenes.length - 1,
            ),
          ],
        );
      },
    );
  }
}

class _EventCard extends ConsumerWidget {
  final NarrativeNode scene;
  final bool hindi;
  final bool read;
  final bool isLast;

  const _EventCard({
    required this.scene,
    required this.hindi,
    required this.read,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cast = ref.watch(sceneCastProvider(scene.id)).valueOrNull ?? const [];
    const accent = Color(0xFF8A6A4F);

    return SizedBox(
      width: 208,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The spine, with this event's node on it.
          SizedBox(
            height: 22,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: read ? accent : scheme.surface,
                    border: Border.all(color: accent, width: 1.6),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: isLast
                        ? Colors.transparent
                        : accent.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/gyan/scene/${scene.id}'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.bookLabel(hindi) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: accent.withValues(alpha: 0.85),
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
                          fontSize: 15,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Text(
                          scene.desc(hindi),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.38,
                            color:
                                scheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                      if (cast.isNotEmpty)
                        Text(
                          cast.take(3).map((c) => c.title(hindi)).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: accent.withValues(alpha: 0.9)),
                        ),
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

/// Entry to the day-by-day view of the war.
class _EighteenDaysLink extends StatelessWidget {
  final bool hindi;
  const _EighteenDaysLink({required this.hindi});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8A6A4F);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/gyan/mahabharata/kurukshetra'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week_rounded,
                  size: 17, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hindi
                      ? 'कुरुक्षेत्र के अठारह दिन, सेनापति अनुसार'
                      : 'The eighteen days of Kurukshetra, by commander',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
