import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'festival_models.dart';
import 'festival_providers.dart';

/// The Festival Explorer.
///
/// Two modes over one dataset: Upcoming, which resolves the stored rules to
/// real dates and orders them; and Browse, which stays in rule-space so a
/// festival can be found by name or category at any time of year.
class FestivalsScreen extends ConsumerStatefulWidget {
  const FestivalsScreen({super.key});

  @override
  ConsumerState<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends ConsumerState<FestivalsScreen> {
  bool _upcoming = true;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'त्योहार' : 'Festivals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: hi ? 'खोजें' : 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          _ModeToggle(
            upcoming: _upcoming,
            hindi: hi,
            onChanged: (v) => setState(() => _upcoming = v),
          ),
          if (!_upcoming)
            _CategoryChips(
              selected: _category,
              hindi: hi,
              onSelected: (c) => setState(() => _category = c),
            ),
          Expanded(
            child: _upcoming ? _UpcomingList(hindi: hi) : _BrowseList(
                hindi: hi, category: _category),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool upcoming;
  final bool hindi;
  final ValueChanged<bool> onChanged;

  const _ModeToggle(
      {required this.upcoming, required this.hindi, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
              value: true, label: Text(hindi ? 'आगामी' : 'Upcoming')),
          ButtonSegment(
              value: false, label: Text(hindi ? 'सभी' : 'Browse')),
        ],
        selected: {upcoming},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final bool hindi;
  final ValueChanged<String?> onSelected;

  const _CategoryChips(
      {required this.selected, required this.hindi, required this.onSelected});

  static const _cats = <(String?, String, String)>[
    (null, 'All', 'सभी'),
    ('major', 'Major', 'प्रमुख'),
    ('vrat', 'Vrat', 'व्रत'),
    ('jayanti', 'Jayanti', 'जयंती'),
    ('regional', 'Regional', 'क्षेत्रीय'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (value, en, hi) in _cats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(hindi ? hi : en),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected == value
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected == value
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.8),
                ),
                selectedColor: scheme.primary.withValues(alpha: 0.14),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingList extends ConsumerWidget {
  final bool hindi;
  const _UpcomingList({required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingFestivalsProvider);
    return AsyncView(
      value: upcoming,
      isEmpty: (l) => l.isEmpty,
      emptyMessage: hindi ? 'कोई त्योहार नहीं' : 'No festivals found',
      builder: (list) {
        final today = DateTime.now();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            final prev = i == 0 ? null : list[i - 1];
            final newMonth =
                prev == null || prev.date.month != r.date.month ||
                    prev.date.year != r.date.year;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (newMonth) _MonthHeader(date: r.date, hindi: hindi),
                _FestivalRow(resolved: r, today: today, hindi: hindi),
              ],
            );
          },
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime date;
  final bool hindi;
  const _MonthHeader({required this.date, required this.hindi});

  static const _en = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _hi = [
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्तूबर', 'नवंबर', 'दिसंबर'
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
      child: Text(
        '${hindi ? _hi[date.month - 1] : _en[date.month - 1]} ${date.year}',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

const _accent = Color(0xFFE0762A);

class _FestivalRow extends StatelessWidget {
  final ResolvedFestival resolved;
  final DateTime today;
  final bool hindi;

  const _FestivalRow(
      {required this.resolved, required this.today, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = resolved.festival;
    final away = resolved.daysFrom(today);
    final soon = away <= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/festivals/${f.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: soon
                    ? _accent.withValues(alpha: 0.45)
                    : scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(date: resolved.date, highlight: soon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title(hindi),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      f.desc(hindi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.38,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _DaysAway(days: away, hindi: hindi),
                        if (!f.isPanIndia) ...[
                          const SizedBox(width: 8),
                          _RegionChip(region: f.regions.first),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool highlight;
  const _DateBadge({required this.date, required this.highlight});

  static const _mon = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: highlight ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text('${date.day}',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: _accent)),
          const SizedBox(height: 2),
          Text(_mon[date.month - 1],
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: _accent.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _DaysAway extends StatelessWidget {
  final int days;
  final bool hindi;
  const _DaysAway({required this.days, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = days == 0
        ? (hindi ? 'आज' : 'Today')
        : days == 1
            ? (hindi ? 'कल' : 'Tomorrow')
            : (hindi ? '$days दिन बाद' : 'in $days days');
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: days <= 1 ? FontWeight.w700 : FontWeight.w600,
        color: days <= 7 ? _accent : scheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String region;
  const _RegionChip({required this.region});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        region.replaceAll('-', ' '),
        style: TextStyle(
            fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _BrowseList extends ConsumerWidget {
  final bool hindi;
  final String? category;
  const _BrowseList({required this.hindi, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allFestivalsProvider);
    return AsyncView(
      value: all,
      isEmpty: (l) => l.isEmpty,
      emptyMessage: hindi ? 'कोई त्योहार नहीं' : 'No festivals found',
      builder: (list) {
        final shown = category == null
            ? list
            : list.where((f) => f.category == category).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          itemCount: shown.length,
          itemBuilder: (context, i) => _RuleRow(f: shown[i], hindi: hindi),
        );
      },
    );
  }
}

/// A festival in rule-space — no date, because Browse is year-independent.
class _RuleRow extends StatelessWidget {
  final Festival f;
  final bool hindi;
  const _RuleRow({required this.f, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/festivals/${f.id}'),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      ruleLabel(f, hindi),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rule in words — "Kartika, Krishna Paksha, Amavasya".
///
/// Shown rather than hidden, because the rule is the durable fact; the date is
/// only this year's answer to it.
String ruleLabel(Festival f, bool hindi) {
  if (f.isSolar) return f.solarRule ?? '';
  final month = (f.lunarMonth ?? '').isEmpty
      ? ''
      : f.lunarMonth![0].toUpperCase() + f.lunarMonth!.substring(1);
  if (f.paksha == null || f.tithi == null) {
    return f.solarRule ?? month;
  }
  final paksha = f.paksha == 'shukla'
      ? (hindi ? 'शुक्ल पक्ष' : 'Shukla Paksha')
      : (hindi ? 'कृष्ण पक्ष' : 'Krishna Paksha');
  final t = f.tithi == 15
      ? (f.paksha == 'shukla'
          ? (hindi ? 'पूर्णिमा' : 'Purnima')
          : (hindi ? 'अमावस्या' : 'Amavasya'))
      : (hindi ? 'तिथि ${f.tithi}' : 'Tithi ${f.tithi}');
  return '$month, $paksha, $t';
}
