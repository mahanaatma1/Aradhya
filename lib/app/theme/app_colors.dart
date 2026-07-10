import 'package:flutter/material.dart';

/// Raw brand palette extracted from the DivyaVaani design system.
/// See reference/DESIGN-TOKENS.md. These are the source-of-truth constants;
/// screens should prefer [Theme.of(context)] / [CategoryColors] over these.
class AppColors {
  AppColors._();

  // Grounds — light
  static const paper = Color(0xFFFDF8F5);
  static const kraft = Color(0xFFF7ECDC);
  static const kraft2 = Color(0xFFFBEFDD);
  static const cardLight = Color(0xFFFFFDF9);

  // Grounds — dark (warm espresso, not flat black)
  static const paperDark = Color(0xFF1A110C);
  static const kraftDark = Color(0xFF23170F);
  static const kraft2Dark = Color(0xFF271A11);
  static const cardDark = Color(0xFF241811);

  // Ink / text
  static const inkLight = Color(0xFF3A2214);
  static const inkSoftLight = Color(0xFF6F4C37);
  static const inkFaintLight = Color(0xFF9A7C67);
  static const inkDark = Color(0xFFF2E6D9);
  static const inkSoftDark = Color(0xFFCDB29C);
  static const inkFaintDark = Color(0xFF9C8371);

  // Brand
  static const terracotta = Color(0xFFA73015);
  static const terracottaDark = Color(0xFF6E1F10);
  static const terracottaBright = Color(0xFFE35A34); // dark-theme accent
  static const gold = Color(0xFFB48B3E);
  static const goldBright = Color(0xFFC0A062);

  // Jewel accents
  static const dharmaPurple = Color(0xFF5A2EA8);
  static const deityRose = Color(0xFF9C2950);
  static const sacredGreen = Color(0xFF25533F);
}
