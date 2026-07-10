import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../panchang/panchang_names.dart' show nakshatraNames;
import 'astro_chart.dart';
import 'sweph_ephemeris.dart';
import 'astrology_data.dart';
import 'astrology_providers.dart';
import 'charts.dart';
import 'interpretations.dart';
import 'life_areas.dart';
import 'soul_profile.dart';
import 'vimshottari.dart';
import 'yogas_doshas.dart';

class KundliScreen extends ConsumerStatefulWidget {
  const KundliScreen({super.key});
  @override
  ConsumerState<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends ConsumerState<KundliScreen> {
  bool _south = false;
  bool _navamsa = false;

  @override
  Widget build(BuildContext context) {
    final birth = ref.watch(birthDetailsProvider);
    final chart = ref.watch(chartProvider);
    final hi = ref.watch(isHindiProvider);

    if (birth == null || chart == null) {
      return Scaffold(
        appBar: AppBar(title: Text(hi ? 'कुंडली' : 'Kundli')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.pushReplacement('/astrology'),
            child: Text(hi ? 'जन्म विवरण दर्ज करें' : 'Enter birth details'),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(birth.name, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => context.pushReplacement('/astrology'),
              child: Text(hi ? 'संपादित करें' : 'Edit'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: hi ? 'कुंडली' : 'Chart'),
              Tab(text: hi ? 'आत्म परिचय' : 'Soul Profile'),
              Tab(text: hi ? 'दशा' : 'Dasha'),
              Tab(text: hi ? 'योग व दोष' : 'Yogas & Doshas'),
              Tab(text: hi ? 'जीवन क्षेत्र' : 'Life Areas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChartTab(
              chart: chart,
              birth: birth,
              hi: hi,
              south: _south,
              navamsa: _navamsa,
              onSouth: (v) => setState(() => _south = v),
              onNavamsa: (v) => setState(() => _navamsa = v),
            ),
            _SoulTab(chart: chart, birth: birth, hi: hi),
            _DashaTab(chart: chart, birth: birth, hi: hi),
            _YogasTab(chart: chart, hi: hi),
            _LifeAreasTab(chart: chart, birth: birth, hi: hi),
          ],
        ),
      ),
    );
  }
}

// ---------------- shared bits ----------------

class _Reading extends StatelessWidget {
  final String label;
  final String value;
  final String body;
  final Color? accent;
  final String? badge;
  const _Reading(
      {required this.label,
      required this.value,
      required this.body,
      this.accent,
      this.badge});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = accent ?? scheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: c)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(badge!,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c)),
                ),
            ],
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 19)),
          ],
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
      ),
    );
  }
}

// ---------------- Chart tab ----------------

class _ChartTab extends StatelessWidget {
  final BirthChart chart;
  final BirthDetails birth;
  final bool hi;
  final bool south, navamsa;
  final ValueChanged<bool> onSouth, onNavamsa;
  const _ChartTab({
    required this.chart,
    required this.birth,
    required this.hi,
    required this.south,
    required this.navamsa,
    required this.onSouth,
    required this.onNavamsa,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moon = chart.byKey('moon');
    final view = navamsa ? chart.navamsaView : chart.rashiView;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${DateFormat('d MMM yyyy · HH:mm').format(birth.dob)} · ${birth.place}',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 14),
        Center(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: false,
                  label: Text(hi ? 'उत्तर भारतीय' : 'North Indian')),
              ButtonSegment(
                  value: true,
                  label: Text(hi ? 'दक्षिण भारतीय' : 'South Indian')),
            ],
            selected: {south},
            onSelectionChanged: (s) => onSouth(s.first),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: south
              ? SouthIndianChart(view: view)
              : NorthIndianChart(view: view),
        ),
        const SizedBox(height: 14),
        Center(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: false, label: Text(hi ? 'राशि · D1' : 'Rashi · D1')),
              ButtonSegment(
                  value: true,
                  label: Text(hi ? 'नवांश · D9' : 'Navamsa · D9')),
            ],
            selected: {navamsa},
            onSelectionChanged: (s) => onNavamsa(s.first),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _summary(context, hi ? 'लग्न' : 'Lagna',
                signNames[chart.lagnaRashi](hi), degMinSec(chart.lagnaDegInSign)),
            _summary(context, hi ? 'चंद्र राशि' : 'Moon Sign',
                signNames[moon.graha.rashi](hi), degMinSec(moon.graha.degInSign)),
            _summary(context, hi ? 'नक्षत्र' : 'Nakshatra',
                nakshatraNames[moon.graha.nakshatra](hi),
                '${hi ? 'पाद' : 'Pada'} ${moon.graha.nakPada}'),
          ],
        ),
        const SizedBox(height: 18),
        _PlanetTable(chart: chart, hi: hi),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                  '${hi ? 'अयनांश' : 'Ayanamsa'}: ${chart.ayanamsaDeg.toStringAsFixed(4)}° (${hi ? 'लाहिड़ी' : 'Lahiri'})',
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.55))),
              Text(
                  swephReady
                      ? (hi ? 'स्विस एफेमेरिस' : 'Swiss Ephemeris')
                      : (hi ? 'अंतर्निहित अनुमान' : 'Built-in approximation'),
                  style: TextStyle(
                      fontSize: 11,
                      color: (swephReady
                              ? AppColors.sacredGreen
                              : scheme.onSurface)
                          .withValues(alpha: 0.5))),
              if (!swephReady && swephError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('sweph: $swephError',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          color: scheme.error.withValues(alpha: 0.7))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context, String label, String value, String sub) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: scheme.secondary)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

