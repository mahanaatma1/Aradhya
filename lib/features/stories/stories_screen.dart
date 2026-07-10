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

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final value = ref.watch(storiesProvider);

    // When opened from a Home emotion tile, the app-bar title names the emotion.
    final isAll = _emotion == 'all';
    final title = isAll
        ? t.catKatha
        : (hi ? EmotionStyle.of(_emotion).hi : EmotionStyle.of(_emotion).en);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: value,
        emptyMessage: t.comingSoon,
        isEmpty: (l) => l.isEmpty,
        builder: (stories) {
          final list = isAll
              ? stories
              : stories.where((s) => s.emotions.contains(_emotion)).toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
  Color(0xFF9C2950), // rose
  Color(0xFF4A4A8A), // indigo
  Color(0xFF25533F), // deep green
  Color(0xFF5A2EA8), // violet
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
    final tags = story.emotions.take(3).toList();

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
                child: Icon(primary?.icon ?? Icons.auto_stories_rounded,
                    color: Colors.white, size: 26),
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
                                hindi
                                    ? EmotionStyle.of(tag).hi
                                    : EmotionStyle.of(tag).en,
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

