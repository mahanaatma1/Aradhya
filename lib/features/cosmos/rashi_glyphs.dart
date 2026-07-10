import 'package:flutter/material.dart';

/// The 12 rashi (zodiac) glyphs, built from the same materials as the app
/// logo and the Kamal/Punya marks — a **solid two-tone emblem**: a terracotta
/// face laid over a gold underlay, exactly the terracotta-over-gold layering of
/// the lotus. Not a hairline. Drawn with CustomPaint, so it stays crisp at any
/// size, theme-aware, with no image assets and no emoji.
/// [index] 0 = Aries … 11 = Pisces.
class RashiGlyph extends StatelessWidget {
  final int index;
  final double size;
  const RashiGlyph({super.key, required this.index, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _RashiPainter(index, dark: dark),
    );
  }
}

class _RashiPainter extends CustomPainter {
  final int i;
  final bool dark;
  _RashiPainter(this.i, {required this.dark});

  // Gold underlay (wide) + terracotta face (narrow) — the logo's two tones.
  static const _goldLight = [Color(0xFFDFC488), Color(0xFFA9822F)];
  static const _goldDark = [Color(0xFFCBAE72), Color(0xFF8C6C36)];
  static const _terraLight = [Color(0xFFC0451F), Color(0xFF7E230F)];
  static const _terraDark = [Color(0xFFE86A44), Color(0xFFB23A18)];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    Shader grad(List<Color> c) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c,
        ).createShader(rect);

    final goldShader = grad(dark ? _goldDark : _goldLight);
    final terraShader = grad(dark ? _terraDark : _terraLight);

    Paint strokePaint(Shader shader, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..shader = shader
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    Paint fillPaint(Shader shader) => Paint()
      ..style = PaintingStyle.fill
      ..shader = shader
      ..isAntiAlias = true;

    final goldStroke = strokePaint(goldShader, 4.6);
    final terraStroke = strokePaint(terraShader, 2.6);
    final goldFill = fillPaint(goldShader);
    final terraFill = fillPaint(terraShader);

    Offset o(double x, double y) => Offset(x * s, y * s);

    // Extra primitives some signs need (drawn in both tones for the enamel).
    void extras(Paint stroke, Paint fill) {
      switch (i) {
        case 1: // Taurus — the bull's face ring
          canvas.drawCircle(o(12, 16), 4.7 * s, stroke);
          break;
        case 3: // Cancer — the two seeds
          canvas.drawCircle(o(14.4, 10.2), 1.9 * s, fill);
          canvas.drawCircle(o(9.6, 13.8), 1.9 * s, fill);
          break;
        case 4: // Leo — the lion's head
          canvas.drawCircle(o(8, 16), 3 * s, stroke);
          break;
      }
    }

    final p = _signPath(s);

    // Underlay first (gold, wide), then the face (terracotta, narrow).
    extras(goldStroke, goldFill);
    canvas.drawPath(p, goldStroke);
    extras(terraStroke, terraFill);
    canvas.drawPath(p, terraStroke);
  }

  Path _signPath(double s) {
    final p = Path();
    switch (i) {
      case 0: // Aries — the ram
        p.moveTo(12 * s, 21 * s);
        p.lineTo(12 * s, 10.5 * s);
        p.moveTo(12 * s, 11 * s);
        p.cubicTo(11.5 * s, 5.5 * s, 5.5 * s, 5 * s, 5 * s, 9.5 * s);
        p.cubicTo(4.7 * s, 12.5 * s, 8.2 * s, 12.5 * s, 8 * s, 9.8 * s);
        p.moveTo(12 * s, 11 * s);
        p.cubicTo(12.5 * s, 5.5 * s, 18.5 * s, 5 * s, 19 * s, 9.5 * s);
        p.cubicTo(19.3 * s, 12.5 * s, 15.8 * s, 12.5 * s, 16 * s, 9.8 * s);
        break;
      case 1: // Taurus — the bull (ring drawn in extras)
        p.moveTo(5.5 * s, 6 * s);
        p.quadraticBezierTo(12 * s, 12.5 * s, 18.5 * s, 6 * s);
        break;
      case 2: // Gemini — the twins
        p.moveTo(7 * s, 5.5 * s);
        p.quadraticBezierTo(12 * s, 3.8 * s, 17 * s, 5.5 * s);
        p.moveTo(7 * s, 18.5 * s);
        p.quadraticBezierTo(12 * s, 20.2 * s, 17 * s, 18.5 * s);
        p.moveTo(9.3 * s, 5 * s);
        p.lineTo(9.3 * s, 19 * s);
        p.moveTo(14.7 * s, 5 * s);
        p.lineTo(14.7 * s, 19 * s);
        break;
      case 3: // Cancer — 69 (seeds drawn in extras)
        p.moveTo(5.5 * s, 11 * s);
        p.cubicTo(5.5 * s, 7.3 * s, 11.5 * s, 7 * s, 13.8 * s, 9.6 * s);
        p.moveTo(18.5 * s, 13 * s);
        p.cubicTo(18.5 * s, 16.7 * s, 12.5 * s, 17 * s, 10.2 * s, 14.4 * s);
        break;
      case 4: // Leo — the lion (head drawn in extras)
        p.moveTo(10.4 * s, 15.6 * s);
        p.cubicTo(15.5 * s, 15 * s, 17 * s, 9.3 * s, 13 * s, 7.8 * s);
        p.cubicTo(10 * s, 6.7 * s, 9.4 * s, 10 * s, 12.6 * s, 10.7 * s);
        break;
      case 5: // Virgo — M with an inward loop
        p.moveTo(5.5 * s, 19 * s);
        p.lineTo(5.5 * s, 9 * s);
        p.quadraticBezierTo(5.5 * s, 7 * s, 7.5 * s, 7 * s);
        p.quadraticBezierTo(9.5 * s, 7 * s, 9.5 * s, 9 * s);
        p.lineTo(9.5 * s, 19 * s);
        p.moveTo(9.5 * s, 9 * s);
        p.quadraticBezierTo(9.5 * s, 7 * s, 11.5 * s, 7 * s);
        p.quadraticBezierTo(13.5 * s, 7 * s, 13.5 * s, 9 * s);
        p.lineTo(13.5 * s, 15.5 * s);
        p.cubicTo(13.5 * s, 19.5 * s, 18 * s, 18.5 * s, 17 * s, 14 * s);
        p.cubicTo(16.2 * s, 10.8 * s, 12 * s, 12 * s, 13.2 * s, 16 * s);
        break;
      case 6: // Libra — the scales
        p.moveTo(5 * s, 18.5 * s);
        p.lineTo(19 * s, 18.5 * s);
        p.moveTo(6.5 * s, 13.6 * s);
        p.lineTo(9.6 * s, 13.6 * s);
        p.quadraticBezierTo(12 * s, 8 * s, 14.4 * s, 13.6 * s);
        p.lineTo(17.5 * s, 13.6 * s);
        break;
      case 7: // Scorpio — M with a stinger
        p.moveTo(5 * s, 18 * s);
        p.lineTo(5 * s, 9 * s);
        p.quadraticBezierTo(5 * s, 7 * s, 7 * s, 7 * s);
        p.quadraticBezierTo(9 * s, 7 * s, 9 * s, 9 * s);
        p.lineTo(9 * s, 18 * s);
        p.moveTo(9 * s, 9 * s);
        p.quadraticBezierTo(9 * s, 7 * s, 11 * s, 7 * s);
        p.quadraticBezierTo(13 * s, 7 * s, 13 * s, 9 * s);
        p.lineTo(13 * s, 18 * s);
        p.lineTo(18.5 * s, 18 * s);
        p.moveTo(18.5 * s, 18 * s);
        p.lineTo(16 * s, 15.8 * s);
        p.moveTo(18.5 * s, 18 * s);
        p.lineTo(16.2 * s, 20.4 * s);
        break;
      case 8: // Sagittarius — the archer's arrow
        p.moveTo(5.5 * s, 18.5 * s);
        p.lineTo(18 * s, 6 * s);
        p.moveTo(18 * s, 6 * s);
        p.lineTo(12 * s, 6.4 * s);
        p.moveTo(18 * s, 6 * s);
        p.lineTo(17.6 * s, 12 * s);
        p.moveTo(9 * s, 10.5 * s);
        p.lineTo(13.5 * s, 15 * s);
        break;
      case 9: // Capricorn — the sea-goat
        p.moveTo(4.5 * s, 7.5 * s);
        p.cubicTo(6 * s, 6.3 * s, 8.2 * s, 8 * s, 8.7 * s, 11 * s);
        p.cubicTo(9.2 * s, 13.6 * s, 11 * s, 14 * s, 12 * s, 11.5 * s);
        p.cubicTo(13 * s, 9 * s, 15 * s, 9.4 * s, 15.5 * s, 12 * s);
        p.cubicTo(19 * s, 11.8 * s, 19 * s, 18 * s, 14.4 * s, 17 * s);
        p.cubicTo(11.4 * s, 16.3 * s, 13 * s, 12.6 * s, 16 * s, 13.7 * s);
        break;
      case 10: // Aquarius — the water-bearer (two waves)
        for (final dy in [0.0, 4.6]) {
          p.moveTo(4.5 * s, (10 + dy) * s);
          p.cubicTo(6 * s, (7.6 + dy) * s, 8 * s, (7.6 + dy) * s,
              9.5 * s, (10 + dy) * s);
          p.cubicTo(11 * s, (12.4 + dy) * s, 13 * s, (12.4 + dy) * s,
              14.5 * s, (10 + dy) * s);
          p.cubicTo(16 * s, (7.6 + dy) * s, 18 * s, (7.6 + dy) * s,
              19.5 * s, (10 + dy) * s);
        }
        break;
      case 11: // Pisces — the two fishes
        p.moveTo(9 * s, 4 * s);
        p.cubicTo(4 * s, 8 * s, 4 * s, 16 * s, 9 * s, 20 * s);
        p.moveTo(15 * s, 4 * s);
        p.cubicTo(20 * s, 8 * s, 20 * s, 16 * s, 15 * s, 20 * s);
        p.moveTo(6 * s, 12 * s);
        p.lineTo(18 * s, 12 * s);
        break;
    }
    return p;
  }

  @override
  bool shouldRepaint(_RashiPainter old) => old.i != i || old.dark != dark;
}
