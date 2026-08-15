import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'festival_models.dart';
import 'festival_resolver.dart';

/// Every stored festival, rules only — no dates yet.
final allFestivalsProvider = FutureProvider<List<Festival>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.festivals ORDER BY title_en');
  return rows.map(Festival.fromRow).toList();
});

/// The device's offset. Festival dates are local by nature: the tithi at
/// sunrise decides the day, and sunrise depends on where you are.
final festivalResolverProvider = Provider<FestivalResolver>(
    (ref) => FestivalResolver(DateTime.now().timeZoneOffset));

/// Upcoming festivals, resolved and sorted.
///
/// Resolution walks a day at a time through the panchang engine, so it is far
/// too heavy for a build method — it runs once here and the result is cached
/// by Riverpod for the life of the provider.
final upcomingFestivalsProvider =
    FutureProvider<List<ResolvedFestival>>((ref) async {
  final list = await ref.watch(allFestivalsProvider.future);
  final resolver = ref.watch(festivalResolverProvider);
  return resolver.resolveAll(list, DateTime.now());
});

final festivalByIdProvider =
    FutureProvider.family<Festival?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw
      .rawQuery('SELECT * FROM gyan.festivals WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : Festival.fromRow(rows.first);
});

/// The next few dates this festival falls on, for the detail screen.
final festivalDatesProvider =
    FutureProvider.family<List<DateTime>, int>((ref, id) async {
  final f = await ref.watch(festivalByIdProvider(id).future);
  if (f == null) return const [];
  final resolver = ref.watch(festivalResolverProvider);
  return resolver.occurrences(f, DateTime.now(), withinDays: 800);
});
