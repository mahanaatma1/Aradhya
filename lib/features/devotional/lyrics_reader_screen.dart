import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../related/related_rail.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmark_button.dart';
import '../../core/user/bookmarks.dart';
import 'deity_accent.dart';
import 'devotional_models.dart';
import 'devotional_providers.dart';

/// Reads an aarti / chalisa. Our layout: a deity crest header on a warm panel,
/// then the lyrics in a calm serif column with an EN/हिं toggle.
class LyricsReaderScreen extends ConsumerWidget {
  final DevotionalItem item;
  final LyricsKind kind;
  const LyricsReaderScreen(
      {super.key, required this.item, this.kind = LyricsKind.aartis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final hi = locale.languageCode == 'hi';
    final accent = DeityAccent.of(item.deity);
    final lyrics = item.lyrics(hi) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title(hi), style: const TextStyle(fontSize: 18)),
        actions: [
          BookmarkButton(
            bookmark: Bookmark(
              kind: kind == LyricsKind.aartis ? 'aarti' : 'chalisa',
              id: item.id,
              titleEn: item.titleEn,
              titleHi: item.titleHi,
              subtitle: item.deity,
              route:
                  '/read-lyrics?id=${item.id}&kind=${kind == LyricsKind.chalisas ? 'chalisas' : 'aartis'}',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.color.withValues(alpha: 0.18),
                  accent.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(accent.icon, color: accent.color, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title(hi),
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w600,
                              fontSize: 20)),
                      if (item.deity != null)
                        Text(item.deity!,
                            style: TextStyle(color: accent.color, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            lyrics,
            style: TextStyle(
              fontFamily: hi ? AppFonts.devanagari : AppFonts.accent,
              fontSize: 18,
              height: 1.9,
            ),
          ),
          // Temples of this deity, their mantras, puja vidhi and kathas.
          RelatedRail(
            table: kind == LyricsKind.chalisas ? 'chalisas' : 'aartis',
            id: item.id,
          ),
        ],
      ),
    );
  }
}

