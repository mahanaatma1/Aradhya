import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'passport_providers.dart';
import 'passport_stamp.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC08A2E);
const _ink = Color(0xFF3A2A18);

/// A section heading with an optional way through to the full list.
class SectionHead extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHead(this.text, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(text,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w800,
                color: _accent.withValues(alpha: 0.75),
              )),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: _gold.withValues(alpha: 0.3)),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: _gold.withValues(alpha: 0.95),
                  )),
            ),
        ],
      );
}

/// The journey at a glance, in the passport's own terms.
///
/// There is no India map here yet. Showing the states as chips is honest about
/// what the app currently knows; a map would need state outlines the project
/// does not hold, and a fake one would be worse than none.
class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final visited = ref.watch(visitedTemplesProvider).valueOrNull ?? const [];
    final states = ref.watch(visitedStatesProvider).valueOrNull ?? const [];
    final stats = PassportStats.of(visited);

    return StitchedCard(
      radius: 16,
      background: kPaper,
      stitchColor: _gold.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(value: '${stats.darshan}', label: hi ? 'दर्शन' : 'Darshan'),
              _Stat(value: '${stats.states}', label: hi ? 'राज्य' : 'States'),
              _Stat(
                value: stats.sinceYear?.toString() ?? '—',
                label: hi ? 'से' : 'Since',
              ),
            ],
          ),
          if (states.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in states.take(8))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold.withValues(alpha: 0.34)),
                    ),
                    child: Text(
                      s.value > 1 ? '${s.key} · ${s.value}' : s.key,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4632),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                )),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: _accent.withValues(alpha: 0.7),
                )),
          ],
        ),
      );
}

/// The journey as a thread rather than a list: each darshan on a dated node,
/// the line running on to the next.
class JourneyTimeline extends StatelessWidget {
  final List<PassportEntry> entries;
  final bool hindi;
  const JourneyTimeline({
    super.key,
    required this.entries,
    required this.hindi,
  });

  static const _mon = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  static String dateLine(PassportEntry e, bool hindi) {
    final d = e.visitedAt;
    if (d == null) return hindi ? 'तिथि दर्ज नहीं' : 'DATE NOT RECORDED';
    return '${d.day.toString().padLeft(2, '0')} ${_mon[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _JourneyStop(
              entry: entries[i],
              hindi: hindi,
              last: i == entries.length - 1,
            ),
        ],
      );
}

class _JourneyStop extends StatelessWidget {
  final PassportEntry entry;
  final bool hindi;
  final bool last;
  const _JourneyStop({
    required this.entry,
    required this.hindi,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold,
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.3), width: 3),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _gold.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push('/temple?id=${entry.templeId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      JourneyTimeline.dateLine(entry, hindi),
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: _accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.name(hindi),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        if ((entry.state ?? '').isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_rounded,
                                  size: 12,
                                  color: _accent.withValues(alpha: 0.65)),
                              const SizedBox(width: 3),
                              Text(
                                entry.state!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _accent.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        Text(
                          hindi ? 'मुद्रा प्राप्त' : 'STAMP COLLECTED',
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: _gold.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                    if ((entry.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        entry.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppFonts.accent,
                          fontSize: 13,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF5A4632),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Milestones as gold seals.
///
/// Unearned ones stay visible but unstruck -- a milestone nobody can see is
/// not something to aim at. Each names a real first rather than a score.
class MilestoneRail extends ConsumerWidget {
  final bool preview;
  const MilestoneRail({super.key, this.preview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final all = ref.watch(milestonesProvider).valueOrNull ?? const [];
    if (all.isEmpty) return const SizedBox.shrink();

    if (preview) {
      // Earned first, so the row leads with what has actually happened.
      final shown = [
        ...all.where((m) => m.earned),
        ...all.where((m) => !m.earned),
      ].take(3).toList();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in shown)
            Expanded(child: _Seal(milestone: m, hindi: hi, compact: true)),
        ],
      );
    }

    return Column(
      children: [
        for (final m in all)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Seal(milestone: m, hindi: hi, compact: false),
          ),
      ],
    );
  }
}

class _Seal extends StatelessWidget {
  final Milestone milestone;
  final bool hindi;
  final bool compact;
  const _Seal({
    required this.milestone,
    required this.hindi,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final on = milestone.earned;
    final disc = Container(
      width: compact ? 44 : 52,
      height: compact ? 44 : 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: on
            ? const LinearGradient(
                colors: [Color(0xFFF0D28A), Color(0xFFC08A2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: on ? null : _gold.withValues(alpha: 0.10),
        border: Border.all(
          color: _gold.withValues(alpha: on ? 0.85 : 0.30),
          width: 1.4,
        ),
      ),
      child: Icon(
        on ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
        size: compact ? 22 : 26,
        color: on ? const Color(0xFF5A3A10) : _accent.withValues(alpha: 0.42),
      ),
    );

    if (compact) {
      return Column(
        children: [
          disc,
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              milestone.title(hindi),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: _ink.withValues(alpha: on ? 0.9 : 0.45),
              ),
            ),
          ),
        ],
      );
    }

    return StitchedCard(
      radius: 14,
      background: on ? _gold.withValues(alpha: 0.10) : kPaper,
      stitchColor: _gold.withValues(alpha: on ? 0.7 : 0.32),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          disc,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title(hindi),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: on ? 1 : 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.blurb(hindi),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: _accent.withValues(alpha: on ? 0.9 : 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
