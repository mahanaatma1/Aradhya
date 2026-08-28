import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../search/search_providers.dart';
import 'ask_models.dart';
import 'ask_repository.dart';

/// The whole curated set. Small enough (hundreds of rows) to rank in memory,
/// which keeps the matcher one testable pure function instead of SQL.
final qaPairsProvider = FutureProvider<List<QaPair>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery('SELECT * FROM gyan.qa_pairs');
  return rows.map(QaPair.fromRow).toList();
});

final askRepositoryProvider = Provider((ref) => const AskRepository());

/// Suggested questions for the empty state — high-confidence rows only.
final suggestedQuestionsProvider = FutureProvider<List<QaPair>>((ref) async {
  final all = await ref.watch(qaPairsProvider.future);
  return all.where((p) => p.confidence == 'high').take(6).toList();
});

/// The current question. Held in a notifier rather than recomputed in build so
/// the "consulting" pause is a state change, not a rebuild side effect.
class AskController extends StateNotifier<AskResult> {
  AskController(this._ref) : super(AskResult.empty);

  final Ref _ref;
  bool _busy = false;
  bool get busy => _busy;

  Future<void> ask(String question) async {
    if (question.trim().isEmpty) {
      state = AskResult.empty;
      return;
    }
    _busy = true;
    // A short, honest pause. Retrieval is instant; the beat exists so the
    // answer does not appear before the reader has finished asking.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final all = await _ref.read(qaPairsProvider.future);
    var result = _ref.read(askRepositoryProvider).ask(question, all);

    // AK-02: the curated set is small (hundreds of rows) and will not have
    // everything. Rather than leave a not-sure reader with only "closest
    // questions" drawn from that same small set, fall back to the 27,890
    // indexed shlokas — the same search index and ranking the rest of the
    // app already uses, restricted to kind 'shloka'.
    if (result.outcome == AskOutcome.notSure) {
      final search = await _ref.read(searchRepositoryProvider.future);
      final hits =
          await search.search(question, kind: 'shloka', limit: 5);
      if (hits.isNotEmpty) {
        result = AskResult(AskOutcome.notSure,
            candidates: result.candidates, verseFallback: hits);
      }
    }

    _busy = false;
    if (mounted) state = result;
  }

  void clear() => state = AskResult.empty;
}

final askControllerProvider =
    StateNotifierProvider<AskController, AskResult>((ref) => AskController(ref));

/// Where a scripture section sits: its book, and its index within that book.
///
/// qa_pairs stores a section id, but the reader is addressed by book plus
/// verse index (`/scriptures/book/3?v=46`). This resolves one into the other
/// with a single query rather than adding a second reader entry point.
final verseLocationProvider =
    FutureProvider.family<({int bookId, int index})?, int>((ref, sectionId) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery('''
    SELECT s.book_id AS book_id,
           (SELECT COUNT(*) FROM scripture_sections s2
             WHERE s2.book_id = s.book_id AND s2.order_no < s.order_no) AS idx
    FROM scripture_sections s WHERE s.id = ? LIMIT 1
  ''', [sectionId]);
  if (rows.isEmpty) return null;
  final b = rows.first['book_id'] as int?;
  if (b == null) return null;
  return (bookId: b, index: (rows.first['idx'] as int?) ?? 0);
});
