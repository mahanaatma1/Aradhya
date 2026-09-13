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

  // Gyan surfaces. Two modules deliberately reuse existing gradients instead of
  // getting their own — Festivals rides `panchang` because it is the same
  // calendar domain, and Dharma rides `personality` because it is the same
  // reflective register. Inventing distinct colours there would imply a
  // separation that does not exist.
  final CategoryStyle gyan;
  final CategoryStyle srishty;
  final CategoryStyle epics;
  final CategoryStyle sadhana;

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
    required this.gyan,
    required this.srishty,
    required this.epics,
    required this.sadhana,
  });

  // Sandhyā rebrand: every gradient below is drawn from one of four families
  // (brass, ember, sage, violet) plus two muted extensions (indigo, umber)
  // used only where a fifth/sixth hue is truly needed to stay distinguishable.
  // Previously each category had an unrelated hue of its own — 13 different
  // colors that never read as one designed app. Categories in the same
  // register now share a family and differ by depth/warmth, not by hue:
  // Scriptures/Katha/Epics/Temples (brass-toned — the "text & place" group),
  // Aartis/Mantras/Panchang (ember-toned — the "devotional practice" group),
  // Quiz/Sadhana (sage — the "practice & play" group),
  // Astrology/Gyan/Srishty/Personality (violet — the "knowledge" group).
  static const standard = CategoryColors(
    scriptures: CategoryStyle([Color(0xFFC97A3E), Color(0xFF6E3A1F)]),
    aartis: CategoryStyle([Color(0xFFE39B6B), Color(0xFF9C5A28)]),
    mantras: CategoryStyle([Color(0xFFD9748C), Color(0xFF7C2E44)]),
    quiz: CategoryStyle([Color(0xFF6FA88C), Color(0xFF2F5E48)]),
    astrology: CategoryStyle([Color(0xFF8778B8), Color(0xFF4E3F78)]),
    panchang: CategoryStyle([Color(0xFFD9748C), Color(0xFFA5445C)]),
    katha: CategoryStyle([Color(0xFF9C8250), Color(0xFF5C4A28)]),
    personality: CategoryStyle([Color(0xFF6C5A9C), Color(0xFF3F3363)]),
    temples: CategoryStyle([Color(0xFF9C5A28), Color(0xFF4A2E18)]),
    gyan: CategoryStyle([Color(0xFF6C5A9C), Color(0xFF352A54)]),
    srishty: CategoryStyle([Color(0xFF4E3F78), Color(0xFF241C3E)]),
    epics: CategoryStyle([Color(0xFF8A6A4F), Color(0xFF4A3220)]),
    sadhana: CategoryStyle([Color(0xFF5E8C74), Color(0xFF33543F)]),
  );

  @override
  CategoryColors copyWith() => this;

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) => this;
}
