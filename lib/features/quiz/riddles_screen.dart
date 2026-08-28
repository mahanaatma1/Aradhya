import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../shared/widgets/skeleton.dart';
import '../related/related_rail.dart';
import 'riddles_providers.dart';

/// Riddles game — clues reveal one at a time; guess the answer for more points
/// the fewer clues you needed. "Who Am I?" style over 365 clue riddles.
class RiddlesScreen extends ConsumerStatefulWidget {
  const RiddlesScreen({super.key});

  @override
  ConsumerState<RiddlesScreen> createState() => _RiddlesScreenState();
}

class _RiddlesScreenState extends ConsumerState<RiddlesScreen> {
  int _index = 0;
  int _revealed = 1; // clues shown so far
  bool _solved = false;
  int _score = 0;

  void _next(int total) {
    setState(() {
      _index = (_index + 1) % total;
      _revealed = 1;
      _solved = false;
    });
  }

  void _reveal(Riddle r) {
    if (_revealed < r.clues(false).length) {
      setState(() => _revealed++);
    }
  }

  void _solve(Riddle r) {
    if (_solved) return;
    final gained = (r.clues(false).length - _revealed + 1).clamp(1, 10);
    setState(() {
      _solved = true;
      _score += gained;
    });
    ref.read(streakProvider.notifier).addPoints(gained);
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final async = ref.watch(riddlesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'पहेलियाँ' : 'Riddles'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('★ $_score',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.secondary)),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const SkeletonReader(),
        error: (e, _) => Center(child: Text('$e')),
        data: (riddles) {
          if (riddles.isEmpty) {
            return Center(child: Text(hi ? 'कोई पहेली नहीं' : 'No riddles'));
          }
          final r = riddles[_index % riddles.length];
          final clues = r.clues(hi);
          final shown = _revealed.clamp(1, clues.length);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.dharmaPurple, Color(0xFF3B1E70)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hi ? 'मैं कौन हूँ?' : 'Who am I?',
                              style: const TextStyle(
                                  color: Color(0xFFEDE3FF),
                                  fontSize: 13,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          Text(
                            _solved ? r.answer : '?',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 34,
                              color: Colors.white,
                            ),
                          ),
                          if (!_solved) ...[
                            const SizedBox(height: 6),
                            Text(
                              hi
                                  ? 'मन ही मन अनुमान लगाएँ, फिर उत्तर देखें'
                                  : 'Guess in your mind, then reveal',
                              style: const TextStyle(
                                  color: Color(0xFFEDE3FF),
                                  fontSize: 12.5,
                                  height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < shown; i++)
                      _ClueTile(number: i + 1, text: clues[i], hi: hi),
                    if (!_solved && shown < clues.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: () => _reveal(r),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: Text(hi
                              ? 'अगला संकेत (${clues.length - shown})'
                              : 'Next clue (${clues.length - shown} left)'),
                        ),
                      ),
                    if (_solved)
                      RelatedRail(table: 'clue_riddles', id: r.id),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _solved
                            ? OutlinedButton(
                                onPressed: () => _next(riddles.length),
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16)),
                                child: Text(hi ? 'अगली' : 'Next'),
                              )
                            : FilledButton.icon(
                                onPressed: () => _solve(r),
                                icon: const Icon(Icons.visibility_rounded),
                                label: Text(hi ? 'उत्तर दिखाएँ' : 'Reveal answer'),
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClueTile extends StatelessWidget {
  final int number;
  final String text;
  final bool hi;
  const _ClueTile(
      {required this.number, required this.text, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.primary.withValues(alpha: 0.14),
            child: Text('$number',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontFamily: hi ? AppFonts.devanagari : AppFonts.body)),
          ),
        ],
      ),
    );
  }
}
