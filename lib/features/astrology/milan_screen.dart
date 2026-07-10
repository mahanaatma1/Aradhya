import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../app/theme/app_theme.dart';
import 'ashtakoot.dart';
import 'astro_chart.dart';
import 'astrology_providers.dart';
import 'city_picker.dart';
import 'date_input.dart';

/// Kundli Milan — Step 1: enter both people's birth details, then compute the
/// Ashtakoot Guna Milan and open the result screen.
class MilanScreen extends ConsumerStatefulWidget {
  const MilanScreen({super.key});
  @override
  ConsumerState<MilanScreen> createState() => _MilanScreenState();
}

class _SideInput {
  final name = TextEditingController();
  final dateText = TextEditingController();
  final timeText = TextEditingController();
  City? city;
  DateTime? get date => parseBirthDate(dateText.text);
  (int, int)? get time => parseBirthTime(timeText.text);
  bool get valid =>
      name.text.trim().isNotEmpty &&
      city != null &&
      date != null &&
      time != null;
  void dispose() {
    name.dispose();
    dateText.dispose();
    timeText.dispose();
  }
}

class _MilanScreenState extends ConsumerState<MilanScreen> {
  late bool _useMine;
  final _side1 = _SideInput();
  final _side2 = _SideInput();

  @override
  void initState() {
    super.initState();
    _useMine = ref.read(birthDetailsProvider) != null;
  }

  @override
  void dispose() {
    _side1.dispose();
    _side2.dispose();
    super.dispose();
  }

  bool get _valid {
    final side1ok = _useMine
        ? ref.read(birthDetailsProvider) != null
        : _side1.valid;
    return side1ok && _side2.valid;
  }

  BirthChart _chartFrom(_SideInput s) {
    final c = s.city!;
    final d = s.date!;
    final (h, m) = s.time!;
    final local = DateTime(d.year, d.month, d.day, h, m);
    final utc = local.subtract(Duration(minutes: (c.utcOffset * 60).round()));
    return computeChart(utc, c.lat, c.lon);
  }

