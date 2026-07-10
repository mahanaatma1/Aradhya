import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmarks.dart';

/// An AppBar action that toggles a [Bookmark] on/off. Drop into any reader's
/// `actions:` list.
class BookmarkButton extends ConsumerWidget {
  final Bookmark bookmark;
  const BookmarkButton({super.key, required this.bookmark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(bookmarksProvider).any((b) => b.uid == bookmark.uid);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: saved ? 'Remove bookmark' : 'Bookmark',
      onPressed: () async {
        await ref.read(bookmarksProvider.notifier).toggle(bookmark);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(saved ? 'Removed from bookmarks' : 'Bookmarked'),
            ),
          );
        }
      },
      icon: Icon(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: saved ? scheme.primary : null,
      ),
    );
  }
}
