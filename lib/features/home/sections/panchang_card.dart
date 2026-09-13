import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/stitched_border.dart';
import '../../panchang/panchang_providers.dart';
import '../../widgets/home_widgets.dart';

/// Today's Panchang — a clean, single-column card: date + masa/paksha header,
/// a Tithi/Nakshatra/Yoga/Karana grid, sunrise/sunset, Rahu Kaal, and two
/// actions (View Panchang · Full Calendar). All values computed on-device.
class PanchangCard extends ConsumerWidget {
  const PanchangCard({super.key});

  static const _accent = AppColors.terracotta; // brass — this room's color

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
  static Color _ink(ColorScheme s) => s.onSurface;
  static Color _label(ColorScheme s) => s.onSurface.withValues(alpha: 0.5);
  static Color _muted(ColorScheme s) => s.onSurface.withValues(alpha: 0.4);
  static Color _dash(ColorScheme s) => s.onSurface.withValues(alpha: 0.14);

  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthsHi = [
    'जन', 'फ़र', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुल', 'अग', 'सित', 'अक्तू', 'नव', 'दिस'
  ];

  static String _time(DateTime? d) {
    if (d == null) return '—';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final p = ref.watch(panchangProvider);
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;

    final waxing = p.paksha.en.toLowerCase().contains('shukla');
    final moonPhase = waxing
        ? (hi ? 'शुक्ल पक्ष' : 'Waxing')
        : (hi ? 'कृष्ण पक्ष' : 'Waning');
    dynamic rahu;
    for (final m in p.muhurats) {
      if (m.name.en.toLowerCase().contains('rahu')) {
        rahu = m;
        break;
      }
    }

    return StitchedCard(
      background: _bg(scheme),
      stitchColor: _accent.withValues(alpha: 0.45),
      radius: 20,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header: date + day + masa · paksha ----
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${now.day}',
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${hi ? p.vara(true) : _weekdaysEn[now.weekday - 1]}, ${(hi ? _monthsHi : _monthsEn)[now.month - 1]} ${now.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: _ink(scheme))),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                              waxing
                                  ? Icons.nightlight_round
                                  : Icons.dark_mode,
                              size: 15,
                              color: const Color(0xFFCB9B3E)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                                '${p.month(hi)} · ${p.paksha(hi)} ($moonPhase)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.5, color: _label(scheme))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DashedLine(color: _dash(scheme)),
            // Tithi leads as the hero fact — that's the one thing a reader
            // actually opens this card to check ("what day is it, for
            // fasting/puja purposes") — everything else demotes beneath it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: waxing
                          ? const [
                              Color(0xFFFCEFD8),
                              Color(0xFFE8B98A),
                              Color(0xFF9C5A28)
                            ]
                          : [
                              scheme.onSurface.withValues(alpha: 0.5),
                              scheme.onSurface.withValues(alpha: 0.28),
                              scheme.onSurface.withValues(alpha: 0.16),
                            ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.tithi.current(hi),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: _ink(scheme))),
                      Text(
                          '${p.tithi.endTime == null ? (hi ? 'पूरे दिन' : 'all day') : '${hi ? 'तक ' : 'till '}${_time(p.tithi.endTime)}'} · ${p.nakshatra.current(hi)} ${hi ? 'नक्षत्र' : 'nakshatra'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: _label(scheme))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // A sunrise-to-sunset day bar with Rahu Kaal marked as a hazard
            // zone — a window a reader can *see*, not decode from a label.
            DayBar(
              scheme: scheme,
              hi: hi,
              sunrise: p.sunrise,
              sunset: p.sunset,
              rahuStart: rahu?.start,
              rahuEnd: rahu?.end,
            ),
            const SizedBox(height: 10),
            if (rahu != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 14, color: scheme.error),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                        '${hi ? 'राहु काल' : 'Rahu Kaal'} ${_time(rahu.start)}–${_time(rahu.end)} — ${hi ? 'नई शुरुआत से बचें' : 'avoid new beginnings'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: scheme.error)),
                  ),
                ],
              ),
            DashedLine(color: _dash(scheme)),
            // Yoga · Karana · Add-to-widget — demoted to a compact strip.
            Row(children: [
              _element(scheme, hi ? 'योग' : 'Yoga', p.yoga, hi),
              _element(scheme, hi ? 'करण' : 'Karana', p.karana, hi),
              _widgetOption(scheme, hi, () => pinPanchangWidget(ref)),
            ]),
            const SizedBox(height: 14),
            // ---- Actions ----
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.wb_sunny_outlined,
                    label: hi ? 'पंचांग देखें' : 'View Panchang',
                    onTap: () => context.push('/panchang'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.calendar_month_rounded,
                    label: hi ? 'पूर्ण कैलेंडर' : 'Full Calendar',
                    onTap: () => context.push('/calendar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _element(ColorScheme s, String label, dynamic el, bool hi) =>
      _cell(
        s,
        label,
        el.current(hi),
        el.endTime == null
            ? (hi ? 'पूरे दिन' : 'all day')
            : '${hi ? 'तक ' : 'till '}${_time(el.endTime)}',
      );

  /// A labelled cell — LABEL / value / optional sub-line.
  static Widget _cell(ColorScheme s, String label, String value, String? sub) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: _label(s))),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: _ink(s))),
            if (sub != null && sub.isNotEmpty)
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: _muted(s))),
          ],
        ),
      );

  /// The "add to home-screen widget" slot (shown beside sunrise/sunset).
  static Widget _widgetOption(ColorScheme s, bool hi, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.widgets_rounded, size: 14, color: _accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(hi ? 'विजेट' : 'WIDGET',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: _label(s))),
                ),
              ]),
              const SizedBox(height: 2),
              Text(hi ? 'होम पर जोड़ें' : 'Add to home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
            ],
          ),
        ),
      );

  static Widget _actionBtn(
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      Material(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: _accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: _accent)),
                ),
              ],
            ),
          ),
        ),
      );
}

