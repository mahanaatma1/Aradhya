import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/stitched_border.dart';
import '../../quiz/quiz_providers.dart';

/// A "Did You Know?" card cycling trivia facts, with a reshuffle button.
class DidYouKnowCard extends ConsumerStatefulWidget {
  const DidYouKnowCard({super.key});

  @override
  ConsumerState<DidYouKnowCard> createState() => _DidYouKnowCardState();
}

class _DidYouKnowCardState extends ConsumerState<DidYouKnowCard> {
  int _i = 0;

  /// How many progress dots to draw. Capped rather than one-per-fact: with
  /// hundreds of trivia rows, a literal dot per fact would be meaningless
  /// noise — this just signals "there's a deck here, keep tapping."
  static const _maxDots = 5;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final trivia = ref.watch(triviaProvider);
    final scheme = Theme.of(context).colorScheme;

    final fact = trivia.maybeWhen(
      data: (facts) =>
          facts.isEmpty ? null : facts[_i % facts.length].text(hi),
      orElse: () => null,
    );
    final count = trivia.maybeWhen(data: (f) => f.length, orElse: () => 0);
    final dots = count < _maxDots ? count : _maxDots;

    return StitchedCard(
      background: scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHighest
          : AppColors.kraft2,
      stitchColor: AppColors.terracotta.withValues(alpha: 0.4),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(hi ? 'क्या आप जानते हैं?' : 'DID YOU KNOW',
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracotta.withValues(alpha: 0.9))),
                ],
              ),
              if (dots > 1)
                Row(
                  children: List.generate(
                    dots,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i == _i % dots
                              ? AppColors.terracotta
                              : AppColors.terracotta.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fact ?? (hi ? 'रोचक तथ्य लोड हो रहे…' : 'Loading facts…'),
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 16.5,
                height: 1.42,
                color: scheme.onSurface.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: count == 0
                    ? null
                    : () => setState(() => _i = (_i + 1) % count),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hi ? 'अगला तथ्य' : 'Next fact',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.terracotta)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 15, color: AppColors.terracotta),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
