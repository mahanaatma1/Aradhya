import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import 'search_models.dart';
import 'search_repository.dart';

final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  return SearchRepository(db.raw);
});

/// True when `gyan.sqlite`'s index was built against a different
/// `content.sqlite` than the one bundled.
///
/// Search results would then deep-link to shifted or missing rows. The UI shows
/// a quiet warning rather than hiding search or crashing — degrade, never fail.
final searchIndexStaleProvider = FutureProvider<bool>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  return db.isSearchIndexStale();
});

/// The live query text.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected kind filter, or null for everything.
final searchKindProvider = StateProvider<String?>((ref) => null);

/// Debounced results.
///
/// 180 ms is deliberate: fast enough to feel live, slow enough that typing
/// "hanuman" runs one query instead of seven.
final searchResultsProvider = FutureProvider<List<SearchHit>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final kind = ref.watch(searchKindProvider);
  if (query.trim().length < 2) return const [];

  await _debounce(ref, const Duration(milliseconds: 180));

  final repo = await ref.watch(searchRepositoryProvider.future);
  return repo.search(query, kind: kind);
});

/// Per-kind counts for the filter chips. Not filtered by the selected kind —
/// the chips must keep showing what else is available.
final searchCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return const {};

  await _debounce(ref, const Duration(milliseconds: 180));

  final repo = await ref.watch(searchRepositoryProvider.future);
  return repo.countsByKind(query);
});

/// Cancels the pending wait when the provider is re-run (i.e. the user typed
/// another character), so only the final keystroke reaches the database.
Future<void> _debounce(Ref ref, Duration d) {
  final completer = Completer<void>();
  final timer = Timer(d, () {
    if (!completer.isCompleted) completer.complete();
  });
  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) completer.complete();
  });
  return completer.future;
}

/// Spelling corrections for a query that found nothing (SR-03).
///
/// Deliberately chained off [searchResultsProvider] rather than off the query
/// text: a search that worked returns here immediately without touching the
/// database, so the correction costs a query only on the misses — and it
/// inherits that provider's debounce instead of adding a second one.
final didYouMeanProvider = FutureProvider<List<String>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return const [];

  final hits = await ref.watch(searchResultsProvider.future);
  if (hits.isNotEmpty) return const [];

  final repo = await ref.watch(searchRepositoryProvider.future);
  return repo.spellingSuggestions(query);
});

/// The last few queries, kept locally so the empty state is useful.
class RecentSearches extends StateNotifier<List<String>> {
  RecentSearches(this._prefs) : super(_prefs.getStringList(_key) ?? const []);

  final SharedPreferences _prefs;
  static const _key = 'search_recent';
  static const _max = 8;

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final next = [q, ...state.where((s) => s.toLowerCase() != q.toLowerCase())]
        .take(_max)
        .toList();
    state = next;
    await _prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    state = const [];
    await _prefs.remove(_key);
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearches, List<String>>(
        (ref) => RecentSearches(ref.read(sharedPrefsProvider)));

/// The empty-state "Try" row (SR-02).
///
/// Drawn from `gyan.entities.importance = 1` — the corpus's own answer to what
/// matters — round-robined across kinds so the row shows the reach of the index
/// rather than a wall of deities. [searchSuggestions] is the fallback if the
/// query fails or the DB is absent, so the empty state is never itself empty.
final curatedTermsProvider = FutureProvider<List<CuratedTerm>>((ref) async {
  final repo = await ref.watch(searchRepositoryProvider.future);
  final curated = await repo.curatedTerms();
  if (curated.isNotEmpty) return curated;
  return [for (final s in searchSuggestions) (en: s, hi: null)];
});

/// The hardcoded fallback for [curatedTermsProvider]. Kept because a curated
/// row driven entirely by the database would show nothing at all if the query
/// ever failed — and an empty "Try" row is worse than a slightly stale one.
///
/// Chosen to demonstrate what the index can do — a Devanagari term, a diacritic
/// term, and a substring city match — rather than just being popular words.
const searchSuggestions = <String>[
  'Hanuman',
  'कृष्ण',
  'Ekadashi',
  'Kedarnath',
  'Gita',
  'Shiva',
];
