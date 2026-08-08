import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'reminders_repository.dart';

/// A switch plus a time picker for one reminder.
///
/// Reusable across journal, sadhana and mandir so a reminder behaves the same
/// everywhere. The toggle only stays on if the OS actually granted permission
/// and the schedule call succeeded — showing "on" for a reminder that will
/// never fire is the failure mode worth designing against.
class ReminderTile extends ConsumerWidget {
  final String kind;
  final String? refKey;

  /// Notification copy.
  final String titleEn;
  final String titleHi;
  final String bodyEn;
  final String bodyHi;

  /// Row label.
  final String labelEn;
  final String labelHi;

  /// Used when the user turns it on for the first time.
  final int defaultMinuteOfDay;

  const ReminderTile({
    super.key,
    required this.kind,
    required this.titleEn,
    required this.titleHi,
    required this.bodyEn,
    required this.bodyHi,
    required this.labelEn,
    required this.labelHi,
    this.refKey,
    this.defaultMinuteOfDay = 20 * 60,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final reminders = ref.watch(remindersProvider);
    final scheme = Theme.of(context).colorScheme;

    final existing = reminders
        .where((r) => r.kind == kind && r.refKey == refKey)
        .firstOrNull;
    final on = existing != null && existing.enabled;

    Future<void> setAt(int minuteOfDay) async {
      final ok = await ref.read(remindersProvider.notifier).set(
            kind: kind,
            refKey: refKey,
            minuteOfDay: minuteOfDay,
            title: hi ? titleHi : titleEn,
            body: hi ? bodyHi : bodyEn,
          );
      if (!ok && context.mounted) {
        // Say what happened rather than silently leaving the switch off.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(hi
              ? 'सूचनाओं की अनुमति नहीं मिली — इसे सेटिंग्स में चालू करें।'
              : 'Notification permission was declined — enable it in Settings.'),
        ));
      }
    }

    Future<void> pickTime() async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: existing?.hour ?? defaultMinuteOfDay ~/ 60,
          minute: existing?.minute ?? defaultMinuteOfDay % 60,
        ),
      );
      if (t != null) await setAt(t.hour * 60 + t.minute);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 19, color: scheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hi ? labelHi : labelEn,
                    style: const TextStyle(fontSize: 14.5)),
                if (on)
                  Text(
                    hi
                        ? 'प्रतिदिन ${existing.timeLabel}'
                        : 'Daily at ${existing.timeLabel}',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.primary.withValues(alpha: 0.9)),
                  ),
              ],
            ),
          ),
          if (on)
            TextButton(
              onPressed: pickTime,
              child: Text(existing.timeLabel,
                  style: const TextStyle(fontSize: 13)),
            ),
          Switch(
            value: on,
            onChanged: (v) async {
              if (v) {
                await setAt(defaultMinuteOfDay);
              } else {
                await ref
                    .read(remindersProvider.notifier)
                    .remove(kind, refKey);
              }
            },
          ),
        ],
      ),
    );
  }
}
