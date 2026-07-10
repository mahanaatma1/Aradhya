import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// The user's name, captured during onboarding (empty if skipped).
final userNameProvider = StateProvider<String>(
  (ref) => ref.read(sharedPrefsProvider).getString(PrefKeys.userName) ?? '',
);

/// The user's chosen Ishta Devata (canonical English name), set in onboarding.
final ishtaDeityProvider = StateProvider<String>(
  (ref) => ref.read(sharedPrefsProvider).getString(PrefKeys.ishtaDeity) ?? '',
);

/// All verses from the `daily_quotes` table, in id order. Loaded once and
/// cached; the day's verse and the "another verse" shuffle both index into it.
final allDailyQuotesProvider = FutureProvider<List<DailyQuote>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.query('daily_quotes', orderBy: 'id');
  return rows.map(DailyQuote.fromRow).toList();
});

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
