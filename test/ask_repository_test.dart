import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/ask/ask_models.dart';
import 'package:divyavaani/features/ask/ask_repository.dart';

QaPair p(int id, String q, String fold, {String conf = 'high'}) => QaPair(
      id: id, questionEn: q, questionFold: fold, answerEn: 'a',
      confidence: conf);

void main() {
  const repo = AskRepository();

  final corpus = [
    p(1, 'What does the Gita say about the results of my work?',
        'what does the gita say about the results of my work कर्म फल'),
    p(2, 'What does the Gita say about fear?',
        'what does the gita say about fear गीता भय के विषय में'),
    p(3, 'How do I control the mind?',
        'how do i control the mind मन को कैसे वश में करूँ'),
  ];

  test('a close question is answered', () {
    final r = repo.ask('what happens to the results of my work', corpus);
    expect(r.outcome, AskOutcome.answered);
    expect(r.best!.id, 1);
  });

  test('Hindi finds the same row as English', () {
    final r = repo.ask('भय', corpus);
    expect(r.outcome, isNot(AskOutcome.empty));
    expect(r.candidates.isNotEmpty || r.best != null, isTrue);
    final hit = r.best ?? r.candidates.first;
    expect(hit.id, 2);
  });

  test('an unrelated question is answered with not-sure, never a guess', () {
    final r = repo.ask('how do I file my tax return', corpus);
    expect(r.outcome, AskOutcome.notSure);
    expect(r.best, isNull);
  });

  test('stop words alone do not produce an answer', () {
    final r = repo.ask('what does the gita say about', corpus);
    expect(r.outcome, isNot(AskOutcome.answered));
  });

  test('a low-confidence row is never presented as the answer', () {
    final weak = [
      p(9, 'How do I control the mind?',
          'how do i control the mind मन को कैसे वश में करूँ', conf: 'low')
    ];
    final r = repo.ask('how do i control the mind', weak);
    expect(r.outcome, AskOutcome.notSure);
    expect(r.candidates.single.id, 9);
  });

  test('empty input yields the empty state', () {
    expect(repo.ask('   ', corpus).outcome, AskOutcome.empty);
  });
}
