import 'package:flutter/material.dart';

/// Font families (bundled for offline use — see pubspec.yaml).
///
/// Utsav: Yatra One (display) and Poppins (body) both ship Devanagari as well
/// as Latin, so a heading or a paragraph keeps one family in either language;
/// Noto Sans Devanagari stays as the guaranteed-coverage fallback.
abstract final class AppFonts {
  static const display = 'YatraOne';
  static const accent = 'YatraOne';
  static const body = 'Poppins';
  static const devanagari = 'Poppins';
  static const fallback = <String>['NotoSansDevanagari'];

  /// Families that carry their own Devanagari glyphs.
  static const bilingual = <String>{display, body};
}

/// The app's one type scale (TY-02).
///
/// Steps are a modular scale (~1.2) rounded to half-points, anchored on a 15pt
/// body. Every step carries an explicit `height` because Material's defaults
/// are tuned for Latin and leave Devanagari cramped — see [AppType.forScript]
/// and [ScriptText].
class AppType {
  AppType._();

  static const _fontStep = <String, double>{
    'micro': 10.5,
    'caption': 12.0,
    'body': 15.0,
    'bodyLarge': 16.5,
    'subtitle': 18.0,
    'title': 22.0,
    'headline': 26.0,
    'display': 32.0,
  };

  static double size(String role) => _fontStep[role] ?? _fontStep['body']!;

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

  /// Devanagari needs roughly 15–20% more leading than Latin at the same size
  /// (TY-01). One multiplier, applied to the Latin height for the role.
  static const devanagariLeadingBoost = 1.18;

  static double heightFor(String role, {required bool devanagari}) {
    final base = _latinHeight[role] ?? _latinHeight['body']!;
    return devanagari ? base * devanagariLeadingBoost : base;
  }

  static TextStyle style(
    String role, {
    bool devanagari = false,
    FontWeight? weight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: devanagari ? AppFonts.devanagari : null,
      fontFamilyFallback: AppFonts.fallback,
      fontSize: size(role),
      height: heightFor(role, devanagari: devanagari),
      fontWeight: weight,
      color: color,
    );
  }

  /// Adjust an existing style for script — keeps size/weight/colour, fixes
  /// the leading, and swaps in a Devanagari-capable family when the base one
  /// is not bilingual.
  static TextStyle forScript(TextStyle base, {required bool devanagari}) {
    if (!devanagari) return base;
    final h = base.height;
    final fam = base.fontFamily;
    return base.copyWith(
      fontFamily: fam != null && AppFonts.bilingual.contains(fam)
          ? fam
          : AppFonts.devanagari,
      fontFamilyFallback: AppFonts.fallback,
      height: h == null ? devanagariLeadingBoost : h * devanagariLeadingBoost,
    );
  }

  /// The [TextTheme] the app theme installs: every role wired to a scale step.
  static TextTheme textThemeFor(TextTheme base) {
    TextStyle? s(TextStyle? from, String role,
            {FontWeight? weight, String? family}) =>
        from?.copyWith(
          fontFamily: family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size(role),
          height: _latinHeight[role],
          fontWeight: weight,
        );

    return base.copyWith(
      displayLarge: s(base.displayLarge, 'display',
          weight: FontWeight.w400, family: AppFonts.display),
      displayMedium: s(base.displayMedium, 'display',
          weight: FontWeight.w400, family: AppFonts.display),
      headlineLarge: s(base.headlineLarge, 'headline',
          weight: FontWeight.w400, family: AppFonts.display),
      headlineMedium: s(base.headlineMedium, 'headline',
          weight: FontWeight.w400, family: AppFonts.display),
      headlineSmall: s(base.headlineSmall, 'title',
          weight: FontWeight.w400, family: AppFonts.display),
      titleLarge: s(base.titleLarge, 'title',
          weight: FontWeight.w400, family: AppFonts.display),
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
/// deciding from the content itself.
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
