import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'epic_explore.dart';
import 'epic_view_mode.dart';
import 'journey_view.dart';
import 'narrative_providers.dart';
import 'story_mode_view.dart';

/// The Ramayana, in two views of one text (SC-12), cut along four axes (SC-13).
///
/// Story mode is the seven kandas with their arcs inside — the shape of the
/// work. Timeline is the vertical path, shared with the Mahabharata via
/// journey_view.dart, so the two epics read as one app rather than two
/// experiments. Which one you last used is remembered.
///
/// Above both sits the Explore row, which narrows *what* is shown without
/// touching *how*: an arc, a character, a place. It is not remembered — a filter
/// you left on three days ago is a confusing thing to come back to, where a
/// preferred view is not.
class RamayanaJourneyScreen extends ConsumerStatefulWidget {
  const RamayanaJourneyScreen({super.key});

  @override
  ConsumerState<RamayanaJourneyScreen> createState() =>
      _RamayanaJourneyScreenState();
}

class _RamayanaJourneyScreenState extends ConsumerState<RamayanaJourneyScreen> {
  ExploreBy _facet = ExploreBy.book;
  String? _value;

  static const _epic = 'ramayana';

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scenes = ref.watch(epicScenesProvider(_epic));
    final progress = ref.watch(epicProgressProvider);
    // Watched here rather than inside the AsyncView builder: that callback runs
    // during a descendant's build, and this ref belongs to this element.
    final mode = ref.watch(epicViewModeProvider);
    final cast = ref.watch(epicCastFacetProvider(_epic)).valueOrNull ?? const [];
    final places =
        ref.watch(epicPlaceFacetProvider(_epic)).valueOrNull ?? const [];

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
                subtitle: hi
                    ? 'वाल्मीकि रामायण के सात कांड, दृश्य दर दृश्य।'
                    : 'The seven kandas of the Valmiki Ramayana, scene by scene.',
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
              const SizedBox(height: 14),
            ],
          );

          return Stack(
            children: [
              if (mode == EpicViewMode.story)
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
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
                  itemCount: list.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return header;
                    final scene = list[i - 1];
                    final prev = i >= 2 ? list[i - 2] : null;
                    final newKanda = prev?.bookNo != scene.bookNo;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (newKanda)
                          JourneyBanner(
                              label: scene.bookLabel(hi) ?? '', hindi: hi),
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
