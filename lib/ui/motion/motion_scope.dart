import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion_settings.dart';

/// Resolves [MotionSettings] once for the whole tree (system reduced-motion
/// ∪ user Motion level ∪ device tier) and hands it to every primitive through
/// [MotionScope.of], so painters and transition builders need no `ref`.
class MotionScope extends InheritedWidget {
  const MotionScope({super.key, required this.settings, required super.child});

  final MotionSettings settings;

  static MotionSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MotionScope>()?.settings ??
      MotionSettings.resolve(
        systemReduce: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        level: MotionLevel.full,
        tier: PerfTier.mid,
      );

  @override
  bool updateShouldNotify(MotionScope old) => old.settings != settings;
}

/// Mount once inside `MaterialApp.builder`.
class MotionScopeHost extends ConsumerWidget {
  const MotionScopeHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = MotionSettings.resolve(
      systemReduce: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      level: ref.watch(motionLevelProvider),
      tier: ref.watch(perfTierProvider),
    );
    return MotionScope(settings: settings, child: child);
  }
}
