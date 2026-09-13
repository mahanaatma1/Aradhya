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

  /// Where the walk has been. Long-pressing re-roots in place rather than
  /// pushing a route, so without this the way back is lost the moment you
  /// move -- and the back button leaves the tree entirely.
  final List<int> _trail = [];

  /// Which tradition's reading to show, when the edges disagree (FT-04).
  String? _tradition;

  /// Which relation family the tree is drawn from (FT-01). Genealogy by
  /// default -- it is what the screen is named for and what most roots have.
  String _family = 'lineage';

  @override
  void initState() {
    super.initState();
    _root = widget.rootId;
    if (_root != null) _trail.add(_root!);
  }

  void _reroot(int id) {
    setState(() {
      if (_trail.contains(id)) {
        _trail.removeRange(_trail.indexOf(id) + 1, _trail.length);
      } else {
        _trail.add(id);
      }
      _root = id;
    });
  }

  void _truncateTo(int index) {
    setState(() {
      _trail.removeRange(index + 1, _trail.length);
      _root = _trail[index];
    });
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
              onPressed: () => setState(() {
                _root = null;
                _trail.clear();
                _tradition = null;
                _family = 'lineage';
              }),
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
              onPick: _reroot,
            );
          }
          final byId = {for (final e in entities) e.id: e};
          return Column(
            children: [
              if (_trail.length > 1)
                _Breadcrumb(
                  trail: _trail,
                  byId: byId,
                  hindi: hi,
                  onTap: _truncateTo,
                ),
              Expanded(
                child: _Tree(
                  rootId: _root!,
                  byId: byId,
                  hindi: hi,
                  onReroot: _reroot,
                  tradition: _tradition,
                  onTradition: (t) => setState(() => _tradition = t),
                  family: _family,
                  onFamily: (f) => setState(() => _family = f),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Only entities that actually have edges a tree can be drawn from are offered
/// as roots — opening a tree with a single lonely node is a dead end. The test
/// itself is in `_RootRow`, which hides its own tile; this widget only narrows
/// the candidates to the major figures.
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
  final String? tradition;
  final ValueChanged<String?> onTradition;
  final String family;
  final ValueChanged<String> onFamily;
  final Map<int, Entity> byId;
  final bool hindi;
  final ValueChanged<int> onReroot;

  const _Tree({
    required this.rootId,
    required this.byId,
    required this.hindi,
    required this.onReroot,
    required this.tradition,
    required this.onTradition,
    required this.family,
    required this.onFamily,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = byId[rootId];
    final rels =
        ref.watch(entityRelationsProvider(rootId)).valueOrNull ?? const [];
    if (root == null) return const SizedBox.shrink();

    // Traditions that disagree are labelled, never silently reconciled. When
    // one is chosen, edges with no tradition stay -- they are the undisputed
    // ones, and dropping them would empty most of the tree.
    final traditions = {
      for (final r in rels)
        if (r.tradition != null && r.tradition!.isNotEmpty) r.tradition!,
    }.toList()
      ..sort();

    final rels2 = tradition == null
        ? rels
        : rels
            .where((r) =>
                r.tradition == null ||
                r.tradition!.isEmpty ||
                r.tradition == tradition)
            .toList();

    // FT-01. Offered only where the root actually has the edges: a chip that
    // opens an empty tree is worse than no chip, because it reads as a claim
    // that nothing is recorded when the truth is that nothing was ever asked
    // for. Teaching and dynasty edges used to be dropped here in silence --
    // Vishvamitra guru_of Rama is in this very data and Rama's tree gave no
    // sign of it.
    final available = <String>[
      for (final f in RelBands.drawable)
        if (rels2.any((r) => r.family == f)) f,
    ];
    // Fall back to the genealogical view when the chosen family has nothing
    // here, so re-rooting onto a figure with no guru cannot land on a blank.
    final shown = available.contains(family)
        ? family
        : (available.isNotEmpty ? available.first : 'lineage');
    final spec = RelBands.forFamily(shown);

    final parents =
        rels2.where((r) => spec.above.contains(r.relType)).toList();
    final children =
        rels2.where((r) => spec.below.contains(r.relType)).toList();
    // Spouses and siblings are genealogy only -- a teacher has no consort in
    // their capacity as a teacher.
    final partners = shown != 'lineage'
        ? const <EntityRelation>[]
        : rels2
            .where((r) =>
                r.relType == 'spouse_of' || r.relType == 'consort_of')
            .toList();
    final siblings = shown != 'lineage'
        ? const <EntityRelation>[]
        : rels2.where((r) => r.relType == 'sibling_of').toList();

    final scheme = Theme.of(context).colorScheme;

    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 2.4,
      boundaryMargin: const EdgeInsets.all(80),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            if (available.length > 1) ...[
              _FamilyFilter(
                families: available,
                selected: shown,
                hindi: hindi,
                onPick: onFamily,
              ),
              const SizedBox(height: 12),
            ],
            if (traditions.length > 1) ...[
              _TraditionPicker(
                traditions: traditions,
                selected: tradition,
                hindi: hindi,
                onPick: onTradition,
              ),
              const SizedBox(height: 12),
            ],
            // Generations run top to bottom and are joined with real brackets,
            // so three children read as three descents from one couple rather
            // than as a list that happens to sit lower on the screen.
            if (parents.isNotEmpty) ...[
              _BandLabel(spec.aboveLabel(hindi)),
              _Band(relations: parents, hindi: hindi, onReroot: onReroot),
              if (spec.descent)
                _Bracket(count: parents.length, pointsDown: false)
              else
                const SizedBox(height: 10),
            ],
            _CoupleRow(
              root: _RootCard(entity: root, hindi: hindi),
              partners: partners,
              hindi: hindi,
              onReroot: onReroot,
            ),
            if (partners.length > 1) ...[
              const SizedBox(height: 8),
              _BandLabel(hindi ? 'अन्य सहचर' : 'OTHER CONSORTS'),
              _Band(
                  relations: partners.skip(1).toList(),
                  hindi: hindi,
                  onReroot: onReroot),
            ],
            if (children.isNotEmpty) ...[
              if (spec.descent)
                _Bracket(count: children.length)
              else
                const SizedBox(height: 10),
              _BandLabel(spec.belowLabel(hindi)),
              _Band(relations: children, hindi: hindi, onReroot: onReroot),
            ],
            if (siblings.isNotEmpty) ...[
              const SizedBox(height: 18),
              // Siblings sit beside the generation, not below it, so they are
              // separated by a rule rather than joined by a descent bracket.
              const _SiblingRule(),
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
                  // Named by family, so "nothing here" cannot be misread as
                  // "nothing at all" when the other chips have something.
                  switch (shown) {
                    'teaching' => hindi
                        ? 'इस नाम के लिए अभी कोई गुरु-शिष्य संबंध दर्ज नहीं है।'
                        : 'No teaching links recorded for this name yet.',
                    'dynasty' => hindi
                        ? 'इस नाम के लिए अभी कोई वंश-संबंध दर्ज नहीं है।'
                        : 'No dynasty links recorded for this name yet.',
                    _ => hindi
                        ? 'इस नाम के लिए अभी कोई पारिवारिक संबंध दर्ज नहीं है।'
                        : 'No family links recorded for this name yet.',
                  },
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
                      ? 'परंपरा अनुसार: ${tradition ?? traditions.join(", ")}'
                      : 'As given in: ${tradition ?? traditions.join(", ")}'),
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

/// A genealogical bracket: one stem, a horizontal rail, and a drop to each
/// card beneath.
///
/// The tree used to join its bands with a single straight line, which said
/// nothing about who descends from whom -- three children looked exactly like
/// one. A rail with drops is the notation family trees actually use, and it
/// costs one painter.
class _Bracket extends StatelessWidget {
  /// How many cards the rail has to reach. Drops land at the centre of each
  /// equal-width cell, which is where a Wrap of equal cards puts them.
  final int count;

  /// Rail above the cards (children) or below them (parents).
  final bool pointsDown;

  const _Bracket({required this.count, this.pointsDown = true});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 26,
        width: double.infinity,
        child: CustomPaint(
          painter: _BracketPainter(count: count, pointsDown: pointsDown),
        ),
      );
}

class _BracketPainter extends CustomPainter {
  final int count;
  final bool pointsDown;
  const _BracketPainter({required this.count, required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final stemTop = pointsDown ? 0.0 : size.height;
    canvas.drawLine(Offset(size.width / 2, stemTop),
        Offset(size.width / 2, midY), paint);

    if (count <= 1) {
      canvas.drawLine(Offset(size.width / 2, midY),
          Offset(size.width / 2, pointsDown ? size.height : 0), paint);
      return;
    }

    // Rail spans only as far as the outermost drops, so it never runs past
    // the cards it is joining.
    final firstX = size.width * (0.5 / count);
    final lastX = size.width * ((count - 0.5) / count);
    canvas.drawLine(Offset(firstX, midY), Offset(lastX, midY), paint);

    for (var i = 0; i < count; i++) {
      final x = size.width * ((i + 0.5) / count);
      canvas.drawLine(
          Offset(x, midY), Offset(x, pointsDown ? size.height : 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) =>
      old.count != count || old.pointsDown != pointsDown;
}

/// Root and consort side by side, joined by the double line a marriage is
/// drawn with.
class _CoupleRow extends StatelessWidget {
  final Widget root;
  final List<EntityRelation> partners;
  final bool hindi;
  final ValueChanged<int> onReroot;

  const _CoupleRow({
    required this.root,
    required this.partners,
    required this.hindi,
    required this.onReroot,
  });

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) return root;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: root),
        const _MarriageLine(),
        Flexible(
          child: _PersonCard(
              relation: partners.first, hindi: hindi, onReroot: onReroot),
        ),
      ],
    );
  }
}

class _MarriageLine extends StatelessWidget {
  const _MarriageLine();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 26,
        height: 14,
        child: CustomPaint(painter: _MarriagePainter()),
      );
}

class _MarriagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, size.height * 0.35),
        Offset(size.width, size.height * 0.35), p);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Siblings share a generation with the root, so they are introduced by a
/// rule rather than a descent bracket -- drawing them below on a bracket would
/// claim they are the root's children.
class _SiblingRule extends StatelessWidget {
  const _SiblingRule();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
                child: Container(
                    height: 1,
                    color: AppColors.gold.withValues(alpha: 0.28))),
          ],
        ),
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

