import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';
import 'story_structure.dart';

const _accent = Color(0xFF8A6A4F);

/// Devanagari needs more room between lines than Latin at the same size.
double _lh(bool hindi, double base) => hindi ? base * 1.18 : base;

/// The axis a reader is cutting an epic along (SC-13).
///
/// This sits *above* the view mode and is independent of it: the facet decides
/// which events are in front of you, the mode decides whether you see them as a
/// shelf of books or as a path. Both epics get the same row.
///
/// [book] is the whole epic with nothing filtered — in either mode the sections
/// already do their own grouping, so there is no second row of chips and nothing
/// to add. It is the default for that reason.
///
/// The plan calls the second facet "Story". It is called [arc] here because one
/// of the two view modes is already named Story, and a chip and a mode sharing a
/// word while meaning different things is a UI bug however faithful the naming.
/// `arc` is the word the schema, the models and the section headers all use.
///
/// Themes is absent, and not by oversight: one narrative row in seventy-nine
/// carries a theme, so the chip would be a filter with nothing behind it. It
/// arrives with the content, not before.
enum ExploreBy { book, arc, characters, places }

extension ExploreByLabel on ExploreBy {
  /// The section word differs by epic — kandas in the Ramayana, parvas in the
  /// Mahabharata — so the label is asked of the epic rather than fixed.
  String label(bool hindi, String epic) => switch (this) {
        ExploreBy.book => sectionWord(epic, hindi),
        ExploreBy.arc => hindi ? 'खंड' : 'Arc',
        ExploreBy.characters => hindi ? 'पात्र' : 'Characters',
        ExploreBy.places => hindi ? 'स्थान' : 'Places',
      };

  IconData get icon => switch (this) {
        ExploreBy.book => Icons.menu_book_rounded,
        // Not timeline_rounded: that icon belongs to the view mode toggle, and
        // two controls on one screen must not share a glyph.
        ExploreBy.arc => Icons.route_rounded,
        ExploreBy.characters => Icons.groups_rounded,
        ExploreBy.places => Icons.place_rounded,
      };

  /// What to say when this facet cannot place [n] of the [of] events in front of
  /// the reader.
  ///
  /// Never suppressed. A chip row that quietly covers a third of an epic reads as
  /// though it covered all of it, and the reader has no way to tell.
  String gap(int n, int of, bool hindi) => switch (this) {
        ExploreBy.book => '',
        ExploreBy.arc => hindi
            ? '$of में से $n प्रसंग किसी खंड में नहीं रखे गए हैं।'
            : '$n of $of events are not yet placed in an arc.',
        ExploreBy.characters => hindi
            ? '$of में से $n प्रसंगों के पात्र अभी दर्ज नहीं हैं।'
            : '$n of $of events have no cast recorded yet.',
        ExploreBy.places => hindi
            ? '$of में से $n प्रसंगों का स्थान अभी दर्ज नहीं है।'
            : '$n of $of events have no place recorded yet.',
      };
}

/// One chip in the second row: a label, and how many events it covers.
typedef FacetChoice = ({String key, String label, int count});

/// One epic resolved against one facet — the chips to offer, the events to show,
/// and what the facet could not account for (SC-13).
///
/// Counts are computed from the list the screen is actually showing, never from a
/// database aggregate. The war days make the difference visible: Kurukshetra is
/// eight events on the Mahabharata screen and twenty-six in the table, and a chip
/// promising twenty-six that opens onto eight is a chip the reader catches.
class ExploreScope {
  final String epic;
  final ExploreBy facet;

  /// The chosen chip, or null for all of them. Entity facets key on the entity
  /// id as a string; the arc facet keys on the arc slug.
  final String? value;

  final List<FacetChoice> choices;

  /// The events to render, filtered.
  final List<NarrativeNode> events;

  /// How many events the epic has before filtering.
  final int total;

  /// Events this facet holds no chip for — unplaced, uncast, or unwritten.
  final int unassigned;

  const ExploreScope._({
    required this.epic,
    required this.facet,
    required this.value,
    required this.choices,
    required this.events,
    required this.total,
    required this.unassigned,
  });

