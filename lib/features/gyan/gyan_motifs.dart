import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn motifs for the Gyan tiles, one per module.
///
/// Material icons were doing this job and doing it badly: `hub_rounded` for a
/// knowledge graph, a generic book for the epics, a calendar for festivals.
/// They are legible but anonymous, and fourteen of them in a grid read as a
/// settings screen rather than as a way into the tradition.
///
/// These are drawn as vector paths rather than shipped as images, which is
/// deliberate. Bundled art would need a licence and a manifest row (the app's
/// placeholder art is already its top release blocker), it would need three
/// densities, and it could not take the tile's own colour. A path costs
/// nothing, stays crisp at any size, and inherits the gradient it sits on.
class GyanMotif extends StatelessWidget {
  final String moduleId;
  final Color color;
  final double size;

  /// Watermarks sit large and faint behind the tile; glyphs sit small and
  /// solid in the icon chip. Same path, two weights.
  final bool watermark;

  const GyanMotif({
    super.key,
    required this.moduleId,
    required this.color,
    this.size = 24,
    this.watermark = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MotifPainter(
            id: moduleId,
            color: color,
            watermark: watermark,
          ),
        ),
      );
}

class _MotifPainter extends CustomPainter {
  final String id;
  final Color color;
  final bool watermark;

  const _MotifPainter({
    required this.id,
    required this.color,
    required this.watermark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (watermark ? 0.045 : 0.075) * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;

    switch (id) {
      case 'journey':
        _journey(canvas, size, stroke, fill, r);
      case 'graph':
        _graph(canvas, c, r, stroke, fill);
      case 'lineage':
        _lineage(canvas, size, stroke, fill);
      case 'rishis':
        _rishi(canvas, c, r, stroke, fill);
      case 'astras':
        _astra(canvas, c, r, stroke, fill);
      case 'symbols':
        _lotus(canvas, c, r, stroke);
      case 'srishty':
        _cosmos(canvas, c, r, stroke, fill);
      case 'yuga':
        _wheel(canvas, c, r, stroke, fill);
      case 'ramayana':
        _bow(canvas, c, r, stroke, fill);
      case 'mahabharata':
        _chakra(canvas, c, r, stroke, fill);
      case 'vidya':
        _leaf(canvas, c, r, stroke);
      case 'dharma':
        _scales(canvas, c, r, stroke, fill);
      case 'festivals':
        _diya(canvas, c, r, stroke, fill);
      case 'ask':
        _conch(canvas, c, r, stroke);
      default:
        _lotus(canvas, c, r, stroke);
    }
  }

  /// A dashed path winding upward — the same motif the journey screens use.
  void _journey(Canvas canvas, Size s, Paint stroke, Paint fill, double r) {
    final p = Path()
      ..moveTo(s.width * 0.25, s.height * 0.88)
      ..cubicTo(s.width * 0.85, s.height * 0.72, s.width * 0.15,
          s.height * 0.48, s.width * 0.75, s.height * 0.14);
    _dashed(canvas, p, stroke);
    canvas.drawCircle(Offset(s.width * 0.75, s.height * 0.14), r * 0.13, fill);
  }

  /// A focus with orbiting nodes.
  void _graph(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * 0.68;
      canvas.drawLine(c, o, stroke);
      canvas.drawCircle(o, r * 0.13, fill);
    }
    canvas.drawCircle(c, r * 0.2, fill);
  }

  /// A descent bracket: one stem, a rail, three drops.
  void _lineage(Canvas canvas, Size s, Paint stroke, Paint fill) {
    final top = Offset(s.width / 2, s.height * 0.16);
    canvas.drawCircle(top, s.width * 0.1, fill);
    canvas.drawLine(top, Offset(s.width / 2, s.height * 0.45), stroke);
    canvas.drawLine(Offset(s.width * 0.18, s.height * 0.45),
        Offset(s.width * 0.82, s.height * 0.45), stroke);
    for (final x in [0.18, 0.5, 0.82]) {
      canvas.drawLine(Offset(s.width * x, s.height * 0.45),
          Offset(s.width * x, s.height * 0.7), stroke);
      canvas.drawCircle(Offset(s.width * x, s.height * 0.82), s.width * 0.09,
          fill);
    }
  }

