import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/router/app_router.dart';
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

  /// Set when the app was cold-started by tapping a notification —
  /// `onDidReceiveNotificationResponse` does not fire for that case, so
  /// `main()` reads this once the router exists and navigates itself.
  String? _pendingLaunchPayload;

  /// Consumes and returns the payload of the notification that cold-started
  /// the app, if any. Null every other time (warm start, or no launch
  /// notification) — deliberately one-shot so re-reading it after `main()`
  /// has already navigated does not send the user back there again.
  String? takePendingLaunchPayload() {
    final p = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return p;
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    // Fires from a platform callback, outside any widget's BuildContext —
    // the app-wide router instance is the only way to navigate from here.
    try {
      appRouter.push(payload);
    } catch (e) {
      debugPrint('ReminderService: tap navigation failed ($e)');
    }
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// One channel per kind, so a user can silence journal nudges without
  /// losing festival reminders. Bundling everything into one channel makes
  /// that an all-or-nothing choice.
  static const _channels = <String, (String, String)>{
    'sadhana': ('Sadhana', 'Reminders for breathing and daily practice'),
    'japa': ('Japa', 'A nudge to complete today\'s mala'),
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
        // A tapped reminder should land on the thing it was about — a
        // journal nudge on the journal, a festival reminder on that
        // festival — not just bring the app to whatever screen it was
        // last on. `onDidReceiveNotificationResponse` covers the app
        // already running or backgrounded; `_onLaunchPayload` (below)
        // covers a cold start from a tap, which this callback does not
        // fire for.
        onDidReceiveNotificationResponse: _onTap,
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _pendingLaunchPayload = launch?.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('ReminderService: init failed ($e)');
    }
  }

  /// Requests permission at the point a reminder is actually being set.
  /// Returns false when denied, so callers can leave the toggle off rather
  /// than pretending a reminder was scheduled.
  ///
  /// On Android this asks for two things: the POST_NOTIFICATIONS runtime
  /// permission (13+), and — where the OS did not auto-grant it via
  /// USE_EXACT_ALARM — the exact-alarm permission, without which a reminder
  /// under Doze on a Xiaomi/Oppo/Samsung device can be delayed for hours or
  /// dropped. Notification permission is the hard requirement; exact-alarm is
  /// best-effort, so a refusal there still returns true and the schedule falls
  /// back to inexact.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final notif =
            await android?.requestNotificationsPermission() ?? false;
        if (notif) {
          _canScheduleExact =
              await android?.canScheduleExactNotifications() ?? false;
          if (!_canScheduleExact) {
            // Opens the system "Alarms & reminders" page for this app. The
            // user may decline; we do not block the reminder on it.
            await android?.requestExactAlarmsPermission();
            _canScheduleExact =
                await android?.canScheduleExactNotifications() ?? false;
          }
        }
        return notif;
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

  /// Whether the OS will let us post *exact* alarms. Re-checked on each
  /// permission request; assume true elsewhere (iOS has no such gate) and let
  /// [_scheduleMode] downgrade when it is false.
  bool _canScheduleExact = true;

  /// Exact where the OS allows it — a reminder the user set for 6:00 am should
  /// arrive at 6:00 am, not 7:40. Falls back to inexact-while-idle when the
  /// exact-alarm permission was refused, which still fires, just fuzzily.
  AndroidScheduleMode get _scheduleMode => _canScheduleExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

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
    String? payload,
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
        // Exact where the OS permits it (USE_EXACT_ALARM is auto-granted for a
        // reminder-first app; otherwise the user grants it once). Falls back to
        // inexact-while-idle when refused — still fires, just fuzzily. Inexact
        // alone was the reason reminders were unreliable on OEM-throttled
        // devices.
        androidScheduleMode: _scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? reminderRouteFor(kind, null),
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
    String? payload,
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
        // A festival fires once, on a date the panchang fixed — exactness
        // matters more here than for a daily nudge. Same fallback as above.
        androidScheduleMode: _scheduleMode,
        // No matchDateTimeComponents: this must NOT repeat.
        payload: payload ?? reminderRouteFor(kind, null),
      );
    } catch (e) {
      debugPrint('ReminderService: scheduleOnce failed ($e)');
    }
  }

  Future<void> cancel(int notifId) async {
    if (!_supported) return;
    await init();
    if (!_ready) return; // nothing was ever scheduled, nothing to cancel
    try {
      await _plugin.cancel(id: notifId);
    } catch (e) {
      debugPrint('ReminderService: cancel failed ($e)');
    }
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
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
        final refKey = r['ref_key'] as String?;
        if (kind == 'festival') {
          // Festival rows carry their date in ref_key as 'id@iso'. They fire
          // once, and a row whose date has passed is simply not re-armed.
          final when = festivalReminderDate(refKey);
          if (when != null) {
            await scheduleOnce(
              notifId: r['notif_id'] as int,
              kind: kind,
              title: _titleFor(kind, hindi),
              body: _bodyFor(kind, refKey, hindi),
              when: when,
              payload: reminderRouteFor(kind, refKey),
            );
          }
          continue;
        }
        await schedule(
          notifId: r['notif_id'] as int,
          kind: kind,
          title: _titleFor(kind, hindi),
          body: _bodyFor(kind, refKey, hindi),
          minuteOfDay: (r['minute_of_day'] as int?) ?? 8 * 60,
          weekdays: (r['weekdays'] as String?) ?? '1234567',
          payload: reminderRouteFor(kind, refKey),
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
        'japa' => hi ? 'जप' : 'Japa',
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
        'japa' => hi
            ? 'आज की माला अभी पूरी नहीं हुई।'
            : 'Today\'s mala is still waiting.',
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

/// Where tapping a reminder of this [kind] should land. [refKey] carries the
/// festival id (`'42@2026-...'`) for festival reminders; every other kind
/// ignores it and goes to its one fixed screen. A top-level function (rather
/// than a private method on [ReminderService]) so it's directly testable —
/// this is the part most worth locking in, since a wrong route here fails
/// silently: the notification still fires, it just lands somewhere else.
String reminderRouteFor(String kind, String? refKey) => switch (kind) {
      'journal' => '/journal',
      'festival' => refKey == null
          ? '/festivals'
          : '/festivals/${festivalReminderSlug(refKey)}',
      'mandir' => '/mandir',
      'japa' => '/japa',
      _ => '/sadhana',
    };
