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

  Future<List<QuizQuestion>> randomQuestions(int n, {String? category}) async {
    if (category == null || !db.gyanAttached) {
      final rows = await db.raw.rawQuery(
          'SELECT * FROM knowledge_quiz ORDER BY RANDOM() LIMIT ?', [n]);
      return rows.map(QuizQuestion.fromRow).toList();
    }
    // Only ~38% of questions carry a category (QZ-02) -- it comes from the
    // build-time relate.py link between a question's correct answer and a
    // gyan entity, not a column on knowledge_quiz itself, so this filters by
    // joining through related_edges/entities rather than a WHERE on the
    // legacy table.
    final rows = await db.raw.rawQuery('''
      SELECT DISTINCT q.* FROM knowledge_quiz q
      JOIN gyan.related_edges re
        ON re.src_table = 'knowledge_quiz' AND re.src_id = q.id
        AND re.dst_src = 'gyan'
      JOIN gyan.entities e ON e.id = re.dst_id
      WHERE e.kind = ?
      ORDER BY RANDOM() LIMIT ?
    ''', [category, n]);
    return rows.map(QuizQuestion.fromRow).toList();
  }

  /// Distinct entity kinds available to filter by, with a count each —
  /// drives the category chooser. Only kinds actually linked to a question
  /// appear, so the UI never offers an empty filter.
  Future<List<(String kind, int count)>> quizCategories() async {
    if (!db.gyanAttached) return const [];
    final rows = await db.raw.rawQuery('''
      SELECT e.kind AS kind, COUNT(DISTINCT re.src_id) AS n
      FROM gyan.related_edges re
      JOIN gyan.entities e ON e.id = re.dst_id
      WHERE re.src_table = 'knowledge_quiz' AND re.dst_src = 'gyan'
      GROUP BY e.kind ORDER BY n DESC
    ''');
    return rows
        .map((r) => (r['kind'] as String, (r['n'] as int?) ?? 0))
        .toList();
  }

  Future<List<TriviaFact>> randomTrivia(int n) async {
    final rows = await db.raw
        .rawQuery('SELECT * FROM trivia_facts ORDER BY RANDOM() LIMIT ?', [n]);
    return rows.map(TriviaFact.fromRow).toList();
  }
}
