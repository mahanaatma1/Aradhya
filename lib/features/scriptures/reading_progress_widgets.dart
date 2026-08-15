import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/user/reading_progress.dart';
import 'scripture_models.dart';
import 'scripture_providers.dart';

/// Resume card for the top of `/scriptures` (P3-13).
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final map = ref.watch(readingProgressProvider);
    BookReadingProgress? progress;
    for (final p in map.values) {
      if (progress == null || p.lastReadAt.isAfter(progress.lastReadAt)) {
        progress = p;
      }
    }
    if (progress == null) return const SizedBox.shrink();
    final p = progress;

    final bookAsync = ref.watch(scriptureBookProvider(p.bookId));
    final book = bookAsync.asData?.value;
    if (book == null) {
      return bookAsync.isLoading
          ? const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            )
          : const SizedBox.shrink();
    }

    final scriptures = ref.watch(scripturesProvider).asData?.value;
    Scripture? scripture;
    if (scriptures != null && progress.scriptureId != null) {
      for (final s in scriptures) {
        if (s.id == progress.scriptureId) {
          scripture = s;
          break;
        }
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final pct = progress.percent;
    final verseNo = progress.lastSectionIdx + 1;
    final detail = progress.sectionsTotal > 0
        ? '$pct% · ${book.title(hi)} · ${hi ? 'श्लोक' : 'Verse'} $verseNo'
        : '${book.title(hi)} · ${hi ? 'श्लोक' : 'Verse'} $verseNo';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        color: scheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final sid = p.scriptureId ?? book.scriptureId;
            context.push('/scriptures/$sid/book/${p.bookId}',
                extra: p.lastSectionIdx);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _CoverThumb(
                  cover: scripture?.cover,
                  label: scripture?.name(hi) ?? book.title(hi),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hi ? 'पढ़ना जारी रखें' : 'Continue reading',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      if (progress.sectionsTotal > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.fraction,
                            minHeight: 5,
                            backgroundColor:
                                scheme.outline.withValues(alpha: 0.15),
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final sid = p.scriptureId ?? book.scriptureId;
                    context.push('/scriptures/$sid/book/${p.bookId}',
                        extra: p.lastSectionIdx);
                  },
                  child: Text(hi ? 'जारी' : 'Resume'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final String? cover;
  final String label;
  const _CoverThumb({this.cover, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 56.0;
    if (cover != null && cover!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          cover!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(scheme, size),
        ),
      );
    }
    return _fallback(scheme, size);
  }

  Widget _fallback(ColorScheme scheme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.primary.withValues(alpha: 0.12),
      ),
      child: Icon(Icons.menu_book_rounded, color: scheme.primary, size: 28),
    );
  }
}

/// Thin chapter progress ring on book list rows (P3-13).
class BookProgressRing extends StatelessWidget {
  final BookReadingProgress? progress;
  final double size;
  const BookProgressRing({super.key, this.progress, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (progress == null || progress!.sectionsTotal <= 0) {
      return Icon(Icons.chevron_right_rounded,
          color: scheme.onSurface.withValues(alpha: 0.45));
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress!.fraction,
            strokeWidth: 3,
            backgroundColor: scheme.outline.withValues(alpha: 0.2),
            color: AppColors.terracotta,
          ),
          Text(
            '${progress!.percent}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
