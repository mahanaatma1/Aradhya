import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/brand.dart';
import '../../core/models/daily_quote.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../../features/widgets/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';
import '../share_card.dart';
import 'app_logo.dart';

/// The verse-of-the-day hero card on Home: vermilion festival card with the
/// Sanskrit line, its translation and source, and four actions — change,
/// save, share (as an image) and pin to the home screen.
class DailyQuoteCard extends ConsumerStatefulWidget {
  final DailyQuote quote;
  const DailyQuoteCard({super.key, required this.quote});

  @override
  ConsumerState<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends ConsumerState<DailyQuoteCard> {
  bool _sharing = false;
  int _pop = 0;

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
    refreshHomeWidgets(ref);
  }

  Future<void> _save() async {
    final saved = ref.read(bookmarksProvider).any((b) => b.uid == _bookmark.uid);
    await ref.read(bookmarksProvider.notifier).toggle(_bookmark);
    if (!mounted) return;
    setState(() => _pop++);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    showAppSnack(
      context,
      saved
          ? (hi ? 'सहेजे गए से हटाया' : 'Removed from bookmarks')
          : (hi ? 'सहेजा गया' : 'Saved to bookmarks'),
      kind: saved ? NoticeKind.info : NoticeKind.success,
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
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
      if (mounted) showAppSnack(context, 'Could not share: $e', kind: NoticeKind.danger);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.colors;
    final hindi = Localizations.localeOf(context).languageCode == 'hi';
    final saved = ref.watch(bookmarksProvider).any((b) => b.uid == _bookmark.uid);
    final on = c.inkOnAccent;

    return AccentCard(
      style: CategoryStyle(c.accentGradient),
      padding: const EdgeInsets.fromLTRB(Space.x5, Space.x4, Space.x5, Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Eyebrow(t.verseOfTheDay, color: on.withValues(alpha: .85))),
            if (quote.source(hindi) != null)
              ScriptText(quote.source(hindi)!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on.withValues(alpha: .85))),
          ]),
          AnimatedSwitcher(
            duration: Motion.slow,
            switchInCurve: Motion.emphasized,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(quote.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quote.sanskrit != null) ...[
                  const SizedBox(height: Space.x3),
                  ScriptText(
                    quote.sanskrit!,
                    style: context.type.verse.copyWith(color: on, fontSize: 18),
                  ),
                ],
                const SizedBox(height: Space.x2),
                ScriptText(
                  quote.text(hindi),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontFamilyFallback: AppFonts.fallback,
                    fontSize: 16,
                    height: 1.4,
                    color: on,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x3),
          Divider(height: 1, color: on.withValues(alpha: .25)),
          const SizedBox(height: Space.x2),
          Row(children: [
            _Action(icon: Icons.autorenew_rounded, label: hindi ? 'बदलें' : 'Change', onTap: _change, on: on),
            const Spacer(),
            Reveal(
              key: ValueKey(_pop),
              kind: RevealKind.pop,
              duration: Motion.base,
              child: _Action(
                icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: hindi ? 'सहेजें' : 'Save',
                onTap: _save,
                on: on,
              ),
            ),
            _Action(
              icon: Icons.ios_share_rounded,
              label: hindi ? 'साझा' : 'Share',
              onTap: _sharing ? null : _share,
              busy: _sharing,
              on: on,
            ),
            _Action(
              icon: Icons.widgets_rounded,
              tooltip: hindi ? 'होम पर जोड़ें' : 'Add to home',
              onTap: () => pinVerseWidget(ref),
              on: on,
            ),
          ]),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.onTap,
    required this.on,
    this.label,
    this.tooltip,
    this.busy = false,
  });
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool busy;
  final Color on;

  @override
  Widget build(BuildContext context) {
    final child = PressScale(
      enabled: onTap != null,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: label == null ? Space.x2 : Space.x3),
        decoration: BoxDecoration(
          color: on.withValues(alpha: .16),
          borderRadius: Radii.rPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: on))
            else
              Icon(icon, size: 18, color: on),
            if (label != null) ...[
              const SizedBox(width: Space.x1),
              ScriptText(label!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on)),
            ],
          ],
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

/// The branded verse card rendered offscreen for sharing — same look as the
/// Home card with the wordmark footer and no actions.
class _VerseShareCard extends StatelessWidget {
  final DailyQuote quote;
  final bool hindi;
  const _VerseShareCard({required this.quote, required this.hindi});

  @override
  Widget build(BuildContext context) {
    const on = Palette.white;
    return SizedBox(
      width: 420,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.vermilion400, Palette.vermilion500, Palette.vermilion600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Stack(children: [
          const Positioned.fill(child: BandhaniDots(opacity: .18)),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (hindi ? 'आज का श्लोक' : 'Verse of the day').toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontFamilyFallback: AppFonts.fallback,
                    fontSize: 12,
                    letterSpacing: hindi ? 0.2 : 2,
                    fontWeight: FontWeight.w700,
                    color: on.withValues(alpha: 0.85),
                  ),
                ),
                if (quote.sanskrit != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    quote.sanskrit!,
                    style: const TextStyle(
                      fontFamily: AppFonts.devanagari,
                      fontFamilyFallback: AppFonts.fallback,
                      fontSize: 21,
                      height: 1.55,
                      color: on,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  quote.text(hindi),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontFamilyFallback: AppFonts.fallback,
                    fontSize: 18,
                    height: 1.45,
                    color: on,
                  ),
                ),
                if (quote.source(hindi) != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    '— ${quote.source(hindi)}',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontFamilyFallback: AppFonts.fallback,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                Divider(height: 28, thickness: 1, color: on.withValues(alpha: 0.25)),
                Row(children: [
                  const AppLogo(size: 30, tile: false),
                  const SizedBox(width: 8),
                  Text(
                    hindi ? Brand.nameHi : Brand.name,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontFamilyFallback: AppFonts.fallback,
                      fontSize: 18,
                      color: on,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    hindi ? Brand.taglineHi : Brand.taglineEn,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontFamilyFallback: AppFonts.fallback,
                      fontSize: 13,
                      color: on.withValues(alpha: 0.85),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
