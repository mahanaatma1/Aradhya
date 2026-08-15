import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import 'dharma_hub_screen.dart' show dharmaAccent, dharmaDeep;
import 'dharma_models.dart';
import 'dharma_providers.dart';

/// One dilemma.
///
/// Choosing reveals the consequence and then the reflection. There is never a
/// tick or a cross, no option is styled as better than another, and the
/// scenario cannot be "passed" — the whole design rests on that.
class DharmaScenarioScreen extends ConsumerStatefulWidget {
  final int scenarioId;
  const DharmaScenarioScreen({super.key, required this.scenarioId});

  @override
  ConsumerState<DharmaScenarioScreen> createState() =>
      _DharmaScenarioScreenState();
}

class _DharmaScenarioScreenState
    extends ConsumerState<DharmaScenarioScreen> {
  DharmaChoice? _chosen;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scenario = ref.watch(dharmaScenarioProvider(widget.scenarioId));
    final choices = ref.watch(dharmaChoicesProvider(widget.scenarioId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [dharmaAccent, dharmaDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AsyncView(
          value: scenario,
          isEmpty: (s) => s == null,
          emptyMessage: hi ? 'प्रसंग नहीं मिला' : 'Scenario not found',
          builder: (s) => SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(s!.title(hi),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: Colors.white)),
                const SizedBox(height: 14),
                Text(s.context(hi),
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.62,
                        color: Colors.white)),
                const SizedBox(height: 24),
                choices.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (list) => Column(
                    children: [
                      for (final c in list)
                        _ChoiceCard(
                          choice: c,
                          hindi: hi,
                          chosen: _chosen?.id == c.id,
                          dimmed: _chosen != null && _chosen!.id != c.id,
                          onTap: _chosen != null
                              ? null
                              : () {
                                  setState(() => _chosen = c);
                                  ref
                                      .read(dharmaProgressProvider.notifier)
                                      .record(s, c, hindi: hi);
                                },
                        ),
                    ],
                  ),
                ),
                if (_chosen != null) ...[
                  const SizedBox(height: 20),
                  _ReflectionPanel(scenario: s, hindi: hi),
                  const SizedBox(height: 16),
                  _Actions(scenario: s, hindi: hi),
                ],
                const SizedBox(height: 18),
                _Disclaimer(scenario: s, hindi: hi),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final DharmaChoice choice;
  final bool hindi;
  final bool chosen;
  final bool dimmed;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.choice,
    required this.hindi,
    required this.chosen,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? 0.45 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: chosen ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: chosen ? 0.75 : 0.32),
                  width: chosen ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choice.label(hindi),
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: Colors.white)),
                // The consequence appears on selection. Never a tick or a
                // cross: this is what follows, not whether it was right.
                if (chosen) ...[
                  const SizedBox(height: 10),
                  Text(choice.consequence(hindi),
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.white70)),
                  if (choice.guna != null &&
                      gunaLabels.containsKey(choice.guna)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hindi
                            ? gunaLabels[choice.guna]!.$2
                            : gunaLabels[choice.guna]!.$1,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The scripture-grounded commentary, on cream so it reads as a different
/// voice from the scenario itself.
class _ReflectionPanel extends StatelessWidget {
  final DharmaScenario scenario;
  final bool hindi;
  const _ReflectionPanel({required this.scenario, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hindi ? 'ग्रंथ क्या कहता है' : 'What the text does',
              style: const TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: dharmaDeep)),
          const SizedBox(height: 8),
          Text(scenario.reflection(hindi),
              style: const TextStyle(
                  fontFamily: AppFonts.accent,
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF2E2A28))),
          const SizedBox(height: 12),
          SourceChip(
            sourceName: scenario.sourceName,
            sourceRef: scenario.sourceRef,
            sourceUrl: scenario.sourceUrl,
            lastVerifiedAt: scenario.lastVerifiedAt,
            hindi: hindi,
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  final DharmaScenario scenario;
  final bool hindi;
  const _Actions({required this.scenario, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/journal/new'),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: Text(hindi ? 'डायरी में लिखें' : 'Journal this'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(hindi ? 'अगला' : 'Next'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: dharmaDeep,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final DharmaScenario scenario;
  final bool hindi;
  const _Disclaimer({required this.scenario, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final text = scenario.disclaimer(hindi);
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: Colors.white54),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.45, color: Colors.white54)),
        ),
      ],
    );
  }
}
