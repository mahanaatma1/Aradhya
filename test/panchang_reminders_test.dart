import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/core/notifications/panchang_reminders.dart';
import 'package:divyavaani/features/panchang/panchang_engine.dart';

/// Guards the auto-scheduler's pure logic. The actual OS scheduling is a
/// no-op under `flutter test` — `PanchangReminders._supported` is false on
/// desktop/web — so this covers the pref state and what *would* be queued.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Force the "unsupported platform" branch so setEnabled/rescheduleWindow
    // exercise only the pref path and never touch the (uninitialised) plugin.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('feature is off by default', () async {
    expect(await PanchangReminders.instance.isEnabled(), isFalse);
  });

  test('setEnabled persists the flag both ways', () async {
    await PanchangReminders.instance.setEnabled(true, hindi: false);
    expect(await PanchangReminders.instance.isEnabled(), isTrue);
    await PanchangReminders.instance.setEnabled(false, hindi: false);
    expect(await PanchangReminders.instance.isEnabled(), isFalse);
  });

  test('rescheduleWindow is a no-op while disabled', () async {
    await PanchangReminders.instance.rescheduleWindow(hindi: false);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('panchang_reminders_armed_ids'), isNull);
  });

  test('a 180-day window spans at least a dozen Ekadashis and five Purnimas',
      () {
    // ~2 Ekadashis + 1 Purnima + 1 Amavasya per lunar month. Over 180 days
    // that is roughly 12 / 6 / 6. If the tithi indices (10/25 Ekadashi,
    // 14 Purnima, 29 Amavasya) ever drift, the scheduler would queue the
    // wrong days and this catches it.
    final tz = DateTime.now().timeZoneOffset;
    final today = DateTime.now();
    var ekadashi = 0, purnima = 0, amavasya = 0;
    for (var i = 0; i <= 180; i++) {
      final d = DateTime(today.year, today.month, today.day)
          .add(Duration(days: i));
      switch (dayTithiIndex(d, tz)) {
        case 10:
        case 25:
          ekadashi++;
        case 14:
          purnima++;
        case 29:
          amavasya++;
      }
    }
    expect(ekadashi, greaterThanOrEqualTo(12));
    expect(purnima, greaterThanOrEqualTo(5));
    expect(amavasya, greaterThanOrEqualTo(5));
  });
}
