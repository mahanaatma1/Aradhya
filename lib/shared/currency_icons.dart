import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Vector icon for **Kamal** (कमल) — the spendable currency, drawn as a lotus.
class KamalIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const KamalIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _KamalPainter(color ?? AppColors.deityRose),
      );
}

class _KamalPainter extends CustomPainter {
  final Color color;
  _KamalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final cx = 12 * s;
    final base = 20 * s;
    final light = Color.lerp(color, Colors.white, 0.35)!;
    final dark = Color.lerp(color, Colors.black, 0.2)!;

    Paint fill(Color c) => Paint()
      ..isAntiAlias = true
      ..color = c;

    void petal(double deg, double len, double wid, Color c) {
      canvas.save();
      canvas.translate(cx, base);
      canvas.rotate(deg * math.pi / 180);
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(-wid, -len * 0.55, -wid * 0.35, -len, 0, -len)
        ..cubicTo(wid * 0.35, -len, wid, -len * 0.55, 0, 0)
        ..close();
      canvas.drawPath(p, fill(c));
      canvas.restore();
    }

    // Back petals (lighter), then front petals, then centre.
    for (final a in const [-58.0, 58.0]) {
      petal(a, 13 * s, 5 * s, light);
    }
    for (final a in const [-30.0, 30.0]) {
      petal(a, 15 * s, 5 * s, color);
    }
    petal(0, 16 * s, 4.5 * s, dark);

    // Little gold cradle at the base.
    final cradle = Path()
      ..moveTo(cx - 6 * s, base + 0.5 * s)
      ..quadraticBezierTo(cx, base + 4 * s, cx + 6 * s, base + 0.5 * s)
      ..quadraticBezierTo(cx, base + 2 * s, cx - 6 * s, base + 0.5 * s)
      ..close();
    canvas.drawPath(cradle, fill(AppColors.gold));
  }

  @override
  bool shouldRepaint(_KamalPainter old) => old.color != color;
}

/// Vector icon for **Punya** (पुण्य) — lifetime merit, drawn as a lit diya.
class PunyaIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const PunyaIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _PunyaPainter(color ?? AppColors.gold),
      );
}

class _PunyaPainter extends CustomPainter {
  final Color color;
  _PunyaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final cx = 12 * s;

    Paint fill(Color c) => Paint()
      ..isAntiAlias = true
      ..color = c;

    // Flame — a teardrop with a lighter inner core.
    final flame = Path()
      ..moveTo(cx, 3 * s)
      ..cubicTo(cx + 5 * s, 8 * s, cx + 4 * s, 13 * s, cx, 13.5 * s)
      ..cubicTo(cx - 4 * s, 13 * s, cx - 5 * s, 8 * s, cx, 3 * s)
      ..close();
    canvas.drawPath(flame, fill(const Color(0xFFE8802A)));
    final core = Path()
      ..moveTo(cx, 6 * s)
      ..cubicTo(cx + 2.6 * s, 9 * s, cx + 2 * s, 12 * s, cx, 12.6 * s)
      ..cubicTo(cx - 2.6 * s, 12 * s, cx - 2.2 * s, 9 * s, cx, 6 * s)
      ..close();
    canvas.drawPath(core, fill(const Color(0xFFF6C445)));

    // Diya bowl — a warm clay crescent.
    final bowl = Path()
      ..moveTo(3 * s, 15 * s)
      ..quadraticBezierTo(cx, 23 * s, 21 * s, 15 * s)
      ..quadraticBezierTo(cx, 18 * s, 3 * s, 15 * s)
      ..close();
    canvas.drawPath(bowl, fill(color));
    // Rim highlight.
    canvas.drawPath(
      Path()
        ..moveTo(3 * s, 15 * s)
        ..quadraticBezierTo(cx, 18 * s, 21 * s, 15 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s
        ..color = Color.lerp(color, Colors.white, 0.4)!,
    );
  }

  @override
  bool shouldRepaint(_PunyaPainter old) => old.color != color;
}
