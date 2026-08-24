
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/brand.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/tts_voice.dart';
import '../../core/user/reading_progress.dart';
import '../../core/user/user_prefs.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/share_card.dart';
import '../related/related_rail.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/stitched_border.dart';
import 'scripture_models.dart';
import 'scripture_providers.dart';
import 'verse_note_sheet.dart';
import 'verse_tabs.dart';

/// The verse reader for one book/chapter, styled after the reference app:
/// centred verse number → Sanskrit → transliteration → a short divider →
/// translation → a collapsible commentary. A top action row offers Listen
/// (text-to-speech), Share and Bookmark; a floating Prev / n·of·total / Next
/// pill pages through the shlokas (Ramayana kandas run to thousands).
class SectionReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final int initialIndex;
  const SectionReaderScreen(
      {super.key, required this.bookId, this.initialIndex = 0});

  @override
  ConsumerState<SectionReaderScreen> createState() =>
      _SectionReaderScreenState();
}

class _SectionReaderScreenState extends ConsumerState<SectionReaderScreen> {
  late int _index = widget.initialIndex;
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  final _tts = _ReaderTts();
  bool _autoPlay = false; // continuous read-aloud through the chapter
  bool _autoAdvancing = false; // guards programmatic page jumps
  bool _savedInitial = false;

  @override
  void dispose() {
    _autoPlay = false;
    _controller.dispose();
    _tts.dispose();
    super.dispose();
  }

  void _goto(int index) {
    _stopAll();
    if (_controller.hasClients) {
      _controller.jumpToPage(index);
    } else {
      setState(() => _index = index);
    }
  }

  void _stopAll() {
    _autoPlay = false;
    _tts.stop();
    if (mounted) setState(() {});
  }

  /// Persist reading position to SQLite (+ legacy prefs for one release).
  Future<void> _saveProgress(int i, int? scriptureId, int sectionsTotal) async {
    await ref.read(readingProgressProvider.notifier).recordSection(
          bookId: widget.bookId,
          scriptureId: scriptureId,
          sectionIndex: i,
          sectionsTotal: sectionsTotal,
        );
  }

  Future<ScriptureSection?> _resolveSection(int index) async {
    final chunk = index ~/ kReaderPageSize;
    final pos = index % kReaderPageSize;
    final list = await ref.read(
        scriptureSectionPageProvider((bookId: widget.bookId, page: chunk))
            .future);
    return pos < list.length ? list[pos] : null;
  }

  /// Continuous read-aloud: confirm once, then speak each verse and auto-advance
  /// to the next until the chapter ends or the user stops / swipes away.
  Future<void> _toggleAutoPlay(int count, bool hi) async {
    if (_autoPlay) {
      _stopAll();
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hi ? 'सस्वर पाठ' : 'Read aloud'),
        content: Text(hi
            ? 'पूरा अध्याय सस्वर पढ़ें? यह अपने आप अगले श्लोक पर जाता रहेगा।'
            : 'Read the whole chapter aloud? It will move to the next verse automatically.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(hi ? 'रद्द करें' : 'Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(hi ? 'पढ़ें' : 'Read')),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final prefs = ref.read(sharedPrefsProvider);
    setState(() => _autoPlay = true);
    var i = _index;
    while (_autoPlay && mounted) {
      final section = await _resolveSection(i);
      if (section == null) break;
      await _tts.playVerse(
          section.sanskrit, section.body(hi), section.commentary(hi), hi, prefs);
      if (!_autoPlay || !mounted || i >= count - 1) break;
      i += 1;
      _autoAdvancing = true; // reset inside onPageChanged
      if (_controller.hasClients) {
        _controller.jumpToPage(i);
      } else {
        setState(() => _index = i);
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (mounted) setState(() => _autoPlay = false);
  }

  Future<void> _promptJump(int count, bool hi) async {
    final controller = TextEditingController(text: '${_index + 1}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hi ? 'श्लोक पर जाएँ' : 'Jump to verse'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: '1 – $count'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(hi ? 'रद्द करें' : 'Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text(hi ? 'जाएँ' : 'Go'),
          ),
        ],
      ),
    );
    if (result != null) _goto((result - 1).clamp(0, count - 1));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    final bookAsync = ref.watch(scriptureBookProvider(widget.bookId));
    final countAsync = ref.watch(scriptureSectionCountProvider(widget.bookId));

