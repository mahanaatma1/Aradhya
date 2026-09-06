import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/panchang/festivals.dart';
import '../../features/panchang/panchang_engine.dart';
import 'reminder_service.dart';

/// Automatic panchang reminders — the equivalent of Ishvarvaani's
/// `scheduleAllNotifications` (which fans out to `scheduleEkadashiNotifications`
/// / `schedulePurnimaAmavasyaNotifications` / `scheduleFestivalNotifications` /
/// `scheduleQuoteNotifications`).
///
/// Unlike the per-festival opt-in in `festival_reminder.dart` (the user taps a
/// switch on one festival's page), this is a **single** toggle that, once on,
/// keeps a rolling window queued with the OS — all computed on-device from the
/// panchang engine, nothing fetched.
///
/// ## Timing, matched to what Ishvarvaani actually does
///
/// Read off a live device with `dumpsys alarm` (its bundle is Hermes bytecode,
/// so the schedule is only observable at runtime):
///
/// | What | When it fires | How far ahead it batches |
/// |---|---|---|
/// | Ekadashi / Purnima / Amavasya | **09:00 on the day itself** | ~180 days |
/// | Daily bhog / diya practice nudge | **21:00 every day** | one row per calendar day |
/// | Verse of the day | a morning hour | repeats on its own |
///
/// So: not "the evening before", not a 60-day horizon. The window is re-armed
/// on every app launch (see `main.dart`) so it never drains even if the user
/// does not open the panchang screen.
class PanchangReminders {
  PanchangReminders._();
  static final instance = PanchangReminders._();

  /// SharedPreferences keys.
  static const _enabledKey = 'panchang_reminders_enabled';
  static const _lunarHourKey = 'panchang_lunar_hour'; // 09:00 on the day
  static const _practiceHourKey = 'panchang_practice_hour'; // 21:00 daily
  static const _verseHourKey = 'panchang_verse_hour'; // morning verse nudge
  static const _armedIdsKey = 'panchang_reminders_armed_ids'; // csv of notif ids

  /// Defaults, chosen to match the observed Ishvarvaani schedule.
  static const _lunarHourDefault = 9;
  static const _practiceHourDefault = 21;
  static const _verseHourDefault = 7;

  /// Notification-id band reserved for these — clear of user reminders (1..1e5)
  /// and per-festival reminders (900000+id).
  static const _idBase = 700000; // one-shot lunar days, per day-of-year
  static const _verseId = 700998; // repeating morning verse nudge
  static const _practiceId = 700997; // repeating 21:00 practice nudge

  /// ~6 months, like Ishvarvaani's festival batch (seen out to March from
  /// September). Re-armed each launch, so this is a floor, not a promise.
  static const _horizonDays = 180;

  final _svc = ReminderService.instance;

