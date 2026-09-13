import 'package:flutter/material.dart';

/// Raw colour ramps for the "Utsav" identity — the only file in the app that
/// may hold a hex literal. Everything else reads a semantic role from
/// [ColorTokens] or a category from [CategoryColors].
abstract final class Palette {
  // Grounds
  static const ivory50 = Color(0xFFFFFDF8);
  static const ivory100 = Color(0xFFFFF8EC);
  static const ivory200 = Color(0xFFFFEFD2);
  static const ivory300 = Color(0xFFF7E3BF);
  static const white = Color(0xFFFFFFFF);

  static const night950 = Color(0xFF130609);
  static const night900 = Color(0xFF1C0A10);
  static const night800 = Color(0xFF2B1219);
  static const night700 = Color(0xFF3D1B26);

  // Ink
  static const plum900 = Color(0xFF241214);
  static const plum700 = Color(0xFF5E3D42);
  static const plum500 = Color(0xFF9A7A80);
  static const plum300 = Color(0xFFC9B0B5);
  static const cream100 = Color(0xFFFFF3E4);
  static const cream300 = Color(0xFFE3C6B3);
  static const cream500 = Color(0xFFA88A8F);

  // Vermilion — the primary accent
  static const vermilion300 = Color(0xFFFF7A5C);
  static const vermilion400 = Color(0xFFFF5A3C);
  static const vermilion500 = Color(0xFFD8321E);
  static const vermilion600 = Color(0xFFB0261A);
  static const vermilion700 = Color(0xFF7E1A12);
  static const vermilion50 = Color(0xFFFFE2DA);

  // Marigold — ornament and glow
  static const marigold300 = Color(0xFFFFD866);
  static const marigold400 = Color(0xFFFFC63A);
  static const marigold500 = Color(0xFFF5B31E);
  static const marigold600 = Color(0xFFD99A0C);
  static const marigold700 = Color(0xFFA87200);
  static const marigold50 = Color(0xFFFFF0C2);

  // Saffron-orange — flame, aartis
  static const flame300 = Color(0xFFFF9A5C);
  static const flame400 = Color(0xFFFF7A3C);
  static const flame500 = Color(0xFFE8552F);
  static const flame600 = Color(0xFFC25A12);

  // Peacock — play, info, focus
  static const peacock300 = Color(0xFF6FD8DD);
  static const peacock400 = Color(0xFF2CC2C9);
  static const peacock500 = Color(0xFF0F6E73);
  static const peacock600 = Color(0xFF0B5459);
  static const peacock700 = Color(0xFF073A3E);

  // Magenta — devotion, mantras, lotus
  static const magenta400 = Color(0xFFE04A93);
  static const magenta500 = Color(0xFFB5236B);
  static const magenta600 = Color(0xFF8C1852);
  static const magenta700 = Color(0xFF5B1020);

  // Violet — knowledge, jyotish
  static const violet400 = Color(0xFF9A6BD1);
  static const violet500 = Color(0xFF6B3FA0);
  static const violet600 = Color(0xFF4E2C78);
  static const violet700 = Color(0xFF33194F);
  static const violet800 = Color(0xFF1F1040);

  // Tulsi — sadhana, success
  static const tulsi400 = Color(0xFF5EC08A);
  static const tulsi500 = Color(0xFF2E8B57);
  static const tulsi600 = Color(0xFF1F5A3A);

  // Copper — temples, place
  static const copper500 = Color(0xFFC8702E);
  static const copper700 = Color(0xFF7A3512);
}