  factory ExploreScope.of({
    required String epic,
    required List<NarrativeNode> all,
    required ExploreBy facet,
    required String? value,
    required bool hindi,
    required List<EpicFacetValue> cast,
    required List<EpicFacetValue> places,
  }) {
    final shown = {for (final n in all) n.id};
    final choices = <FacetChoice>[];
    var events = all;
    var covered = 0;

    switch (facet) {
      case ExploreBy.book:
        break;

      case ExploreBy.arc:
        for (final arc in allArcs(epic, all)) {
          choices.add((
            key: arc.slug,
            label: arc.title(hindi) ?? arc.slug,
            count: arc.events.length,
          ));
          covered += arc.events.length;
          if (arc.slug == value) events = arc.events;
        }

      case ExploreBy.characters:
      case ExploreBy.places:
        // Intersected with what is on screen rather than trusted from the query.
        // The queries already exclude the war days, so today this changes
        // nothing — but it means the counts are right for whatever list is passed,
        // which is the property worth having.
        final touched = <int>{};
        for (final v in facet == ExploreBy.characters ? cast : places) {
          final mine = v.nodeIds.intersection(shown);
          if (mine.isEmpty) continue;
          touched.addAll(mine);
          final key = '${v.entityId}';
          choices.add((key: key, label: v.title(hindi), count: mine.length));
          if (key == value) {
            events = all.where((n) => mine.contains(n.id)).toList();
          }
        }
        covered = touched.length;
    }

    return ExploreScope._(
      epic: epic,
      facet: facet,
      value: value,
      choices: choices,
      // A selection with no chip behind it — the data moved under a held filter —
      // shows nothing rather than silently reverting to everything.
      events: (value != null && !choices.any((c) => c.key == value))
          ? const []
          : events,
      total: all.length,
      unassigned: facet == ExploreBy.book ? 0 : all.length - covered,
    );
  }

  bool get filtered => value != null;

  /// Changes whenever the set of events does, so the shelf can re-seed which
  /// section is open instead of leaving the reader on a collapsed screen.
  String get stateKey => '${facet.name}:${value ?? ''}';
}

/// The facet row: how you would like to come at this epic (SC-13).
class ExploreByChips extends StatelessWidget {
  final String epic;
  final ExploreBy selected;
  final bool hindi;
  final ValueChanged<ExploreBy> onSelected;

  const ExploreByChips({
    super.key,
    required this.epic,
    required this.selected,
    required this.hindi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Text(
                hindi ? 'देखें' : 'EXPLORE BY',
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          for (final f in ExploreBy.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.label(hindi, epic)),
                avatar: Icon(
                  f.icon,
                  size: 15,
                  color: f == selected
                      ? _accent
                      : scheme.onSurface.withValues(alpha: 0.6),
                ),
                selected: f == selected,
                // No toggle-off: one of the four is always the way you are
                // reading, and Book is the one that means "unfiltered".
                onSelected: (_) => onSelected(f),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: f == selected ? FontWeight.w700 : FontWeight.w500,
                  color: f == selected
                      ? _accent
                      : scheme.onSurface.withValues(alpha: 0.8),
                ),
                selectedColor: _accent.withValues(alpha: 0.16),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The value row: which arc, which character, which place.
///
/// Counts ride in the label the way the search screen's kind chips do, because
/// the row can run to forty-odd entries and a number is what makes the swipe
/// worth taking.
class FacetValueChips extends StatelessWidget {
  final List<FacetChoice> choices;
  final int total;
  final String? selected;
  final bool hindi;
  final ValueChanged<String?> onSelected;

  const FacetValueChips({
    super.key,
    required this.choices,
    required this.total,
    required this.selected,
    required this.hindi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String? value, String label, int count) {
      final on = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$label  $count'),
          selected: on,
          onSelected: (_) => onSelected(on ? null : value),
          showCheckmark: false,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? _accent : scheme.onSurface.withValues(alpha: 0.8),
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
          chip(null, hindi ? 'सब' : 'All', total),
          for (final c in choices) chip(c.key, c.label, c.count),
        ],
      ),
    );
  }
}

/// What the chip row above could not account for.
class ExploreGapNote extends StatelessWidget {
  final String text;
  final bool hindi;
  const ExploreGapNote({super.key, required this.text, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(Icons.info_outline_rounded,
                size: 13, color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                height: _lh(hindi, 1.35),
                color: scheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