    final book = bookAsync.asData?.value;
    final title = book?.title(hi) ?? t.catScriptures;

    // The scripture this book belongs to, for the Context tab (RD-01). Watched
    // here rather than in the verse page so the list is resolved once for the
    // whole chapter instead of on every swipe.
    String? scriptureName;
    final scriptures = ref.watch(scripturesProvider).asData?.value;
    if (scriptures != null && book != null) {
      for (final s in scriptures) {
        if (s.id == book.scriptureId) {
          scriptureName = s.name(hi);
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title,
            style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
        bottom: countAsync.asData?.value != null && countAsync.asData!.value > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / countAsync.asData!.value,
                  minHeight: 4,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.12),
                  color: AppColors.terracotta,
                ),
              )
            : null,
      ),
      body: countAsync.when(
        loading: () => const SkeletonReader(),
        error: (e, _) => Center(child: Text('$e')),
        data: (count) {
          if (count == 0) return Center(child: Text(t.comingSoon));
          if (_index >= count) _index = count - 1;

          // The currently-visible verse, resolved from its cached chunk, so the
          // top action row (share / bookmark / listen) always acts on it.
          final chunk = _index ~/ kReaderPageSize;
          final pos = _index % kReaderPageSize;
          final pageAsync = ref.watch(
              scriptureSectionPageProvider((bookId: widget.bookId, page: chunk)));
          final current = pageAsync.asData?.value;
          final section =
              (current != null && pos < current.length) ? current[pos] : null;

          // Backfill section totals and record the starting position once.
          // Deferred by a frame on purpose: both calls set a StateNotifier's
          // state synchronously, and doing that from inside a build only works
          // by accident — it works in the app because the reader is pushed as a
          // route, in its own build pass, and it throws the moment the reader is
          // mounted in the same frame as its ProviderScope. A widget test does
          // exactly that, and so would any caller that inlined this screen.
          if (!_savedInitial && book != null) {
            _savedInitial = true;
            final scriptureId = book.scriptureId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref.read(readingProgressProvider.notifier).ensureBookOpen(
                    bookId: widget.bookId,
                    scriptureId: scriptureId,
                    sectionsTotal: count,
                  );
              _saveProgress(_index, scriptureId, count);
            });
          }

          return Column(
            children: [
              _ActionRow(
                section: section,
                book: book,
                bookId: widget.bookId,
                index: _index,
                hi: hi,
                tts: _tts,
                autoPlay: _autoPlay,
                onListen: section == null
                    ? null
                    : () {
                        if (_autoPlay) {
                          _stopAll();
                        } else {
                          _tts.toggle(
                              section.sanskrit,
                              section.body(hi),
                              section.commentary(hi),
                              hi,
                              ref.read(sharedPrefsProvider));
                        }
                      },
                onAutoPlay: () => _toggleAutoPlay(count, hi),
              ),
              Divider(
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15)),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (i) {
                    if (_autoAdvancing) {
                      _autoAdvancing = false; // programmatic auto-advance
                    } else {
                      _tts.stop();
                      _autoPlay = false; // a manual swipe stops continuous play
                    }
                    setState(() => _index = i);
                    _saveProgress(i, book?.scriptureId, count);
                  },
                  itemBuilder: (ctx, i) => _VersePage(
                    bookId: widget.bookId,
                    index: i,
                    hindi: hi,
                    book: book,
                    scriptureName: scriptureName,
                    count: count,
                  ),
                ),
              ),
              _PagerPill(
                index: _index,
                count: count,
                hi: hi,
                onPrev: _index > 0 ? () => _goto(_index - 1) : null,
                onNext: _index < count - 1 ? () => _goto(_index + 1) : null,
                onTapCount: () => _promptJump(count, hi),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wraps [FlutterTts]: reads the Sanskrit (hi-IN) then the translation (in the
/// reader's language), and exposes a [speaking] flag so the button can toggle.
class _ReaderTts {
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> speaking = ValueNotifier(false);
  bool _init = false;

  Future<void> _ensure() async {
    if (_init) return;
    _init = true;
    await _tts.awaitSpeakCompletion(true);
    _tts.setCancelHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) => speaking.value = false);
  }

  Future<void> toggle(String? sanskrit, String? body, String? commentary,
      bool hindi, SharedPreferences prefs) async {
    if (speaking.value) {
      await stop();
      return;
    }
    await _ensure();
    speaking.value = true;
    try {
      final skt = sanskrit?.trim() ?? '';
      if (skt.isNotEmpty) {
        applyTtsVoice(_tts, prefs, true); // Sanskrit reads in Hindi
        await _tts.speak(skt);
      }
      // Translation + commentary read in the reader's language.
      applyTtsVoice(_tts, prefs, hindi);
      final tr = body?.trim() ?? '';
      if (speaking.value && tr.isNotEmpty) await _tts.speak(tr);
      final com = commentary?.trim() ?? '';
      if (speaking.value && com.isNotEmpty) await _tts.speak(com);
    } finally {
      speaking.value = false;
    }
  }

  /// Speak one verse and return when it finishes (for continuous auto-play).
  /// Like [toggle] but without the "if already speaking, stop" early return.
  Future<void> playVerse(String? sanskrit, String? body, String? commentary,
      bool hindi, SharedPreferences prefs) async {
    await _ensure();
    speaking.value = true;
    try {
      final skt = sanskrit?.trim() ?? '';
      if (skt.isNotEmpty) {
        applyTtsVoice(_tts, prefs, true);
        await _tts.speak(skt);
      }
      applyTtsVoice(_tts, prefs, hindi);
      final tr = body?.trim() ?? '';
      if (speaking.value && tr.isNotEmpty) await _tts.speak(tr);
      final com = commentary?.trim() ?? '';
      if (speaking.value && com.isNotEmpty) await _tts.speak(com);
    } finally {
      speaking.value = false;
    }
  }

  /// Open the shared voice chooser for the reader's TTS.
  Future<void> chooseVoice(
          BuildContext context, SharedPreferences prefs, bool hi) =>
      showVoicePicker(context: context, tts: _tts, prefs: prefs, hi: hi);

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }

  void dispose() {
    _tts.stop();
    speaking.dispose();
  }
}

