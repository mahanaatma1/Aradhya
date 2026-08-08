import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/notifications/reminder_tile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/widgets/source_chip.dart';
import '../../shared/widgets/stitched_border.dart';
import 'journal_models.dart';
import 'journal_providers.dart';

/// Karma Journal — a private daily reflection.
///
/// Everything here stays on the device. That is stated plainly on the screen
/// rather than buried in a policy, because a person deciding whether to write
/// something honest needs to know before they write it, not after.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final entries = ref.watch(journalProvider);
    final prompt = ref.watch(todaysPromptProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'कर्म डायरी' : 'Karma Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journal/new'),
        icon: const Icon(Icons.edit_rounded),
        label: Text(hi ? 'लिखें' : 'Write'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (prompt != null) _PromptCard(prompt: prompt, hindi: hi),
          const SizedBox(height: 18),
          _MoodStrip(hindi: hi),
          const SizedBox(height: 20),
          if (entries.isNotEmpty) ...[
            _Heatmap(byDay: ref.read(journalProvider.notifier).byDay),
            const SizedBox(height: 18),
            Text(
              hi ? 'आपकी प्रविष्टियाँ' : 'YOUR ENTRIES',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            for (final e in entries) _EntryRow(entry: e, hindi: hi),
          ] else
            _EmptyState(hindi: hi),
          const SizedBox(height: 20),
          ReminderTile(
            kind: 'journal',
            labelEn: 'Daily reminder',
            labelHi: 'दैनिक स्मरण',
            titleEn: 'Karma Journal',
            titleHi: 'कर्म डायरी',
            bodyEn: "Today's prompt is waiting for you.",
            bodyHi: 'आज का प्रश्न आपकी प्रतीक्षा में है।',
            // Evening by default: reflection reads better looking back on a
            // day than forward into one.
            defaultMinuteOfDay: 21 * 60,
          ),
          const SizedBox(height: 24),
          _PrivacyNote(hindi: hi),
        ],
      ),
    );
  }
}

