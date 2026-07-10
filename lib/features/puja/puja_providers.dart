import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'puja_models.dart';

final pujaVidhiProvider = FutureProvider<List<PujaVidhi>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw.query('puja_vidhi', orderBy: 'id');
  return rows.map(PujaVidhi.fromRow).toList();
});
