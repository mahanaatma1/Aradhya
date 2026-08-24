import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import 'search_models.dart';
import 'search_providers.dart';

/// Universal search across everything the app owns.
///
/// Pushed over the shell rather than given a tab: five tabs at 58 px already
/// crowd the Hindi labels, and search is a verb, not a destination.
class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = widget.initialQuery;
      });
    } else {
      // Open with the keyboard up: arriving here means the user already
      // intends to type.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String q) {
    _controller.text = q;
    _controller.selection =
        TextSelection.collapsed(offset: q.length);
    ref.read(searchQueryProvider.notifier).state = q;
    ref.read(recentSearchesProvider.notifier).add(q);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final query = ref.watch(searchQueryProvider);
    final stale = ref.watch(searchIndexStaleProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchField(
          controller: _controller,
          focusNode: _focus,
          hindi: hi,
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
          onSubmitted: (v) =>
              ref.read(recentSearchesProvider.notifier).add(v),
          onClear: () {
            _controller.clear();
            ref.read(searchQueryProvider.notifier).state = '';
            _focus.requestFocus();
          },
        ),
      ),
      body: Column(
        children: [
          if (stale) _StaleIndexBanner(hindi: hi),
          if (query.trim().length >= 2) _KindChips(hindi: hi),
          Expanded(
            child: query.trim().length < 2
                ? _EmptyState(hindi: hi, onPick: _submit)
                : _Results(hindi: hi, onOpened: _submit),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hindi;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hindi,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.surface,
          hintText: hindi ? 'मंदिर, श्लोक, मंत्र…' : 'Temples, verses, mantras…',
          prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: onClear,
                  ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide:
                BorderSide(color: scheme.primary.withValues(alpha: 0.65)),
          ),
        ),
      ),
    );
  }
}

/// Shown when the bundled index was built against a different content.sqlite.
/// Results may deep-link to shifted rows, so the app says so and keeps working
/// rather than hiding search or crashing.
class _StaleIndexBanner extends StatelessWidget {
  final bool hindi;
  const _StaleIndexBanner({required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFF9F43).withValues(alpha: 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF9A5B00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hindi
                  ? 'खोज सूची पुरानी है — कुछ परिणाम सही न हों।'
                  : 'Search index is out of date — some results may be off.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A5B00)),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChips extends ConsumerWidget {
  final bool hindi;
  const _KindChips({required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(searchCountsProvider).valueOrNull ?? const {};
    if (counts.isEmpty) return const SizedBox(height: 8);

    final selected = ref.watch(searchKindProvider);
    final scheme = Theme.of(context).colorScheme;
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    Widget chip(String? kind, String label, int n) {
      final on = selected == kind;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$label  $n'),
          selected: on,
          onSelected: (_) =>
              ref.read(searchKindProvider.notifier).state = on ? null : kind,
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? scheme.primary : scheme.onSurface.withValues(alpha: .8),
          ),
          selectedColor: scheme.primary.withValues(alpha: 0.14),
          side: BorderSide(
            color: on
                ? scheme.primary.withValues(alpha: 0.55)
                : scheme.outline.withValues(alpha: 0.25),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(null, hindi ? 'सभी' : 'All', total),
          // Fixed order, so the chip row does not reshuffle as you type.
          for (final k in SearchKinds.chipOrder)
            if ((counts[k] ?? 0) > 0)
              chip(k, hindi ? SearchKinds.of(k).hi : SearchKinds.of(k).en,
                  counts[k]!),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool hindi;
  final ValueChanged<String> onPick;
  const _EmptyState({required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final curated = ref.watch(curatedTermsProvider).valueOrNull ??
        [for (final s in searchSuggestions) (en: s, hi: null)];
    final scheme = Theme.of(context).colorScheme;

    // A curated term carries both spellings; a recent search is a bare string.
    // Both fold to the same documents, so what changes is only the label.
    Widget chips(List<CuratedTerm> items) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in items)
              ActionChip(
                label: Text((hindi && (t.hi?.isNotEmpty ?? false)) ? t.hi! : t.en),
                onPressed: () => onPick(
                    (hindi && (t.hi?.isNotEmpty ?? false)) ? t.hi! : t.en),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
              ),
          ],
        );

    Widget section(String title, List<CuratedTerm> items,
        {bool recentRow = false}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
              const Spacer(),
              if (recentRow)
                TextButton(
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).clear(),
                  child: Text(hindi ? 'साफ़ करें' : 'Clear',
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          chips(items),
          const SizedBox(height: 22),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        section(hindi ? 'हाल की खोज' : 'RECENT',
            [for (final r in recent) (en: r, hi: null)], recentRow: true),
        section(hindi ? 'आज़माएँ' : 'TRY', curated),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  final bool hindi;
  final ValueChanged<String> onOpened;
  const _Results({required this.hindi, required this.onOpened});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final scheme = Theme.of(context).colorScheme;

    return results.when(
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 40),
        child: SizedBox(
            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      )),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            hindi ? 'खोज में समस्या हुई।' : 'Something went wrong with search.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      ),
      data: (hits) {
        if (hits.isEmpty) return _NoResults(hindi: hindi, onPick: onOpened);

        void open(SearchHit hit) {
          onOpened(ref.read(searchQueryProvider));
          // `route` was resolved at index time and validated against the real
          // router, so this can never hit the error page.
          context.push(hit.route);
        }

        Widget tile(SearchHit hit, {bool showKind = true}) => _ResultTile(
              hit: hit,
              hindi: hindi,
              query: ref.read(searchQueryProvider),
              showKind: showKind,
              onTap: () => open(hit),
            );

        // A chosen kind is already a narrowing, so its results stay a plain
        // score-ordered list. Grouping is for the "All" view, where a reader is
        // scanning across kinds and the list is otherwise a wall of verses.
        final kind = ref.watch(searchKindProvider);
        if (kind != null) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: hits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            // Every row is the same kind and the chip above already says which,
            // so the corner label would be the third time a reader is told.
            itemBuilder: (context, i) => tile(hits[i], showKind: false),
          );
        }

        return _GroupedResults(
          hits: hits,
          hindi: hindi,
          tile: (hit) => tile(hit, showKind: false),
        );
      },
    );
  }
}

/// The "All" view, bucketed by kind (SR-01).
///
/// The hits arrive score-ordered, so bucketing them into a [LinkedHashMap]
/// makes the *groups* appear in relevance order too — the kind of the single
/// best hit leads. Each group shows a handful and defers the rest to its own
/// filtered view, because the whole point of grouping is that no one kind (883
/// verses for "hanuman") can bury the others.
class _GroupedResults extends ConsumerWidget {
  final List<SearchHit> hits;
  final bool hindi;
  final Widget Function(SearchHit) tile;
  const _GroupedResults(
      {required this.hits, required this.hindi, required this.tile});

