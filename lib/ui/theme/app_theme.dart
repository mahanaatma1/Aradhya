import 'package:flutter/material.dart';

import '../motion/transitions.dart';
import '../tokens/tokens.dart';

/// Builds the two [ThemeData]s from the token sets. Cached: `MaterialApp`
/// rebuilds on every locale/theme change and must not rebuild the theme tree.
class AppTheme {
  AppTheme._();

  static final ThemeData _light = _build(
    ColorTokens.light,
    ElevationTokens.light,
    Brightness.light,
  );
  static final ThemeData _dark = _build(
    ColorTokens.dark,
    ElevationTokens.dark,
    Brightness.dark,
  );

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  static ThemeData _build(
    ColorTokens c,
    ElevationTokens e,
    Brightness brightness,
  ) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.inkOnAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accentStrong,
      secondary: c.gold,
      onSecondary: Palette.plum900,
      secondaryContainer: c.goldSoft,
      onSecondaryContainer: Palette.marigold700,
      tertiary: c.info,
      onTertiary: c.inkOnAccent,
      error: c.danger,
      onError: c.inkOnAccent,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSoft,
      surfaceContainerHighest: c.surfaceSunken,
      surfaceContainerLow: c.surfaceRaised,
      outline: c.borderStrong,
      outlineVariant: c.border,
      scrim: c.scrim,
      shadow: Palette.plum900,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.canvas,
      fontFamily: AppFonts.body,
      splashFactory: InkSparkle.splashFactory,
      extensions: [
        c,
        e,
        TextRoles.forColors(c),
        CategoryColors.standard,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: AppPageTransitions(),
        TargetPlatform.iOS: AppPageTransitions(),
        TargetPlatform.macOS: AppPageTransitions(),
        TargetPlatform.windows: AppPageTransitions(),
        TargetPlatform.linux: AppPageTransitions(),
      }),
    );

    final textTheme = AppType.textThemeFor(base.textTheme)
        .apply(bodyColor: c.ink, displayColor: c.ink);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rLg),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surfaceSunken,
        selectedColor: c.accentSoft,
        labelStyle: textTheme.labelLarge?.copyWith(color: c.ink),
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      dividerColor: c.border,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rSheet),
        showDragHandle: true,
        dragHandleColor: c.inkFaint,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rLg),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.canvasDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.inkOnDeep),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rMd),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.inkOnAccent,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          side: BorderSide(color: c.borderStrong, width: 1.5),
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(44, 44),
        ),
      ),
      iconTheme: IconThemeData(color: c.inkSoft, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: c.inkSoft,
        textColor: c.ink,
        shape: const RoundedRectangleBorder(borderRadius: Radii.rMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.inkOnAccent : c.inkFaint),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.accent : c.surfaceSunken),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
      ),
    );
  }
}
