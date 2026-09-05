import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_type.dart';
import 'category_colors.dart';

/// Font families (bundled for offline use — see pubspec.yaml).
class AppFonts {
  AppFonts._();
  static const display = 'Eczar'; // headings & verse
  static const accent = 'Ramaraja'; // quotes / flourishes
  static const body = 'Inter'; // UI
  static const devanagari = 'NotoSansDevanagari'; // Hindi / Sanskrit
}

class AppTheme {
  AppTheme._();

  static const _radiusLg = 24.0;

  static ThemeData light() => _build(
        brightness: Brightness.light,
        paper: AppColors.paper,
        card: AppColors.cardLight,
        ink: AppColors.inkLight,
        inkSoft: AppColors.inkSoftLight,
        inkFaint: AppColors.inkFaintLight,
        primary: AppColors.terracotta,
        onPrimary: const Color(0xFFFFF4E9),
        secondary: AppColors.goldBright,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        paper: AppColors.paperDark,
        card: AppColors.cardDark,
        ink: AppColors.inkDark,
        inkSoft: AppColors.inkSoftDark,
        inkFaint: AppColors.inkFaintDark,
        primary: AppColors.terracottaBright,
        onPrimary: const Color(0xFF2A1109),
        secondary: AppColors.goldBright,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color paper,
    required Color card,
    required Color ink,
    required Color inkSoft,
    required Color inkFaint,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: brightness == Brightness.light
          ? const Color(0xFF2A1B06)
          : const Color(0xFF2A1B06),
      error: const Color(0xFFC0392B),
      onError: Colors.white,
      surface: card,
      onSurface: ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      fontFamily: AppFonts.body,
      extensions: const [CategoryColors.standard],
      // Smooth, consistent page transitions on every platform.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _SmoothPageTransitions(),
        TargetPlatform.iOS: _SmoothPageTransitions(),
        TargetPlatform.macOS: _SmoothPageTransitions(),
        TargetPlatform.windows: _SmoothPageTransitions(),
        TargetPlatform.linux: _SmoothPageTransitions(),
      }),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, ink, inkSoft),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: brightness == Brightness.light
            ? AppColors.kraft
            : AppColors.kraftDark,
      ),
      dividerColor: inkFaint.withValues(alpha: 0.24),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color ink, Color inkSoft) {
    // The one type scale — sizes and Latin line-heights per role. See
    // app_type.dart. Devanagari leading is boosted at render time by
    // ScriptText / AppType.forScript.
    return AppType.textThemeFor(base).apply(bodyColor: ink, displayColor: ink);
  }
}

/// A gentle fade + slight upward slide for every route push — softer and more
/// consistent than the default platform transitions.
class _SmoothPageTransitions extends PageTransitionsBuilder {
  const _SmoothPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
