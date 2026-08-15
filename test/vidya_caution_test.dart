import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/vidya/vidya_models.dart';

/// P5-17. The §4.15 rule is enforced in three places -- the schema (caution is
/// required), validate.py (fails the build without it), and a widget assert.
/// This pins the model half so a refactor cannot quietly make it optional.
void main() {
  VidyaTopic t(String caution) => VidyaTopic(
        id: 1, slug: 'x', discipline: 'ayurveda', titleEn: 'X',
        descEn: 'd', cautionEn: caution, modernStatus: 'not_evaluated',
      );

  test('a topic without a caution is not renderable', () {
    expect(t('').hasCaution, isFalse);
    expect(t('   ').hasCaution, isFalse);
    expect(t('Speak to a doctor.').hasCaution, isTrue);
  });

  test('every modern_status has a label and a plain explanation', () {
    for (final s in [
      'corroborated', 'partially_corroborated', 'not_evaluated', 'contested'
    ]) {
      expect(modernStatusLabels[s], isNotNull, reason: 'label for $s');
      expect(modernStatusExplain[s], isNotNull, reason: 'explanation for $s');
    }
  });

  test('the Hindi caution falls back to English, never to empty', () {
    final noHi = t('English only');
    expect(noHi.caution(true), 'English only');
  });
}
