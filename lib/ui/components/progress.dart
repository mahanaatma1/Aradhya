import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';

/// Circular progress ring with a rangoli-dot track.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.stroke = 6,
    this.color,
    this.track,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedProgress(
      value: value,
      builder: (context, v) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: v,
            stroke: stroke,
            color: color ?? c.accent,
            track: track ?? c.border,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value, stroke;
  final Color color, track;
  const _RingPainter(
      {required this.value,
      required this.stroke,
      required this.color,
      required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);
    if (value > 0) {
      canvas.drawArc(
          r,
          -math.pi / 2,
          math.pi * 2 * value.clamp(0, 1),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Linear progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 8});
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedProgress(
      value: value,
      builder: (context, v) => ClipRRect(
        borderRadius: Radii.rPill,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: c.border)),
              FractionallySizedBox(
                widthFactor: v.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: color == null ? c.accentGradient : [color!, color!]),
                    borderRadius: Radii.rPill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak count with a flame.
class StreakFlame extends StatelessWidget {
  const StreakFlame(this.count, {super.key, this.compact = true});
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: compact ? 32 : 40,
      padding: EdgeInsets.symmetric(horizontal: compact ? Space.x3 : Space.x4),
      decoration: BoxDecoration(
        color: c.flame.withValues(alpha: context.isDarkTheme ? .22 : .14),
        borderRadius: Radii.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: compact ? 18 : 22, color: c.flame),
          const SizedBox(width: Space.x1),
          AnimatedCount(count,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: c.flame, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
