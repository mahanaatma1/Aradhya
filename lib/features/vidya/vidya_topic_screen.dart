import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import '../related/related_rail.dart';
import 'vidya_models.dart';
import 'vidya_providers.dart';
import 'vidya_screen.dart' show StatusChip, statusColor;

/// One topic.
///
/// The section order is fixed and not negotiable: what it says, where it comes
/// from, how it was used, the caution, then the modern status in plain words.
/// The caution is never last-in-the-scroll by accident and never optional —
/// a reader who stops halfway must already have passed it.
class VidyaTopicScreen extends ConsumerWidget {
  final int topicId;
  const VidyaTopicScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final topic = ref.watch(vidyaTopicProvider(topicId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'वैदिक विद्या' : 'Vedic Science')),
      body: AsyncView(
        value: topic,
        isEmpty: (t) => t == null,
        emptyMessage: hi ? 'विषय नहीं मिला' : 'Topic not found',
        builder: (topicOrNull) {
          // Bound once: type promotion does not survive into the closures
          // below, and `t!` scattered through the tree reads as if null were
          // a real possibility here. AsyncView has already ruled it out.
          final t = topicOrNull!;
          assert(t.hasCaution,
              'vidya topic ${t.slug} has no caution — §4.15 forbids rendering it');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              Text(t.title(hi),
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2)),
              const SizedBox(height: 8),
              StatusChip(status: t.modernStatus, hindi: hi),
              const SizedBox(height: 14),

              // 1. What it says
              Text(t.desc(hi),
                  style: const TextStyle(fontSize: 15.5, height: 1.55)),
              if ((t.long(hi) ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(t.long(hi)!,
                    style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: scheme.onSurface.withValues(alpha: 0.8))),
              ],

              // 2. Where it comes from
              const SizedBox(height: 16),
              SourceChip(
                sourceName: t.sourceName,
                sourceRef: t.sourceRef,
                sourceUrl: t.sourceUrl,
                lastVerifiedAt: t.lastVerifiedAt,
                hindi: hi,
              ),

              // 3. How it was used
              if ((t.use(hi) ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                _Heading(text: hi ? 'व्यवहार में' : 'How it was used'),
                const SizedBox(height: 6),
                Text(t.use(hi)!,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: scheme.onSurface.withValues(alpha: 0.8))),
              ],

              // 4. Caution — always rendered, always bordered.
              const SizedBox(height: 20),
              _CautionPanel(text: t.caution(hi), hindi: hi),

              // 5. Modern status, in plain words.
              const SizedBox(height: 18),
              _StatusExplain(status: t.modernStatus, hindi: hi),

              RelatedRail(src: 'gyan', table: 'vidya_topics', id: t.id),
            ],
          );
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 17,
          fontWeight: FontWeight.w700));
}

/// The §4.15 panel. Bordered in the warning accent, never collapsible, never
/// styled down to a footnote.
class _CautionPanel extends StatelessWidget {
  final String text;
  final bool hindi;
  const _CautionPanel({required this.text, required this.hindi});

  static const _warn = Color(0xFFFF9F43);

  @override
  Widget build(BuildContext context) {
    // The panel is a translucent wash over the page surface, so its ink has to
    // follow the theme. A fixed dark brown reads well on cream and vanishes
    // into the dark ramp — the one panel that must never be hard to read.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF0DCC2) : const Color(0xFF4A3A22);
    final head = dark ? const Color(0xFFFFC078) : const Color(0xFFB3701C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warn.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _warn.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 17, color: head),
              const SizedBox(width: 7),
              Text(hindi ? 'सावधानी' : 'Caution',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: head)),
            ],
          ),
          const SizedBox(height: 7),
          Text(text,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: ink)),
        ],
      ),
    );
  }
}

class _StatusExplain extends StatelessWidget {
  final String status;
  final bool hindi;
  const _StatusExplain({required this.status, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = modernStatusExplain[status];
    if (e == null) return const SizedBox.shrink();
    final c = statusColor(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 34, color: c.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hindi
                    ? modernStatusLabels[status]!.$2
                    : modernStatusLabels[status]!.$1,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: c),
              ),
              const SizedBox(height: 2),
              Text(hindi ? e.$2 : e.$1,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.65))),
            ],
          ),
        ),
      ],
    );
  }
}
