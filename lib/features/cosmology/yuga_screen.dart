import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import '../narrative/narrative_providers.dart';
import 'cosmology_models.dart';
import 'cosmology_providers.dart';

/// YG-01: which epic's narrative is set in each yuga, per the Purana's own
/// account (Treta is "the age of the Ramayana", Dvapara "the age of the
/// Mahabharata" — see the yuga entries' short_description in
/// content/data/cosmology/vishnu_purana.jsonl). Satya and Kali carry no epic
/// of their own in this corpus, so they are intentionally absent here rather
/// than guessed at.
const _yugaEpic = {
  'yuga-treta': 'ramayana',
  'yuga-dvapara': 'mahabharata',
};

/// Yuga Explorer — the four ages, drawn to scale.
///
/// Rebuilt on the app's own paper-and-gold palette. The previous version was a
/// dark indigo wash borrowed from the Srishty screen, which made the one place
/// in the app that is about *decline over time* look like a screen about outer
/// space, and put white-on-indigo text next to every cream card around it.
///
/// The wheel's arcs stay proportional to duration, because that is the whole
/// argument: Satya is four times Kali, and four equal quarters would quietly
/// assert the opposite of what the text says. What changed is that the ages
/// now also read as a decline — gold burning down to ash — instead of four
/// arbitrary colours.
class YugaScreen extends ConsumerStatefulWidget {
  const YugaScreen({super.key});

  @override
  ConsumerState<YugaScreen> createState() => _YugaScreenState();
}

class _YugaScreenState extends ConsumerState<YugaScreen> {
  int _selected = 0;

  /// Gold → bronze → copper → ash. The order is the point.
  static const _ageColors = [
    Color(0xFFC97A3E),
    Color(0xFFC07A3E),
    Color(0xFF9C5A3C),
    Color(0xFF6E5A4E),
  ];

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final yugas = ref.watch(yugasProvider);
    final cycles = ref.watch(timeCyclesProvider).valueOrNull ?? const [];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'युग' : 'The Four Ages')),
      body: AsyncView(
        value: yugas,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'अभी कोई युग नहीं' : 'No yugas yet',
        builder: (list) {
          final sel = list[_selected.clamp(0, list.length - 1)];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              Text(
                hi
                    ? 'चार युग, अवधि के अनुपात में। सत्ययुग कलियुग से चार गुना लंबा है।'
                    : 'Four ages, drawn in proportion. Satya is four times as long as Kali.',
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 250,
                child: _Wheel(
                  yugas: list,
                  colors: _ageColors,
                  selected: _selected,
                  hindi: hi,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ),
              const SizedBox(height: 18),
              _AgeBars(
                yugas: list,
                colors: _ageColors,
                selected: _selected,
                hindi: hi,
                onSelect: (i) => setState(() => _selected = i),
              ),
              const SizedBox(height: 20),
              _Detail(
                  yuga: sel, colour: _ageColors[_selected % 4], hindi: hi),
              if (cycles.isNotEmpty) ...[
                const SizedBox(height: 22),
                _ZoomOut(cycles: cycles, hindi: hi),
              ],
              const SizedBox(height: 18),
              _Disclaimer(hindi: hi),
            ],
          );
        },
      ),
    );
  }
}

/// The proportional wheel.
class _Wheel extends StatelessWidget {
  final List<CosmologyNode> yugas;
  final List<Color> colors;
  final int selected;
  final bool hindi;
  final ValueChanged<int> onSelect;

  const _Wheel({
    required this.yugas,
    required this.colors,
    required this.selected,
    required this.hindi,
    required this.onSelect,
  });

  static double _years(CosmologyNode n) =>
      double.tryParse((n.durationYears ?? '0').replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final total = yugas.fold<double>(0, (s, n) => s + _years(n));
    if (total <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        return Center(
          child: GestureDetector(
            onTapUp: (d) {
              final centre = Offset(side / 2, side / 2);
              final v = d.localPosition - centre;
              if (v.distance > side / 2 || v.distance < side * 0.17) return;
              var a = math.atan2(v.dy, v.dx) + math.pi / 2;
              if (a < 0) a += 2 * math.pi;
              var acc = 0.0;
              for (var i = 0; i < yugas.length; i++) {
                acc += _years(yugas[i]) / total * 2 * math.pi;
                if (a <= acc) return onSelect(i);
              }
            },
            child: SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _WheelPainter(
                  fractions: [for (final y in yugas) _years(y) / total],
                  colors: colors,
                  selected: selected,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hindi ? 'महायुग' : 'MAHAYUGA',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45)),
                      ),
                      const SizedBox(height: 2),
                      Text('4,320,000',
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      Text(hindi ? 'वर्ष' : 'years',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final int selected;

  const _WheelPainter({
    required this.fractions,
    required this.colors,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var start = -math.pi / 2;

    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 2 * math.pi;
      final isSel = i == selected;
      final r = isSel ? radius : radius * 0.94;

      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        start,
        sweep - 0.012,
        true,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [
              colors[i % colors.length],
              colors[i % colors.length].withValues(alpha: 0.72),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: r)),
      );

      if (isSel) {
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: r),
          start,
          sweep - 0.012,
          true,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = const Color(0xFF3A2A18).withValues(alpha: 0.55),
        );
      }
      start += sweep;
    }

    // The hub, punched out so the wheel reads as a ring of ages.
    canvas.drawCircle(centre, radius * 0.42,
        Paint()..color = const Color(0xFFF7F5F2));
    canvas.drawCircle(
        centre,
        radius * 0.42,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFC97A3E).withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.selected != selected || old.fractions != fractions;
}

/// Length bars beneath the wheel.
///
/// The wheel shows proportion; the bars let you actually compare two ages
/// without estimating arc angles by eye.
class _AgeBars extends StatelessWidget {
  final List<CosmologyNode> yugas;
  final List<Color> colors;
  final int selected;
  final bool hindi;
  final ValueChanged<int> onSelect;

