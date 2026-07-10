import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'skeleton.dart';

/// Consistent loading / error / empty / data rendering for a Riverpod
/// [AsyncValue]. Keeps feature screens free of repetitive `.when` blocks.
/// While loading it shows a shimmer skeleton (never a spinner).
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;

  /// Skeleton shown while loading. Defaults to a generic list skeleton.
  final Widget? loading;

  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyMessage,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const SkeletonList(),
      error: (e, _) => _Message(
        icon: Icons.error_outline_rounded,
        text: 'Could not load content.\n$e',
      ),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return _Message(
            icon: Icons.hourglass_empty_rounded,
            text: emptyMessage ?? 'Nothing here yet.',
          );
        }
        return builder(data);
      },
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