  /// Same gate as [ReminderService]: nothing to schedule on desktop/web (used
  /// by tests). The pref still reads/writes so the toggle's state is honest.
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> isEnabled() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<int> _hour(String key, int fallback) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Turn the feature on or off. On → immediately arms the window; off →
  /// cancels every id in the band.
  Future<void> setEnabled(bool on, {required bool hindi}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_enabledKey, on);
    } catch (e) {
      debugPrint('PanchangReminders: pref write failed ($e)');
    }
    if (!_supported) return;
    if (on) {
      await rescheduleWindow(hindi: hindi);
    } else {
      await _clearBand();
    }
  }

  /// A lunar day worth a reminder. Title reads "today" — the reminder fires on
  /// the day itself, at 09:00, as Ishvarvaani does.
  static ({String titleEn, String titleHi})? _lunarDayLabel(int tithiIdx) {
    switch (tithiIdx) {
      case 10: // Shukla Ekadashi
      case 25: // Krishna Ekadashi
        return (titleEn: 'Ekadashi today', titleHi: 'आज एकादशी है');
      case 14: // Purnima
        return (titleEn: 'Purnima today', titleHi: 'आज पूर्णिमा है');
      case 29: // Amavasya
        return (titleEn: 'Amavasya today', titleHi: 'आज अमावस्या है');
      default:
        return null;
    }
  }

  /// Deterministic id for a lunar-day reminder on [date], so re-arming the
  /// overlapping part of the window replaces rather than duplicates. Year is
  /// folded in (mod 100) so a window that crosses New Year does not collide.
  static int _idFor(DateTime date) =>
      _idBase + int.parse('${date.year % 100}${_dayOfYear(date)}');

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year)).inDays + 1;

  /// Re-arm the rolling window. Safe to call repeatedly (idempotent by id).
  Future<void> rescheduleWindow({required bool hindi}) async {
    if (!_supported) return;
    if (!await isEnabled()) return;

    final tz = DateTime.now().timeZoneOffset;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lunarHour = await _hour(_lunarHourKey, _lunarHourDefault);
    final practiceHour = await _hour(_practiceHourKey, _practiceHourDefault);

    // Clear whatever the previous arming left, so a day that stopped
    // qualifying (or a horizon that moved) does not leave a stale alarm.
    await _clearBand();

    final armedIds = <int>[];
    var lunarCount = 0;

    // The daily practice nudge is a fixed-clock repeat — one alarm the OS
    // re-fires forever, not 180 one-shots. Ishvarvaani queues a row per day
    // because Notifee has no clean daily-repeat for a *background* trigger;
    // flutter_local_notifications does (matchDateTimeComponents), so we use it.
    await _svc.schedule(
      notifId: _practiceId,
      kind: 'mandir',
      title: hindi ? 'आज की साधना' : "Today's practice",
      body: hindi
          ? 'अपने मंदिर में दीप, भोग और प्रार्थना अर्पित करें।'
          : 'Offer a diya, bhog and a prayer at your mandir.',
      minuteOfDay: practiceHour * 60,
      payload: '/mandir',
    );

    // Only the lunar days need one-shots — they are irregular, so no
    // fixed-clock repeat can express them. ~24 over 180 days.
    for (var i = 0; i <= _horizonDays; i++) {
      final day = today.add(Duration(days: i));

      // Lunar-calendar day — Ekadashi / Purnima / Amavasya, at 09:00 on
      // the day itself.
      final label = _lunarDayLabel(dayTithiIndex(day, tz));
      if (label == null) continue;
      final lunarWhen = DateTime(day.year, day.month, day.day, lunarHour);
      if (!lunarWhen.isAfter(now)) continue;

      // If a named festival also lands on this day, lead with its name — the
      // generic nudge still earns its place for the many Ekadashis/Purnimas
      // that are not "festivals".
      final fest = festivalOnDay(day, tz);
      final bodyEn = fest != null
          ? '${fest.name.en} — a day for vrat and quiet practice.'
          : 'A day for vrat and quiet practice.';
      final bodyHi = fest != null
          ? '${fest.name.hi} — व्रत और शांत साधना का दिन।'
          : 'व्रत और शांत साधना का दिन।';

      final lid = _idFor(day);
      await _svc.scheduleOnce(
        notifId: lid,
        kind: 'festival', // Festivals channel + route
        title: hindi ? label.titleHi : label.titleEn,
        body: hindi ? bodyHi : bodyEn,
        when: lunarWhen,
        payload: '/panchang',
      );
      armedIds.add(lid);
      lunarCount++;
    }

    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_armedIdsKey, armedIds.join(','));
    } catch (_) {}

    await _scheduleDailyVerse(
        hindi: hindi, hour: await _hour(_verseHourKey, _verseHourDefault));

    debugPrint('PanchangReminders: armed $lunarCount one-shot lunar-day '
        'reminder(s) over $_horizonDays days, plus the daily practice + '
        'verse repeats');
  }

  /// The one clock-repeating reminder in this set. Uses the service's own
  /// repeating path so the OS keeps re-firing it without our help.
  Future<void> _scheduleDailyVerse(
      {required bool hindi, required int hour}) async {
    await _svc.schedule(
      notifId: _verseId,
      kind: 'sadhana',
      title: hindi ? 'आज का श्लोक' : 'Verse of the day',
      body: hindi
          ? 'आज का श्लोक आपकी प्रतीक्षा में है।'
          : "Today's verse is waiting for you.",
      minuteOfDay: hour * 60,
      payload: '/',
    );
  }

  /// Cancel every id the last arming recorded, plus the fixed repeat ids.
  Future<void> _clearBand() async {
    await _svc.cancel(_verseId);
    await _svc.cancel(_practiceId);
    try {
      final p = await SharedPreferences.getInstance();
      final csv = p.getString(_armedIdsKey) ?? '';
      for (final s in csv.split(',')) {
        final id = int.tryParse(s.trim());
        if (id != null) await _svc.cancel(id);
      }
      await p.remove(_armedIdsKey);
    } catch (e) {
      debugPrint('PanchangReminders: clear failed ($e)');
    }
  }
}
