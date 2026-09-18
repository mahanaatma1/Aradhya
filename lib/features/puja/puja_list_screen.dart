import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../devotional/deity_accent.dart';
import 'puja_providers.dart';

/// Puja Vidhi directory — grouped ritual guides with deity accents.
class PujaListScreen extends ConsumerWidget {
  const PujaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final pujas = ref.watch(pujaVidhiProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'पूजा विधि' : 'Puja Vidhi')),
      body: AsyncView(
        value: pujas,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'कोई विधि नहीं' : 'No guides',
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = list[i];
            final accent = DeityAccent.of(p.deityEn);
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/puja-detail', extra: p),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(accent.icon, color: accent.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title(hi),
                                style: const TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17)),
                            if (p.category(hi) != null)
                              Text(p.category(hi)!,
                                  style: TextStyle(
                                      fontSize: 13, color: accent.color)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
