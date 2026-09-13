import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'motion_scope.dart';

/// What a particle looks like. Each sprite is rasterised once into a shared
/// atlas and drawn with `drawAtlas`, so a field of 400 costs one draw call.
enum Sprite { petal, marigold, spark, smoke, flame, star, dot }

/// Describes how particles are born and move. Emitters are pure data +
/// functions so a screen can `const` them.
class Emitter {
  const Emitter({
    required this.sprite,
    required this.spawn,
    required this.rate,
    required this.life,
    this.color = Colors.white,
    this.blend = BlendMode.srcOver,
    this.gravity = 0,
    this.drag = 0,
    this.wind = 0,
    this.spin = 0,
    this.sizeMin = 6,
    this.sizeMax = 12,
    this.fadeIn = 0.1,
    this.fadeOut = 0.35,
    this.burst = 0,
    this.share = 1,
  });

  final Sprite sprite;

  /// Where a particle starts (normalised 0..1 of the field) and its initial
  /// velocity in px/s. Called with a random source and the field size.
  final ParticleSpawn spawn;

  /// Particles per second (0 for burst-only emitters).
  final double rate;

  /// Lifetime range in seconds.
  final (double, double) life;

  final Color color;
  final BlendMode blend;
  final double gravity;
  final double drag;
  final double wind;
  final double spin;
  final double sizeMin;
  final double sizeMax;

  /// Fraction of life spent fading in / out.
  final double fadeIn;
  final double fadeOut;

  /// Particles emitted immediately at start.
  final int burst;

  /// Share of the tier's particle budget this emitter may use (0..1).
  final double share;
}

typedef ParticleSpawn = ({Offset pos, Offset vel}) Function(
    math.Random rng, Size size);

/// Stock emitters. Positions are normalised; sizes in logical px.
abstract final class Emitters {
  static Emitter flame({Offset at = const Offset(0.5, 0.75), double spread = 0.05, Color color = const Color(0xFFFFB347), double rate = 26}) =>
      Emitter(
        sprite: Sprite.flame,
        color: color,
        blend: BlendMode.plus,
        rate: rate,
        life: (0.5, 0.9),
        sizeMin: 8,
        sizeMax: 18,
        gravity: -140,
        drag: 1.8,
        fadeIn: 0.05,
        fadeOut: 0.5,
        share: 0.25,
        spawn: (r, s) => (
          pos: Offset(at.dx + (r.nextDouble() - .5) * spread, at.dy),
          vel: Offset((r.nextDouble() - .5) * 18, -40 - r.nextDouble() * 30),
        ),
      );

  static Emitter smoke({Offset at = const Offset(0.5, 0.7), Color color = const Color(0x66FFFFFF), double rate = 4}) =>
      Emitter(
        sprite: Sprite.smoke,
        color: color,
        rate: rate,
        life: (2.5, 4.0),
        sizeMin: 18,
        sizeMax: 40,
        gravity: -22,
        drag: 0.6,
        wind: 6,
        spin: 0.3,
        fadeIn: 0.25,
        fadeOut: 0.5,
        share: 0.1,
        spawn: (r, s) => (
          pos: Offset(at.dx + (r.nextDouble() - .5) * 0.02, at.dy),
          vel: Offset((r.nextDouble() - .5) * 8, -18),
        ),
      );

  static Emitter petals({double rate = 6, Color color = const Color(0xFFF5B31E)}) =>
      Emitter(
        sprite: Sprite.petal,
        color: color,
        rate: rate,
        life: (5, 8),
        sizeMin: 8,
        sizeMax: 14,
        gravity: 18,
        drag: 0.4,
        wind: 14,
        spin: 1.6,
        fadeIn: 0.1,
        fadeOut: 0.15,
        share: 0.35,
        spawn: (r, s) => (
          pos: Offset(r.nextDouble(), -0.05),
          vel: Offset((r.nextDouble() - .5) * 20, 20 + r.nextDouble() * 20),
        ),
      );

