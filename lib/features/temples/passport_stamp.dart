import 'dart:math' as math;

import 'package:flutter/material.dart';


const kStampInk = Color(0xFF8A3B2A);
const kStampGold = Color(0xFFC08A2E);
const kPaper = Color(0xFFF7EDDF);
const kPaperDeep = Color(0xFFEADCC7);

/// A visa stamp, the way one is actually struck into a passport.
///
/// Drawn rather than assembled from widgets because a real stamp is a single
/// impression: a scalloped ring, the place around the rim, the date across the
/// middle, and the whole thing set down at a slight angle with the ink coming
/// out uneven. A Container with a border cannot do any of that.
///
/// The rotation and the ink density are derived from the temple id, so a given
/// temple always stamps the same way — the page has to look the same every
/// time it is opened.
class PassportStamp extends StatelessWidget {
  final int templeId;
  final String place;
  final DateTime? date;

  /// Rendered around the bottom rim. It is what makes one stamp tell itself
  /// apart from another on a full page.
  final String? state;
  final double size;

  const PassportStamp({
    super.key,
    required this.templeId,
    required this.place,
    this.date,
    this.state,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    // Deterministic per temple: same stamp, same tilt, every open.
    final rnd = math.Random(templeId);
    final angle = (rnd.nextDouble() - 0.5) * 0.34;
    final ink = 0.72 + rnd.nextDouble() * 0.28;

    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _StampPainter(
            place: place,
            date: date,
            state: state,
            ink: ink,
            seed: templeId,
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  final String place;
  final DateTime? date;
  final String? state;
  final double ink;
  final int seed;

  const _StampPainter({
    required this.place,
    required this.date,
    required this.state,
    required this.ink,
    required this.seed,
  });

  static const _mon = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The ink breaks below are drawn with BlendMode.clear, which erases
    // everything beneath it in the current layer -- including the page. The
    // stamp needs a layer of its own so a gap in the ink shows the paper, not
    // a hole through the whole card.
    canvas.saveLayer(Offset.zero & size, Paint());
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final colour = kStampInk.withValues(alpha: ink);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = colour;

    // Outer scalloped ring — the giveaway that this is a stamp and not a badge.
    final scallop = Path();
    const teeth = 34;
    for (var i = 0; i <= teeth; i++) {
      final t = i / teeth * 2 * math.pi;
      final wobble = i.isEven ? r : r - 3.2;
      final p = c + Offset(math.cos(t), math.sin(t)) * wobble;
      if (i == 0) {
        scallop.moveTo(p.dx, p.dy);
      } else {
        scallop.lineTo(p.dx, p.dy);
      }
    }
    scallop.close();
    canvas.drawPath(scallop, line);
    canvas.drawCircle(c, r - 7, line..strokeWidth = 1.1);

    // Place name curved along the top of the rim.
    _arcText(canvas, c, r - 15, place.toUpperCase(), colour, top: true);

    // A shikhara over the date, so a stamp reads as a temple rather than a
    // generic cachet. Drawn from the seed so no two sit identically.
    _shikhara(canvas, c.translate(0, -r * 0.30), r * 0.30, colour);

    // Date across the middle, the way an entry stamp reads.
    if (date != null) {
      final d = date!;
      _line(
          canvas,
          c.translate(0, r * 0.16),
          '${d.day.toString().padLeft(2, '0')} ${_mon[d.month - 1]} ${d.year}',
          colour,
          10.5,
          FontWeight.w800);
    } else {
      _line(canvas, c.translate(0, r * 0.16), 'DARSHAN', colour, 9.5,
          FontWeight.w700);
    }

    // Two rules, as on a real cachet.
    canvas.drawLine(c.translate(-r * 0.40, r * 0.04), c.translate(r * 0.40, r * 0.04),
        Paint()..strokeWidth = 0.9..color = colour.withValues(alpha: 0.5));
    canvas.drawLine(c.translate(-r * 0.40, r * 0.30), c.translate(r * 0.40, r * 0.30),
        Paint()..strokeWidth = 0.9..color = colour.withValues(alpha: 0.5));

    _line(canvas, c.translate(0, r * 0.44), 'ARADHYA',
        colour.withValues(alpha: 0.75), 6.5, FontWeight.w800);

    // The state around the bottom rim -- the line that makes one stamp
    // distinguishable from another at a glance.
    final foot = (state == null || state!.trim().isEmpty)
        ? 'YATRA'
        : state!.toUpperCase();
    _arcText(canvas, c, r - 15, foot, colour.withValues(alpha: 0.85),
        top: false);

    // Ink breaks: a struck stamp never prints evenly.
    final rnd = math.Random(seed + 7);
    final erase = Paint()..blendMode = BlendMode.clear;
    for (var i = 0; i < 5; i++) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final rad = r * (0.35 + rnd.nextDouble() * 0.6);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * rad,
          1.2 + rnd.nextDouble() * 2.2, erase);
    }
    canvas.restore();
  }