  const _AgeBars({
    required this.yugas,
    required this.colors,
    required this.selected,
    required this.hindi,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vals = [for (final y in yugas) _Wheel._years(y)];
    final max = vals.isEmpty ? 1.0 : vals.reduce(math.max);

    return Column(
      children: [
        for (var i = 0; i < yugas.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelect(i),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      yugas[i].title(hindi),
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 14,
                        fontWeight:
                            i == selected ? FontWeight.w800 : FontWeight.w600,
                        color: i == selected
                            ? colors[i % colors.length]
                            : scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : vals[i] / max,
                        minHeight: i == selected ? 12 : 8,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.07),
                        valueColor: AlwaysStoppedAnimation(
                            colors[i % colors.length]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 64,
                    child: Text(
                      yugas[i].durationYears ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  final CosmologyNode yuga;
  final Color colour;
  final bool hindi;
  const _Detail(
      {required this.yuga, required this.colour, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = yuga.attributes['dharma_ratio'];
    final have = (ratio is List && ratio.length == 2)
        ? (ratio[0] as num).toInt()
        : null;
    final present = yuga.attributes['present'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(yuga.title(hindi),
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colour)),
              ),
              if (present)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: colour.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    hindi ? 'इस गणना अनुसार वर्तमान' : 'the present age',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colour),
                  ),
                ),
            ],
          ),
          if (have != null) ...[
            const SizedBox(height: 12),
            Text(hindi ? 'धर्म' : 'DHARMA',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            // Four quarters: the classical image is a bull losing a leg each
            // age, so four segments say it better than a percentage.
            Row(
              children: [
                for (var q = 0; q < 4; q++)
                  Expanded(
                    child: Container(
                      height: 9,
                      margin: EdgeInsets.only(right: q == 3 ? 0 : 5),
                      decoration: BoxDecoration(
                        color: q < have
                            ? colour
                            : scheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              hindi ? 'चार में से $have चरण' : '$have of four quarters',
              style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
          const SizedBox(height: 12),
          Text(yuga.desc(hindi),
              style: const TextStyle(fontSize: 14.5, height: 1.5)),
          if ((yuga.long(hindi) ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(yuga.long(hindi)!,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: scheme.onSurface.withValues(alpha: 0.78))),
          ],
          if (_yugaEpic[yuga.slug] != null) ...[
            const SizedBox(height: 12),
            _EpicLink(epic: _yugaEpic[yuga.slug]!, colour: colour, hindi: hindi),
          ],
          const SizedBox(height: 12),
          SourceChip(
            sourceName: yuga.sourceName,
            sourceRef: yuga.sourceRef,
            sourceUrl: yuga.sourceUrl,
            lastVerifiedAt: yuga.lastVerifiedAt,
            hindi: hindi,
          ),
        ],
      ),
    );
  }
}

/// YG-01: a tappable link from the yuga to the epic set in it, with the
/// scene count fetched so the claim isn't just a label — "38 scenes" says
/// there is somewhere to actually go.
class _EpicLink extends ConsumerWidget {
  final String epic;
  final Color colour;
  final bool hindi;
  const _EpicLink(
      {required this.epic, required this.colour, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(epicScenesProvider(epic)).valueOrNull;
    final isRamayana = epic == 'ramayana';
    final label = isRamayana
        ? (hindi ? 'रामायण' : 'the Ramayana')
        : (hindi ? 'महाभारत' : 'the Mahabharata');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/gyan/$epic'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, size: 18, color: colour),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  children: [
                    TextSpan(
                        text: hindi ? 'इसी युग में सेट: ' : 'Set in this age: '),
                    TextSpan(
                      text: label,
                      style: TextStyle(fontWeight: FontWeight.w800, color: colour),
                    ),
                    if (scenes != null)
                      TextSpan(
                        text: hindi
                            ? ' (${scenes.length} दृश्य)'
                            : ' (${scenes.length} scenes)',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55)),
                      ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colour.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// yuga → mahayuga → manvantara → kalpa, each step showing its multiplier.
class _ZoomOut extends StatelessWidget {
  final List<CosmologyNode> cycles;
  final bool hindi;
  const _ZoomOut({required this.cycles, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hindi ? 'और बड़े पैमाने' : 'ZOOM OUT',
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.45))),
        const SizedBox(height: 10),
        for (var i = 0; i < cycles.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC97A3E).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9C5A3C))),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cycles[i].title(hindi),
                          style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      Text(cycles[i].desc(hindi),
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.7))),
                      if ((cycles[i].durationYears ?? '').isNotEmpty)
                        Text(
                          '${cycles[i].durationYears} ${hindi ? "वर्ष" : "years"}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.55)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final bool hindi;
  const _Disclaimer({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 13, color: scheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            hindi
                ? 'यह एक पारंपरिक कालगणना है। इसे वैज्ञानिक कालक्रम के रूप में प्रस्तुत नहीं किया जा रहा।'
                : 'This is a traditional cosmological model. It is not being presented as scientific chronology.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
