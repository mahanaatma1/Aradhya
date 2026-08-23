import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'epic_explore.dart';
import 'epic_view_mode.dart';
import 'journey_view.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';
import 'story_mode_view.dart';

const _accent = Color(0xFF8A6A4F);

/// The Mahabharata, in two views of one text (SC-12), cut along four axes (SC-13).
///
/// Story mode is the eighteen parvas with their arcs inside. Timeline is the
/// vertical path: this was a horizontal band, and side by side with the Ramayana
/// the vertical path simply won — it scrolls the way a phone scrolls, each scene
/// gets room for its cast and its blurb, and nobody has to swipe sideways
/// through twenty events to reach the war. What stays distinctly Mahabharata is
/// the structure above the path — the four remembered arcs, and the eighteen
/// days.
///
/// The four remembered arcs of `MahabharataArcs` still head the path in Timeline
/// mode. They stopped being a *filter* when the Explore row arrived: it offers the
/// twenty-two arcs the rows were actually authored into (SC-03), and two chip rows
/// both called "arc" at two granularities is the failure that would have been.
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
  ExploreBy _facet = ExploreBy.book;
  String? _value;

  static const _epic = 'mahabharata';

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scenes = ref.watch(epicScenesProvider(_epic));
    final progress = ref.watch(epicProgressProvider);
    // Watched here rather than inside the AsyncView builder: that callback runs
    // during a descendant's build, and this ref belongs to this element.
    final mode = ref.watch(epicViewModeProvider);
    final story = mode == EpicViewMode.story;
    // The eighteen days, so Story mode can offer them from inside the parva they
    // belong to instead of reporting that parva as two events.
    final warDays = ref.watch(warDaysProvider).valueOrNull ?? const [];
    final warBookNo = warDays.isEmpty ? null : warDays.first.bookNo;
    final cast = ref.watch(epicCastFacetProvider(_epic)).valueOrNull ?? const [];
    final places =
        ref.watch(epicPlaceFacetProvider(_epic)).valueOrNull ?? const [];

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
          final scope = ExploreScope.of(
            epic: _epic,
            all: all,
            facet: _facet,
            value: _value,
            hindi: hi,
            cast: cast,
            places: places,
          );
          final list = scope.events;
          final next = ref.read(epicProgressProvider.notifier).nextIn(list);
          final done = list.where((s) => progress.contains(s.id)).length;

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JourneyHeader(
                done: done,
                total: list.length,
                hindi: hi,
                subtitle: story
                    ? (hi
                        ? 'महाभारत के अठारह पर्व, प्रत्येक अपने खंडों में — कथा-क्रम में, तिथि-क्रम में नहीं।'
                        : 'The eighteen parvas of the Mahabharata, each in its arcs — in narrative order, not a chronology.')
                    : (hi
                        ? 'चार पर्वों में महाभारत — कथा-क्रम में, तिथि-क्रम में नहीं।'
                        : 'The Mahabharata in four arcs — in narrative order, not a chronology.'),
              ),
              EpicModeToggle(hindi: hi),
              const SizedBox(height: 10),
              ExploreByChips(
                epic: _epic,
                selected: _facet,
                hindi: hi,
                // A held value means nothing under a different axis, so changing
                // the axis clears it rather than filtering by an id from the
                // wrong table.
                onSelected: (f) => setState(() {
                  _facet = f;
                  _value = null;
                }),
              ),
              if (scope.choices.isNotEmpty)
                FacetValueChips(
                  choices: scope.choices,
                  total: scope.total,
                  selected: _value,
                  hindi: hi,
                  onSelected: (v) => setState(() => _value = v),
                ),
              if (scope.unassigned > 0)
                ExploreGapNote(
                    text: _facet.gap(scope.unassigned, scope.total, hi),
                    hindi: hi),
              // In Story mode this link lives inside the parva that holds the
              // days, which is a truer place for it than the top of the screen.
              // Under a filter it is offered nowhere: the days are not filtered,
              // and eighteen unnarrowed rows beneath a narrowed list would belong
              // to neither.
              if (!story && !scope.filtered) ...[
                const SizedBox(height: 10),
                _EighteenDaysLink(hindi: hi, count: warDays.length),
              ],
              const SizedBox(height: 14),
            ],
          );

          return Stack(
            children: [
              if (story)
                StoryModeView(
                  // A new filter is a new reading position: the shelf re-seeds
                  // which section is open instead of leaving the reader looking
                  // at collapsed titles.
                  key: ValueKey(scope.stateKey),
                  epic: _epic,
                  scenes: list,
                  hindi: hi,
                  header: header,
                  hideEmpty: scope.filtered,
                  sectionExtra: scope.filtered
                      ? null
                      : (s) => (warBookNo != null &&
                              s.no == warBookNo &&
                              warDays.isNotEmpty)
                          ? _EighteenDaysLink(hindi: hi, count: warDays.length)
                          : null,
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return header;
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
                          JourneyBanner(label: hi ? arc.$2 : arc.$1, hindi: hi),
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

/// Entry to the day-by-day view of the war.
///
/// The count is passed in rather than written as "eighteen", so the label cannot
/// drift from the data the way the hardcoded arc ranges once did.
class _EighteenDaysLink extends StatelessWidget {
  final bool hindi;
  final int count;
  const _EighteenDaysLink({required this.hindi, required this.count});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hindi
                        ? 'कुरुक्षेत्र के दिन, सेनापति अनुसार'
                        : 'The days of Kurukshetra, by commander',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: _accent),
                  ),
                  if (count > 0)
                    Text(
                      hindi
                          ? '$count दिन'
                          : '$count ${count == 1 ? "day" : "days"}',
                      style: TextStyle(
                          fontSize: 11,
                          color: _accent.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _accent),
          ],
        ),
      ),
    );
  }
}