  void _submit() {
    final b = ref.read(birthDetailsProvider);
    late final String nameA;
    late final BirthChart chartA;
    if (_useMine && b != null) {
      nameA = b.name;
      chartA = computeChart(b.utc, b.lat, b.lon);
    } else {
      nameA = _side1.name.text.trim();
      chartA = _chartFrom(_side1);
    }
    final result =
        computeMilan(nameA, chartA, _side2.name.text.trim(), _chartFrom(_side2));
    context.push('/astrology/milan/result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = ref.watch(birthDetailsProvider);
    final hi = ref.watch(isHindiProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(hi ? 'कुंडली मिलान' : 'KUNDLI MILAN',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 6),
          Text(hi ? 'अनुकूलता परीक्षण' : 'Compatibility Test',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  color: scheme.onSurface)),
          const SizedBox(height: 10),
          Text(
            hi
                ? 'अष्टकूट गुण मिलान — पारंपरिक 36-गुण वैदिक परीक्षण।'
                : 'Ashtakoot Guna Milan — the traditional 36-point Vedic test.',
            style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 22),

          // Use-my-kundli toggle (only if a chart exists).
          if (mine != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        hi
                            ? 'पक्ष 1 के लिए मेरी कुंडली लें'
                            : 'Use my Kundli for Side 1',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                  ),
                  Switch(
                    value: _useMine,
                    onChanged: (v) => setState(() => _useMine = v),
                  ),
                ],
              ),
            ),
          if (mine != null) const SizedBox(height: 16),

          // Side 1
          _SideCard(
            label: hi ? 'पक्ष 1' : 'Side 1',
            hi: hi,
            accent: scheme.primary,
            fromKundli: _useMine && mine != null,
            mine: mine,
            input: _side1,
            onChanged: () => setState(() {}),
            onPickCity: () async {
              final c = await pickBirthCity(context);
              if (c != null) setState(() => _side1.city = c);
            },
          ),

          // Heart divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                    child: Divider(
                        color: scheme.outline.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.favorite_border_rounded,
                      color: scheme.primary, size: 22),
                ),
                Expanded(
                    child: Divider(
                        color: scheme.outline.withValues(alpha: 0.3))),
              ],
            ),
          ),

          // Side 2
          _SideCard(
            label: hi ? 'पक्ष 2' : 'Side 2',
            hi: hi,
            accent: scheme.primary,
            fromKundli: false,
            mine: null,
            input: _side2,
            onChanged: () => setState(() {}),
            onPickCity: () async {
              final c = await pickBirthCity(context);
              if (c != null) setState(() => _side2.city = c);
            },
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _valid ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(hi ? 'अनुकूलता जांचें' : 'Check Compatibility',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
                hi
                    ? 'दोनों व्यक्तियों का सही जन्म समय आवश्यक है।'
                    : 'Accurate birth time is required for both people.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

}

class _SideCard extends StatelessWidget {
  final String label;
  final bool hi;
  final Color accent;
  final bool fromKundli;
  final BirthDetails? mine;
  final _SideInput input;
  final VoidCallback onChanged;
  final VoidCallback onPickCity;

  const _SideCard({
    required this.label,
    required this.hi,
    required this.accent,
    required this.fromKundli,
    required this.mine,
    required this.input,
    required this.onChanged,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: scheme.onSurface)),
              const Spacer(),
              if (fromKundli)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(hi ? 'आपकी कुंडली से' : 'From your Kundli',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (fromKundli && mine != null)
            _readonly(context, mine!)
          else
            _editable(context),
        ],
      ),
    );
  }

  Widget _readonly(BuildContext context, BirthDetails b) {
    return Column(
      children: [
        _filled(context, b.name),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _filled(context, DateFormat('dd-MM-yyyy').format(b.dob))),
            const SizedBox(width: 10),
            Expanded(child: _filled(context, DateFormat('HH:mm').format(b.dob))),
          ],
        ),
        const SizedBox(height: 10),
        _filled(context, b.place,
            sub:
                '${b.lat.toStringAsFixed(2)}°, ${b.lon.toStringAsFixed(2)}° · UTC${b.utcOffset >= 0 ? '+' : ''}${_off(b.utcOffset)}'),
      ],
    );
  }

  Widget _editable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          controller: input.name,
          onChanged: (_) => onChanged(),
          decoration: _dec(scheme, hi ? 'पूरा नाम' : 'Full name'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: input.dateText,
                keyboardType: TextInputType.number,
                inputFormatters: const [dateMask],
                onChanged: (_) => onChanged(),
                decoration: _dec(scheme, 'DD-MM-YYYY').copyWith(
                    hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.4)),
                    errorText: dateErrorText(input.dateText.text, hi),
                    prefixIcon: Icon(Icons.calendar_today_rounded,
                        size: 17, color: accent),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 34, minHeight: 0)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: input.timeText,
                keyboardType: TextInputType.number,
                inputFormatters: const [timeMask],
                onChanged: (_) => onChanged(),
                decoration: _dec(scheme, 'HH:MM').copyWith(
                    hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.4)),
                    errorText: timeErrorText(input.timeText.text, hi),
                    prefixIcon: Icon(Icons.access_time_rounded,
                        size: 17, color: accent),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 34, minHeight: 0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
            hi
                ? 'समय 24-घंटे के प्रारूप में (जैसे 18:30)।'
                : 'Time in 24-hour format (e.g. 18:30).',
            style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 10),
        _tile(context, Icons.place_rounded,
            input.city?.label ?? (hi ? 'शहर चुनें…' : 'Select city…'),
            onPickCity),
      ],
    );
  }

  Widget _filled(BuildContext context, String text, {String? sub}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ],
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String text, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(ColorScheme scheme, String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      );

  String _off(double h) {
    final m = (h.abs() * 60).round();
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }
}
