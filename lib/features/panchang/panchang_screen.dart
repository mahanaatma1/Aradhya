import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'panchang_engine.dart';
import 'panchang_providers.dart';

class PanchangScreen extends ConsumerWidget {
  const PanchangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(localeProvider).languageCode == 'hi';
    final date = ref.watch(panchangDateProvider);
    final loc = ref.watch(effectiveLocationProvider);
    final p = ref.watch(panchangProvider);
    final amanta = ref.watch(amantaSystemProvider);
    final scheme = Theme.of(context).colorScheme;

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        ref.read(panchangDateProvider.notifier).state = picked;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'पंचांग' : 'Panchang'),
        actions: [
          IconButton(
            tooltip: hi ? 'पूरा कैलेंडर' : 'Full Calendar',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => context.push('/calendar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // date + location
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(DateFormat('EEE, dd MMM yyyy').format(date)),
              onPressed: pickDate,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(loc.isGps ? Icons.my_location_rounded : Icons.place_rounded,
                    size: 14, color: scheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${loc.name}  ·  ${loc.lat.toStringAsFixed(4)}°N, ${loc.lon.toStringAsFixed(4)}°E',
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Amanta / Purnimanta month-system toggle
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(hi ? 'पूर्णिमांत' : 'Purnimanta'),
                  selected: !amanta,
                  onSelected: (_) =>
                      ref.read(amantaSystemProvider.notifier).state = false,
                ),
                ChoiceChip(
                  label: Text(hi ? 'अमांत' : 'Amanta'),
                  selected: amanta,
                  onSelected: (_) =>
                      ref.read(amantaSystemProvider.notifier).state = true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Named Ekadashi banner (only on Ekadashi tithi)
          if (p.ekadashi != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  scheme.secondary.withValues(alpha: 0.18),
                  scheme.primary.withValues(alpha: 0.10),
                ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.brightness_5_rounded,
                      size: 20, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p.ekadashi!(hi)} ${hi ? 'एकादशी' : 'Ekadashi'}',
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w600,
                          fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // header: month / paksha / vara
          StitchedCard(
            gradient: const LinearGradient(
              colors: [AppColors.terracotta, AppColors.terracottaDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            stitchColor: Colors.white.withValues(alpha: 0.6),
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderBit(label: hi ? 'मास' : 'Month', value: p.month(hi)),
                _HeaderBit(label: hi ? 'पक्ष' : 'Paksha', value: p.paksha(hi)),
                _HeaderBit(label: hi ? 'वार' : 'Vara', value: p.vara(hi)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // main attributes grid
          Row(children: [
            Expanded(child: _ElementCard(label: hi ? 'तिथि' : 'Tithi', e: p.tithi, hi: hi)),
            const SizedBox(width: 12),
            Expanded(child: _ElementCard(label: hi ? 'नक्षत्र' : 'Nakshatra', e: p.nakshatra, hi: hi)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ElementCard(label: hi ? 'योग' : 'Yoga', e: p.yoga, hi: hi)),
            const SizedBox(width: 12),
            Expanded(child: _ElementCard(label: hi ? 'करण' : 'Karana', e: p.karana, hi: hi)),
          ]),
          const SizedBox(height: 14),

          // sun / moon panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(children: [
                  _Time(label: hi ? 'सूर्योदय' : 'Sunrise', time: p.sunrise),
                  _Time(label: hi ? 'सूर्यास्त' : 'Sunset', time: p.sunset),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  child: Divider(color: scheme.outline.withValues(alpha: 0.2)),
                ),
                Row(children: [
                  _Time(label: hi ? 'चंद्रोदय' : 'Moonrise', time: p.moonrise),
                  _Time(label: hi ? 'चंद्रास्त' : 'Moonset', time: p.moonset),
                ]),
              ],
            ),
          ),

          // Auspicious muhurats
          if (p.muhurats.any((m) => m.auspicious)) ...[
            _MuhuratHeader(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2E7D4F),
              label: hi ? 'शुभ मुहूर्त' : 'Auspicious Muhurat',
            ),
            for (final m in p.muhurats.where((m) => m.auspicious))
              _MuhuratRow(m: m, hi: hi),
          ],

          // Inauspicious periods
          if (p.muhurats.any((m) => !m.auspicious)) ...[
            _MuhuratHeader(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFB4462F),
              label: hi ? 'अशुभ काल' : 'Inauspicious',
            ),
            for (final m in p.muhurats.where((m) => !m.auspicious))
              _MuhuratRow(m: m, hi: hi),
          ],
        ],
      ),
    );
  }
}

class _MuhuratHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MuhuratHeader(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _MuhuratRow extends StatelessWidget {
  final Muhurat m;
  final bool hi;
  const _MuhuratRow({required this.m, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              m.name(hi),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          Text(
            '${DateFormat('h:mm a').format(m.start)} – ${DateFormat('h:mm a').format(m.end)}',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBit extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderBit({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    const on = Color(0xFFFDEEDE);
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: on.withValues(alpha: 0.75))),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: on)),
      ],
    );
  }
}

class _ElementCard extends StatelessWidget {
  final String label;
  final PElement e;
  final bool hi;
  const _ElementCard({required this.label, required this.e, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final endTxt = e.endTime == null
        ? null
        : '${hi ? 'तक ' : 'until '}${DateFormat('h:mm a').format(e.endTime!)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.secondary)),
          const SizedBox(height: 8),
          Text(e.current(hi),
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
          if (endTxt != null)
            Text(endTxt,
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
          if (e.next != null) ...[
            const SizedBox(height: 8),
            Text(e.next!(hi),
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: scheme.onSurface.withValues(alpha: 0.75))),
            Text(hi ? 'शेष दिन' : 'Rest of the day',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }
}

class _Time extends StatelessWidget {
  final String label;
  final DateTime? time;
  const _Time({required this.label, required this.time});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Text(time == null ? '—' : DateFormat('h:mm a').format(time!),
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: scheme.primary)),
        ],
      ),
    );
  }
}
