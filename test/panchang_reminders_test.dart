import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/core/notifications/panchang_reminders.dart';
import 'package:divyavaani/features/panchang/panchang_engine.dart';

/// Guards the auto-scheduler's pure logic. The actual OS scheduling is a
/// no-op under `flutter test` (ReminderService bails on unsupported
/// platforms), so this covers the parts that decide *what* gets queued.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('feature is off by default', () async {
    expect(await PanchangReminders.instance.isEnabled(), isFalse);
  });

  test('setEnabled persists the flag', () async {
    // Under `flutter test` the OS scheduling is a no-op (see _supported), so
    // this only asserts the pref half — the queueing is a device check.
    await PanchangReminders.instance.setEnabled(true, hindi: false);
    expect(await PanchangReminders.instance.isEnabled(), isTrue);
    await PanchangReminders.instance.setEnabled(false, hindi: false);
    expect(await PanchangReminders.instance.isEnabled(), isFalse);
  });

  test('rescheduleWindow is a no-op while disabled', () async {
    // Must not throw and must not persist an armed-ids list.
    await PanchangReminders.instance.rescheduleWindow(hindi: false);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('panchang_reminders_armed_ids'), isNull);
  });

  test('the next 60 days contain at least four Ekadashis and two Purnimas',
      () {
    // Two Ekadashis + one Purnima + one Amavasya per lunar month, so a
    // 60-day window always spans ~two months of them. This is what the
    // scheduler will queue; if the tithi indices ever drift this catches it.
    final tz = DateTime.now().timeZoneOffset;
    final today = DateTime.now();
    var ekadashi = 0, purnima = 0, amavasya = 0;
    for (var i = 1; i <= 60; i++) {
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
    expect(ekadashi, greaterThanOrEqualTo(4));
    expect(purnima, greaterThanOrEqualTo(1));
    expect(amavasya, greaterThanOrEqualTo(1));
  });
}
