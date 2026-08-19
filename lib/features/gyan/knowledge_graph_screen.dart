import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'entity_models.dart';
import 'entity_providers.dart';

/// The Knowledge Graph — deities, sages, weapons and places as a tappable web.
///
/// Tapping a neighbour **re-centres in place** rather than pushing a route, so
/// exploring feels continuous instead of like a stack of pages. A breadcrumb
/// keeps the way back, and "Open page" goes to the full entity screen when the
/// user wants the detail rather than the map.
class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  /// Entity to open on. Falls back to the most important one available.
  final int? focusId;
  const KnowledgeGraphScreen({super.key, this.focusId});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() =>
      _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends ConsumerState<KnowledgeGraphScreen> {
  /// Visited entity ids, oldest first. Doubles as the breadcrumb.
  final List<int> _trail = [];

  /// Relation families currently shown. Empty means all.
  final Set<String> _families = {};

  int? get _focus => _trail.isEmpty ? null : _trail.last;

  void _focusOn(int id) {
    setState(() {
      // Revisiting something already on the trail truncates back to it rather
      // than growing an ever-longer path through the same nodes.
      final existing = _trail.indexOf(id);
      if (existing >= 0) {
        _trail.removeRange(existing + 1, _trail.length);
      } else {
        _trail.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final all = ref.watch(allEntitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'ज्ञान संजाल' : 'Knowledge Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: AsyncView(
        value: all,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'ग्राफ़ अभी खाली है' : 'The graph is empty',
        builder: (entities) {
          final byId = {for (final e in entities) e.id: e};
          final focusId = _focus ?? widget.focusId ?? entities.first.id;
          if (_trail.isEmpty) _trail.add(focusId);

          final focus = byId[focusId] ?? entities.first;
          final relations =
              ref.watch(entityRelationsProvider(focus.id)).valueOrNull ??
                  const <EntityRelation>[];

          final visible = _families.isEmpty
              ? relations
              : relations.where((r) => _families.contains(r.family)).toList();

          return Column(
            children: [
              _Breadcrumb(
                trail: _trail,
                byId: byId,
                hindi: hi,
                onTap: _focusOn,
              ),
              _FamilyFilter(
                available: {for (final r in relations) r.family},
                selected: _families,
                hindi: hi,
                onToggle: (f) => setState(() {
                  _families.contains(f)
                      ? _families.remove(f)
                      : _families.add(f);
                }),
              ),
              Expanded(
                child: _GraphCanvas(
                  focus: focus,
                  relations: visible,
                  hindi: hi,
                  onTapNeighbour: _focusOn,
                ),
              ),
              _FocusBar(entity: focus, hindi: hi, degree: relations.length),
            ],
          );
        },
      ),
    );
  }
}

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
    if (trail.length < 2) return const SizedBox(height: 6);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trail.length,
        separatorBuilder: (_, _) => Icon(Icons.chevron_right_rounded,
            size: 15, color: scheme.onSurface.withValues(alpha: 0.35)),
        itemBuilder: (context, i) {
          final e = byId[trail[i]];
          final last = i == trail.length - 1;
          return Center(
            child: InkWell(
              onTap: last ? null : () => onTap(trail[i]),
              child: Text(
                e?.title(hindi) ?? '…',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: last ? FontWeight.w700 : FontWeight.w500,
                  color: last
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FamilyFilter extends StatelessWidget {
  final Set<String> available;
  final Set<String> selected;
  final bool hindi;
  final ValueChanged<String> onToggle;

  const _FamilyFilter({
    required this.available,
    required this.selected,
    required this.hindi,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (available.length < 2) return const SizedBox(height: 4);
    const order = ['lineage', 'teaching', 'epic', 'text', 'place', 'general'];
    final families = order.where(available.contains).toList();
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final f in families)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: FilterChip(
                label: Text(RelLabels.familyLabel(f, hindi)),
                selected: selected.contains(f),
                onSelected: (_) => onToggle(f),
                labelStyle: const TextStyle(fontSize: 11.5),
                visualDensity: VisualDensity.compact,
                selectedColor: scheme.primary.withValues(alpha: 0.14),
                side: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.25)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The orbital layout: focus at the centre, neighbours arranged by family.
class _GraphCanvas extends StatefulWidget {
  final Entity focus;
  final List<EntityRelation> relations;
  final bool hindi;
  final ValueChanged<int> onTapNeighbour;

  const _GraphCanvas({
    required this.focus,
    required this.relations,
    required this.hindi,
    required this.onTapNeighbour,
  });

  @override
  State<_GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<_GraphCanvas> {
  final _controller = TransformationController();

  /// The canvas is bigger than the screen, so without this the view opens at
  /// its top-left corner -- which is empty space, with the focus node off
  /// somewhere below and to the right. Centring is done once per focus.
  Offset? _centredOn;

  void _centre(Size viewport, Offset centre) {
    if (_centredOn == centre) return;
    _centredOn = centre;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.value = Matrix4.identity()
        ..translateByDouble(viewport.width / 2 - centre.dx,
            viewport.height / 2 - centre.dy, 0, 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Entity get focus => widget.focus;
  List<EntityRelation> get relations => widget.relations;
  bool get hindi => widget.hindi;
  ValueChanged<int> get onTapNeighbour => widget.onTapNeighbour;

  /// Where each relation family sits around the focus, in radians.
  /// Lineage above, teaching left, epic right, places below — so the same kind
  /// of connection is always in the same place and the layout is learnable.
  static const _familyAngle = <String, double>{
    'lineage': -math.pi / 2,
    'teaching': math.pi,
    'epic': 0,
    'text': -math.pi / 4,
    'place': math.pi / 2,
    'general': 3 * math.pi / 4,
  };

  @override
  Widget build(BuildContext context) {
    // Cap what is drawn: beyond a dozen neighbours the orbit stops being
    // readable and the screen is better served by the detail page's list.
    final shown = relations.take(12).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // A node chip is a real rectangle, so the ring has to be big enough to
        // seat every chip along its circumference. The old layout used a fixed
        // radius and packed each family into a narrow arc, which guaranteed
        // overlap the moment a family had more than two members -- and the
        // lineage families always do.
        const chipW = 132.0;      // chip width plus the gap it needs
        const chipH = 54.0;
        final n = shown.length;

        // Two rings once one ring cannot seat them all: alternating radii on a
        // single ring only staggers the collision, it does not remove it.
        final twoRings = n > 7;
        final perRing = twoRings ? (n / 2).ceil() : n;
        final minR = (perRing * chipW) / (2 * math.pi);
        final innerR = math.max(minR, 120.0);
        final outerR = innerR + chipH + 46;

        // The canvas is deliberately larger than the viewport: the graph is
        // inside an InteractiveViewer, so it is meant to be panned, and sizing
        // it to the screen is what pushed outer nodes off the edge.
        final extent = (outerR + chipW) * 2;
        final side = math.max(
            extent, math.max(constraints.maxWidth, constraints.maxHeight));
        final size = Size(side, side);
        final centre = Offset(side / 2, side / 2);

        // Sort by family so related edges still sit together on the ring,
        // then distribute EVENLY. Even spacing is what actually guarantees the
        // angular gap; grouping is presentation on top of it.
        final ordered = [...shown]
          ..sort((a, b) {
            final fa = _familyAngle[a.family] ?? 0;
            final fb = _familyAngle[b.family] ?? 0;
            final d = fa.compareTo(fb);
            return d != 0 ? d : a.family.compareTo(b.family);
          });

        final positions = <EntityRelation, Offset>{};
        for (var i = 0; i < ordered.length; i++) {
          final ring = twoRings && i.isOdd;
          final idxInRing = twoRings ? i ~/ 2 : i;
          final countInRing = twoRings
              ? (ring ? n ~/ 2 : (n / 2).ceil())
              : n;
          final step = countInRing == 0 ? 0.0 : (2 * math.pi) / countInRing;
          // Offset the outer ring by half a step so the two rings interleave
          // rather than sitting radially in line with each other.
          final angle = -math.pi / 2 + idxInRing * step + (ring ? step / 2 : 0);
          final r = ring ? outerR : innerR;
          positions[ordered[i]] =
              centre + Offset(math.cos(angle) * r, math.sin(angle) * r);
        }

        _centre(Size(constraints.maxWidth, constraints.maxHeight), centre);

        return InteractiveViewer(
          transformationController: _controller,
          // WITHOUT this the viewer forces the child back inside the viewport,
          // so an oversized canvas is clipped instead of panned -- the graph
          // appeared cut off and refused to drag. constrained: false lets the
          // child keep its natural size and the viewer move over it.
          constrained: false,
          minScale: 0.4,
          maxScale: 2.6,
          boundaryMargin: const EdgeInsets.all(400),
          clipBehavior: Clip.none,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgePainter(
                      centre: centre,
                      targets: positions.values.toList(),
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                for (final entry in positions.entries)
                  _NodeChip(
                    relation: entry.key,
                    position: entry.value,
                    hindi: hindi,
                    onTap: () => onTapNeighbour(entry.key.dstId),
                  ),
                _FocusNode(entity: focus, centre: centre, hindi: hindi),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  final Offset centre;
  final List<Offset> targets;
  final Color color;
  const _EdgePainter(
      {required this.centre, required this.targets, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;

    for (final t in targets) {
      // Gentle bow rather than a straight line: a star of straight spokes
      // reads as a diagram, a bowed one reads as a web.
      final mid = Offset((centre.dx + t.dx) / 2, (centre.dy + t.dy) / 2);
      final normal = Offset(-(t.dy - centre.dy), t.dx - centre.dx);
      final len = normal.distance;
      final bow = len == 0 ? Offset.zero : normal / len * 16;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy)
          ..quadraticBezierTo(mid.dx + bow.dx, mid.dy + bow.dy, t.dx, t.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.centre != centre || old.targets.length != targets.length;
}

class _FocusNode extends StatelessWidget {
  final Entity entity;
  final Offset centre;
  final bool hindi;
  const _FocusNode(
      {required this.entity, required this.centre, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 86.0;

    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: Container(
          key: ValueKey(entity.id),
          width: size,
          height: size,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            boxShadow: [
              BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Text(
            entity.glyph?.isNotEmpty == true
                ? entity.glyph!
                : entity.title(hindi),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.12,
              color: Color(0xFFFFF8EF),
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeChip extends StatelessWidget {
  final EntityRelation relation;
  final Offset position;
  final bool hindi;
  final VoidCallback onTap;

  const _NodeChip({
    required this.relation,
    required this.position,
    required this.hindi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const w = 118.0;

    return Positioned(
      left: position.dx - w / 2,
      top: position.dy - 26,
      width: w,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RelLabels.of(relation.relType, hindi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                relation.dstTitle(hindi),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer: what is focused, and the way into its full page.
class _FocusBar extends StatelessWidget {
  final Entity entity;
  final bool hindi;
  final int degree;
  const _FocusBar(
      {required this.entity, required this.hindi, required this.degree});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title(hindi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${EntityKinds.label(entity.kind, hindi)} · '
                      '$degree ${hindi ? "संबंध" : "connections"}',
                      style: TextStyle(
                          fontSize: 11.5,
                          color:
                              scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/gyan/entity/${entity.id}'),
                child: Text(hindi ? 'पूरा पृष्ठ' : 'Open page',
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
