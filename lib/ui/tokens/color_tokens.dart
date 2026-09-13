import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Semantic colour roles. Installed on [ThemeData.extensions] so the
/// Light/Dark/System switch cross-fades every role through [lerp].
@immutable
class ColorTokens extends ThemeExtension<ColorTokens> {
  // Grounds
  final Color canvas;
  final Color canvasDeep;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color scrim;

  // Ink
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color inkOnAccent;
  final Color inkOnDeep;

  // Lines
  final Color border;
  final Color borderStrong;
  final Color focusRing;

  // Brand & sacred accents
  final Color accent;
  final Color accentSoft;
  final Color accentStrong;
  final Color gold;
  final Color goldSoft;
  final Color flame;
  final Color lotus;
  final Color tulsi;
  final Color cosmos;
  final Color glow;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Gradients (three stops each)
  final List<Color> skyGradient;
  final List<Color> accentGradient;
  final List<Color> goldGradient;
  final List<Color> deepGradient;

  const ColorTokens({
    required this.canvas,
    required this.canvasDeep,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.scrim,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.inkOnAccent,
    required this.inkOnDeep,
    required this.border,
    required this.borderStrong,
    required this.focusRing,
    required this.accent,
    required this.accentSoft,
    required this.accentStrong,
    required this.gold,
    required this.goldSoft,
    required this.flame,
    required this.lotus,
    required this.tulsi,
    required this.cosmos,
    required this.glow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.skyGradient,
    required this.accentGradient,
    required this.goldGradient,
    required this.deepGradient,
  });

  static const light = ColorTokens(
    canvas: Palette.ivory100,
    canvasDeep: Palette.night900,
    surface: Palette.white,
    surfaceRaised: Palette.ivory50,
    surfaceSunken: Palette.ivory200,
    scrim: Color(0x8C241214),
    ink: Palette.plum900,
    inkSoft: Palette.plum700,
    inkFaint: Palette.plum500,
    inkOnAccent: Palette.white,
    inkOnDeep: Palette.cream100,
    border: Color(0x2ED8321E),
    borderStrong: Color(0x59D8321E),
    focusRing: Palette.peacock500,
    accent: Palette.vermilion500,
    accentSoft: Palette.vermilion50,
    accentStrong: Palette.vermilion600,
    gold: Palette.marigold500,
    goldSoft: Palette.marigold50,
    flame: Palette.flame400,
    lotus: Palette.magenta500,
    tulsi: Palette.tulsi500,
    cosmos: Palette.violet500,
    glow: Palette.marigold400,
    success: Palette.tulsi500,
    warning: Palette.marigold600,
    danger: Palette.vermilion600,
    info: Palette.peacock500,
    skyGradient: [Palette.marigold400, Palette.flame400, Palette.vermilion500],
    accentGradient: [
      Palette.vermilion400,
      Palette.vermilion500,
      Palette.vermilion600
    ],
    goldGradient: [Palette.marigold300, Palette.marigold500, Palette.marigold600],
    deepGradient: [Palette.magenta500, Palette.magenta700, Palette.night950],
  );

  static const dark = ColorTokens(
    canvas: Palette.night900,
    canvasDeep: Palette.night950,
    surface: Palette.night800,
    surfaceRaised: Palette.night700,
    surfaceSunken: Palette.night950,
    scrim: Color(0x99000000),
    ink: Palette.cream100,
    inkSoft: Palette.cream300,
    inkFaint: Palette.cream500,
    inkOnAccent: Palette.white,
    inkOnDeep: Palette.cream100,
    border: Color(0x40FFC63A),
    borderStrong: Color(0x73FFC63A),
    focusRing: Palette.peacock400,
    accent: Palette.vermilion400,
    accentSoft: Color(0xFF4A1A14),
    accentStrong: Palette.vermilion300,
    gold: Palette.marigold400,
    goldSoft: Color(0xFF4A3A10),
    flame: Palette.flame300,
    lotus: Palette.magenta400,
    tulsi: Palette.tulsi400,
    cosmos: Palette.violet400,
    glow: Palette.marigold400,
    success: Palette.tulsi400,
    warning: Palette.marigold300,
    danger: Palette.vermilion300,
    info: Palette.peacock400,
    skyGradient: [Palette.magenta700, Palette.magenta500, Palette.vermilion400],
    accentGradient: [
      Palette.vermilion300,
      Palette.vermilion400,
      Palette.vermilion500
    ],
    goldGradient: [Palette.marigold300, Palette.marigold400, Palette.marigold500],
    deepGradient: [Palette.night700, Palette.night900, Palette.night950],
  );

