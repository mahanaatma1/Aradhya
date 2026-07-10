import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/features/astrology/astro_chart.dart';
import 'package:divyavaani/features/astrology/astro_planets.dart';
import 'package:divyavaani/features/astrology/astrology_providers.dart';
import 'package:divyavaani/features/astrology/soul_profile.dart';
import 'package:divyavaani/features/astrology/yogas_doshas.dart';
import 'package:divyavaani/features/cosmos/daily_cosmos.dart';
import 'package:divyavaani/features/panchang/panchang_engine.dart';

void main() {
  // Sample birth (Lakhisarai) — app-style non-UTC DateTime holding UTC values.
  final birth = BirthDetails(
    name: 'Test',
    dob: DateTime(2001, 7, 23, 4, 52),
    lat: 25.1764,
    lon: 86.0943,
    utcOffset: 5.5,
    place: 'Lakhisarai',
  );
  final chart = computeChart(birth.utc, birth.lat, birth.lon);
  final soul = computeSoulProfile(chart, birth);

  DailyCosmos cosmosFor(DateTime now) {
    final transits = computeGrahas(now.toUtc());
    final panchang = computePanchang(
      date: now,
      lat: birth.lat,
      lonEast: birth.lon,
      tzOffset: const Duration(hours: 5, minutes: 30),
      amanta: false,
    );
    final doshas = detectDoshas(chart, nowUtc: now.toUtc());
    return buildDailyCosmos(
      chart: chart,
      birth: birth,
      transits: transits,
      panchang: panchang,
      soul: soul,
      doshas: doshas,
      now: now,
    );
  }

  test('gochar house is 1..12 and shifts across a week', () {
    final a = cosmosFor(DateTime(2026, 7, 9, 10));
    final b = cosmosFor(DateTime(2026, 7, 16, 10));

    expect(a.gocharHouse, inInclusiveRange(1, 12));
    expect(b.gocharHouse, inInclusiveRange(1, 12));
    // The Moon crosses ~3 signs in a week, so the house must change.
    expect(a.gocharHouse, isNot(b.gocharHouse));

    expect(a.mahaLord, isNotEmpty);
    expect(a.antarLord, isNotEmpty);
    // Rahu Kaal is always present → there is at least one tricky window.
    expect(a.trickyHours, isNotEmpty);
    expect(a.verdict, isA<Verdict>());
  });

  test('verdict / score are deterministic for the same instant', () {
    final now = DateTime(2026, 7, 9, 10);
    expect(cosmosFor(now).score, cosmosFor(now).score);
    expect(cosmosFor(now).verdict, cosmosFor(now).verdict);
  });

  test('nextFavourableDay returns a day within a month', () {
    final from = DateTime(2026, 7, 9);
    final d = nextFavourableDay(chart, from);
    expect(d, isNotNull);
    expect(d!.difference(from).inDays, inInclusiveRange(1, 30));
  });

  group('dailyVariant', () {
    test('is in range and reproducible for the same key', () {
      final day = DateTime(2026, 7, 9);
      for (var rashi = 0; rashi < 12; rashi++) {
        for (var aspect = 0; aspect < 5; aspect++) {
          final a = dailyVariant(rashi, aspect, day, 3);
          final b = dailyVariant(rashi, aspect, day, 3);
          expect(a, b); // deterministic
          expect(a, inInclusiveRange(0, 2)); // 0..count-1
        }
      }
    });

    test('count <= 1 always returns 0', () {
      expect(dailyVariant(3, 2, DateTime(2026, 7, 9), 1), 0);
      expect(dailyVariant(3, 2, DateTime(2026, 7, 9), 0), 0);
    });

    test('varies across days and across signs', () {
      // Same sign, consecutive days: at least one of the next few differs.
      final base = dailyVariant(0, 0, DateTime(2026, 7, 9), 3);
      final anyDayDiffers = [1, 2, 3, 4].any((d) =>
          dailyVariant(0, 0, DateTime(2026, 7, 9 + d), 3) != base);
      expect(anyDayDiffers, isTrue);

      // Same day, different signs: not all identical.
      final day = DateTime(2026, 7, 9);
      final perSign =
          List.generate(12, (r) => dailyVariant(r, 0, day, 3)).toSet();
      expect(perSign.length, greaterThan(1));
    });
  });

  test('BirthDetails JSON round-trips', () {
    final j = birth.toJson();
    final back = BirthDetails.fromJson(j);
    expect(back.name, birth.name);
    expect(back.dob, birth.dob);
    expect(back.lat, birth.lat);
    expect(back.lon, birth.lon);
    expect(back.utcOffset, birth.utcOffset);
    expect(back.place, birth.place);
    expect(back.utc, birth.utc);
  });
}
