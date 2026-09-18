import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';

/// Shared text-to-speech voice preference — used by Breathing and the readers so
/// the chosen voice applies everywhere. Stored per language as "name|locale".

String _voiceKey(bool hi) => hi ? 'tts_voice_hi' : 'tts_voice_en';

const _rateKey = 'tts_rate';
const _pitchKey = 'tts_pitch';

/// Unhurried by default. On Android `setSpeechRate` is not linear and 1.0 is
/// already brisk; devotional reading wants roughly 0.40–0.50. Sanskrit gets a
/// further slowdown (see [ttsRate]) because the syllables are dense.
const double kTtsRateDefault = 0.44;

/// Slightly below the 1.0 default reads as calmer without turning muddy, which
/// is what happens under about 0.85.
const double kTtsPitchDefault = 0.92;

/// Sanskrit is read by a Hindi voice that has no model of its vowel lengths, so
/// it runs away at a normal rate. Slowing it proportionally keeps it followable.
const double kSanskritRateFactor = 0.85;

double ttsRate(SharedPreferences prefs, {bool sanskrit = false}) {
  final base = prefs.getDouble(_rateKey) ?? kTtsRateDefault;
  return (sanskrit ? base * kSanskritRateFactor : base).clamp(0.1, 1.0);
}

double ttsPitch(SharedPreferences prefs) =>
    (prefs.getDouble(_pitchKey) ?? kTtsPitchDefault).clamp(0.5, 2.0);

Future<void> setTtsRate(SharedPreferences prefs, double v) =>
    prefs.setDouble(_rateKey, v);

Future<void> setTtsPitch(SharedPreferences prefs, double v) =>
    prefs.setDouble(_pitchKey, v);

/// Point [tts] at the saved voice for [hi], else the default language voice,
/// and apply the saved rate and pitch. Pass [sanskrit] when the text is a
/// shloka so it is paced slower than surrounding prose.
///
/// Fire-and-forget: the platform channel keeps commands ordered, so a following
/// `speak` still uses these settings.
void applyTtsVoice(
  FlutterTts tts,
  SharedPreferences prefs,
  bool hi, {
  bool sanskrit = false,
}) {
  final raw = prefs.getString(_voiceKey(hi));
  if (raw != null && raw.contains('|')) {
    final p = raw.split('|');
    tts.setVoice({'name': p[0], 'locale': p[1]});
  } else {
    tts.setLanguage(hi ? 'hi-IN' : 'en-US');
  }
  tts.setSpeechRate(ttsRate(prefs, sanskrit: sanskrit));
  tts.setPitch(ttsPitch(prefs));
}

