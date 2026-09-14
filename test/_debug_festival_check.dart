import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/panchang/festivals.dart';

void main() {
  test('debug: what does nextFestival return today', () {
    final now = DateTime.now();
    final tz = now.timeZoneOffset;
    print('Today is: $now');
    final next = nextFestival(now, tz, withinDays: 20);
    print('nextFestival result: $next');
    if (next != null) {
      print('  date: ${next.date}');
      print('  name: ${next.hit.name(false)}');
      print('  daysAway: ${next.daysAway}');
    }
    // Also scan day by day to see if ANYTHING is found in a wider window
    for (var i = 0; i <= 60; i++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final f = festivalOnDay(d, tz);
      if (f != null) {
        print('  [+${i}d] $d -> ${f.name(false)} (major=${f.major})');
      }
    }
  });
}
