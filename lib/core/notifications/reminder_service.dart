import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/user_database.dart';

/// Local, scheduled reminders for sadhana, journal and festivals.
///
/// Entirely on-device: `flutter_local_notifications` schedules against the OS
/// alarm manager. Nothing is registered with a push service and nothing leaves
/// the phone — the app has no backend, and a reminder is not a reason to
/// acquire one.
///
/// Every method is a no-op on unsupported platforms rather than throwing, so a
/// desktop or web build (used for tests) is unaffected.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// One channel per kind, so a user can silence journal nudges without
  /// losing festival reminders. Bundling everything into one channel makes
  /// that an all-or-nothing choice.
  static const _channels = <String, (String, String)>{
    'sadhana': ('Sadhana', 'Reminders for japa, breathing and daily practice'),
    'journal': ('Journal', 'A nudge to write your daily reflection'),
    'festival': ('Festivals', 'Upcoming vrats and festivals'),
    'mandir': ('Mandir', 'Offering windows at your home shrine'),
  };

  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      tzdata.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        // Asked for later, in context, rather than at first launch — a
        // permission prompt before the user knows what it is for gets denied.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      // v22 moved these to named parameters.
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (e) {
      debugPrint('ReminderService: init failed ($e)');
    }
  }

  /// Requests permission at the point a reminder is actually being set.
  /// Returns false when denied, so callers can leave the toggle off rather
  /// than pretending a reminder was scheduled.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    } catch (e) {
      debugPrint('ReminderService: permission request failed ($e)');
      return false;
    }
  }

  NotificationDetails _details(String kind) {
    final (name, desc) = _channels[kind] ?? _channels['sadhana']!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'aradhya_$kind',
        name,
        channelDescription: desc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Next occurrence of [minuteOfDay] that falls on one of [weekdays]
  /// (1 = Monday … 7 = Sunday, matching DateTime.weekday).
  tz.TZDateTime _nextOccurrence(int minuteOfDay, String weekdays) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day)
        .add(Duration(minutes: minuteOfDay));
    // Search forward at most a week; a reminder with no valid weekday would
    // otherwise loop forever.
    for (var i = 0; i < 8; i++) {
      if (when.isAfter(now) && weekdays.contains('${when.weekday}')) {
        return when;
      }
      when = when.add(const Duration(days: 1));
    }
    return now.add(const Duration(days: 1));
  }

  Future<void> schedule({
    required int notifId,
    required String kind,
    required String title,
    required String body,
    required int minuteOfDay,
    String weekdays = '1234567',
  }) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: _nextOccurrence(minuteOfDay, weekdays),
        notificationDetails: _details(kind),
        // Inexact on purpose: an exact alarm needs SCHEDULE_EXACT_ALARM, which
        // Android 13+ treats as a high-friction permission. A devotional
        // reminder does not need to fire to the second.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Exact-alarm permission, OEM battery policies and Doze all fail here.
      // A missed reminder must not take the feature — or the app — down.
      debugPrint('ReminderService: schedule failed ($e)');
    }
  }

  /// A one-shot reminder at a specific moment.
  ///
  /// [schedule] repeats daily, which is right for a sadhana or a journal nudge
  /// and wrong for a festival: a festival happens once, on a date the panchang
  /// decides. Fires nothing if [when] is already past.
  Future<void> scheduleOnce({
    required int notifId,
    required String kind,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    final at = tz.TZDateTime.from(when, tz.local);
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: at,
        notificationDetails: _details(kind),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // No matchDateTimeComponents: this must NOT repeat.
      );
    } catch (e) {
      debugPrint('ReminderService: scheduleOnce failed ($e)');
    }
  }

  Future<void> cancel(int notifId) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: notifId);
    } catch (e) {
      debugPrint('ReminderService: cancel failed ($e)');
    }
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('ReminderService: cancelAll failed ($e)');
    }
  }

  /// Re-arms every enabled reminder from the database.
  ///
  /// Android drops scheduled alarms on reboot and on app update, so this runs
  /// at startup. Without it, reminders quietly stop working after a phone
  /// restart — a failure the user would blame on the app, correctly.
  Future<void> rescheduleAll(UserDatabase db, {required bool hindi}) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      final rows = await db.raw.query('reminders', where: 'enabled = 1');
      await cancelAll();
      for (final r in rows) {
        final kind = (r['kind'] as String?) ?? 'sadhana';
        if (kind == 'festival') {
          // Festival rows carry their date in ref_key as 'slug@iso'. They fire
          // once, and a row whose date has passed is simply not re-armed.
          final when = festivalReminderDate(r['ref_key'] as String?);
          if (when != null) {
            await scheduleOnce(
              notifId: r['notif_id'] as int,
              kind: kind,
              title: _titleFor(kind, hindi),
              body: _bodyFor(kind, r['ref_key'] as String?, hindi),
              when: when,
            );
          }
          continue;
        }
        await schedule(
          notifId: r['notif_id'] as int,
          kind: kind,
          title: _titleFor(kind, hindi),
          body: _bodyFor(kind, r['ref_key'] as String?, hindi),
          minuteOfDay: (r['minute_of_day'] as int?) ?? 8 * 60,
          weekdays: (r['weekdays'] as String?) ?? '1234567',
        );
      }
      debugPrint('ReminderService: rescheduled ${rows.length} reminder(s)');
    } catch (e) {
      debugPrint('ReminderService: reschedule failed ($e)');
    }
  }

  static String _titleFor(String kind, bool hi) => switch (kind) {
        'journal' => hi ? 'कर्म डायरी' : 'Karma Journal',
        'festival' => hi ? 'आगामी पर्व' : 'Upcoming festival',
        'mandir' => hi ? 'मंदिर' : 'Mandir',
        _ => hi ? 'साधना' : 'Sadhana',
      };

  static String _bodyFor(String kind, String? refKey, bool hi) =>
      switch (kind) {
        'journal' => hi
            ? 'आज का प्रश्न आपकी प्रतीक्षा में है।'
            : 'Today\'s prompt is waiting for you.',
        'festival' => hi ? 'कल एक पर्व है।' : 'A festival falls tomorrow.',
        'mandir' => hi
            ? 'अर्पण का समय खुला है।'
            : 'The offering window is open.',
        _ => hi
            ? 'आज की साधना का समय।'
            : 'Time for today\'s practice.',
      };
}

final reminderServiceProvider =
    Provider<ReminderService>((ref) => ReminderService.instance);

/// The date encoded in a festival reminder's `ref_key`.
///
/// Stored as `slug@2026-10-20T18:00:00.000` rather than in a column of its own:
/// every other reminder kind repeats and needs no date, and a schema migration
/// to carry one field used by a single kind is a worse trade than a documented
/// encoding. Returns null for a malformed or non-festival key.
DateTime? festivalReminderDate(String? refKey) {
  if (refKey == null) return null;
  final at = refKey.indexOf('@');
  if (at < 0) return null;
  return DateTime.tryParse(refKey.substring(at + 1));
}

/// The slug half of a festival reminder's `ref_key`.
String festivalReminderSlug(String refKey) {
  final at = refKey.indexOf('@');
  return at < 0 ? refKey : refKey.substring(0, at);
}
