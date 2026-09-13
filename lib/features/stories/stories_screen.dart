import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/async_view.dart';
import 'emotion_style.dart';
import 'story_models.dart';
import 'story_providers.dart';

/// Stories browsed by emotion — our own colour-coded chip filter + card list.
/// [initialEmotion] (lowercase tag, e.g. 'anger') pre-selects that filter, e.g.
/// when opened from a Home emotion tile.
class StoriesScreen extends ConsumerStatefulWidget {
  final String? initialEmotion;
  const StoriesScreen({super.key, this.initialEmotion});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  late final String _emotion =
      widget.initialEmotion?.trim().toLowerCase() ?? 'all';

  /// Which collection is showing (ST-01): both together by default, or one
  /// kind isolated. Not a hard either/or — [_StoryCollection.all] is the
  /// merged, categorised list; the underlying [Story.kind] tag is what makes
  /// filtering back down to one kind possible without a second screen.
  /// Opening from a Home emotion tile jumps straight to that emotion, and
  /// emotion is a story-only concept (kathas carry no emotion tags), so that
  /// path starts on stories-only rather than the merged view.
  late _StoryCollection _collection =
      widget.initialEmotion == null
          ? _StoryCollection.all
          : _StoryCollection.story;

  /// Selected deity chip, or null for all. `_otherKey` gathers every deity too
  /// rare to earn its own chip. Only meaningful when kathas are in view.
  String? _deity;
  static const _otherKey = '__other__';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final isAll = _emotion == 'all';

    final title = switch (_collection) {
      _StoryCollection.katha => hi ? 'व्रत कथा' : 'Vrat Katha',
      _StoryCollection.story when !isAll =>
        hi ? EmotionStyle.of(_emotion).hi : EmotionStyle.of(_emotion).en,
      _StoryCollection.story => hi ? 'कहानियाँ' : 'Stories',
      _StoryCollection.all => hi ? 'कहानियाँ और कथाएँ' : 'Stories & Katha',
    };

    final showDeityChips =
        isAll && _collection != _StoryCollection.story;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Only offered when the screen is not already filtered to one
          // emotion — arriving from "Stories about anger" and being shown a
          // collection switch would be a non-sequitur.
          if (isAll) _CollectionSelector(
            selected: _collection,
            hindi: hi,
            onChanged: (v) => setState(() {
              _collection = v;
              _deity = null;
            }),
          ),
          if (showDeityChips) _DeityChips(
            selected: _deity,
            hindi: hi,
            otherKey: _otherKey,
            onSelected: (d) => setState(() => _deity = d),
          ),
          Expanded(
            child: switch (_collection) {
              _StoryCollection.all =>
                _buildList(ref.watch(allStoriesProvider), t, hi, _filterAll),
              _StoryCollection.story =>
                _buildList(ref.watch(storiesProvider), t, hi, _filterStories),
              _StoryCollection.katha =>
                _buildList(ref.watch(kathasProvider), t, hi, _filterKathas),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<Story>> value,
    L10n t,
    bool hi,
    List<Story> Function(List<Story>) filter,
  ) {
    return AsyncView(
      value: value,
      emptyMessage: t.comingSoon,
      isEmpty: (l) => l.isEmpty,
      builder: (all) {
        final list = filter(all);
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                hi ? 'इस चयन में कोई कथा नहीं' : 'Nothing in this selection',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) => _StoryCard(
            story: list[i],
            index: i,
            hindi: hi,
            onTap: () => context.push('/read-story', extra: list[i]),
          ),
        );
      },
    );
  }

  List<Story> _filterStories(List<Story> all) => _emotion == 'all'
      ? all
      : all.where((s) => s.emotions.contains(_emotion)).toList();

  List<Story> _filterKathas(List<Story> all) {
    if (_deity == null) return all;
    if (_deity == _otherKey) {
      final chipped =
          ref.read(kathaDeitiesProvider).valueOrNull?.toSet() ?? const {};
      return all
          .where((k) => !chipped.contains(k.primaryDeity ?? ''))
          .toList();
    }
    return all.where((k) => k.primaryDeity == _deity).toList();
  }

  /// The merged view (ST-01). Stories are shown as-is; kathas go through the
  /// same deity filter as the katha-only view, so switching from "Vrat
  /// Katha" to "All" with a deity chip already picked does not silently drop
  /// it — [Story.isKatha] tells stories and kathas apart in one list.
  List<Story> _filterAll(List<Story> all) {
    final stories = all.where((s) => !s.isKatha);
    final kathas = _filterKathas(all.where((s) => s.isKatha).toList());
    return [...stories, ...kathas];
  }
}

