import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'scripture_models.dart';

/// RD-01/RD-02. The four facets of a verse, as a strip of tabs under the
/// shloka: what it says, what it means, what each word means, and where it
/// sits.
///
/// Measured coverage across all 27,890 sections, which is what the empty states
/// below are written against:
///
///   Meaning       27,890 (100%)  — `body_en` / `body_hi`
///   Explanation      701 (3%)    — `commentary_*`, **Bhagavad Gita only**
///   Word meaning       0          — no column, and no table anywhere
///   Context       always         — position; plus Ask pairs and story events
///
/// So three of the four tabs are empty on every Ramayana and Upanishad verse,
/// and one of them is empty on all 27,890. That is the honest shape of the
/// data, and the reason each tab states *why* it is empty rather than showing a
/// spinner or a shrug: "Coming soon" on a verse of the Yuddha Kanda would be a
/// promise nobody has undertaken, while "the Gita is the only text here with a
/// commentary" is a fact the reader can act on.
///
/// Word meaning has no data path at all, not merely no rows. `content.sqlite`
/// is the inherited Ishvarvaani fixture -- read-only to the pipeline, and due
/// to be replaced before submission (RG-01/RG-02) -- so nothing may be added to
/// `scripture_sections`. When word-by-word meanings are authored they will land
/// in `gyan.sqlite` keyed on `scripture_section_id`, the way `qa_pairs` already
/// does, and this tab will fill in from there.

/// Which facet the reader is looking at.
enum ReaderTab {
  meaning(en: 'Meaning', hi: 'अर्थ'),
  explanation(en: 'Explanation', hi: 'व्याख्या'),
  wordMeaning(en: 'Word meaning', hi: 'शब्दार्थ'),
  context(en: 'Context', hi: 'प्रसंग');

  const ReaderTab({required this.en, required this.hi});

  final String en;
  final String hi;

  String label(bool hindi) => hindi ? hi : en;
}

/// The selected tab, persisted.
///
/// It lives outside the verse page for a reason that shows up the moment you
/// use the reader: swiping to the next shloka rebuilds the page, and a reader
/// working through a chapter's commentary should not be dropped back on
/// Meaning eighteen times. Persisted for the same reason the font scale is --
/// a deliberate choice should not have to be made again on the next launch.
class ReaderTabChoice extends StateNotifier<ReaderTab> {
  ReaderTabChoice(this._prefs) : super(_restore(_prefs));

  final SharedPreferences _prefs;

  static ReaderTab _restore(SharedPreferences prefs) {
    final saved = prefs.getString(PrefKeys.readerTab);
    for (final t in ReaderTab.values) {
      if (t.name == saved) return t;
    }
    return ReaderTab.meaning;
  }

  Future<void> set(ReaderTab tab) async {
    if (tab == state) return;
    state = tab;
    await _prefs.setString(PrefKeys.readerTab, tab.name);
  }
}

final readerTabProvider = StateNotifierProvider<ReaderTabChoice, ReaderTab>(
    (ref) => ReaderTabChoice(ref.read(sharedPrefsProvider)));

/// An Ask pair that cites this verse as its passage.
typedef VerseQuestion = ({int id, String en, String? hi});

/// A story event whose scene is set at this verse.
typedef VerseEvent = ({int id, String en, String? hi});

/// What the Context tab found beyond the verse's own position.
class VerseContext {
  final List<VerseQuestion> questions;
  final VerseEvent? event;
  const VerseContext({this.questions = const [], this.event});

  bool get isEmpty => questions.isEmpty && event == null;
}

/// Everything in `gyan.sqlite` that points at this verse.
///
/// Both links are soft -- an integer into another database, no foreign key --
/// so both are allowed to find nothing, and today one of them always does:
/// 20 of 20 Ask pairs carry a `scripture_section_id`, and 0 of 79 story events
/// do. The tab is built to grow rather than to be rewritten: AK-01 takes Ask
/// from 20 pairs to 300-500, and SC-11 fills in the story links, and this
/// panel gains both without another change here.
final verseContextProvider =
    FutureProvider.family<VerseContext, int>((ref, sectionId) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const VerseContext();

  final qa = await db.raw.rawQuery('''
    SELECT id, question_en, question_hi FROM gyan.qa_pairs
     WHERE scripture_section_id = ? ORDER BY id
  ''', [sectionId]);
  final events = await db.raw.rawQuery('''
    SELECT id, title_en, title_hi FROM gyan.narrative_nodes
     WHERE scripture_section_id = ? LIMIT 1
  ''', [sectionId]);

  return VerseContext(
    questions: [
      for (final r in qa)
        (
          id: r['id'] as int,
          en: (r['question_en'] as String?) ?? '',
          hi: r['question_hi'] as String?,
        ),
    ],
    event: events.isEmpty
        ? null
        : (
            id: events.first['id'] as int,
            en: (events.first['title_en'] as String?) ?? '',
            hi: events.first['title_hi'] as String?,
          ),
  );
});

