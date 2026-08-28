import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/core/notifications/reminder_service.dart';

void main() {
  group('reminderRouteFor', () {
    test('journal reminders land on the journal', () {
      expect(reminderRouteFor('journal', null), '/journal');
    });

    test('mandir reminders land on the shrine', () {
      expect(reminderRouteFor('mandir', null), '/mandir');
    });

    test('sadhana reminders land on the sadhana hub', () {
      expect(reminderRouteFor('sadhana', null), '/sadhana');
    });

    test('japa reminders land on the japa counter', () {
      expect(reminderRouteFor('japa', null), '/japa');
    });

    test('an unrecognised kind falls back to sadhana, not a crash', () {
      expect(reminderRouteFor('something_new', null), '/sadhana');
    });

    test('a festival reminder with no ref_key lands on the explorer', () {
      expect(reminderRouteFor('festival', null), '/festivals');
    });

    test('a festival reminder lands on that exact festival', () {
      expect(reminderRouteFor('festival', '42@2026-10-20T18:00:00.000'),
          '/festivals/42');
    });
  });

  group('festivalReminderDate / festivalReminderSlug', () {
    test('splits the id and the date apart', () {
      const key = '42@2026-10-20T18:00:00.000';
      expect(festivalReminderSlug(key), '42');
      expect(festivalReminderDate(key), DateTime.parse('2026-10-20T18:00:00.000'));
    });

    test('a malformed key with no @ yields no date', () {
      expect(festivalReminderDate('not-a-real-key'), isNull);
    });

    test('a null key yields no date', () {
      expect(festivalReminderDate(null), isNull);
    });
  });
}
