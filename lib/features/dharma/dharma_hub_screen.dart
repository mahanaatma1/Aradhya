import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'dharma_models.dart';
import 'dharma_providers.dart';

const dharmaAccent = Color(0xFFA85A8C);
const dharmaDeep = Color(0xFF5C2549);

/// The Dharma Decision Game hub.
///
/// Deliberately not framed as a quiz. There is no score anywhere on this
/// screen, and the counters say how many scenarios have been *reflected on*,
/// never how many were answered correctly — because none of them have a
/// correct answer.
class DharmaHubScreen extends ConsumerWidget {
  const DharmaHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scenarios = ref.watch(dharmaScenariosProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'धर्म संकट' : 'Dharma Dilemmas')),
      body: AsyncView(
        value: scenarios,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई प्रसंग नहीं' : 'No scenarios yet',
        builder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _Intro(hindi: hi),
            const SizedBox(height: 14),
            _TodayCard(hindi: hi),
            const SizedBox(height: 18),
            for (final (key, en, hiLabel) in dharmaCategories)
              _CategorySection(
                categoryKey: key,
                titleEn: en,
                titleHi: hiLabel,
                hindi: hi,
                all: list,
              ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final bool hindi;
  const _Intro({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      hindi
          ? 'ये वे प्रश्न हैं जो ग्रंथों ने स्वयं उठाए। यहाँ कोई उत्तर सही या गलत नहीं है, और कोई अंक नहीं मिलता — केवल यह देखना है कि आप क्या चुनते हैं और क्यों।'
          : 'These are questions the texts themselves raise. No answer here is right or wrong and nothing is scored — the point is to notice what you choose, and why.',
      style: TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  final bool hindi;
  const _TodayCard({required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(dharmaOfTheDayProvider).valueOrNull;
    if (today == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/dharma/play/${today.id}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [dharmaAccent, dharmaDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hindi ? 'आज का प्रसंग' : "TODAY'S DILEMMA",
                style: const TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70)),
            const SizedBox(height: 7),
            Text(today.title(hindi),
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              today.context(hindi),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, height: 1.45, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String categoryKey;
  final String titleEn;
  final String titleHi;
  final bool hindi;
  final List<DharmaScenario> all;

  const _CategorySection({
    required this.categoryKey,
    required this.titleEn,
    required this.titleHi,
    required this.hindi,
    required this.all,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final list = all.where((s) => s.category == categoryKey).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    final done = ref.watch(dharmaProgressProvider.notifier).doneIn(list);
    ref.watch(dharmaProgressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 6),
          child: Row(
            children: [
              Text(hindi ? titleHi : titleEn,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(
                hindi
                    ? '$done / ${list.length} पर विचार किया'
                    : '$done of ${list.length} reflected on',
                style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        for (final s in list) _ScenarioRow(scenario: s, hindi: hindi),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ScenarioRow extends ConsumerWidget {
  final DharmaScenario scenario;
  final bool hindi;
  const _ScenarioRow({required this.scenario, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final done = ref.watch(dharmaProgressProvider).contains(scenario.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/dharma/play/${scenario.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: done
                    ? dharmaAccent.withValues(alpha: 0.4)
                    : scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.title(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5)),
                    const SizedBox(height: 3),
                    Text(
                      scenario.context(hindi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: scheme.onSurface.withValues(alpha: 0.68)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (done)
                const Icon(Icons.brightness_1_rounded,
                    size: 9, color: dharmaAccent)
              else
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
