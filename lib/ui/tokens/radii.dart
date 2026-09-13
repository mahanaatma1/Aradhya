import 'package:flutter/painting.dart';

/// Corner radii. Utsav is generous: cards 24, tiles 18, chips pill.
abstract final class Radii {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
  static const pill = 999.0;

  static const rXs = BorderRadius.all(Radius.circular(xs));
  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rPill = BorderRadius.all(Radius.circular(pill));
  static const rSheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}
