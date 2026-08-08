import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../related/related_rail.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'puja_models.dart';

/// Puja Vidhi detail — when to perform, samagri (items), step-by-step vidhi,
/// the key mantra and benefits.
class PujaDetailScreen extends ConsumerWidget {
  final PujaVidhi puja;
  const PujaDetailScreen({super.key, required this.puja});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final mantra = puja.mantra;

    return Scaffold(
      appBar: AppBar(
        title: Text(puja.title(hi), style: const TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(puja.title(hi),
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 24)),
          if (puja.deity != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(puja.deity!,
                  style: TextStyle(color: scheme.primary, fontSize: 14)),
            ),
          const SizedBox(height: 16),

          if (puja.whenText(hi) != null)
            _Section(
              icon: Icons.event_available_rounded,
              label: hi ? 'कब करें' : 'When to perform',
              child: Text(puja.whenText(hi)!,
                  style: const TextStyle(fontSize: 15, height: 1.55)),
            ),

          if (puja.items.isNotEmpty)
            _Section(
              icon: Icons.checklist_rounded,
              label: hi ? 'सामग्री' : 'Samagri (items)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final it in puja.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ',
                              style: TextStyle(color: scheme.primary)),
                          Expanded(
                              child: Text(it,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (puja.steps.isNotEmpty)
            _Section(
              icon: Icons.format_list_numbered_rounded,
              label: hi ? 'विधि' : 'Vidhi (steps)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < puja.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.14),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(puja.steps[i],
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.45))),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (mantra.sanskrit != null) ...[
            const SizedBox(height: 4),
            StitchedCard(
              gradient: const LinearGradient(
                colors: [AppColors.terracotta, AppColors.terracottaDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              stitchColor: Colors.white.withValues(alpha: 0.6),
              radius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(mantra.sanskrit!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppFonts.devanagari,
                          fontSize: 18,
                          height: 1.7,
                          color: Color(0xFFFDEEDE))),
                  if (mantra.translation != null) ...[
                    const SizedBox(height: 10),
                    Text(mantra.translation!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13.5,
                            color: Color(0xFFF6D9C8))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (puja.benefitsEn != null && puja.benefitsEn!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: scheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(puja.benefitsEn!,
                        style: const TextStyle(fontSize: 14.5, height: 1.5)),
                  ),
                ],
              ),
            ),
                  // The deity's temples, aarti, mantras and vrat kathas.
          RelatedRail(table: 'puja_vidhi', id: puja.id),
],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _Section(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
