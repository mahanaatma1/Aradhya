import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/panchang/festivals.dart';
import '../../features/panchang/panchang_engine.dart';
import 'reminder_service.dart';

/// Automatic panchang reminders — the equivalent of Ishvarvaani's
/// `scheduleEkadashiNotifications` / `schedulePurnimaAmavasyaNotifications` /
/// `scheduleQuoteNotifications`.
///
/// Unlike the per-festival opt-in in `festival_reminder.dart` (the user taps a
/// switch on one festival's page), this is a **single** toggle that, once on,
/// keeps a rolling window of the recurring lunar-calendar days queued with the
/// OS — computed on-device from the panchang engine, nothing fetched.
///
/// The window is re-armed on every app launch (see `main.dart`). Because the
/// tithi-based days (Ekadashi, Purnima, Amavasya) do not repeat on a fixed
/// clock, they cannot use `matchDateTimeComponents` the way a daily nudge can;
/// a 60-day horizon re-armed each launch is the margin. The daily verse nudge
/// *does* repeat on its own and is scheduled once.
class PanchangReminders {
  PanchangReminders._();
  static final instance = PanchangReminders._();

  /// SharedPreferences keys.
  static const _enabledKey = 'panchang_reminders_enabled';
  static const _hourKey = 'panchang_reminders_hour'; // evening-before hour
  static const _verseHourKey = 'panchang_verse_hour'; // daily verse nudge hour
  static const _armedIdsKey = 'panchang_reminders_armed_ids'; // csv of notif ids

  /// Notification-id band reserved for these — clear of user reminders (1..1e5)
  /// and per-festival reminders (900000+id). 60 days of at most ~6 lunar days a
  /// month fits comfortably.
  static const _idBase = 700000;
  static const _verseId = 700999;

  static const _horizonDays = 60;

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

  Future<int> _eveHour() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_hourKey) ?? 19; // 7 pm the evening before
    } catch (_) {
      return 19;
    }
  }

  Future<int> _verseHour() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_verseHourKey) ?? 7; // 7 am
    } catch (_) {
      return 7;
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

  /// A lunar day worth a reminder, with a stable per-day id so re-arming the
  /// overlapping part of the window is idempotent.
  static ({String titleEn, String titleHi})? _lunarDayLabel(int tithiIdx) {
    switch (tithiIdx) {
      case 10: // Shukla Ekadashi
      case 25: // Krishna Ekadashi
        return (titleEn: 'Ekadashi tomorrow', titleHi: 'कल एकादशी है');
      case 14: // Purnima
        return (titleEn: 'Purnima tomorrow', titleHi: 'कल पूर्णिमा है');
      case 29: // Amavasya
        return (titleEn: 'Amavasya tomorrow', titleHi: 'कल अमावस्या है');
      default:
        return null;
    }
  }

  /// Deterministic id for the reminder about [date]'s lunar day: day-of-year in
  /// the band, so the same calendar day always maps to the same slot and a
  /// second arming replaces rather than duplicates.
  static int _idFor(DateTime date) =>
      _idBase + int.parse('${date.year % 100}${_dayOfYear(date)}');

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year)).inDays + 1;

  /// Re-arm the rolling window. Safe to call repeatedly (idempotent by id).
  Future<void> rescheduleWindow({required bool hindi}) async {
    if (!_supported) return;
    if (!await isEnabled()) return;
    final tz = DateTime.now().timeZoneOffset;
    final eveHour = await _eveHour();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Cancel whatever the previous arming left, so a day that stopped
    // qualifying (or a horizon that moved) does not leave a stale alarm.
    await _clearBand();

    final armedIds = <int>[];
    for (var i = 1; i <= _horizonDays; i++) {
      final day = today.add(Duration(days: i));
      final label = _lunarDayLabel(dayTithiIndex(day, tz));
      if (label == null) continue;

      // Fire the evening before, at the chosen hour.
      final when = DateTime(day.year, day.month, day.day, eveHour)
          .subtract(const Duration(days: 1));
      if (!when.isAfter(now)) continue;

      // If a named festival also lands on this day, let its own reminder
      // (if the user set one) speak — but this generic nudge is still useful
      // for the many Ekadashis/Purnimas that are not "festivals".
      final fest = festivalOnDay(day, tz);
      final bodyEn = fest != null
          ? '${fest.name.en} — ${label.titleEn.toLowerCase()}.'
          : 'A day for vrat and quiet practice.';
      final bodyHi = fest != null
          ? '${fest.name.hi} — ${label.titleHi}।'
          : 'व्रत और शांत साधना का दिन।';

      final id = _idFor(day);
      await _svc.scheduleOnce(
        notifId: id,
        kind: 'festival', // reuses the "Festivals" channel + route
        title: hindi ? label.titleHi : label.titleEn,
        body: hindi ? bodyHi : bodyEn,
        when: when,
        payload: '/panchang',
      );
      armedIds.add(id);
    }

    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_armedIdsKey, armedIds.join(','));
    } catch (_) {}

    await _scheduleDailyVerse(hindi: hindi, hour: await _verseHour());
    debugPrint('PanchangReminders: armed ${armedIds.length} lunar-day '
        'reminder(s) over $_horizonDays days');
  }

  /// The one daily-repeating reminder in this set. Uses the service's own
  /// repeating path so the OS keeps re-firing it without our help.
  Future<void> _scheduleDailyVerse(
      {required bool hindi, required int hour}) async {
    await _svc.schedule(
      notifId: _verseId,
      kind: 'sadhana', // a gentle daily nudge; Sadhana channel fits
      title: hindi ? 'आज का श्लोक' : 'Verse of the day',
      body: hindi
          ? 'आज का श्लोक आपकी प्रतीक्षा में है।'
          : "Today's verse is waiting for you.",
      minuteOfDay: hour * 60,
      payload: '/',
    );
  }

  /// Cancel every id the last arming recorded, plus the fixed verse id.
  Future<void> _clearBand() async {
    await _svc.cancel(_verseId);
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
