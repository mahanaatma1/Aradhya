import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's single [SharedPreferences] instance. Loaded once in `main()`
/// (before `runApp`) and injected via an override so the rest of the app can
/// read/write user state synchronously.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// A local date stamp `YYYY-MM-DD` — used to key day-scoped state (streak,
/// habit completions) without pulling in a date library.
String dayStamp([DateTime? at]) {
  final d = at ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Whole-day difference between two `YYYY-MM-DD` stamps (b - a), or null if
/// either is empty/invalid.
int? dayGap(String a, String b) {
  final da = _parse(a), db = _parse(b);
  if (da == null || db == null) return null;
  return db.difference(da).inDays;
}

DateTime? _parse(String stamp) {
  final p = stamp.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Shared preference keys, kept in one place.
class PrefKeys {
  PrefKeys._();
  static const streakCount = 'streak_count';
  static const streakLast = 'streak_last';
  static const points = 'points'; // Punya — lifetime merit (never spent)
  static const kamal = 'kamal_balance'; // Kamal — spendable currency
  static const japaLifetime = 'japa_lifetime';
  static const japaMalas = 'japa_malas';
  static const japaHistory = 'japa_history_json'; // {dayStamp: count}
  static const habitsPrefix = 'habits_'; // + dayStamp
  static const offeringTotalDays = 'offering_total_days';
  static const offeringStreak = 'offering_streak';
  static const offeringLast = 'offering_last';
  static const bookmarks = 'bookmarks_json';
  static const templesVisited = 'temples_visited';
  static const onboarded = 'onboarded';
  static const userName = 'user_name';
  static const ishtaDeity = 'ishta_deity'; // canonical English deity name
  static const personalityResult = 'personality_result'; // archetype key
  static const rashi = 'rashifal_rashi'; // selected moon sign 0..11
  static const birthDetails = 'birth_details_json'; // saved kundli birth input
  static const breathLast = 'breathing_last'; // dayStamp of last session
  static const breathStreak = 'breathing_streak'; // consecutive-day count
  static const scripturePosPrefix = 'scripture_pos_'; // + bookId → verse index
  static const scriptureLast = 'scripture_last'; // JSON {scriptureId,bookId,index}
}