class _PlanetTable extends StatelessWidget {
  final BirthChart chart;
  final bool hi;
  const _PlanetTable({required this.chart, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'ग्रह स्थिति' : 'Planetary Positions',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: scheme.primary)),
          const SizedBox(height: 6),
          for (final key in planetOrder) _row(context, chart.byKey(key)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PlacedGraha p) {
    final scheme = Theme.of(context).colorScheme;
    final g = p.graha;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text('${planetInfo[g.key]!.name(hi)}${g.retrograde ? ' ˚' : ''}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${signNames[g.rashi](hi)} ${degMinSec(g.degInSign)}',
                    style: const TextStyle(fontSize: 14)),
                Text('${hi ? 'भाव' : 'House'} ${p.house} · ${nakshatraNames[g.nakshatra](hi)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Soul Profile tab ----------------

class _SoulTab extends StatelessWidget {
  final BirthChart chart;
  final BirthDetails birth;
  final bool hi;
  const _SoulTab({required this.chart, required this.birth, required this.hi});

  String _p(String key) => planetInfo[key]!.name(hi);
  static const _rose = Color(0xFF9C2950);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = computeSoulProfile(chart, birth);
    final ak = chart.byKey(s.atmakaraka).graha;
    final dk = chart.byKey(s.darakaraka).graha;
    final moon = chart.byKey('moon').graha.rashi;
    final sun = chart.byKey('sun').graha.rashi;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Ishta Devata ----
        _bordered(
          context,
          borderColor: scheme.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hi ? 'इष्ट देवता' : 'ISHTA DEVATA',
                  style: TextStyle(
                      color: scheme.primary,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(s.ishtaDevata,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 23,
                      height: 1.15)),
              if (s.ishtaMantra.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(s.ishtaMantra,
                    style: TextStyle(
                        fontFamily: AppFonts.devanagari,
                        fontSize: 17,
                        color: scheme.primary)),
              ],
              const SizedBox(height: 14),
              _karakaBox(context, [
                (hi ? 'आत्मकारक' : 'Atmakaraka',
                    '${_p(s.atmakaraka)} · ${signNames[ak.rashi](hi)} ${degMinSec(ak.degInSign)}'),
                (hi ? 'कारकांश लग्न (D9)' : 'Karakamsa Lagna (D9)',
                    signNames[s.karakamsaSign](hi)),
                (hi ? 'कारकांश से 12वां' : '12th from Karakamsa',
                    signNames[s.ishtaSign](hi)),
                (hi ? 'इष्ट ग्रह (स्वामी)' : 'Ishta planet (lord)',
                    s.ishtaPlanets.isEmpty ? '—' : s.ishtaPlanets.map(_p).join(', ')),
              ]),
              const SizedBox(height: 12),
              Text(
                hi
                    ? 'आपका आत्मकारक ${_p(s.atmakaraka)} है — कुंडली में सर्वोच्च अंश वाला ग्रह। इसकी नवांश राशि कारकांश लग्न निर्धारित करती है; वहां से 12वीं राशि आत्मा के चुने हुए इष्ट देव को दर्शाती है।'
                    : 'Your Atmakaraka is ${_p(s.atmakaraka)}, the planet at the highest degree in your chart. Its navamsa sign sets the Karakamsa Lagna; the 12th sign from there reveals the soul\'s chosen deity.',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        // Atmakaraka detailed reading (our depth layer)
        _Reading(
            label: hi
                ? 'आत्मकारक · ${signNames[ak.rashi](hi)} में ${_p(s.atmakaraka)}'
                : 'Atmakaraka · ${_p(s.atmakaraka)} in ${signNames[ak.rashi](hi)}',
            value: hi ? 'आत्मा का कारक' : 'The Soul\'s Significator',
            accent: scheme.secondary,
            body:
                '${(hi ? atmakarakaByPlanetHi : atmakarakaByPlanet)[s.atmakaraka] ?? ''}\n\n${(hi ? atmakarakaBySignHi : atmakarakaBySign)[ak.rashi]}'),

        // ---- Darakaraka ----
        _bordered(
          context,
          borderColor: _rose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hi ? 'दाराकारक' : 'DARAKARAKA',
                  style: TextStyle(
                      color: _rose,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                hi
                    ? 'जीवनसाथी कारक — सबसे कम अंश वाला ग्रह, जो जीवनसाथी के स्वरूप को दर्शाता है।'
                    : 'Spouse karaka — the planet at the lowest degree, revealing the partner archetype.',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
              _karakaBox(context, [
                (hi ? 'दाराकारक' : 'Darakaraka', _p(s.darakaraka)),
                (hi ? 'स्थिति' : 'Position',
                    '${signNames[dk.rashi](hi)} ${degMinSec(dk.degInSign)}'),
              ]),
              const SizedBox(height: 12),
              Text(
                '${(hi ? darakarakaByPlanetHi : darakarakaByPlanet)[s.darakaraka] ?? ''}\n\n${(hi ? darakarakaBySignHi : darakarakaBySign)[dk.rashi]}',
                style: const TextStyle(fontSize: 14.5, height: 1.5),
              ),
            ],
          ),
        ),

        // ---- Lucky + Numerology tiles (2-column) ----
        _pair(
            _tile(context, hi ? 'भाग्यशाली रत्न' : 'Lucky Stone',
                hi ? s.luckyGemHi : s.luckyGem),
            _tile(context, hi ? 'भाग्यशाली रंग' : 'Lucky Colour',
                hi ? s.luckyColorHi : s.luckyColor)),
        _pair(
            _tile(context, hi ? 'भाग्यशाली दिन' : 'Lucky Day',
                hi ? s.luckyDayHi : s.luckyDay),
            _tile(context, hi ? 'भाग्यशाली धातु' : 'Lucky Metal',
                hi ? s.luckyMetalHi : s.luckyMetal)),
        _pair(_tile(context, hi ? 'मूलांक' : 'Mulank', '${s.mulank}', big: true),
            _tile(context, hi ? 'भाग्यांक' : 'Destiny Number', '${s.bhagyank}',
                big: true)),
        _pair(
            _tile(context, hi ? 'नामांक' : 'Name Number',
                s.nameNumber == 0 ? '—' : '${s.nameNumber}',
                big: true),
            _tile(context, hi ? 'शुभ वर्ष' : 'Good Years', s.goodYears.join(', '))),
        _pair(
            _tile(context, hi ? 'शुभ ग्रह' : 'Good Planets',
                s.goodPlanets.isEmpty ? '—' : s.goodPlanets.map(_p).join(', ')),
            _tile(context, hi ? 'मित्र राशियाँ' : 'Friendly Signs',
                s.friendlySigns.map((i) => signNames[i](hi)).join(', '))),
        _tile(context, hi ? 'शुभ लग्न' : 'Good Lagna',
            s.goodLagnaSigns.map((i) => signNames[i](hi)).join(', ')),
        const SizedBox(height: 10),
        if (s.luckMantra.isNotEmpty)
          _tile(context, hi ? 'भाग्य मंत्र (नवग्रह)' : 'Lucky Mantra (Navagraha)',
              s.luckMantra,
              devanagari: true),

        const SizedBox(height: 6),
        _Reading(
            label: hi
                ? 'लग्न · ${signNames[chart.lagnaRashi](hi)} उदित'
                : 'Lagna · ${signNames[chart.lagnaRashi](hi)} rising',
            value: hi ? 'आपका मूल स्वरूप' : 'Your Core Self',
            body: (hi ? soulByLagnaHi : soulByLagna)[chart.lagnaRashi]),
        _Reading(
            label: '${hi ? 'सूर्य' : 'Sun'} · ${signNames[sun](hi)}',
            value: hi ? 'आपकी जीवनी शक्ति' : 'Your Vital Essence',
            body: (hi ? soulBySunHi : soulBySun)[sun]),
        _Reading(
            label: '${hi ? 'चंद्र' : 'Moon'} · ${signNames[moon](hi)}',
            value: hi ? 'आपका अंतर्जगत' : 'Your Inner World',
            body: (hi ? soulByMoonHi : soulByMoon)[moon]),
      ],
    );
  }

  Widget _bordered(BuildContext context,
      {required Color borderColor, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _karakaBox(BuildContext context, List<(String, String)> rows) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: scheme.outline.withValues(alpha: 0.15)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].$1,
                        style: TextStyle(
                            fontSize: 13.5,
                            color: scheme.onSurface.withValues(alpha: 0.65))),
                  ),
                  Text(rows[i].$2,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 10),
              Expanded(child: b),
            ],
          ),
        ),
      );

  Widget _tile(BuildContext context, String label, String value,
      {bool big = false, bool devanagari = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          const SizedBox(height: 6),
          Text(value,
              style: big
                  ? TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      color: scheme.primary)
                  : TextStyle(
                      fontFamily: devanagari ? AppFonts.devanagari : AppFonts.body,
                      fontWeight: FontWeight.w600,
                      fontSize: devanagari ? 17 : 15,
                      height: devanagari ? 1.5 : 1.3)),
        ],
      ),
    );
  }
}

