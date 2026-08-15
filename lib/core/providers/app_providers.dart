import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/content_database.dart';
import '../models/daily_quote.dart';
import '../user/user_prefs.dart';

/// Opens (and caches) the read-only content database for the app's lifetime.
final contentDbProvider = FutureProvider<ContentDatabase>((ref) async {
  final db = await ContentDatabase.open();
  ref.onDispose(() => db.raw.close());
  return db;
});

/// The current UI locale — drives the EN/HI toggle. Defaults to English.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Convenience: is the current locale Hindi?
final isHindiProvider = Provider<bool>(
  (ref) => ref.watch(localeProvider).languageCode == 'hi',
);

/// The user's chosen theme mode (system by default).
/// Light, dark, or follow the system.
///
/// Defaults to light rather than system. The warm cream palette is the app's
/// identity, and a first launch that lands in dark because the phone happens
/// to be in dark mode shows a version of the app most users have not chosen.
/// Following the system is available, it is just not assumed.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _read(SharedPreferences p) => switch (p.getString(_key)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
        (ref) => ThemeModeController(ref.watch(sharedPrefsProvider)));

/// The user's name, captured during onboarding (empty if skipped).
final userNameProvider = StateProvider<String>(
  (ref) => ref.read(sharedPrefsProvider).getString(PrefKeys.userName) ?? '',
);

/// The user's chosen Ishta Devata (canonical English name), set in onboarding.
final ishtaDeityProvider = StateProvider<String>(
  (ref) => ref.read(sharedPrefsProvider).getString(PrefKeys.ishtaDeity) ?? '',
);

/// Every verse available for the verse-of-the-day, loaded once and cached.
///
/// Two tables, deliberately combined:
///
///   * `daily_quotes` (3 rows) is the only one carrying `sanskrit` and
///     `transliteration`, which the Home card renders in Devanagari.
///   * `quotes` (1,000 rows) has the same EN/HI/source shape but no Sanskrit,
///     and was previously never queried at all.
///
/// Reading only `daily_quotes` meant the verse of the day repeated on a
/// **three-day cycle**. Swapping wholesale to `quotes` would have fixed the
/// repetition but silently dropped the Sanskrit. Using both keeps the richer
/// rows first and gives the rotation 1,003 verses to draw on.
final allDailyQuotesProvider = FutureProvider<List<DailyQuote>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);

  final rich = await db.query('daily_quotes', orderBy: 'id');
  final plain = await db.query('quotes', orderBy: 'id');

  return [
    ...rich.map(DailyQuote.fromRow),
    // Offset the ids so the two tables cannot collide — bookmarks and the
    // share card identify a verse by id.
    ...plain.map((r) => DailyQuote.fromRow({
          ...r,
          'id': (r['id'] as int) + _quotesIdOffset,
        })),
  ];
});

/// Keeps `quotes` ids disjoint from `daily_quotes` ids in the merged list.
const _quotesIdOffset = 1000000;

/// The index of the today's verse within [allDailyQuotesProvider], derived
/// from the day-of-year so it is stable across a day and needs no network.
int verseIndexForToday(int count) {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return dayOfYear % count;
}

/// When non-null, overrides the day's verse with this index — set by the
/// "another verse" (change) button on the Home card. Reset on app restart.
final verseIndexOverrideProvider = StateProvider<int?>((ref) => null);

/// Verse of the day — the day-of-year pick, unless the user has tapped
/// "change" to shuffle to another verse.
final verseOfTheDayProvider = FutureProvider<DailyQuote?>((ref) async {
  final quotes = await ref.watch(allDailyQuotesProvider.future);
  if (quotes.isEmpty) return null;
  final override = ref.watch(verseIndexOverrideProvider);
  final index = override ?? verseIndexForToday(quotes.length);
  return quotes[index % quotes.length];
});
