import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/user/reading_progress.dart';
import '../../scriptures/scripture_providers.dart';

/// Resumes at the exact verse someone left off at — the book title, a
/// progress bar, and a tap straight into `/scriptures/book/:id?v=:index`,
/// rather than making a returning reader retrace scripture -> book -> page
/// on their own. Reads the same `readingProgressProvider` the You tab's
/// `YourReadingSection` already aggregates from; this just surfaces its
/// single most useful row (the most recently read book) at the top of Home,
/// where a returning reader actually looks first.
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final progress = ref.watch(readingProgressProvider);
    if (progress.isEmpty) return const SizedBox.shrink();
    final recent = ref.read(readingProgressProvider.notifier).mostRecent;
    if (recent == null) return const SizedBox.shrink();

    final book = ref.watch(scriptureBookProvider(recent.bookId)).valueOrNull;
    // The card names the book, so it stays hidden until that title has
    // actually loaded rather than showing "Continue reading" with nothing
    // to continue.
    if (book == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(
          '/scriptures/book/${recent.bookId}?v=${recent.lastSectionIdx}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7A4A1E), Color(0xFF4A2A10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Color(0xFFE6C34A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hi ? 'पढ़ना जारी रखें' : 'Continue reading',
                      style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE6C34A))),
                  const SizedBox(height: 2),
                  Text(book.title(hi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFFFCEFE2))),
                  if (recent.sectionsTotal > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: recent.fraction,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: const Color(0xFFE6C34A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hi
                          ? '${recent.percent}% पूर्ण'
                          : '${recent.percent}% complete',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFFFCEFE2).withValues(alpha: 0.75)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFE6C34A)),
          ],
        ),
      ),
    );
  }
}