  /// How many rows of one kind to show before "See all". Small on purpose: the
  /// row is a sample that says "this kind has matches", not the kind's results.
  static const _perGroup = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // True totals, so "See all 109" is the real number and not the ~40-row
    // page this view was built from — a kind can have far more matches than
    // reach the top of the score-ordered page.
    final counts = ref.watch(searchCountsProvider).valueOrNull ?? const {};

    final groups = <String, List<SearchHit>>{};
    for (final h in hits) {
      (groups[h.kind] ??= []).add(h);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      final ks = SearchKinds.of(entry.key);
      final shown = entry.value.take(_perGroup).toList();
      final total = counts[entry.key] ?? entry.value.length;

      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(
          children: [
            Icon(ks.icon, size: 15, color: scheme.primary),
            const SizedBox(width: 7),
            // Flexible so a long kind name at a large text scale ellipsizes
            // rather than pushing the count off the right edge and overflowing.
            Flexible(
              child: Text(
                hindi ? ks.hi : ks.en,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ));

      for (final h in shown) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: tile(h),
        ));
      }

      if (total > shown.length) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            // Switching to this kind's chip drops into the flat, score-ordered
            // list for that kind — the same view the chip itself opens.
            onTap: () =>
                ref.read(searchKindProvider.notifier).state = entry.key,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      hindi ? 'सभी $total देखें' : 'See all $total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: scheme.primary),
                ],
              ),
            ),
          ),
        ));
      }

      children.add(const SizedBox(height: 14));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: children,
    );
  }
}

/// The miss: "Nothing found", plus SR-03's "Did you mean" when a single-word
/// query is one edit away from a term the index does hold.
class _NoResults extends ConsumerWidget {
  final bool hindi;
  final ValueChanged<String> onPick;
  const _NoResults({required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = ref.watch(didYouMeanProvider).valueOrNull ?? const [];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: scheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              hindi ? 'कुछ नहीं मिला' : 'Nothing found',
              style:
                  const TextStyle(fontFamily: AppFonts.display, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              hindi
                  ? 'वर्तनी जाँचें, या कोई छोटा शब्द आज़माएँ।'
                  : 'Check the spelling, or try a shorter word.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                hindi ? 'क्या आपका मतलब था' : 'Did you mean',
                style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => onPick(s),
                      side: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.4)),
                      labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchHit hit;
  final bool hindi;
  final String query;
  final VoidCallback onTap;

  /// The kind name in the corner. Off whenever something above the row already
  /// says it — a group heading, or a selected filter chip — because repeating
  /// it costs the title the width it needs and tells the reader nothing.
  final bool showKind;

  const _ResultTile({
    required this.hit,
    required this.hindi,
    required this.query,
    required this.onTap,
    this.showKind = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats = Theme.of(context).extension<CategoryColors>() ??
        CategoryColors.standard;
    final ks = SearchKinds.of(hit.kind);
    final accent = ks.style(cats).gradient.last;

    final subtitle = hit.subtitle(hindi);
    final snippet = hit.snippet(hindi);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ks.style(cats).linear,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ks.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Highlighted(
                    text: hit.title(hindi),
                    query: query,
                    accent: scheme.primary,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: accent.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600)),
                  ],
                  if (snippet != null && snippet.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: scheme.onSurface.withValues(alpha: 0.62))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showKind)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                // Bounded: Hindi kind names ("व्रत कथा") are wider than their
                // English counterparts and would otherwise squeeze the title.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 62),
                  child: Text(
                    hindi ? ks.hi : ks.en,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.onSurface.withValues(alpha: 0.38)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Highlights the matched span so it is obvious *why* a result matched.
///
/// Plain case-insensitive substring matching on purpose: the folded form used
/// by the index does not map back to character offsets in the original string,
/// and a highlight that is occasionally absent is far better than one that is
/// occasionally in the wrong place.
class _Highlighted extends StatelessWidget {
  final String text;
  final String query;
  final Color accent;
  final TextStyle style;

  const _Highlighted({
    required this.text,
    required this.query,
    required this.accent,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final word in q.toLowerCase().split(RegExp(r'\s+'))) {
      if (word.length < 2) continue;
      final idx = lower.indexOf(word, cursor);
      if (idx < 0) continue;
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + word.length),
        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
      ));
      cursor = idx + word.length;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    // `Text.rich`, not a bare `RichText`. RichText defaults to
    // `TextScaler.noScaling`, so at 2x OS text size the title alone would have
    // stayed at 16px beside a subtitle that had grown to 25 — the one line in
    // the tile that ignored the reader's setting. Text also inherits
    // DefaultTextStyle, which is where the colour was being copied in by hand.
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
