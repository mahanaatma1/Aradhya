import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'quiz_models.dart';
import 'quiz_providers.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int index = 0;
  int score = 0;
  String? selected;

  void _answer(QuizQuestion q, String key) {
    if (selected != null) return;
    setState(() {
      selected = key;
      if (key == q.correctKey) score++;
    });
  }

  void _next(int total) {
    if (index + 1 >= total) {
      _showResult(total);
    } else {
      setState(() {
        index++;
        selected = null;
      });
    }
  }

  void _showResult(int total) {
    final hi = ref.read(isHindiProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hi ? 'आपके अंक' : 'Your score'),
        content: Text(hi ? '$total में से $score सही' : '$score / $total correct',
            style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(hi ? 'पूर्ण' : 'Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                index = 0;
                score = 0;
                selected = null;
              });
              ref.invalidate(quizSessionProvider);
            },
            child: Text(hi ? 'फिर से खेलें' : 'Play again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final session = ref.watch(quizSessionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'ज्ञान प्रश्नोत्तरी' : 'Knowledge Quiz')),
      body: AsyncView(
        value: session,
        isEmpty: (l) => l.isEmpty,
        builder: (questions) {
          final total = questions.length;
          final q = questions[index.clamp(0, total - 1)];
          return Column(
            children: [
              LinearProgressIndicator(value: (index + 1) / total),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hi
                            ? 'प्रश्न ${index + 1} / $total  ·  अंक $score'
                            : 'Question ${index + 1} of $total  ·  Score $score',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Quiz content is data-driven: question/options show
                      // Hindi via q.question(hi) when the content database has
                      // it, and fall back to English otherwise.
                      Text(
                        q.question(hi),
                        style: TextStyle(
                          fontFamily:
                              hi ? AppFonts.devanagari : AppFonts.display,
                          fontSize: 22,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...q.options.map((o) => _OptionTile(
                            option: o,
                            hindi: hi,
                            state: _stateFor(o, q),
                            onTap: () => _answer(q, o.key),
                          )),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected == null ? null : () => _next(total),
                      child: Text(index + 1 >= total
                          ? (hi ? 'समाप्त' : 'Finish')
                          : (hi ? 'अगला' : 'Next')),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _OptionState _stateFor(QuizOption o, QuizQuestion q) {
    if (selected == null) return _OptionState.idle;
    if (o.key == q.correctKey) return _OptionState.correct;
    if (o.key == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final bool hindi;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.hindi,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color border = scheme.outline.withValues(alpha: 0.3);
    Color bg = scheme.surface;
    Color fg = scheme.onSurface;
    IconData? icon;

    switch (state) {
      case _OptionState.correct:
        border = const Color(0xFF2E7D32);
        bg = const Color(0xFF2E7D32).withValues(alpha: 0.12);
        icon = Icons.check_circle_rounded;
        break;
      case _OptionState.wrong:
        border = scheme.error;
        bg = scheme.error.withValues(alpha: 0.1);
        icon = Icons.cancel_rounded;
        break;
      case _OptionState.dimmed:
        fg = fg.withValues(alpha: 0.5);
        break;
      case _OptionState.idle:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.text(hindi),
                      style: TextStyle(
                        fontSize: 16,
                        color: fg,
                        fontFamily: hindi ? AppFonts.devanagari : AppFonts.body,
                      ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: border),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
