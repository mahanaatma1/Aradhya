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

/// RD-01/RD-02. The four facets of a verse, and what each one says when it has
/// nothing to say.
///
/// The reason this is worth a test file rather than a glance: the tabs promise
/// four things about every verse, and the corpus can only keep one of those
/// promises everywhere. Measured over all 27,890 sections of the shipped DB —
///
///   Meaning       27,890   Explanation  701 (Gita only)
///   Word meaning       0   Context      always (position)
///
/// — so on any Ramayana or Upanishad verse two tabs are empty and one is
/// structurally empty forever. The failure this guards against is the ordinary
/// one: a tab that renders blank, or a spinner, or "Coming soon", any of which
/// tells the reader to wait for something nobody has undertaken to write.
/// Every assertion below is about a tab *saying why*.

const _sanskrit = 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।';

/// A Gita verse: the only shape in the corpus with all of translation,
/// transliteration and commentary.
ScriptureSection _gita() => ScriptureSection.fromRow(const {
      'id': 1,
      'book_id': 7,
      'number': '1.1',
      'sanskrit': _sanskrit,
      'transliteration': 'dharma-kṣetre kuru-kṣetre samavetā yuyutsavaḥ |',
      'body_en': 'What did my sons and the sons of Pandu do, O Sanjaya?',
      'body_hi': 'हे संजय! मेरे और पाण्डु के पुत्रों ने क्या किया?',
      'commentary_en': 'The question that opens the Gita is not a neutral one.',
      'commentary_hi': 'गीता का पहला प्रश्न निष्पक्ष नहीं है।',
    });