  /// A seated figure: the sage.
  void _rishi(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawCircle(c.translate(0, -r * 0.45), r * 0.2, fill);
    final body = Path()
      ..moveTo(c.dx - r * 0.55, c.dy + r * 0.55)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.25, c.dx + r * 0.55,
          c.dy + r * 0.55);
    canvas.drawPath(body, stroke);
    canvas.drawLine(c.translate(-r * 0.62, r * 0.55),
        c.translate(r * 0.62, r * 0.55), stroke);
  }

  /// An arrow crossing a bow-curve.
  void _astra(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawLine(c.translate(-r * 0.62, r * 0.62),
        c.translate(r * 0.55, -r * 0.55), stroke);
    final head = Path()
      ..moveTo(c.dx + r * 0.72, c.dy - r * 0.72)
      ..lineTo(c.dx + r * 0.3, c.dy - r * 0.62)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.3)
      ..close();
    canvas.drawPath(head, fill);
    canvas.drawLine(c.translate(-r * 0.62, r * 0.2),
        c.translate(-r * 0.2, r * 0.62), stroke);
  }

  /// Eight petals.
  void _lotus(Canvas canvas, Offset c, double r, Paint stroke) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r * 0.82;
      final l = c + Offset(math.cos(a - 0.42), math.sin(a - 0.42)) * r * 0.34;
      final rr = c + Offset(math.cos(a + 0.42), math.sin(a + 0.42)) * r * 0.34;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..quadraticBezierTo(l.dx, l.dy, tip.dx, tip.dy)
            ..quadraticBezierTo(rr.dx, rr.dy, c.dx, c.dy),
          stroke);
    }
  }

  /// Concentric worlds inside a shell.
  void _cosmos(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawCircle(c, r * 0.9, stroke);
    canvas.drawCircle(c, r * 0.58, stroke);
    canvas.drawCircle(c, r * 0.16, fill);
    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r * 0.74, r * 0.08, fill);
    }
  }

  /// A quartered wheel — the four ages.
  void _wheel(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawCircle(c, r * 0.85, stroke);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * r * 0.85,
          stroke);
    }
    canvas.drawCircle(c, r * 0.14, fill);
  }

  /// A drawn bow.
  void _bow(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.8),
        -math.pi / 2.4, math.pi * 1.2, false, stroke);
    canvas.drawLine(c.translate(r * 0.34, -r * 0.72),
        c.translate(r * 0.34, r * 0.72), stroke);
    canvas.drawLine(c.translate(-r * 0.7, 0), c.translate(r * 0.34, 0), stroke);
    canvas.drawCircle(c.translate(-r * 0.7, 0), r * 0.1, fill);
  }

  /// A discus with a serrated rim.
  void _chakra(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawCircle(c, r * 0.82, stroke);
    canvas.drawCircle(c, r * 0.34, stroke);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * r * 0.34,
          c + Offset(math.cos(a), math.sin(a)) * r * 0.82, stroke);
    }
    canvas.drawCircle(c, r * 0.1, fill);
  }

  /// A leaf with a central vein.
  void _leaf(Canvas canvas, Offset c, double r, Paint stroke) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r * 0.85)
      ..quadraticBezierTo(c.dx + r * 0.9, c.dy, c.dx, c.dy + r * 0.85)
      ..quadraticBezierTo(c.dx - r * 0.9, c.dy, c.dx, c.dy - r * 0.85);
    canvas.drawPath(p, stroke);
    canvas.drawLine(c.translate(0, -r * 0.7), c.translate(0, r * 0.7), stroke);
  }

  /// A balance — two pans, no verdict.
  void _scales(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    canvas.drawLine(c.translate(0, -r * 0.8), c.translate(0, r * 0.7), stroke);
    canvas.drawLine(c.translate(-r * 0.78, -r * 0.45),
        c.translate(r * 0.78, -r * 0.45), stroke);
    for (final x in [-0.78, 0.78]) {
      canvas.drawArc(
          Rect.fromCircle(center: c.translate(r * x, -r * 0.12), radius: r * 0.3),
          0, math.pi, false, stroke);
    }
    canvas.drawCircle(c.translate(0, r * 0.72), r * 0.12, fill);
  }

  /// A lamp with a flame.
  void _diya(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final bowl = Path()
      ..moveTo(c.dx - r * 0.8, c.dy + r * 0.16)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.92, c.dx + r * 0.8,
          c.dy + r * 0.16)
      ..close();
    canvas.drawPath(bowl, stroke);
    final flame = Path()
      ..moveTo(c.dx, c.dy - r * 0.82)
      ..quadraticBezierTo(c.dx + r * 0.34, c.dy - r * 0.28, c.dx,
          c.dy + r * 0.08)
      ..quadraticBezierTo(c.dx - r * 0.34, c.dy - r * 0.28, c.dx,
          c.dy - r * 0.82);
    canvas.drawPath(flame, fill);
  }

  /// A spiral shell — the conch that opens a question.
  void _conch(Canvas canvas, Offset c, double r, Paint stroke) {
    final p = Path();
    for (var t = 0.0; t < math.pi * 4; t += 0.12) {
      final rad = r * 0.1 + r * 0.085 * t;
      final o = c + Offset(math.cos(t), math.sin(t)) * rad;
      if (t == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(p, stroke);
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + 5.5, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + 4.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.id != id || old.color != color || old.watermark != watermark;
}
