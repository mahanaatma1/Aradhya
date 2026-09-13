import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/core/providers/app_providers.dart';
import 'package:divyavaani/core/user/user_prefs.dart';
import 'package:divyavaani/l10n/app_localizations.dart';
import 'package:divyavaani/ui/debug/kit_gallery_screen.dart';
import 'package:divyavaani/ui/motion/motion.dart';
import 'package:divyavaani/ui/theme/app_theme.dart';

/// The whole kit must lay out at a 320 px phone, in Hindi, at 1.3× text.
void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpGallery(WidgetTester tester,
      {required bool hindi, required bool dark, double scale = 1.3, double width = 320}) async {
    tester.view.physicalSize = Size(width * 3, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        localeProvider.overrideWith((_) => Locale(hindi ? 'hi' : 'en')),
        themeModeProvider.overrideWith((_) => ThemeModeController(prefs)..set(dark ? ThemeMode.dark : ThemeMode.light)),
      ],
      child: Consumer(builder: (context, ref, _) {
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: ref.watch(localeProvider),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: L10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: MotionScope(settings: MotionSettings.full, child: child!),
          ),
          home: const KitGalleryScreen(),
        );
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  for (final (hindi, dark) in [(false, false), (true, false), (true, true)]) {
    testWidgets('kit lays out without overflow — hindi=$hindi dark=$dark', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d);
      await pumpGallery(tester, hindi: hindi, dark: dark);
      // scroll through the whole gallery so every section lays out
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 12; i++) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 300));
      }
      FlutterError.onError = prev;
      final overflow = errors.where((e) => e.toString().contains('overflowed')).toList();
      expect(overflow, isEmpty, reason: overflow.map((e) => e.exception).join('\n'));
    });
  }

  testWidgets('sheet opens and closes', (tester) async {
    await pumpGallery(tester, hindi: false, dark: false, scale: 1.0, width: 390);
    final scrollable = find.byType(Scrollable).first;
    await tester.dragUntilVisible(find.text('Open sheet'), scrollable, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Open sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Choose a voice'), findsOneWidget);
    await tester.tap(find.text('Hindi (offline)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose a voice'), findsNothing);
  });
}