/// The top action row: Listen · Share · Bookmark, then a text-size menu and the
/// EN/हिं language toggle — acting on the currently-visible verse.
class _ActionRow extends ConsumerWidget {
  final ScriptureSection? section;
  final ScriptureBook? book;
  final int bookId;
  final int index;
  final bool hi;
  final _ReaderTts tts;
  final bool autoPlay;
  final VoidCallback? onListen;
  final VoidCallback? onAutoPlay;
  const _ActionRow({
    required this.section,
    required this.book,
    required this.bookId,
    required this.index,
    required this.hi,
    required this.tts,
    required this.autoPlay,
    required this.onListen,
    required this.onAutoPlay,
  });

  String get _verseNo =>
      section?.number.isNotEmpty == true ? section!.number : '${index + 1}';

  Bookmark _bookmark() {
    // Show a snippet of the translation so the Bookmarks list has real detail.
    final snippet = section?.body(hi) ?? '';
    final trimmed =
        snippet.length > 60 ? '${snippet.substring(0, 60).trim()}…' : snippet;
    final label = (hi ? 'श्लोक ' : 'Verse ') + _verseNo;
    return Bookmark(
      // 'shloka' keeps scripture verses distinct from the daily 'verse' quote.
      kind: 'shloka',
      // Unique per verse: chapter id + 1-based verse number.
      id: bookId * 100000 + (index + 1),
      titleEn: book?.titleEn ?? 'Verse',
      titleHi: book?.titleHi,
      subtitle: trimmed.isEmpty ? label : '$label · $trimmed',
      // `?v=` carries the verse. Without it a bookmark on verse 47 reopened the
      // chapter at verse 1, which reads as the bookmark having been lost — the
      // router has understood this parameter since the route was registered.
      route: '/scriptures/book/$bookId?v=$index',
    );
  }

