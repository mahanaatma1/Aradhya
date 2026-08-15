import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
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

/// Reader font size, shared by the scripture and story readers.
///
/// Persisted: this is an accessibility setting, and someone who enlarges the
/// text because they cannot comfortably read the default should not have to do
/// it again on every launch.
class ReaderFontScale extends StateNotifier<double> {
  ReaderFontScale(this._prefs)
      : super(_prefs.getDouble(PrefKeys.readerFontScale) ?? 1.0);

  final SharedPreferences _prefs;

  /// Bounded so the reader stays usable — an unbounded scale can push a verse
  /// off-screen with no way back to the menu.
  static const min = 0.85;
  static const max = 1.6;

  Future<void> set(double value) async {
    final v = value.clamp(min, max);
    if (v == state) return;
    state = v;
    await _prefs.setDouble(PrefKeys.readerFontScale, v);
  }
}

final readerFontScaleProvider =
    StateNotifierProvider<ReaderFontScale, double>(
        (ref) => ReaderFontScale(ref.read(sharedPrefsProvider)));
