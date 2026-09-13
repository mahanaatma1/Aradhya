import 'package:flutter/widgets.dart';

/// 4-pt spacing scale.
abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
}

abstract final class Insets {
  static const page = EdgeInsets.symmetric(horizontal: Space.x4);
  static const card = EdgeInsets.all(Space.x4);
  static const cardTight = EdgeInsets.all(Space.x3);
  static const section = EdgeInsets.fromLTRB(Space.x4, Space.x6, Space.x4, 0);
}

abstract final class Gap {
  static const x1 = SizedBox(width: Space.x1, height: Space.x1);
  static const x2 = SizedBox(width: Space.x2, height: Space.x2);
  static const x3 = SizedBox(width: Space.x3, height: Space.x3);
  static const x4 = SizedBox(width: Space.x4, height: Space.x4);
  static const x6 = SizedBox(width: Space.x6, height: Space.x6);
  static const x8 = SizedBox(width: Space.x8, height: Space.x8);
}
