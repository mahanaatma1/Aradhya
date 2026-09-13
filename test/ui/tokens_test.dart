import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/ui/theme/app_theme.dart';
import 'package:divyavaani/ui/tokens/tokens.dart';

void main() {
  group('ColorTokens', () {
    for (final (name, t) in [('light', ColorTokens.light), ('dark', ColorTokens.dark)]) {
      test('$name: body ink on every ground meets 4.5:1', () {
        for (final ground in [t.canvas, t.surface, t.surfaceRaised, t.surfaceSunken]) {
          expect(ColorTokens.contrast(t.ink, ground), greaterThanOrEqualTo(4.5),
              reason: '$name ink on $ground');
          expect(ColorTokens.contrast(t.inkSoft, ground), greaterThanOrEqualTo(4.5),
              reason: '$name inkSoft on $ground');
        }
        expect(ColorTokens.contrast(t.inkOnAccent, t.accent), greaterThanOrEqualTo(3.0));
        expect(ColorTokens.contrast(t.inkOnDeep, t.canvasDeep), greaterThanOrEqualTo(4.5));
      });
    }

    test('lerp at 0.5 moves every colour role', () {
      final mid = ColorTokens.light.lerp(ColorTokens.dark, 0.5);
      final a = ColorTokens.light.allColors, b = ColorTokens.dark.allColors, m = mid.allColors;
      expect(m.length, a.length);
      for (var i = 0; i < a.length; i++) {
        if (a[i] == b[i]) continue;
        expect(m[i], isNot(a[i]), reason: 'field $i did not lerp from light');
        expect(m[i], isNot(b[i]), reason: 'field $i did not lerp from dark');
      }
    });

    test('lerp endpoints round-trip', () {
      expect(ColorTokens.light.lerp(ColorTokens.dark, 0).allColors, ColorTokens.light.allColors);
      expect(ColorTokens.light.lerp(ColorTokens.dark, 1).allColors, ColorTokens.dark.allColors);
    });
  });

  group('CategoryColors', () {
    test('every tile gradient keeps white text readable at its dark end', () {
      for (final s in CategoryColors.standard.all) {
        expect(ColorTokens.contrast(Colors.white, s.end), greaterThanOrEqualTo(3.0),
            reason: 'white on ${s.end}');
      }
    });
    test('lerp is field-wise, not identity', () {
      final swapped = CategoryColors(
        scriptures: CategoryColors.standard.quiz,
        aartis: CategoryColors.standard.aartis,
        mantras: CategoryColors.standard.mantras,
        quiz: CategoryColors.standard.scriptures,
        astrology: CategoryColors.standard.astrology,
        panchang: CategoryColors.standard.panchang,
        katha: CategoryColors.standard.katha,
        personality: CategoryColors.standard.personality,
        temples: CategoryColors.standard.temples,
        gyan: CategoryColors.standard.gyan,
        srishty: CategoryColors.standard.srishty,
        epics: CategoryColors.standard.epics,
        sadhana: CategoryColors.standard.sadhana,
      );
      final mid = CategoryColors.standard.lerp(swapped, 0.5);
      expect(mid.scriptures.start, isNot(CategoryColors.standard.scriptures.start));
      expect(mid.aartis.start, CategoryColors.standard.aartis.start);
    });
  });

  group('AppTheme', () {
    test('installs every token extension on both themes', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.extension<ColorTokens>(), isNotNull);
        expect(theme.extension<ElevationTokens>(), isNotNull);
        expect(theme.extension<TextRoles>(), isNotNull);
        expect(theme.extension<CategoryColors>(), isNotNull);
      }
      expect(AppTheme.light().extension<ColorTokens>()!.isDark, isFalse);
      expect(AppTheme.dark().extension<ColorTokens>()!.isDark, isTrue);
    });

    test('theme builders are cached', () {
      expect(identical(AppTheme.light(), AppTheme.light()), isTrue);
    });

    testWidgets('context.colors resolves through Theme', (tester) async {
      late ColorTokens seen;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(builder: (context) {
          seen = context.colors;
          return const SizedBox();
        }),
      ));
      expect(seen.canvas, ColorTokens.dark.canvas);
    });
  });
}
