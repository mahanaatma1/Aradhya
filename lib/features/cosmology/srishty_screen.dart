import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF120B26), Color(0xFF241645), Color(0xFF0E0A1C)],
          ),
        ),
        child: Stack(
          children: [
            // Parallax starfield: deterministic, so the sky does not reshuffle
            // on every rebuild.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scroll,
                builder: (_, _) => CustomPaint(
                  painter: _StarfieldPainter(
                    offset: _scroll.hasClients ? _scroll.offset : 0,
                  ),
                ),
              ),
            ),
            SafeArea(
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
                        itemCount: list.length + 1,
                        itemBuilder: (context, i) {
                          if (i == list.length) {
                            return _TraditionNote(hindi: hi);
                          }
                          final n = list[i];
                          final prev = i > 0 ? list[i - 1] : null;
                          return Column(
                            children: [
                              if (_track == 'loka' &&
                                  n.band == 'lower' &&
                                  prev?.band != 'lower')
                                _EarthDivider(hindi: hi),
                              _NodeCard(
                                node: n,
                                hindi: hi,
                                track: _track,
                                expanded: _expanded == n.id,
                                onTap: () => setState(() =>
                                    _expanded = _expanded == n.id ? null : n.id),
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
          ],
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
                  color: Color(0xFFE8DFFF), size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Text(
              hindi ? 'सृष्टि' : 'Srishty Universe',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 21,
                color: Color(0xFFE8DFFF),
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
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected == t
                            ? AppColors.goldBright.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.12),
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
                            : const Color(0xFFE8DFFF)
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
            color: Colors.white.withValues(alpha: isEarth ? 0.16 : 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEarth
                  ? AppColors.terracottaBright.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.14),
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
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Text('${node.orderNo}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE8DFFF))),
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
                                : const Color(0xFFE8DFFF),
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
                    color: const Color(0xFFE8DFFF).withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                node.desc(hindi),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: const Color(0xFFE8DFFF).withValues(alpha: 0.82),
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
                            const Color(0xFFE8DFFF).withValues(alpha: 0.75),
                      )),
                ],
                const SizedBox(height: 12),
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
            color: const Color(0xFFE8DFFF).withValues(alpha: 0.5),
          ),
        ),
      );
}

/// A seeded starfield at three depths, drifting with scroll.
///
/// Seeded from a fixed value so the sky is the same every build — a field that
/// reshuffles on scroll reads as noise rather than as depth.
class _StarfieldPainter extends CustomPainter {
  final double offset;
  const _StarfieldPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(20260808);
    const layers = [(40, 0.12, 0.9), (45, 0.28, 1.4), (35, 0.5, 2.0)];

    for (final (count, parallax, radius) in layers) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18 + parallax * 0.5);
      for (var i = 0; i < count; i++) {
        final x = rnd.nextDouble() * size.width;
        final baseY = rnd.nextDouble() * size.height;
        // Wrap vertically so the field never runs out as the user scrolls.
        final y = (baseY - offset * parallax) % size.height;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.offset != offset;
}
