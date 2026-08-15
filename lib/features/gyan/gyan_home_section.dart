import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import 'gyan_modules.dart';

/// "Explore Gyan" — a horizontal rail of featured modules on Home, plus a
/// "See all" into the hub.
///
/// Shipped modules are shown first so the rail leads with what actually works;
/// the rest are visible but marked, which is more honest than hiding them and
/// also advertises what is coming.
class GyanHomeSection extends ConsumerWidget {
  const GyanHomeSection({super.key});

  /// Featured modules, in rail order. Kept short — this is a teaser, and the
  /// hub is one tap away.
  static const _featured = <String>[
    'journey',
    'graph',
    'rishis',
    'astras',
    'festivals',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final scheme = Theme.of(context).colorScheme;

    final modules = [
      for (final id in _featured)
        if (gyanModuleById(id) != null) gyanModuleById(id)!,
    ]..sort((a, b) {
        if (a.shipped == b.shipped) return 0;
        return a.shipped ? -1 : 1;
      });

    if (modules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hi ? 'ज्ञान संसार' : 'Explore Gyan',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/gyan'),
                child: Text(hi ? 'सभी देखें' : 'See all',
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: modules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final m = modules[i];
              final style = m.style(cats);
              return SizedBox(
                width: 140,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: m.shipped
                      ? () => context.push(m.route)
                      : () => context.go('/gyan'),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: m.shipped ? style.linear : null,
                      color: m.shipped
                          ? null
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: m.shipped
                          ? null
                          : Border.all(
                              color: scheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(m.icon,
                            size: 22,
                            color: m.shipped
                                ? const Color(0xFFFFF8EF)
                                : scheme.onSurface.withValues(alpha: 0.5)),
                        const Spacer(),
                        Text(
                          m.title(hi),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.15,
                            color: m.shipped
                                ? const Color(0xFFFFF8EF)
                                : scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m.shipped
                              ? m.blurb(hi)
                              : (hi ? 'जल्द आ रहा है' : 'Coming soon'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: m.shipped
                                ? const Color(0xFFFFF8EF).withValues(alpha: 0.88)
                                : scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
