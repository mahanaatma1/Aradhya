import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/panchang_reminders.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/providers/app_providers.dart';

/// Debug-only. A hands-on panel for checking that notifications actually fire
/// on a real device, what they say, and where a tap lands — without waiting
/// for 09:00 or an Ekadashi. Reached from Profile → Reminders in debug builds;
/// the route is not registered in release.
class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  final _svc = ReminderService.instance;
  String _log = '';
  int _pending = 0;
  int _active = 0;
  List<String> _pendingList = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final c = await _svc.counts();
    final list = await _svc.pendingList();
    if (!mounted) return;
    setState(() {
      _pending = c.pending;
      _active = c.active;
      _pendingList = list;
    });
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    final msg = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _log = '${DateTime.now().toString().substring(11, 19)}  $msg\n$_log';
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;

    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification test')),
        body: const Center(child: Text('Debug builds only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'सूचना परीक्षण' : 'Notification test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _busy ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- live counts ----
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                      label: hi ? 'निर्धारित' : 'Scheduled',
                      value: '$_pending'),
                  _Stat(
                      label: hi ? 'ट्रे में' : 'In tray',
                      value: '$_active'),
                  _Stat(
                    label: hi ? 'सटीक अलार्म' : 'Exact alarms',
                    value: _svc.canScheduleExact ? 'ON' : 'OFF',
                    warn: !_svc.canScheduleExact,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(hi ? 'अभी भेजें' : 'Send now',
              style: Theme.of(context).textTheme.titleMedium),
          Text(
            hi
                ? 'तुरंत दिखनी चाहिए। टैप करने पर नीचे लिखी स्क्रीन खुलेगी।'
                : 'Should appear instantly. Tapping opens the screen noted.',
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          for (final (kind, name) in ReminderService.channels)
            _TestRow(
              name: name,
              route: reminderRouteFor(kind, null),
              busy: _busy,
              onNow: () => _run(() => _svc.fireTest(kind: kind, hindi: hi)),
              onDelayed: () => _run(() => _svc.fireTest(
                  kind: kind, hindi: hi, delay: const Duration(seconds: 15))),
            ),

          const SizedBox(height: 20),
          Text(hi ? 'असली रिमाइंडर' : 'Real reminders',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await PanchangReminders.instance
                          .setEnabled(true, hindi: hi);
                      return hi
                          ? 'पंचांग रिमाइंडर चालू + शेड्यूल हुए।'
                          : 'Panchang reminders enabled + scheduled.';
                    }),
            icon: const Icon(Icons.event_available_rounded),
            label: Text(hi
                ? 'पंचांग रिमाइंडर चालू करें और शेड्यूल करें'
                : 'Enable & schedule panchang reminders'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await PanchangReminders.instance
                          .setEnabled(false, hindi: hi);
                      return hi ? 'बंद + सब रद्द।' : 'Disabled + all cancelled.';
                    }),
            icon: const Icon(Icons.event_busy_rounded),
            label: Text(hi ? 'बंद करें और रद्द करें' : 'Disable & cancel all'),
          ),

          const SizedBox(height: 20),
          Text(hi ? 'निर्धारित सूची' : 'Scheduled queue',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_pendingList.isEmpty)
            Text(hi ? 'कुछ भी निर्धारित नहीं।' : 'Nothing scheduled.',
                style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.6))),
          for (final row in _pendingList)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(row,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12)),
            ),

          const SizedBox(height: 20),
          Text(hi ? 'लॉग' : 'Log',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _log.isEmpty ? '—' : _log,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.warn = false});
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: warn ? scheme.error : scheme.primary)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({
    required this.name,
    required this.route,
    required this.busy,
    required this.onNow,
    required this.onDelayed,
  });
  final String name;
  final String route;
  final bool busy;
  final VoidCallback onNow;
  final VoidCallback onDelayed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('→ $route',
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
          TextButton(onPressed: busy ? null : onNow, child: const Text('Now')),
          TextButton(
              onPressed: busy ? null : onDelayed, child: const Text('+15s')),
        ],
      ),
    );
  }
}
