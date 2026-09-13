import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/stitched_border.dart';
import '../../panchang/festivals.dart';

/// A compact banner for today's or an upcoming festival (within ~20 days).
/// Hidden when nothing is near. Taps open the festival detail sheet.
class FestivalBanner extends ConsumerWidget {
  const FestivalBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final tz = DateTime.now().timeZoneOffset;
    final next = nextFestival(DateTime.now(), tz, withinDays: 20);
    if (next == null) return const SizedBox.shrink();

    final days = next.daysAway;
    final when = days <= 0
        ? (hi ? 'आज' : 'Today')
        : days == 1
            ? (hi ? 'कल' : 'Tomorrow')
            : DateFormat('d MMM').format(next.date);
    final heading = days <= 0
        ? (hi ? 'आज का पर्व' : "Today's Festival")
        : (hi ? 'आगामी पर्व' : 'Upcoming Festival');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Opens the Explorer rather than a one-off sheet: the same festival
        // leads that list, and from there the whole year is reachable.
        onTap: () => context.push('/festivals'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.secondary.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: CustomPaint(
            foregroundPainter: StitchedBorderPainter(
              color: scheme.primary.withValues(alpha: 0.4),
              radius: 13,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🪔', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(heading.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.55))),
                      const SizedBox(height: 2),
                      Text(next.hit.name(hi),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.15)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: scheme.primary)),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
