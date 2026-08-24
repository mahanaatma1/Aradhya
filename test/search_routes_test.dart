// SR-04. Every route the search index emits must resolve against the real
// router — no result may tap through to GoRouter's "no routes for location"
// page.
//
// `content/tools/index.py` already gates this at build time (`route_ok` drops
// any doc whose route is not in `routes.txt`), so this test is not the first
// line of defence. It is the second, and a different one: it runs the actual
// `appRouter` from `lib/`, so it catches the case the Python cannot — a route
// pattern that was renamed or removed in Dart after the index was built. The
// index would still hold the old shape and every such result would land on the
// error page. Here that is a failing test rather than a shipped dead end.
//
// Rather than hardcode the route shapes (which would just re-encode the same
// assumption twice), it reads one representative route per distinct shape out
// of the shipped `search_docs` and matches each against the router.

import 'dart:io';

import 'package:divyavaani/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reduces a concrete route to its shape: numeric ids to `N`, query values
/// dropped, query keys sorted. `/scriptures/book/7?v=42` and
/// `/scriptures/book/1?v=1` share a shape and so are tested once.
String _shapeOf(String route) {
  final parts = route.split('?');
  final path = parts[0].replaceAll(RegExp(r'\d+'), 'N');
  if (parts.length < 2 || parts[1].isEmpty) return path;
  final keys = parts[1].split('&').map((p) => p.split('=').first).toList()
    ..sort();
  return '$path?${keys.join('&')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final gyan = File('assets/db/gyan.sqlite');

  late Database db;
  final representatives = <String, String>{};

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    db = await databaseFactoryFfi.openDatabase(gyan.absolute.path,
        options: OpenDatabaseOptions(readOnly: true));

    // One real route per distinct shape. Taken from the DB, not invented, so a
    // shape this test does not anticipate still gets exercised.
    final rows = await db.rawQuery('SELECT DISTINCT route FROM search_docs');
    for (final r in rows) {
      final route = r['route'] as String;
      representatives.putIfAbsent(_shapeOf(route), () => route);
    }
  });

  tearDownAll(() async {
    try {
      await db.close();
    } catch (_) {/* setUpAll may have failed before db was assigned */}
  });

  test('the index actually contains routes to check', () {
    expect(representatives, isNotEmpty, reason: 'run: py -m content.tools.build');
    // A guard against the shaping accidentally collapsing everything to one
    // bucket — the shipped index has eleven distinct shapes.
    expect(representatives.length, greaterThanOrEqualTo(8));
  });

  test('every distinct route shape resolves without hitting the error page', () {
    final broken = <String>[];
    representatives.forEach((shape, route) {
      final match = appRouter.configuration.findMatch(Uri.parse(route));
      if (match.isError) broken.add('$shape  ($route)');
    });
    expect(broken, isEmpty,
        reason: 'these search routes no longer exist in the router:\n'
            '${broken.join('\n')}');
  });

  test('the matcher has teeth — a route the app never registered is an error',
      () {
    // If this passed, the test above would pass no matter how broken the
    // routes were. A path the router genuinely does not know must come back
    // as an error, or `isError` is not measuring what it claims to.
    final match =
        appRouter.configuration.findMatch(Uri.parse('/no-such-route-xyz'));
    expect(match.isError, isTrue);
  });
}
