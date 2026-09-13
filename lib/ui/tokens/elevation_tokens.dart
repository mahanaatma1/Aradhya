import 'package:flutter/material.dart';

import 'palette.dart';

/// Shadow sets per brightness. Light casts soft warm shadows; dark uses a
/// marigold rim glow instead, since shadows vanish on a night ground.
@immutable
class ElevationTokens extends ThemeExtension<ElevationTokens> {
  final List<BoxShadow> rest;
  final List<BoxShadow> raised;
  final List<BoxShadow> float;
  final List<BoxShadow> glow;

  const ElevationTokens({
    required this.rest,
    required this.raised,
    required this.float,
    required this.glow,
  });

  static const light = ElevationTokens(
    rest: [
      BoxShadow(color: Color(0x14501414), blurRadius: 10, offset: Offset(0, 3)),
    ],
    raised: [
      BoxShadow(color: Color(0x1F501414), blurRadius: 20, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A501414), blurRadius: 3, offset: Offset(0, 1)),
    ],
    float: [
      BoxShadow(color: Color(0x33501414), blurRadius: 34, offset: Offset(0, 16)),
      BoxShadow(color: Color(0x14501414), blurRadius: 6, offset: Offset(0, 2)),
    ],
    glow: [
      BoxShadow(color: Color(0x66F5B31E), blurRadius: 24),
    ],
  );

  static const dark = ElevationTokens(
    rest: [
      BoxShadow(color: Color(0x1FFFC63A), blurRadius: 0, spreadRadius: 1),
    ],
    raised: [
      BoxShadow(color: Color(0x33FFC63A), blurRadius: 0, spreadRadius: 1),
      BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 10)),
    ],
    float: [
      BoxShadow(color: Color(0x40FFC63A), blurRadius: 0, spreadRadius: 1),
      BoxShadow(color: Color(0xB3000000), blurRadius: 40, offset: Offset(0, 18)),
    ],
    glow: [
      BoxShadow(color: Color(0x80FFC63A), blurRadius: 30),
    ],
  );

  static List<BoxShadow> _lerp(List<BoxShadow> a, List<BoxShadow> b, double t) =>
      BoxShadow.lerpList(a, b, t) ?? (t < 0.5 ? a : b);

  @override
  ElevationTokens copyWith() => this;

  @override
  ElevationTokens lerp(ThemeExtension<ElevationTokens>? other, double t) {
    if (other is! ElevationTokens) return this;
    return ElevationTokens(
      rest: _lerp(rest, other.rest, t),
      raised: _lerp(raised, other.raised, t),
      float: _lerp(float, other.float, t),
      glow: _lerp(glow, other.glow, t),
    );
  }

  static const Color glowColor = Palette.marigold400;
}
