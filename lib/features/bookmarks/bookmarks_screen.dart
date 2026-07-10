import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../devotional/devotional_models.dart';
import '../stories/story_models.dart';

/// Everything the user has bookmarked across aartis, chalisas, mantras and
/// stories. Tapping re-fetches the source row and opens its reader.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final items = ref.watch(bookmarksProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'सहेजे गए' : 'Bookmarks')),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border_rounded,
                        size: 56,
                        color: scheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      hi
                          ? 'अभी तक कुछ सहेजा नहीं गया।\nपढ़ते समय 🔖 दबाएँ।'
                          : 'Nothing saved yet.\nTap 🔖 while reading to bookmark.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final b = items[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(_iconFor(b.kind), color: scheme.primary),
                    title: Text(hi ? (b.titleHi ?? b.titleEn) : b.titleEn,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w600)),
                    subtitle: b.subtitle == null ? null : Text(b.subtitle!),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () =>
                          ref.read(bookmarksProvider.notifier).toggle(b),
                    ),
                    onTap: () => _open(context, ref, b),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'aarti' => Icons.local_fire_department_rounded,
        'chalisa' => Icons.auto_stories_rounded,
        'mantra' => Icons.self_improvement_rounded,
        'story' => Icons.article_rounded,
        'verse' => Icons.format_quote_rounded,
        'shloka' => Icons.menu_book_rounded,
        _ => Icons.bookmark_rounded,
      };

  Future<void> _open(
      BuildContext context, WidgetRef ref, Bookmark b) async {
    final db = await ref.read(contentDbProvider.future);
    if (!context.mounted) return;
    switch (b.kind) {
      case 'aarti':
      case 'chalisa':
        final table = b.kind == 'aarti' ? 'aartis' : 'chalisas';
        final rows =
            await db.raw.query(table, where: 'id=?', whereArgs: [b.id]);
        if (rows.isEmpty || !context.mounted) return;
        context.push('/read-lyrics', extra: DevotionalItem.fromRow(rows.first));
      case 'mantra':
        final rows =
            await db.raw.query('mantras', where: 'id=?', whereArgs: [b.id]);
        if (rows.isEmpty || !context.mounted) return;
        context.push('/read-mantra', extra: Mantra.fromRow(rows.first));
      case 'story':
        final rows =
            await db.raw.query('stories', where: 'id=?', whereArgs: [b.id]);
        if (rows.isEmpty || !context.mounted) return;
        context.push('/read-story', extra: Story.fromRow(rows.first));
      case 'shloka':
        // id encodes chapter + 1-based verse: bookId * 100000 + verseNo.
        final bookId = b.id ~/ 100000;
        final verse = (b.id % 100000) - 1;
        context.push('/scriptures/book/$bookId',
            extra: verse > 0 ? verse : null);
    }
  }
}
