import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/source_chip.dart';
import 'ask_models.dart';
import 'ask_providers.dart';

const _teal = Color(0xFF3E7F8E);
const _tealDeep = Color(0xFF1D4552);

/// Ask the Scriptures.
///
/// Every answer is a passage somebody wrote down centuries ago, selected by
/// token overlap and shown with its citation. Nothing is generated, no model
/// runs on the device, and a weak match says so.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String q) {
    FocusScope.of(context).unfocus();
    ref.read(askControllerProvider.notifier).ask(q);
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final result = ref.watch(askControllerProvider);
    final busy = ref.watch(askControllerProvider.notifier).busy;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'शास्त्र से पूछें' : 'Ask the Scriptures')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          _Field(controller: _controller, hindi: hi, onSubmit: _submit),
          const SizedBox(height: 18),
          if (busy)
            const _Consulting()
          else
            switch (result.outcome) {
              AskOutcome.empty => _Suggestions(
                  hindi: hi,
                  onPick: (q) {
                    _controller.text = q;
                    _submit(q);
                  }),
              AskOutcome.answered => _Answer(pair: result.best!, hindi: hi),
              AskOutcome.notSure =>
                _NotSure(candidates: result.candidates, hindi: hi),
            },
          if (!busy && result.outcome == AskOutcome.answered &&
              result.candidates.isNotEmpty) ...[
            const SizedBox(height: 20),
            _RelatedQuestions(
                pairs: result.candidates,
                hindi: hi,
                onPick: (q) {
                  _controller.text = q;
                  _submit(q);
                }),
          ],
          const SizedBox(height: 26),
          _Footer(hindi: hi),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final bool hindi;
  final ValueChanged<String> onSubmit;

  const _Field(
      {required this.controller, required this.hindi, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      maxLines: null,
      style: const TextStyle(fontSize: 16.5, height: 1.4),
      decoration: InputDecoration(
        hintText: hindi
            ? 'कोई प्रश्न पूछें…'
            : 'Ask a question…',
        filled: true,
        fillColor: scheme.surface,
        prefixIcon: const Icon(Icons.help_outline_rounded, color: _teal),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded, color: _teal),
          onPressed: () => onSubmit(controller.text),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _teal.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _teal.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _teal, width: 1.6),
        ),
      ),
    );
  }
}

class _Consulting extends StatefulWidget {
  const _Consulting();

  @override
  State<_Consulting> createState() => _ConsultingState();
}

class _ConsultingState extends State<_Consulting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: RotationTransition(
          turns: _c,
          child: const Icon(Icons.brightness_7_rounded,
              size: 34, color: _teal),
        ),
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  final bool hindi;
  final ValueChanged<String> onPick;
  const _Suggestions({required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final list = ref.watch(suggestedQuestionsProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hindi ? 'ये पूछकर देखें' : 'Try asking',
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in list)
              ActionChip(
                label: Text(p.question(hindi),
                    style: const TextStyle(fontSize: 12.5)),
                onPressed: () => onPick(p.question(hindi)),
                side: BorderSide(color: _teal.withValues(alpha: 0.3)),
                backgroundColor: _teal.withValues(alpha: 0.06),
              ),
          ],
        ),
      ],
    );
  }
}

/// The verse first, then our explanation, then the citation. Never the other
/// way around — the passage is the answer, our words are commentary on it.
class _Answer extends StatelessWidget {
  final QaPair pair;
  final bool hindi;
  const _Answer({required this.pair, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((pair.passageSa ?? '').isNotEmpty) ...[
            Text(pair.passageSa!,
                style: const TextStyle(
                    fontFamily: AppFonts.devanagari,
                    fontSize: 19,
                    height: 1.6,
                    color: _tealDeep)),
            const SizedBox(height: 6),
          ],
          if ((pair.passageTranslit ?? '').isNotEmpty) ...[
            Text(pair.passageTranslit!,
                style: TextStyle(
                    fontFamily: AppFonts.accent,
                    fontStyle: FontStyle.italic,
                    fontSize: 14.5,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 10),
          ],
          Text(pair.answer(hindi),
              style: const TextStyle(fontSize: 16.5, height: 1.55)),
          if ((pair.explanation(hindi) ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(pair.explanation(hindi)!,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: scheme.onSurface.withValues(alpha: 0.82))),
            ),
          ],
          const SizedBox(height: 14),
          SourceChip(
            sourceName: pair.sourceName,
            sourceRef: pair.sourceRef,
            sourceUrl: pair.sourceUrl,
            lastVerifiedAt: pair.lastVerifiedAt,
            hindi: hindi,
          ),
          if (pair.scriptureSectionId != null) ...[
            const SizedBox(height: 12),
            _ReadInContext(sectionId: pair.scriptureSectionId!, hindi: hindi),
          ],
        ],
      ),
    );
  }
}

/// Opens the reader at the exact verse.
///
/// Hidden rather than shown-and-broken when the section cannot be located:
/// a button that lands the reader on the wrong line is worse than no button.
class _ReadInContext extends ConsumerWidget {
  final int sectionId;
  final bool hindi;
  const _ReadInContext({required this.sectionId, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(verseLocationProvider(sectionId)).valueOrNull;
    if (loc == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () =>
          context.push('/scriptures/book/${loc.bookId}?v=${loc.index}'),
      icon: const Icon(Icons.menu_book_rounded, size: 16),
      label: Text(hindi ? 'प्रसंग में पढ़ें' : 'Read in context'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _tealDeep,
        side: BorderSide(color: _teal.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// The honest failure. §4.19 requires this to be a real state, not a fallback
/// that quietly shows the least-bad row as though it were the answer.
class _NotSure extends StatelessWidget {
  final List<QaPair> candidates;
  final bool hindi;
  const _NotSure({required this.candidates, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
          ),
          child: Text(
            hindi
                ? 'इस प्रश्न के लिए कोई स्पष्ट वचन नहीं मिला। अनुमान लगाने के बजाय यह कहना ठीक है।'
                : 'I could not find a clear passage for this. Better to say so than to guess.',
            style: const TextStyle(fontSize: 14.5, height: 1.5),
          ),
        ),
        if (candidates.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(hindi ? 'निकटतम प्रश्न' : 'Closest questions',
              style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          for (final c in candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· ${c.question(hindi)}',
                  style: const TextStyle(fontSize: 13.5, height: 1.4)),
            ),
        ],
      ],
    );
  }
}

class _RelatedQuestions extends StatelessWidget {
  final List<QaPair> pairs;
  final bool hindi;
  final ValueChanged<String> onPick;
  const _RelatedQuestions(
      {required this.pairs, required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hindi ? 'और पूछें' : 'Related questions',
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in pairs)
              ActionChip(
                label: Text(p.question(hindi),
                    style: const TextStyle(fontSize: 12.5)),
                onPressed: () => onPick(p.question(hindi)),
                side: BorderSide(color: _teal.withValues(alpha: 0.3)),
                backgroundColor: _teal.withValues(alpha: 0.06),
              ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool hindi;
  const _Footer({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 13, color: scheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            hindi
                ? 'उत्तर शास्त्रों के वचन हैं — चुने गए, रचे नहीं गए।'
                : 'Answers are passages from the scriptures, selected — not generated.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
