import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';
import 'story_structure.dart';

const _accent = Color(0xFF8A6A4F);

/// Devanagari needs noticeably more room between lines than Latin at the same
/// size. Laying out in English and letting Hindi cope is how the dense screens
/// in this app ended up tight, so every multi-line style here goes through this.
double _lh(bool hindi, double base) => hindi ? base * 1.18 : base;

/// A warm panel fill that survives both themes. `AppColors.kraft` is the
/// *light* ground; laid over the espresso dark theme a cream box glows.
Color _panel(ColorScheme scheme, double alpha) =>
    scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest.withValues(alpha: alpha)
        : AppColors.kraft.withValues(alpha: alpha);

/// Gold dark enough to read on that fill, in either theme.
Color _goldInk(ColorScheme scheme) => scheme.brightness == Brightness.dark
    ? AppColors.goldBright
    : const Color(0xFF8A6A2E);

/// Story mode: the epic as its books, each holding its arcs (SC-12).
///
/// The vertical path in `journey_view.dart` shows the whole sweep in one scroll,
/// which is the right thing for "where am I". It is the wrong thing for "what
/// is in the Sundara Kanda" — thirty-two cards in one column have no structure
/// a reader can hold. This view answers the second question: sections you can
/// collapse, arcs inside them, and an honest line where nothing is written yet.
class StoryModeView extends ConsumerStatefulWidget {
  final String epic;
  final List<NarrativeNode> scenes;
  final bool hindi;

  /// Rendered as the first item, so the parent keeps its header and progress
  /// bar rather than this view growing its own.
  final Widget header;

  /// Extra content for one section, placed below its arcs.
  ///
  /// This exists for the eighteen days of Kurukshetra. They are rows of the
  /// Bhishma Parva, but the epic list leaves them out on purpose — eighteen
  /// near-identical entries would bury the events that carry the story. Without
  /// a hook here the parva would report two events when twenty sit in it, so the
  /// Mahabharata screen uses this to link its own sub-view, counted.
  final Widget? Function(EpicSection section)? sectionExtra;

  /// Leave sections with nothing in them out, instead of saying they are empty.
  ///
  /// Off by default, because "No events yet" on the Uttara Kanda is a true and
  /// useful thing to say: the section exists in the work and we have not written
  /// it (SC-15). Turned on when the Explore row is filtering (SC-13), where a
  /// section is empty because the *reader* narrowed the list — reporting that as
  /// unwritten content would be a lie about the data.
  ///
  /// A section whose only content is [sectionExtra] counts as empty here, which
  /// is why the epic screens drop the extra while a filter is on: eighteen
  /// unfiltered war days under a filtered parva would not belong to either.
  final bool hideEmpty;

  const StoryModeView({
    super.key,
    required this.epic,
    required this.scenes,
    required this.hindi,
    required this.header,
    this.sectionExtra,
    this.hideEmpty = false,
  });

  @override
  ConsumerState<StoryModeView> createState() => _StoryModeViewState();
}

class _StoryModeViewState extends ConsumerState<StoryModeView> {
  /// Sections the reader has opened. Seeded once, on the first build that has
  /// progress to read, with the section holding the next unread event — landing
  /// on a wall of collapsed titles would hide the thing you came back for.
  Set<int>? _open;

  @override
  Widget build(BuildContext context) {
    final hi = widget.hindi;
    final progress = ref.watch(epicProgressProvider);
    final all = buildStory(widget.epic, widget.scenes);
    final sections =
        widget.hideEmpty ? all.where((s) => !s.isEmpty).toList() : all;

    _open ??= _seed(sections, progress);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
      // A filter that survives its own chip disappearing leaves nothing to draw.
      // The header alone, with no word about why, reads as a broken screen.
      itemCount: sections.isEmpty ? 2 : sections.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return widget.header;
        if (sections.isEmpty) return _NothingMatched(hindi: hi);
        final s = sections[i - 1];
        return _SectionCard(
          story: s,
          hindi: hi,
          expanded: _open!.contains(s.section.no),
          progress: progress,
          extra: widget.sectionExtra?.call(s.section),
          onToggle: () => setState(() {
            _open!.contains(s.section.no)
                ? _open!.remove(s.section.no)
                : _open!.add(s.section.no);
          }),
        );
      },
    );
  }

  /// The section holding the first unread event, or the first section that has
  /// anything in it at all.
  Set<int> _seed(List<StorySection> sections, Set<int> read) {
    for (final s in sections) {
      for (final a in s.arcs) {
        for (final e in a.events) {
          if (!read.contains(e.id)) return {s.section.no};
        }
      }
    }
    final first = sections.firstWhere((s) => !s.isEmpty,
        orElse: () => sections.isEmpty
            ? const StorySection(
                section: EpicSection(no: 0, titleEn: '', titleHi: ''),
                arcs: [])
            : sections.first);
    return {first.section.no};
  }
}

/// One kanda or parva, as a book on a shelf.
class _SectionCard extends StatelessWidget {
  final StorySection story;
  final bool hindi;
  final bool expanded;
  final Set<int> progress;
  final Widget? extra;
  final VoidCallback onToggle;

