import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/user_database.dart';
import 'reminder_service.dart';

/// One scheduled reminder, as stored.
class Reminder {
  final int id;

  /// 'sadhana' | 'journal' | 'festival' | 'mandir' — picks the channel.
  final String kind;

  /// Which thing within that kind (a practice key, a festival slug).
  final String? refKey;

  final int minuteOfDay;

  /// Digits 1-7, matching DateTime.weekday. '1234567' is every day.
  final String weekdays;

  final bool enabled;
  final int notifId;

  const Reminder({
    required this.id,
    required this.kind,
    required this.minuteOfDay,
    required this.notifId,
    this.refKey,
    this.weekdays = '1234567',
    this.enabled = true,
  });

  factory Reminder.fromRow(Map<String, Object?> r) => Reminder(
        id: r['id'] as int,
        kind: (r['kind'] as String?) ?? 'sadhana',
        refKey: r['ref_key'] as String?,
        minuteOfDay: (r['minute_of_day'] as int?) ?? 480,
        weekdays: (r['weekdays'] as String?) ?? '1234567',
        enabled: (r['enabled'] as int?) == 1,
        notifId: (r['notif_id'] as int?) ?? 0,
      );

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool get isDaily => weekdays.length == 7;
}

/// Reminders, kept in step with the OS scheduler.
///
/// Every write goes to the database *and* to [ReminderService] in the same
/// call. Letting those drift is the classic failure here: a toggle that looks
/// on while nothing is actually scheduled, which the user only discovers by
/// the reminder never arriving.
class RemindersController extends StateNotifier<List<Reminder>> {
  RemindersController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  UserDatabase? get _db => _ref.read(userDatabaseProvider);
  ReminderService get _svc => ReminderService.instance;

  Future<void> _load() async {
    final db = _db;
    if (db == null) return;
    try {
      final rows = await db.raw.query('reminders', orderBy: 'minute_of_day');
      if (!mounted) return;
      state = rows.map(Reminder.fromRow).toList();
    } catch (e) {
      debugPrint('RemindersController: load failed ($e)');
    }
  }

  /// A stable, unique notification id for a (kind, refKey) pair, in the band
  /// 100000..699999 — clear of panchang auto-reminders (700000+) and
  /// per-festival reminders (900000+). Deterministic so the same reminder
  /// always maps to the same id across restarts, and distinct kinds never
  /// collide (which would make one tray entry stand for two reminders).
  static int _notifIdFor(String kind, String? refKey) {
    final h = '$kind|${refKey ?? ''}'.hashCode & 0x7fffffff;
    return 100000 + (h % 600000);
  }

  Reminder? forKey(String kind, String? refKey) {
    for (final r in state) {
      if (r.kind == kind && r.refKey == refKey) return r;
    }
    return null;
  }

  /// Creates or updates a reminder, and schedules it.
  ///
  /// Returns false when the OS denied notification permission — the caller
  /// should then leave its toggle off rather than showing a reminder that will
  /// never fire.
  Future<bool> set({
    required String kind,
    String? refKey,
    required int minuteOfDay,
    String weekdays = '1234567',
    required String title,
    required String body,
  }) async {
    final db = _db;
    if (db == null) return false;

    final granted = await _svc.requestPermission();
    if (!granted) return false;

    final existing = forKey(kind, refKey);
    // Notification ids must be stable and unique per (kind, refKey). The old
    // code used `millis % 100000`, which is random: two reminders created in
    // the same ~100s window could land on the same id, and then the OS treats
    // the second `show`/`schedule` as an *update* of the first — one tray
    // entry, and cancelling one cancels both. Deriving it from the key fixes
    // that and also lets a reminder be cancelled after a cold restart.
    // Band 100000..699999 — clear of panchang (700000+) and festivals (900000+).
    final notifId = existing?.notifId ?? _notifIdFor(kind, refKey);

    try {
      if (existing == null) {
        await db.raw.insert('reminders', {
          'kind': kind,
          'ref_key': refKey,
          'minute_of_day': minuteOfDay,
          'weekdays': weekdays,
          'enabled': 1,
          'notif_id': notifId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await db.raw.update(
          'reminders',
          {
            'minute_of_day': minuteOfDay,
            'weekdays': weekdays,
            'enabled': 1,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await _svc.cancel(existing.notifId);
      }

      await _svc.schedule(
        notifId: notifId,
        kind: kind,
        title: title,
        body: body,
        minuteOfDay: minuteOfDay,
        weekdays: weekdays,
      );
      await _load();
      return true;
    } catch (e) {
      debugPrint('RemindersController: set failed ($e)');
      return false;
    }
  }

  Future<void> remove(String kind, String? refKey) async {
    final existing = forKey(kind, refKey);
    if (existing == null) return;
    await _svc.cancel(existing.notifId);
    final db = _db;
    if (db == null) return;
    try {
      await db.raw
          .delete('reminders', where: 'id = ?', whereArgs: [existing.id]);
      await _load();
    } catch (e) {
      debugPrint('RemindersController: remove failed ($e)');
    }
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersController, List<Reminder>>(
        (ref) => RemindersController(ref));
