import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/core/user/bookmarks.dart';

import 'support/reader_harness.dart';

/// RD-04. The verse action row: bookmark, note, listen, share.
///
/// Two things here are worth holding down with tests rather than trusting.
///
/// The first is that a note has no table of its own. It lives on the verse's
/// bookmark row, because `bookmarks.note` already existed and `setNote` returns
/// silently when there is no row to write to. So saving a note has to create the
/// bookmark, and clearing one must *not* remove it — a reader deleting their own
/// words is not asking to throw the verse away as well. Both directions of that
/// asymmetry are asserted below, because the natural implementation of the
/// second is a toggle, and a toggle would be wrong.
///
/// The second is width. Seven 48-pixel targets and the size button want 340
/// logical pixels; a 320-wide phone has 304. That overflowed at *every* text
/// size, not just large ones, so the row now scrolls — and the point of it
/// scrolling is that the bookmark is on the fixed leading edge and the voice
/// picker is what leaves the screen.

/// The verse's bookmark row, or null if the verse was never saved. Nothing on
/// screen shows a bookmark's note or route, so the assertions have to read them.
Bookmark? _mark(ProviderContainer container) => container
    .read(bookmarksProvider)
    .where((b) => b.kind == 'shloka')
    .firstOrNull;

Future<void> _openNote(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// A snackbar sits for four seconds and queues anything shown behind it, so a
/// test that saves twice never sees the second message until the first is gone.
Future<void> _letSnackBarGo(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('the actions are all reachable (RD-04)', () {
    testWidgets('bookmark, note, listen and share are all on the row',
        (tester) async {
      await pumpReader(tester, section: gita());
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    });

    testWidgets('the row fits the narrowest phone at ordinary sizes',
        (tester) async {
      // The regression this locks: adding the note button made eight controls,
      // which overflowed by 36 pixels here at default text size — nothing to do
      // with accessibility scaling, just a phone 320 pixels wide.
      await pumpReader(tester, section: gita(), width: 320);
      expect(tester.takeException(), isNull);
    });

    testWidgets('what scrolls off a narrow phone is the voice picker',
        (tester) async {
      // Ordering is the whole fix. If the row is ever reordered back, this is
      // the test that says which end of it a reader cannot afford to lose.
      await pumpReader(tester, section: gita(), width: 320);
      final row = tester.getRect(find.byType(Scaffold));
      final bookmark = tester.getRect(find.byIcon(Icons.bookmark_border_rounded));
      final voice = tester.getRect(find.byIcon(Icons.record_voice_over_outlined));
      expect(bookmark.right, lessThanOrEqualTo(row.right),
          reason: 'the bookmark must be on screen without scrolling');
      expect(voice.left, greaterThan(bookmark.left),
          reason: 'voice is a setting, so it sits at the tail that scrolls');
    });

    testWidgets('the row survives 3.2x, where it has to scroll furthest',
        (tester) async {
      await pumpReader(tester,
          section: gita(),
          width: 320,
          fontScale: 1.6,
          systemScale: 2.0,
          height: 4000);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });

  group('a note lives on the verse bookmark', () {
    testWidgets('the sheet says it will bookmark, before anything is typed',
        (tester) async {
      await pumpReader(tester, section: gita());
      await _openNote(tester);
      expect(find.textContaining('bookmarks this verse too'), findsOneWidget,
          reason: 'the app is about to save something on the reader\'s behalf, '
              'so it says so first rather than in a snackbar afterwards');
    });

    testWidgets('saving a note creates the bookmark and stores the words',
        (tester) async {
      final container = await pumpReader(tester, section: gita());
      await _openNote(tester);
      await _type(tester, 'The question is not neutral.');
      await _save(tester);

      final saved = _mark(container);
      expect(saved, isNotNull, reason: 'setNote is a no-op without a row');
      expect(saved!.note, 'The question is not neutral.');
      expect(find.text('Note saved'), findsOneWidget);
    });

    testWidgets('a verse that has a note shows a filled icon', (tester) async {
      await pumpReader(tester, section: gita());
      await _openNote(tester);
      await _type(tester, 'Worth returning to.');
      await _save(tester);

      // The only clue on this screen that a note exists at all.
      expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget,
          reason: 'the bookmark it created should read as saved');
    });

    testWidgets('reopening shows what was written', (tester) async {
      await pumpReader(tester, section: gita());
      await _openNote(tester);
      await _type(tester, 'Worth returning to.');
      await _save(tester);
      await _letSnackBarGo(tester);

      await tester.tap(find.byIcon(Icons.sticky_note_2_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Worth returning to.'), findsOneWidget);
      // Already bookmarked, so the line about bookmarking is no longer news.
      expect(find.textContaining('bookmarks this verse too'), findsNothing);
      expect(find.textContaining('stays on this device'), findsOneWidget);
    });

    testWidgets('clearing a note keeps the bookmark', (tester) async {
      final container = await pumpReader(tester, section: gita());
      await _openNote(tester);
      await _type(tester, 'A first thought.');
      await _save(tester);
      await _letSnackBarGo(tester);

      await tester.tap(find.byIcon(Icons.sticky_note_2_rounded));
      await tester.pumpAndSettle();
      await _type(tester, '');
      await _save(tester);

      final saved = _mark(container);
      expect(saved, isNotNull,
          reason: 'deleting your own words is not a request to unsave the verse');
      expect(saved!.note, isNull);
      expect(find.text('Note removed'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    });

    testWidgets('an empty note on an unsaved verse saves nothing at all',
        (tester) async {
      final container = await pumpReader(tester, section: gita());
      await _openNote(tester);
      await _save(tester);
      expect(_mark(container), isNull,
          reason: 'opening the sheet and changing your mind must not '
              'silently bookmark the verse');
      expect(find.text('Nothing written'), findsOneWidget);
    });

    testWidgets('the sheet names the verse it belongs to', (tester) async {
      await pumpReader(tester, section: gita());
      await _openNote(tester);
      expect(find.text('Bala Kanda 1.1'), findsOneWidget);
    });

    testWidgets('Hindi throughout', (tester) async {
      await pumpReader(tester, section: gita(), hindi: true);
      await _openNote(tester);
      expect(find.text('आपका नोट'), findsOneWidget);
      expect(find.textContaining('यह श्लोक भी सहेजा जाएगा'), findsOneWidget);
      await _type(tester, 'यह श्लोक स्मरणीय है।');
      await tester.tap(find.text('सहेजें'));
      await tester.pumpAndSettle();
      expect(find.text('नोट सहेजा गया'), findsOneWidget);
    });
  });

  group('a bookmark reopens at the verse it was made on', () {
    testWidgets('the route carries ?v=', (tester) async {
      // The bug: the route was `/scriptures/book/7` with no verse, so a
      // bookmark on verse 48 reopened the chapter at verse 1 — which reads
      // exactly like the bookmark having been lost. The router has understood
      // `?v=` since the route was registered.
      final container =
          await pumpReader(tester, section: gita(), next: gitaNext());
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();

      final saved = _mark(container);
      expect(saved, isNotNull);
      expect(saved!.route, '/scriptures/book/7?v=1');
      expect(saved.isNavigable, isTrue);
    });

    testWidgets('the subtitle records which verse, so the list is legible',
        (tester) async {
      final container = await pumpReader(tester, section: gita());
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();
      expect(_mark(container)!.subtitle, contains('1.1'));
    });
  });
}
