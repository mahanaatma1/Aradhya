import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/user/bookmarks.dart';

/// RD-04's missing action: a private note on a verse.
///
/// Notes have nowhere of their own to live. `bookmarks.note` already exists,
/// the Bookmarks screen already edits it, and `BookmarksController.setNote`
/// already writes it — what was missing was any way to reach it from the one
/// screen where a reader is actually reading. So a verse note is a note on the
/// verse's bookmark row, and there is no second table for it.
///
/// That has one consequence worth stating in the UI rather than hiding:
/// `setNote` returns silently when the bookmark does not exist, so writing a
/// note on an unsaved verse would vanish. Saving a note therefore bookmarks the
/// verse. This is not a liberty — a note *is* someone saying "keep this" — but
/// it is a thing the app does on their behalf, so the sheet says so out loud
/// before they type, not in a snackbar afterwards.
Future<void> showVerseNoteSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Bookmark bookmark,
  required String reference,
  required bool hindi,
}) async {
  final existing = ref
      .read(bookmarksProvider)
      .where((b) => b.uid == bookmark.uid)
      .firstOrNull;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _VerseNoteSheet(
        bookmark: bookmark,
        reference: reference,
        hindi: hindi,
        initialNote: existing?.note,
        alreadySaved: existing != null,
      ),
    ),
  );
}

class _VerseNoteSheet extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final String reference;
  final bool hindi;
  final String? initialNote;
  final bool alreadySaved;

  const _VerseNoteSheet({
    required this.bookmark,
    required this.reference,
    required this.hindi,
    required this.initialNote,
    required this.alreadySaved,
  });

  @override
  ConsumerState<_VerseNoteSheet> createState() => _VerseNoteSheetState();
}

class _VerseNoteSheetState extends ConsumerState<_VerseNoteSheet> {
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final hi = widget.hindi;
    final text = _note.text.trim();
    final notes = ref.read(bookmarksProvider.notifier);

    // A note needs a row to live on, and `setNote` is a no-op without one.
    // Clearing a note does NOT unbookmark: removing the words a reader wrote
    // is not a request to throw the verse away too.
    if (!notes.contains(widget.bookmark.uid) && text.isNotEmpty) {
      await notes.toggle(widget.bookmark);
    }
    await notes.setNote(widget.bookmark.uid, text.isEmpty ? null : text);

    if (!mounted) return;
    Navigator.pop(context);
    final was = (widget.initialNote ?? '').isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text.isEmpty
          ? (was
              ? (hi ? 'नोट हटाया गया' : 'Note removed')
              : (hi ? 'कुछ लिखा नहीं गया' : 'Nothing written'))
          : (hi ? 'नोट सहेजा गया' : 'Note saved')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hi = widget.hindi;
    // The bookmark is created by saving, so the line is only worth showing to
    // someone for whom it is still news.
    final willSave = !widget.alreadySaved;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hi ? 'आपका नोट' : 'Your note',
            style: TextStyle(
              fontFamily: hi ? AppFonts.devanagari : AppFonts.display,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.reference,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            style: TextStyle(
              fontFamily: hi ? AppFonts.devanagari : AppFonts.body,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: hi
                  ? 'यह श्लोक आपसे क्या कहता है…'
                  : 'What this verse says to you…',
              filled: true,
              fillColor: scheme.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 15, color: scheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  willSave
                      ? (hi
                          ? 'नोट सहेजने पर यह श्लोक भी सहेजा जाएगा, ताकि आप इसे फिर पा सकें। नोट इसी उपकरण पर रहता है।'
                          : 'Saving a note bookmarks this verse too, so you can find it again. The note stays on this device.')
                      : (hi
                          ? 'नोट इसी उपकरण पर रहता है।'
                          : 'The note stays on this device.'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.pop(context),
                  child: Text(hi ? 'रद्द करें' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(hi ? 'सहेजें' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
