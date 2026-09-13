import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/stitched_border.dart';
import '../../astrology/astrology_data.dart' show signNames;
import '../../cosmos/cosmos_content.dart' show cGocharThemes, cVerdictLabels;
import '../../cosmos/cosmos_providers.dart';
import '../../cosmos/daily_cosmos.dart';
import '../../cosmos/rashi_glyphs.dart';

/// A one-glance daily Rashifal teaser for the reader's selected moon sign —
/// sign glyph, today's star rating and the one-line Chandra-gochar reading.
/// Taps through to the full Rashifal tab. Computed on-device (no birth data).
class RashifalCard extends ConsumerWidget {
  const RashifalCard({super.key});

  static const _accent = AppColors.dharmaPurple; // violet — this room's color

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
  static Color _ink(ColorScheme s) => s.onSurface;
  static Color _label(ColorScheme s) => s.onSurface.withValues(alpha: 0.5);

  /// A coarse 1-5 star read straight off the same [Verdict] the badge used
  /// to show as text — no invented precision, just that tone made visual.
  static int _stars(Verdict v) => switch (v) {
        Verdict.favourable => 4,
        Verdict.mixed => 3,
        Verdict.challenging => 2,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final moonRashi = ref.watch(transitMoonRashiProvider);
    final rashi = ref.watch(selectedRashiProvider);
    final house = gocharHouseFrom(rashi, moonRashi);
    final verdict = rashiVerdict(house);
    final line = cGocharThemes[house - 1].call(hi);
    final vColor = switch (verdict) {
      Verdict.favourable => AppColors.sacredGreen,
      Verdict.mixed => AppColors.gold,
      Verdict.challenging => AppColors.terracotta,
    };
    final stars = _stars(verdict);

    return StitchedCard(
      background: _bg(scheme),
      stitchColor: _accent.withValues(alpha: 0.45),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, _accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: RashiGlyph(index: rashi, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The verdict itself leads — that's the one thing a
                    // reader actually wants to know at a glance.
                    Text(cVerdictLabels[verdict.index].call(hi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            color: vColor)),
                    const SizedBox(height: 2),
                    Text(
                        hi
                            ? '${signNames[rashi].call(hi)} के लिए · आज'
                            : 'for ${signNames[rashi].call(hi)} · today',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: _label(scheme))),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 15,
                          color: i < stars
                              ? const Color(0xFFD9A441)
                              : _label(scheme),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(line,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: _ink(scheme).withValues(alpha: 0.82))),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.push('/cosmos'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hi ? 'पूर्ण विवरण' : 'Full reading',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _accent)),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: _accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
