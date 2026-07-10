import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'scripture_models.dart';
import 'scripture_repository.dart';

/// Repository, available once the content DB has opened.
final scriptureRepoProvider = FutureProvider<ScriptureRepository>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  return ScriptureRepository(db);
});

/// All scriptures for the list screen.
final scripturesProvider = FutureProvider<List<Scripture>>((ref) async {
  final repo = await ref.watch(scriptureRepoProvider.future);
  return repo.scriptures();
});

/// Books/chapters for a given scripture id.
final scriptureBooksProvider =
    FutureProvider.family<List<ScriptureBook>, int>((ref, scriptureId) async {
  final repo = await ref.watch(scriptureRepoProvider.future);
  return repo.books(scriptureId);
});

/// Verses per page in the reader.
const kReaderPageSize = 20;

/// Total verse/section count for a book (drives the page count).
final scriptureSectionCountProvider =
    FutureProvider.family<int, int>((ref, bookId) async {
  final repo = await ref.watch(scriptureRepoProvider.future);
  return repo.sectionCount(bookId);
});

/// One page of sections for the reader, keyed by (bookId, page).
typedef SectionPageKey = ({int bookId, int page});

final scriptureSectionPageProvider =
    FutureProvider.family<List<ScriptureSection>, SectionPageKey>(
        (ref, key) async {
  final repo = await ref.watch(scriptureRepoProvider.future);
  return repo.sectionsPage(
    key.bookId,
    limit: kReaderPageSize,
    offset: key.page * kReaderPageSize,
  );
});

/// A single book's metadata (title etc.).
final scriptureBookProvider =
    FutureProvider.family<ScriptureBook?, int>((ref, bookId) async {
  final repo = await ref.watch(scriptureRepoProvider.future);
  return repo.book(bookId);
});

/// Reader font-size preference (persist later; in-memory for now).
final readerFontScaleProvider = StateProvider<double>((ref) => 1.0);
