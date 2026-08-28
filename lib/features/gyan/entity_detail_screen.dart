import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/category_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import '../related/related_rail.dart';
import 'entity_models.dart';
import 'entity_providers.dart';
import 'symbol_motifs.dart';

/// One detail screen for every entity kind.
///
/// The fixed spine — title, aliases, description, citation, kind-specific
/// facts, connections, related content — is the same whether the subject is a
/// deity, a sage, an astra or a symbol. Only the facts panel varies, driven by
/// `props`. Five screens here would have been five places to forget the
/// citation.
class EntityDetailScreen extends ConsumerWidget {
  final int entityId;
  const EntityDetailScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final value = ref.watch(entityByIdProvider(entityId));

    return Scaffold(
      body: AsyncView(
        value: value,
        isEmpty: (e) => e == null,
        emptyMessage: hi ? 'यह प्रविष्टि नहीं मिली' : 'Entity not found',
        builder: (entity) => _Body(entity: entity!, hindi: hi),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Entity entity;
  final bool hindi;
  const _Body({required this.entity, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cats =
        Theme.of(context).extension<CategoryColors>() ?? CategoryColors.standard;
    final style = _styleFor(entity.kind, cats);

    final relations =
        ref.watch(entityRelationsProvider(entity.id)).valueOrNull ?? const [];
    final aliases =
        ref.watch(entityAliasesProvider(entity.id)).valueOrNull ?? const [];

    final bookmarks = ref.watch(bookmarksProvider);
    final uid = 'gyan:entity:${entity.id}';
    final saved = bookmarks.any((b) => b.uid == uid);

    final script = entity.scriptLine();
    final long = entity.long(hindi);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 168,
          backgroundColor: style.gradient.last,
          foregroundColor: const Color(0xFFFFF8EF),
          actions: [
            IconButton(
              tooltip: hindi ? 'सहेजें' : 'Save',
              icon: Icon(saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded),
              onPressed: () => ref.read(bookmarksProvider.notifier).toggle(
                    Bookmark(
                      src: 'gyan',
                      kind: 'entity',
                      id: entity.id,
                      titleEn: entity.titleEn,
                      titleHi: entity.titleHi,
                      subtitle: EntityKinds.label(entity.kind, false),
                      // Resolved at save time, so a bookmark can always reopen.
                      route: '/gyan/entity/${entity.id}',
                    ),
                  ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(gradient: style.linear),
              child: Stack(
                children: [
                  if (entity.glyph != null && entity.glyph!.isNotEmpty)
                    Positioned(
                      right: 18,
                      bottom: 6,
                      child: Text(
                        entity.glyph!,
                        style: TextStyle(
                          fontSize: 96,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    )
                  else if (SymbolMotif.covered.contains(entity.slug))
                    Positioned(
                      right: 18,
                      bottom: 6,
                      child: SymbolMotif(
                        slug: entity.slug,
                        color: Colors.white.withValues(alpha: 0.18),
                        size: 96,
                      ),
                    ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          EntityKinds.label(entity.kind, hindi).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color:
                                const Color(0xFFFFF8EF).withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entity.title(hindi),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 27,
                            height: 1.1,
                            color: Color(0xFFFFF8EF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sanskrit and IAST sit together under the title, deliberately
                // distinct from the Hindi name in the header.
                if (script != null)
                  Text(script,
                      style: TextStyle(
                        fontFamily: AppFonts.accent,
                        fontSize: 16,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      )),
                if (entity.verificationStatus != 'verified') ...[
                  const SizedBox(height: 8),
                  VerificationChip(
                      status: entity.verificationStatus, hindi: hindi),
                ],
                const SizedBox(height: 12),
                Text(
                  entity.desc(hindi),
                  style: const TextStyle(fontSize: 16, height: 1.55),
                ),
                if (long != null && long.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(long,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: scheme.onSurface.withValues(alpha: 0.82))),
                ],
                const SizedBox(height: 14),
                SourceChip(
                  hindi: hindi,
                  sourceName: entity.sourceName,
                  sourceRef: entity.sourceRef,
                  sourceUrl: entity.sourceUrl,
                  lastVerifiedAt: entity.lastVerifiedAt,
                ),
                if (aliases.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Label(hindi ? 'अन्य नाम' : 'ALSO KNOWN AS'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final a in aliases)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    scheme.outline.withValues(alpha: 0.28)),
                          ),
                          child: Text(a,
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                    ],
                  ),
                ],
                if (entity.props.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _PropsCard(entity: entity, hindi: hindi),
                ],
                // RS-04: guru/disciple is a teaching chain, not a birth
                // generation, so it does not belong in the Family Tree's
                // three-band genealogical layout (see FT-01's note on why
                // that screen only reads child_of/parent_of/father_of/
                // mother_of). It already reaches this page via `relations`
                // and RelatedRail below, just without ever being singled
                // out as *lineage* -- this renders that same data as a
                // compact one-level tree instead of a generic related-card.
                if (entity.kind == 'rishi')
                  _TeachingLineage(relations: relations, hindi: hindi),
                // RS-05: attributions in this corpus follow the tradition of
                // the text they are cited from. Two traditions can assign the
                // same hymn or lineage differently, and the app is in no
                // position to arbitrate -- so it says whose account it is
                // showing rather than presenting one as settled fact.
                if (entity.kind == 'rishi') ...[
                  const SizedBox(height: 14),
                  _AttributionNote(hindi: hindi),
                ],
                const SizedBox(height: 18),
                if (relations.isNotEmpty)
                  _Connections(relations: relations, hindi: hindi)
                else
                  _NoConnections(hindi: hindi),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RelatedRail(
              src: 'gyan', table: 'entities', id: entity.id),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  static CategoryStyle _styleFor(String kind, CategoryColors c) =>
      switch (kind) {
        'weapon' => c.quiz,
        'symbol' => c.mantras,
        'rishi' => c.scriptures,
        'yuga' || 'loka' => c.srishty,
        _ => c.gyan,
      };
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
}

/// RS-04: a one-level teaching tree — this rishi's own guru above, their
/// disciples below. Built from `relations`, so it can never drift from the
/// data RelatedRail already shows lower on the page; it just gives the
/// teaching edges a shape of their own instead of leaving them to read as
/// one more generic "related entity" card.
class _TeachingLineage extends StatelessWidget {
  final List<EntityRelation> relations;
  final bool hindi;
  const _TeachingLineage({required this.relations, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final guru = relations.where((r) => r.relType == 'disciple_of').toList();
    final disciples = relations.where((r) => r.relType == 'guru_of').toList();
    if (guru.isEmpty && disciples.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(hindi ? 'गुरु-परंपरा' : 'TEACHING LINEAGE'),
            const SizedBox(height: 10),
            if (guru.isNotEmpty) ...[
              _LineageRow(
                  label: hindi ? 'गुरु' : 'Guru', people: guru, hindi: hindi),
              if (disciples.isNotEmpty) const SizedBox(height: 8),
            ],
            if (disciples.isNotEmpty)
              _LineageRow(
                  label: hindi ? 'शिष्य' : 'Disciples',
                  people: disciples,
                  hindi: hindi),
          ],
        ),
      ),
    );
  }
}

class _LineageRow extends StatelessWidget {
  final String label;
  final List<EntityRelation> people;
  final bool hindi;
  const _LineageRow(
      {required this.label, required this.people, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.65))),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in people)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => context.push('/gyan/entity/${r.dstId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(r.dstTitle(hindi),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kind-specific facts, rendered from `props`.
///
/// Symbolic readings get their own panel rather than sitting in the fact list:
/// §4.10 and §4.12 both require that interpretation is visibly separated from
/// description, so a reader can tell what the text says from what it is taken
/// to mean.
class _PropsCard extends StatelessWidget {
  final Entity entity;
  final bool hindi;
  const _PropsCard({required this.entity, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = entity.props;
    final rows = <(String, String)>[];

    void add(String labelEn, String labelHi, Object? v) {
      if (v == null) return;
      final text = v is List ? v.join(' · ') : v.toString();
      if (text.trim().isEmpty) return;
      rows.add((hindi ? labelHi : labelEn, text));
    }

    switch (entity.kind) {
      case 'weapon':
        add('Type', 'प्रकार', p['weapon_type']);
        add('Nature', 'स्वरूप', p['nature']);
        add('Invocation', 'आह्वान', p['invocation']);
        add('Effect', 'प्रभाव', p['powers_en']);
        add('Counter', 'प्रतिकार', p['counter_en']);
      case 'symbol':
        add('Visual form', 'स्वरूप', p['visual_form_en']);
        add('Common usage', 'प्रयोग', p['common_usage_en']);
      case 'rishi':
        add('Gotra', 'गोत्र', p['gotra']);
        add('Veda', 'वेद', p['veda']);
        add('Ashram', 'आश्रम', p['ashram_place_slug']);
        add('Hymns', 'सूक्त', p['hymns']);
      case 'deity':
        add('Vahana', 'वाहन', p['vahana_slug']);
        add('Consort', 'सहचर', p['consort_slugs']);
        add('Ayudha', 'आयुध', p['ayudha_slugs']);
      default:
        p.forEach((k, v) {
          if (v is String || v is num) {
            add(_pretty(k), _pretty(k), v);
          }
        });
    }

    final symbolic = p['symbolic_meaning_en'] as String?;
    final varies = (p['meaning_varies_by'] as List?)?.cast<String>() ?? const [];

    if (rows.isEmpty && symbolic == null && varies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty) ...[
          _Label(hindi ? 'विवरण' : 'DETAILS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        color: scheme.outline.withValues(alpha: 0.14)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(rows[i].$1,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55))),
                        ),
                        Expanded(
                          child: Text(rows[i].$2,
                              style: const TextStyle(
                                  fontSize: 13.5, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (symbolic != null && symbolic.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _InterpretationPanel(
            title: hindi ? 'प्रतीकात्मक अर्थ' : 'Symbolic meaning',
            body: symbolic,
          ),
        ],
        if (varies.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InterpretationPanel(
            title: hindi ? 'अर्थ परंपरा-भेद से' : 'Meanings vary',
            body: hindi
                ? 'इस प्रतीक का अर्थ परंपरा अनुसार भिन्न है: ${varies.join(", ")}. यहाँ दिया गया विवरण किसी एक परंपरा का अंतिम मत नहीं है।'
                : 'This symbol is read differently across traditions: ${varies.join(", ")}. What is given here is not any one tradition\'s final word.',
          ),
        ],
      ],
    );
  }

  static String _pretty(String k) => k
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\ben\b'), '')
      .trim();
}

/// Kraft-coloured panel used wherever the app is interpreting rather than
/// reporting. Visually distinct on purpose.
class _InterpretationPanel extends StatelessWidget {
  final String title;
  final String body;
  const _InterpretationPanel({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECDC).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB48B3E).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A6A2E))),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontFamily: AppFonts.accent,
                  fontSize: 14.5,
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// Typed edges, grouped by family, each row navigating deeper into the graph.
/// Connections, grouped by family.
///
/// Two behaviours only kick in on the well-connected entities: past twenty
/// edges the families collapse to a few rows each, and filter chips appear.
/// Krishna has enough relations to bury the rest of the page otherwise, while
/// an entity with four edges needs neither and gets neither.
class _Connections extends StatefulWidget {
  final List<EntityRelation> relations;
  final bool hindi;
  const _Connections({required this.relations, required this.hindi});

  @override
  State<_Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends State<_Connections> {
  static const _order = [
    'lineage', 'teaching', 'epic', 'text', 'place', 'general'
  ];

  /// Beyond this many edges the section starts managing itself.
  static const _busy = 20;

  /// Rows shown per family before a "show all" appears.
  static const _perFamily = 5;

  String? _filter;
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hindi = widget.hindi;
    final relations = widget.relations;
    final busy = relations.length > _busy;

    final groups = <String, List<EntityRelation>>{};
    for (final r in relations) {
      groups.putIfAbsent(r.family, () => []).add(r);
    }
    final present = _order.where(groups.containsKey).toList();
    final keys = _filter == null
        ? present
        : present.where((f) => f == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Label(hindi ? 'संबंध' : 'CONNECTIONS'),
            const SizedBox(width: 8),
            Text('${relations.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                )),
          ],
        ),
        // Filter chips only where they earn their space.
        if (busy && present.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text(hindi ? 'सभी' : 'All'),
                labelStyle: const TextStyle(fontSize: 12),
                visualDensity: VisualDensity.compact,
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final f in present)
                ChoiceChip(
                  label: Text(
                      '${RelLabels.familyLabel(f, hindi)} ${groups[f]!.length}'),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  selected: _filter == f,
                  onSelected: (_) => setState(
                      () => _filter = _filter == f ? null : f),
                ),
            ],
          ),
        ],
        for (final family in keys) ...[
          const SizedBox(height: 10),
          Text(RelLabels.familyLabel(family, hindi),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 6),
          for (final r in _rowsFor(groups[family]!, family, busy))
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push('/gyan/entity/${r.dstId}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        RelLabels.of(r.relType, hindi),
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                scheme.onSurface.withValues(alpha: 0.55)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.dstTitle(hindi),
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Traditions disagree about some lineages; the app labels
                    // that rather than silently picking a winner.
                    if (r.tradition != null && r.tradition!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(r.tradition!,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.45))),
                      ),
                    if (r.confidence == 'disputed')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.help_outline_rounded,
                            size: 14,
                            color: scheme.onSurface.withValues(alpha: 0.45)),
                      ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.onSurface.withValues(alpha: 0.35)),
                  ],
                ),
              ),
            ),
          if (_hiddenIn(groups[family]!, family, busy) > 0)
            TextButton(
              onPressed: () => setState(() => _expanded.add(family)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                hindi
                    ? '${_hiddenIn(groups[family]!, family, busy)} और दिखाएँ'
                    : 'Show ${_hiddenIn(groups[family]!, family, busy)} more',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
        ],
      ],
    );
  }

  /// The rows to render for one family, capped only when the section is busy
  /// and the user has not asked for the rest.
  List<EntityRelation> _rowsFor(
      List<EntityRelation> all, String family, bool busy) {
    if (!busy || _expanded.contains(family) || all.length <= _perFamily) {
      return all;
    }
    return all.take(_perFamily).toList();
  }

  int _hiddenIn(List<EntityRelation> all, String family, bool busy) =>
      all.length - _rowsFor(all, family, busy).length;
}

