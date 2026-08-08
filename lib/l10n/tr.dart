/// The app's bilingual convention, in one place.
///
/// ## Why this and not the ARB
///
/// The app had two systems: a 19-key generated ARB, and inline
/// `hi ? 'हिंदी' : 'English'` ternaries used for effectively everything else.
/// Two conventions is the actual problem — a translator cannot find the
/// strings, and a developer has to guess which system a given screen uses.
///
/// The ternary won because it is what >95% of the codebase already does, and
/// because this app's copy is genuinely *paired*: nearly every string is
/// authored in both languages at the same moment by the same person, and the
/// Hindi is often not a translation but a different register (देवनागरी
/// scripture vocabulary rather than rendered English). An ARB round-trip adds
/// a key-lookup indirection for no benefit when the pair is written together.
///
/// The ARB is retained for the handful of strings that are genuinely
/// structural (app name, category labels reused across screens) — see
/// `app_en.arb`. Everything else uses [tr] / [BuildContextTr.tr].
///
/// ## Rules
///
/// 1. English first, Hindi second: `tr(hi, 'Search', 'खोजें')`.
/// 2. Never fall back silently. A missing Hindi string should look wrong in
///    review, not quietly render English to a Hindi reader.
/// 3. Lay screens out in **Hindi first**, then check English — Devanagari runs
///    ~15-20% taller and its words are longer, so English-first layouts overflow
///    the moment the language is switched.
library;

import 'package:flutter/widgets.dart';

/// Pick the string for the active language.
///
/// The `hi` flag comes from `isHindiProvider` in a widget, or from
/// `Localizations.localeOf(context)` outside one.
String tr(bool hi, String en, String hiText) =>
    hi && hiText.isNotEmpty ? hiText : en;

extension BuildContextTr on BuildContext {
  /// True when the active locale is Hindi.
  ///
  /// Use this in plain widgets. In a `ConsumerWidget`, prefer
  /// `ref.watch(isHindiProvider)` so the rebuild is driven by the same provider
  /// that the in-app language switcher writes to.
  bool get isHindi => Localizations.localeOf(this).languageCode == 'hi';

  /// `context.tr('Search', 'खोजें')`
  String tr(String en, String hiText) => isHindi && hiText.isNotEmpty ? hiText : en;
}

/// A string that carries both languages, for use in `const` data tables
/// (navigation labels, module registries, enum-like lists) where a
/// `BuildContext` is not available at construction time.
@immutable
class Bilingual {
  final String en;
  final String hi;
  const Bilingual(this.en, this.hi);

  String call(bool isHindi) => isHindi && hi.isNotEmpty ? hi : en;

  @override
  String toString() => en;
}