  static Emitter sparkleBurst({Offset at = const Offset(0.5, 0.5), int count = 40, Color color = const Color(0xFFFFC63A)}) =>
      Emitter(
        sprite: Sprite.spark,
        color: color,
        blend: BlendMode.plus,
        rate: 0,
        burst: count,
        life: (0.6, 1.2),
        sizeMin: 3,
        sizeMax: 7,
        gravity: 120,
        drag: 2.5,
        fadeIn: 0,
        fadeOut: 0.6,
        share: 0.3,
        spawn: (r, s) {
          final a = r.nextDouble() * math.pi * 2;
          final v = 120 + r.nextDouble() * 220;
          return (pos: at, vel: Offset(math.cos(a) * v, math.sin(a) * v));
        },
      );

  static Emitter stars({double rate = 3, Color color = const Color(0xFFFFF3E4)}) =>
      Emitter(
        sprite: Sprite.star,
        color: color,
        blend: BlendMode.plus,
        rate: rate,
        burst: 40,
        life: (2, 5),
        sizeMin: 2,
        sizeMax: 5,
        fadeIn: 0.4,
        fadeOut: 0.4,
        share: 0.25,
        spawn: (r, s) => (pos: Offset(r.nextDouble(), r.nextDouble() * 0.7), vel: Offset.zero),
      );

  static Emitter confetti({int count = 80}) => Emitter(
        sprite: Sprite.dot,
        color: Colors.white,
        rate: 0,
        burst: count,
        life: (1.5, 2.6),
        sizeMin: 5,
        sizeMax: 9,
        gravity: 260,
        drag: 1.2,
        wind: 10,
        spin: 4,
        fadeIn: 0,
        fadeOut: 0.3,
        share: 0.4,
        spawn: (r, s) => (
          pos: Offset(0.5, 0.35),
          vel: Offset((r.nextDouble() - .5) * 520, -300 - r.nextDouble() * 260),
        ),
      );
}

/// Renders one or more emitters inside its box. Honors [MotionScope]:
/// budget by tier, off under reduced motion (renders [fallback] instead).
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    required this.emitters,
    this.fallback,
    this.paused = false,
    this.palette,
    this.child,
  });

  final List<Emitter> emitters;
  final Widget? fallback;
  final bool paused;

  /// Per-particle colour cycling for [Sprite.dot] (confetti).
  final List<Color>? palette;
  final Widget? child;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final _Pool _pool = _Pool(0);
  Duration _last = Duration.zero;
  double _accum = 0;
  bool _burstDone = false;
  final _rng = math.Random();
  Size _size = Size.zero;
  int _slowFrames = 0;
  int _budget = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didUpdateWidget(ParticleField old) {
    super.didUpdateWidget(old);
    if (old.emitters != widget.emitters) _burstDone = false;
  }

  void _tick(Duration now) {
    if (!mounted) return;
    final dt = _last == Duration.zero
        ? 0.0
        : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (widget.paused || _size.isEmpty || _budget == 0) return;
    final sw = Stopwatch()..start();
    _step(dt);
    sw.stop();
    // Self-throttle: if simulation+paint keeps exceeding 8 ms, halve budget.
    if (sw.elapsedMicroseconds > 8000) {
      if (++_slowFrames > 30) {
        _budget = math.max(20, _budget ~/ 2);
        _slowFrames = 0;
      }
    } else {
      _slowFrames = 0;
    }
    setState(() {});
  }

  void _step(double dt) {
    final emitters = widget.emitters;
    for (var e = 0; e < emitters.length; e++) {
      final em = emitters[e];
      final cap = (_budget * em.share).round();
      if (!_burstDone && em.burst > 0) {
        for (var i = 0; i < em.burst && _pool.countOf(e) < cap; i++) {
          _spawn(e, em);
        }
      }
      if (em.rate > 0) {
        _accum += em.rate * dt;
        while (_accum >= 1) {
          _accum -= 1;
          if (_pool.countOf(e) < cap) _spawn(e, em);
        }
      }
    }
    _burstDone = true;
    _pool.update(dt, emitters, _size);
  }

  void _spawn(int e, Emitter em) {
    final s = em.spawn(_rng, _size);
    final life = em.life.$1 + _rng.nextDouble() * (em.life.$2 - em.life.$1);
    _pool.add(
      e: e,
      x: s.pos.dx * _size.width,
      y: s.pos.dy * _size.height,
      vx: s.vel.dx,
      vy: s.vel.dy,
      life: life,
      size: em.sizeMin + _rng.nextDouble() * (em.sizeMax - em.sizeMin),
      rot: _rng.nextDouble() * math.pi * 2,
      seed: _rng.nextDouble(),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MotionScope.of(context);
    if (!m.particles) {
      return widget.fallback ?? (widget.child ?? const SizedBox.shrink());
    }
    if (_budget == 0) _budget = m.maxParticles;
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth.isFinite ? box.maxWidth : 400,
          box.maxHeight.isFinite ? box.maxHeight : 400);
      return RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          willChange: true,
          painter: _FieldPainter(_pool, widget.emitters, widget.palette),
          child: widget.child ?? const SizedBox.expand(),
        ),
      );
    });
  }
}

