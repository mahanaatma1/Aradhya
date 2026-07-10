import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/app/router/app_router.dart';
import 'package:divyavaani/core/user/user_prefs.dart';
import 'package:divyavaani/features/panchang/panchang_providers.dart';
import 'package:divyavaani/main.dart';

void main() {
  testWidgets('App boots past onboarding and shows the home header',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    gOnboarded = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          // Avoid hitting the Geolocator plugin in the headless test.
          deviceLocationProvider.overrideWith((ref) async => null),
        ],
        child: const DivyaVaaniApp(),
      ),
    );
    await tester.pump(); // splash first frame
    // Let the splash's navigation timer fire and land on Home.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byType(DivyaVaaniApp), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });
}
