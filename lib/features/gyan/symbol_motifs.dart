import 'dart:math' as math;

import 'package:flutter/material.dart';

/// SB-02: a drawn motif for the symbol entities Unicode has no glyph for.
///
/// `entity.glyph` already covers five of the twelve symbols with a real
/// character (卐 for swastika would exist, but is avoided as a live symbol
/// widely read as something else in the modern west; ॐ, 🪔, and the two
/// dingbat marks for chakra/yantra are the ones that do have one). The other
/// seven -- Damaru, Kalash, Padma, Rudraksha, Shankha, Swastika, Tilaka --
/// fell back to a generic sparkle icon, which is the exact "anonymous mark"
/// problem `gyan_motifs.dart` already solved for the module tiles. This is
/// that same fix for the individual symbol entities: same vector-path
/// approach (crisp at any size, inherits the caller's colour, no asset/
/// licence/manifest row), keyed by symbol slug instead of module id.
///
/// Returns null for any slug not covered here, so a caller can fall back to
/// its own default (an icon, or nothing) rather than silently drawing blank.
class SymbolMotif extends StatelessWidget {
  final String slug;
  final Color color;
  final double size;

  const SymbolMotif({
    super.key,
    required this.slug,
    required this.color,
    this.size = 46,
  });

  /// The slugs this widget actually knows how to draw.
  static const covered = {
    'damaru',
    'kalash',
    'padma',
    'rudraksha',
    'shankha',
    'swastika',
    'tilaka',
  };

  @override
  Widget build(BuildContext context) {
    if (!covered.contains(slug)) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SymbolPainter(slug: slug, color: color)),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  final String slug;
  final Color color;
  const _SymbolPainter({required this.slug, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.075 * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;

    switch (slug) {
      case 'damaru':
        _damaru(canvas, c, r, stroke, fill);
      case 'kalash':
        _kalash(canvas, c, r, stroke, fill);
      case 'padma':
        _padma(canvas, c, r, stroke);
      case 'rudraksha':
        _rudraksha(canvas, c, r, stroke, fill);
      case 'shankha':
        _shankha(canvas, c, r, stroke);
      case 'swastika':
        _swastika(canvas, c, r, stroke);
      case 'tilaka':
        _tilaka(canvas, c, r, fill);
    }
  }

  /// Two cones joined at a waist, laced top and bottom — Shiva's hourglass drum.
  void _damaru(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final top = Path()
      ..moveTo(c.dx - r * 0.62, c.dy - r * 0.78)
      ..lineTo(c.dx - r * 0.14, c.dy - r * 0.06)
      ..lineTo(c.dx - r * 0.62, c.dy + r * 0.06)
      ..moveTo(c.dx - r * 0.62, c.dy - r * 0.78)
      ..quadraticBezierTo(
          c.dx - r * 0.9, c.dy - r * 0.36, c.dx - r * 0.62, c.dy + r * 0.06);
    canvas.drawPath(top, stroke);
    final bottom = Path()
      ..moveTo(c.dx + r * 0.62, c.dy + r * 0.78)
      ..lineTo(c.dx + r * 0.14, c.dy + r * 0.06)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.06)
      ..moveTo(c.dx + r * 0.62, c.dy + r * 0.78)
      ..quadraticBezierTo(
          c.dx + r * 0.9, c.dy + r * 0.36, c.dx + r * 0.62, c.dy - r * 0.06);
    canvas.drawPath(bottom, stroke);
    // The waist where the two cones meet, and the cord.
    canvas.drawCircle(c, r * 0.1, fill);
  }

  /// A rounded pot with a narrow neck and a spray of leaves — the Amrita
  /// vessel Dhanvantari carries, per Wilson's Vishnu Purana Book I Ch. IX.
  void _kalash(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final body = Path()
      ..moveTo(c.dx - r * 0.1, c.dy - r * 0.15)
      ..lineTo(c.dx - r * 0.1, c.dy - r * 0.4)
      ..lineTo(c.dx - r * 0.34, c.dy - r * 0.5)
      ..moveTo(c.dx + r * 0.1, c.dy - r * 0.15)
      ..lineTo(c.dx + r * 0.1, c.dy - r * 0.4)
      ..lineTo(c.dx + r * 0.34, c.dy - r * 0.5);
    canvas.drawPath(body, stroke); // the neck and a leaf-spray either side
    canvas.drawLine(c.translate(-r * 0.22, -r * 0.15),
        c.translate(r * 0.22, -r * 0.15), stroke); // the mouth rim
    final pot = Path()
      ..moveTo(c.dx - r * 0.22, c.dy - r * 0.15)
      ..lineTo(c.dx - r * 0.62, c.dy + r * 0.1)
      ..quadraticBezierTo(
          c.dx - r * 0.7, c.dy + r * 0.72, c.dx, c.dy + r * 0.78)
      ..quadraticBezierTo(
          c.dx + r * 0.7, c.dy + r * 0.72, c.dx + r * 0.62, c.dy + r * 0.1)
      ..lineTo(c.dx + r * 0.22, c.dy - r * 0.15)
      ..close();
    canvas.drawPath(pot, stroke);
  }

