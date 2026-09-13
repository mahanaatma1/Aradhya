import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Bandhani tie-dye dots — the Utsav texture, painted as a repeating field of
/// small pale circles. Cheap: one `drawPoints` call per paint.
class BandhaniDots extends StatelessWidget {
  const BandhaniDots({
    super.key,
    this.color,
    this.spacing = 14,
    this.radius = 1.6,
    this.opacity = 0.35,
  });

  final Color? color;
  final double spacing;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DotsPainter(
          color: (color ?? Colors.white).withValues(alpha: opacity),
          spacing: spacing,
          radius: radius,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;
  const _DotsPainter(
      {required this.color, required this.spacing, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = radius * 2
      ..strokeCap = StrokeCap.round;
    final pts = <Offset>[];
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        pts.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, pts, paint);
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}

/// The three-colour festival stripe (vermilion · marigold · peacock).
class FestivalStripe extends StatelessWidget {
  const FestivalStripe({super.key, this.height = 6, this.radius = 3});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _StripePainter([c.accent, c.gold, c.info]),
        size: Size(double.infinity, height),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final List<Color> colors;
  const _StripePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 14.0;
    var x = 0.0, i = 0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height),
          Paint()..color = colors[i % colors.length]);
      x += w;
      i++;
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.colors != colors;
}

/// A rangoli-style ring motif for empty states and section marks.
class RangoliMark extends StatelessWidget {
  const RangoliMark({super.key, this.size = 72, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RangoliPainter(color ?? context.colors.accent),
    );
  }
}

class _RangoliPainter extends CustomPainter {
  final Color color;
  const _RangoliPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.7);
    canvas.drawCircle(c, r * 0.95, stroke);
    canvas.drawCircle(c, r * 0.68, stroke);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 3.14159 / 4);
      canvas.drawLine(Offset(0, -r * 0.68), Offset(0, -r * 0.95), stroke);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-r * 0.18, -r * 0.3, 0, -r * 0.6)
        ..quadraticBezierTo(r * 0.18, -r * 0.3, 0, 0)
        ..close();
      canvas.drawPath(petal, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawPath(petal, stroke);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.12, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RangoliPainter old) => old.color != color;
}
