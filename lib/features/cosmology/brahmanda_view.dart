import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'cosmology_models.dart';

/// The Brahmanda — the cosmos drawn as the structure it is described as.
///
/// The lokas were rendered as a scrolling list of cards, which describes the
/// arrangement without ever showing it. The Vishnu Purana is explicit that the
/// whole thing sits inside one shell with the earth at its middle, seven
/// worlds rising and seven descending; that is a diagram, and a list is the
/// wrong shape for it.
///
/// Drawn rather than illustrated: paths need no licence, stay crisp at any
/// size, and can be hit-tested ring by ring, which an image cannot.
class BrahmandaView extends StatelessWidget {
  final List<CosmologyNode> nodes;
  final bool hindi;
  final int? selectedId;
  final ValueChanged<CosmologyNode> onSelect;

  const BrahmandaView({
    super.key,
    required this.nodes,
    required this.hindi,
    required this.selectedId,
    required this.onSelect,
  });

  /// Upper worlds outward from the earth, lower worlds inward beneath it.
  static const _upper = [
    'loka-bhur', 'loka-bhuvar', 'loka-svar', 'loka-mahar',
    'loka-jana', 'loka-tapa', 'loka-satya',
  ];
  static const _lower = [
    'loka-atala', 'loka-vitala', 'loka-sutala', 'loka-talatala',
    'loka-mahatala', 'loka-rasatala', 'loka-patala',
  ];

  @override
  Widget build(BuildContext context) {
    final byId = {for (final n in nodes) n.slug: n};
    final upper = [for (final s in _upper) if (byId[s] != null) byId[s]!];
    final lower = [for (final s in _lower) if (byId[s] != null) byId[s]!];
    if (upper.isEmpty && lower.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, 420.0);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: GestureDetector(
              onTapUp: (d) {
                final hit = _hitTest(d.localPosition, Size(side, side),
                    upper.length, lower.length);
                if (hit == null) return;
                final (isUpper, index) = hit;
                final list = isUpper ? upper : lower;
                if (index < list.length) onSelect(list[index]);
              },
              child: CustomPaint(
                painter: _BrahmandaPainter(
                  upper: upper,
                  lower: lower,
                  hindi: hindi,
                  selectedId: selectedId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Which ring was tapped, if any.
  ///
  /// The same geometry as the painter, kept in one place so the drawing and
  /// the touch target cannot drift apart.
  static (bool, int)? _hitTest(Offset p, Size size, int upperN, int lowerN) {
    final c = Offset(size.width / 2, size.height / 2);
    final v = p - c;
    final r = v.distance;
    final maxR = size.width / 2 * 0.94;
    final coreR = maxR * 0.20;

    if (r < coreR) return null;                       // Meru itself
    if (r > maxR) return null;                        // outside the shell

    final band = (maxR - coreR) / math.max(upperN, 1);
    final index = ((r - coreR) / band).floor();
    // Above the horizon reads as ascent, below it as descent.
    final isUpper = v.dy <= 0;
    final n = isUpper ? upperN : lowerN;
    return (isUpper, index.clamp(0, n - 1));
  }
}

class _BrahmandaPainter extends CustomPainter {
  final List<CosmologyNode> upper;
  final List<CosmologyNode> lower;
  final bool hindi;
  final int? selectedId;

  const _BrahmandaPainter({
    required this.upper,
    required this.lower,
    required this.hindi,
    required this.selectedId,
  });

  // Warm, not spacey. The screen sits beside cream cards everywhere else in
  // the app, and an indigo starfield made cosmology look like astronomy.
  static const _shell = Color(0xFF8A6A4F);
  static const _gold = Color(0xFFC97A3E);
  static const _up = Color(0xFFC9873F);
  static const _down = Color(0xFF6E5A4E);
  static const _ink = Color(0xFF3A2A18);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 * 0.94;
    final coreR = maxR * 0.20;
    final band = (maxR - coreR) / math.max(upper.length, 1);

    // The shell. Everything that exists is inside it, and the Purana is
    // careful that it has an outside -- so it is drawn closed.
    canvas.drawCircle(
        c,
        maxR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _shell.withValues(alpha: 0.75));
    canvas.drawCircle(c, maxR, Paint()..color = _shell.withValues(alpha: 0.04));

    for (var i = upper.length - 1; i >= 0; i--) {
      _band(canvas, c, coreR + band * i, coreR + band * (i + 1), true,
          upper[i], i);
    }
    for (var i = lower.length - 1; i >= 0; i--) {
      _band(canvas, c, coreR + band * i, coreR + band * (i + 1), false,
          lower[i], i);
    }

    // The horizon: the plane the reader is standing on. Everything above is
    // measured up from it and everything below is measured down.
    canvas.drawLine(
        Offset(c.dx - maxR, c.dy),
        Offset(c.dx + maxR, c.dy),
        Paint()
          ..strokeWidth = 1.4
          ..color = _gold.withValues(alpha: 0.75));

    _meru(canvas, c, coreR);
  }

  void _band(Canvas canvas, Offset c, double inner, double outer, bool up,
      CosmologyNode node, int index) {
    final selected = node.id == selectedId;
    final base = up ? _up : _down;
    // Higher worlds lighter, lower worlds darker: the depth is carried by the
    // colour so the diagram reads before any label does.
    final t = index / math.max(upper.length - 1, 1);
    final colour = Color.lerp(base, up ? _gold : const Color(0xFF2A1810), t)!;

    final rect = Rect.fromCircle(center: c, radius: (inner + outer) / 2);
    canvas.drawArc(
        rect,
        up ? math.pi : 0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (outer - inner) * (selected ? 0.92 : 0.72)
          ..color = colour.withValues(alpha: selected ? 0.95 : 0.62));

    if (selected) {
      canvas.drawArc(
          rect,
          up ? math.pi : 0,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (outer - inner) * 0.92
            ..color = _ink.withValues(alpha: 0.35));
    }

    _label(canvas, c, (inner + outer) / 2, up, node);
  }

  void _label(Canvas canvas, Offset c, double r, bool up, CosmologyNode node) {
    final tp = TextPainter(
      text: TextSpan(
        text: node.title(hindi),
        style: TextStyle(
          fontFamily: hindi ? AppFonts.devanagari : AppFonts.display,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFFF8EF),
          shadows: const [Shadow(color: Color(0x66000000), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Sat on the vertical axis where each ring is widest and least crowded.
    final dy = up ? -r : r;
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + dy - tp.height / 2));
  }

  /// Meru at the centre, which is where every account puts it.
  void _meru(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF7F5F2));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _gold);

    final mountain = Path()
      ..moveTo(c.dx - r * 0.52, c.dy + r * 0.34)
      ..lineTo(c.dx - r * 0.16, c.dy - r * 0.40)
      ..lineTo(c.dx + r * 0.16, c.dy - r * 0.40)
      ..lineTo(c.dx + r * 0.52, c.dy + r * 0.34)
      ..close();
    canvas.drawPath(mountain, Paint()..color = _gold.withValues(alpha: 0.85));

    final tp = TextPainter(
      text: TextSpan(
        text: hindi ? 'मेरु' : 'Meru',
        style: const TextStyle(
            fontSize: 8.5, fontWeight: FontWeight.w800, color: _ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + r * 0.42));
  }

  @override
  bool shouldRepaint(covariant _BrahmandaPainter old) =>
      old.selectedId != selectedId ||
      old.hindi != hindi ||
      old.upper.length != upper.length;
}
