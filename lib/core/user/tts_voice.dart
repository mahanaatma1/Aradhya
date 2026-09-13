import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';

/// Shared text-to-speech voice preference — used by Breathing and the readers so
/// the chosen voice applies everywhere. Stored per language as "name|locale".

String _voiceKey(bool hi) => hi ? 'tts_voice_hi' : 'tts_voice_en';

/// Point [tts] at the saved voice for [hi], else the default language voice.
/// Fire-and-forget: the platform channel keeps commands ordered, so a following
/// `speak` still uses this voice.
void applyTtsVoice(FlutterTts tts, SharedPreferences prefs, bool hi) {
  final raw = prefs.getString(_voiceKey(hi));
  if (raw != null && raw.contains('|')) {
    final p = raw.split('|');
    tts.setVoice({'name': p[0], 'locale': p[1]});
  } else {
    unawaited(pickOfflineVoice(tts, hi));
  }
}

/// True when the engine reports this voice as usable without a network.
bool isOfflineVoice(Map<String, String> v) =>
    v['network_required'] != '1' &&
    v['network_required'] != 'true' &&
    !(v['features'] ?? '').contains('notInstalled');

int _quality(Map<String, String> v) => switch (v['quality']) {
      'very_high' || '500' => 4,
      'high' || '400' => 3,
      'normal' || '300' => 2,
      _ => 1,
    };

/// All installed voices for [hi], offline ones first, best quality first.
Future<List<Map<String, String>>> ttsVoicesFor(FlutterTts tts, bool hi) async {
  try {
    final raw = await tts.getVoices;
    final want = hi ? 'hi' : 'en';
    final voices = (raw as List)
        .map((v) => (v as Map)
            .map((k, val) => MapEntry(k.toString(), val.toString())))
        .where((v) => (v['locale'] ?? '').toLowerCase().startsWith(want))
        .toList()
      ..sort((a, b) {
        final oa = isOfflineVoice(a) ? 1 : 0, ob = isOfflineVoice(b) ? 1 : 0;
        if (oa != ob) return ob - oa;
        return _quality(b) - _quality(a);
      });
    return voices;
  } catch (_) {
    return const [];
  }
}

/// Selects the best offline voice for [hi] so playback never depends on a
/// network synthesiser. Falls back to `setLanguage` when the engine lists
/// no offline voice; returns whether an offline voice was found.
Future<bool> pickOfflineVoice(FlutterTts tts, bool hi) async {
  final voices = await ttsVoicesFor(tts, hi);
  final offline = voices.where(isOfflineVoice).toList();
  if (offline.isNotEmpty) {
    await tts.setVoice(
        {'name': offline.first['name']!, 'locale': offline.first['locale']!});
    return true;
  }
  await tts.setLanguage(hi ? 'hi-IN' : 'en-US');
  return false;
}

/// Whether any offline voice exists for [hi] (for the readers' notice).
Future<bool> hasOfflineVoice(FlutterTts tts, bool hi) async =>
    (await ttsVoicesFor(tts, hi)).any(isOfflineVoice);

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
  // Network-only voices are hidden: choosing one would make playback fail
  // silently the moment the phone is offline.
  final voices =
      (await ttsVoicesFor(tts, hi)).where(isOfflineVoice).toList();
  if (!context.mounted) return;

  final key = _voiceKey(hi);
  final sample =
      previewText ?? (hi ? 'नमस्ते, यह मेरी आवाज़ है' : 'Hello, this is my voice');

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final currentRaw = prefs.getString(key);
      final selName = (currentRaw != null && currentRaw.contains('|'))
          ? currentRaw.split('|')[0]
          : null;

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
                      '${voices[i]['locale']} · ${hi ? 'ऑफ़लाइन' : 'offline'}',
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
                        tts.speak(sample);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
