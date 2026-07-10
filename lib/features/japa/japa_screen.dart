import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/japa.dart';
import '../../core/user/user_prefs.dart';

/// Japa counter — tap the big bead to advance the mala (108). Below it sit the
/// practice stats Ishvarvaani tracks: today's count, lifetime total, current &
/// longest streak, a calendar heatmap and the next milestone.
class JapaScreen extends ConsumerWidget {
  const JapaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final japa = ref.watch(japaProvider);
    final ctrl = ref.read(japaProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'जप' : 'Japa'),
        actions: [
          IconButton(
            tooltip: hi ? 'माला रीसेट' : 'Reset round',
            onPressed: ctrl.resetRound,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _Bead(japa: japa, hi: hi, onTap: () {
            HapticFeedback.selectionClick();
            final before = ref.read(japaProvider).malas;
            ctrl.advance();
            if (ref.read(japaProvider).malas != before) {
              HapticFeedback.heavyImpact();
            }
          }),
          const SizedBox(height: 16),
          // + button (increment) and "log offline japa" for counts done away
          // from the app — the extras Ishvarvaani's Japa offers.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _logOffline(context, ref, hi),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(hi ? 'ऑफ़लाइन जोड़ें' : 'Log offline'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12)),
              ),
              const SizedBox(width: 14),
              FloatingActionButton(
                heroTag: 'japa_plus',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final before = ref.read(japaProvider).malas;
                  ctrl.advance();
                  if (ref.read(japaProvider).malas != before) {
                    HapticFeedback.heavyImpact();
                  }
                },
                backgroundColor: AppColors.terracotta,
                foregroundColor: const Color(0xFFFDEEDE),
                child: const Icon(Icons.add_rounded, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.today_rounded,
                  label: hi ? 'आज' : 'Today',
                  value: '${japa.today}',
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.all_inclusive_rounded,
                  label: hi ? 'कुल जप' : 'Total',
                  value: '${japa.total}',
                  color: AppColors.dharmaPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: hi ? 'वर्तमान श्रृंखला' : 'Current streak',
                  value: hi ? '${japa.currentStreak} दिन' : '${japa.currentStreak}d',
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: hi ? 'सबसे लंबी' : 'Longest',
                  value: hi ? '${japa.longestStreak} दिन' : '${japa.longestStreak}d',
                  color: AppColors.sacredGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _MilestoneCard(malas: japa.malas, hi: hi),
          const SizedBox(height: 22),
          Text(
            hi ? 'साधना का ताल' : 'Your practice rhythm',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _Heatmap(history: japa.history),
          const SizedBox(height: 8),
          Text(
            hi
                ? 'माला को स्पर्श करें · हर मनके पर एक जप'
                : 'Tap the mala · one chant per bead',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Log japa done away from the app — quick-add a mala or a custom count.
  Future<void> _logOffline(BuildContext context, WidgetRef ref, bool hi) async {
    final controller = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hi ? 'ऑफ़लाइन जप जोड़ें' : 'Log offline japa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                hi
                    ? 'ऐप के बाहर किए गए जप की संख्या जोड़ें।'
                    : 'Add chants you completed away from the app.',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final q in const [27, 54, 108])
                  ActionChip(
                    label: Text('+$q'),
                    onPressed: () => Navigator.pop(ctx, q),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: hi ? 'संख्या' : 'Count',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(hi ? 'रद्द' : 'Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
            child: Text(hi ? 'जोड़ें' : 'Add'),
          ),
        ],
      ),
    );
    if (n != null && n > 0) {
      await ref.read(japaProvider.notifier).addCounts(n);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(hi ? '$n जप जोड़े गए' : 'Added $n chants'),
        ));
      }
    }
  }
}

/// The big tappable mala bead with the round counter + progress ring.
class _Bead extends StatelessWidget {
  final JapaState japa;
  final bool hi;
  final VoidCallback onTap;
  const _Bead({required this.japa, required this.hi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = japa.beads / JapaController.mala;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor:
                      AppColors.terracotta.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
              Container(
                width: 210,
                height: 210,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.terracotta, AppColors.terracottaDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${japa.beads}',
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                        fontSize: 68,
                        color: Color(0xFFFDEEDE),
                      ),
                    ),
                    Text(
                      hi
                          ? '${JapaController.mala} में से · ${japa.malas} माला'
                          : 'of ${JapaController.mala} · ${japa.malas} malas',
                      style: const TextStyle(
                          color: Color(0xFFFDEEDE), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Progress toward the next mala milestone (mirrors "Reward unlocked at N").
class _MilestoneCard extends StatelessWidget {
  final int malas;
  final bool hi;
  const _MilestoneCard({required this.malas, required this.hi});

  static const _milestones = [1, 5, 11, 21, 51, 108, 251, 501, 1008];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = _milestones.firstWhere((m) => m > malas,
        orElse: () => _milestones.last);
    final prev = _milestones.lastWhere((m) => m <= malas, orElse: () => 0);
    final span = (next - prev) == 0 ? 1 : (next - prev);
    final progress = ((malas - prev) / span).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.16),
          AppColors.terracotta.withValues(alpha: 0.10),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hi
                      ? '$next माला पर अगला पुरस्कार'
                      : 'Reward unlocked at $next malas',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: scheme.onSurface),
                ),
              ),
              Text('$malas/$next',
                  style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracotta)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.gold.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

/// A GitHub-style calendar heatmap of the last ~18 weeks of japa activity.
class _Heatmap extends StatelessWidget {
  final Map<String, int> history;
  const _Heatmap({required this.history});

  static const _weeks = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    // Start on the Sunday of the week containing (today - 17 weeks).
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday % 7 + (_weeks - 1) * 7));

    Color cell(int count) {
      if (count <= 0) return scheme.onSurface.withValues(alpha: 0.06);
      final t = (count / 108).clamp(0.15, 1.0);
      return Color.lerp(
          AppColors.gold.withValues(alpha: 0.35), AppColors.terracotta, t)!;
    }

    return LayoutBuilder(builder: (context, box) {
      const gap = 3.0;
      final size = ((box.maxWidth - gap * (_weeks - 1)) / _weeks)
          .clamp(8.0, 20.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < _weeks; w++) ...[
                if (w > 0) const SizedBox(width: gap),
                Column(
                  children: [
                    for (var d = 0; d < 7; d++) ...[
                      if (d > 0) const SizedBox(height: gap),
                      Builder(builder: (_) {
                        final day = start.add(Duration(days: w * 7 + d));
                        final future = day.isAfter(today);
                        final count = history[dayStamp(day)] ?? 0;
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: future
                                ? Colors.transparent
                                : cell(count),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less',
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(width: 6),
              for (final c in [0, 20, 60, 108]) ...[
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: cell(c),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text('More',
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      );
    });
  }
}
