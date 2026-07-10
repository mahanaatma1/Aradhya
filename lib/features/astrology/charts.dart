import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'astro_chart.dart';
import 'astrology_data.dart';

// House-center positions (unit square, y down) for the North-Indian diamond.
const _northCenters = <Offset>[
  Offset(0.50, 0.29), // H1
  Offset(0.27, 0.14), // H2
  Offset(0.14, 0.27), // H3
  Offset(0.29, 0.50), // H4
  Offset(0.14, 0.73), // H5
  Offset(0.27, 0.86), // H6
  Offset(0.50, 0.71), // H7
  Offset(0.73, 0.86), // H8
  Offset(0.86, 0.73), // H9
  Offset(0.71, 0.50), // H10
  Offset(0.86, 0.27), // H11
  Offset(0.73, 0.14), // H12
];

class NorthIndianChart extends StatelessWidget {
  final ChartView view;
  const NorthIndianChart({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byHouse = <int, List<ChartPlacement>>{};
    for (final p in view.placements) {
      (byHouse[view.houseOf(p.sign)] ??= []).add(p);
    }
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth;
        final cell = s * 0.2;
        return Stack(
          children: [
            CustomPaint(size: Size.square(s), painter: _NorthLines(scheme)),
            for (var h = 1; h <= 12; h++)
              Positioned(
                left: _northCenters[h - 1].dx * s - cell / 2,
                top: _northCenters[h - 1].dy * s - cell / 2,
                width: cell,
                height: cell,
                child: _HouseCell(
                  sign: (view.lagnaSign + h - 1) % 12,
                  planets: byHouse[h] ?? const [],
                  isLagna: h == 1,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _NorthLines extends CustomPainter {
  final ColorScheme scheme;
  _NorthLines(this.scheme);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = scheme.primary.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    canvas.drawLine(Offset.zero, Offset(w, h), p);
    canvas.drawLine(Offset(w, 0), Offset(0, h), p);
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_NorthLines old) => old.scheme != scheme;
}

/// South-Indian fixed grid: sign -> (row, col) in a 4x4.
const _southCell = <int, List<int>>{
  11: [0, 0], 0: [0, 1], 1: [0, 2], 2: [0, 3],
  10: [1, 0], 3: [1, 3],
  9: [2, 0], 4: [2, 3],
  8: [3, 0], 7: [3, 1], 6: [3, 2], 5: [3, 3],
};

class SouthIndianChart extends StatelessWidget {
  final ChartView view;
  const SouthIndianChart({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bySign = <int, List<ChartPlacement>>{};
    for (final p in view.placements) {
      (bySign[p.sign] ??= []).add(p);
    }
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth;
        final cell = s / 4;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.7), width: 1.4),
              ),
            ),
            for (final e in _southCell.entries)
              Positioned(
                left: e.value[1] * cell,
                top: e.value[0] * cell,
                width: cell,
                height: cell,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: _HouseCell(
                    sign: e.key,
                    planets: bySign[e.key] ?? const [],
                    isLagna: e.key == view.lagnaSign,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _HouseCell extends StatelessWidget {
  final int sign;
  final List<ChartPlacement> planets;
  final bool isLagna;
  const _HouseCell(
      {required this.sign, required this.planets, required this.isLagna});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${sign + 1}${isLagna ? ' Asc' : ''}',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: scheme.secondary),
          ),
          const SizedBox(height: 1),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            runSpacing: 0,
            children: [
              for (final p in planets)
                Text(
                  '${planetInfo[p.key]!.short}${p.retro ? '˚' : ''}',
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: AppFonts.body,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
