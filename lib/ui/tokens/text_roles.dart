import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'type_tokens.dart';

/// Text roles Material's [TextTheme] lacks. Built from the one type scale.
@immutable
class TextRoles extends ThemeExtension<TextRoles> {
  /// Small tracked label above a section or card.
  final TextStyle eyebrow;

  /// Sanskrit / Hindi verse lines — the reader's primary voice.
  final TextStyle verse;

  /// Big tabular numerals (streaks, counts, scores).
  final TextStyle numeral;

  /// Pull-quotes and translations set in the display face.
  final TextStyle quote;

  const TextRoles({
    required this.eyebrow,
    required this.verse,
    required this.numeral,
    required this.quote,
  });

  factory TextRoles.forColors(ColorTokens c) => TextRoles(
        eyebrow: TextStyle(
          fontFamily: AppFonts.body,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: AppType.size('micro'),
          height: AppType.heightFor('micro', devanagari: false),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: c.inkFaint,
        ),
        verse: TextStyle(
          fontFamily: AppFonts.devanagari,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: AppType.size('subtitle'),
          height: AppType.heightFor('subtitle', devanagari: true),
          fontWeight: FontWeight.w500,
          color: c.ink,
        ),
        numeral: TextStyle(
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: AppType.size('display'),
          height: AppType.heightFor('display', devanagari: false),
          fontFeatures: const [FontFeature.tabularFigures()],
          color: c.ink,
        ),
        quote: TextStyle(
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: AppType.size('subtitle'),
          height: AppType.heightFor('subtitle', devanagari: false),
          color: c.inkSoft,
        ),
      );

  @override
  TextRoles copyWith() => this;

  @override
  TextRoles lerp(ThemeExtension<TextRoles>? other, double t) {
    if (other is! TextRoles) return this;
    return TextRoles(
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      verse: TextStyle.lerp(verse, other.verse, t)!,
      numeral: TextStyle.lerp(numeral, other.numeral, t)!,
      quote: TextStyle.lerp(quote, other.quote, t)!,
    );
  }
}