  const _SectionCard({
    required this.story,
    required this.hindi,
    required this.expanded,
    required this.progress,
    required this.extra,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = story.note(hindi);
    // A section with a sub-view to offer is not an empty section.
    final empty = story.isEmpty && extra == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: empty ? Colors.transparent : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: empty
                ? scheme.outline.withValues(alpha: 0.14)
                : scheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A section with nothing in it is not a button. Saying "no events
            // yet" and then opening to nothing would be worse than saying it.
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: empty ? null : onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Spine(no: story.section.no, muted: empty),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title(hindi),
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                              height: _lh(hindi, 1.2),
                              color: empty
                                  ? scheme.onSurface.withValues(alpha: 0.55)
                                  : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (_subtitle() case final sub?)
                            Text(
                              sub,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: _lh(hindi, 1.3),
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          if (story.teaching) ...[
                            const SizedBox(height: 7),
                            _TeachingBadge(hindi: hindi),
                          ],
                          if (note != null) ...[
                            const SizedBox(height: 8),
                            _TraditionNote(text: note, hindi: hindi),
                          ],
                        ],
                      ),
                    ),
                    if (!empty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(Icons.expand_more_rounded,
                              size: 22,
                              color: scheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (expanded && !empty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final arc in story.arcs) ...[
                      _ArcHeader(arc: arc, hindi: hindi),
                      for (final e in arc.events)
                        _EventRow(
                          event: e,
                          hindi: hindi,
                          read: progress.contains(e.id),
                        ),
                      const SizedBox(height: 6),
                    ],
                    ?extra,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _readCount() {
    var n = 0;
    for (final a in story.arcs) {
      for (final e in a.events) {
        if (progress.contains(e.id)) n++;
      }
    }
    return n;
  }

  String? _subtitle() {
    if (story.isEmpty) {
      // A section whose only content is a sub-view says nothing here; the
      // sub-view row inside states its own count.
      if (extra != null) return null;
      return hindi ? 'अभी कोई प्रसंग नहीं' : 'No events yet';
    }
    final n = story.eventCount;
    final arcs = story.arcs.length;
    final done = _readCount();
    final unit = story.teaching
        ? (hindi ? 'उपदेश' : (n == 1 ? 'teaching' : 'teachings'))
        : (hindi ? 'प्रसंग' : (n == 1 ? 'event' : 'events'));
    final arcWord = hindi ? 'खंड' : (arcs == 1 ? 'arc' : 'arcs');
    final base = '$n $unit  ·  $arcs $arcWord';
    return done == 0 ? base : '$base  ·  $done ${hindi ? "पढ़े" : "read"}';
  }
}

/// Shown when a filter leaves no section standing — see [StoryModeView.hideEmpty].
class _NothingMatched extends StatelessWidget {
  final bool hindi;
  const _NothingMatched({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: _panel(scheme, 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_off_rounded,
              size: 18, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hindi
                  ? 'इस चयन में कोई प्रसंग नहीं। ऊपर से "सब" चुनें।'
                  : 'No events under this choice. Pick "All" above.',
              style: TextStyle(
                fontSize: 12.5,
                height: _lh(hindi, 1.35),
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The numbered gold spine that makes a section read as a book.
class _Spine extends StatelessWidget {
  final int no;
  final bool muted;
  const _Spine({required this.no, required this.muted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted ? Colors.transparent : _panel(scheme, 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: muted ? 0.28 : 0.5),
        ),
      ),
      child: Text(
        '$no',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: muted
              ? AppColors.gold.withValues(alpha: 0.6)
              : _goldInk(scheme),
        ),
      ),
    );
  }
}

/// Says a section is discourse rather than narrative (SC-14).
class _TeachingBadge extends StatelessWidget {
  final bool hindi;
  const _TeachingBadge({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // sacredGreen is a deep green picked for cream. On the espresso dark theme
    // it disappears, so it is lifted rather than dropped.
    final green = scheme.brightness == Brightness.dark
        ? Color.lerp(AppColors.sacredGreen, Colors.white, 0.5)!
        : AppColors.sacredGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: green.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.self_improvement_rounded, size: 12, color: green),
          const SizedBox(width: 5),
          // Flexible, not bare: the label is the longest string on the card at
          // its smallest size, and a pill that cannot wrap spills its text past
          // its own border on a 320 dp screen. Wrapping is the graceful failure.
          Flexible(
            child: Text(
              hindi ? 'उपदेश, घटना नहीं' : 'Teachings, not events',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: _lh(hindi, 1.15),
                color: green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A note the tradition carries about a section — kept visually separate from
/// the section's own title, the same way the entity screen separates symbolism
/// from description.
class _TraditionNote extends StatelessWidget {
  final String text;
  final bool hindi;
  const _TraditionNote({required this.text, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: _panel(scheme, 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hindi ? 'परंपरा में' : 'IN THE TRADITION',
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: _goldInk(scheme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              height: _lh(hindi, 1.45),
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

/// One movement of the story, titled.
class _ArcHeader extends StatelessWidget {
  final StoryArc arc;
  final bool hindi;
  const _ArcHeader({required this.arc, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final title = arc.title(hindi);
    // A pre-SC-02 row with no arc gets a rule and no label, rather than an
    // empty heading taking up space.
    if (title == null || title.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(
            height: 1, color: _accent.withValues(alpha: 0.18)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                height: _lh(hindi, 1.25),
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One event inside an arc.
class _EventRow extends StatelessWidget {
  final NarrativeNode event;
  final bool hindi;
  final bool read;

  const _EventRow({
    required this.event,
    required this.hindi,
    required this.read,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The quick summary is the 30-second read and is the right blurb here.
    // Until SC-05 lands it is null everywhere, so the card blurb stands in.
    final blurb = event.quickSummary(hindi) ?? event.desc(hindi);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/gyan/scene/${event.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 7, 2, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: read ? _accent : Colors.transparent,
                  border: Border.all(
                    color: read
                        ? _accent
                        : scheme.outline.withValues(alpha: 0.45),
                    width: 1.3,
                  ),
                ),
                child: read
                    ? const Icon(Icons.check_rounded,
                        size: 10, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title(hindi),
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: _lh(hindi, 1.22),
                      color: read
                          ? scheme.onSurface.withValues(alpha: 0.72)
                          : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: _lh(hindi, 1.38),
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 17, color: scheme.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}
