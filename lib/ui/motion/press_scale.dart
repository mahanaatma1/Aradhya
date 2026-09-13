import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../tokens/motion_tokens.dart';
import 'motion_scope.dart';

enum HapticKind { none, selection, light, medium, heavy }

/// Tactile press: scales down while held and springs back on release, with a
/// haptic tick. Under reduced motion it only dips opacity.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = HapticKind.selection,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HapticKind haptic;
  final bool enabled;

  static void haptics(HapticKind kind) {
    switch (kind) {
      case HapticKind.none:
        break;
      case HapticKind.selection:
        HapticFeedback.selectionClick();
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  void _down(TapDownDetails _) {
    if (!widget.enabled) return;
    _c.animateTo(widget.scale, duration: Motion.fast, curve: Motion.standard);
  }

  void _release() {
    if (!widget.enabled) return;
    _c.animateWith(SpringSimulation(Springs.snappy, _c.value, 1, -2));
  }

  void _tap() {
    if (!widget.enabled || widget.onTap == null) return;
    PressScale.haptics(widget.haptic);
    widget.onTap!();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionScope.of(context).reduce;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: _tap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              PressScale.haptics(HapticKind.medium);
              widget.onLongPress!();
            },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => reduce
            ? Opacity(opacity: 0.6 + 0.4 * ((_c.value - widget.scale) / (1 - widget.scale)).clamp(0, 1), child: child)
            : Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}