  /// A shikhara in outline: plinth, curved tower, kalasha.
  ///
  /// Two strokes and a dot is enough -- at 20 logical pixels a detailed
  /// elevation turns to mud, and the point is recognition, not architecture.
  void _shikhara(Canvas canvas, Offset base, double h, Color colour) {
    final w = h * 0.86;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round
      ..color = colour;

    final left = base.dx - w / 2;
    final right = base.dx + w / 2;
    final bottom = base.dy + h / 2;
    final top = base.dy - h / 2;

    // Plinth.
    canvas.drawLine(Offset(left - w * 0.14, bottom),
        Offset(right + w * 0.14, bottom), stroke);

    // Tower: two curves meeting under the finial.
    final tower = Path()
      ..moveTo(left, bottom)
      ..quadraticBezierTo(left + w * 0.16, top + h * 0.30, base.dx, top)
      ..quadraticBezierTo(right - w * 0.16, top + h * 0.30, right, bottom);
    canvas.drawPath(tower, stroke);

    // Doorway.
    final door = Path()
      ..moveTo(base.dx - w * 0.13, bottom)
      ..lineTo(base.dx - w * 0.13, bottom - h * 0.22)
      ..quadraticBezierTo(
          base.dx, bottom - h * 0.34, base.dx + w * 0.13, bottom - h * 0.22)
      ..lineTo(base.dx + w * 0.13, bottom);
    canvas.drawPath(door, stroke..strokeWidth = 0.9);

    // Kalasha.
    canvas.drawCircle(Offset(base.dx, top - h * 0.10), h * 0.075,
        Paint()..color = colour);
  }

  void _line(Canvas canvas, Offset at, String text, Color colour, double size,
      FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: 1.2,
            color: colour),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, at.dy - tp.height / 2));
  }

  /// Text bent around the rim, one glyph at a time.
  void _arcText(Canvas canvas, Offset c, double radius, String text,
      Color colour, {required bool top}) {
    if (text.isEmpty) return;
    final chars = text.characters.toList();
    // Keep it inside a comfortable arc so long names do not wrap onto
    // themselves at the sides.
    final span = math.min(chars.length * 0.19, top ? 2.2 : 1.5);
    final start = top ? -math.pi / 2 - span / 2 : math.pi / 2 + span / 2;

    for (var i = 0; i < chars.length; i++) {
      final t = chars.length == 1 ? 0.5 : i / (chars.length - 1);
      final a = top ? start + span * t : start - span * t;
      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: colour),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
          c.dx + math.cos(a) * radius, c.dy + math.sin(a) * radius);
      canvas.rotate(top ? a + math.pi / 2 : a - math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StampPainter old) =>
      old.place != place ||
      old.date != date ||
      old.state != state ||
      old.ink != ink;
}

/// The paper a passport page is printed on: warm stock with a faint guilloche
/// wash, so a stamp has something to sit on rather than floating on flat white.
class PassportPaper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PassportPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPaper, kPaperDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: _GuillochePainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The faint interference pattern security paper is printed with.
class _GuillochePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = kStampGold.withValues(alpha: 0.10);
    final c = Offset(size.width / 2, size.height * 0.45);

    for (var k = 0; k < 5; k++) {
      final path = Path();
      final rx = size.width * (0.30 + k * 0.08);
      final ry = size.height * (0.22 + k * 0.05);
      for (var i = 0; i <= 90; i++) {
        final t = i / 90 * 2 * math.pi;
        final p = c +
            Offset(math.cos(t * 3 + k) * rx * 0.5 + math.cos(t) * rx * 0.5,
                math.sin(t * 2 + k) * ry * 0.5 + math.sin(t) * ry * 0.5);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The rows of chevrons along the bottom of a real passport data page.
class MachineReadableStrip extends StatelessWidget {
  final String line1;
  final String line2;
  const MachineReadableStrip({
    super.key,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle style() => const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5A4632),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line1, style: style(), maxLines: 1, overflow: TextOverflow.clip),
        const SizedBox(height: 2),
        Text(line2, style: style(), maxLines: 1, overflow: TextOverflow.clip),
      ],
    );
  }
}
