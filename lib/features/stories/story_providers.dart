import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'story_models.dart';

final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('stories', orderBy: 'id');
  return rows.map(Story.fromRow).toList();
});
