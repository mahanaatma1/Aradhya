import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'temple_models.dart';

/// Which drawn silhouette a temple gets, inferred from its own architecture
/// note and category tags — the same two fields [templeTint] and
/// [tagChipColor] already read, so this needed no new content-pipeline column.
///
/// The 187 bundled temples cluster into a handful of real architectural
/// families (Dravidian gopuram, Nagara shikhara, Kerala sloped roof, Kalinga,
/// Himalayan, cave/rock-cut, modern, pagoda) — this draws each family once, as
/// a vector, rather than needing a licensed photo per temple. Every family
/// reads as visibly different silhouette, not a recolored copy of the same
/// icon, which is what the old `Icons.temple_hindu_rounded` watermark gave
/// all 187 cards regardless of what kind of temple they were.
enum TempleArchetype {
  dravidian, // tiered gopuram — South Indian
  nagara, // curved shikhara — North Indian
  kerala, // sloped tiled/copper roofs
  kalinga, // Odisha's curved deul + mandapa
  himalayan, // stone/wood hill shrine, snow-capped backdrop
  cave, // rock-cut sanctum
  pagoda, // tiered pagoda roofline
  modern; // contemporary marble/dome complex

  static TempleArchetype of(Temple t) {
    final arch = (t.architectureEn ?? '').toLowerCase();
    final tags = t.tags.map((e) => e.toLowerCase()).toList();
    bool has(String s) => arch.contains(s) || tags.any((x) => x.contains(s));

    if (has('cave') || has('rock-cut') || has('rock_cut')) return cave;
    if (has('pagoda')) return pagoda;
    if (has('himalayan') || has('pahari') || has('hill_temple')) {
      return himalayan;
    }
    if (has('kerala') || has('wooden')) return kerala;
    if (has('kalinga')) return kalinga;
    if (has('modern')) return modern;
    if (has('dravidian') || has('gopuram')) return dravidian;
    if (has('nagara') || has('shikhara')) return nagara;
    // Fall back on the same id rotation the old flat tint used, so an
    // unclassified temple still gets *a* distinct, stable silhouette rather
    // than always the same default.
    const fallback = [dravidian, nagara, kerala, kalinga, himalayan];
    return fallback[t.id % fallback.length];
  }
}

/// A drawn temple silhouette for [archetype], filled with [colors] as a dusk
/// gradient (sky) behind an ink silhouette (the structure) — no photography,
/// same hand-drawn-vector approach as [GyanMotif].
class TempleIllustration extends StatelessWidget {
  final TempleArchetype archetype;
  final List<Color> colors;
  const TempleIllustration(
      {super.key, required this.archetype, required this.colors});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TemplePainter(archetype: archetype, colors: colors),
      child: const SizedBox.expand(),
    );
  }
}

