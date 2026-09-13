import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/core/platform/platform_bridge.dart';
import 'package:divyavaani/ui/motion/motion.dart';

void main() {
  group('MotionSettings.resolve', () {
    test('system reduced motion wins over everything', () {
      final m = MotionSettings.resolve(
          systemReduce: true, level: MotionLevel.full, tier: PerfTier.high);
      expect(m.reduce, isTrue);
      expect(m.particles, isFalse);
      expect(m.maxParticles, 0);
    });
    test('tiers scale particles and gate shaders/blur', () {
      final hi = MotionSettings.resolve(systemReduce: false, level: MotionLevel.full, tier: PerfTier.high);
      final mid = MotionSettings.resolve(systemReduce: false, level: MotionLevel.full, tier: PerfTier.mid);
      final lo = MotionSettings.resolve(systemReduce: false, level: MotionLevel.full, tier: PerfTier.low);
      expect(hi.maxParticles > mid.maxParticles && mid.maxParticles > lo.maxParticles, isTrue);
      expect(hi.blur, isTrue);
      expect(mid.blur, isFalse);
      expect(lo.shaders, isFalse);
      expect(lo.parallax, isFalse);
    });
    test('reduced keeps transitions but drops ambient effects', () {
      final m = MotionSettings.resolve(systemReduce: false, level: MotionLevel.reduced, tier: PerfTier.high);
      expect(m.reduce, isFalse);
      expect(m.particles, isFalse);
      expect(m.ambient, isFalse);
    });
  });

  group('PerfTierController.classify', () {
    test('classifies by RAM, cores and SDK', () {
      expect(PerfTierController.classify(const DeviceInfo(isLowRamDevice: false, totalMemBytes: 8 << 30, sdkInt: 36, cores: 8)), PerfTier.high);
      expect(PerfTierController.classify(const DeviceInfo(isLowRamDevice: false, totalMemBytes: 4 << 30, sdkInt: 30, cores: 8)), PerfTier.mid);
      expect(PerfTierController.classify(const DeviceInfo(isLowRamDevice: true, totalMemBytes: 8 << 30, sdkInt: 36, cores: 8)), PerfTier.low);
      expect(PerfTierController.classify(const DeviceInfo(isLowRamDevice: false, totalMemBytes: 2 << 30, sdkInt: 33, cores: 8)), PerfTier.low);
    });
  });

  Widget host(MotionSettings s, Widget child) => MaterialApp(
        home: MotionScope(settings: s, child: Scaffold(body: Center(child: child))),
      );

  testWidgets('Reveal shows content immediately under reduced motion', (tester) async {
    final off = MotionSettings.resolve(systemReduce: true, level: MotionLevel.full, tier: PerfTier.high);
    await tester.pumpWidget(host(off, const Reveal(index: 5, child: Text('hi'))));
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1.0);
  });

  testWidgets('Reveal fades in over time when motion is on', (tester) async {
    await tester.pumpWidget(host(MotionSettings.full, const Reveal(child: Text('hi'))));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.0);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));
    final mid = tester.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(mid, greaterThan(0.0));
    expect(mid, lessThan(1.0));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
  });

  testWidgets('PressScale fires onTap and springs back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(MotionSettings.full,
        PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40))));
    await tester.tap(find.byType(PressScale));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('AnimatedCount lands on the target', (tester) async {
    await tester.pumpWidget(host(MotionSettings.full, const AnimatedCount(108)));
    await tester.pumpAndSettle();
    expect(find.text('108'), findsOneWidget);
  });
}