// ---------------- Dasha tab ----------------

class _DashaTab extends StatelessWidget {
  final BirthChart chart;
  final BirthDetails birth;
  final bool hi;
  const _DashaTab({required this.chart, required this.birth, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moonSid = chart.byKey('moon').graha.sidereal;
    final cd = currentDasha(birth.utc, moonSid, DateTime.now());
    final f = DateFormat('d MMM yyyy');

    Widget level(String label, DashaPeriod p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
              Text(planetInfo[p.lord]!.name(hi),
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 22)),
              Text('${f.format(p.start)}  →  ${f.format(p.end)}',
                  style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        );

    final lord = cd.maha.lord;
    final areas = (hi ? lifeAreaByLordHi : lifeAreaByLord)[lord] ?? const [];
    final now = DateTime.now();
    final antars = antarDashas(cd.maha);
    final mahas = mahaDashas(birth.utc, moonSid).take(9).toList();
    const good = Color(0xFF2E7D4F);
    const bad = Color(0xFFB4462F);

    String pName(String k) => planetInfo[k]!.name(hi);
    String dur(DashaPeriod p) {
      final days = p.days;
      if (days >= 364) {
        final y = days / 365.25;
        return (y - y.roundToDouble()).abs() < 0.08
            ? '${y.round()} ${hi ? 'वर्ष' : 'yr'}'
            : '${y.toStringAsFixed(1)} ${hi ? 'वर्ष' : 'yr'}';
      }
      return '${(days / 30.44).toStringAsFixed(1)} ${hi ? 'माह' : 'mo'}';
    }

    final white = Color.alphaBlend(
        Colors.white.withValues(
            alpha: Theme.of(context).brightness == Brightness.light ? 1 : 0.06),
        scheme.surface);
    Widget sub(String label, String body, Color color, {bool tint = true}) =>
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tint ? color.withValues(alpha: 0.06) : white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: tint ? 0.3 : 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        );

    Widget periodRow(DashaPeriod p) {
      final current = now.isAfter(p.start) && now.isBefore(p.end);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: current
              ? scheme.secondary.withValues(alpha: 0.14)
              : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: current
                  ? scheme.secondary.withValues(alpha: 0.5)
                  : scheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pName(p.lord),
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w600,
                          fontSize: 17)),
                  Text('${f.format(p.start)} → ${f.format(p.end)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Text(dur(p),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: current ? scheme.primary : scheme.secondary)),
          ],
        ),
      );
    }

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(t,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: scheme.primary)),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(hi ? 'वर्तमान विंशोत्तरी दशा' : 'Current Vimshottari Dasha',
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: scheme.primary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              level(hi ? 'महादशा' : 'Maha Dasha', cd.maha),
              Divider(color: scheme.outline.withValues(alpha: 0.15)),
              level(hi ? 'अंतर्दशा' : 'Antar Dasha', cd.antar),
              Divider(color: scheme.outline.withValues(alpha: 0.15)),
              level(hi ? 'प्रत्यंतर दशा' : 'Pratyantar Dasha', cd.pratyantar),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: scheme.secondary.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  hi
                      ? 'यह ${pName(lord)} काल आपसे क्या चाहता है'
                      : 'What this ${pName(lord)} period asks of you',
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: scheme.primary)),
              const SizedBox(height: 8),
              Text((hi ? dashaByLordHi : dashaByLord)[lord] ?? '',
                  style: const TextStyle(fontSize: 14.5, height: 1.55)),
              if ((hi ? dashaFlavorByLordHi : dashaFlavorByLord)[lord] !=
                  null) ...[
                const SizedBox(height: 10),
                Text((hi ? dashaFlavorByLordHi : dashaFlavorByLord)[lord]!,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
              const SizedBox(height: 14),
              if (areas.length >= 4) ...[
                sub(hi ? 'करियर' : 'Career', areas[0], scheme.primary,
                    tint: false),
                sub(hi ? 'संबंध' : 'Relationships', areas[1], scheme.primary,
                    tint: false),
                sub(hi ? 'स्वास्थ्य' : 'Health', areas[2], scheme.primary,
                    tint: false),
                sub(hi ? 'धन' : 'Money', areas[3], scheme.primary, tint: false),
              ],
              sub(hi ? 'क्या करें' : 'What to do',
                  (hi ? dashaDoByLordHi : dashaDoByLord)[lord] ?? '', good),
              sub(hi ? 'किससे बचें' : 'What to avoid',
                  (hi ? dashaAvoidByLordHi : dashaAvoidByLord)[lord] ?? '', bad),
            ],
          ),
        ),
        const SizedBox(height: 16),
        heading(hi
            ? '${pName(lord)} महादशा में अंतर्दशाएँ'
            : 'Antar Dashas in ${pName(lord)} Maha'),
        for (final a in antars) periodRow(a),
        const SizedBox(height: 10),
        heading(hi ? 'संपूर्ण 120-वर्षीय दशा चक्र' : 'Full 120-Year Dasha Cycle'),
        for (final m in mahas) periodRow(m),
      ],
    );
  }
}

