import 'package:flutter/animation.dart';

/// Durations and curves. Every animation in the app reads one of these.
abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const reveal = Duration(milliseconds: 460);
  static const hero = Duration(milliseconds: 520);
  static const ambient = Duration(milliseconds: 3000);

  /// Delay between staggered siblings, and the cap so long lists never wait.
  static const stagger = Duration(milliseconds: 40);
  static const staggerCap = Duration(milliseconds: 320);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
  static const enter = Curves.easeOutBack;
  static const exit = Curves.easeInCubic;
  static const linear = Curves.linear;
}

/// Spring presets for physics-driven motion.
abstract final class Springs {
  static const gentle = SpringDescription(mass: 1, stiffness: 120, damping: 18);
  static const snappy = SpringDescription(mass: 1, stiffness: 320, damping: 26);
  static const bouncy = SpringDescription(mass: 1, stiffness: 260, damping: 14);
}
