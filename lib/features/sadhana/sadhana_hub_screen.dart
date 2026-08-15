import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/notifications/reminder_tile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/habits.dart';
import '../../core/user/user_prefs.dart';
import 'sadhana_models.dart';
import 'sadhana_providers.dart';

/// One place for daily practice.
///
/// Japa, breathing, habits and mandir each keep their own screen — those routes
/// stay registered for deep links and the home widgets. This hub is the
/// summary over them, built by aggregating `sadhana_sessions` rather than by
/// asking each feature for its state.
class SadhanaHubScreen extends ConsumerWidget {
  const SadhanaHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final allDays = ref.watch(sadhanaAllDaysProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'साधना' : 'Sadhana')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _TodayRing(),
          const SizedBox(height: 22),
          _Label(hi ? 'अभ्यास' : 'PRACTICES'),
          const SizedBox(height: 10),
          for (final p in kPractices) _PracticeRow(practice: p, hindi: hi),
          const _HabitsRow(),
          const SizedBox(height: 22),
          _Label(hi ? 'वर्ष' : 'THIS YEAR'),
          const SizedBox(height: 10),
          _YearHeatmap(byDay: allDays),
          const SizedBox(height: 22),
          _Label(hi ? 'पड़ाव' : 'MILESTONES'),
          const SizedBox(height: 10),
          const _MilestoneRail(),
          const SizedBox(height: 22),
          _Label(hi ? 'स्मरण' : 'REMINDER'),
          const SizedBox(height: 10),
          ReminderTile(
            kind: 'sadhana',
            labelEn: 'Daily practice reminder',
            labelHi: 'दैनिक साधना स्मरण',
            titleEn: 'Sadhana',
            titleHi: 'साधना',
            bodyEn: "Time for today's practice.",
            bodyHi: 'आज की साधना का समय।',
            // Morning by default — practice traditionally begins the day.
            defaultMinuteOfDay: 6 * 60,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
}

/// How much of today has been done, at a glance.
class _TodayRing extends ConsumerWidget {
  const _TodayRing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final done = ref.watch(practicesDoneTodayProvider).valueOrNull ?? 0;
    // Habits count as one practice alongside the four explicit ones.
    const total = 5;
    final frac = (done / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F7A5E), Color(0xFF25533F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: frac,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFE6C34A)),
                  ),
                ),
                Text('$done/$total',
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: Color(0xFFFFF8EF),
                    )),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done == 0
                      ? (hi ? 'आज का आरंभ' : 'Today, unbegun')
                      : (done >= total
                          ? (hi ? 'आज पूर्ण' : 'Today, complete')
                          : (hi ? 'आज चल रहा है' : 'Today, in progress')),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 21,
                    color: Color(0xFFFFF8EF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  // Deliberately not scolding when the count is zero. A
                  // practice tracker that shames you on an empty day is one
                  // people stop opening.
                  done == 0
                      ? (hi
                          ? 'कुछ भी छोटा-सा आरंभ किया जा सकता है।'
                          : 'Anything small is a beginning.')
                      : (hi
                          ? '$done अभ्यास आज दर्ज हुए।'
                          : '$done practice${done == 1 ? "" : "s"} recorded today.'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFFFFF8EF).withValues(alpha: 0.85),
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

class _PracticeRow extends ConsumerWidget {
  final Practice practice;
  final bool hindi;
  const _PracticeRow({required this.practice, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(practiceSummaryProvider(practice.key)).valueOrNull;
    final goal = ref.watch(sadhanaGoalsProvider).valueOrNull?[practice.key];
    final scheme = Theme.of(context).colorScheme;

    final today = s?.todayCount ?? 0;
    final streak = s?.currentStreak ?? 0;
    final target = goal?.targetCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: practice.route == null
            ? null
            : () => context.push(practice.route!),
        onLongPress: () => _editGoal(context, ref, practice, target),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: today > 0
                  ? practice.color.withValues(alpha: 0.45)
                  : scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: practice.color.withValues(alpha: today > 0 ? 1 : 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(practice.icon,
                    size: 20,
                    color: today > 0 ? Colors.white : practice.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(practice.label(hindi),
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        if (streak > 1) ...[
                          const SizedBox(width: 7),
                          Icon(Icons.local_fire_department_rounded,
                              size: 13, color: practice.color),
                          Text('$streak',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: practice.color)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      today == 0
                          ? (hindi ? 'आज नहीं' : 'Not yet today')
                          : (target != null
                              ? '$today / $target ${practice.unit(hindi)}'
                              : '$today ${practice.unit(hindi)}'),
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                height: 26,
                child: _Sparkline(
                    byDay: s?.byDay ?? const {}, color: practice.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, Practice p,
      int? current) async {
    final hi = ref.read(isHindiProvider);
    final ctrl = TextEditingController(text: current?.toString() ?? '');
    final value = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hi ? '${p.labelHi} — दैनिक लक्ष्य' : '${p.labelEn} — daily goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hi ? 'संख्या (खाली = कोई लक्ष्य नहीं)' : 'Number (blank = no goal)',
            suffixText: p.unit(hi),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(hi ? 'हटाएँ' : 'Clear'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 0),
            child: Text(hi ? 'सहेजें' : 'Save'),
          ),
        ],
      ),
    );
    if (value != null) {
      await setSadhanaGoal(ref, practice: p.key, targetCount: value);
    }
  }
}

/// Habits as one row; tapping opens the screen that owns them.
class _HabitsRow extends ConsumerWidget {
  const _HabitsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final s = ref.watch(practiceSummaryProvider('habits')).valueOrNull;
    final doneToday = ref.watch(habitsProvider).length;
    final scheme = Theme.of(context).colorScheme;
    const color = Color(0xFF5A2EA8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/habits'),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: doneToday > 0
                  ? color.withValues(alpha: 0.45)
                  : scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: doneToday > 0 ? 1 : 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checklist_rounded,
                    size: 20,
                    color: doneToday > 0 ? Colors.white : color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(hi ? 'आदतें' : 'Habits',
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        if ((s?.currentStreak ?? 0) > 1) ...[
                          const SizedBox(width: 7),
                          const Icon(Icons.local_fire_department_rounded,
                              size: 13, color: color),
                          Text('${s!.currentStreak}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$doneToday / ${kHabits.length} ${hi ? "आज" : "today"}',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                height: 26,
                child: _Sparkline(byDay: s?.byDay ?? const {}, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last 14 days, as bars.
class _Sparkline extends StatelessWidget {
  final Map<String, int> byDay;
  final Color color;
  const _Sparkline({required this.byDay, required this.color});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final values = [
      for (var i = 13; i >= 0; i--)
        byDay[dayStamp(today.subtract(Duration(days: i)))] ?? 0,
    ];
    final peak = values.fold<int>(0, math.max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final v in values)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.7),
              height: peak == 0 ? 2 : (2 + 24 * (v / peak)).clamp(2.0, 26.0),
              decoration: BoxDecoration(
                color: v == 0
                    ? color.withValues(alpha: 0.14)
                    : color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// A year of practice, all types combined.
class _YearHeatmap extends StatelessWidget {
  final Map<String, int> byDay;
  const _YearHeatmap({required this.byDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    const weeks = 26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 82,
          child: Row(
            children: [
              for (var w = weeks - 1; w >= 0; w--)
                Expanded(
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Builder(builder: (_) {
                          final date = today
                              .subtract(Duration(days: w * 7 + (6 - d)));
                          final n = byDay[dayStamp(date)] ?? 0;
                          return Container(
                            margin: const EdgeInsets.all(1),
                            height: 9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: n == 0
                                  ? scheme.outline.withValues(alpha: 0.12)
                                  : const Color(0xFF25533F).withValues(
                                      alpha:
                                          (0.3 + 0.12 * n).clamp(0.3, 1.0)),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${byDay.length} ${Localizations.localeOf(context).languageCode == "hi" ? "दिन दर्ज" : "days recorded"}',
          style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurface.withValues(alpha: 0.55)),
        ),
      ],
    );
  }
}

class _MilestoneRail extends ConsumerWidget {
  const _MilestoneRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final japa = ref.watch(practiceSummaryProvider('japa')).valueOrNull;
    final all = ref.watch(sadhanaAllDaysProvider).valueOrNull ?? const {};

    final items = <(String, bool)>[
      for (final m in kJapaMilestones)
        (hi ? m.labelHi : m.labelEn, (japa?.lifetimeCount ?? 0) >= m.threshold),
      for (final m in kDayMilestones)
        (hi ? m.labelHi : m.labelEn, all.length >= m.threshold),
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final (label, earned) = items[i];
          final scheme = Theme.of(context).colorScheme;
          return Container(
            width: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: earned
                  ? AppColors.gold.withValues(alpha: 0.14)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: earned
                    ? AppColors.gold.withValues(alpha: 0.55)
                    : scheme.outline.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  earned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  size: 17,
                  color: earned
                      ? AppColors.gold
                      : scheme.onSurface.withValues(alpha: 0.3),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
                    color: earned
                        ? AppColors.inkLight
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