// ---------------- Yogas & Doshas tab ----------------

class _YogasTab extends StatefulWidget {
  final BirthChart chart;
  final bool hi;
  const _YogasTab({required this.chart, required this.hi});
  @override
  State<_YogasTab> createState() => _YogasTabState();
}

class _YogasTabState extends State<_YogasTab> {
  bool _learn = false;
  static const _good = Color(0xFF2E7D4F);
  static const _bad = Color(0xFFB4462F);

  static const _rajaFamily = {'raja', 'dhana', 'neechabhanga', 'vipreet'};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final yogas = detectYogas(widget.chart);
    final doshas = detectDoshas(widget.chart);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _toggle(scheme),
        const SizedBox(height: 16),
        if (_learn)
          ..._learnMore(scheme)
        else
          ..._yourChart(scheme, yogas, doshas),
      ],
    );
  }

  Widget _toggle(ColorScheme scheme) {
    Widget pill(String label, bool active, VoidCallback onTap) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? scheme.onPrimary
                            : scheme.onSurface.withValues(alpha: 0.7))),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        pill(widget.hi ? 'आपकी कुंडली' : 'Your Chart', !_learn,
            () => setState(() => _learn = false)),
        pill(widget.hi ? 'और जानें' : 'Learn More', _learn,
            () => setState(() => _learn = true)),
      ]),
    );
  }

  List<Widget> _yourChart(
      ColorScheme scheme, List<DetectedYoga> yogas, List<DetectedDosha> doshas) {
    return [
      Text(
          widget.hi
              ? 'शुभ योग (${yogas.length})'
              : 'Auspicious Yogas (${yogas.length})',
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _good)),
      const SizedBox(height: 10),
      if (yogas.isEmpty)
        Text(
            widget.hi
                ? 'इस कुंडली में कोई प्रमुख योग नहीं मिला।'
                : 'No major yogas detected in this chart.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
      for (final y in yogas)
        _Reading(
            label: yogaTitle(y.type, widget.hi),
            value: '',
            body: yogaReading(y.type, widget.hi),
            accent: _good,
            badge: _rajaFamily.contains(y.type)
                ? (widget.hi ? 'राज' : 'RAJA')
                : null),
      const SizedBox(height: 8),
      Text(widget.hi ? 'दोष (${doshas.length})' : 'Doshas (${doshas.length})',
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _bad)),
      const SizedBox(height: 10),
      if (doshas.isEmpty)
        Text(
            widget.hi
                ? 'कोई महत्वपूर्ण दोष नहीं मिला।'
                : 'No significant doshas detected.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6))),
      for (final d in doshas) _doshaCard(scheme, d),
    ];
  }

  Widget _doshaCard(ColorScheme scheme, DetectedDosha d) {
    final white = Color.alphaBlend(
        Colors.white.withValues(
            alpha: Theme.of(context).brightness == Brightness.light ? 1 : 0.06),
        scheme.surface);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bad.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bad.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(doshaTitle(d.type, widget.hi),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _bad)),
              ),
              if (d.severity.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _bad.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(severityLabel(d.severity, widget.hi),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _bad)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(doshaReading(d.type, d.severity, widget.hi),
              style: const TextStyle(fontSize: 14.5, height: 1.5)),
          if (d.softening.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
                widget.hi
                    ? 'आपकी कुंडली में शमन कारक:'
                    : 'Softening factors in your chart:',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            for (final f in d.softening)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('•  $f',
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
              ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hi ? 'उपाय' : 'REMEDY',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: _bad)),
                const SizedBox(height: 6),
                Text(doshaRemedy(d.type, widget.hi),
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _learnMore(ColorScheme scheme) {
    Widget item(String title, String desc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        );
    return [
      Text(
          widget.hi
              ? 'वैदिक ज्योतिष में अनेक योग और दोष माने जाते हैं। नीचे प्रमुख योग-दोष दिए गए हैं — चाहे वे आपकी कुंडली में हों या न हों, यहाँ प्रत्येक का अर्थ बताया गया है।'
              : 'Vedic astrology recognises many yogas and doshas. Below are the major ones — whether they appear in your chart or not, this is what each one means.',
          style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.65))),
      const SizedBox(height: 16),
      Text(widget.hi ? 'प्रमुख योग' : 'Major Yogas',
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _good)),
      const SizedBox(height: 10),
      for (final y in (widget.hi ? learnMoreYogasHi : learnMoreYogas))
        item(y.$1, y.$2),
      const SizedBox(height: 8),
      Text(widget.hi ? 'प्रमुख दोष' : 'Major Doshas',
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _bad)),
      const SizedBox(height: 10),
      for (final d in (widget.hi ? learnMoreDoshasHi : learnMoreDoshas))
        item(d.$1, d.$2),
    ];
  }
}

