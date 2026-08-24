import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:divyavaani/app/theme/app_theme.dart';
import 'package:divyavaani/core/user/user_prefs.dart';
import 'package:divyavaani/features/related/related_models.dart';
import 'package:divyavaani/features/related/related_rail.dart';
import 'package:divyavaani/features/scriptures/scripture_models.dart';
import 'package:divyavaani/features/scriptures/scripture_providers.dart';
import 'package:divyavaani/features/scriptures/section_reader_screen.dart';
import 'package:divyavaani/features/scriptures/verse_tabs.dart';
import 'package:divyavaani/l10n/app_localizations.dart';

/// The scripture reader, mounted without a database, plus the verse fixtures
/// the corpus actually contains. Shared by every reader test so that a change
/// to what the screen needs is made once rather than found three times.

const sanskrit = 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।';

/// A Gita verse: the only shape in the corpus with all of translation,
/// transliteration and commentary.
ScriptureSection gita() => ScriptureSection.fromRow(const {
      'id': 1,
      'book_id': 7,
      'number': '1.1',
      'sanskrit': sanskrit,
      'transliteration': 'dharma-kṣetre kuru-kṣetre samavetā yuyutsavaḥ |',
      'body_en': 'What did my sons and the sons of Pandu do, O Sanjaya?',
      'body_hi': 'हे संजय! मेरे और पाण्डु के पुत्रों ने क्या किया?',
      'commentary_en': 'The question that opens the Gita is not a neutral one.',
      'commentary_hi': 'गीता का पहला प्रश्न निष्पक्ष नहीं है।',
    });

/// The verse after it, so a swipe has somewhere to land. Its commentary is
/// deliberately different prose: "the facet survived the swipe" and "the page
/// never turned" look identical if both verses say the same thing.
ScriptureSection gitaNext() => ScriptureSection.fromRow(const {
      'id': 3,
      'book_id': 7,
      'number': '1.2',
      'sanskrit': 'दृष्ट्वा तु पाण्डवानीकं व्यूढं दुर्योधनस्तदा।',
      'transliteration': 'dṛṣṭvā tu pāṇḍavānīkaṁ vyūḍhaṁ duryodhanas tadā |',
      'body_en': 'Seeing the Pandava army drawn up, Duryodhana approached Drona.',
      'body_hi': 'पाण्डव सेना को व्यूह में देखकर दुर्योधन द्रोण के पास गया।',
      'commentary_en': 'Sanjaya answers with a catalogue rather than a verdict.',
      'commentary_hi': 'संजय निर्णय के बजाय एक सूची से उत्तर देते हैं।',
    });

/// The shape 27,189 of 27,890 sections actually have: text and a translation,
/// and no commentary at all.
ScriptureSection ramayana() => ScriptureSection.fromRow(const {
      'id': 2,
      'book_id': 7,
      'number': '1.1',
      'sanskrit': sanskrit,
      'transliteration': 'tapassvādhyāyaniratam tapasvī vāgvidām varam |',
      'body_en': 'Valmiki questioned Narada, foremost among the sages.',
      'body_hi': 'वाल्मीकि ने मुनिश्रेष्ठ नारद से प्रश्न किया।',
    });

const book = ScriptureBook(
  id: 7,
  scriptureId: 3,
  titleEn: 'Bala Kanda',
  titleHi: 'बाल काण्ड',
  subtitleEn: 'The Book of Childhood',
  slug: 'bala-kanda',
);

const scripture = Scripture(
  id: 3,
  nameEn: 'Valmiki Ramayana',
  nameHi: 'वाल्मीकि रामायण',
  slug: 'valmiki-ramayana',
);

/// The reader is taller than the default surface and the verse scrolls, so the
/// surface is made tall. The width stays a real phone's, because that is the
/// axis the four-tab strip and the action row both overflow on.
///
/// Returns the [ProviderContainer] so a test can read what the screen wrote —
/// a bookmark's route, for instance, which nothing on screen displays.
Future<ProviderContainer> pumpReader(
  WidgetTester tester, {
  required ScriptureSection section,
  ScriptureSection? next,
  bool hindi = false,
  VerseContext context = const VerseContext(),
  int count = 24,
  ReaderTab? start,
  double width = 380,
  double height = 2400,
  double fontScale = 1.0,
  double systemScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (start != null) 'reader_tab': start.name,
    'reader_font_scale': fontScale,
  });
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    scriptureBookProvider.overrideWith((ref, id) => book),
    scripturesProvider.overrideWith((ref) async => [scripture]),
    scriptureSectionCountProvider.overrideWith((ref, id) => count),
    scriptureSectionPageProvider.overrideWith((ref, key) => [section, ?next]),
    verseContextProvider.overrideWith((ref, id) => context),
    // The rail has its own tests; here it must simply not reach a database.
    relatedProvider.overrideWith((ref, key) => const <RelatedItem>[]),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(hindi ? 'hi' : 'en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      // Two multipliers stack on this screen and they are not the same axis:
      // `reader_font_scale` is the reader's own slider, `textScaler` is the OS
      // accessibility setting. Nothing in lib/ reads or clamps the second one,
      // so it has to be applied here or RD-06 goes untested.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: systemScale,
        maxScaleFactor: systemScale,
        child: child!,
      ),
      home: const SectionReaderScreen(bookId: 7),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

/// The strip scrolls horizontally, so the tab being tapped may be off-screen —
/// which is the whole point of RD-06. Bring it into view first, exactly as a
/// reader would have to.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