class _TemplePainter extends CustomPainter {
  final TempleArchetype archetype;
  final List<Color> colors;
  const _TemplePainter({required this.archetype, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // A soft disc — sun/moon — behind every archetype, positioned high and
    // off-centre so the silhouette in front always reads against it.
    final disc = Paint()..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(Offset(w * 0.78, h * 0.28), w * 0.16, disc);

    final ink = Paint()..color = Colors.black.withValues(alpha: 0.34);
    final inkLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.006)
      ..color = Colors.black.withValues(alpha: 0.22);

    switch (archetype) {
      case TempleArchetype.dravidian:
        _dravidian(canvas, w, h, ink, inkLine);
      case TempleArchetype.nagara:
        _nagara(canvas, w, h, ink, inkLine);
      case TempleArchetype.kerala:
        _kerala(canvas, w, h, ink, inkLine);
      case TempleArchetype.kalinga:
        _kalinga(canvas, w, h, ink, inkLine);
      case TempleArchetype.himalayan:
        _himalayan(canvas, w, h, ink, inkLine);
      case TempleArchetype.cave:
        _cave(canvas, w, h, ink, inkLine);
      case TempleArchetype.pagoda:
        _pagoda(canvas, w, h, ink, inkLine);
      case TempleArchetype.modern:
        _modern(canvas, w, h, ink, inkLine);
    }

    // Ground line + soft reflection band, shared by every archetype so the
    // structure always sits on something rather than floating in the sky.
    final ground = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.92, w, h * 0.08), ground);
  }

  /// A stepped gopuram: a wide tapering tower of shrinking tiers, capped by a
  /// small kalasha finial — the South Indian temple-gateway silhouette.
  void _dravidian(Canvas c, double w, double h, Paint ink, Paint line) {
    const tiers = 6;
    final baseW = w * 0.62, baseY = h * 0.9, topY = h * 0.16;
    for (var i = 0; i < tiers; i++) {
      final t0 = i / tiers, t1 = (i + 1) / tiers;
      final y0 = baseY - (baseY - topY) * t0;
      final y1 = baseY - (baseY - topY) * t1;
      final wTop = baseW * (1 - t1 * 0.82);
      final wBot = baseW * (1 - t0 * 0.82);
      final path = Path()
        ..moveTo(w / 2 - wBot / 2, y0)
        ..lineTo(w / 2 + wBot / 2, y0)
        ..lineTo(w / 2 + wTop / 2, y1)
        ..lineTo(w / 2 - wTop / 2, y1)
        ..close();
      c.drawPath(path, ink);
      c.drawPath(path, line);
    }
    // Finial.
    c.drawCircle(Offset(w / 2, topY - h * 0.03), h * 0.018, ink);
    // Doorway.
    final door = Path()
      ..moveTo(w / 2 - w * 0.06, baseY)
      ..lineTo(w / 2 - w * 0.06, baseY - h * 0.14)
      ..quadraticBezierTo(w / 2, baseY - h * 0.2, w / 2 + w * 0.06,
          baseY - h * 0.14)
      ..lineTo(w / 2 + w * 0.06, baseY);
    c.drawPath(door, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  /// A single curved shikhara tower rising to a rounded point, banded with
  /// horizontal ribbing — the North Indian temple-spire silhouette.
  void _nagara(Canvas c, double w, double h, Paint ink, Paint line) {
    final baseY = h * 0.9, apexY = h * 0.14;
    final baseHalf = w * 0.24;
    final path = Path()
      ..moveTo(w / 2 - baseHalf, baseY)
      ..quadraticBezierTo(
          w / 2 - baseHalf * 0.5, h * 0.4, w / 2, apexY)
      ..quadraticBezierTo(
          w / 2 + baseHalf * 0.5, h * 0.4, w / 2 + baseHalf, baseY)
      ..close();
    c.drawPath(path, ink);
    c.drawPath(path, line);
    // Amalaka + kalasha at the crown.
    c.drawCircle(Offset(w / 2, apexY - h * 0.015), h * 0.02, ink);
    // Ribbing.
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      final y = baseY - (baseY - apexY) * t;
      final half = baseHalf * (1 - t * 0.94);
      c.drawLine(Offset(w / 2 - half, y), Offset(w / 2 + half, y), line);
    }
    // A low mandapa hall in front.
    final hall = Rect.fromLTWH(w / 2 - w * 0.3, baseY - h * 0.1, w * 0.6, h * 0.1);
    c.drawRect(hall, ink);
  }

  /// A sloped, tiered wooden/copper roofline — the Kerala temple silhouette.
  void _kerala(Canvas c, double w, double h, Paint ink, Paint line) {
    final tiers = [0.36, 0.2];
    var y = h * 0.9;
    var width = w * 0.7;
    for (final ratio in tiers) {
      final roofH = h * ratio;
      final path = Path()
        ..moveTo(w / 2 - width / 2, y)
        ..quadraticBezierTo(w / 2, y - roofH * 1.15, w / 2 + width / 2, y)
        ..close();
      c.drawPath(path, ink);
      c.drawPath(path, line);
      y -= roofH * 0.86;
      width *= 0.56;
    }
    c.drawCircle(Offset(w / 2, y + h * 0.03), h * 0.016, ink);
    // Walls beneath the lowest roof.
    c.drawRect(
        Rect.fromLTWH(w / 2 - w * 0.24, h * 0.78, w * 0.48, h * 0.12), ink);
  }

  /// A curved deul (beehive tower) beside a lower pyramidal mandapa — the
  /// Odisha/Kalinga silhouette.
  void _kalinga(Canvas c, double w, double h, Paint ink, Paint line) {
    final baseY = h * 0.9;
    final deul = Path()
      ..moveTo(w * 0.32, baseY)
      ..cubicTo(w * 0.24, h * 0.5, w * 0.4, h * 0.24, w * 0.5, h * 0.16)
      ..cubicTo(w * 0.6, h * 0.24, w * 0.76, h * 0.5, w * 0.68, baseY)
      ..close();
    c.drawPath(deul, ink);
    c.drawPath(deul, line);
    for (var i = 1; i < 5; i++) {
      final y = baseY - (baseY - h * 0.16) * (i / 5);
      c.drawLine(Offset(w * 0.34, y), Offset(w * 0.66, y), line);
    }
    c.drawCircle(Offset(w / 2, h * 0.16 - h * 0.02), h * 0.015, ink);
    // Front mandapa, stepped and lower.
    final mandapa = Path()
      ..moveTo(w * 0.06, baseY)
      ..lineTo(w * 0.12, h * 0.66)
      ..lineTo(w * 0.34, h * 0.66)
      ..lineTo(w * 0.34, baseY)
      ..close();
    c.drawPath(mandapa, ink);
  }

  /// A modest stone/wood pitched-roof hill shrine set against snow-capped
  /// peaks — the Himalayan silhouette.
  void _himalayan(Canvas c, double w, double h, Paint ink, Paint line) {
    // Distant peaks, drawn faint before the shrine.
    final peaks = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final peakPath = Path()
      ..moveTo(0, h * 0.62)
      ..lineTo(w * 0.18, h * 0.4)
      ..lineTo(w * 0.32, h * 0.56)
      ..lineTo(w * 0.5, h * 0.32)
      ..lineTo(w * 0.68, h * 0.58)
      ..lineTo(w * 0.84, h * 0.38)
      ..lineTo(w, h * 0.6)
      ..lineTo(w, h * 0.92)
      ..lineTo(0, h * 0.92)
      ..close();
    c.drawPath(peakPath, peaks);
    // Snow caps.
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (final x in [0.18, 0.5, 0.84]) {
      final path = Path()
        ..moveTo(w * x - w * 0.05, h * (x == 0.5 ? 0.38 : 0.46))
        ..lineTo(w * x, h * (x == 0.5 ? 0.32 : 0.4))
        ..lineTo(w * x + w * 0.05, h * (x == 0.5 ? 0.38 : 0.46))
        ..close();
      c.drawPath(path, snow);
    }
    // The shrine: a pitched roof over a squat stone base.
    final roof = Path()
      ..moveTo(w * 0.28, h * 0.74)
      ..lineTo(w / 2, h * 0.5)
      ..lineTo(w * 0.72, h * 0.74)
      ..close();
    c.drawPath(roof, ink);
    c.drawPath(roof, line);
    c.drawRect(
        Rect.fromLTWH(w * 0.32, h * 0.74, w * 0.36, h * 0.16), ink);
    c.drawLine(Offset(w / 2, h * 0.5), Offset(w / 2, h * 0.42), line);
    c.drawCircle(Offset(w / 2, h * 0.4), h * 0.013, ink);
  }

  /// An arched sanctum cut into a rock face — the cave/rock-cut silhouette.
  void _cave(Canvas c, double w, double h, Paint ink, Paint line) {
    final rock = Paint()..color = Colors.black.withValues(alpha: 0.26);
    final rockPath = Path()
      ..moveTo(0, h * 0.94)
      ..lineTo(0, h * 0.3)
      ..quadraticBezierTo(w * 0.3, h * 0.1, w * 0.55, h * 0.2)
      ..quadraticBezierTo(w * 0.85, h * 0.32, w, h * 0.24)
      ..lineTo(w, h * 0.94)
      ..close();
    c.drawPath(rockPath, rock);
    // The carved arch entrance.
    final archRect = Rect.fromLTWH(w * 0.32, h * 0.42, w * 0.36, h * 0.5);
    final arch = Path()
      ..moveTo(archRect.left, archRect.bottom)
      ..lineTo(archRect.left, archRect.top + archRect.width / 2)
      ..arcToPoint(Offset(archRect.right, archRect.top + archRect.width / 2),
          radius: Radius.circular(archRect.width / 2))
      ..lineTo(archRect.right, archRect.bottom)
      ..close();
    c.drawPath(arch, ink);
    c.drawPath(arch, line);
    // Pillars flanking the arch.
    for (final x in [archRect.left - w * 0.05, archRect.right + w * 0.02]) {
      c.drawRect(Rect.fromLTWH(x, h * 0.5, w * 0.03, h * 0.42), ink);
    }
  }

  /// A tiered, upturned-eave pagoda roofline.
  void _pagoda(Canvas c, double w, double h, Paint ink, Paint line) {
    var y = h * 0.9;
    var width = w * 0.6;
    for (var i = 0; i < 4; i++) {
      final roofH = h * 0.14;
      final path = Path()
        ..moveTo(w / 2 - width / 2 - w * 0.04, y)
        ..lineTo(w / 2, y - roofH)
        ..lineTo(w / 2 + width / 2 + w * 0.04, y)
        ..quadraticBezierTo(w / 2 + width / 2 - w * 0.03, y - h * 0.02,
            w / 2 + width / 2 - w * 0.08, y - h * 0.015)
        ..lineTo(w / 2 - width / 2 + w * 0.08, y - h * 0.015)
        ..quadraticBezierTo(w / 2 - width / 2 - w * 0.03, y - h * 0.02,
            w / 2 - width / 2 - w * 0.04, y)
        ..close();
      c.drawPath(path, ink);
      c.drawPath(path, line);
      y -= roofH * 0.92;
      width *= 0.72;
    }
    c.drawLine(Offset(w / 2, y), Offset(w / 2, y - h * 0.06), line);
    c.drawCircle(Offset(w / 2, y - h * 0.07), h * 0.012, ink);
  }

  /// A contemporary domed marble complex — smooth arches, a central dome, no
  /// carved tiering — the "modern marvel" silhouette.
  void _modern(Canvas c, double w, double h, Paint ink, Paint line) {
    final baseY = h * 0.9;
    // Wide low base.
    c.drawRect(
        Rect.fromLTWH(w * 0.12, h * 0.66, w * 0.76, baseY - h * 0.66), ink);
    // Central dome.
    final domeRect = Rect.fromCircle(center: Offset(w / 2, h * 0.66), radius: w * 0.22);
    c.drawArc(domeRect, math.pi, math.pi, true, ink);
    c.drawArc(domeRect, math.pi, math.pi, true, line);
    c.drawLine(Offset(w / 2, h * 0.44), Offset(w / 2, h * 0.36), line);
    c.drawCircle(Offset(w / 2, h * 0.35), h * 0.012, ink);
    // Flanking smaller domes.
    for (final dx in [-0.32, 0.32]) {
      final r = Rect.fromCircle(
          center: Offset(w / 2 + w * dx, h * 0.74), radius: w * 0.09);
      c.drawArc(r, math.pi, math.pi, true, ink);
    }
    // Arched doorway.
    final door = Rect.fromLTWH(w / 2 - w * 0.07, h * 0.74, w * 0.14, h * 0.16);
    final doorPath = Path()
      ..moveTo(door.left, door.bottom)
      ..lineTo(door.left, door.top + door.width / 2)
      ..arcToPoint(Offset(door.right, door.top + door.width / 2),
          radius: Radius.circular(door.width / 2))
      ..lineTo(door.right, door.bottom)
      ..close();
    c.drawPath(doorPath, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _TemplePainter old) =>
      old.archetype != archetype || old.colors != colors;
}

/// Dusk-toned sky gradients, rotated by temple id so a scrolling list still
/// varies even within the same archetype (matches how [templeTint] already
/// rotates gold→rose→teal by id).
List<Color> templeSkyColors(Temple t) {
  const palettes = <List<Color>>[
    [Color(0xFFF3C77E), Color(0xFFB9652F)], // dawn gold
    [Color(0xFFE79A8D), Color(0xFF8C3F52)], // dusk rose
    [Color(0xFF7FB8B0), Color(0xFF2E5C5A)], // dusk teal
    [Color(0xFFB79AD9), Color(0xFF4E3F78)], // twilight violet
    [Color(0xFFE3B36B), Color(0xFF6E3A1F)], // amber
  ];
  return palettes[t.id % palettes.length];
}