/// Which of stories, kathas is showing: [all] is the merged, categorised
/// list ST-01 asks for; the other two isolate one kind, unchanged from the
/// screen's previous either/or toggle.
enum _StoryCollection { all, story, katha }

/// All / Stories / Vrat Katha switch.
class _CollectionSelector extends StatelessWidget {
  final _StoryCollection selected;
  final bool hindi;
  final ValueChanged<_StoryCollection> onChanged;
  const _CollectionSelector(
      {required this.selected, required this.hindi, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SegmentedButton<_StoryCollection>(
        segments: [
          ButtonSegment(
            value: _StoryCollection.all,
            label: Text(hindi ? 'सभी' : 'All'),
          ),
          ButtonSegment(
            value: _StoryCollection.story,
            icon: const Icon(Icons.auto_stories_rounded, size: 18),
            label: Text(hindi ? 'कहानियाँ' : 'Stories'),
          ),
          ButtonSegment(
            value: _StoryCollection.katha,
            icon: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: Text(hindi ? 'व्रत कथा' : 'Vrat Katha'),
          ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary.withValues(alpha: 0.14),
          selectedForegroundColor: scheme.primary,
        ),
      ),
    );
  }
}

/// Deity filter for kathas. Rare deities are gathered under "Other" rather than
/// each getting a chip that matches a single item.
class _DeityChips extends ConsumerWidget {
  final String? selected;
  final bool hindi;
  final String otherKey;
  final ValueChanged<String?> onSelected;
  const _DeityChips({
    required this.selected,
    required this.hindi,
    required this.otherKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deities = ref.watch(kathaDeitiesProvider).valueOrNull ?? const [];
    if (deities.isEmpty) return const SizedBox.shrink();

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
            fontSize: 13,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? scheme.primary : scheme.onSurface.withValues(alpha: 0.8),
          ),
          selectedColor: scheme.primary.withValues(alpha: 0.14),
          side: BorderSide(
              color: on
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.28)),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(null, hindi ? 'सभी' : 'All'),
          for (final d in deities) chip(d, d),
          chip(otherKey, hindi ? 'अन्य' : 'Other'),
        ],
      ),
    );
  }
}

/// A rotating palette so consecutive cards read as different colours even when
/// they all share one emotion (e.g. an all-"anger" filtered list).
const _cardPalette = <Color>[
  Color(0xFFC0392B), // ember red
  Color(0xFF2E8B8B), // teal
  Color(0xFFC79200), // gold
  Color(0xFFD9748C), // rose
  Color(0xFF4A4A8A), // indigo
  Color(0xFF5E8C74), // deep green
  Color(0xFF6C5A9C), // violet
  Color(0xFFB4611E), // amber-brown
];

/// A story card washed in a rotating palette colour (so a filtered list stays
/// colourful and varied), with a soft rounded emotion medallion and a subtle
/// press-spring animation.
class _StoryCard extends StatefulWidget {
  final Story story;
  final int index;
  final bool hindi;
  final VoidCallback onTap;
  const _StoryCard(
      {required this.story,
      required this.index,
      required this.hindi,
      required this.onTap});

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final hindi = widget.hindi;
    final accent = _cardPalette[widget.index % _cardPalette.length];
    final primary =
        story.emotions.isEmpty ? null : EmotionStyle.of(story.emotions.first);

    // Kathas carry no emotion tags, so without this they would render as a bare
    // title with a generic icon. Their deities are the meaningful label.
    final tags = story.isKatha
        ? story.deities.take(3).toList()
        : story.emotions.take(3).toList();
    final icon = story.isKatha
        ? Icons.local_fire_department_rounded
        : (primary?.icon ?? Icons.auto_stories_rounded);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.13),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Soft rounded emotion medallion (replaces the hard left stripe).
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.40),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title(hindi),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.28,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                story.isKatha
                                    ? tag
                                    : (hindi
                                        ? EmotionStyle.of(tag).hi
                                        : EmotionStyle.of(tag).en),
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: accent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

