import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import 'journal_models.dart';
import 'journal_providers.dart';

/// Write or edit one entry.
///
/// Autosaves on pause. A journal that loses what you wrote because you did not
/// find the tick button is worse than no journal — and the moment someone is
/// most likely to leave without saving is exactly the moment they have written
/// something difficult.
class JournalEditorScreen extends ConsumerStatefulWidget {
  /// Null for a new entry.
  final int? entryId;
  const JournalEditorScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _body = TextEditingController();
  final _lesson = TextEditingController();
  final _focus = FocusNode();

  Timer? _autosave;
  int? _id;
  String? _mood;
  String? _promptText;
  int? _promptId;
  bool _loaded = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _id = widget.entryId;
    _body.addListener(_onChanged);
    _lesson.addListener(_onChanged);
    if (_id == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _autosave?.cancel();
    // Last chance: whatever is in the field when the screen goes away is kept.
    if (_dirty) _persist();
    _body.dispose();
    _lesson.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    _dirty = true;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 1200), _persist);
  }

  Future<void> _persist() async {
    if (_body.text.trim().isEmpty) return;
    final id = await ref.read(journalProvider.notifier).save(
          id: _id,
          body: _body.text,
          mood: _mood,
          lesson: _lesson.text.trim().isEmpty ? null : _lesson.text.trim(),
          promptId: _promptId,
          promptText: _promptText,
        );
    if (id != null) {
      _id = id;
      _dirty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;

    // Seed once: an existing entry, or today's prompt for a new one.
    if (!_loaded) {
      _loaded = true;
      if (_id != null) {
        final e = ref.read(journalProvider.notifier).byId(_id!);
        if (e != null) {
          _body.text = e.body;
          _lesson.text = e.lesson ?? '';
          _mood = e.mood;
          _promptText = e.promptText;
          _promptId = e.promptId;
        }
      } else {
        final p = ref.read(todaysPromptProvider).valueOrNull;
        if (p != null) {
          _promptId = p.id;
          _promptText = p.prompt(hi);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_id == null
            ? (hi ? 'नई प्रविष्टि' : 'New entry')
            : (hi ? 'प्रविष्टि' : 'Entry')),
        actions: [
          if (_id != null)
            IconButton(
              tooltip: hi ? 'हटाएँ' : 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(hi ? 'यह प्रविष्टि हटाएँ?' : 'Delete this entry?'),
                    content: Text(hi
                        ? 'यह वापस नहीं लाई जा सकती।'
                        : 'This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(hi ? 'रहने दें' : 'Keep')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(hi ? 'हटाएँ' : 'Delete')),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  _autosave?.cancel();
                  _dirty = false;
                  await ref.read(journalProvider.notifier).delete(_id!);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          IconButton(
            tooltip: hi ? 'सहेजें' : 'Save',
            icon: const Icon(Icons.check_rounded),
            onPressed: () async {
              _autosave?.cancel();
              await _persist();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          if (_promptText != null && _promptText!.isNotEmpty) ...[
            Text(
              _promptText!,
              style: TextStyle(
                fontFamily: AppFonts.accent,
                fontSize: 16.5,
                height: 1.45,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _body,
            focusNode: _focus,
            maxLines: null,
            minLines: 10,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16, height: 1.7),
            decoration: InputDecoration(
              hintText: hi ? 'यहाँ लिखें…' : 'Write here…',
              border: InputBorder.none,
              hintStyle: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hi ? 'भाव' : 'MOOD',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in Moods.keys)
                ChoiceChip(
                  label: Text(Moods.label(key, hi)),
                  selected: _mood == key,
                  onSelected: (_) => setState(() {
                    _mood = _mood == key ? null : key;
                    _dirty = true;
                  }),
                  labelStyle: const TextStyle(fontSize: 12.5),
                  selectedColor: scheme.primary.withValues(alpha: 0.14),
                  side: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.25)),
                ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _lesson,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14.5, height: 1.5),
            decoration: InputDecoration(
              labelText: hi ? 'आज क्या सीखा (वैकल्पिक)' : 'What you learned (optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 13, color: scheme.onSurface.withValues(alpha: 0.42)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hi
                      ? 'यह इसी उपकरण पर सहेजा जाता है। स्वतः सहेजा जा रहा है।'
                      : 'Saved on this device only. Autosaving as you write.',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurface.withValues(alpha: 0.48)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
