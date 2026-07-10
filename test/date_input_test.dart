import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/astrology/date_input.dart';

String fmtDate(String typed) {
  var v = const TextEditingValue();
  for (final ch in typed.split('')) {
    final next = TextEditingValue(text: '${v.text}$ch');
    v = dateMask.formatEditUpdate(v, next);
  }
  return v.text;
}

String fmtTime(String typed) {
  var v = const TextEditingValue();
  for (final ch in typed.split('')) {
    final next = TextEditingValue(text: '${v.text}$ch');
    v = timeMask.formatEditUpdate(v, next);
  }
  return v.text;
}

void main() {
  test('date formatter auto-inserts dashes and blocks bad day/month', () {
    expect(fmtDate('23072001'), '23-07-2001');
    expect(fmtDate('4'), '04'); // day first digit 4-9 -> 0X
    expect(fmtDate('9'), '09');
    expect(fmtDate('35'), '03-05'); // 35 not a day -> 03 / month 05
    expect(fmtDate('1305'), '13-05');
    expect(fmtDate('19'), '19'); // valid 2-digit day
    expect(fmtDate('3112'), '31-12');
    // month can never exceed 12
    expect(fmtDate('01'), '01');
    expect(fmtDate('012'), '01-02'); // month leading 2-9 -> 0X
    expect(fmtDate('0109'), '01-09');
  });

  test('time formatter blocks bad hour/minute', () {
    expect(fmtTime('0452'), '04:52');
    expect(fmtTime('1830'), '18:30');
    expect(fmtTime('5'), '05'); // hour first digit >2 -> 0X
    expect(fmtTime('25'), '02:5'); // 25 not an hour -> 02 / minute 5
    expect(fmtTime('2359'), '23:59');
    expect(fmtTime('0000'), '00:00');
    expect(fmtTime('9'), '09');
  });

  test('parse + error helpers', () {
    expect(parseBirthDate('23-07-2001'), DateTime(2001, 7, 23));
    expect(parseBirthDate('31-02-2001'), isNull); // no 31 Feb
    expect(parseBirthDate('29-02-2001'), isNull); // 2001 not leap
    expect(parseBirthDate('29-02-2000'), isNotNull); // 2000 is leap
    expect(dateErrorText('31-02-2001'), isNotNull);
    expect(dateErrorText('23-07-2001'), isNull);
    expect(dateErrorText('23-07'), isNull); // incomplete -> no error yet

    expect(parseBirthTime('04:52'), (4, 52));
    expect(parseBirthTime('24:00'), isNull);
    expect(timeErrorText('04:52'), isNull);
  });
}
