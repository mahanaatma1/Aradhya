import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/app/theme/app_type.dart';

/// TY-01 / TY-02. Proves the one type scale is real and installed, and that
/// Devanagari gets the extra leading it needs.
void main() {
  group('the type scale (TY-02)', () {
    test('every scale step has a size and a Latin line-height', () {
      for (final role in const [
        'micro',
        'caption',
        'body',
        'bodyLarge',
        'subtitle',
        'title',
        'headline',
        'display',
      ]) {
        final latin = AppType.style(role);
        final deva = AppType.style(role, devanagari: true);
        expect(latin.fontSize, isNotNull, reason: '$role has no size');
        expect(latin.height, isNotNull, reason: '$role has no line-height');
        expect(deva.height! > latin.height!, isTrue,
            reason: '$role: Devanagari leading must exceed Latin');
      }
    });

    test('sizes increase monotonically up the scale', () {
      final roles = const [
        'micro',
        'caption',
        'body',
        'bodyLarge',
        'subtitle',
        'title',
        'headline',
        'display',
      ];
      for (var i = 1; i < roles.length; i++) {
        expect(AppType.size(roles[i]) > AppType.size(roles[i - 1]), isTrue,
            reason: '${roles[i]} should be larger than ${roles[i - 1]}');
      }
    });

    test('AppTheme installs the scale onto the TextTheme', () {
      final tt = AppTheme.light().textTheme;
      expect(tt.bodyMedium!.fontSize, AppType.size('body'));
      expect(tt.titleLarge!.fontSize, AppType.size('title'));
      expect(tt.headlineMedium!.fontSize, AppType.size('headline'));
      // line-heights carried through, not left null
      expect(tt.bodyMedium!.height, isNotNull);
    });
  });

  group('Devanagari leading (TY-01)', () {
    test('forScript boosts height and switches family only for Devanagari', () {
      const base = TextStyle(fontSize: 15, height: 1.4);
      final latin = AppType.forScript(base, devanagari: false);
      final deva = AppType.forScript(base, devanagari: true);
      expect(latin, same(base));
      expect(deva.fontFamily, AppFonts.devanagari);
      expect(deva.height, closeTo(1.4 * AppType.devanagariLeadingBoost, 1e-9));
    });

    testWidgets('ScriptText picks Devanagari from content', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            ScriptText('Krishna', style: TextStyle(fontSize: 15, height: 1.4)),
            ScriptText('कृष्ण', style: TextStyle(fontSize: 15, height: 1.4)),
          ]),
        ),
      ));
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      final latin = texts.firstWhere((t) => t.data == 'Krishna');
      final deva = texts.firstWhere((t) => t.data == 'कृष्ण');
      expect(latin.style!.fontFamily, isNot(AppFonts.devanagari));
      expect(deva.style!.fontFamily, AppFonts.devanagari);
      expect(deva.style!.height! > latin.style!.height!, isTrue);
    });

    test('isDevanagari detects the block, not just non-ASCII', () {
      expect(ScriptText.isDevanagari('Rāma'), isFalse); // diacritics, not Deva
      expect(ScriptText.isDevanagari('राम'), isTrue);
      expect(ScriptText.isDevanagari('Rama (राम)'), isTrue); // mixed
    });
  });
}
