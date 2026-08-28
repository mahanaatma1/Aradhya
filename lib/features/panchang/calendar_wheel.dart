import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import 'calendar_screen.dart' show showFestivalDetail;
import 'festivals.dart';

/// CW-01: the circular year -- twelve months as a ring, festivals as marks
/// on it. A different projection of the same festival data the swipeable
/// month grid already shows; this view exists because a year is a cycle,
/// and a ring says that a flat scrolling list of twelve pages cannot: Chaitra
/// sits next to Phalguna the way it actually recurs, not at opposite ends of
/// a scroll.
class CalendarWheel extends ConsumerWidget {
  final int year;
  final bool hi;
  const CalendarWheel({super.key, required this.year, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tz = DateTime.now().timeZoneOffset;
    // One lookup per month, reusing the exact per-month festival function the
    // grid view already calls -- so the wheel can never show a festival the
    // grid doesn't, or vice versa.
    final byMonth = [
      for (var m = 1; m <= 12; m++) monthFestivals(year, m, tz),
    ];
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(side, side),
                  painter: _WheelPainter(color: scheme.outline),
                ),
                for (var m = 1; m <= 12; m++)
                  ..._marksForMonth(
                      context, ref, side, m, byMonth[m - 1], today),
                for (var m = 1; m <= 12; m++)
                  _MonthLabel(side: side, month: m, hi: hi),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$year',
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: scheme.primary)),
                    Text(hi ? 'वर्ष' : 'year',
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One dot per festival day that month, placed at the angle for its exact
  /// day-of-year -- not just its month -- so Holi and Diwali land at visibly
  /// different points within Phalguna/Kartika's arc rather than stacking at
  /// the segment's centre.
  List<Widget> _marksForMonth(BuildContext context, WidgetRef ref, double side,
      int month, Map<int, FestivalHit> festivals, DateTime today) {
    final daysInYear = DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays + 1;
    final out = <Widget>[];
    for (final entry in festivals.entries) {
      final date = DateTime(year, month, entry.key);
      final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays;
      final angle = -math.pi / 2 + (dayOfYear / daysInYear) * 2 * math.pi;
      final r = side * 0.42;
      final centre = Offset(side / 2, side / 2);
      final pos = centre + Offset(math.cos(angle), math.sin(angle)) * r;
      final hit = entry.value;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      out.add(Positioned(
        left: pos.dx - 7,
        top: pos.dy - 7,
        child: GestureDetector(
          onTap: () => showFestivalDetail(context, ref, date, hit, hi),
          child: Tooltip(
            message: hit.name(hi),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hit.major
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.error, width: 2)
                    : null,
              ),
            ),
          ),
        ),
      ));
    }
    return out;
  }
}

class _WheelPainter extends CustomPainter {
  final Color color;
  const _WheelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.35);
    canvas.drawCircle(centre, r, ring);
    // Twelve spokes, one per month boundary.
    for (var m = 0; m < 12; m++) {
      final a = -math.pi / 2 + (m / 12) * 2 * math.pi;
      final inner = centre + Offset(math.cos(a), math.sin(a)) * (r - 8);
      final outer = centre + Offset(math.cos(a), math.sin(a)) * (r + 8);
      canvas.drawLine(inner, outer, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.color != color;
}

class _MonthLabel extends StatelessWidget {
  final double side;
  final int month; // 1-12
  final bool hi;
  const _MonthLabel(
      {required this.side, required this.month, required this.hi});

  static const _en = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _hiNames = [
    'जन', 'फ़र', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुला', 'अग', 'सित', 'अक्टू', 'नव', 'दिस',
  ];

  @override
  Widget build(BuildContext context) {
    // Centre of the month's arc, so the label sits between its two spokes.
    final a = -math.pi / 2 + ((month - 1) + 0.5) / 12 * 2 * math.pi;
    final r = side * 0.42 + 26;
    final centre = Offset(side / 2, side / 2);
    final pos = centre + Offset(math.cos(a), math.sin(a)) * r;
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 8,
      child: SizedBox(
        width: 36,
        child: Text(
          hi ? _hiNames[month - 1] : _en[month - 1],
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65)),
        ),
      ),
    );
  }
}
