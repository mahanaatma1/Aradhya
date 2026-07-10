import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 20, color: scheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    // Trivia facts are data-driven: they show Hindi when the
                    // content database has it, and fall back to English.
                    child: Text(
                      facts[i].text(hi),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        fontFamily: hi ? AppFonts.devanagari : AppFonts.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
