import 'package:flutter/material.dart';

import 'palette.dart';

/// A single colour-coded content category (the gradient tiles on Home).
class CategoryStyle {
  final List<Color> gradient;
  const CategoryStyle(this.gradient);

  LinearGradient get linear => LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color get start => gradient.first;
  Color get end => gradient.last;

  static CategoryStyle lerp(CategoryStyle a, CategoryStyle b, double t) =>
      CategoryStyle(List.generate(
          a.gradient.length, (i) => Color.lerp(a.gradient[i], b.gradient[i], t)!));
}

/// Theme extension holding the category gradients. Every tile carries light
/// text, so the same values serve both themes; the field names are the public
/// contract (`SearchKinds`, `RelatedRail` and the Gyan screens read them).
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

  // Utsav: four festival families. Text & place = vermilion/copper, devotion =
  // flame/magenta, play & practice = peacock/tulsi, knowledge = violet.
  static const standard = CategoryColors(
    scriptures: CategoryStyle([Palette.vermilion400, Palette.vermilion600]),
    aartis: CategoryStyle([Palette.flame400, Palette.flame600]),
    mantras: CategoryStyle([Palette.magenta400, Palette.magenta600]),
    quiz: CategoryStyle([Palette.peacock400, Palette.peacock600]),
    astrology: CategoryStyle([Palette.violet400, Palette.violet600]),
    panchang: CategoryStyle([Palette.flame400, Palette.vermilion600]),
    katha: CategoryStyle([Palette.flame500, Palette.vermilion700]),
    personality: CategoryStyle([Palette.magenta500, Palette.magenta700]),
    temples: CategoryStyle([Palette.copper500, Palette.copper700]),
    gyan: CategoryStyle([Palette.violet500, Palette.violet700]),
    srishty: CategoryStyle([Palette.violet600, Palette.violet800]),
    epics: CategoryStyle([Palette.vermilion600, Palette.magenta700]),
    sadhana: CategoryStyle([Palette.tulsi500, Palette.tulsi600]),
  );

  List<CategoryStyle> get all => [
        scriptures, aartis, mantras, quiz, astrology, panchang, katha,
        personality, temples, gyan, srishty, epics, sadhana,
      ];

  @override
  CategoryColors copyWith() => this;

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    if (other is! CategoryColors) return this;
    CategoryStyle l(CategoryStyle a, CategoryStyle b) =>
        CategoryStyle.lerp(a, b, t);
    return CategoryColors(
      scriptures: l(scriptures, other.scriptures),
      aartis: l(aartis, other.aartis),
      mantras: l(mantras, other.mantras),
      quiz: l(quiz, other.quiz),
      astrology: l(astrology, other.astrology),
      panchang: l(panchang, other.panchang),
      katha: l(katha, other.katha),
      personality: l(personality, other.personality),
      temples: l(temples, other.temples),
      gyan: l(gyan, other.gyan),
      srishty: l(srishty, other.srishty),
      epics: l(epics, other.epics),
      sadhana: l(sadhana, other.sadhana),
    );
  }
}
