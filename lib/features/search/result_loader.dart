import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';

/// Opens a detail screen from an id alone.
///
/// Most detail routes were built for in-app navigation, where the caller
/// already holds the model and passes it through `extra`. Search results have
/// only a row id — and `extra` does not survive a deep link anyway — so pushing
/// `/temple?id=7` at a builder expecting `state.extra as Temple` would throw a
/// null cast.
///
/// This resolves the row first, then hands the real model to the same screen,
/// so there is exactly one detail implementation per content type.
class ResultLoader<T> extends ConsumerWidget {
  /// Table to read from, in the legacy content database.
  final String table;
  final int id;

  /// Row -> model.
  final T Function(Map<String, Object?> row) fromRow;

  /// Model -> the real detail screen.
  final Widget Function(T model) builder;

  const ResultLoader({
    super.key,
    required this.table,
    required this.id,
    required this.fromRow,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_rowProvider((table: table, id: id)));

    return value.when(
      loading: () => const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => MissingItemScreen(detail: '$e'),
      data: (row) =>
          row == null ? const MissingItemScreen() : builder(fromRow(row)),
    );
  }
}

typedef _RowKey = ({String table, int id});

final _rowProvider =
    FutureProvider.family<Map<String, Object?>?, _RowKey>((ref, key) async {
  final db = await ref.watch(contentDbProvider.future);
  final rows = await db.raw
      .query(key.table, where: 'id = ?', whereArgs: [key.id], limit: 1);
  return rows.isEmpty ? null : rows.first;
});

/// Shown when an id no longer resolves — normally a stale search index pointing
/// at a row that a content rebuild moved or removed. A clear dead end beats a
/// crash or a blank screen.
/// Public so the router can show it when a deep link arrives with no usable
/// id at all — the same dead end, reached a different way.
class MissingItemScreen extends StatelessWidget {
  final String? detail;
  const MissingItemScreen({super.key, this.detail});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off_rounded,
                  size: 40, color: scheme.onSurface.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              Text(
                Localizations.localeOf(context).languageCode == 'hi'
                    ? 'यह सामग्री नहीं मिली'
                    : 'This item could not be found',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.4))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
