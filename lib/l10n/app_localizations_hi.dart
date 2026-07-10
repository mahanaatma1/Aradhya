// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class L10nHi extends L10n {
  L10nHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'आराध्य';

  @override
  String get verseOfTheDay => 'आज का श्लोक';

  @override
  String get explore => 'अन्वेषण करें';

  @override
  String streakDays(int count) {
    return '$count दिन की लय';
  }

  @override
  String get catScriptures => 'ग्रंथ';

  @override
  String get catAartis => 'आरती';

  @override
  String get catMantras => 'मंत्र';

  @override
  String get catQuiz => 'प्रश्न';

  @override
  String get catAstrology => 'ज्योतिष';

  @override
  String get catPanchang => 'पंचांग';

  @override
  String get catKatha => 'कथा';

  @override
  String get catPersonality => 'व्यक्तित्व';

  @override
  String get catTemples => 'मंदिर';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';
}
