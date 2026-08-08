import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'entity_models.dart';
import 'entity_providers.dart';

/// Lineage view.
///
/// This is **not a separate dataset** — it is a projection of `relations`
/// filtered to the lineage edges. Storing lineages separately would guarantee
/// drift: a sage's children would eventually be recorded twice and disagree.
///
/// Generations run top to bottom. Where traditions differ, both edges are kept
/// (with a `tradition` label) and the header says which reading is shown, per
/// reference doc §4.2 — the app does not pick a winner.
class FamilyTreeScreen extends ConsumerStatefulWidget {
  /// Entity to root the tree at. Null opens the picker.
  final int? rootId;
  const FamilyTreeScreen({super.key, this.rootId});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  int? _root;

  @override
  void initState() {
    super.initState();
    _root = widget.rootId;
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final all = ref.watch(allEntitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'वंशावली' : 'Family Tree'),
        actions: [
          if (_root != null)
            IconButton(
              tooltip: hi ? 'दूसरा मूल चुनें' : 'Choose another root',
              icon: const Icon(Icons.account_tree_rounded),
              onPressed: () => setState(() => _root = null),
            ),
        ],
      ),
      body: AsyncView(
        value: all,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'कोई वंशावली नहीं' : 'No lineage data yet',
        builder: (entities) {
          if (_root == null) {
            return _RootPicker(
              entities: entities,
              hindi: hi,
              onPick: (id) => setState(() => _root = id),
            );
          }
          return _Tree(
            rootId: _root!,
            byId: {for (final e in entities) e.id: e},
            hindi: hi,
            onReroot: (id) => setState(() => _root = id),
          );
        },
      ),
    );
  }
}

/// Only entities that actually have lineage edges are offered as roots —
/// opening a tree with a single lonely node is a dead end.
class _RootPicker extends ConsumerWidget {
  final List<Entity> entities;
  final bool hindi;
  final ValueChanged<int> onPick;
  const _RootPicker(
      {required this.entities, required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          hindi
              ? 'किसी नाम से आरंभ करें। वंशावली उसी को केंद्र मानकर बनती है।'
              : 'Start from a name. The tree is drawn around whoever you pick.',
          style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: 16),
        for (final e in entities.where((e) => e.importance <= 2))
          _RootRow(entity: e, hindi: hindi, onPick: onPick),
      ],
    );
  }
}

class _RootRow extends ConsumerWidget {
  final Entity entity;
  final bool hindi;
  final ValueChanged<int> onPick;
  const _RootRow(
      {required this.entity, required this.hindi, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rels =
        ref.watch(entityRelationsProvider(entity.id)).valueOrNull ?? const [];
    final lineage = rels.where((r) => r.family == 'lineage').toList();
    if (lineage.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onPick(entity.id),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.title(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '${lineage.length} ${hindi ? "संबंध" : "family links"}',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three bands: parents above, the root, then spouses and children below.
///
/// Deliberately not a full recursive genealogy. At this data volume a
/// three-band view around a movable root is more readable than a sprawling
/// canvas, and re-rooting (long-press) walks the tree one step at a time.
class _Tree extends ConsumerWidget {
  final int rootId;
  final Map<int, Entity> byId;
  final bool hindi;
  final ValueChanged<int> onReroot;

  const _Tree({
    required this.rootId,
    required this.byId,
    required this.hindi,
    required this.onReroot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = byId[rootId];
    final rels =
        ref.watch(entityRelationsProvider(rootId)).valueOrNull ?? const [];
    if (root == null) return const SizedBox.shrink();

    final parents = rels
        .where((r) => r.relType == 'child_of' || r.relType == 'parent_of')
        .toList();
    final partners = rels
        .where((r) => r.relType == 'spouse_of' || r.relType == 'consort_of')
        .toList();
    final children = rels
        .where((r) => r.relType == 'father_of' || r.relType == 'mother_of')
        .toList();
    final siblings = rels.where((r) => r.relType == 'sibling_of').toList();

    // Traditions that disagree are labelled, never silently reconciled.
    final traditions = {
      for (final r in rels)
        if (r.tradition != null && r.tradition!.isNotEmpty) r.tradition!,
    };

    final scheme = Theme.of(context).colorScheme;

    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 2.4,
      boundaryMargin: const EdgeInsets.all(80),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            if (parents.isNotEmpty) ...[
              _BandLabel(hindi ? 'माता-पिता' : 'PARENTS'),
              _Band(relations: parents, hindi: hindi, onReroot: onReroot),
              const _Connector(),
            ],
            _RootCard(entity: root, hindi: hindi),
            if (partners.isNotEmpty) ...[
              const SizedBox(height: 8),
              _BandLabel(hindi ? 'सहचर' : 'CONSORT'),
              _Band(relations: partners, hindi: hindi, onReroot: onReroot),
            ],
            if (children.isNotEmpty) ...[
              const _Connector(),
              _BandLabel(hindi ? 'संतान' : 'CHILDREN'),
              _Band(relations: children, hindi: hindi, onReroot: onReroot),
            ],
            if (siblings.isNotEmpty) ...[
              const SizedBox(height: 14),
              _BandLabel(hindi ? 'भाई-बहन' : 'SIBLINGS'),
              _Band(relations: siblings, hindi: hindi, onReroot: onReroot),
            ],
            if (parents.isEmpty &&
                partners.isEmpty &&
                children.isEmpty &&
                siblings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  hindi
                      ? 'इस नाम के लिए अभी कोई वंश-संबंध दर्ज नहीं है।'
                      : 'No family links recorded for this name yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              traditions.isEmpty
                  ? (hindi
                      ? 'लंबे समय तक दबाकर किसी नाम को केंद्र बनाएँ।'
                      : 'Long-press a name to re-root the tree there.')
                  : (hindi
                      ? 'परंपरा अनुसार: ${traditions.join(", ")}'
                      : 'As given in: ${traditions.join(", ")}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandLabel extends StatelessWidget {
  final String text;
  const _BandLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text,
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            )),
      );
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        height: 22,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: AppColors.gold.withValues(alpha: 0.5),
      );
}

class _RootCard extends StatelessWidget {
  final Entity entity;
  final bool hindi;
  const _RootCard({required this.entity, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/gyan/entity/${entity.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Text(entity.title(hindi),
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFFFFF8EF))),
            if (entity.titleSa != null && entity.titleSa!.isNotEmpty)
              Text(entity.titleSa!,
                  style: TextStyle(
                      fontSize: 12.5,
                      color:
                          const Color(0xFFFFF8EF).withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  final List<EntityRelation> relations;
  final bool hindi;
  final ValueChanged<int> onReroot;
  const _Band(
      {required this.relations, required this.hindi, required this.onReroot});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in relations)
          _PersonCard(relation: r, hindi: hindi, onReroot: onReroot),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final EntityRelation relation;
  final bool hindi;
  final ValueChanged<int> onReroot;
  const _PersonCard(
      {required this.relation, required this.hindi, required this.onReroot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => context.push('/gyan/entity/${relation.dstId}'),
      // Long-press re-roots, so the tree can be walked without leaving it.
      onLongPress: () => onReroot(relation.dstId),
      child: Container(
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              relation.dstTitle(hindi),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.15,
                color: AppColors.inkLight,
              ),
            ),
            if (relation.tradition != null && relation.tradition!.isNotEmpty)
              Text(relation.tradition!,
                  style: TextStyle(
                      fontSize: 9.5,
                      color: scheme.onSurface.withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }
}