/// Split [text] at clause boundaries so it can be spoken in short utterances.
///
/// This is what makes synthesized reading sound unhurried: the engine flattens
/// a long blob into one breathless run, whereas separate utterances land a real
/// pause at each boundary. Danda (।/॥) is kept because it is where a shloka
/// actually breathes.
List<String> ttsChunks(String text) {
  final parts = text
      .split(RegExp(r'(?<=[।॥.!?;:])\s+|\n+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return parts.isEmpty ? const [] : parts;
}

/// Speak [text] clause by clause, pausing [gapMs] between them.
///
/// Returns early if [keepGoing] stops returning true, so a Stop button still
/// takes effect mid-passage. Requires `awaitSpeakCompletion(true)`.
Future<void> speakSmooth(
  FlutterTts tts,
  String text, {
  int gapMs = 220,
  bool Function()? keepGoing,
}) async {
  for (final part in ttsChunks(text)) {
    if (keepGoing != null && !keepGoing()) return;
    await tts.speak(part);
    if (gapMs > 0) {
      if (keepGoing != null && !keepGoing()) return;
      await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
  }
}

/// A reusable voice chooser. Lists the device's TTS voices for the current
/// language under friendly names (Voice 1, Voice 2 …), lets you preview each,
/// and persists the choice.
Future<void> showVoicePicker({
  required BuildContext context,
  required FlutterTts tts,
  required SharedPreferences prefs,
  required bool hi,
  String? previewText,
}) async {
  var voices = <Map<String, String>>[];
  try {
    final raw = await tts.getVoices;
    final want = hi ? 'hi' : 'en';
    voices = (raw as List)
        .map((v) => (v as Map)
            .map((k, val) => MapEntry(k.toString(), val.toString())))
        .where((v) => (v['locale'] ?? '').toLowerCase().startsWith(want))
        .toList();
  } catch (_) {}
  if (!context.mounted) return;

  final key = _voiceKey(hi);
  final sample =
      previewText ?? (hi ? 'नमस्ते, यह मेरी आवाज़ है' : 'Hello, this is my voice');

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
      final scheme = Theme.of(ctx).colorScheme;
      final currentRaw = prefs.getString(key);
      final selName = (currentRaw != null && currentRaw.contains('|'))
          ? currentRaw.split('|')[0]
          : null;

      // Speed and pitch apply to every reader, so they live beside the voice
      // list rather than being duplicated per screen.
      Widget slider({
        required String label,
        required double value,
        required double min,
        required double max,
        required ValueChanged<double> onChanged,
      }) =>
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: [
                SizedBox(width: 86, child: Text(label)),
                Expanded(
                  child: Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: ((max - min) * 100).round(),
                    label: value.toStringAsFixed(2),
                    onChanged: (v) => setSheetState(() => onChanged(v)),
                    onChangeEnd: (_) {
                      applyTtsVoice(tts, prefs, hi);
                      tts.speak(sample);
                    },
                  ),
                ),
              ],
            ),
          );

      Widget tile(String title, String? sub, bool selected, VoidCallback onTap,
              {VoidCallback? onPreview}) =>
          ListTile(
            onTap: onTap,
            leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: scheme.primary),
            title: Text(title),
            subtitle: sub == null
                ? null
                : Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: onPreview == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    tooltip: hi ? 'सुनें' : 'Preview',
                    onPressed: onPreview,
                  ),
          );

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                  '${hi ? 'आवाज़ चुनें' : 'Choose a voice'}  (${voices.length})',
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  tile(hi ? 'डिफ़ॉल्ट' : 'Default', null, selName == null, () {
                    prefs.remove(key);
                    Navigator.pop(ctx);
                  }),
                  if (voices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(hi
                          ? 'इस डिवाइस पर कोई अन्य आवाज़ नहीं मिली'
                          : 'No other voices installed on this device'),
                    ),
                  for (var i = 0; i < voices.length; i++)
                    tile(
                      '${hi ? 'आवाज़' : 'Voice'} ${i + 1}',
                      voices[i]['locale'],
                      voices[i]['name'] == selName,
                      () {
                        prefs.setString(
                            key, '${voices[i]['name']}|${voices[i]['locale']}');
                        Navigator.pop(ctx);
                      },
                      onPreview: () {
                        tts.setVoice({
                          'name': voices[i]['name']!,
                          'locale': voices[i]['locale']!
                        });
                        tts.setSpeechRate(ttsRate(prefs));
                        tts.setPitch(ttsPitch(prefs));
                        tts.speak(sample);
                      },
                    ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(hi ? 'गति और स्वर' : 'Speed & pitch',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  slider(
                    label: hi ? 'गति' : 'Speed',
                    value: ttsRate(prefs),
                    min: 0.25,
                    max: 0.75,
                    onChanged: (v) => setTtsRate(prefs, v),
                  ),
                  slider(
                    label: hi ? 'स्वर' : 'Pitch',
                    value: ttsPitch(prefs),
                    min: 0.75,
                    max: 1.25,
                    onChanged: (v) => setTtsPitch(prefs, v),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: TextButton(
                      onPressed: () => setSheetState(() {
                        setTtsRate(prefs, kTtsRateDefault);
                        setTtsPitch(prefs, kTtsPitchDefault);
                      }),
                      child: Text(hi ? 'रीसेट करें' : 'Reset'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
      },
    ),
  );
}
