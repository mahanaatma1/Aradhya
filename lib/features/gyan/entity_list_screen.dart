import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'entity_models.dart';
import 'entity_providers.dart';
import 'symbol_motifs.dart';

/// One list screen for every entity encyclopedia — Rishis, Astras, Symbols.
///
/// The presentation varies by kind (symbols read as a glyph grid, weapons as
/// striped rows), but the data and navigation are identical, so this is one
/// screen with a layout switch rather than three near-copies.
class EntityListScreen extends ConsumerStatefulWidget {
  final String kind;
  final String titleEn;
  final String titleHi;

  const EntityListScreen({
    super.key,
    required this.kind,
    required this.titleEn,
    required this.titleHi,
  });

  @override
  ConsumerState<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends ConsumerState<EntityListScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final value = ref.watch(entitiesByKindProvider(widget.kind));
    final isSymbolGrid = widget.kind == 'symbol';

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? widget.titleHi : widget.titleEn),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AsyncView(
        value: value,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई प्रविष्टि नहीं' : 'Nothing here yet',
        builder: (all) {
          final categories = <String>{
            for (final e in all)
              if (e.category != null && e.category!.isNotEmpty) e.category!,
          }.toList()
            ..sort();

          final list = _category == null
              ? all
              : all.where((e) => e.category == _category).toList();

          return Column(
            children: [
              if (categories.length > 1)
                _CategoryChips(
                  categories: categories,
                  selected: _category,
                  hindi: hi,
                  onSelected: (c) => setState(() => _category = c),
                ),
              Expanded(
                child: isSymbolGrid
                    ? _SymbolGrid(entities: list, hindi: hi)
                    : _EntityRows(entities: list, hindi: hi),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final bool hindi;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.hindi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String? value, String label) {
      final on = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: (_) => onSelected(on ? null : value),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? scheme.primary : scheme.onSurface.withValues(alpha: .8),
          ),
          selectedColor: scheme.primary.withValues(alpha: 0.14),
          side: BorderSide(
              color: on
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.25)),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(null, hindi ? 'सभी' : 'All'),
          for (final c in categories) chip(c, _pretty(c)),
        ],
      ),
    );
  }

  static String _pretty(String slug) => slug
      .split('-')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Wide rows with a left accent stripe — used for deities, rishis and weapons.
class _EntityRows extends StatelessWidget {
  final List<Entity> entities;
  final bool hindi;
  const _EntityRows({required this.entities, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final accent = cats.gyan.gradient.last;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: entities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = entities[i];
        final script = e.scriptLine();
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/gyan/entity/${e.id}'),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Importance is legible at a glance: major figures get a
                  // fully saturated stripe, minor ones a faint one.
                  Container(
                    width: 4,
                    color: accent.withValues(
                        alpha: (1.15 - 0.18 * e.importance).clamp(0.2, 1.0)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  e.title(hindi),
                                  style: const TextStyle(
                                    fontFamily: AppFonts.display,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (e.glyph != null && e.glyph!.isNotEmpty)
                                Text(e.glyph!,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: accent.withValues(alpha: 0.85))),
                            ],
                          ),
                          if (script != null) ...[
                            const SizedBox(height: 2),
                            Text(script,
                                style: TextStyle(
                                    fontFamily: AppFonts.accent,
                                    fontSize: 12.5,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.55))),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            e.desc(hindi),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.38,
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glyph-first grid for symbols, where the mark itself is the content.
class _SymbolGrid extends StatelessWidget {
  final List<Entity> entities;
  final bool hindi;
  const _SymbolGrid({required this.entities, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final accent = cats.gyan.gradient.last;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: entities.length,
      itemBuilder: (context, i) {
        final e = entities[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/gyan/entity/${e.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: e.glyph != null && e.glyph!.isNotEmpty
                        ? Text(e.glyph!,
                            style: TextStyle(
                                fontSize: 46,
                                height: 1,
                                color: scheme.primary))
                        : SymbolMotif.covered.contains(e.slug)
                            ? SymbolMotif(slug: e.slug, color: scheme.primary)
                            : Icon(Icons.auto_awesome_rounded,
                                size: 34,
                                color: accent.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.title(hindi),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  EntityKinds.label(e.category ?? e.kind, hindi),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
