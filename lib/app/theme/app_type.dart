import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The app's one type scale (TY-02).
///
/// Before this, sizes ran 8–96 across ~850 call sites with no system. New code
/// should reach for a [TextTheme] role via `Theme.of(context).textTheme` — the
/// roles below are what `AppTheme` installs — or, for the handful of genuinely
/// bespoke cases, one of the named [AppType] steps rather than a bare number.
///
/// Steps are a modular scale (~1.2) rounded to half-points, anchored on a 15pt
/// body. Every step carries an explicit `height` (line-height as a multiple of
/// font size) because Material's defaults are tuned for Latin and leave
/// Devanagari cramped — see [AppType.forScript] and [ScriptText].
class AppType {
  AppType._();

  // The scale. Name by role, not by size, so a later retune moves one constant.
  static const _fontStep = <String, double>{
    'micro': 10.5, // timestamps, chip counters
    'caption': 12.0, // metadata under a title
    'body': 15.0, // running text — the anchor
    'bodyLarge': 16.5, // reader body, comfortable
    'subtitle': 18.0, // card titles
    'title': 22.0, // screen section headings
    'headline': 26.0, // screen titles
    'display': 32.0, // hero numerals, splash
  };

  static double size(String role) =>
      _fontStep[role] ?? _fontStep['body']!;

  // Latin line-heights. Tighter as size grows — display text does not want the
  // same ratio as a caption.
  static const _latinHeight = <String, double>{
    'micro': 1.35,
    'caption': 1.35,
    'body': 1.45,
    'bodyLarge': 1.55,
    'subtitle': 1.30,
    'title': 1.22,
    'headline': 1.18,
    'display': 1.10,
  };

  /// Devanagari needs roughly 15–20% more leading than Latin at the same size —
  /// the conjuncts and the ि/ी/ै matras stack above and below the baseline
  /// (TY-01). One multiplier, applied to the Latin height for the role.
  static const devanagariLeadingBoost = 1.18;

  static double heightFor(String role, {required bool devanagari}) {
    final base = _latinHeight[role] ?? _latinHeight['body']!;
    return devanagari ? base * devanagariLeadingBoost : base;
  }

  /// A ready [TextStyle] for a scale step. [devanagari] switches both the font
  /// family and the line-height; pass it when the string is Hindi/Sanskrit.
  static TextStyle style(
    String role, {
    bool devanagari = false,
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: devanagari ? AppFonts.devanagari : null,
      fontSize: size(role),
      height: heightFor(role, devanagari: devanagari),
      fontWeight: weight,
      color: color,
    );
  }

  /// Adjust an existing style for script — keeps its size/weight/color, fixes
  /// the family and the leading. Use when you already have a [TextTheme] role
  /// and just need it to render Devanagari correctly.
  static TextStyle forScript(TextStyle base, {required bool devanagari}) {
    if (!devanagari) return base;
    final h = base.height;
    return base.copyWith(
      fontFamily: AppFonts.devanagari,
      height: h == null ? devanagariLeadingBoost : h * devanagariLeadingBoost,
    );
  }

  /// The [TextTheme] `AppTheme` installs: every role wired to a scale step with
  /// its Latin line-height. Screens that read `textTheme.bodyMedium` etc. get
  /// the scale for free.
  static TextTheme textThemeFor(TextTheme base) {
    TextStyle? s(TextStyle? from, String role,
            {FontWeight? weight, String? family}) =>
        from?.copyWith(
          fontFamily: family,
          fontSize: size(role),
          height: _latinHeight[role],
          fontWeight: weight,
        );

    return base.copyWith(
      displayLarge: s(base.displayLarge, 'display',
          weight: FontWeight.w600, family: AppFonts.display),
      displayMedium: s(base.displayMedium, 'display',
          weight: FontWeight.w600, family: AppFonts.display),
      headlineLarge: s(base.headlineLarge, 'headline',
          weight: FontWeight.w600, family: AppFonts.display),
      headlineMedium: s(base.headlineMedium, 'headline',
          weight: FontWeight.w600, family: AppFonts.display),
      headlineSmall: s(base.headlineSmall, 'title',
          weight: FontWeight.w600, family: AppFonts.display),
      titleLarge: s(base.titleLarge, 'title',
          weight: FontWeight.w600, family: AppFonts.display),
      titleMedium: s(base.titleMedium, 'subtitle', weight: FontWeight.w600),
      titleSmall: s(base.titleSmall, 'caption', weight: FontWeight.w600),
      bodyLarge: s(base.bodyLarge, 'bodyLarge'),
      bodyMedium: s(base.bodyMedium, 'body'),
      bodySmall: s(base.bodySmall, 'caption'),
      labelLarge: s(base.labelLarge, 'caption', weight: FontWeight.w600),
      labelMedium: s(base.labelMedium, 'micro', weight: FontWeight.w600),
      labelSmall: s(base.labelSmall, 'micro'),
    );
  }
}

/// Renders [text] with the right font family and leading for its script,
/// deciding from the content itself. Use for any string that may be Hindi or
/// Sanskrit — a bilingual title, a verse, a user's name.
class ScriptText extends StatelessWidget {
  const ScriptText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// True when the string contains any Devanagari codepoint (U+0900–U+097F).
  static bool isDevanagari(String s) {
    for (final r in s.runes) {
      if (r >= 0x0900 && r <= 0x097F) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final deva = isDevanagari(text);
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      text,
      style: AppType.forScript(base, devanagari: deva),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
