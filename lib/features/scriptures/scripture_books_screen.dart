import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/user/user_prefs.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/async_view.dart';
import 'scripture_models.dart';
import 'scripture_providers.dart';

/// Lists the books / chapters (parvas, kandas, adhyayas) of one scripture, with
/// a "Continue reading" tile that jumps to the last verse the user was on.
class ScriptureBooksScreen extends ConsumerWidget {
  final int scriptureId;
  const ScriptureBooksScreen({super.key, required this.scriptureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final books = ref.watch(scriptureBooksProvider(scriptureId));
    final scriptures = ref.watch(scripturesProvider);
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(sharedPrefsProvider);

    final title = scriptures.maybeWhen(
      data: (list) {
        for (final s in list) {
          if (s.id == scriptureId) return s.name(hi);
        }
        return t.catScriptures;
      },
      orElse: () => t.catScriptures,
    );

    // The global "last read" spot, if it belongs to this scripture.
    Map<String, dynamic>? last;
    final raw = prefs.getString(PrefKeys.scriptureLast);
    if (raw != null) {
      try {
        last = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    int? lastBookId;
    int lastIndex = 0;
    if (last != null && last['scriptureId'] == scriptureId) {
      lastBookId = last['bookId'] as int?;
      lastIndex = last['index'] as int? ?? 0;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: books,
        emptyMessage: t.comingSoon,
        isEmpty: (list) => list.isEmpty,
        builder: (list) {
          ScriptureBook? lastBook;
          if (lastBookId != null) {
            for (final b in list) {
              if (b.id == lastBookId) {
                lastBook = b;
                break;
              }
            }
          }
          final hasContinue = lastBook != null;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length + (hasContinue ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (hasContinue && i == 0) {
                return _ContinueTile(
                  book: lastBook!,
                  index: lastIndex,
                  hi: hi,
                  onTap: () => context.push(
                      '/scriptures/$scriptureId/book/${lastBook!.id}',
                      extra: lastIndex),
                );
              }
              final idx = hasContinue ? i - 1 : i;
              final b = list[idx];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    b.title(hi),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: (b.subtitle(hi)?.isNotEmpty ?? false)
                      ? Text(b.subtitle(hi)!,
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.6)))
                      : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  // Resume at the last verse read in this chapter.
                  onTap: () {
                    final pos = prefs
                        .getInt('${PrefKeys.scripturePosPrefix}${b.id}');
                    context.push('/scriptures/$scriptureId/book/${b.id}',
                        extra: pos ?? 0);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// The highlighted "Continue reading" card (chapter + verse) at the top.
class _ContinueTile extends StatelessWidget {
  final ScriptureBook book;
  final int index;
  final bool hi;
  final VoidCallback onTap;
  const _ContinueTile({
    required this.book,
    required this.index,
    required this.hi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.primary.withValues(alpha: 0.10),
      child: ListTile(
        leading: Icon(Icons.play_circle_fill_rounded,
            color: scheme.primary, size: 36),
        title: Text(hi ? 'पढ़ना जारी रखें' : 'Continue reading',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: scheme.primary)),
        subtitle: Text(
            '${book.title(hi)} · ${hi ? 'श्लोक' : 'Verse'} ${index + 1}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