  bool get isDark => canvas.computeLuminance() < 0.2;

  @override
  ColorTokens copyWith({Color? accent}) => accent == null ? this : _with(accent);

  ColorTokens _with(Color a) => ColorTokens(
        canvas: canvas,
        canvasDeep: canvasDeep,
        surface: surface,
        surfaceRaised: surfaceRaised,
        surfaceSunken: surfaceSunken,
        scrim: scrim,
        ink: ink,
        inkSoft: inkSoft,
        inkFaint: inkFaint,
        inkOnAccent: inkOnAccent,
        inkOnDeep: inkOnDeep,
        border: border,
        borderStrong: borderStrong,
        focusRing: focusRing,
        accent: a,
        accentSoft: accentSoft,
        accentStrong: accentStrong,
        gold: gold,
        goldSoft: goldSoft,
        flame: flame,
        lotus: lotus,
        tulsi: tulsi,
        cosmos: cosmos,
        glow: glow,
        success: success,
        warning: warning,
        danger: danger,
        info: info,
        skyGradient: skyGradient,
        accentGradient: accentGradient,
        goldGradient: goldGradient,
        deepGradient: deepGradient,
      );

  static List<Color> _lerpList(List<Color> a, List<Color> b, double t) =>
      List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);

  @override
  ColorTokens lerp(ThemeExtension<ColorTokens>? other, double t) {
    if (other is! ColorTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColorTokens(
      canvas: c(canvas, other.canvas),
      canvasDeep: c(canvasDeep, other.canvasDeep),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      scrim: c(scrim, other.scrim),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkFaint: c(inkFaint, other.inkFaint),
      inkOnAccent: c(inkOnAccent, other.inkOnAccent),
      inkOnDeep: c(inkOnDeep, other.inkOnDeep),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      focusRing: c(focusRing, other.focusRing),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      accentStrong: c(accentStrong, other.accentStrong),
      gold: c(gold, other.gold),
      goldSoft: c(goldSoft, other.goldSoft),
      flame: c(flame, other.flame),
      lotus: c(lotus, other.lotus),
      tulsi: c(tulsi, other.tulsi),
      cosmos: c(cosmos, other.cosmos),
      glow: c(glow, other.glow),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      info: c(info, other.info),
      skyGradient: _lerpList(skyGradient, other.skyGradient, t),
      accentGradient: _lerpList(accentGradient, other.accentGradient, t),
      goldGradient: _lerpList(goldGradient, other.goldGradient, t),
      deepGradient: _lerpList(deepGradient, other.deepGradient, t),
    );
  }

  /// Every colour role, for tests that must touch each field.
  List<Color> get allColors => [
        canvas, canvasDeep, surface, surfaceRaised, surfaceSunken, scrim,
        ink, inkSoft, inkFaint, inkOnAccent, inkOnDeep,
        border, borderStrong, focusRing,
        accent, accentSoft, accentStrong, gold, goldSoft, flame, lotus, tulsi,
        cosmos, glow, success, warning, danger, info,
        ...skyGradient, ...accentGradient, ...goldGradient, ...deepGradient,
      ];

  /// WCAG contrast ratio between two opaque colours.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static double lerpAlpha(double a, double b, double t) => lerpDouble(a, b, t)!;
}
