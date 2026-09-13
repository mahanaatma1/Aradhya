import 'package:flutter/material.dart';

import '../tokens/motion_tokens.dart';
import 'motion_scope.dart';

enum RevealKind { fadeUp, fadeIn, pop }

/// Staggered entrance: fade + 8% rise + slight scale, delayed by [index] ×
/// [Motion.stagger] (capped). Returns the child untouched under reduced
/// motion, and never re-runs on rebuild.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.kind = RevealKind.fadeUp,
    this.duration = Motion.reveal,
    this.delay,
  });

  final Widget child;
  final int index;
  final RevealKind kind;
  final Duration duration;
  final Duration? delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _c,
    curve: widget.kind == RevealKind.pop ? Motion.enter : Motion.emphasized,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final m = MotionScope.of(context);
    if (m.reduce) {
      _c.value = 1;
      return;
    }
    final delay = widget.delay ??
        Duration(
            milliseconds: (widget.index * Motion.stagger.inMilliseconds)
                .clamp(0, Motion.staggerCap.inMilliseconds));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        Widget w = Opacity(opacity: t.clamp(0, 1), child: child);
        switch (widget.kind) {
          case RevealKind.fadeIn:
            return w;
          case RevealKind.fadeUp:
            return Transform.translate(
              offset: Offset(0, 18 * (1 - t)),
              child: Transform.scale(scale: 0.96 + 0.04 * t, child: w),
            );
          case RevealKind.pop:
            return Transform.scale(scale: 0.7 + 0.3 * t, child: w);
        }
      },
    );
  }
}

/// Reveals the first [maxAnimated] children with a stagger; the rest appear
/// immediately, so long lists never queue up hundreds of tickers.
class RevealList extends StatelessWidget {
  const RevealList({
    super.key,
    required this.children,
    this.maxAnimated = 12,
    this.kind = RevealKind.fadeUp,
    this.startIndex = 0,
  });

  final List<Widget> children;
  final int maxAnimated;
  final RevealKind kind;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          if (i < maxAnimated)
            Reveal(index: startIndex + i, kind: kind, child: children[i])
          else
            children[i],
      ],
    );
  }
}