  /// Eight open petals, the same construction as `gyan_motifs.dart`'s
  /// module-tile lotus but drawn solo, without the module's surrounding
  /// chrome — Padma stands alone here rather than representing "symbols" as
  /// a category.
  void _padma(Canvas canvas, Offset c, double r, Paint stroke) {
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r * 0.85;
      final l = c + Offset(math.cos(a - 0.4), math.sin(a - 0.4)) * r * 0.32;
      final rr = c + Offset(math.cos(a + 0.4), math.sin(a + 0.4)) * r * 0.32;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..quadraticBezierTo(l.dx, l.dy, tip.dx, tip.dy)
            ..quadraticBezierTo(rr.dx, rr.dy, c.dx, c.dy),
          stroke);
    }
  }

  /// A japa strand: beads on a thread, looping at the bottom the way a mala
  /// actually hangs, one larger bead standing in for the meru/head bead.
  void _rudraksha(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    const n = 9;
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final a = math.pi * 0.12 + t * math.pi * 0.76;
      final o = c + Offset(math.cos(a), -math.sin(a)) * r * 0.8;
      canvas.drawCircle(o, i == n ~/ 2 ? r * 0.15 : r * 0.11, fill);
    }
    final p = Path();
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final a = math.pi * 0.12 + t * math.pi * 0.76;
      final o = c + Offset(math.cos(a), -math.sin(a)) * r * 0.8;
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(p, stroke..strokeWidth = stroke.strokeWidth * 0.4);
  }

  /// A right-spiralling conch shell, drawn as a growing spiral with a flared
  /// mouth — Vishnu's Panchajanya.
  void _shankha(Canvas canvas, Offset c, double r, Paint stroke) {
    final p = Path();
    for (var t = 0.0; t < math.pi * 3.4; t += 0.12) {
      final rad = r * 0.06 + r * 0.11 * t;
      final o = c + Offset(math.cos(t), math.sin(t)) * rad
        ..translate(0, -r * 0.1);
      if (t == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(p, stroke);
  }

  /// The four-armed hooked cross, each arm turning the same way — deliberately
  /// distinct from the swastika-as-hate-symbol silhouette by keeping proper
  /// proportion (a square core, short arms) rather than the elongated,
  /// tilted rendering that reading carries.
  void _swastika(Canvas canvas, Offset c, double r, Paint stroke) {
    final arm = r * 0.55;
    final hook = r * 0.32;
    canvas.drawLine(
        c.translate(0, -arm), c.translate(0, arm), stroke); // vertical spine
    canvas.drawLine(c.translate(-arm, 0), c.translate(arm, 0),
        stroke); // horizontal spine
    canvas.drawLine(
        c.translate(0, -arm), c.translate(hook, -arm), stroke); // top hook
    canvas.drawLine(
        c.translate(0, arm), c.translate(-hook, arm), stroke); // bottom hook
    canvas.drawLine(
        c.translate(-arm, 0), c.translate(-arm, -hook), stroke); // left hook
    canvas.drawLine(
        c.translate(arm, 0), c.translate(arm, hook), stroke); // right hook
  }

  /// A vertical U with a central line — the Vaishnava tilaka. (Sect marks
  /// vary; this is the one form the corpus's own props describe. The
  /// Shaiva tripundra, three horizontal lines, is the other common form and
  /// is not drawn here since no entity in this corpus currently specifies
  /// it -- adding it without a specific citable subject would be guessing
  /// at which reading to show.)
  void _tilaka(Canvas canvas, Offset c, double r, Paint fill) {
    final u = Path()
      ..moveTo(c.dx - r * 0.5, c.dy - r * 0.7)
      ..quadraticBezierTo(
          c.dx - r * 0.5, c.dy + r * 0.7, c.dx, c.dy + r * 0.85)
      ..quadraticBezierTo(
          c.dx + r * 0.5, c.dy + r * 0.7, c.dx + r * 0.5, c.dy - r * 0.7)
      ..lineTo(c.dx + r * 0.32, c.dy - r * 0.7)
      ..quadraticBezierTo(
          c.dx + r * 0.32, c.dy + r * 0.4, c.dx, c.dy + r * 0.5)
      ..quadraticBezierTo(
          c.dx - r * 0.32, c.dy + r * 0.4, c.dx - r * 0.32, c.dy - r * 0.7)
      ..close();
    canvas.drawPath(u, fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c.translate(0, -r * 0.1), width: r * 0.22, height: r * 1.3),
            Radius.circular(r * 0.1)),
        fill);
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter old) =>
      old.slug != slug || old.color != color;
}
