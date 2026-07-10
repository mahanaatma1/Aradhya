import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/habits.dart';

/// Per-habit accent colour + a short "why" line, keyed by habit key.
const _habitMeta = <String, (Color, String, String)>{
  'meditate': (
    AppColors.dharmaPurple,
    'Steady the mind for a few minutes',
    'कुछ मिनट मन को स्थिर करें'
  ),
  'scripture': (
    AppColors.terracotta,
    'A verse of the Gita or Ramayana',
    'गीता या रामायण का एक श्लोक'
  ),
  'japa': (
    Color(0xFFD26A2E),
    'One mala of your Ishta mantra',
    'अपने इष्ट मंत्र की एक माला'
  ),
  'pranayama': (
    Color(0xFF3E7C8C),
    'A few rounds of mindful breathing',
    'कुछ चक्र सजग श्वास के'
  ),
  'gratitude': (
    AppColors.deityRose,
    'Note one thing you are grateful for',
    'एक कृतज्ञता लिखें'
  ),
  'seva': (
    AppColors.sacredGreen,
    'One small act of kindness',
    'एक छोटा भला कार्य'
  ),
};

/// Daily sadhana habits — check off today's practices; each earns points and
/// keeps the streak warm. Completions reset each calendar day.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final done = ref.watch(habitsProvider);
    final ctrl = ref.read(habitsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final ratio = done.length / kHabits.length;
    final allDone = done.length == kHabits.length;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'दैनिक साधना' : 'Daily Sadhana')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress hero.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.secondary.withValues(alpha: 0.10),
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 6,
                        backgroundColor: scheme.primary.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.gold),
                      ),
                      Text('${done.length}/${kHabits.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allDone
                            ? (hi ? 'आज की साधना पूर्ण 🙏' : "Today's sadhana complete 🙏")
                            : (hi ? 'आज का अभ्यास' : "Today's practice"),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        allDone
                            ? (hi ? 'कल फिर मिलते हैं।' : 'See you again tomorrow.')
                            : (hi
                                ? 'छोटी चुनौतियाँ, बड़ा बदलाव'
                                : 'Small challenges, big change'),
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.65)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final h in kHabits)
            _HabitCard(
              habit: h,
              hi: hi,
              done: done.contains(h.key),
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.toggle(h.key);
              },
            ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool hi;
  final bool done;
  final VoidCallback onTap;
  const _HabitCard(
      {required this.habit,
      required this.hi,
      required this.done,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = _habitMeta[habit.key];
    final color = meta?.$1 ?? scheme.primary;
    final subtitle = meta == null ? null : (hi ? meta.$3 : meta.$2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: done
                  ? color.withValues(alpha: 0.10)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: color.withValues(alpha: done ? 0.5 : 0.18),
                  width: done ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(habit.icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.label(hi),
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? scheme.onSurface.withValues(alpha: 0.6)
                                  : scheme.onSurface)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12.5,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(
                        color: done
                            ? color
                            : scheme.onSurface.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
