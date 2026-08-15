import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../devotional/devotional_models.dart';
import '../stories/story_models.dart';
import 'bookmark_search.dart';

enum _BookmarkSort { recent, title }

/// Saved items across the app — notes and tags stay on-device only.
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _search = TextEditingController();
  String? _kindFilter;
  _BookmarkSort _sort = _BookmarkSort.recent;
  String? _noteExpandedUid;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final all = ref.watch(bookmarksProvider);
    final scheme = Theme.of(context).colorScheme;
    final q = _search.text;

    final kinds = all.map((b) => b.kind).toSet().toList()..sort();
    var items = all.where((b) {
      if (_kindFilter != null && b.kind != _kindFilter) return false;
      return bookmarkMatchesQuery(b, q, hindi: hi);
    }).toList();

    items = switch (_sort) {
      _BookmarkSort.recent => items
        ..sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
      _BookmarkSort.title => items
        ..sort((a, b) {
          final ta = hi ? (a.titleHi ?? a.titleEn) : a.titleEn;
          final tb = hi ? (b.titleHi ?? b.titleEn) : b.titleEn;
          return ta.toLowerCase().compareTo(tb.toLowerCase());
        }),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'सहेजे गए' : 'Bookmarks'),
        actions: [
          PopupMenuButton<_BookmarkSort>(
            tooltip: hi ? 'क्रम' : 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _BookmarkSort.recent,
                child: Text(hi ? 'हाल के' : 'Recent'),
              ),
              PopupMenuItem(
                value: _BookmarkSort.title,
                child: Text(hi ? 'शीर्षक (A–Z)' : 'Title (A–Z)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hi ? 'शीर्षक, नोट, टैग…' : 'Title, notes, tags…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (kinds.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _KindChip(
                    label: hi ? 'सभी' : 'All',
                    selected: _kindFilter == null,
                    onTap: () => setState(() => _kindFilter = null),
                  ),
                  for (final k in kinds)
                    _KindChip(
                      label: _kindLabel(k, hi),
                      selected: _kindFilter == k,
                      onTap: () => setState(
                          () => _kindFilter = _kindFilter == k ? null : k),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: all.isEmpty
                ? _EmptyState(hi: hi)
                : items.isEmpty
                    ? Center(
                        child: Text(
                          hi ? 'कोई मेल नहीं' : 'No matches',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.55)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _BookmarkCard(
                          bookmark: items[i],
                          hi: hi,
                          noteExpanded: _noteExpandedUid == items[i].uid,
                          onToggleNote: () => setState(() {
                            _noteExpandedUid = _noteExpandedUid == items[i].uid
                                ? null
                                : items[i].uid;
                          }),
                          onOpen: () => _open(context, ref, items[i]),
                          onRemove: () =>
                              ref.read(bookmarksProvider.notifier).toggle(items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
      BuildContext context, WidgetRef ref, Bookmark b) async {
    if (b.kind == 'shloka') {
      final bookId = b.id ~/ 100000;
      final verse = (b.id % 100000) - 1;
      context.push('/scriptures/book/$bookId',
          extra: verse > 0 ? verse : null);
      return;
    }
    if (b.isNavigable) {
      context.push(b.route);
      return;
    }

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
      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(isHindiProvider)
                  ? 'यह सहेजा गया आइटम खोला नहीं जा सकता'
                  : 'This saved item cannot be opened'),
            ),
          );
        }
    }
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _KindChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color:
              selected ? scheme.primary : scheme.onSurface.withValues(alpha: .8),
        ),
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.outline.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _BookmarkCard extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final bool hi;
  final bool noteExpanded;
  final VoidCallback onToggleNote;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.hi,
    required this.noteExpanded,
    required this.onToggleNote,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  ConsumerState<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends ConsumerState<_BookmarkCard> {
  late final TextEditingController _noteCtrl;
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.bookmark.note ?? '');
    _noteFocus.addListener(_onNoteFocus);
  }

  @override
  void didUpdateWidget(covariant _BookmarkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookmark.uid != widget.bookmark.uid ||
        oldWidget.bookmark.note != widget.bookmark.note) {
      _noteCtrl.text = widget.bookmark.note ?? '';
    }
  }

  void _onNoteFocus() {
    if (!_noteFocus.hasFocus) _saveNote();
  }

  Future<void> _saveNote() async {
    final uid = widget.bookmark.uid;
    await ref.read(bookmarksProvider.notifier).setNote(uid, _noteCtrl.text);
  }

  Future<void> _addTag() async {
    final hi = widget.hi;
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text(hi ? 'टैग जोड़ें' : 'Add tag'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hi ? 'उदा. भक्ति' : 'e.g. devotion',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(hi ? 'रद्द' : 'Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(hi ? 'जोड़ें' : 'Add'),
            ),
          ],
        );
      },
    );
    if (tag == null || tag.trim().isEmpty) return;
    final next = [...widget.bookmark.tags, tag.trim()];
    await ref.read(bookmarksProvider.notifier).setTags(widget.bookmark.uid, next);
  }

  @override
  void dispose() {
    _noteFocus.removeListener(_onNoteFocus);
    _noteFocus.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bookmark;
    final hi = widget.hi;
    final scheme = Theme.of(context).colorScheme;
    final title = hi ? (b.titleHi ?? b.titleEn) : b.titleEn;
    final hasNote = (b.note ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: b.isNavigable || b.kind == 'shloka' ? widget.onOpen : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          scheme.primary.withValues(alpha: 0.12),
                      child: Icon(_iconFor(b.kind),
                          size: 20, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (b.subtitle != null && b.subtitle!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                b.subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.62),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _kindLabel(b.kind, hi),
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: hi ? 'नोट' : 'Note',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onToggleNote,
                      icon: Icon(
                        hasNote || widget.noteExpanded
                            ? Icons.sticky_note_2_rounded
                            : Icons.sticky_note_2_outlined,
                        color: hasNote || widget.noteExpanded
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    IconButton(
                      tooltip: hi ? 'हटाएँ' : 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onRemove,
                      icon: Icon(Icons.close_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
                if (widget.noteExpanded) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    focusNode: _noteFocus,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: hi
                          ? 'आपका निजी नोट…'
                          : 'Your private note…',
                      filled: true,
                      fillColor: scheme.surface.withValues(alpha: 0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onEditingComplete: () => _noteFocus.unfocus(),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in b.tags)
                      InputChip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                        onDeleted: () async {
                          final next = b.tags.where((x) => x != t).toList();
                          await ref
                              .read(bookmarksProvider.notifier)
                              .setTags(b.uid, next);
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text(hi ? 'टैग' : 'Tag'),
                      visualDensity: VisualDensity.compact,
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (!b.isNavigable && b.kind != 'shloka')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      hi ? 'खोलने योग्य नहीं (पुराना सहेजा)' : 'Not openable (legacy save)',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.error.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hi;
  const _EmptyState({required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded,
                size: 56, color: scheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              hi
                  ? 'अभी तक कुछ सहेजा नहीं गया।\nपढ़ते समय 🔖 दबाएँ।'
                  : 'Nothing saved yet.\nTap 🔖 while reading to bookmark.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

String _kindLabel(String kind, bool hi) => switch (kind) {
      'aarti' => hi ? 'आरती' : 'Aarti',
      'chalisa' => hi ? 'चालीसा' : 'Chalisa',
      'mantra' => hi ? 'मंत्र' : 'Mantra',
      'story' => hi ? 'कथा' : 'Story',
      'shloka' => hi ? 'श्लोक' : 'Shloka',
      'verse' => hi ? 'श्लोक' : 'Verse',
      'entity' => hi ? 'ज्ञान' : 'Knowledge',
      'temple' => hi ? 'मंदिर' : 'Temple',
      'festival' => hi ? 'त्योहार' : 'Festival',
      'scene' => hi ? 'दृश्य' : 'Scene',
      _ => kind,
    };

IconData _iconFor(String kind) => switch (kind) {
      'aarti' => Icons.local_fire_department_rounded,
      'chalisa' => Icons.auto_stories_rounded,
      'mantra' => Icons.self_improvement_rounded,
      'story' => Icons.article_rounded,
      'verse' => Icons.format_quote_rounded,
      'shloka' => Icons.menu_book_rounded,
      'entity' => Icons.hub_rounded,
      'temple' => Icons.temple_hindu_rounded,
      'festival' => Icons.celebration_rounded,
      'scene' => Icons.movie_filter_rounded,
      _ => Icons.bookmark_rounded,
    };
