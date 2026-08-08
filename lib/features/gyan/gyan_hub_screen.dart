import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import 'gyan_modules.dart';

/// The home for all Gyan modules.
///
/// A pushed route rather than a tab: the bottom bar is already tight with five
/// Hindi labels, and promoting Gyan is a deliberate later step (merging Rashifal
/// into Astrology) that should land on its own revertible commit.
///
/// Tiles come from [gyanModules], so adding a module updates this grid, the
/// search filter chips and the content pipeline's module list at once.
class GyanHubScreen extends ConsumerWidget {
  const GyanHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;

    final shipped = gyanModules.where((m) => m.shipped).toList();
    final soon = gyanModules.where((m) => !m.shipped).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'ज्ञान' : 'Gyan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _Hero(hi: hi),
          const SizedBox(height: 18),
          if (shipped.isNotEmpty) ...[
            _Label(hi ? 'खुला' : 'AVAILABLE'),
            const SizedBox(height: 10),
            _Grid(modules: shipped, cats: cats, hi: hi, enabled: true),
            const SizedBox(height: 22),
          ],
          if (soon.isNotEmpty) ...[
            _Label(hi ? 'जल्द आ रहा है' : 'COMING SOON'),
            const SizedBox(height: 10),
            _Grid(modules: soon, cats: cats, hi: hi, enabled: false),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
}

class _Hero extends StatelessWidget {
  final bool hi;
  const _Hero({required this.hi});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3E7F8E), Color(0xFF1D4552)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hi ? 'ज्ञान' : 'GYAN',
                style: TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.goldBright)),
            const SizedBox(height: 6),
            Text(hi ? 'सनातन का संसार' : 'The world of Sanatan',
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    height: 1.08,
                    color: Color(0xFFFCEFE2))),
            const SizedBox(height: 8),
            Text(
              hi
                  ? 'देव · ऋषि · अस्त्र · प्रतीक · महाकाव्य · सृष्टि'
                  : 'Deities · Sages · Astras · Symbols · Epics · Cosmos',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: const Color(0xFFFCEFE2).withValues(alpha: 0.82)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<GyanModule> modules;
  final CategoryColors cats;
  final bool hi;
  final bool enabled;
  const _Grid({
    required this.modules,
    required this.cats,
    required this.hi,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // 0.88 not 0.95: Devanagari line boxes are ~15-20% taller, so a
        // two-line Hindi blurb clipped at the English-derived ratio.
        childAspectRatio: 0.88,
      ),
      itemCount: modules.length,
      itemBuilder: (context, i) =>
          _Tile(module: modules[i], cats: cats, hi: hi, enabled: enabled),
    );
  }
}

class _Tile extends StatelessWidget {
  final GyanModule module;
  final CategoryColors cats;
  final bool hi;
  final bool enabled;
  const _Tile({
    required this.module,
    required this.cats,
    required this.hi,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final style = module.style(cats);
    final scheme = Theme.of(context).colorScheme;

    // Unshipped modules render flat and muted rather than gradient. The state
    // has to look deliberately different, not merely non-tappable, or a user
    // reads it as a broken tile.
    final gradient = enabled
        ? style.linear
        : LinearGradient(colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          ]);
    final fg = enabled ? const Color(0xFFFFF8EF) : scheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled
          ? () => context.push(module.route)
          : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(hi
                      ? '${module.titleHi} — जल्द आ रहा है'
                      : '${module.titleEn} — coming soon'),
                ),
              ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: enabled
              ? null
              : Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: style.gradient.last.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (enabled)
              Positioned(
                right: -26,
                top: -26,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (enabled ? Colors.white : scheme.onSurface)
                          .withValues(alpha: enabled ? 0.22 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(module.icon,
                        color: fg.withValues(alpha: enabled ? 1 : 0.55),
                        size: 21),
                  ),
                  const Spacer(),
                  Text(
                    module.title(hi),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.15,
                      color: fg.withValues(alpha: enabled ? 1 : 0.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.blurb(hi),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color: fg.withValues(alpha: enabled ? 0.9 : 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
