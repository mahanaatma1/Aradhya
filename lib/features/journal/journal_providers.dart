import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'journal_models.dart';

/// All prompts, from the bundled content database.
final journalPromptsProvider = FutureProvider<List<JournalPrompt>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows =
      await db.raw.rawQuery('SELECT * FROM gyan.journal_prompts ORDER BY id');
  return rows.map(JournalPrompt.fromRow).toList();
});

/// Lets the user draw a different prompt without it being random on rebuild.
final promptOffsetProvider = StateProvider<int>((ref) => 0);

/// Today's prompt.
///
/// Derived from the day-of-year plus a user-controlled offset, so it is stable
/// across a day and across app restarts — a prompt that changed every time the
/// screen rebuilt would be impossible to sit with.
final todaysPromptProvider = FutureProvider<JournalPrompt?>((ref) async {
  final prompts = await ref.watch(journalPromptsProvider.future);
  if (prompts.isEmpty) return null;
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  final offset = ref.watch(promptOffsetProvider);
  return prompts[(dayOfYear + offset) % prompts.length];
});

/// Journal entries, newest first. Local only.
class JournalController extends StateNotifier<List<JournalEntry>> {
  JournalController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  UserDatabase? get _db => _ref.read(userDatabaseProvider);

  Future<void> _load() async {
    final db = _db;
    if (db == null) return;
    try {
      final rows = await db.raw
          .query('journal_entries', orderBy: 'created_at DESC');
      if (!mounted) return;
      state = rows.map(JournalEntry.fromRow).toList();
    } catch (e) {
      debugPrint('JournalController: load failed ($e)');
    }
  }

  Future<int?> save({
    int? id,
    required String body,
    String? mood,
    String? lesson,
    int? promptId,
    String? promptText,
  }) async {
    final db = _db;
    if (db == null || body.trim().isEmpty) return null;
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      if (id == null) {
        final newId = await db.raw.insert('journal_entries', {
          'day_stamp': dayStamp(),
          'prompt_id': promptId,
          'prompt_text': promptText,
          'body': body.trim(),
          'mood': mood,
          'lesson': lesson,
          'is_private': 1,
          'created_at': now,
          'updated_at': now,
        });
        await _load();
        return newId;
      }
      await db.raw.update(
        'journal_entries',
        {
          'body': body.trim(),
          'mood': mood,
          'lesson': lesson,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await _load();
      return id;
    } catch (e) {
      debugPrint('JournalController: save failed ($e)');
      return null;
    }
  }

  Future<void> delete(int id) async {
    state = state.where((e) => e.id != id).toList();
    final db = _db;
    if (db == null) return;
    try {
      await db.raw.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('JournalController: delete failed ($e)');
    }
  }

  JournalEntry? byId(int id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// day -> entry count, for the heatmap.
  Map<String, int> get byDay {
    final out = <String, int>{};
    for (final e in state) {
      out[e.dayStamp] = (out[e.dayStamp] ?? 0) + 1;
    }
    return out;
  }
}

final journalProvider =
    StateNotifierProvider<JournalController, List<JournalEntry>>(
        (ref) => JournalController(ref));
