import 'package:flutter/material.dart';

/// A single color-coded content category (the gradient tiles on Home).
class CategoryStyle {
  final List<Color> gradient;
  const CategoryStyle(this.gradient);

  LinearGradient get linear => LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Theme extension holding the fixed category gradients. These read on both
/// light and dark grounds because every tile carries light text, so the same
/// values are used for both themes.
@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  final CategoryStyle scriptures;
  final CategoryStyle aartis;
  final CategoryStyle mantras;
  final CategoryStyle quiz;
  final CategoryStyle astrology;
  final CategoryStyle panchang;
  final CategoryStyle katha;
  final CategoryStyle personality;
  final CategoryStyle temples;

  const CategoryColors({
    required this.scriptures,
    required this.aartis,
    required this.mantras,
    required this.quiz,
    required this.astrology,
    required this.panchang,
    required this.katha,
    required this.personality,
    required this.temples,
  });

  static const standard = CategoryColors(
    scriptures: CategoryStyle([Color(0xFFA73015), Color(0xFF6E1F10)]),
    aartis: CategoryStyle([Color(0xFFD4AF37), Color(0xFFA54325)]),
    mantras: CategoryStyle([Color(0xFFC7567F), Color(0xFF7C1F44)]),
    quiz: CategoryStyle([Color(0xFF3E8E6E), Color(0xFF204B39)]),
    astrology: CategoryStyle([Color(0xFF8B6AC7), Color(0xFF4A2493)]),
    panchang: CategoryStyle([Color(0xFFE0762A), Color(0xFFA7430F)]),
    katha: CategoryStyle([Color(0xFF5C6BC0), Color(0xFF2F3B8E)]),
    personality: CategoryStyle([Color(0xFFA85A8C), Color(0xFF5C2549)]),
    temples: CategoryStyle([Color(0xFF9C7A3C), Color(0xFF5C3B28)]),
  );

  @override
  CategoryColors copyWith() => this;

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) => this;
}
