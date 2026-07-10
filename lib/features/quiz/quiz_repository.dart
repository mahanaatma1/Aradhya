import '../../core/db/content_database.dart';
import 'quiz_models.dart';

/// Read-only access to the quiz game tables.
class QuizRepository {
  final ContentDatabase db;
  const QuizRepository(this.db);

  Future<int> count(String table) async {
    final rows = await db.raw.rawQuery('SELECT COUNT(*) AS n FROM $table');
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<List<QuizQuestion>> randomQuestions(int n) async {
    final rows = await db.raw
        .rawQuery('SELECT * FROM knowledge_quiz ORDER BY RANDOM() LIMIT ?', [n]);
    return rows.map(QuizQuestion.fromRow).toList();
  }

  Future<List<TriviaFact>> randomTrivia(int n) async {
    final rows = await db.raw
        .rawQuery('SELECT * FROM trivia_facts ORDER BY RANDOM() LIMIT ?', [n]);
    return rows.map(TriviaFact.fromRow).toList();
  }
}