/// The verse after it, so a swipe has somewhere to land. Its commentary is
/// deliberately different prose: "the facet survived the swipe" and "the page
/// never turned" look identical if both verses say the same thing.
ScriptureSection _gitaNext() => ScriptureSection.fromRow(const {
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
ScriptureSection _ramayana() => ScriptureSection.fromRow(const {
      'id': 2,
      'book_id': 7,
      'number': '1.1',
      'sanskrit': _sanskrit,
      'transliteration': 'tapassvādhyāyaniratam tapasvī vāgvidām varam |',
      'body_en': 'Valmiki questioned Narada, foremost among the sages.',
      'body_hi': 'वाल्मीकि ने मुनिश्रेष्ठ नारद से प्रश्न किया।',
    });

const _book = ScriptureBook(
  id: 7,
  scriptureId: 3,
  titleEn: 'Bala Kanda',
  titleHi: 'बाल काण्ड',
  subtitleEn: 'The Book of Childhood',
  slug: 'bala-kanda',
);

const _scripture = Scripture(
  id: 3,
  nameEn: 'Valmiki Ramayana',
  nameHi: 'वाल्मीकि रामायण',
  slug: 'valmiki-ramayana',
);

/// The reader is taller than the default surface and the verse scrolls, so the
/// surface is made tall. The width stays a real phone's, because that is the
/// axis the four-tab strip overflows on.
Future<void> pumpReader(
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
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (start != null) 'reader_tab': start.name,
    'reader_font_scale': fontScale,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      scriptureBookProvider.overrideWith((ref, id) => _book),
      scripturesProvider.overrideWith((ref) async => [_scripture]),
      scriptureSectionCountProvider.overrideWith((ref, id) => count),
      scriptureSectionPageProvider
          .overrideWith((ref, key) => [section, ?next]),
      verseContextProvider.overrideWith((ref, id) => context),
      // The rail has its own tests; here it must simply not reach a database.
      relatedProvider.overrideWith((ref, key) => const <RelatedItem>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(hindi ? 'hi' : 'en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: const SectionReaderScreen(bookId: 7),
    ),
  ));
  await tester.pumpAndSettle();
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

void main() {
  group('the strip offers all four facets (RD-01)', () {
    testWidgets('every tab is present, on a verse that can fill only two',
        (tester) async {
      await pumpReader(tester, section: _ramayana());
      expect(tester.takeException(), isNull);
      for (final tab in ReaderTab.values) {
        expect(find.text(tab.en), findsOneWidget,
            reason: '${tab.name} must be offered even when it is empty — '
                'hiding it would shuffle the others sideways between verses');
      }
    });

    testWidgets('Meaning is what opens, and it shows the translation',
        (tester) async {
      await pumpReader(tester, section: _ramayana());
      expect(find.textContaining('Valmiki questioned Narada'), findsOneWidget);
    });

    testWidgets('the Sanskrit stays above the strip, not inside a tab',
        (tester) async {
      // The verse itself is the one thing that is never a facet of itself.
      await pumpReader(tester, section: _ramayana());
      final sanskrit = tester.getTopLeft(find.text(_sanskrit)).dy;
      final strip = tester.getTopLeft(find.text(ReaderTab.meaning.en)).dy;
      expect(sanskrit, lessThan(strip));

      await tapTab(tester, ReaderTab.context.en);
      expect(find.text(_sanskrit), findsOneWidget,
          reason: 'switching facet must not hide the verse');
    });
  });

  group('an empty tab says why (RD-02)', () {
    testWidgets('word meaning names the gap and its extent', (tester) async {
      await pumpReader(tester, section: _gita(), start: ReaderTab.wordMeaning);
      expect(find.textContaining('Word-by-word meaning has not been added'),
          findsOneWidget);
      // The corpus-wide claim matters: without it the reader assumes this one
      // verse was skipped and goes looking for one that was not.
      expect(find.textContaining('whole collection'), findsOneWidget);
      expect(find.textContaining('Coming soon'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('word meaning is empty even on the Gita, which has everything',
        (tester) async {
      await pumpReader(tester, section: _gita(), start: ReaderTab.wordMeaning);
      expect(find.textContaining('has not been added'), findsOneWidget);
    });

    testWidgets('no commentary points at the one text that has one',
        (tester) async {
      await pumpReader(tester,
          section: _ramayana(), start: ReaderTab.explanation);
      expect(find.textContaining('No commentary is recorded'), findsOneWidget);
      expect(find.textContaining('Bhagavad Gita'), findsOneWidget,
          reason: 'a dead end should be turned into a direction');
    });

    testWidgets('commentary shows when there is one', (tester) async {
      await pumpReader(tester, section: _gita(), start: ReaderTab.explanation);
      expect(find.textContaining('not a neutral one'), findsOneWidget);
      expect(find.textContaining('No commentary is recorded'), findsNothing);
    });

    testWidgets('empty states carry Hindi too', (tester) async {
      await pumpReader(tester,
          section: _ramayana(), hindi: true, start: ReaderTab.wordMeaning);
      expect(find.textContaining('शब्द-दर-शब्द'), findsOneWidget);
      await tapTab(tester, ReaderTab.explanation.hi);
      expect(find.textContaining('व्याख्या दर्ज नहीं'), findsOneWidget);
    });
  });

  group('Context is never empty, because position always exists', () {
    testWidgets('scripture, chapter and position, with nothing linked',
        (tester) async {
      await pumpReader(tester,
          section: _ramayana(), start: ReaderTab.context, count: 2265);
      expect(find.text('Valmiki Ramayana'), findsOneWidget);
      // The chapter line, not the app bar title, which also says "Bala Kanda".
      expect(find.text('Bala Kanda — The Book of Childhood'), findsOneWidget,
          reason: 'the chapter subtitle is the only theme data there is');
      expect(find.text('Verse 1 of 2265'), findsOneWidget);
    });

    testWidgets('an unlinked verse announces nothing it does not have',
        (tester) async {
      await pumpReader(tester,
          section: _ramayana(), start: ReaderTab.context);
      // Unlike the tabs, nothing here promised a story or a question, so
      // silence is accurate rather than evasive. Uppercase because that is how
      // the section labels render — matching the mixed case would pass here
      // whether or not the section was drawn.
      expect(find.textContaining('THIS VERSE ANSWERS'), findsNothing);
      expect(find.textContaining('THE STORY SET HERE'), findsNothing);
    });

    testWidgets('Ask pairs citing the verse appear, and grow with AK-01',
        (tester) async {
      await pumpReader(
        tester,
        section: _gita(),
        start: ReaderTab.context,
        context: const VerseContext(questions: [
          (id: 1, en: 'What does the Gita say about fear?', hi: null),
          (id: 2, en: 'Is the soul destroyed when the body dies?', hi: null),
        ]),
      );
      expect(find.textContaining('THIS VERSE ANSWERS'), findsOneWidget);
      expect(find.textContaining('about fear'), findsOneWidget);
      expect(find.textContaining('soul destroyed'), findsOneWidget);
    });

    testWidgets('a linked story event appears when SC-11 fills the link in',
        (tester) async {
      await pumpReader(
        tester,
        section: _ramayana(),
        start: ReaderTab.context,
        context: const VerseContext(
            event: (id: 12, en: 'Hanuman enters the grove', hi: null)),
      );
      expect(find.textContaining('THE STORY SET HERE'), findsOneWidget);
      expect(find.text('Hanuman enters the grove'), findsOneWidget);
    });
  });

  group('the choice survives the things that would reset it', () {
    testWidgets('a facet chosen on one verse holds on the next', (tester) async {
      // The bug this defends: the tab lived in the verse page, so swiping
      // rebuilt it and dropped the reader back onto Meaning every time.
      await pumpReader(tester, section: _gita(), next: _gitaNext());
      await tapTab(tester, ReaderTab.explanation.en);
      expect(find.textContaining('not a neutral one'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sanjaya answers with a catalogue'),
          findsOneWidget,
          reason: 'a swipe must not reset the facet');
    });

    testWidgets('a facet chosen last session is restored', (tester) async {
      await pumpReader(tester, section: _gita(), start: ReaderTab.explanation);
      expect(find.textContaining('not a neutral one'), findsOneWidget);
    });

    testWidgets('an unknown saved facet falls back to Meaning', (tester) async {
      SharedPreferences.setMockInitialValues({'reader_tab': 'nonsense'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      expect(container.read(readerTabProvider), ReaderTab.meaning);
    });
  });

  group('the strip holds at the largest text (RD-06)', () {
    testWidgets('four tabs on a narrow phone at max scale do not overflow',
        (tester) async {
      // 1.6 is ReaderFontScale.max, 320 is the narrowest phone width we
      // support. "Word meaning" cannot fit beside the other three here at any
      // weight, which is why the strip scrolls.
      await pumpReader(tester,
          section: _gita(), width: 320, fontScale: 1.6, height: 2600);
      expect(tester.takeException(), isNull);
      expect(find.text(ReaderTab.meaning.en), findsOneWidget);
    });

    testWidgets('Hindi labels at max scale do not overflow either',
        (tester) async {
      await pumpReader(tester,
          section: _gita(),
          hindi: true,
          width: 320,
          fontScale: 1.6,
          height: 2600);
      expect(tester.takeException(), isNull);
      expect(find.text(ReaderTab.wordMeaning.hi), findsOneWidget);
    });
  });
}