// ---------------- Life Areas tab ----------------

class _LifeAreasTab extends StatelessWidget {
  final BirthChart chart;
  final BirthDetails birth;
  final bool hi;
  const _LifeAreasTab(
      {required this.chart, required this.birth, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final areas = computeLifeAreas(chart, hi);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(hi ? 'आपका जीवन, भाव दर भाव' : 'Your Life, House by House',
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: scheme.primary)),
        const SizedBox(height: 4),
        Text(
          hi
              ? 'प्रत्येक क्षेत्र उसके भाव पर स्थित राशि, उस भाव के स्वामी की स्थिति और उसमें बैठे ग्रहों के आधार पर पढ़ा जाता है।'
              : 'Each area is read from the sign on its house (bhava), the placement '
                  'of that house\'s ruler, and any planets sitting in it.',
          style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 18),
        for (final a in areas) ...[
          _areaHeader(context, a),
          for (final asp in a.aspects)
            _Reading(label: asp.label, value: '', body: asp.body),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _areaHeader(BuildContext context, LifeArea a) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: scheme.primary)),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 22,
                height: 2,
                margin: const EdgeInsets.only(right: 8),
                color: scheme.secondary.withValues(alpha: 0.6),
              ),
              Text(a.subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ],
      ),
    );
  }
}
