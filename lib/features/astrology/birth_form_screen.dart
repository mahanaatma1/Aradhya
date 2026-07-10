import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/widgets/skeleton.dart';
import 'astrology_providers.dart';
import 'date_input.dart';

/// Birth-detail entry — name, date, time, place — then generates the kundli.
class BirthFormScreen extends ConsumerStatefulWidget {
  /// Where to go after submit ('/astrology/kundli' or '/astrology/milan/...').
  final String nextRoute;
  final String title;
  const BirthFormScreen({
    super.key,
    this.nextRoute = '/astrology/kundli',
    this.title = 'Birth Details',
  });

  @override
  ConsumerState<BirthFormScreen> createState() => _BirthFormScreenState();
}

class _BirthFormScreenState extends ConsumerState<BirthFormScreen> {
  final _name = TextEditingController();
  final _dateText = TextEditingController();
  final _timeText = TextEditingController();
  City? _city;

  @override
  void initState() {
    super.initState();
    // Pre-fill when editing an existing chart.
    final b = ref.read(birthDetailsProvider);
    if (b != null) {
      _name.text = b.name;
      _dateText.text = DateFormat('dd-MM-yyyy').format(b.dob);
      _timeText.text = DateFormat('HH:mm').format(b.dob);
      _city = City(b.place, '', b.lat, b.lon, b.utcOffset);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dateText.dispose();
    _timeText.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CityPickerSheet(),
    );
    if (picked != null) setState(() => _city = picked);
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _city != null &&
      parseBirthDate(_dateText.text) != null &&
      parseBirthTime(_timeText.text) != null;

  void _submit() {
    final c = _city!;
    final date = parseBirthDate(_dateText.text)!;
    final (h, m) = parseBirthTime(_timeText.text)!;
    final details = BirthDetails(
      name: _name.text.trim(),
      dob: DateTime(date.year, date.month, date.day, h, m),
      lat: c.lat,
      lon: c.lon,
      utcOffset: c.utcOffset,
      place: c.label,
    );
    ref.read(birthDetailsProvider.notifier).state = details;
    // Persist so the Kundli/personalized Rashifal survives an app restart.
    ref
        .read(sharedPrefsProvider)
        .setString(PrefKeys.birthDetails, jsonEncode(details.toJson()));
    context.push(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hi = ref.watch(isHindiProvider);
    final appBarTitle =
        (hi && widget.title == 'Birth Details') ? 'जन्म विवरण' : widget.title;

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label(hi ? 'नाम' : 'Name'),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: _dec(scheme, hi ? 'पूरा नाम' : 'Full name'),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(hi ? 'जन्म तिथि' : 'Date of birth'),
                    TextField(
                      controller: _dateText,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [dateMask],
                      onChanged: (_) => setState(() {}),
                      decoration: _dec(scheme, 'DD-MM-YYYY').copyWith(
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        errorText: dateErrorText(_dateText.text, hi),
                        prefixIcon: Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 34, minHeight: 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(hi ? 'जन्म समय' : 'Time of birth'),
                    TextField(
                      controller: _timeText,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [timeMask],
                      onChanged: (_) => setState(() {}),
                      decoration: _dec(scheme, 'HH:MM').copyWith(
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        errorText: timeErrorText(_timeText.text, hi),
                        prefixIcon: Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 34, minHeight: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              hi
                  ? '24-घंटे के प्रारूप में समय दर्ज करें, जैसे 04:52 या 18:30।'
                  : 'Use 24-hour time, e.g. 04:52 or 18:30.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          _label(hi ? 'जन्म स्थान' : 'Place of birth'),
          _PickerTile(
            icon: Icons.place_rounded,
            text: _city?.label ?? (hi ? 'शहर चुनें…' : 'Select city…'),
            onTap: _pickCity,
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _valid ? _submit : null,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(hi ? 'कुंडली बनाएं' : 'Generate Kundli'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              hi
                  ? 'गणना लाहिड़ी अयनांश (वैदिक / निरयण) पर आधारित है।'
                  : 'Calculations use Lahiri ayanamsa (Vedic / sidereal).',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 6),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );

  InputDecoration _dec(ColorScheme scheme, String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: scheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
    ),
  );
}

/// Bottom sheet to search & pick a birth city from the bundled 4276-city list.
class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet();
  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hi = ref.watch(isHindiProvider);
    final results = _query.trim().length >= 2
        ? ref.watch(citySearchProvider(_query.trim()))
        : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hi ? 'जन्म स्थान' : 'Place of birth',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: hi ? 'शहर खोजें…' : 'Search city…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: results == null
                ? Center(
                    child: Text(
                      hi ? 'कम से कम 2 अक्षर लिखें' : 'Type at least 2 letters',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : results.when(
                    loading: () => const SkeletonList(
                        count: 5,
                        padding: EdgeInsets.symmetric(vertical: 8)),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (cities) => ListView(
                      children: [
                        for (final c in cities)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(c.name),
                            subtitle: Text(c.state),
                            onTap: () => Navigator.pop(context, c),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontFamily: AppFonts.body, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
