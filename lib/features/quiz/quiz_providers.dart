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

/// The category (an entity `kind` — 'deity', 'human', 'scripture', …) the
/// next session should be filtered to, or null for "all questions" (QZ-02).
/// Chosen on the hub before starting a session, so it's a settable provider
/// rather than derived.
final quizCategoryProvider = StateProvider<String?>((ref) => null);

/// Entity kinds available to filter quiz questions by, each with a count —
/// only kinds actually linked to a question, from `relate.py`'s
/// `link_quiz_riddle_trivia`.
final quizCategoriesProvider =
    FutureProvider<List<(String, int)>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  return repo.quizCategories();
});

/// A fresh 10-question session, filtered to `quizCategoryProvider` when set.
/// Invalidate to reshuffle.
final quizSessionProvider = FutureProvider<List<QuizQuestion>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  final category = ref.watch(quizCategoryProvider);
  return repo.randomQuestions(10, category: category);
});

/// Random trivia set for the browse screen.
final triviaProvider = FutureProvider<List<TriviaFact>>((ref) async {
  final repo = await ref.watch(quizRepoProvider.future);
  return repo.randomTrivia(40);
});
