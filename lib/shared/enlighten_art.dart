import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

/// Original vector illustrations for the Home "Spiritual Enlightenment" cards,
/// drawn with CustomPaint (no image assets) — the same approach as the app
/// logo and rashi glyphs, so they stay crisp and are our own artwork (not the
/// reference app's). Sized to fill the card's art slot.

/// Mantras — a seated figure in dhyana with Om (ॐ) syllables rising.
class MeditationArt extends StatelessWidget {
  const MeditationArt({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _MeditationPainter());
}

/// Aartis — an evening aarti on the river ghat: temple, steps and a lit diya.
class GhatArt extends StatelessWidget {
  const GhatArt({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _GhatPainter());
}

class _MeditationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Warm cream backdrop.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCEFD9), Color(0xFFF5E1C2)],
        ).createShader(rect),
    );

    final cx = w * 0.40;
    final baseY = h * 0.88;

    // Soft sun halo behind the figure.
    canvas.drawCircle(Offset(cx, h * 0.52), h * 0.36,
        Paint()..color = const Color(0xFFF0CE82).withValues(alpha: 0.45));

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, baseY + 2), width: w * 0.44, height: h * 0.10),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );

    // Folded legs / dhoti — a low rounded band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, baseY - h * 0.05),
            width: w * 0.42,
            height: h * 0.17),
        Radius.circular(h * 0.09),
      ),
      Paint()..color = const Color(0xFFF3E7CF),
    );

    // Robe / torso.
    final robe = Paint()..color = const Color(0xFFB4471F);
    final tX = w * 0.16;
    final torso = Path()
      ..moveTo(cx - tX, baseY - h * 0.10)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.42, cx - w * 0.055, h * 0.38)
      ..lineTo(cx + w * 0.055, h * 0.38)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.42, cx + tX, baseY - h * 0.10)
      ..close();
    canvas.drawPath(torso, robe);

    // Hands resting on the knees.
    canvas.drawCircle(Offset(cx - tX * 0.88, baseY - h * 0.13), h * 0.05, robe);
    canvas.drawCircle(Offset(cx + tX * 0.88, baseY - h * 0.13), h * 0.05, robe);

    // Head + hair.
    final headC = Offset(cx, h * 0.31);
    final r = h * 0.115;
    canvas.drawCircle(headC, r, Paint()..color = const Color(0xFFE7B48A));
    final hair = Path()
      ..moveTo(headC.dx - r, headC.dy - r * 0.15)
      ..arcToPoint(Offset(headC.dx + r, headC.dy - r * 0.15),
          radius: Radius.circular(r), clockwise: true)
      ..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xFF3A2A20));

    // Om syllables rising to the upper-right.
    _om(canvas, Offset(cx + w * 0.30, h * 0.44), h * 0.22,
        const Color(0xFFB4471F).withValues(alpha: 0.92));
    _om(canvas, Offset(cx + w * 0.39, h * 0.26), h * 0.16,
        const Color(0xFFC79200).withValues(alpha: 0.85));
    _om(canvas, Offset(cx + w * 0.46, h * 0.13), h * 0.11,
        const Color(0xFFC79200).withValues(alpha: 0.55));
  }

  void _om(Canvas canvas, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'ॐ',
        style: TextStyle(
          fontFamily: AppFonts.devanagari,
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MeditationPainter oldDelegate) => false;
}

class _GhatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Evening sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9CFEA), Color(0xFFE2C6C8)],
        ).createShader(rect),
    );

    final waterTop = h * 0.64;

    // Temple shikhara on the right (drawn before water so its base is hidden).
    final tx = w * 0.80;
    final temple = Path()
      ..moveTo(tx - w * 0.11, waterTop)
      ..lineTo(tx - w * 0.055, h * 0.22)
      ..lineTo(tx, h * 0.10)
      ..lineTo(tx + w * 0.055, h * 0.22)
      ..lineTo(tx + w * 0.11, waterTop)
      ..close();
    canvas.drawPath(temple, Paint()..color = const Color(0xFFA84A28));
    canvas.drawCircle(
        Offset(tx, h * 0.08), h * 0.022, Paint()..color = const Color(0xFFC79200));

    // Ghat steps on the left — a few ascending terracotta bands.
    for (var i = 0; i < 3; i++) {
      final sy = waterTop - (i + 1) * h * 0.10;
      canvas.drawRect(
        Rect.fromLTWH(0, sy, w * (0.56 - i * 0.13), h * 0.10),
        Paint()
          ..color = Color.lerp(
              const Color(0xFFCF9566), const Color(0xFFA9683B), i / 2)!,
      );
    }

    // River.
    canvas.drawRect(Rect.fromLTWH(0, waterTop, w, h - waterTop),
        Paint()..color = const Color(0xFF6E90B8));
    final refl = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.10, waterTop + h * 0.12),
        Offset(w * 0.32, waterTop + h * 0.12), refl);
    canvas.drawLine(Offset(w * 0.52, waterTop + h * 0.22),
        Offset(w * 0.74, waterTop + h * 0.22), refl);

    // A worshipper on the steps holding a diya.
    final fx = w * 0.32, fy = waterTop - h * 0.11;
    final robe = Path()
      ..moveTo(fx - w * 0.055, fy)
      ..quadraticBezierTo(fx, fy - h * 0.20, fx + w * 0.055, fy)
      ..close();
    canvas.drawPath(robe, Paint()..color = const Color(0xFFE68A2E));
    canvas.drawCircle(Offset(fx, fy - h * 0.20), h * 0.05,
        Paint()..color = const Color(0xFF7A4A2A));

    // Diya glow + flame in the worshipper's hands.
    final flame = Offset(fx + w * 0.10, fy - h * 0.07);
    canvas.drawCircle(flame, h * 0.11,
        Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.55));
    canvas.drawCircle(
        flame, h * 0.045, Paint()..color = const Color(0xFFF3852A));
    canvas.drawCircle(Offset(flame.dx, flame.dy - h * 0.015), h * 0.022,
        Paint()..color = const Color(0xFFFFE08A));
  }

  @override
  bool shouldRepaint(_GhatPainter oldDelegate) => false;
}
