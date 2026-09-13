import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/skeleton.dart';
import '../tokens/tokens.dart';
import 'buttons.dart';
import 'utsav_decor.dart';

export '../../shared/widgets/skeleton.dart';

/// Nothing here yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.action,
    this.motif,
  });

  final String title;
  final String? body;
  final Widget? action;
  final Widget? motif;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            motif ?? RangoliMark(color: c.gold),
            const SizedBox(height: Space.x4),
            ScriptText(title,
                style: tt.titleMedium?.copyWith(color: c.ink),
                textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: Space.x2),
              ScriptText(body!,
                  style: tt.bodyMedium?.copyWith(color: c.inkFaint),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: Space.x4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Something failed; offers a retry.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry, this.title});
  final String message;
  final String? title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hi = Localizations.maybeLocaleOf(context)?.languageCode == 'hi';
    return EmptyState(
      motif: Icon(Icons.error_outline_rounded, size: 48, color: c.danger),
      title: title ?? (hi ? 'कुछ गड़बड़ हो गई' : 'Something went wrong'),
      body: message,
      action: onRetry == null
          ? null
          : SecondaryButton(
              label: hi ? 'फिर कोशिश करें' : 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry),
    );
  }
}

/// Skeleton presets while data loads.
class LoadingState extends StatelessWidget {
  const LoadingState.list({super.key}) : _kind = 0;
  const LoadingState.cards({super.key}) : _kind = 1;
  const LoadingState.reader({super.key}) : _kind = 2;
  final int _kind;

  @override
  Widget build(BuildContext context) => switch (_kind) {
        1 => const SkeletonTempleCards(),
        2 => const SkeletonReader(),
        _ => const SkeletonList(),
      };
}

/// Riverpod [AsyncValue] → loading / error / empty / data, kit-styled.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyTitle,
    this.emptyBody,
    this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String? emptyTitle;
  final String? emptyBody;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hi = Localizations.maybeLocaleOf(context)?.languageCode == 'hi';
    return value.when(
      loading: () => loading ?? const LoadingState.list(),
      error: (e, _) => ErrorState(message: '$e', onRetry: onRetry),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return EmptyState(
            title: emptyTitle ?? (hi ? 'अभी यहाँ कुछ नहीं' : 'Nothing here yet'),
            body: emptyBody,
          );
        }
        return builder(data);
      },
    );
  }
}
