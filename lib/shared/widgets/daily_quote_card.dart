import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/brand.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/daily_quote.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../../features/widgets/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../share_card.dart';
import 'app_logo.dart';
import 'stitched_border.dart';

/// The verse-of-the-day hero card on Home. Below the verse sit three actions:
/// change (shuffle to another verse), save (bookmark), and share (as an image).
class DailyQuoteCard extends ConsumerStatefulWidget {
  final DailyQuote quote;
  const DailyQuoteCard({super.key, required this.quote});

  @override
  ConsumerState<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends ConsumerState<DailyQuoteCard> {
  bool _sharing = false;

  static const _onColor = Color(0xFFFDEEDE);

  DailyQuote get quote => widget.quote;

  Bookmark get _bookmark => Bookmark(
        kind: 'verse',
        id: quote.id,
        titleEn: quote.en,
        titleHi: quote.hi,
        subtitle: quote.source(false),
      );

  /// Shuffle to a different verse (never the one currently shown).
  void _change() {
    final quotes = ref.read(allDailyQuotesProvider).valueOrNull;
    if (quotes == null || quotes.length < 2) return;
    final current = ref.read(verseIndexOverrideProvider) ??
        verseIndexForToday(quotes.length);
    ref.read(verseIndexOverrideProvider.notifier).state =
        (current + 1) % quotes.length;
    // Reflect the newly-chosen verse on any pinned home-screen widget.
    refreshHomeWidgets(ref);
  }

  Future<void> _save() async {
    final saved = ref.read(bookmarksProvider).any((b) => b.uid == _bookmark.uid);
    await ref.read(bookmarksProvider.notifier).toggle(_bookmark);
    if (!mounted) return;
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(saved
            ? (hi ? 'सहेजे गए से हटाया' : 'Removed from bookmarks')
            : (hi ? 'सहेजा गया' : 'Saved to bookmarks')),
      ),
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final hindi = Localizations.localeOf(context).languageCode == 'hi';
    try {
      final caption = [
        if (quote.sanskrit != null) quote.sanskrit,
        quote.text(hindi),
        if (quote.source(hindi) != null) '— ${quote.source(hindi)}',
        '\n${Brand.name} · ${hindi ? Brand.taglineHi : Brand.taglineEn}',
      ].whereType<String>().join('\n');
      if (!mounted) return;
      await shareCardImage(
        context: context,
        card: _VerseShareCard(quote: quote, hindi: hindi),
        text: caption,
        filename: 'aradhya_verse.png',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not share: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hindi = Localizations.localeOf(context).languageCode == 'hi';
    final saved = ref.watch(bookmarksProvider).any((b) => b.uid == _bookmark.uid);

    return StitchedCard(
      gradient: const LinearGradient(
        colors: [AppColors.terracotta, AppColors.terracottaDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      stitchColor: Colors.white.withValues(alpha: 0.6),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.verseOfTheDay.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: _onColor.withValues(alpha: 0.82),
            ),
          ),
          if (quote.sanskrit != null) ...[
            const SizedBox(height: 10),
            Text(
              quote.sanskrit!,
              style: const TextStyle(
                fontFamily: AppFonts.devanagari,
                fontSize: 17,
                height: 1.5,
                color: _onColor,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            quote.text(hindi),
            style: TextStyle(
              fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
              fontSize: 15,
              height: 1.4,
              color: _onColor,
            ),
          ),
          if (quote.source(hindi) != null) ...[
            const SizedBox(height: 12),
            Text(
              '— ${quote.source(hindi)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _onColor.withValues(alpha: 0.85),
              ),
            ),
          ],
          Divider(
            height: 22,
            thickness: 1,
            color: _onColor.withValues(alpha: 0.18),
          ),
          Row(
            children: [
              _CardAction(
                icon: Icons.autorenew_rounded,
                label: hindi ? 'बदलें' : 'Change',
                onTap: _change,
              ),
              const Spacer(),
              _CardAction(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: hindi ? 'सहेजें' : 'Save',
                onTap: _save,
              ),
              const SizedBox(width: 6),
              _CardAction(
                icon: Icons.ios_share_rounded,
                label: hindi ? 'साझा' : 'Share',
                onTap: _sharing ? null : _share,
                busy: _sharing,
              ),
              const SizedBox(width: 2),
              _CardAction(
                icon: Icons.widgets_rounded,
                label: '',
                tooltip: hindi ? 'होम पर जोड़ें' : 'Add to home',
                onTap: () => pinVerseWidget(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One pill-style action button tinted for the terracotta card. An empty
/// [label] renders an icon-only button (with an optional [tooltip]).
class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool busy;
  const _CardAction({
    required this.icon,
    required this.label,
    this.tooltip,
    required this.onTap,
    this.busy = false,
  });

  static const _onColor = Color(0xFFFDEEDE);

  @override
  Widget build(BuildContext context) {
    final iconOnly = label.isEmpty;
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 8 : 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _onColor),
                    )
                  : Icon(icon, size: 18, color: _onColor),
              if (!iconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _onColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// The clean, branded verse card rendered offscreen for sharing — same look as
/// the Home card but with the wordmark footer and no action buttons.
class _VerseShareCard extends StatelessWidget {
  final DailyQuote quote;
  final bool hindi;
  const _VerseShareCard({required this.quote, required this.hindi});

  static const _onColor = Color(0xFFFDEEDE);

  @override
  Widget build(BuildContext context) {
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
              Text(
                (hindi ? 'आज का श्लोक' : 'Verse of the Day').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: _onColor.withValues(alpha: 0.82),
                ),
              ),
              if (quote.sanskrit != null) ...[
                const SizedBox(height: 14),
                Text(
                  quote.sanskrit!,
                  style: const TextStyle(
                    fontFamily: AppFonts.devanagari,
                    fontSize: 21,
                    height: 1.5,
                    color: _onColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                quote.text(hindi),
                style: TextStyle(
                  fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
                  fontSize: 18,
                  height: 1.45,
                  color: _onColor,
                ),
              ),
              if (quote.source(hindi) != null) ...[
                const SizedBox(height: 14),
                Text(
                  '— ${quote.source(hindi)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _onColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
              Divider(
                height: 28,
                thickness: 1,
                color: _onColor.withValues(alpha: 0.2),
              ),
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
