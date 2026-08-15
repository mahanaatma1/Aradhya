import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:divyavaani/features/panchang/panchang_engine.dart';
import 'package:divyavaani/features/panchang/festivals.dart';

void main() {
  test('Panchang matches reference app for 6 Jul 2026 (Bengaluru)', () {
    final p = computePanchang(
      date: DateTime(2026, 7, 6),
      lat: 12.8204,
      lonEast: 77.5118,
      tzOffset: const Duration(hours: 5, minutes: 30),
    );
    String tm(DateTime? d) => d == null ? '—' : DateFormat('h:mm a').format(d);

    // Print for manual comparison with the captured app screenshots.
    // ignore: avoid_print
    print('Tithi:     ${p.tithi.current.en} until ${tm(p.tithi.endTime)} → ${p.tithi.next?.en}');
    // ignore: avoid_print
    print('Nakshatra: ${p.nakshatra.current.en} until ${tm(p.nakshatra.endTime)} → ${p.nakshatra.next?.en}');
    // ignore: avoid_print
    print('Yoga:      ${p.yoga.current.en} until ${tm(p.yoga.endTime)} → ${p.yoga.next?.en}');
    // ignore: avoid_print
    print('Karana:    ${p.karana.current.en} until ${tm(p.karana.endTime)} → ${p.karana.next?.en}');
    // ignore: avoid_print
    print('Month/Paksha/Vara: ${p.month.en} / ${p.paksha.en} / ${p.vara.en}');
    // ignore: avoid_print
    print('Sunrise ${tm(p.sunrise)}  Sunset ${tm(p.sunset)}  Moonrise ${tm(p.moonrise)}  Moonset ${tm(p.moonset)}');

    // Reference app values (location-independent panchang elements):
    expect(p.tithi.current.en, 'Shashthi');
    expect(p.nakshatra.current.en, 'Purva Bhadrapada');
    expect(p.yoga.current.en, 'Saubhagya');
    expect(p.karana.current.en, 'Vanija');
    expect(p.paksha.en, 'Krishna Paksha');
    expect(p.vara.en, 'Somavara');
    // Purnimanta (North-Indian) convention: Jul 6 falls in Ashadha
    // (the reference app uses Amanta, which labels it Jyeshtha).
    expect(p.month.en, 'Ashadha');
  });

  test('Festivals for July 2026 match reference dates', () {
    const tz = Duration(hours: 5, minutes: 30);
    final hits = {
      for (final e in monthFestivals(2026, 7, tz).entries) e.key: e.value.name.en
    };
    // ignore: avoid_print
    print('July 2026 festivals: $hits');
    // Assert the FULL name. The earlier bare 'Ekadashi' expectation was never
    // satisfiable and hid G16: krishna-paksha Ekadashis were named from the
    // amanta month against a purnimanta-indexed table.
    //
    // 2026 carries an adhika (leap) Ashadha — the Jun 15 to Jul 14 lunation
    // contains no sankranti — so these festivals fall in the nija month in
    // July, not June. Do not "correct" them to June dates; that reading is
    // what an intercalary month is supposed to look like.
    expect(hits[10], 'Yogini Ekadashi');
    expect(hits[14], 'Ashadha Amavasya');
    expect(hits[25], 'Devshayani Ekadashi');
  });

  test('Named festivals land on the right dates (purnimanta)', () {
    const tz = Duration(hours: 5, minutes: 30);
    String? on(int y, int m, int day) =>
        monthFestivals(y, m, tz)[day]?.name.en;
    expect(on(2026, 8, 28), 'Raksha Bandhan');
    expect(on(2026, 7, 16), 'Rath Yatra');
    expect(on(2026, 9, 4), 'Janmashtami');
    expect(on(2026, 9, 15), 'Ganesh Chaturthi');
    expect(on(2026, 3, 4), 'Holi');
    // Diwali = Kartika Amavasya, somewhere in Nov 2026.
    final nov = monthFestivals(2026, 11, tz);
    expect(nov.values.any((f) => f.name.en == 'Diwali'), isTrue);
  });

  test('the adhika month of 2026 is named and dated as its own', () {
    const tz = Duration(hours: 5, minutes: 30);
    String? on(int y, int m, int d) => monthFestivals(y, m, tz)[d]?.name.en;

    // 2026 carries an intercalary Jyeshtha: the sun enters no new rashi
    // between the May 16 and Jun 15 new moons, so that lunation is adhika.
    // Its Ekadashis take their own names instead of the nija month's.
    expect(on(2026, 5, 26), 'Padmini Ekadashi');
    expect(on(2026, 6, 11), 'Parama Ekadashi');
    expect(on(2026, 5, 31), 'Adhika Purnima');

    // The nija month follows, and each of its festivals occurs exactly once.
    expect(on(2026, 6, 25), 'Nirjala Ekadashi');
    expect(on(2026, 6, 29), 'Jyeshtha Purnima');
    expect(on(2026, 7, 10), 'Yogini Ekadashi');
  });

  test('a vriddhi tithi does not fire its festival twice', () {
    const tz = Duration(hours: 5, minutes: 30);
    // Tithi 10 spans both the May 26 and May 27 sunrises. The vrat is one day.
    final may = monthFestivals(2026, 5, tz);
    expect(may[26], isNotNull);
    expect(may[27], isNull);
  });
}
