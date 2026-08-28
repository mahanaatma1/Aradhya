import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/skeleton.dart';
import 'quiz_providers.dart';

/// Labels for the entity `kind`s a quiz question can be filtered by
/// (QZ-02). A different vocabulary from `SearchKinds` — these are
/// `entities.kind` values ('deity', 'human', …), not `search_docs.kind`.
const _quizCategoryLabels = <String, (String, String)>{
  'deity': ('Deities', 'देवी-देवता'),
  'human': ('People', 'व्यक्ति'),
  'scripture': ('Scriptures', 'ग्रंथ'),
  'river': ('Rivers', 'नदियाँ'),
  'rishi': ('Sages', 'ऋषि'),
  'concept': ('Concepts', 'अवधारणाएँ'),
  'avatar': ('Avatars', 'अवतार'),
  'asura': ('Asuras', 'असुर'),
  'place': ('Places', 'स्थान'),
  'weapon': ('Weapons', 'अस्त्र'),
  'symbol': ('Symbols', 'प्रतीक'),
  'mountain': ('Mountains', 'पर्वत'),
};

/// Pauranik Prasna hub: choose Knowledge Quiz / Riddles / Trivia.
class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = ref.watch(isHindiProvider);
    final counts = ref.watch(quizCountsProvider);
    final cats = Theme.of(context).extension<CategoryColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(t.catQuiz)),
      body: counts.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('$e')),
        data: (c) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ModeCard(
              gradient: cats.quiz.linear,
              icon: Icons.quiz_rounded,
              title: hi ? 'ज्ञान प्रश्नोत्तरी' : 'Knowledge Quiz',
              subtitle: hi
                  ? '${c['quiz']} प्रश्न · पौराणिक प्रश्नोत्तरी'
                  : '${c['quiz']} questions · पौराणिक प्रश्न',
              onTap: () => context.push('/quiz/play'),
            ),
            const _QuizCategoryPicker(),
            const SizedBox(height: 12),
            _ModeCard(
              gradient: cats.astrology.linear,
              icon: Icons.lightbulb_outline_rounded,
              title: hi ? 'पहेलियाँ' : 'Riddles',
              subtitle: hi
                  ? '${c['riddles']} पहेलियाँ · मैं कौन हूँ?'
                  : '${c['riddles']} clue riddles · मैं कौन हूँ?',
              onTap: () => context.push('/riddles'),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              gradient: cats.aartis.linear,
              icon: Icons.auto_stories_rounded,
              title: hi ? 'रोचक तथ्य' : 'Trivia',
              subtitle: hi
                  ? '${c['trivia']} तथ्य पढ़ें'
                  : '${c['trivia']} facts to explore',
              onTap: () => context.push('/quiz/trivia'),
            ),
            const SizedBox(height: 12),
            // Sits here because this is where people come to be asked
            // questions — but nothing in it is scored, which the subtitle
            // says outright so the card is not mistaken for another quiz.
            _ModeCard(
              gradient: cats.personality.linear,
              icon: Icons.balance_rounded,
              title: hi ? 'धर्म संकट' : 'Dharma Dilemmas',
              subtitle: hi
                  ? 'ग्रंथों के प्रश्न — कोई उत्तर सही या गलत नहीं'
                  : 'Questions from the texts — no right answers',
              onTap: () => context.push('/dharma'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip row to narrow the next Knowledge Quiz session to one category
/// (QZ-02). Reads `quizCategoriesProvider` so only categories that actually
/// have linked questions appear — a chip can never lead to an empty quiz.
/// Renders nothing while categories are still loading or if none exist.
class _QuizCategoryPicker extends ConsumerWidget {
  const _QuizCategoryPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final cats = ref.watch(quizCategoriesProvider).valueOrNull ?? const [];
    if (cats.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(quizCategoryProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String? kind, String label) {
      final isSelected = selected == kind;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) =>
              ref.read(quizCategoryProvider.notifier).state = kind,
          selectedColor: scheme.primary.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            color: isSelected ? scheme.primary : null,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            chip(null, hi ? 'सभी' : 'All'),
            for (final (kind, n) in cats)
              chip(kind, () {
                final label = _quizCategoryLabels[kind];
                final text = label == null ? kind : (hi ? label.$2 : label.$1);
                return '$text ($n)';
              }()),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFFFFF8EF), size: 34),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Color(0xFFFFF8EF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFFFFF8EF).withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFFFF8EF)),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
