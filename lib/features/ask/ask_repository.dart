import '../search/search_fold.dart';
import 'ask_models.dart';

/// Retrieval over the curated question set.
///
/// Deliberately not a model and not a generator. Scoring is token overlap
/// against `question_fold`, which build.py populates with tokenize() — the
/// same function used here — so a question folds identically on both sides.
///
/// The important property is not the ranking. It is that a weak best match
/// returns [AskOutcome.notSure] instead of dressing up the least-bad row as
/// an answer. An app that always answers is worse than one that admits it
/// does not know, because the reader cannot tell the two cases apart.
class AskRepository {
  /// Below this, we do not claim to have found the question.
  static const answerThreshold = 0.34;

  /// Below this a candidate is not worth showing at all.
  static const candidateFloor = 0.12;

  const AskRepository();

  /// Jaccard-style overlap, weighted toward covering the QUESTION asked.
  ///
  /// Plain Jaccard punishes a long stored question for being thorough. What
  /// matters is how much of what the user typed is accounted for, so recall
  /// over the query carries most of the weight.
  static double score(Set<String> query, Set<String> stored) {
    if (query.isEmpty || stored.isEmpty) return 0;
    final shared = query.intersection(stored).length;
    if (shared == 0) return 0;
    final coverage = shared / query.length;
    final precision = shared / stored.length;
    return coverage * 0.75 + precision * 0.25;
  }

  /// Words that carry no signal and would otherwise inflate every score.
  static const _stop = {
    'what', 'does', 'the', 'say', 'about', 'is', 'are', 'do', 'i', 'my',
    'me', 'to', 'of', 'a', 'an', 'in', 'on', 'for', 'and', 'it', 'that',
    'this', 'how', 'can', 'should', 'will', 'be', 'am', 'gita', 'says',
    'क', 'के', 'की', 'का', 'है', 'हैं', 'में', 'से', 'को', 'और', 'क्या',
    'कि', 'यह', 'वह', 'पर',
  };

  static Set<String> queryTokens(String text) =>
      tokenize(text).where((t) => !_stop.contains(t)).toSet();

  /// Rank [all] against a free-text question.
  AskResult ask(String question, List<QaPair> all) {
    final q = queryTokens(question);
    if (q.isEmpty || all.isEmpty) return AskResult.empty;

    final scored = <(QaPair, double)>[];
    for (final p in all) {
      final s = score(q, p.tokens.where((t) => !_stop.contains(t)).toSet());
      if (s >= candidateFloor) scored.add((p, s));
    }
    if (scored.isEmpty) {
      return const AskResult(AskOutcome.notSure);
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final best = scored.first;
    // A pair the curator marked low or needs_review does not get to be
    // presented as the answer however well it matches.
    final trusted = best.$1.confidence == 'high' || best.$1.confidence == 'medium';

    if (best.$2 < answerThreshold || !trusted) {
      return AskResult(
        AskOutcome.notSure,
        candidates: scored.take(4).map((e) => e.$1).toList(),
      );
    }
    return AskResult(
      AskOutcome.answered,
      best: best.$1,
      candidates: scored.skip(1).take(3).map((e) => e.$1).toList(),
    );
  }
}
