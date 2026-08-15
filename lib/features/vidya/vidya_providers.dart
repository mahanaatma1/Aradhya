import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'vidya_models.dart';

final vidyaTopicsProvider = FutureProvider<List<VidyaTopic>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return const [];
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.vidya_topics ORDER BY discipline, title_en');
  return rows.map(VidyaTopic.fromRow).toList();
});

final vidyaTopicProvider =
    FutureProvider.family<VidyaTopic?, int>((ref, id) async {
  final db = await ref.watch(contentDbProvider.future);
  if (!db.gyanAttached) return null;
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.vidya_topics WHERE id = ? LIMIT 1', [id]);
  return rows.isEmpty ? null : VidyaTopic.fromRow(rows.first);
});
