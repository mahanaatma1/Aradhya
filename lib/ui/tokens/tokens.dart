import 'package:flutter/material.dart';

import 'category_tokens.dart';
import 'color_tokens.dart';
import 'elevation_tokens.dart';
import 'text_roles.dart';

export 'category_tokens.dart';
export 'color_tokens.dart';
export 'elevation_tokens.dart';
export 'motion_tokens.dart';
export 'palette.dart';
export 'radii.dart';
export 'space.dart';
export 'text_roles.dart';
export 'type_tokens.dart';

/// `context.colors.accent`, `context.elevation.raised`, `context.type.verse`,
/// `context.categories.quiz` — the one way screens reach design tokens.
extension TokensX on BuildContext {
  ThemeData get _theme => Theme.of(this);

  ColorTokens get colors =>
      _theme.extension<ColorTokens>() ??
      (_theme.brightness == Brightness.dark
          ? ColorTokens.dark
          : ColorTokens.light);

  ElevationTokens get elevation =>
      _theme.extension<ElevationTokens>() ??
      (_theme.brightness == Brightness.dark
          ? ElevationTokens.dark
          : ElevationTokens.light);

  TextRoles get type =>
      _theme.extension<TextRoles>() ?? TextRoles.forColors(colors);

  CategoryColors get categories =>
      _theme.extension<CategoryColors>() ?? CategoryColors.standard;

  bool get isDarkTheme => _theme.brightness == Brightness.dark;
}
