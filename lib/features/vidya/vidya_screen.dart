import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'vidya_models.dart';
import 'vidya_providers.dart';

const vidyaAccent = Color(0xFF3E7F8E);

/// Colours for the honesty chip. Chosen to be legible, not attractive: an
/// unevaluated claim should not look like a validated one.
Color statusColor(String status) => switch (status) {
      'corroborated' => const Color(0xFF3F7A5E),
      'partially_corroborated' => const Color(0xFFC98A2B),
      'contested' => const Color(0xFFB3402F),
      _ => const Color(0xFF7A7570),
    };

class VidyaScreen extends ConsumerStatefulWidget {
  const VidyaScreen({super.key});

  @override
  ConsumerState<VidyaScreen> createState() => _VidyaScreenState();
}

class _VidyaScreenState extends ConsumerState<VidyaScreen> {
  String _discipline = vidyaDisciplines.first.$1;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final topics = ref.watch(vidyaTopicsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'वैदिक विद्या' : 'Vedic Science')),
      body: AsyncView(
        value: topics,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई विषय नहीं' : 'No topics yet',
        builder: (all) {
          final shown =
              all.where((t) => t.discipline == _discipline).toList();
          return Column(
            children: [
              _DisciplineTabs(
                selected: _discipline,
                hindi: hi,
                available: all.map((t) => t.discipline).toSet(),
                onSelected: (d) => setState(() => _discipline = d),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                            hi ? 'इस विषय में अभी कुछ नहीं' : 'Nothing here yet',
                            style: const TextStyle(fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                        itemCount: shown.length,
                        itemBuilder: (context, i) =>
                            _TopicCard(topic: shown[i], hindi: hi),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DisciplineTabs extends StatelessWidget {
  final String selected;
  final bool hindi;
  final Set<String> available;
  final ValueChanged<String> onSelected;

  const _DisciplineTabs({
    required this.selected,
    required this.hindi,
    required this.available,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final (key, en, hiLabel) in vidyaDisciplines)
            if (available.contains(key))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(hindi ? hiLabel : en),
                  selected: selected == key,
                  onSelected: (_) => onSelected(key),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected == key ? FontWeight.w700 : FontWeight.w500,
                    color: selected == key
                        ? vidyaAccent
                        : scheme.onSurface.withValues(alpha: 0.8),
                  ),
                  selectedColor: vidyaAccent.withValues(alpha: 0.14),
                  side:
                      BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
                ),
              ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final VidyaTopic topic;
  final bool hindi;
  const _TopicCard({required this.topic, required this.hindi});

  @override
  Widget build(BuildContext context) {
    // A vidya card must never render without its caution. Enforced in debug
    // builds so the rule cannot quietly rot.
    assert(topic.hasCaution,
        'vidya topic ${topic.slug} has no caution — §4.15 forbids rendering it');

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/gyan/vidya/${topic.id}'),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(topic.title(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2)),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: topic.modernStatus, hindi: hindi),
                ],
              ),
              const SizedBox(height: 5),
              Text(topic.desc(hindi),
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.72))),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final bool hindi;
  const StatusChip({super.key, required this.status, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    final label = modernStatusLabels[status];
    if (label == null) return const SizedBox.shrink();
    final contested = status == 'contested';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: contested ? Colors.transparent : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: contested ? 0.8 : 0.3)),
      ),
      child: Text(
        hindi ? label.$2 : label.$1,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}
