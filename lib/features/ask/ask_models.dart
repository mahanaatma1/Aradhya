/// A curated question and the passage that answers it.
///
/// The answer is always a real passage. Nothing is generated: there is no
/// model on the device, and `answer` is text a human wrote from a cited
/// translation.
class QaPair {
  final int id;
  final String questionEn;
  final String? questionHi;
  final String questionFold;
  final String answerEn;
  final String? answerHi;
  final String? explanationEn;
  final String? explanationHi;
  final String? passageSa;
  final String? passageTranslit;

  /// Soft link into main.scripture_sections. Null when the reference could not
  /// be resolved to exactly one verse — build.py refuses to guess.
  final int? scriptureSectionId;

  /// 'high' | 'medium' | 'low' | 'needs_review'
  final String confidence;
  final String? tagsRaw;

  final String? sourceName;
  final String? sourceRef;
  final String? sourceUrl;
  final String? lastVerifiedAt;

  const QaPair({
    required this.id,
    required this.questionEn,
    required this.questionFold,
    required this.answerEn,
    required this.confidence,
    this.questionHi,
    this.answerHi,
    this.explanationEn,
    this.explanationHi,
    this.passageSa,
    this.passageTranslit,
    this.scriptureSectionId,
    this.tagsRaw,
    this.sourceName,
    this.sourceRef,
    this.sourceUrl,
    this.lastVerifiedAt,
  });

  factory QaPair.fromRow(Map<String, Object?> r) => QaPair(
        id: r['id'] as int,
        questionEn: (r['question_en'] as String?) ?? '',
        questionHi: r['question_hi'] as String?,
        questionFold: (r['question_fold'] as String?) ?? '',
        answerEn: (r['answer_en'] as String?) ?? '',
        answerHi: r['answer_hi'] as String?,
        explanationEn: r['explanation_en'] as String?,
        explanationHi: r['explanation_hi'] as String?,
        passageSa: r['passage_sa'] as String?,
        passageTranslit: r['passage_translit'] as String?,
        scriptureSectionId: r['scripture_section_id'] as int?,
        confidence: (r['confidence'] as String?) ?? 'medium',
        tagsRaw: r['tags'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
        sourceUrl: r['primary_source_url'] as String?,
        lastVerifiedAt: r['last_verified_at'] as String?,
      );

  String question(bool hi) =>
      (hi && (questionHi?.isNotEmpty ?? false)) ? questionHi! : questionEn;
  String answer(bool hi) =>
      (hi && (answerHi?.isNotEmpty ?? false)) ? answerHi! : answerEn;
  String? explanation(bool hi) => (hi && (explanationHi?.isNotEmpty ?? false))
      ? explanationHi
      : explanationEn;

  /// The folded question as a token set, for scoring.
  Set<String> get tokens => questionFold.split(' ').where((t) => t.isNotEmpty).toSet();
}

/// What the Ask screen decided to show.
///
/// `notSure` is a first-class outcome, not an error. §4.19 requires that a
/// weak match says so plainly and offers candidates, rather than presenting
/// the best of a bad set as if it were the answer.
enum AskOutcome { answered, notSure, empty }

class AskResult {
  final AskOutcome outcome;

  /// The chosen pair when [outcome] is `answered`.
  final QaPair? best;

  /// Ranked alternatives. Shown as "closest questions" under a notSure, and as
  /// related chips under an answer.
  final List<QaPair> candidates;

  const AskResult(this.outcome, {this.best, this.candidates = const []});

  static const empty = AskResult(AskOutcome.empty);
}