/// What a page says when the graph has nothing on this entity yet.
///
/// Most of the corpus is still skeletons imported from Wikidata, and a screen
/// that simply omits the section reads as though the entity has no place in
/// anything. Saying so plainly is more honest than an absence, and it does not
/// invent an edge to fill the gap.
class _NoConnections extends StatelessWidget {
  final bool hindi;
  const _NoConnections({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(hindi ? 'संबंध' : 'CONNECTIONS'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined,
                  size: 18, color: scheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hindi
                      ? 'इस प्रविष्टि के लिए अभी कोई सत्यापित संबंध दर्ज नहीं है। '
                          'जो सत्यापित नहीं है, वह यहाँ नहीं दिखाया जाता।'
                      : 'No verified connections are recorded for this entry '
                          'yet. Nothing unverified is shown here.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// Standing note on rishi pages: attributions follow the cited tradition.
class _AttributionNote extends StatelessWidget {
  final bool hindi;
  const _AttributionNote({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.menu_book_rounded,
            size: 14, color: scheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hindi
                ? 'गोत्र, वेद, सूक्त और गुरु-परंपरा उसी ग्रंथ के अनुसार दी गई हैं '
                    'जिसका यहाँ उल्लेख है। परंपराओं में भिन्नता हो सकती है।'
                : 'Gotra, veda, hymn and lineage attributions follow the text '
                    'cited here. Traditions differ, and this shows one account.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}
