import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tokens/motion_tokens.dart';
import 'motion_scope.dart';

enum AppTransition {
  /// Push: incoming slides in from the right, outgoing parallaxes left.
  sharedAxisX,

  /// Sheet-like: rises from below.
  sharedAxisY,

  /// Tab-level and readers: fade through a scale.
  fadeThrough,

  /// Detail with a Hero cover: fade only, so the hero flight owns the motion.
  heroFade,
}

/// The one page type for go_router routes. Reads [MotionScope] at transition
/// time, so reduced motion collapses everything to a 120 ms fade.
class AppPage<T> extends CustomTransitionPage<T> {
  AppPage({
    required GoRouterState state,
    required super.child,
    AppTransition kind = AppTransition.sharedAxisX,
    super.opaque,
  }) : super(
          key: state.pageKey,
          name: state.name ?? state.uri.toString(),
          arguments: state.extra,
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.base,
          transitionsBuilder: (context, animation, secondary, child) =>
              _build(context, kind, animation, secondary, child),
        );

  static Widget _build(
    BuildContext context,
    AppTransition kind,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (MotionScope.of(context).reduce) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    }
    final enter = CurvedAnimation(
        parent: animation, curve: Motion.emphasized, reverseCurve: Motion.exit);
    final leave = CurvedAnimation(parent: secondary, curve: Motion.standard);
    switch (kind) {
      case AppTransition.sharedAxisX:
        return SlideTransition(
          position: Tween(begin: const Offset(-0.18, 0), end: Offset.zero)
              .animate(leave)
              .drive(Tween(begin: Offset.zero, end: const Offset(-0.18, 0))),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.7).animate(leave),
            child: SlideTransition(
              position: Tween(begin: const Offset(0.16, 0), end: Offset.zero)
                  .animate(enter),
              child: FadeTransition(opacity: enter, child: child),
            ),
          ),
        );
      case AppTransition.sharedAxisY:
        return SlideTransition(
          position:
              Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(enter),
          child: FadeTransition(opacity: enter, child: child),
        );
      case AppTransition.fadeThrough:
        return FadeTransition(
          opacity: enter,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(enter),
            child: child,
          ),
        );
      case AppTransition.heroFade:
        return FadeTransition(opacity: enter, child: child);
    }
  }
}
