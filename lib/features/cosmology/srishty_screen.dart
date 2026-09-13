
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import 'brahmanda_view.dart';
import 'cosmology_models.dart';
import 'cosmology_providers.dart';

/// Srishty Universe — creation, the fourteen lokas, and the cycles of time.
///
/// Rendered as a vertical descent through a night sky rather than a list: the
/// lokas are arranged above and below the earth, and that arrangement *is* the
/// content. A bulleted list would lose it entirely.
class SrishtyScreen extends ConsumerStatefulWidget {
  const SrishtyScreen({super.key});

  @override
  ConsumerState<SrishtyScreen> createState() => _SrishtyScreenState();
}

class _SrishtyScreenState extends ConsumerState<SrishtyScreen> {
  String _track = 'loka';
  final _scroll = ScrollController();
  int? _expanded;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final nodes = ref.watch(cosmologyTrackProvider(_track));

    return Scaffold(
      body: Container(
        // Warm, not spacey. The indigo starfield made the one screen about
        // cosmology look like a screen about astronomy, and it sat wrongly
        // beside the cream cards on every other surface.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F5F2), Color(0xFFF6EADF), Color(0xFFEFE0D2)],
          ),
        ),
        child: SafeArea(
              child: Column(
                children: [
                  _TopBar(hindi: hi),
                  _TrackTabs(
                    selected: _track,
                    hindi: hi,
                    onSelected: (t) => setState(() {
                      _track = t;
                      _expanded = null;
                    }),
                  ),
                  Expanded(
                    child: AsyncView(
                      value: nodes,
                      isEmpty: (l) => l.isEmpty,
                      emptyMessage:
                          hi ? 'अभी कोई विवरण नहीं' : 'Nothing here yet',
                      builder: (list) => ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                        itemCount: list.length + 2,
                        itemBuilder: (context, i) {
                          // The lokas are a structure, so the structure is
                          // drawn first and the cards explain what was tapped.
                          if (i == 0) {
                            return _track == 'loka'
                                ? Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 14),
                                    child: BrahmandaView(
                                      nodes: list,
                                      hindi: hi,
                                      selectedId: _expanded,
                                      onSelect: (n) => setState(() =>
                                          _expanded =
                                              _expanded == n.id ? null : n.id),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          if (i == list.length + 1) {
                            return _TraditionNote(hindi: hi);
                          }
                          final n = list[i - 1];
                          final prev = i > 1 ? list[i - 2] : null;
                          return Column(
                            children: [
                              if (_track == 'loka' &&
                                  n.band == 'lower' &&
                                  prev?.band != 'lower')
                                _EarthDivider(hindi: hi),
                              _LadderRow(
                                node: n,
                                index: i - 1,
                                total: list.length,
                                isFirst: i == 1,
                                isLast: i == list.length,
                                track: _track,
                                child: _NodeCard(
                                  node: n,
                                  hindi: hi,
                                  track: _track,
                                  expanded: _expanded == n.id,
                                  onTap: () => setState(() => _expanded =
                                      _expanded == n.id ? null : n.id),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool hindi;
  const _TopBar({required this.hindi});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF3A2A18), size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Text(
              hindi ? 'सृष्टि' : 'Srishty Universe',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 21,
                color: Color(0xFF3A2A18),
              ),
            ),
          ],
        ),
      );
}

class _TrackTabs extends StatelessWidget {
  final String selected;
  final bool hindi;
  final ValueChanged<String> onSelected;

  const _TrackTabs({
    required this.selected,
    required this.hindi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          for (final t in CosmologyTracks.order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == t
                          ? AppColors.goldBright.withValues(alpha: 0.22)
                          : const Color(0xFF3A2A18).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected == t
                            ? AppColors.goldBright.withValues(alpha: 0.7)
                            : const Color(0xFF8A6A4F).withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      CosmologyTracks.label(t, hindi),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected == t
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected == t
                            ? AppColors.goldBright
                            : const Color(0xFF3A2A18)
                                .withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The line the lokas are arranged around.
class _EarthDivider extends StatelessWidget {
  final bool hindi;
  const _EarthDivider({required this.hindi});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                  height: 1,
                  color: AppColors.goldBright.withValues(alpha: 0.4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                hindi ? 'अधोलोक' : 'THE NETHER WORLDS',
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldBright.withValues(alpha: 0.85),
                ),
              ),
            ),
            Expanded(
              child: Container(
                  height: 1,
                  color: AppColors.goldBright.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
}

/// One rung of the ladder: the spine on the left, the card on the right.
///
/// The fourteen lokas are a descent -- seven worlds above the earth and seven
/// below it -- and the screen rendered them as a flat list, which described
/// that structure without ever showing it. The rail makes the shape visible:
/// a continuous line down the page, a node per world, filled while you are
/// above the earth and hollow once you are beneath it.
class _LadderRow extends StatelessWidget {
  final CosmologyNode node;
  final int index;
  final int total;
  final bool isFirst;
  final bool isLast;
  final String track;
  final Widget child;

  const _LadderRow({
    required this.node,
    required this.index,
    required this.total,
    required this.isFirst,
    required this.isLast,
    required this.track,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isEarth = node.slug == 'loka-bhur';
    final lower = node.band == 'lower';
    // Creation and time are sequences, not a descent, so they get a plain
    // numbered spine rather than the above/below reading.
    final numbered = track != 'loka';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: CustomPaint(
              painter: _RailPainter(
                isFirst: isFirst,
                isLast: isLast,
                isEarth: isEarth,
                hollow: lower && !numbered,
              ),
              child: numbered
                  ? Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3A2A18)),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final bool isEarth;
  final bool hollow;

  const _RailPainter({
    required this.isFirst,
    required this.isLast,
    required this.isEarth,
    required this.hollow,
  });

  static const _gold = Color(0xFFC97A3E);

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const nodeY = 30.0;
    final line = Paint()
      ..strokeWidth = 1.4
      ..color = _gold.withValues(alpha: 0.35);

    if (!isFirst) canvas.drawLine(Offset(x, 0), Offset(x, nodeY), line);
    if (!isLast) {
      canvas.drawLine(Offset(x, nodeY), Offset(x, size.height), line);
    }

    final r = isEarth ? 8.0 : 5.5;
    if (hollow) {
      canvas.drawCircle(Offset(x, nodeY), r,
          Paint()..color = const Color(0xFFF7F5F2));
      canvas.drawCircle(
          Offset(x, nodeY),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _gold.withValues(alpha: 0.75));
    } else {
      canvas.drawCircle(Offset(x, nodeY), r, Paint()..color = _gold);
    }

    // The earth gets a ring, because it is the one rung the reader is standing
    // on and everything above and below is measured from it.
    if (isEarth) {
      canvas.drawCircle(
          Offset(x, nodeY),
          r + 5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = _gold.withValues(alpha: 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter o) =>
      o.isFirst != isFirst ||
      o.isLast != isLast ||
      o.isEarth != isEarth ||
      o.hollow != hollow;
}

class _NodeCard extends ConsumerWidget {
  final CosmologyNode node;
  final bool hindi;
  final String track;
  final bool expanded;
  final VoidCallback onTap;

  const _NodeCard({
    required this.node,
    required this.hindi,
    required this.track,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bhuloka is where a reader actually stands, and marking it is the single
    // thing that makes the stack legible as a map rather than a list.
    final isEarth = node.slug == 'loka-bhur';
    final long = node.long(hindi);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Glass over the night sky.
            color: const Color(0xFF8A6A4F).withValues(alpha: isEarth ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEarth
                  ? AppColors.terracottaBright.withValues(alpha: 0.85)
                  : const Color(0xFF8A6A4F).withValues(alpha: 0.35),
              width: isEarth ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (track != 'creation')
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8A6A4F).withValues(alpha: 0.28),
                      ),
                      child: Text('${node.orderNo}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A2A18))),
                    ),
                  if (track != 'creation') const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title(hindi),
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: isEarth
                                ? AppColors.goldBright
                                : const Color(0xFF3A2A18),
                          ),
                        ),
                        if (node.durationYears != null)
                          Text(
                            '${node.durationYears} ${hindi ? "वर्ष" : "years"}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.goldBright
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isEarth)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaBright
                            .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hindi ? 'आप यहाँ' : 'You are here',
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFD9C7)),
                      ),
                    ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 19,
                    color: const Color(0xFF3A2A18).withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                node.desc(hindi),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: const Color(0xFF3A2A18).withValues(alpha: 0.82),
                ),
              ),
              if (expanded) ...[
                if (long != null && long.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(long,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color:
                            const Color(0xFF3A2A18).withValues(alpha: 0.75),
                      )),
                ],
                const SizedBox(height: 12),
                _TraditionsDiffer(
                    attributes: node.attributes, hindi: hindi),
                SourceChip(
                  hindi: hindi,
                  sourceName: node.sourceName,
                  sourceRef: node.sourceRef,
                  sourceUrl: node.sourceUrl,
                  lastVerifiedAt: node.lastVerifiedAt,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Where accounts genuinely disagree, both are shown and neither is called a
/// correction of the other. The Vishnu Purana and the Bhagavata do not order
/// the Patalas the same way, and pretending otherwise would be tidier and
/// false.
class _TraditionsDiffer extends StatelessWidget {
  final Map<String, dynamic> attributes;
  final bool hindi;
  const _TraditionsDiffer({required this.attributes, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final note = attributes['traditions_differ'];
    if (note is! Map) return const SizedBox.shrink();
    final text = (hindi ? note['hi'] : note['en']) as String?;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF8A6A4F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A6A4F).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded,
                  size: 14, color: Color(0xFF8A6A4F)),
              const SizedBox(width: 6),
              Text(hindi ? 'परंपराएँ भिन्न हैं' : 'Traditions differ',
                  style: const TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A6A4F))),
            ],
          ),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.45, color: Color(0xFF4A3A22))),
        ],
      ),
    );
  }
}

class _TraditionNote extends StatelessWidget {
  final bool hindi;
  const _TraditionNote({required this.hindi});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Text(
          // §4.6 asks for this explicitly: a doctrinal model, labelled as one.
          hindi
              ? 'यह विष्णु पुराण में दिया गया विवरण है — एक शास्त्रीय ब्रह्मांड-चित्र, आधुनिक खगोल-विज्ञान का कथन नहीं।'
              : 'This is the account given in the Vishnu Purana — a doctrinal picture of the cosmos, not a claim about modern astronomy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: const Color(0xFF3A2A18).withValues(alpha: 0.5),
          ),
        ),
      );
}