/// A generation band. Past four names it collapses, because a canvas is only
/// readable while a generation fits on one screen -- and some of these
/// lineages run to dozens of children.
class _Band extends StatefulWidget {
  final List<EntityRelation> relations;
  final bool hindi;
  final ValueChanged<int> onReroot;
  const _Band(
      {required this.relations, required this.hindi, required this.onReroot});

  @override
  State<_Band> createState() => _BandState();
}

class _BandState extends State<_Band> {
  static const _cap = 4;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.relations;
    final collapsed = !_open && all.length > _cap;
    final shown = collapsed ? all.take(_cap).toList() : all;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in shown)
              _PersonCard(
                  relation: r,
                  hindi: widget.hindi,
                  onReroot: widget.onReroot),
          ],
        ),
        if (all.length > _cap)
          TextButton(
            onPressed: () => setState(() => _open = !_open),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              collapsed
                  ? (widget.hindi
                      ? '${all.length - _cap} और'
                      : 'Show ${all.length - _cap} more')
                  : (widget.hindi ? 'कम दिखाएँ' : 'Show fewer'),
              style: TextStyle(
                  fontSize: 12, color: scheme.primary.withValues(alpha: 0.9)),
            ),
          ),
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
          color: scheme.surface,
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
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.15,
                color: scheme.onSurface,
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