/// Structure-of-arrays particle storage.
class _Pool {
  _Pool(int initial) {
    _grow(math.max(64, initial));
  }

  int count = 0;
  late Float32List x, y, vx, vy, life, age, size, rot, seed;
  late Uint8List emitter;

  void _grow(int cap) {
    Float32List g(Float32List? old) {
      final n = Float32List(cap);
      if (old != null) n.setRange(0, old.length, old);
      return n;
    }

    final first = count == 0 && !_init;
    x = g(first ? null : x);
    y = g(first ? null : y);
    vx = g(first ? null : vx);
    vy = g(first ? null : vy);
    life = g(first ? null : life);
    age = g(first ? null : age);
    size = g(first ? null : size);
    rot = g(first ? null : rot);
    seed = g(first ? null : seed);
    final em = Uint8List(cap);
    if (!first) em.setRange(0, emitter.length, emitter);
    emitter = em;
    _init = true;
  }

  bool _init = false;

  int countOf(int e) {
    var n = 0;
    for (var i = 0; i < count; i++) {
      if (emitter[i] == e) n++;
    }
    return n;
  }

  void add({
    required int e,
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double size,
    required double rot,
    required double seed,
  }) {
    if (count >= this.x.length) _grow(this.x.length * 2);
    final i = count++;
    this.x[i] = x;
    this.y[i] = y;
    this.vx[i] = vx;
    this.vy[i] = vy;
    this.life[i] = life;
    age[i] = 0;
    this.size[i] = size;
    this.rot[i] = rot;
    this.seed[i] = seed;
    emitter[i] = e;
  }

  void _remove(int i) {
    final last = count - 1;
    if (i != last) {
      x[i] = x[last];
      y[i] = y[last];
      vx[i] = vx[last];
      vy[i] = vy[last];
      life[i] = life[last];
      age[i] = age[last];
      size[i] = size[last];
      rot[i] = rot[last];
      seed[i] = seed[last];
      emitter[i] = emitter[last];
    }
    count = last;
  }

