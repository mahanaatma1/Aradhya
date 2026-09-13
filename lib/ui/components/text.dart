import 'package:flutter/material.dart';

import '../../l10n/tr.dart';
import '../tokens/tokens.dart';

export '../tokens/type_tokens.dart' show ScriptText;

/// Renders the active language of a [Bilingual] pair with script-aware type.
class BiText extends StatelessWidget {
  const BiText(this.text,
      {super.key, this.style, this.maxLines, this.overflow, this.textAlign});
  final Bilingual text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => ScriptText(
        text.of(context),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
}

/// Small tracked label above a card or section. Never uppercased for Hindi.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final deva = ScriptText.isDevanagari(text);
    final base = context.type.eyebrow;
    return Text(
      deva ? text : text.toUpperCase(),
      style: AppType.forScript(
        base.copyWith(
            color: color, letterSpacing: deva ? 0.2 : base.letterSpacing),
        devanagari: deva,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A big tabular number.
class Numeral extends StatelessWidget {
  const Numeral(this.text, {super.key, this.color, this.size});
  final String text;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: context.type.numeral.copyWith(color: color, fontSize: size),
      );
}

/// A verse line in the reader voice.
class VerseText extends StatelessWidget {
  const VerseText(this.text, {super.key, this.color, this.textAlign});
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => ScriptText(
        text,
        style: context.type.verse.copyWith(color: color),
        textAlign: textAlign,
      );
}

extension BilingualOf on Bilingual {
  String of(BuildContext context) => context.isHindi && hi.isNotEmpty ? hi : en;
}
