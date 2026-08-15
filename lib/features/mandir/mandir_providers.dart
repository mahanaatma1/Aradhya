import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/user/streak.dart';
import '../../core/user/user_prefs.dart';
import '../sadhana/sadhana_providers.dart';
import 'mandir_models.dart';

/// Offerings made today, by key.
///
/// Read from `sadhana_sessions`, the same table japa and habits write to, so
/// the Mandir shows up on the Sadhana hub for free. The old `offering_*`
/// preference keys are no longer written — they were declared but never read,
/// and this replaces them properly.
final todaysOfferingsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(userDatabaseProvider);
  if (db == null) return const {};
  try {
    final rows = await db.raw.rawQuery(
      "SELECT meta, COUNT(*) AS n FROM sadhana_sessions "
      "WHERE practice = 'mandir' AND day_stamp = ? GROUP BY meta",
      [dayStamp()],
    );
    final out = <String, int>{};
    for (final r in rows) {
      final meta = (r['meta'] as String?) ?? '';
      // meta is `{"offering":"diya"}` — parsed loosely on purpose so a row
      // written by an older build never breaks the screen.
      final match = RegExp(r'"offering"\s*:\s*"([a-z]+)"').firstMatch(meta);
      final key = match?.group(1) ?? 'unknown';
      out[key] = (out[key] ?? 0) + ((r['n'] as num?)?.toInt() ?? 0);
    }
    return out;
  } catch (e) {
    debugPrint('todaysOfferingsProvider: $e');
    return const {};
  }
});

/// Consecutive days on which at least one offering was made.
final offeringStreakProvider = FutureProvider<int>((ref) async {
  final byDay = await ref.watch(sadhanaByDayProvider.future);
  return currentStreakOf(byDay['mandir'] ?? const {});
});

/// Total offerings ever made.
final offeringLifetimeProvider = FutureProvider<int>((ref) async {
  final byDay = await ref.watch(sadhanaByDayProvider.future);
  return (byDay['mandir'] ?? const <String, int>{})
      .values
      .fold<int>(0, (a, b) => a + b);
});

/// The result of attempting an offering, so the UI can say what happened.
enum OfferingResult { offered, notEnoughKamal, failed }

/// Makes an offering: charges Kamal when outside a free window, records the
/// session, and awards merit.
///
/// Merit is granted whether or not Kamal was charged. Punya tracks devotion;
/// Kamal only paces it.
Future<OfferingResult> makeOffering(WidgetRef ref, Offering offering) async {
  final db = ref.read(userDatabaseProvider);
  if (db == null) return OfferingResult.failed;

  final free = MandirWindows.isFree();
  if (!free) {
    final paid = await ref.read(streakProvider.notifier).spendKamal(offering.cost);
    if (!paid) return OfferingResult.notEnoughKamal;
  }

  try {
    await db.raw.insert('sadhana_sessions', {
      'day_stamp': dayStamp(),
      'practice': 'mandir',
      'count': 1,
      'duration_s': 0,
      'meta': '{"offering":"${offering.key}"}',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // A ledger row so "where did my Kamal go?" is answerable.
    if (!free) {
      await db.raw.insert('currency_ledger', {
        'day_stamp': dayStamp(),
        'reason': 'offering:${offering.key}',
        'punya': 1,
        'kamal': -offering.cost,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  } catch (e) {
    debugPrint('makeOffering: $e');
    return OfferingResult.failed;
  }

  await ref.read(streakProvider.notifier).earn(1);

  ref.invalidate(todaysOfferingsProvider);
  ref.invalidate(sadhanaByDayProvider);
  return OfferingResult.offered;
}
