import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'journey_view.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';

const _accent = Color(0xFF8A6A4F);

/// The Mahabharata, down the page.
///
/// This was a horizontal band, and side by side with the Ramayana the vertical
/// path simply won: it scrolls the way a phone scrolls, each scene gets room
/// for its cast and its blurb, and nobody has to swipe sideways through twenty
/// events to reach the war. What stays distinctly Mahabharata is the structure
/// above the path — the four arcs, and the eighteen days.
///
/// Ordering is **narrative**, never dates. Putting these events on a calendar
/// would assert a chronology the sources do not support.
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
        title: Text(hi ? 'महाभारत' : 'Mahabharata'),
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
          final next = ref.read(epicProgressProvider.notifier).nextIn(list);
          final done = list.where((s) => progress.contains(s.id)).length;

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
                itemCount: list.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        JourneyHeader(
                          done: done,
                          total: list.length,
                          hindi: hi,
                          subtitle: hi
                              ? 'चार पर्वों में महाभारत — कथा-क्रम में, तिथि-क्रम में नहीं।'
                              : 'The Mahabharata in four arcs — in narrative order, not a chronology.',
                        ),
                        _ArcChips(
                          selected: _arcFilter,
                          hindi: hi,
                          onSelected: (a) => setState(() => _arcFilter = a),
                        ),
                        const SizedBox(height: 10),
                        _EighteenDaysLink(hindi: hi),
                      ],
                    );
                  }
                  final scene = list[i - 1];
                  final prev = i >= 2 ? list[i - 2] : null;
                  final arc = MahabharataArcs.arcFor(scene.sequenceNo);
                  final prevArc = prev == null
                      ? null
                      : MahabharataArcs.arcFor(prev.sequenceNo);
                  final newArc = arc != null && arc.$1 != prevArc?.$1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (newArc)
                        JourneyBanner(
                            label: hi ? arc.$2 : arc.$1, hindi: hi),
                      JourneySceneRow(
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
                          ? (hi ? 'कथा आरंभ करें' : 'Begin the story')
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
            color: on ? _accent : scheme.onSurface.withValues(alpha: .8),
          ),
          selectedColor: _accent.withValues(alpha: 0.16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(null, hindi ? 'सब' : 'All'),
          for (final (en, hiLabel, _, _) in MahabharataArcs.arcs)
            chip(en, hindi ? hiLabel : en),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/gyan/mahabharata/kurukshetra'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_view_week_rounded,
                size: 17, color: _accent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hindi
                    ? 'कुरुक्षेत्र के अठारह दिन, सेनापति अनुसार'
                    : 'The eighteen days of Kurukshetra, by commander',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _accent),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _accent),
          ],
        ),
      ),
    );
  }
}
