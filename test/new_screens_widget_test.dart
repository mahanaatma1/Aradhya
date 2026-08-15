import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/ask/ask_models.dart';
import 'package:divyavaani/features/dharma/dharma_models.dart';
import 'package:divyavaani/features/festivals/festival_models.dart';
import 'package:divyavaani/features/vidya/vidya_models.dart';
import 'package:divyavaani/features/vidya/vidya_screen.dart';

/// P7-13 and P7-03. Two things are checked together here: that the new
/// surfaces build, and that they survive Hindi, which is longer and taller
/// than English and is where these layouts overflow if they are going to.
Widget host(Widget child, {double width = 360}) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  testWidgets('the modern-status chip renders in Hindi without overflow',
      (tester) async {
    for (final s in [
      'corroborated', 'partially_corroborated', 'not_evaluated', 'contested'
    ]) {
      await tester.pumpWidget(host(StatusChip(status: s, hindi: true)));
      expect(tester.takeException(), isNull, reason: 'chip $s in Hindi');
    }
  });

  testWidgets('status chips also survive the narrowest phone', (tester) async {
    await tester.pumpWidget(host(
        const StatusChip(status: 'partially_corroborated', hindi: true),
        width: 240));
    expect(tester.takeException(), isNull);
  });

  test('every festival category has a rule that can be stated', () {
    const f = Festival(
      id: 1, slug: 'x', titleEn: 'X', category: 'major',
      region: 'pan-india', descEn: 'd',
      lunarMonth: 'kartika', paksha: 'krishna', tithi: 15,
    );
    expect(f.isSolar, isFalse);
    expect(f.isPanIndia, isTrue);
    expect(f.regions, ['pan-india']);
  });

  test('a regional festival lists its regions', () {
    const f = Festival(
      id: 2, slug: 'y', titleEn: 'Y', category: 'regional',
      region: 'tamil-nadu,kerala', descEn: 'd', solarRule: 'Sun enters Mesha',
    );
    expect(f.isSolar, isTrue);
    expect(f.isPanIndia, isFalse);
    expect(f.regions, ['tamil-nadu', 'kerala']);
  });

  test('a guna is described, never scored', () {
    // If this ever grows a numeric field, the feature has changed meaning.
    for (final g in ['sattva', 'rajas', 'tamas']) {
      expect(gunaLabels[g], isNotNull);
      expect(gunaLabels[g]!.$1, contains('—'));
    }
  });

  test('an answer falls back to English rather than showing nothing', () {
    const p = QaPair(
      id: 1, questionEn: 'q', questionFold: 'q', answerEn: 'English answer',
      confidence: 'high',
    );
    expect(p.answer(true), 'English answer');
    expect(p.question(true), 'q');
  });
}
