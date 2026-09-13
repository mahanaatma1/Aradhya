import 'package:flutter/material.dart';

/// Raw brand palette — the "Sandhyā" identity (2026 rebrand off Ishvarvaani's
/// terracotta/cream/gold, which these constants used to hold verbatim).
/// Built from the two hours the app is actually used in: before sunrise,
/// after sunset. See reference/DESIGN-TOKENS.md for the retired palette this
/// replaces. Constant *names* are kept stable across the rebrand — only the
/// hex values changed — since ~170 call sites reference them by name;
/// screens should still prefer [Theme.of(context)] / [CategoryColors] over
/// reaching for these directly.
class AppColors {
  AppColors._();

  // Grounds — light. Warm paper, not the old cream (which read as the same
  // "temple brochure" warm-cream cluster common to devotional apps).
  static const paper = Color(0xFFF7F5F2);
  static const kraft = Color(0xFFEFEBE4);
  static const kraft2 = Color(0xFFF1E9DD);
  static const cardLight = Color(0xFFFFFFFF);

  // Grounds — dark. Ink is the blended pink/orange/red/yellow warm dark —
  // the "sandhyā" anchor color — not a neutral near-black.
  static const paperDark = Color(0xFF22110D);
  static const kraftDark = Color(0xFF2C1712);
  static const kraft2Dark = Color(0xFF351C15);
  static const cardDark = Color(0xFF3A1A16);

  // Ink / text
  static const inkLight = Color(0xFF241713);
  static const inkSoftLight = Color(0xFF6B5B52);
  static const inkFaintLight = Color(0xFFA89A8F);
  static const inkDark = Color(0xFFF7EFE6);
  static const inkSoftDark = Color(0xFFD9C2B4);
  static const inkFaintDark = Color(0xFF9C8B80);

  // Brand. `terracotta` is now brass — the primary accent — kept under its
  // old name so every existing call site re-themes without a rename pass.
  static const terracotta = Color(0xFFC97A3E);
  static const terracottaDark = Color(0xFF9C5A28);
  static const terracottaBright = Color(0xFFE8B98A); // dark-theme accent
  static const gold = Color(0xFF9C5A28);
  static const goldBright = Color(0xFFC97A3E);

  // Jewel accents. `dharmaPurple`/`deityRose`/`sacredGreen` keep their old
  // names (Astrology/Knowledge violet, Devotion ember, Sadhana sage).
  static const dharmaPurple = Color(0xFF6C5A9C);
  static const deityRose = Color(0xFFD9748C);
  static const sacredGreen = Color(0xFF5E8C74);
}
