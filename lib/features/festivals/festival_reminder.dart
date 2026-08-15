import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/user_database.dart';
import '../../core/notifications/reminder_service.dart';
import 'festival_models.dart';

/// Festival reminders.
///
/// A festival reminder is one-off — it fires the evening before a date the
/// panchang decided — so it is stored and re-armed differently from the daily
/// sadhana and journal nudges. See [festivalReminderDate] for the ref_key
/// encoding.
class FestivalReminders extends StateNotifier<Set<int>> {
  FestivalReminders(this._ref) : super(const {}) {
    _load();
  }

  final Ref _ref;

  /// The hour of the evening before, when the reminder lands.
  static const _eveHour = 18;

  Future<void> _load() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw
          .query('reminders', where: "kind = 'festival' AND enabled = 1");
      final ids = <int>{};
      for (final r in rows) {
        final key = r['ref_key'] as String?;
        if (key == null) continue;
        final id = int.tryParse(festivalReminderSlug(key));
        if (id != null) ids.add(id);
      }
      if (mounted) state = ids;
    } catch (_) {
      // A reminder list that fails to load must not take the screen with it.
    }
  }

  bool isSet(int festivalId) => state.contains(festivalId);

  /// Toggle the reminder for [f], firing the evening before [date].
  ///
  /// Returns true if a reminder is now set. Returns false when it was removed,
  /// and also when the date is already past — there is nothing to remind about.
  Future<bool> toggle(Festival f, DateTime date, {required bool hindi}) async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return false;
    final service = _ref.read(reminderServiceProvider);

    if (state.contains(f.id)) {
      await _remove(db, service, f.id);
      state = {...state}..remove(f.id);
      return false;
    }

    final when = DateTime(date.year, date.month, date.day, _eveHour)
        .subtract(const Duration(days: 1));
    if (!when.isAfter(DateTime.now())) return false;

    // A stable handle per festival, kept clear of the sadhana range.
    final notifId = 900000 + f.id;
    try {
      await db.raw.insert('reminders', {
        'kind': 'festival',
        'ref_key': '${f.id}@${when.toIso8601String()}',
        'minute_of_day': _eveHour * 60,
        'weekdays': '1234567',
        'enabled': 1,
        'notif_id': notifId,
      });
      await service.scheduleOnce(
        notifId: notifId,
        kind: 'festival',
        title: hindi ? 'कल का पर्व' : 'Festival tomorrow',
        body: hindi
            ? '${f.title(true)} कल है।'
            : '${f.title(false)} is tomorrow.',
        when: when,
      );
    } catch (_) {
      return false;
    }
    state = {...state, f.id};
    return true;
  }

  Future<void> _remove(
      UserDatabase db, ReminderService service, int festivalId) async {
    try {
      await db.raw.delete('reminders',
          where: "kind = 'festival' AND ref_key LIKE ?",
          whereArgs: ['$festivalId@%']);
      await service.cancel(900000 + festivalId);
    } catch (_) {
      // Already gone, or the plugin is unavailable on this platform.
    }
  }
}

final festivalRemindersProvider =
    StateNotifierProvider<FestivalReminders, Set<int>>(
        (ref) => FestivalReminders(ref));
