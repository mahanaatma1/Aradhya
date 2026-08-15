import 'package:flutter_test/flutter_test.dart';
import 'package:divyavaani/features/festivals/festival_models.dart';
import 'package:divyavaani/features/festivals/festival_resolver.dart';

Festival rule(String slug,
        {String? month, String? paksha, int? tithi, String? solar}) =>
    Festival(
        id: 1, slug: slug, titleEn: slug, category: 'major',
        region: 'pan-india', descEn: '', lunarMonth: month, paksha: paksha,
        tithi: tithi, solarRule: solar);

void main() {
  const tz = Duration(hours: 5, minutes: 30);
  const r = FestivalResolver(tz);
  final from = DateTime(2026, 1, 1);

  String? d(Festival f) {
    final x = r.next(f, from);
    return x == null ? null : '${x.year}-${x.month}-${x.day}';
  }

  test('lunar rules resolve to the engine dates', () {
    // Cross-checked against monthFestivals in panchang_test.
    expect(d(rule('guru-purnima', month: 'ashadha', paksha: 'shukla', tithi: 15)),
        '2026-7-29');
    expect(d(rule('devshayani', month: 'ashadha', paksha: 'shukla', tithi: 11)),
        '2026-7-25');
    expect(d(rule('nirjala', month: 'jyeshtha', paksha: 'shukla', tithi: 11)),
        '2026-6-25');
    expect(d(rule('shivratri', month: 'phalguna', paksha: 'krishna', tithi: 14)),
        isNotNull);
  });

  test('the adhika month is skipped', () {
    // Jyeshtha shukla 11 must land in the nija month (Jun 25), never in the
    // intercalary one that precedes it (May 26).
    final all = r.occurrences(
        rule('nirjala', month: 'jyeshtha', paksha: 'shukla', tithi: 11),
        from, withinDays: 300);
    expect(all.any((x) => x.month == 5), isFalse);
  });

  test('solar rules land on the ingress day only', () {
    final mk = r.occurrences(
        rule('makar', solar: 'Sun enters sidereal Makara (Capricorn)'),
        from, withinDays: 400);
    // A 400-day window spans two Januaries, so two ingresses is correct.
    expect(mk.length, 2);
    expect(mk.first.month, 1);
    expect(mk.first.day, inInclusiveRange(13, 16));
  });

  test('an unresolvable rule yields nothing rather than a wrong date', () {
    expect(r.next(rule('onam', solar: 'Thiruvonam nakshatra in Chingam'), from),
        isNull);
  });
}
