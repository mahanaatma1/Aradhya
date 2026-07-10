import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/brand.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmark_button.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/tts_voice.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/share_card.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/stitched_border.dart';
import '../scriptures/scripture_providers.dart' show readerFontScaleProvider;
import 'emotion_style.dart';
import 'story_models.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  final Story story;
  const StoryReaderScreen({super.key, required this.story});

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  final _tts = _StoryTts();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _share(bool hi) {
    final story = widget.story;
    final body = story.body(hi) ?? '';
    final excerpt =
        body.length > 220 ? '${body.substring(0, 220).trim()}…' : body;
    final caption = <String>[
      story.title(hi),
      excerpt,
      '',
      '${Brand.name} · ${hi ? Brand.taglineHi : Brand.taglineEn}',
    ].join('\n');
    shareCardImage(
      context: context,
      card: _StoryShareCard(story: story, hindi: hi),
      text: caption,
      filename: 'aradhya_katha.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final story = widget.story;
    final hi = ref.watch(localeProvider).languageCode == 'hi';
    final scale = ref.watch(readerFontScaleProvider);
    final body = story.body(hi) ?? '';

    return Scaffold(
      appBar: AppBar(
        // Title intentionally omitted — the story heading is shown in the body.
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _tts.speaking,
            builder: (_, speaking, _) => IconButton(
              icon: Icon(
                  speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: speaking ? scheme.error : null),
              tooltip: speaking
                  ? (hi ? 'रोकें' : 'Stop')
                  : (hi ? 'सुनें' : 'Listen'),
              onPressed: () => _tts.toggle(
                  story.title(hi), body, hi, ref.read(sharedPrefsProvider)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            tooltip: hi ? 'आवाज़' : 'Voice',
            onPressed: () =>
                _tts.chooseVoice(context, ref.read(sharedPrefsProvider), hi),
          ),
          const _FontSizeButton(),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: hi ? 'साझा करें' : 'Share',
            onPressed: () => _share(hi),
          ),
          BookmarkButton(
            bookmark: Bookmark(
              kind: 'story',
              id: story.id,
              titleEn: story.titleEn,
              titleHi: story.titleHi,
              subtitle: story.emotions.isEmpty ? null : story.emotions.first,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
        children: [
          Text(
            story.title(hi),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w600,
              fontSize: 24 * scale,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in story.emotions)
                _Tag(style: EmotionStyle.of(tag), hindi: hi),
            ],
          ),
          const SizedBox(height: 20),
          SelectableText(
            body,
            style: TextStyle(
              fontFamily: hi ? AppFonts.devanagari : AppFonts.body,
              fontSize: 16.5 * scale,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reads a story aloud: the title then the body, in the reader's language.
/// Exposes a [speaking] flag so the Listen button can toggle to Stop.
class _StoryTts {
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> speaking = ValueNotifier(false);
  bool _init = false;

  Future<void> _ensure() async {
    if (_init) return;
    _init = true;
    await _tts.awaitSpeakCompletion(true);
    _tts.setCancelHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) => speaking.value = false);
  }

  Future<void> toggle(
      String title, String body, bool hindi, SharedPreferences prefs) async {
    if (speaking.value) {
      await stop();
      return;
    }
    await _ensure();
    speaking.value = true;
    try {
      applyTtsVoice(_tts, prefs, hindi);
      if (title.trim().isNotEmpty) await _tts.speak(title);
      if (speaking.value && body.trim().isNotEmpty) await _tts.speak(body);
    } finally {
      speaking.value = false;
    }
  }

  Future<void> chooseVoice(
          BuildContext context, SharedPreferences prefs, bool hi) =>
      showVoicePicker(context: context, tts: _tts, prefs: prefs, hi: hi);

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }

  void dispose() {
    _tts.stop();
    speaking.dispose();
  }
}

/// Text-size menu — reuses the shared [readerFontScaleProvider] so the choice
/// is consistent with the scripture reader.
class _FontSizeButton extends ConsumerWidget {
  const _FontSizeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    return PopupMenuButton<double>(
      icon: const Icon(Icons.format_size_rounded),
      tooltip: hi ? 'अक्षर आकार' : 'Text size',
      onSelected: (v) => ref.read(readerFontScaleProvider.notifier).state = v,
      itemBuilder: (context) => [
        PopupMenuItem(value: 0.9, child: Text(hi ? 'छोटा' : 'Small')),
        PopupMenuItem(value: 1.0, child: Text(hi ? 'सामान्य' : 'Default')),
        PopupMenuItem(value: 1.2, child: Text(hi ? 'बड़ा' : 'Large')),
        PopupMenuItem(
            value: 1.4, child: Text(hi ? 'बहुत बड़ा' : 'Extra large')),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final EmotionStyle style;
  final bool hindi;
  const _Tag({required this.style, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 5),
          Text(hindi ? style.hi : style.en,
              style: TextStyle(
                  fontSize: 12, color: style.color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Branded share card for a katha — title + emotion badges + an excerpt, with
/// the Aradhya logo footer. Rendered off-screen and captured to a PNG.
class _StoryShareCard extends StatelessWidget {
  final Story story;
  final bool hindi;
  const _StoryShareCard({required this.story, required this.hindi});

  static const _onColor = Color(0xFFFDEEDE);

  @override
  Widget build(BuildContext context) {
    final body = story.body(hindi) ?? '';
    final excerpt =
        body.length > 300 ? '${body.substring(0, 300).trim()}…' : body;
    return SizedBox(
      width: 420,
      child: DefaultTextStyle(
        style: const TextStyle(color: _onColor),
        child: StitchedCard(
          gradient: const LinearGradient(
            colors: [AppColors.terracotta, AppColors.terracottaDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          stitchColor: Colors.white.withValues(alpha: 0.6),
          radius: 24,
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text((hindi ? 'कथा' : 'Katha').toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: _onColor.withValues(alpha: 0.82))),
              const SizedBox(height: 12),
              Text(
                story.title(hindi),
                style: TextStyle(
                  fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 1.3,
                  color: _onColor,
                ),
              ),
              if (story.emotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in story.emotions.take(4))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _onColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                            hindi
                                ? EmotionStyle.of(tag).hi
                                : EmotionStyle.of(tag).en,
                            style: TextStyle(
                                fontFamily: hindi
                                    ? AppFonts.devanagari
                                    : AppFonts.body,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _onColor)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Text(
                excerpt,
                style: TextStyle(
                  fontFamily: hindi ? AppFonts.devanagari : AppFonts.body,
                  fontSize: 14.5,
                  height: 1.55,
                  color: _onColor.withValues(alpha: 0.92),
                ),
              ),
              Divider(
                  height: 28,
                  thickness: 1,
                  color: _onColor.withValues(alpha: 0.2)),
              Row(
                children: [
                  const AppLogo(size: 30, tile: false),
                  const SizedBox(width: 8),
                  Text(
                    hindi ? Brand.nameHi : Brand.name,
                    style: TextStyle(
                      fontFamily:
                          hindi ? AppFonts.devanagari : AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _onColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    hindi ? Brand.taglineHi : Brand.taglineEn,
                    style: TextStyle(
                      fontFamily: hindi ? AppFonts.devanagari : AppFonts.accent,
                      fontSize: 13,
                      color: _onColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
