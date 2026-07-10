import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'quiz_models.dart';
import 'quiz_repository.dart';

final quizRepoProvider = FutureProvider<QuizRepository>((ref) async {
  final db = await ref.watch(contentDbProvider.future);
  return QuizRepository(db);
});

/// Counts for the hub screen (quiz / riddles / trivia).
final quizCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  return {
    'quiz': await repo.count('knowledge_quiz'),
    'riddles': await repo.count('clue_riddles'),
    'trivia': await repo.count('trivia_facts'),
  };
});

/// A fresh 10-question session. Invalidate to reshuffle.
final quizSessionProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  return repo.randomQuestions(10);
});

/// Random trivia set for the browse screen.
final triviaProvider = FutureProvider<List<TriviaFact>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  return repo.randomTrivia(40);
});
