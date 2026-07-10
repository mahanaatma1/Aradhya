import 'package:flutter/cupertino.dart' show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import 'festivals.dart';
import '../../shared/widgets/stitched_border.dart';
import 'panchang_engine.dart' show lunarMonth;
import 'panchang_names.dart' show monthNames;
import 'panchang_providers.dart';

const _minYear = 1950;
const _maxYear = 2100;
const _totalMonths = (_maxYear - _minYear + 1) * 12;

DateTime _monthForIndex(int i) => DateTime(_minYear, 1 + i);
int _indexForMonth(DateTime m) => (m.year - _minYear) * 12 + (m.month - 1);

// Hindi date names (Dart weekday 1=Mon..7=Sun; month 1=Jan..12=Dec).
const _wkFullHi = [
  'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'
];
const _wkShortHi = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
const _monthsHi = [
  'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
  'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
];

/// Bilingual date label. English uses [DateFormat]; Hindi is built from the
/// tables above so weekday/month names localise (DateFormat defaults to en).
String _fmtDay(DateTime d, bool hi, {bool full = false, bool year = false}) {
  if (!hi) {
    return DateFormat(year
            ? 'EEE, d MMM yyyy'
            : full
                ? 'EEEE, d MMM'
                : 'EEE, d MMM')
        .format(d);
  }
  final wd = (full ? _wkFullHi : _wkShortHi)[d.weekday - 1];
  final base = '$wd, ${d.day} ${_monthsHi[d.month - 1]}';
  return year ? '$base ${d.year}' : base;
}

/// Gregorian "month year" header, localised.
String _fmtMonth(DateTime m, bool hi) =>
    hi ? '${_monthsHi[m.month - 1]} ${m.year}' : DateFormat('MMMM yyyy').format(m);