/// The path a re-root walk has taken, so it can be undone.
class _Breadcrumb extends StatelessWidget {
  final List<int> trail;
  final Map<int, Entity> byId;
  final bool hindi;
  final ValueChanged<int> onTap;
  const _Breadcrumb({
    required this.trail,
    required this.byId,
    required this.hindi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: trail.length,
        itemBuilder: (c, i) {
          final e = byId[trail[i]];
          if (e == null) return const SizedBox.shrink();
          final last = i == trail.length - 1;
          return Row(
            children: [
              if (i > 0)
                Icon(Icons.chevron_right_rounded,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.35)),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: last ? null : () => onTap(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    e.title(hindi),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: last ? FontWeight.w700 : FontWeight.w500,
                      color: last
                          ? scheme.onSurface
                          : scheme.primary.withValues(alpha: 0.9),
                    ),
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

/// Which tradition's lineage to read.
///
/// Only appears when the edges actually disagree. The app does not pick a
/// winner; it shows one reading at a time and says which.
/// FT-01. Which relation family the tree is drawn from.
///
/// A `ChoiceChip` set rather than a dropdown or a tab bar: there are at most
/// three, the whole point is that the user can see which kinds of link this
/// figure has at all, and a closed control would hide exactly that.
class _FamilyFilter extends StatelessWidget {
  final List<String> families;
  final String selected;
  final bool hindi;
  final ValueChanged<String> onPick;
  const _FamilyFilter({
    required this.families,
    required this.selected,
    required this.hindi,
    required this.onPick,
  });

  static const _icons = <String, IconData>{
    'lineage': Icons.family_restroom_rounded,
    'teaching': Icons.school_rounded,
    'dynasty': Icons.castle_rounded,
  };

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final f in families)
            ChoiceChip(
              avatar: Icon(_icons[f] ?? Icons.link_rounded, size: 15),
              label: Text(RelLabels.familyLabel(f, hindi)),
              labelStyle: const TextStyle(fontSize: 12),
              visualDensity: VisualDensity.compact,
              selected: selected == f,
              // Not a toggle. Deselecting the only chip would leave the screen
              // with no family to draw and nothing to say about why.
              onSelected: (_) => onPick(f),
            ),
        ],
      );
}

class _TraditionPicker extends StatelessWidget {
  final List<String> traditions;
  final String? selected;
  final bool hindi;
  final ValueChanged<String?> onPick;
  const _TraditionPicker({
    required this.traditions,
    required this.selected,
    required this.hindi,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        ChoiceChip(
          label: Text(hindi ? 'सभी परंपराएँ' : 'All traditions'),
          labelStyle: const TextStyle(fontSize: 12),
          visualDensity: VisualDensity.compact,
          selected: selected == null,
          onSelected: (_) => onPick(null),
        ),
        for (final t in traditions)
          ChoiceChip(
            label: Text(t),
            labelStyle: const TextStyle(fontSize: 12),
            visualDensity: VisualDensity.compact,
            selected: selected == t,
            onSelected: (_) => onPick(selected == t ? null : t),
          ),
      ],
    );
  }
}
