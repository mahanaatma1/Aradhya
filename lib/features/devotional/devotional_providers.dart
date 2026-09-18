import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'devotional_models.dart';

/// Which lyrics table a list screen reads from.
enum LyricsKind { aartis, chalisas }

extension LyricsKindX on LyricsKind {
  String get table => this == LyricsKind.aartis ? 'aartis' : 'chalisas';
}

final aartisProvider = FutureProvider<List<DevotionalItem>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery(
      "SELECT * FROM gyan.devotional_lyrics WHERE kind = 'aarti' "
      'ORDER BY order_no, id');
  return rows.map(DevotionalItem.fromRow).toList();
});

final chalisasProvider = FutureProvider<List<DevotionalItem>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery(
      "SELECT * FROM gyan.devotional_lyrics WHERE kind = 'chalisa' "
      'ORDER BY order_no, id');
  return rows.map(DevotionalItem.fromRow).toList();
});

final mantrasProvider = FutureProvider<List<Mantra>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.rawQuery(
      'SELECT * FROM gyan.mantras ORDER BY order_no, id');
  return rows.map(Mantra.fromRow).toList();
});
