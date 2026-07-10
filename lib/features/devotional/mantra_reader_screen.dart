import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmark_button.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/tts_voice.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/widgets/stitched_border.dart';
import 'deity_accent.dart';
import 'devotional_models.dart';

/// Mantra reader: Sanskrit hero → transliteration → meaning → how-to-chant,
/// each as its own labelled block. Our own vertical rhythm.
class MantraReaderScreen extends ConsumerStatefulWidget {
  final Mantra mantra;
  const MantraReaderScreen({super.key, required this.mantra});

  @override
  ConsumerState<MantraReaderScreen> createState() =>
      _MantraReaderScreenState();
}

class _MantraReaderScreenState extends ConsumerState<MantraReaderScreen> {
  final _tts = _MantraTts();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mantra = widget.mantra;
    final hi = ref.watch(localeProvider).languageCode == 'hi';
    final accent = DeityAccent.of(mantra.deity);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(mantra.title(hi), style: const TextStyle(fontSize: 18)),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _tts.speaking,
            builder: (_, speaking, _) => IconButton(
              icon: Icon(
                  speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: speaking ? scheme.error : null),
              tooltip: speaking ? (hi ? 'रोकें' : 'Stop') : (hi ? 'सुनें' : 'Listen'),
              onPressed: () => _tts.toggle(mantra.sanskrit,
                  mantra.translation(hi), hi, ref.read(sharedPrefsProvider)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            tooltip: hi ? 'आवाज़' : 'Voice',
            onPressed: () =>
                _tts.chooseVoice(context, ref.read(sharedPrefsProvider), hi),
          ),
          BookmarkButton(
            bookmark: Bookmark(
              kind: 'mantra',
              id: mantra.id,
              titleEn: mantra.titleEn,
              titleHi: mantra.titleHi,
              subtitle: mantra.deity,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Sanskrit hero on a stitched terracotta panel
          if (mantra.sanskrit != null)
            StitchedCard(
              gradient: const LinearGradient(
                colors: [AppColors.terracotta, AppColors.terracottaDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              stitchColor: Colors.white.withValues(alpha: 0.6),
              radius: 20,
              padding: const EdgeInsets.all(22),
              child: Text(
                mantra.sanskrit!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.devanagari,
                  fontSize: 21,
                  height: 1.7,
                  color: Color(0xFFFDEEDE),
                ),
              ),
            ),
          const SizedBox(height: 18),
          if (mantra.iast != null)
            _Block(
              label: 'Transliteration',
              accent: accent.color,
              child: Text(mantra.iast!,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, fontSize: 16, height: 1.6)),
            ),
          if (mantra.translation(hi) != null)
            _Block(
              label: hi ? 'अर्थ' : 'Meaning',
              accent: accent.color,
              child: Text(mantra.translation(hi)!,
                  style: TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      fontFamily: hi ? AppFonts.devanagari : AppFonts.body)),
            ),
          if (mantra.summary(hi) != null)
            _Block(
              label: hi ? 'महत्व' : 'Significance',
              accent: accent.color,
              child: Text(mantra.summary(hi)!,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      fontFamily: hi ? AppFonts.devanagari : AppFonts.body)),
            ),
          if (mantra.howToChant(hi) != null)
            _InfoCard(
              icon: Icons.self_improvement_rounded,
              label: hi ? 'कैसे जप करें' : 'How to chant',
              text: mantra.howToChant(hi)!,
              accent: accent.color,
              hi: hi,
            ),
        ],
      ),
    );
  }
}

/// Reads the mantra aloud — the Sanskrit (Hindi voice) then its meaning (in the
/// reader's language) — and opens the shared voice chooser.
class _MantraTts {
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

  Future<void> toggle(String? sanskrit, String? meaning, bool hindi,
      SharedPreferences prefs) async {
    if (speaking.value) {
      await stop();
      return;
    }
    await _ensure();
    speaking.value = true;
    try {
      final skt = sanskrit?.trim() ?? '';
      if (skt.isNotEmpty) {
        applyTtsVoice(_tts, prefs, true); // Sanskrit reads in Hindi
        await _tts.speak(skt);
      }
      final m = meaning?.trim() ?? '';
      if (speaking.value && m.isNotEmpty) {
        applyTtsVoice(_tts, prefs, hindi);
        await _tts.speak(m);
      }
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

class _Block extends StatelessWidget {
  final String label;
  final Color accent;
  final Widget child;
  const _Block({required this.label, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color accent;
  final bool hi;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.text,
    required this.accent,
    required this.hi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: accent, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontFamily: hi ? AppFonts.devanagari : AppFonts.body)),
        ],
      ),
    );
  }
}