class _PromptCard extends ConsumerWidget {
  final JournalPrompt prompt;
  final bool hindi;
  const _PromptCard({required this.prompt, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return StitchedCard(
      // The signature dashed outline, in the sadhana green used across the
      // personal features.
      stitchColor: AppColors.goldBright.withValues(alpha: 0.75),
      gradient: const LinearGradient(
        colors: [Color(0xFF3F7A5E), Color(0xFF25533F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hindi ? 'आज का प्रश्न' : 'TODAY',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldBright.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: hindi ? 'दूसरा प्रश्न' : 'Another prompt',
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: Color(0xFFFFF8EF)),
                onPressed: () =>
                    ref.read(promptOffsetProvider.notifier).state++,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            prompt.prompt(hindi),
            style: const TextStyle(
              fontFamily: AppFonts.accent,
              fontSize: 19,
              height: 1.45,
              color: Color(0xFFFFF8EF),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/journal/new'),
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: Text(hindi ? 'उत्तर लिखें' : 'Write on this'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF25533F),
                  ),
                ),
              ),
            ],
          ),
          if (prompt.sourceName != null) ...[
            const SizedBox(height: 10),
            // The prompt is our writing; the teaching behind it is not.
            DefaultTextStyle(
              style: TextStyle(color: scheme.onSurface),
              child: SourceChip(
                hindi: hindi,
                sourceName: prompt.sourceName,
                sourceRef: prompt.sourceRef,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One-tap mood logging: writes a short entry so a day still gets recorded
/// when there is no energy to write a paragraph.
class _MoodStrip extends ConsumerWidget {
  final bool hindi;
  const _MoodStrip({required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hindi ? 'आज कैसा बीता?' : 'HOW WAS TODAY?',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final key in Moods.keys)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await ref.read(journalProvider.notifier).save(
                            body: Moods.label(key, false),
                            mood: key,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(hindi ? 'दर्ज हुआ' : 'Noted'),
                        ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.22)),
                      ),
                      child: Column(
                        children: [
                          _MoodGlyph(mood: key, size: 22),
                          const SizedBox(height: 5),
                          Text(
                            Moods.label(key, hindi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Hand-drawn mood marks.
///
/// Not emoji: emoji carry a cartoon register that sits badly against Devanagari
/// scripture text, and they render differently on every device.
class _MoodGlyph extends StatelessWidget {
  final String mood;
  final double size;
  const _MoodGlyph({required this.mood, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = switch (mood) {
      'shanti' => const Color(0xFF3E8E8E),
      'harsha' => const Color(0xFFD4AF37),
      'vishada' => const Color(0xFF5C6BC0),
      'krodha' => const Color(0xFFC0392B),
      'bhaya' => const Color(0xFF7A5AA8),
      _ => Theme.of(context).colorScheme.primary,
    };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MoodPainter(mood: mood, color: color)),
    );
  }
}

class _MoodPainter extends CustomPainter {
  final String mood;
  final Color color;
  const _MoodPainter({required this.mood, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color;
    final fill = Paint()..color = color;

    switch (mood) {
      case 'shanti': // still water — concentric rings
        for (final f in [1.0, 0.62, 0.28]) {
          canvas.drawCircle(c, r * f, stroke);
        }
      case 'harsha': // a small sun
        canvas.drawCircle(c, r * 0.42, fill);
        for (var i = 0; i < 8; i++) {
          final a = i * 3.14159 / 4;
          canvas.drawLine(
            c + Offset.fromDirection(a, r * 0.62),
            c + Offset.fromDirection(a, r * 0.98),
            stroke,
          );
        }
      case 'vishada': // a weight pulling down
        canvas.drawCircle(c.translate(0, -r * 0.3), r * 0.34, stroke);
        canvas.drawLine(c.translate(0, r * 0.05),
            c.translate(0, r * 0.95), stroke);
      case 'krodha': // a sharp upward flame
        final p = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.6, c.dy + r * 0.7)
          ..lineTo(c.dx - r * 0.6, c.dy + r * 0.7)
          ..close();
        canvas.drawPath(p, stroke);
      case 'bhaya': // an unclosed circle
        canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.8),
            -0.6, 5.1, false, stroke);
      default:
        canvas.drawCircle(c, r * 0.7, stroke);
    }
  }

  @override
  bool shouldRepaint(_MoodPainter old) =>
      old.mood != mood || old.color != color;
}

/// Twelve-week grid, matching the japa heatmap so the app reads as one system.
class _Heatmap extends StatelessWidget {
  final Map<String, int> byDay;
  const _Heatmap({required this.byDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    const weeks = 12;

    return SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = weeks - 1; w >= 0; w--)
            Expanded(
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(builder: (_) {
                      final date = today.subtract(
                          Duration(days: w * 7 + (6 - d)));
                      final n = byDay[dayStamp(date)] ?? 0;
                      return Container(
                        margin: const EdgeInsets.all(1.5),
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2.5),
                          color: n == 0
                              ? scheme.outline.withValues(alpha: 0.12)
                              : const Color(0xFF25533F).withValues(
                                  alpha: (0.35 + 0.2 * n).clamp(0.35, 1.0)),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  final JournalEntry entry;
  final bool hindi;
  const _EntryRow({required this.entry, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/journal/entry/${entry.id}'),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.mood != null)
                Padding(
                  padding: const EdgeInsets.only(right: 11, top: 2),
                  child: _MoodGlyph(mood: entry.mood!, size: 20),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.dayStamp,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hindi;
  const _EmptyState({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded,
              size: 38, color: scheme.onSurface.withValues(alpha: 0.22)),
          const SizedBox(height: 12),
          Text(
            hindi
                ? 'अभी कुछ नहीं लिखा गया।'
                : 'Nothing written yet.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            hindi
                ? 'ऊपर का प्रश्न एक आरंभ है — दो पंक्तियाँ भी पर्याप्त हैं।'
                : 'The prompt above is a place to start — two lines is enough.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final bool hindi;
  const _PrivacyNote({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            hindi
                ? 'आपकी प्रविष्टियाँ इसी उपकरण पर रहती हैं। कुछ भी कहीं नहीं भेजा जाता।'
                : 'Your entries stay on this device. Nothing is uploaded anywhere.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
