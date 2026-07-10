import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'stitched_border.dart';

/// The Aradhya logo — a lotus in terracotta + gold on a warm cream tile with
/// the signature dashed "stitched" outline. Drawn (not an asset) so it stays
/// crisp at every size.
class AppLogo extends StatelessWidget {
  final double size;

  /// When false, draws just the lotus with no tile/border (for overlays).
  final bool tile;

  /// 0 = a closed bud, 1 = fully bloomed. Drive this to animate the bloom.
  final double bloom;

  const AppLogo(
      {super.key, this.size = 96, this.tile = true, this.bloom = 1});

  @override
  Widget build(BuildContext context) {
    final lotus = CustomPaint(
      size: Size.square(size),
      painter: _LotusPainter(bloom: bloom),
    );
    if (!tile) return SizedBox.square(dimension: size, child: lotus);

    final radius = size * 0.26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.kraft2,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracotta.withValues(alpha: 0.22),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: StitchedBorderPainter(
          color: AppColors.terracotta.withValues(alpha: 0.38),
          inset: size * 0.11,
          radius: radius * 0.62,
          strokeWidth: size * 0.014,
          dash: size * 0.055,
          gap: size * 0.04,
        ),
        child: lotus,
      ),
    );
  }
}

/// Paints the lotus mark on a 512-unit design grid, scaled to the canvas.
/// [bloom] runs 0 (a closed bud) → 1 (fully open): petals rotate out from the
/// centre and lengthen, and the gold base cradle grows in near the end.
class _LotusPainter extends CustomPainter {
  final double bloom;
  _LotusPainter({this.bloom = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    final cx = 256 * s;
    final cy = 300 * s;

    final t = bloom.clamp(0.0, 1.0);
    // "Bloom + Pop": petals overshoot their target angle, then settle.
    final open = Curves.easeOutBack.transform(t); // petals fan out with a pop
    final grow = Curves.easeOut.transform(t); // petals lengthen
    double lenF(double full) => full * (0.58 + 0.42 * grow);
    double widF(double full) => full * (0.80 + 0.20 * grow);

    Paint fill(List<Color> colors) => Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gold = fill([const Color(0xFFEFCB6A), const Color(0xFFB48B3E)]);
    final terra = fill([const Color(0xFFB23A18), AppColors.terracottaDark]);
    final terraCore =
        fill([const Color(0xFF9A2E12), const Color(0xFF6E1F10)]);

    void petal(double targetDeg, double length, double width, Paint paint) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(targetDeg * open * math.pi / 180);
      final l = lenF(length) * s, w = widF(width) * s;
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(-w, -l * 0.55, -w * 0.4, -l, 0, -l)
        ..cubicTo(w * 0.4, -l, w, -l * 0.55, 0, 0)
        ..close();
      canvas.drawPath(p, paint);
      canvas.restore();
    }

    // Gold back petals (fanned wide)
    for (final a in const [-66.0, -33.0, 0.0, 33.0, 66.0]) {
      petal(a, 194, 82, gold);
    }
    // Terracotta front petals
    for (final a in const [-42.0, -14.0, 14.0, 42.0]) {
      petal(a, 178, 70, terra);
    }
    // Center petal
    petal(0, 196, 58, terraCore);

    // Gold base cradle — grows in as the flower opens.
    final baseT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
    if (baseT > 0) {
      final bw = 150 * s * baseT;
      final base = Path()
        ..moveTo(cx - bw, cy + 6 * s)
        ..quadraticBezierTo(cx, cy + 70 * s, cx + bw, cy + 6 * s)
        ..quadraticBezierTo(cx, cy + 34 * s, cx - bw, cy + 6 * s)
        ..close();
      canvas.drawPath(
          base,
          Paint()
            ..isAntiAlias = true
            ..color = const Color(0xFFC7A24E).withValues(alpha: baseT));
    }
  }

  @override
  bool shouldRepaint(_LotusPainter old) => old.bloom != bloom;
}

/// The horizontal wordmark: two-tone "Ara·dhya" in the display serif.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  const AppWordmark({super.key, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        children: [
          TextSpan(text: 'Ara', style: TextStyle(color: scheme.onSurface)),
          TextSpan(text: 'dhya', style: TextStyle(color: scheme.primary)),
        ],
      ),
    );
  }
}
