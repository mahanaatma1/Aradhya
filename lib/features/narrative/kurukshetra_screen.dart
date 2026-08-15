import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'narrative_models.dart';
import 'narrative_providers.dart';

/// The eighteen days of Kurukshetra, grouped by who was commanding.
///
/// The commander phases are the firm structure the text gives — Bhishma for
/// ten days, Drona for five, Karna for two, Shalya for the last. Presenting
/// eighteen undifferentiated days would lose the shape of the war; presenting
/// only the phases would lose the count.
class KurukshetraScreen extends ConsumerWidget {
  const KurukshetraScreen({super.key});

  /// Kaurava commanders in the order they held the post.
  static const _phases = <(String, String, String, Color)>[
    ('bhishma', 'Bhishma', 'भीष्म', Color(0xFF8A6A4F)),
    ('drona', 'Drona', 'द्रोण', Color(0xFFA7430F)),
    ('karna', 'Karna', 'कर्ण', Color(0xFF9C2950)),
    ('shalya', 'Shalya', 'शल्य', Color(0xFF4A3220)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final days = ref.watch(warDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'कुरुक्षेत्र — अठारह दिन' : 'Kurukshetra — 18 Days'),
      ),
      body: AsyncView(
        value: days,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई दिन नहीं' : 'No days recorded yet',
        builder: (list) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _Intro(hindi: hi),
              const SizedBox(height: 16),
              for (final (key, en, hiName, colour) in _phases)
                _Phase(
                  commanderEn: en,
                  commanderHi: hiName,
                  colour: colour,
                  hindi: hi,
                  days: list.where((d) => commanderOf(d) == key).toList(),
                ),
            ],
          );
        },
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
          ? 'युद्ध अठारह दिन चला। कौरव सेनापति चार बार बदले — भीष्म, द्रोण, कर्ण, शल्य। पांडव पक्ष का नेतृत्व आरंभ से अंत तक धृष्टद्युम्न के पास रहा।'
          : 'The war lasted eighteen days. The Kaurava command changed four times — Bhishma, Drona, Karna, Shalya. On the Pandava side, Dhrishtadyumna led throughout.',
      style: TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _Phase extends StatelessWidget {
  final String commanderEn;
  final String commanderHi;
  final Color colour;
  final bool hindi;
  final List<NarrativeNode> days;

  const _Phase({
    required this.commanderEn,
    required this.commanderHi,
    required this.colour,
    required this.hindi,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final first = days.first.sequenceNo - 100;
    final last = days.last.sequenceNo - 100;
    final span = first == last
        ? (hindi ? 'दिन $first' : 'Day $first')
        : (hindi ? 'दिन $first–$last' : 'Days $first–$last');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Text(
                hindi ? commanderHi : commanderEn,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                span,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        for (final d in days) _DayRow(day: d, colour: colour, hindi: hindi),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final NarrativeNode day;
  final Color colour;
  final bool hindi;

  const _DayRow(
      {required this.day, required this.colour, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = day.sequenceNo - 100;
    // Strip the "Day N — " prefix the title carries, since the number is
    // already shown in its own column.
    final title = day.title(hindi).replaceFirst(
        RegExp(r'^(Day|दिन)\s*\d+\s*—\s*'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/gyan/scene/${day.id}'),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$n',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colour)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      day.desc(hindi),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
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