  void update(double dt, List<Emitter> ems, Size bounds) {
    var i = 0;
    while (i < count) {
      final em = ems[emitter[i]];
      age[i] += dt;
      if (age[i] >= life[i]) {
        _remove(i);
        continue;
      }
      final t = age[i];
      vy[i] += em.gravity * dt;
      vx[i] += em.wind * math.sin(t * 1.7 + seed[i] * 6.28) * dt * 4;
      final d = 1 - em.drag * dt;
      vx[i] *= d;
      vy[i] *= d;
      x[i] += vx[i] * dt;
      y[i] += vy[i] * dt;
      rot[i] += em.spin * dt * (seed[i] > .5 ? 1 : -1);
      if (y[i] > bounds.height + 40 || x[i] < -40 || x[i] > bounds.width + 40) {
        _remove(i);
        continue;
      }
      i++;
    }
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter(this.pool, this.emitters, this.palette);
  final _Pool pool;
  final List<Emitter> emitters;
  final List<Color>? palette;

  static ui.Image? _atlas;
  static const _cell = 32.0;
  static bool _building = false;

  static Rect _spriteRect(Sprite s) =>
      Rect.fromLTWH(s.index * _cell, 0, _cell, _cell);

  static void _ensureAtlas() {
    if (_atlas != null || _building) return;
    _building = true;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    for (final s in Sprite.values) {
      c.save();
      c.translate(s.index * _cell + _cell / 2, _cell / 2);
      _drawSprite(c, s);
      c.restore();
    }
    rec.endRecording().toImage((Sprite.values.length * _cell).toInt(), _cell.toInt()).then((img) {
      _atlas = img;
      _building = false;
    });
  }

  static void _drawSprite(Canvas c, Sprite s) {
    final white = Paint()..color = Colors.white;
    const r = _cell / 2 - 2;
    switch (s) {
      case Sprite.petal:
        final p = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(r * .9, -r * .2, 0, r)
          ..quadraticBezierTo(-r * .9, -r * .2, 0, -r)
          ..close();
        c.drawPath(p, white);
      case Sprite.marigold:
        for (var i = 0; i < 8; i++) {
          c.save();
          c.rotate(i * math.pi / 4);
          c.drawOval(Rect.fromCenter(center: Offset(0, -r * .55), width: r * .7, height: r * .9), white);
          c.restore();
        }
        c.drawCircle(Offset.zero, r * .35, white);
      case Sprite.spark:
        final p = Path()
          ..moveTo(0, -r)
          ..lineTo(r * .25, -r * .25)
          ..lineTo(r, 0)
          ..lineTo(r * .25, r * .25)
          ..lineTo(0, r)
          ..lineTo(-r * .25, r * .25)
          ..lineTo(-r, 0)
          ..lineTo(-r * .25, -r * .25)
          ..close();
        c.drawPath(p, white);
      case Sprite.smoke:
        c.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..shader = ui.Gradient.radial(Offset.zero, r,
                  [Colors.white.withValues(alpha: .9), Colors.white.withValues(alpha: 0)]));
      case Sprite.flame:
        c.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 1.2, height: r * 2),
            Paint()
              ..shader = ui.Gradient.radial(Offset(0, r * .3), r * 1.1,
                  [Colors.white, Colors.white.withValues(alpha: 0)]));
      case Sprite.star:
        c.drawCircle(
            Offset.zero,
            r,
            Paint()
              ..shader = ui.Gradient.radial(Offset.zero, r,
                  [Colors.white, Colors.white.withValues(alpha: .35), Colors.white.withValues(alpha: 0)],
                  [0, .3, 1]));
      case Sprite.dot:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * .9), const Radius.circular(2)), white);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureAtlas();
    final atlas = _atlas;
    if (atlas == null || pool.count == 0) return;

    // Group by emitter so each group shares a blend mode.
    for (var e = 0; e < emitters.length; e++) {
      final em = emitters[e];
      final rect = _spriteRect(em.sprite);
      final transforms = <RSTransform>[];
      final rects = <Rect>[];
      final colors = <Color>[];
      for (var i = 0; i < pool.count; i++) {
        if (pool.emitter[i] != e) continue;
        final t = pool.age[i] / pool.life[i];
        double a = 1;
        if (t < em.fadeIn && em.fadeIn > 0) a = t / em.fadeIn;
        if (t > 1 - em.fadeOut && em.fadeOut > 0) a = math.min(a, (1 - t) / em.fadeOut);
        final scale = pool.size[i] / _cell;
        transforms.add(RSTransform.fromComponents(
          rotation: pool.rot[i],
          scale: scale,
          anchorX: _cell / 2,
          anchorY: _cell / 2,
          translateX: pool.x[i],
          translateY: pool.y[i],
        ));
        rects.add(rect);
        final base = (palette != null && em.sprite == Sprite.dot)
            ? palette![(pool.seed[i] * palette!.length).floor() % palette!.length]
            : em.color;
        colors.add(base.withValues(alpha: base.a * a.clamp(0, 1)));
      }
      if (transforms.isEmpty) continue;
      canvas.drawAtlas(atlas, transforms, rects, colors, BlendMode.modulate,
          null, Paint()..blendMode = em.blend);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => true;
}

/// Pauses every ambient ticker beneath it while the app is not in the
/// foreground. Mount once above the router.
class MotionLifecycle extends StatefulWidget {
  const MotionLifecycle({super.key, required this.child});
  final Widget child;

  @override
  State<MotionLifecycle> createState() => _MotionLifecycleState();
}

class _MotionLifecycleState extends State<MotionLifecycle> {
  late final AppLifecycleListener _l;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _l = AppLifecycleListener(
      onResume: () => setState(() => _active = true),
      onInactive: () => setState(() => _active = false),
    );
  }

  @override
  void dispose() {
    _l.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: _active, child: widget.child);
}
