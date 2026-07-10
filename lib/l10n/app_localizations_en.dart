// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aradhya';

  @override
  String get verseOfTheDay => 'Verse of the day';

  @override
  String get explore => 'Explore';

  @override
  String streakDays(int count) {
    return '$count day streak';
  }

  @override
  String get catScriptures => 'Scriptures';

  @override
  String get catAartis => 'Aartis';

  @override
  String get catMantras => 'Mantras';

  @override
  String get catQuiz => 'Quiz';

  @override
  String get catAstrology => 'Astrology';

  @override
  String get catPanchang => 'Panchang';

  @override
  String get catKatha => 'Katha';

  @override
  String get catPersonality => 'Personality';

  @override
  String get catTemples => 'Temples';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';
}
