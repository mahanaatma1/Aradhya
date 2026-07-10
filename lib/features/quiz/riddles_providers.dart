import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';

/// A single clue riddle: an answer plus a list of progressively-revealing clues.
class Riddle {
  final int id;
  final String answer;
  final List<String> cluesEn;
  final List<String> cluesHi;

  const Riddle({
    required this.id,
    required this.answer,
    required this.cluesEn,
    required this.cluesHi,
  });

  factory Riddle.fromRow(Map<String, Object?> r) {
    List<String> parse(Object? v) {
      if (v == null) return const [];
      try {
        return (jsonDecode(v as String) as List)
            .map((e) => e.toString())
            .toList();
      } catch (_) {
        return const [];
      }
    }

    return Riddle(
      id: r['id'] as int,
      answer: (r['answer'] ?? '') as String,
      cluesEn: parse(r['clues_en']),
      cluesHi: parse(r['clues_hi']),
    );
  }

  List<String> clues(bool hi) =>
      (hi && cluesHi.isNotEmpty) ? cluesHi : cluesEn;
}

/// A fresh shuffled set of riddles. Invalidate to reshuffle.
final riddlesProvider = FutureProvider<List<Riddle>>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw
      .rawQuery('SELECT * FROM clue_riddles ORDER BY RANDOM() LIMIT 20');
  return rows.map(Riddle.fromRow).toList();
});
