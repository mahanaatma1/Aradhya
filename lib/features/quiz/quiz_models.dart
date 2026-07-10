import 'dart:convert';

class QuizOption {
  final String key; // "A".."D"
  final String en;
  final String? hi;
  const QuizOption({required this.key, required this.en, this.hi});

  String text(bool hindi) => (hindi && (hi?.isNotEmpty ?? false)) ? hi! : en;
}

class QuizQuestion {
  final int id;
  final String questionEn;
  final String? questionHi;
  final List<QuizOption> options;
  final String correctKey;

  const QuizQuestion({
    required this.id,
    required this.questionEn,
    this.questionHi,
    required this.options,
    required this.correctKey,
  });

  factory QuizQuestion.fromRow(Map<String, Object?> r) {
    final raw = jsonDecode(r['options'] as String) as List<dynamic>;
    final opts = raw
        .map((o) => QuizOption(
              key: (o['key'] ?? '').toString(),
              en: (o['en'] ?? '').toString(),
              hi: o['hi']?.toString(),
            ))
        .toList();
    return QuizQuestion(
      id: r['id'] as int,
      questionEn: r['question_en'] as String,
      questionHi: r['question_hi'] as String?,
      options: opts,
      correctKey: r['correct_key'] as String,
    );
  }

  String question(bool hindi) =>
      (hindi && (questionHi?.isNotEmpty ?? false)) ? questionHi! : questionEn;
}

class TriviaFact {
  final int id;
  final String en;
  final String? hi;
  const TriviaFact({required this.id, required this.en, this.hi});

  factory TriviaFact.fromRow(Map<String, Object?> r) => TriviaFact(
        id: r['id'] as int,
        en: r['fact_en'] as String,
        hi: r['fact_hi'] as String?,
      );

  String text(bool hindi) => (hindi && (hi?.isNotEmpty ?? false)) ? hi! : en;
}
