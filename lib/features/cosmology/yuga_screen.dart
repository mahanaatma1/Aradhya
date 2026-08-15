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

/// Yuga Explorer — the four ages, drawn to scale.
///
/// The wheel's arcs are **proportional to duration**, which is the whole point:
/// Satya is four times Kali, and a chart with four equal quarters would quietly
/// assert the opposite of what the text says.
class YugaScreen extends ConsumerStatefulWidget {
  const YugaScreen({super.key});

  @override
  ConsumerState<YugaScreen> createState() => _YugaScreenState();
}

class _YugaScreenState extends ConsumerState<YugaScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final yugas = ref.watch(yugasProvider);
    final cycles = ref.watch(timeCyclesProvider).valueOrNull ?? const [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1440), Color(0xFF4A3A7A), Color(0xFF150E2C)],
          ),
        ),
        child: SafeArea(
          child: AsyncView(
            value: yugas,
            isEmpty: (l) => l.isEmpty,
            emptyMessage: hi ? 'अभी कोई युग नहीं' : 'No yugas yet',
            builder: (list) {
              final sel = list[_selected.clamp(0, list.length - 1)];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  _TopBar(hindi: hi),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: _Wheel(
                      yugas: list,
                      selected: _selected,
                      hindi: hi,
                      onSelect: (i) => setState(() => _selected = i),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _YugaDetail(node: sel, hindi: hi),
                  const SizedBox(height: 24),
                  if (cycles.isNotEmpty) _ZoomOut(cycles: cycles, hindi: hi),
                  const SizedBox(height: 20),
                  _Disclaimer(hindi: hi),
                ],
              );
            },
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
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFE8DFFF), size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Text(
            hindi ? 'युग चक्र' : 'Yuga Explorer',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 21,
              color: Color(0xFFE8DFFF),
            ),
          ),
        ],
      );
}

/// The proportional ring.
class _Wheel extends StatelessWidget {
  final List<CosmologyNode> yugas;
  final int selected;
  final bool hindi;
  final ValueChanged<int> onSelect;

  const _Wheel({
    required this.yugas,
    required this.selected,
    required this.hindi,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [
      for (final y in yugas) (y.durationValue ?? 1).toDouble(),
    ];
    final total = durations.fold<double>(0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        final centre = Offset(size / 2, size / 2);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              onTapUp: (d) {
                // Which arc was tapped: angle from centre, matched against the
                // cumulative sweeps.
                final v = d.localPosition - centre;
                if (v.distance > size / 2 || v.distance < size * 0.22) return;
                var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
                if (angle < 0) angle += 2 * math.pi;
                var acc = 0.0;
                for (var i = 0; i < durations.length; i++) {
                  final sweep = 2 * math.pi * durations[i] / total;
                  if (angle >= acc && angle < acc + sweep) {
                    onSelect(i);
                    return;
                  }
                  acc += sweep;
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _WheelPainter(
                      durations: durations,
                      selected: selected,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hindi ? 'महायुग' : 'MAHAYUGA',
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldBright.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '4,320,000',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                          color: Color(0xFFE8DFFF),
                        ),
                      ),
                      Text(
                        hindi ? 'वर्ष' : 'years',
                        style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFE8DFFF)
                                .withValues(alpha: 0.7)),
                      ),
                    ],
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

class _WheelPainter extends CustomPainter {
  final List<double> durations;
  final int selected;
  const _WheelPainter({required this.durations, required this.selected});

  /// Bright gold for Satya darkening toward indigo at Kali — dharma declining
  /// is the one thing every account of the yugas agrees on.
  static const _colors = [
    Color(0xFFE6C34A),
    Color(0xFFC9913C),
    Color(0xFF8A6AA8),
    Color(0xFF4A3A7A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2;
    final total = durations.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < durations.length; i++) {
      final sweep = 2 * math.pi * durations[i] / total;
      final isSel = i == selected;
      final r = isSel ? radius : radius * 0.93;

      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        start,
        sweep - 0.02,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? radius * 0.46 : radius * 0.4
          ..color = _colors[i % _colors.length]
              .withValues(alpha: isSel ? 1 : 0.72),
      );
      start += sweep;
    }

    // The present age, marked on the Kali arc.
    if (durations.length == 4) {
      final kaliStart = -math.pi / 2 +
          2 * math.pi * (durations[0] + durations[1] + durations[2]) / total;
      final kaliSweep = 2 * math.pi * durations[3] / total;
      final a = kaliStart + kaliSweep * 0.5;
      final p = centre + Offset(math.cos(a), math.sin(a)) * (radius * 0.78);
      canvas.drawCircle(p, 5, Paint()..color = const Color(0xFFFFF3D0));
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFFFF3D0).withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.selected != selected;
}

class _YugaDetail extends StatelessWidget {
  final CosmologyNode node;
  final bool hindi;
  const _YugaDetail({required this.node, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final ratio = node.dharmaRatio;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.title(hindi),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 23,
                    color: Color(0xFFE8DFFF),
                  ),
                ),
              ),
              if (node.isPresent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldBright.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    // Hedged deliberately: this is where the tradition places
                    // the present, not a dated fact.
                    hindi ? 'इसी गणना में वर्तमान' : 'The present, by this reckoning',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldBright),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${node.durationYears} ${hindi ? "वर्ष" : "years"}',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.goldBright.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 10),
          Text(
            node.desc(hindi),
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: const Color(0xFFE8DFFF).withValues(alpha: 0.88),
            ),
          ),
          if (ratio != null) ...[
            const SizedBox(height: 16),
            Text(
              hindi ? 'धर्म' : 'DHARMA',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE8DFFF).withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                for (var i = 0; i < ratio.$2; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: i < ratio.$1
                            ? AppColors.goldBright
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Text(
                  '${ratio.$1}/${ratio.$2}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldBright),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SourceChip(
            hindi: hindi,
            sourceName: node.sourceName,
            sourceRef: node.sourceRef,
            sourceUrl: node.sourceUrl,
            lastVerifiedAt: node.lastVerifiedAt,
          ),
        ],
      ),
    );
  }
}

/// Yuga → mahayuga → manvantara → kalpa, each nesting in the next.
class _ZoomOut extends StatelessWidget {
  final List<CosmologyNode> cycles;
  final bool hindi;
  const _ZoomOut({required this.cycles, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hindi ? 'और बड़ा काल' : 'ZOOM OUT',
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE8DFFF).withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < cycles.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i * 14.0, bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cycles[i].title(hindi),
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFFE8DFFF),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cycles[i].desc(hindi),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: const Color(0xFFE8DFFF)
                                .withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cycles[i].durationYears ?? '',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldBright.withValues(alpha: 0.9),
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

class _Disclaimer extends StatelessWidget {
  final bool hindi;
  const _Disclaimer({required this.hindi});

  @override
  Widget build(BuildContext context) => Text(
        // §4.14 requires this to be explicit: a cosmological model, not a
        // chronology to be set beside geology.
        hindi
            ? 'ये अवधियाँ पुराणों का काल-मॉडल हैं। इन्हें आधुनिक वैज्ञानिक कालक्रम के समकक्ष नहीं रखा जा रहा।'
            : 'These durations are the Puranic model of time. They are not being equated with modern scientific chronology.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.5,
          color: const Color(0xFFE8DFFF).withValues(alpha: 0.5),
        ),
      );
}