/// The tab strip. Scrolls horizontally because it has to: four labels, and
/// "Word meaning" at a 1.6 font scale on a 320dp screen does not fit beside
/// the other three at any weight (RD-06).
///
/// A tab with nothing behind it is shown, not hidden. Hiding would shuffle the
/// remaining tabs sideways as the reader swipes between a Gita verse and a
/// Ramayana one, so the same label would sit in a different place on each --
/// and RD-02 asks for word meaning to be visible and honest rather than
/// absent. Instead an empty tab is dimmed, which tells the reader where not to
/// bother without moving anything.
class VerseTabStrip extends ConsumerWidget {
  final ScriptureSection section;
  final bool hindi;
  final double scale;
  const VerseTabStrip({
    super.key,
    required this.section,
    required this.hindi,
    required this.scale,
  });

  /// Whether a tab has anything to show for *this* verse. Context always does:
  /// a verse always has a book and a number, even when nothing links to it.
  bool _filled(ReaderTab tab) => switch (tab) {
        ReaderTab.meaning => (section.body(hindi) ?? '').trim().isNotEmpty,
        ReaderTab.explanation =>
          (section.commentary(hindi) ?? '').trim().isNotEmpty,
        ReaderTab.wordMeaning => false,
        ReaderTab.context => true,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(readerTabProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in ReaderTab.values)
            _Tab(
              label: tab.label(hindi),
              selected: tab == selected,
              filled: _filled(tab),
              scale: scale,
              hindi: hindi,
              onTap: () => ref.read(readerTabProvider.notifier).set(tab),
              scheme: scheme,
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool filled;
  final double scale;
  final bool hindi;
  final VoidCallback onTap;
  final ColorScheme scheme;
  const _Tab({
    required this.label,
    required this.selected,
    required this.filled,
    required this.scale,
    required this.hindi,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final colour = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: filled ? 0.7 : 0.38);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
                fontSize: 13.5 * scale,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: colour,
              ),
            ),
            const SizedBox(height: 6),
            // The underline is the only selected-state marker, so it has to
            // exist unselected too -- otherwise every tab shifts up by 2px as
            // the selection moves.
            Container(
              height: 2,
              width: 100,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              decoration: BoxDecoration(
                color: selected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The body under the strip: whichever facet is selected.
class VerseTabPanel extends ConsumerWidget {
  final ScriptureSection section;
  final ScriptureBook? book;
  final String? scriptureName;
  final int index; // 0-based position in the book
  final int count; // verses in the book
  final bool hindi;
  final double scale;
  const VerseTabPanel({
    super.key,
    required this.section,
    required this.book,
    required this.scriptureName,
    required this.index,
    required this.count,
    required this.hindi,
    required this.scale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(readerTabProvider)) {
      ReaderTab.meaning => _Prose(
          text: section.body(hindi),
          hindi: hindi,
          scale: scale,
          absent: _Absent(
            icon: Icons.translate_rounded,
            line: hindi
                ? 'इस संस्करण में इस श्लोक का अनुवाद नहीं है।'
                : 'This edition carries no translation for this verse.',
            scale: scale,
            hindi: hindi,
          ),
        ),
      ReaderTab.explanation => _Prose(
          text: section.commentary(hindi),
          hindi: hindi,
          scale: scale,
          absent: _Absent(
            icon: Icons.menu_book_rounded,
            line: hindi
                ? 'इस श्लोक पर कोई व्याख्या दर्ज नहीं है।'
                : 'No commentary is recorded for this verse.',
            // Naming the one text that does have commentary turns a dead end
            // into a direction, and it is true: 701 of 27,890 sections carry
            // one, all of them Gita.
            detail: hindi
                ? 'इस संग्रह में व्याख्या केवल भगवद्गीता के साथ है।'
                : 'In this collection, only the Bhagavad Gita is commented on.',
            scale: scale,
            hindi: hindi,
          ),
        ),
      // RD-02. Always empty, and specific about it: there is no partial data
      // to wait on and no row to fetch, so the state names the unit of work
      // instead of implying one is in flight.
      ReaderTab.wordMeaning => _Absent(
          icon: Icons.spellcheck_rounded,
          line: hindi
              ? 'शब्द-दर-शब्द अर्थ अभी नहीं जोड़ा गया है।'
              : 'Word-by-word meaning has not been added yet.',
          detail: hindi
              ? 'यह पूरे संग्रह के लिए सत्य है — किसी भी श्लोक का शब्दार्थ '
                  'उपलब्ध नहीं है।'
              : 'That is true of the whole collection — no verse has a '
                  'word-by-word breakdown yet.',
          scale: scale,
          hindi: hindi,
        ),
      ReaderTab.context => _ContextPanel(
          section: section,
          book: book,
          scriptureName: scriptureName,
          index: index,
          count: count,
          hindi: hindi,
          scale: scale,
        ),
    };
  }
}

/// A block of prose, or the given empty state when there is none.
class _Prose extends StatelessWidget {
  final String? text;
  final bool hindi;
  final double scale;
  final Widget absent;
  const _Prose({
    required this.text,
    required this.hindi,
    required this.scale,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    final body = (text ?? '').trim();
    if (body.isEmpty) return absent;
    return Text(
      body,
      style: TextStyle(
        fontFamily: hindi ? AppFonts.devanagari : AppFonts.body,
        fontSize: 16 * scale,
        height: 1.62,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Where this verse sits, and what points at it.
///
/// The position line is always there, which is what makes Context worth a tab
/// on a corpus this thin: a reader eleven hundred shlokas into the Yuddha Kanda
/// can lose track of which kanda they are in, and the answer needs no authored
/// data at all.
class _ContextPanel extends ConsumerWidget {
  final ScriptureSection section;
  final ScriptureBook? book;
  final String? scriptureName;
  final int index;
  final int count;
  final bool hindi;
  final double scale;
  const _ContextPanel({
    required this.section,
    required this.book,
    required this.scriptureName,
    required this.index,
    required this.count,
    required this.hindi,
    required this.scale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final extra = ref.watch(verseContextProvider(section.id)).valueOrNull;
    final subtitle = book?.subtitle(hindi);

    Widget line(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17 * scale, color: scheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5 * scale,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily:
                            hindi ? AppFonts.devanagari : AppFonts.display,
                        fontSize: 15 * scale,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scriptureName != null && scriptureName!.isNotEmpty)
          line(Icons.auto_stories_rounded, hindi ? 'ग्रंथ' : 'Scripture',
              scriptureName!),
        if (book != null)
          line(
            Icons.bookmark_outline_rounded,
            hindi ? 'अध्याय' : 'Chapter',
            (subtitle?.isNotEmpty ?? false)
                ? '${book!.title(hindi)} — $subtitle'
                : book!.title(hindi),
          ),
        line(
          Icons.numbers_rounded,
          hindi ? 'स्थान' : 'Position',
          hindi
              ? '${index + 1} / $count'
              : 'Verse ${index + 1} of $count',
        ),

        // Both of these are absent for almost every verse today. They are not
        // announced when missing: unlike the tabs, nothing here promised them,
        // so silence is accurate rather than evasive.
        if (extra?.event != null) ...[
          Divider(
              height: 26, color: scheme.outline.withValues(alpha: 0.15)),
          _LinkRow(
            icon: Icons.theater_comedy_rounded,
            label: hindi ? 'इस श्लोक की कथा' : 'The story set here',
            title: (hindi && (extra!.event!.hi?.isNotEmpty ?? false))
                ? extra.event!.hi!
                : extra!.event!.en,
            scale: scale,
            hindi: hindi,
            onTap: () => context.push('/gyan/scene/${extra.event!.id}'),
          ),
        ],
        if (extra != null && extra.questions.isNotEmpty) ...[
          Divider(
              height: 26, color: scheme.outline.withValues(alpha: 0.15)),
          Text(
            (hindi ? 'यह श्लोक इनका उत्तर देता है' : 'This verse answers')
                .toUpperCase(),
            style: TextStyle(
              fontSize: 10.5 * scale,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          for (final q in extra.questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 15 * scale, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (hindi && (q.hi?.isNotEmpty ?? false)) ? q.hi! : q.en,
                      style: TextStyle(
                        fontFamily:
                            hindi ? AppFonts.devanagari : AppFonts.body,
                        fontSize: 14.5 * scale,
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final double scale;
  final bool hindi;
  final VoidCallback onTap;
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.scale,
    required this.hindi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17 * scale, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5 * scale,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
                      fontSize: 15 * scale,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20 * scale,
                color: scheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

/// An empty tab that says what is missing and, where there is one, what to read
/// instead. Deliberately not a spinner and not "Coming soon" -- both of those
/// tell the reader to wait, and for word meaning there is nothing to wait for.
class _Absent extends StatelessWidget {
  final IconData icon;
  final String line;
  final String? detail;
  final double scale;
  final bool hindi;
  const _Absent({
    required this.icon,
    required this.line,
    this.detail,
    required this.scale,
    required this.hindi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26 * scale,
              color: scheme.onSurface.withValues(alpha: 0.34)),
          const SizedBox(height: 12),
          Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
              fontSize: 14.5 * scale,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: hindi ? AppFonts.devanagari : AppFonts.body,
                fontSize: 13 * scale,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
