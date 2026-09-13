import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../motion/motion_scope.dart';

/// Bundled fragment shaders (see pubspec `flutter: shaders:`).
enum ShaderId {
  utsavSky('assets/shaders/utsav_sky.frag'),
  goldShimmer('assets/shaders/gold_shimmer.frag'),
  glowBloom('assets/shaders/glow_bloom.frag'),
  stars('assets/shaders/stars.frag');

  const ShaderId(this.asset);
  final String asset;
}

/// Loads each program once; a failed compile stays null so [ShaderSurface]
/// paints its fallback instead of throwing.
class ShaderLibrary {
  ShaderLibrary._();
  static final _programs = <ShaderId, ui.FragmentProgram?>{};
  static final _pending = <ShaderId, Future<ui.FragmentProgram?>>{};

  static ui.FragmentProgram? get(ShaderId id) => _programs[id];

  static Future<ui.FragmentProgram?> load(ShaderId id) {
    if (_programs.containsKey(id)) return Future.value(_programs[id]);
    return _pending.putIfAbsent(id, () async {
      try {
        final p = await ui.FragmentProgram.fromAsset(id.asset);
        _programs[id] = p;
        return p;
      } catch (e) {
        debugPrint('ShaderLibrary: ${id.asset} unavailable ($e)');
        _programs[id] = null;
        return null;
      }
    });
  }

  /// Load every shader; call on the splash so first use never compiles.
  static Future<void> warmUp() => Future.wait(ShaderId.values.map(load));
}

/// Paints a shader across its box, feeding `uResolution`, `uTime`, then the
/// given [colors] (as vec4 each) and [params] in declaration order. Falls
/// back to [fallback] when the program is unavailable or shaders are off.
class ShaderSurface extends StatefulWidget {
  const ShaderSurface({
    super.key,
    required this.id,
    required this.fallback,
    this.colors = const [],
    this.params = const [],
    this.animate = true,
    this.child,
  });

  final ShaderId id;
  final Widget fallback;
  final List<Color> colors;
  final List<double> params;
  final bool animate;
  final Widget? child;

  @override
  State<ShaderSurface> createState() => _ShaderSurfaceState();
}

class _ShaderSurfaceState extends State<ShaderSurface>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _program = ShaderLibrary.get(widget.id);
    if (_program == null) {
      ShaderLibrary.load(widget.id).then((p) {
        if (mounted) setState(() => _program = p);
      });
    }
    if (widget.animate) _clock.repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MotionScope.of(context);
    final program = _program;
    if (program == null || !m.shaders) {
      return widget.child == null
          ? widget.fallback
          : Stack(fit: StackFit.passthrough, children: [
              Positioned.fill(child: widget.fallback),
              widget.child!,
            ]);
    }
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, child) => CustomPaint(
        painter: _ShaderPainter(
          program: program,
          time: widget.animate ? _clock.value * 1000 : 0,
          colors: widget.colors,
          params: widget.params,
        ),
        child: child,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({
    required this.program,
    required this.time,
    required this.colors,
    required this.params,
  });

  final ui.FragmentProgram program;
  final double time;
  final List<Color> colors;
  final List<double> params;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    var i = 0;
    shader.setFloat(i++, size.width);
    shader.setFloat(i++, size.height);
    shader.setFloat(i++, time % 1000);
    for (final c in colors) {
      shader.setFloat(i++, c.r);
      shader.setFloat(i++, c.g);
      shader.setFloat(i++, c.b);
      shader.setFloat(i++, c.a);
    }
    for (final p in params) {
      shader.setFloat(i++, p);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) =>
      old.time != time || old.colors != colors || old.params != params;
}
