import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/core/user/interest_signals.dart';

/// P7-10. The binding requirement is that the app is fully usable with the
/// table empty, and that ranking only ever reorders — never removes.
///
/// userDatabaseProvider defaults to null, so the notifier's DB paths no-op and
/// these exercise the pure ranking logic against a real Ref.
void main() {
  late ProviderContainer container;
  InterestSignals sig() => container.read(interestSignalsProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('an empty profile leaves ordering untouched', () {
    const items = ['a', 'b', 'c'];
    expect(sig().rank(items, (x) => x), items);
  });

  test('ranking reorders but never drops', () {
    final s = sig()..state = {'b': 9.0};
    final out = s.rank(['a', 'b', 'c'], (x) => x);
    expect(out.first, 'b');
    expect(out.toSet(), {'a', 'b', 'c'});
  });

  test('unknown topics keep their original relative order', () {
    final s = sig()..state = {'c': 4.0};
    expect(s.rank(['a', 'b', 'c', 'd'], (x) => x), ['c', 'a', 'b', 'd']);
  });

  test('influence needs more than a passing tap', () {
    final s = sig();
    s.state = {'x': InterestSignals.openWeight};
    expect(s.isInfluential('x'), isFalse);
    s.state = {'x': InterestSignals.bookmarkWeight};
    expect(s.isInfluential('x'), isTrue);
  });

  test('reset empties the profile', () async {
    final s = sig()..state = {'x': 3.0};
    await s.reset();
    expect(s.state, isEmpty);
  });
}
