import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../related/related_rail.dart' show relatedProvider;
import 'quiz_providers.dart';

/// Browse trivia facts as a simple, calm reading list.
class TriviaScreen extends ConsumerWidget {
  const TriviaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final trivia = ref.watch(triviaProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'रोचक तथ्य' : 'Trivia')),
      body: AsyncView(
        value: trivia,
        isEmpty: (l) => l.isEmpty,
        builder: (facts) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: facts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 20, color: scheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        // Trivia facts are data-driven: they show Hindi when
                        // the content database has it, else fall back to
                        // English.
                        child: Text(
                          facts[i].text(hi),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            fontFamily:
                                hi ? AppFonts.devanagari : AppFonts.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _TriviaLink(triviaId: facts[i].id, hi: hi),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One small tappable link to the entity a fact is actually about, when the
/// build-time relate pass found one. Renders nothing when it didn't — most
/// trivia facts don't name a single major figure, and staying silent there
/// is honest instead of showing a link to something unrelated.
class _TriviaLink extends ConsumerWidget {
  final int triviaId;
  final bool hi;
  const _TriviaLink({required this.triviaId, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
            .watch(relatedProvider(
                (src: 'content', table: 'trivia_facts', id: triviaId)))
            .valueOrNull ??
        const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 32),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final it in items)
            ActionChip(
              avatar: Icon(Icons.arrow_outward_rounded,
                  size: 14, color: scheme.secondary),
              label: Text(it.title(hi)),
              onPressed: () => context.push(it.route),
            ),
        ],
      ),
    );
  }
}
