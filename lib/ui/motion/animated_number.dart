import 'package:flutter/material.dart';

import '../tokens/motion_tokens.dart';
import 'motion_scope.dart';

/// A number that counts to its new value with tabular figures.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(
    this.value, {
    super.key,
    this.style,
    this.duration = Motion.slow,
    this.format,
  });

  final num value;
  final TextStyle? style;
  final Duration duration;
  final String Function(num)? format;

  @override
  Widget build(BuildContext context) {
    final m = MotionScope.of(context);
    final s = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (m.reduce) return Text(format?.call(value) ?? _fmt(value), style: s);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Motion.emphasized,
      builder: (context, v, _) =>
          Text(format?.call(value is int ? v.round() : v) ?? _fmt(value is int ? v.round() : v), style: s),
    );
  }

  static String _fmt(num v) => v is int ? '$v' : v.toStringAsFixed(1);
}

/// Animates a 0..1 progress value for rings and bars.
class AnimatedProgress extends StatelessWidget {
  const AnimatedProgress({
    super.key,
    required this.value,
    required this.builder,
    this.duration = Motion.hero,
  });

  final double value;
  final Widget Function(BuildContext, double) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MotionScope.of(context).reduce) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: duration,
      curve: Motion.emphasized,
      builder: (context, v, _) => builder(context, v),
    );
  }
}