/// A sunrise-to-sunset bar with Rahu Kaal shaded on it as a hazard zone —
/// turns "avoid this window" into something seen at a glance rather than a
/// time range that has to be read and mentally placed in the day.
class DayBar extends StatelessWidget {
  final ColorScheme scheme;
  final bool hi;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? rahuStart;
  final DateTime? rahuEnd;

  const DayBar({super.key, 
    required this.scheme,
    required this.hi,
    required this.sunrise,
    required this.sunset,
    required this.rahuStart,
    required this.rahuEnd,
  });

  static String _time(DateTime? d) {
    if (d == null) return '—';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context) {
    final rise = sunrise ?? DateTime.now();
    final set = sunset ?? rise.add(const Duration(hours: 12));
    final totalMin = set.difference(rise).inMinutes.clamp(1, 24 * 60);
    double frac(DateTime? d) {
      if (d == null) return 0;
      return (d.difference(rise).inMinutes / totalMin).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hi ? 'सूर्योदय ${_time(sunrise)}' : 'Sunrise ${_time(sunrise)}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            Text(hi ? 'सूर्यास्त ${_time(sunset)}' : 'Sunset ${_time(sunset)}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(colors: [
                        AppColors.terracottaBright,
                        const Color(0xFFF4D9A8),
                        const Color(0xFFF4D9A8),
                        scheme.onSurface.withValues(alpha: 0.35),
                      ]),
                    ),
                  ),
                  if (rahuStart != null && rahuEnd != null)
                    Positioned(
                      left: (frac(rahuStart) * w).clamp(0, w - 4),
                      width:
                          ((frac(rahuEnd) - frac(rahuStart)) * w).clamp(4, w),
                      top: -2,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _bg(scheme), width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static Color _bg(ColorScheme s) =>
      s.brightness == Brightness.dark ? AppColors.kraft2Dark : AppColors.paper;
}

/// The signature dashed "stitched" divider — same motif as the Verse card.
class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 1.6,
          width: double.infinity,
          child: CustomPaint(painter: DashPainter(color)),
        ),
      );
}

class DashPainter extends CustomPainter {
  final Color color;
  DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(DashPainter old) => old.color != color;
}
