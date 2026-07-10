import 'package:flutter/material.dart';

/// Paints the signature dashed "stitched" outline, inset from a rounded card's
/// edge — the throughline of the DivyaVaani identity (see the logo).
class StitchedBorderPainter extends CustomPainter {
  final Color color;
  final double inset;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const StitchedBorderPainter({
    required this.color,
    this.inset = 7,
    this.radius = 11,
    this.strokeWidth = 1.5,
    this.dash = 5,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(StitchedBorderPainter old) =>
      old.color != color ||
      old.inset != inset ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

/// A rounded surface with the stitched dashed outline painted inside it.
class StitchedCard extends StatelessWidget {
  final Widget child;
  final Color? background;
  final Gradient? gradient;
  final Color stitchColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const StitchedCard({
    super.key,
    required this.child,
    required this.stitchColor,
    this.background,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: gradient == null ? (background ?? Theme.of(context).cardColor) : null,
            gradient: gradient,
            borderRadius: borderRadius,
          ),
          child: CustomPaint(
            foregroundPainter: StitchedBorderPainter(
              color: stitchColor,
              radius: radius - 7,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