  void _share(BuildContext context) {
    final s = section;
    if (s == null) return;
    final ref = book?.title(hi) ?? '';
    final caption = <String>[
      if (s.sanskrit?.isNotEmpty == true) s.sanskrit!,
      if (s.body(hi)?.isNotEmpty == true) s.body(hi)!,
      '',
      '— $ref $_verseNo',
      '${Brand.name} · ${hi ? Brand.taglineHi : Brand.taglineEn}',
    ].join('\n');
    shareCardImage(
      context: context,
      card: _VerseShareCard(
          section: s, reference: '$ref $_verseNo', hindi: hi),
      text: caption,
      filename: 'aradhya_shloka.png',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ready = section != null;
    final marks = ref.watch(bookmarksProvider);
    final uid = ready ? _bookmark().uid : '';
    final saved = ready && marks.any((b) => b.uid == uid);
    // A note is shown as written, not as saveable — a filled sticky-note icon
    // is the only clue on this screen that one exists at all.
    final hasNote = ready &&
        marks
            .where((b) => b.uid == uid)
            .any((b) => (b.note ?? '').isNotEmpty);

    Widget action(IconData icon, String tip, VoidCallback? onTap,
            {Color? color}) =>
        IconButton(
          icon: Icon(icon, color: color ?? scheme.primary),
          tooltip: tip,
          onPressed: onTap,
          iconSize: 22,
        );

    // Ordered by how much a reader would miss it, because on a narrow phone the
    // tail of this row is what scrolls out of sight. Seven 48-pixel targets plus
    // the size button want 340 logical pixels and a 320-wide phone has 304, so
    // something has to go — and it must not be the bookmark. Shrinking the
    // buttons instead was the other option and a worse one: 48 is the smallest
    // target a thumb can be asked to hit.
    final actions = <Widget>[
      action(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        saved
            ? (hi ? 'हटाएँ' : 'Remove bookmark')
            : (hi ? 'सहेजें' : 'Bookmark'),
        ready
            ? () => ref.read(bookmarksProvider.notifier).toggle(_bookmark())
            : null,
      ),
      action(
        hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
        hasNote
            ? (hi ? 'नोट देखें' : 'Edit note')
            : (hi ? 'नोट जोड़ें' : 'Add note'),
        ready
            ? () => showVerseNoteSheet(
                  context: context,
                  ref: ref,
                  bookmark: _bookmark(),
                  reference: '${book?.title(hi) ?? ''} $_verseNo'.trim(),
                  hindi: hi,
                )
            : null,
        color: hasNote ? AppColors.terracotta : scheme.primary,
      ),
      // Listen — this verse only.
      ValueListenableBuilder<bool>(
        valueListenable: tts.speaking,
        builder: (_, speaking, _) {
          final active = speaking && !autoPlay;
          return action(
            active ? Icons.stop_rounded : Icons.volume_up_rounded,
            active ? (hi ? 'रोकें' : 'Stop') : (hi ? 'सुनें' : 'Listen'),
            (ready && !autoPlay) ? onListen : null,
            color: active ? scheme.error : scheme.primary,
          );
        },
      ),
      action(Icons.ios_share_rounded, hi ? 'साझा करें' : 'Share',
          ready ? () => _share(context) : null),
      // Auto-play — read the whole chapter, auto-advancing.
      action(
        autoPlay ? Icons.stop_circle_rounded : Icons.playlist_play_rounded,
        autoPlay ? (hi ? 'पाठ बंद' : 'Stop') : (hi ? 'सस्वर पाठ' : 'Read all'),
        ready ? onAutoPlay : null,
        color: autoPlay ? scheme.error : scheme.primary,
      ),
      // Last on purpose: choosing a voice is a setting, and the only control
      // here that is not about the verse in front of the reader.
      action(Icons.record_voice_over_outlined, hi ? 'आवाज़' : 'Voice',
          () => tts.chooseVoice(context, ref.read(sharedPrefsProvider), hi)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Never clipped, so a control that does not fit can still be
              // reached; and the leading edge stays put, so the bookmark is
              // always the button under the reader's left thumb.
              child: Row(children: actions),
            ),
          ),
          // Pinned outside the scroller: text size is how a reader gets out of
          // a size that is too big to read, so it cannot be the thing that a
          // size that is too big pushes off the screen.
          _FontSizeButton(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// A single verse page, resolved from its cached chunk so swiping through
/// thousands of shlokas never loads a whole kanda at once.
class _VersePage extends ConsumerWidget {
  final int bookId;
  final int index;
  final bool hindi;
  final ScriptureBook? book;
  final String? scriptureName;
  final int count;
  const _VersePage({
    required this.bookId,
    required this.index,
    required this.hindi,
    required this.book,
    required this.scriptureName,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunk = index ~/ kReaderPageSize;
    final pos = index % kReaderPageSize;
    final async = ref
        .watch(scriptureSectionPageProvider((bookId: bookId, page: chunk)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (pos >= list.length) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: _ShlokaBody(
            section: list[pos],
            hindi: hindi,
            book: book,
            scriptureName: scriptureName,
            index: index,
            count: count,
          ),
        );
      },
    );
  }
}

class _ShlokaBody extends ConsumerWidget {
  final ScriptureSection section;
  final bool hindi;
  final ScriptureBook? book;
  final String? scriptureName;
  final int index;
  final int count;
  const _ShlokaBody({
    required this.section,
    required this.hindi,
    required this.book,
    required this.scriptureName,
    required this.index,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readerFontScaleProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verse number (centred, gold).
        if (section.number.isNotEmpty)
          Text(
            section.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.secondary,
            ),
          ),
        const SizedBox(height: 14),

        // Sanskrit shloka (centred).
        if (section.sanskrit?.isNotEmpty == true)
          Text(
            section.sanskrit!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.devanagari,
              fontSize: 20 * scale,
              height: 1.7,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),

        // Transliteration (IAST) — shown in both languages now.
        if (section.transliteration?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            section.transliteration!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14 * scale,
              height: 1.55,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],

        // Short centred divider, then the four facets of the verse.
        const SizedBox(height: 22),
        Center(
          child: Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // RD-01. Meaning · Explanation · Word meaning · Context. The
        // translation used to sit here unlabelled with the commentary stacked
        // under it, which reads fine on a Gita verse and is misleading
        // everywhere else: 27,189 of 27,890 sections have no commentary, so
        // the page simply ended after the translation with no indication that
        // anything was meant to follow. The tabs name the four facets, and
        // each says why it is empty when it is (RD-02).
        VerseTabStrip(section: section, hindi: hindi, scale: scale),
        Divider(
            height: 1, color: scheme.outline.withValues(alpha: 0.15)),
        const SizedBox(height: 18),
        VerseTabPanel(
          section: section,
          book: book,
          scriptureName: scriptureName,
          index: index,
          count: count,
          hindi: hindi,
          scale: scale,
        ),

        // RD-03. The reader sits on the richest content in the app and was the
        // only detail surface with no way out of it -- a verse knew nothing
        // about the figures in it, the story around it, or the mantra drawn
        // from it, while 2,958 related edges already existed. Bottom padding
        // clears the floating pager pill.
        Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: RelatedRail(
            src: 'content',
            table: 'scripture_sections',
            id: section.id,
          ),
        ),
      ],
    );
  }
}

/// Floating pill at the bottom: ‹ Prev · "n / total" · Next ›.
class _PagerPill extends StatelessWidget {
  final int index; // 0-based
  final int count;
  final bool hi;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTapCount;
  const _PagerPill({
    required this.index,
    required this.count,
    required this.hi,
    required this.onPrev,
    required this.onNext,
    required this.onTapCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget btn(String label, IconData icon, VoidCallback? onTap,
        {required bool filled,
        required bool leading,
        required bool showLabel}) {
      final enabled = onTap != null;
      final fg = filled
          ? scheme.onPrimary
          : (enabled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.3));
      return Material(
        color: filled
            ? (enabled ? scheme.primary : scheme.primary.withValues(alpha: 0.4))
            : scheme.primary.withValues(alpha: enabled ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 16 : 14, vertical: 10),
            child: Semantics(
              // The label is what named this button when it had one; dropping
              // the word must not drop it from the screen reader too.
              label: label,
              button: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading) Icon(icon, size: 18, color: fg),
                  if (leading && showLabel) const SizedBox(width: 4),
                  if (showLabel)
                    ExcludeSemantics(
                      child: Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: fg)),
                    ),
                  if (!leading && showLabel) const SizedBox(width: 4),
                  if (!leading) Icon(icon, size: 18, color: fg),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final prev = hi ? 'पिछला' : 'Prev';
    final next = hi ? 'अगला' : 'Next';
    final counter = '${index + 1} / $count';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: LayoutBuilder(
          builder: (context, box) {
            // Whether the two words fit, measured rather than guessed. At the
            // OS's largest accessibility scale on a 320-wide phone the labelled
            // buttons plus the counter want about 360 logical pixels and this
            // row has 288, which used to overflow by 74. The chevrons carry the
            // meaning on their own, and the counter — the one thing a reader at
            // that scale is trying to read — keeps its space.
            final style = DefaultTextStyle.of(context)
                .style
                .copyWith(fontWeight: FontWeight.w700);
            final scaler = MediaQuery.textScalerOf(context);
            double textWidth(String s) => (TextPainter(
                  text: TextSpan(text: s, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                  maxLines: 1,
                )..layout())
                .width;

            const chrome = 16 * 2 + 18 + 4; // padding + chevron + its gap
            final wanted = textWidth(prev) +
                textWidth(next) +
                textWidth(counter) +
                chrome * 2 +
                24; // breathing room either side of the counter
            final showLabel = wanted <= box.maxWidth;

            return Row(
              children: [
                btn(prev, Icons.chevron_left_rounded, onPrev,
                    filled: false, leading: true, showLabel: showLabel),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onTapCount,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        counter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                btn(next, Icons.chevron_right_rounded, onNext,
                    filled: true, leading: false, showLabel: showLabel),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FontSizeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = Localizations.localeOf(context).languageCode == 'hi';
    return PopupMenuButton<double>(
      icon: const Icon(Icons.format_size_rounded),
      tooltip: hi ? 'अक्षर आकार' : 'Text size',
      onSelected: (v) => ref.read(readerFontScaleProvider.notifier).set(v),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0.9, child: Text(hi ? 'छोटा' : 'Small')),
        PopupMenuItem(value: 1.0, child: Text(hi ? 'सामान्य' : 'Default')),
        PopupMenuItem(value: 1.2, child: Text(hi ? 'बड़ा' : 'Large')),
        PopupMenuItem(
            value: 1.4, child: Text(hi ? 'बहुत बड़ा' : 'Extra large')),
      ],
    );
  }
}

/// The branded verse card rendered off-screen and captured to a PNG for
/// sharing — Sanskrit + translation with the Aradhya wordmark footer.
class _VerseShareCard extends StatelessWidget {
  final ScriptureSection section;
  final String reference;
  final bool hindi;
  const _VerseShareCard(
      {required this.section, required this.reference, required this.hindi});

  static const _onColor = Color(0xFFFDEEDE);

  @override
  Widget build(BuildContext context) {
    final body = section.body(hindi);
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
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reference.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: _onColor.withValues(alpha: 0.82),
                ),
              ),
              if (section.sanskrit?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(
                  section.sanskrit!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.devanagari,
                    fontSize: 20,
                    height: 1.6,
                    color: _onColor,
                  ),
                ),
              ],
              if (body != null) ...[
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily:
                        hindi ? AppFonts.devanagari : AppFonts.display,
                    fontSize: 16,
                    height: 1.5,
                    color: _onColor,
                  ),
                ),
              ],
              Divider(
                  height: 28,
                  thickness: 1,
                  color: _onColor.withValues(alpha: 0.2)),
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
                      fontFamily:
                          hindi ? AppFonts.devanagari : AppFonts.accent,
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