/// Full Hindu Panchang calendar — a swipeable month pager across 1950–2100.
/// Swipe left/right (or use the arrows) to change months. North/South
/// (Purnimanta/Amanta) switch, festival markers, a Festivals & Vrats list, and
/// a festival detail sheet. Tap a day for its full panchang.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final int _initial = _indexForMonth(DateTime.now());
  late final PageController _pc = PageController(initialPage: _initial);
  late int _index = _initial;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int index) {
    final clamped = index.clamp(0, _totalMonths - 1);
    _pc.animateToPage(clamped,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _goToDate(bool hi) async {
    var temp = _monthForIndex(_index);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(hi ? 'रद्द करें' : 'Cancel'),
                      ),
                      Text(hi ? 'तिथि चुनें' : 'Go to date',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, temp),
                        child: Text(hi ? 'जाएँ' : 'Go'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: temp,
                    minimumDate: DateTime(_minYear, 1, 1),
                    maximumDate: DateTime(_maxYear, 12, 31),
                    onDateTimeChanged: (d) => temp = d,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      ref.read(panchangDateProvider.notifier).state = picked;
      _pc.jumpToPage(_indexForMonth(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(localeProvider).languageCode == 'hi';
    final amanta = ref.watch(amantaSystemProvider);
    final scheme = Theme.of(context).colorScheme;
    final month = _monthForIndex(_index);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'हिंदू पंचांग' : 'Hindu Panchang'),
        actions: [
          IconButton(
            tooltip: hi ? 'तिथि पर जाएँ' : 'Go to date',
            icon: const Icon(Icons.event_rounded),
            onPressed: () => _goToDate(hi),
          ),
          TextButton(
            onPressed: () {
              ref.read(panchangDateProvider.notifier).state = DateTime.now();
              _go(_initial);
            },
            child: Text(hi ? 'आज' : 'Today'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: _SystemToggle(amanta: amanta, hi: hi, ref: ref),
          ),
          // Month header with prev / next arrows + Hindu-month subtitle.
          Row(
            children: [
              _ArrowBtn(
                icon: Icons.chevron_left_rounded,
                enabled: _index > 0,
                onTap: () => _go(_index - 1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _fmtMonth(month, hi),
                      style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: scheme.primary),
                    ),
                    Text(
                      _hinduMonthLabel(month, amanta, hi),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.secondary),
                    ),
                  ],
                ),
              ),
              _ArrowBtn(
                icon: Icons.chevron_right_rounded,
                enabled: _index < _totalMonths - 1,
                onTap: () => _go(_index + 1),
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _totalMonths,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) =>
                  _MonthPage(month: _monthForIndex(i), hi: hi),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Hindu lunar month(s) spanning a Gregorian month, in the chosen
/// convention — so the North/South toggle visibly changes it.
String _hinduMonthLabel(DateTime month, bool amanta, bool hi) {
  final tz = DateTime.now().timeZoneOffset;
  final days = DateTime(month.year, month.month + 1, 0).day;
  final seen = <int>[];
  for (final d in [1, 8, 16, 24, days]) {
    final lm = lunarMonth(DateTime(month.year, month.month, d), tz);
    final idx = amanta ? lm.amanta : lm.purnimanta;
    if (!seen.contains(idx)) seen.add(idx);
  }
  return seen.map((i) => monthNames[i](hi)).join(' – ');
}

class _MonthPage extends ConsumerWidget {
  final DateTime month;
  final bool hi;
  const _MonthPage({required this.month, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
      children: [
        _MonthGrid(month: month, hi: hi),
        const SizedBox(height: 16),
        _FestivalList(month: month, hi: hi),
      ],
    );
  }
}

class _SystemToggle extends StatelessWidget {
  final bool amanta;
  final bool hi;
  final WidgetRef ref;
  const _SystemToggle(
      {required this.amanta, required this.hi, required this.ref});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String sub, bool selected, VoidCallback onTap) {
      final scheme = Theme.of(context).colorScheme;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      scheme.primary.withValues(alpha: selected ? 0.5 : 0.18)),
            ),
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: selected ? scheme.primary : scheme.onSurface)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(hi ? 'पूर्णिमांत' : 'Purnimanta', hi ? 'उत्तर भारत' : 'North India',
            !amanta,
            () => ref.read(amantaSystemProvider.notifier).state = false),
        const SizedBox(width: 10),
        chip(hi ? 'अमांत' : 'Amanta', hi ? 'दक्षिण भारत' : 'South India', amanta,
            () => ref.read(amantaSystemProvider.notifier).state = true),
      ],
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _ArrowBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon,
          color: enabled
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.25)),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  final DateTime month;
  final bool hi;
  const _MonthGrid({required this.month, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tz = DateTime.now().timeZoneOffset;
    final today = DateTime.now();
    final selected = ref.watch(panchangDateProvider);
    final festivals = monthFestivals(month.year, month.month, tz);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7;
    final weekdays = hi
        ? ['र', 'सो', 'मं', 'बु', 'गु', 'शु', 'श']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < weekdays.length; i++)
              Expanded(
                child: Center(
                  child: Text(weekdays[i],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: i == 0
                              ? scheme.error.withValues(alpha: 0.7)
                              : scheme.onSurface.withValues(alpha: 0.5))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.92,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
            for (var day = 1; day <= daysInMonth; day++)
              _DayCell(
                day: day,
                sunday: DateTime(month.year, month.month, day).weekday == 7,
                isToday: same(DateTime(month.year, month.month, day), today),
                isSelected:
                    same(DateTime(month.year, month.month, day), selected),
                festival: festivals[day],
                onTap: () {
                  ref.read(panchangDateProvider.notifier).state =
                      DateTime(month.year, month.month, day);
                  context.push('/panchang');
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool sunday;
  final bool isToday;
  final bool isSelected;
  final FestivalHit? festival;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.sunday,
    required this.isToday,
    required this.isSelected,
    required this.festival,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final marked = isToday || isSelected;
    final numColor = isToday
        ? scheme.onPrimary
        : isSelected
            ? scheme.primary
            : sunday
                ? scheme.error.withValues(alpha: 0.85)
                : scheme.onSurface;
    final dotColor = festival == null
        ? null
        : (festival!.major ? scheme.primary : scheme.secondary);

    final number = Text('$day',
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: numColor));

    // Today / selected day sits in a stitched square box (the app motif);
    // other days are just the number.
    final box = SizedBox(
      width: 34,
      height: 32,
      child: marked
          ? Container(
              decoration: BoxDecoration(
                color: isToday ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: CustomPaint(
                foregroundPainter: StitchedBorderPainter(
                  color: isToday ? const Color(0xFFFDEEDE) : scheme.primary,
                  inset: 3,
                  radius: 6,
                  strokeWidth: 1.1,
                  dash: 3,
                  gap: 2.5,
                ),
                child: Center(child: number),
              ),
            )
          : Center(child: number),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          box,
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _FestivalList extends ConsumerWidget {
  final DateTime month;
  final bool hi;
  const _FestivalList({required this.month, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tz = DateTime.now().timeZoneOffset;
    final festivals = monthFestivals(month.year, month.month, tz);
    final days = festivals.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child:
                    Divider(color: scheme.secondary.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                (hi ? 'त्योहार व व्रत' : 'Festivals & Vrats').toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: scheme.secondary),
              ),
            ),
            Expanded(
                child:
                    Divider(color: scheme.secondary.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 6),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                  hi
                      ? 'इस माह कोई प्रमुख पर्व नहीं'
                      : 'No major festivals this month',
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.5))),
            ),
          )
        else
          for (final d in days)
            _FestivalRow(
              date: DateTime(month.year, month.month, d),
              hit: festivals[d]!,
              hi: hi,
            ),
      ],
    );
  }
}

class _FestivalRow extends ConsumerWidget {
  final DateTime date;
  final FestivalHit hit;
  final bool hi;
  const _FestivalRow({required this.date, required this.hit, required this.hi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = hit.major ? scheme.primary : scheme.secondary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showFestivalDetail(context, ref, date, hit, hi),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                child: CustomPaint(
                  foregroundPainter: StitchedBorderPainter(
                    color: const Color(0xFFFDEEDE),
                    inset: 3,
                    radius: 8,
                    strokeWidth: 1.1,
                    dash: 3,
                    gap: 2.5,
                  ),
                  child: Center(
                    child: Text('${date.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.name(hi),
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  Text(_fmtDay(date, hi, full: true),
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet with the festival's name, date, description, and a link to
/// that day's full panchang.
void showFestivalDetail(BuildContext context, WidgetRef ref, DateTime date,
    FestivalHit hit, bool hi) {
  final scheme = Theme.of(context).colorScheme;
  final color = hit.major ? scheme.primary : scheme.secondary;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(_fmtDay(date, hi, year: true),
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12, color: color)),
          ),
          const SizedBox(height: 12),
          Text(hit.name(hi),
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 24)),
          if (hit.desc != null) ...[
            const SizedBox(height: 10),
            Text(hit.desc!(hi),
                style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.8))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ref.read(panchangDateProvider.notifier).state = date;
                Navigator.pop(ctx);
                context.push('/panchang');
              },
              icon: const Icon(Icons.wb_sunny_outlined, size: 18),
              label: Text(
                  hi ? 'इस दिन का पंचांग देखें' : "View this day's Panchang"),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    ),
  );
}
