import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/brand.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/currency_icons.dart';
import '../../shared/share_card.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/stitched_border.dart';
import '../astrology/astrology_data.dart' show planetInfo, signNames;
import '../astrology/astrology_providers.dart';
import '../panchang/panchang_engine.dart' show Muhurat;
import '../panchang/panchang_names.dart' show NamePair;
import 'cosmos_content.dart';
import 'cosmos_providers.dart';
import 'daily_cosmos.dart';
import 'rashi_glyphs.dart';

/// Kamal cost to reveal the next auspicious day.
const _revealCost = 5;

/// "Rashifal" — a personalized daily astrology reading from the user's real
/// chart + today's transits + panchang. Fully bilingual (EN/हिं).
class CosmosScreen extends ConsumerStatefulWidget {
  const CosmosScreen({super.key});

  @override
  ConsumerState<CosmosScreen> createState() => _CosmosScreenState();
}

class _CosmosScreenState extends ConsumerState<CosmosScreen> {
  DateTime? _revealed;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final cosmos = ref.watch(cosmosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'राशिफल' : 'Rashifal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: hi ? 'साझा करें' : 'Share',
            onPressed: () => _shareRashi(hi),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // Classic 12-Rashi daily horoscope — works with no birth details.
          const _RashiHoroscope(),
          const SizedBox(height: 22),
          _SectionHeader(
              hi ? 'आपका व्यक्तिगत राशिफल' : 'Your personalized reading'),
          if (cosmos != null) ...[
            _WeatherCard(cosmos: cosmos, hi: hi),
            const SizedBox(height: 12),
            _DashaCard(cosmos: cosmos, hi: hi),
            const SizedBox(height: 12),
            _GocharCard(cosmos: cosmos, hi: hi),
            const SizedBox(height: 12),
            if (cosmos.sadeSati != null) ...[
              _AlertCard(severity: cosmos.sadeSati!, hi: hi),
              const SizedBox(height: 12),
            ],
            _HoursCard(cosmos: cosmos, hi: hi),
            const SizedBox(height: 12),
            _LuckyCard(cosmos: cosmos, hi: hi),
            const SizedBox(height: 12),
            _DeeperCard(
              hi: hi,
              revealed: _revealed,
              onReveal: () => _reveal(context, ref, hi),
            ),
          ] else
            _PersonalizedCta(hi: hi),
        ],
      ),
    );
  }

  void _reveal(BuildContext context, WidgetRef ref, bool hi) async {
    final chart = ref.read(chartProvider);
    if (chart == null) return;
    final ok = await ref.read(streakProvider.notifier).spendKamal(_revealCost);
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cDeeperInsufficient.call(hi))),
        );
      }
      return;
    }
    final day = nextFavourableDay(chart, DateTime.now());
    if (mounted) setState(() => _revealed = day ?? DateTime.now());
  }

  /// Render the selected sign's reading as a branded card and open the share
  /// sheet (falls back to text if the capture fails — see [shareCardImage]).
  void _shareRashi(bool hi) {
    final moonRashi = ref.read(transitMoonRashiProvider);
    final rashi = ref.read(selectedRashiProvider);
    final house = gocharHouseFrom(rashi, moonRashi);
    final verdict = rashiVerdict(house);
    final name = signNames[rashi].call(hi);
    final general = cGocharThemes[house - 1].call(hi);
    final caption = [
      '$name — ${hi ? 'आज का राशिफल' : "Today's Rashifal"}',
      general,
      '\n${hi ? Brand.nameHi : Brand.name} · ${hi ? Brand.taglineHi : Brand.taglineEn}',
    ].join('\n');
    shareCardImage(
      context: context,
      card: _RashiShareCard(
          hi: hi, rashi: rashi, house: house, verdict: verdict),
      text: caption,
      filename: 'aradhya_rashifal.png',
    );
  }
}

/// The shareable daily-rashifal card — same branded look as the Verse share
/// card (terracotta gradient, stitched outline, logo + wordmark footer).
/// Rendered off-screen by [shareCardImage].
class _RashiShareCard extends StatelessWidget {
  final bool hi;
  final int rashi;
  final int house;
  final Verdict verdict;
  const _RashiShareCard({
    required this.hi,
    required this.rashi,
    required this.house,
    required this.verdict,
  });

  static const _onColor = Color(0xFFFDEEDE);

  @override
  Widget build(BuildContext context) {
    final tone = verdict.index;
    final today = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    final body = hi ? AppFonts.devanagari : AppFonts.body;

    String pick(List<List<NamePair>> pool, int aspectId) {
      final tier = pool[tone];
      final v = dailyVariant(rashi, aspectId, DateTime.now(), tier.length);
      return tier[v].call(hi);
    }

    Widget line(IconData icon, NamePair label, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: _onColor.withValues(alpha: 0.9)),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: body,
                        fontSize: 14.5,
                        height: 1.4,
                        color: _onColor),
                    children: [
                      TextSpan(
                          text: '${label.call(hi)}:  ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: text),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return SizedBox(
      width: 420,
      child: DefaultTextStyle(
        style: const TextStyle(color: _onColor),
        child: StitchedCard(
          gradient: const LinearGradient(
            colors: [AppColors.terracotta, AppColors.terracottaDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          stitchColor: Colors.white.withValues(alpha: 0.6),
          radius: 24,
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((hi ? 'आज का राशिफल' : "Today's Rashifal").toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: _onColor.withValues(alpha: 0.82))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _onColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle),
                    child: RashiGlyph(index: rashi, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(signNames[rashi].call(hi),
                            style: TextStyle(
                                fontFamily: hi
                                    ? AppFonts.devanagari
                                    : AppFonts.display,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: _onColor)),
                        Text(today,
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: _onColor.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: _onColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(cVerdictLabels[tone].call(hi),
                        style: TextStyle(
                            fontFamily: body,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _onColor)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              line(Icons.wb_sunny_rounded, cAspectGeneral,
                  cGocharThemes[house - 1].call(hi)),
              line(Icons.favorite_rounded, cAspectLove, pick(cLove, 0)),
              line(Icons.work_rounded, cAspectCareer, pick(cCareer, 1)),
              line(Icons.favorite_border_rounded, cAspectHealth,
                  pick(cHealth, 2)),
              Divider(
                  height: 26,
                  thickness: 1,
                  color: _onColor.withValues(alpha: 0.2)),
              Row(
                children: [
                  const AppLogo(size: 30, tile: false),
                  const SizedBox(width: 8),
                  Text(hi ? Brand.nameHi : Brand.name,
                      style: TextStyle(
                          fontFamily:
                              hi ? AppFonts.devanagari : AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: _onColor)),
                  const Spacer(),
                  Text(hi ? Brand.taglineHi : Brand.taglineEn,
                      style: TextStyle(
                          fontFamily:
                              hi ? AppFonts.devanagari : AppFonts.accent,
                          fontSize: 13,
                          color: _onColor.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _verdictColor(Verdict v) => switch (v) {
      Verdict.favourable => AppColors.sacredGreen,
      Verdict.mixed => AppColors.gold,
      Verdict.challenging => AppColors.terracotta,
    };

/// A titled card shell used by every section.
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _Card(
      {required this.title,
      required this.icon,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final DailyCosmos cosmos;
  final bool hi;
  const _WeatherCard({required this.cosmos, required this.hi});

  @override
  Widget build(BuildContext context) {
    final v = cosmos.verdict;
    final color = _verdictColor(v);
    final tier = v.index; // 0 fav, 1 mixed, 2 hard
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.9),
          Color.lerp(color, Colors.black, 0.3)!,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.brightness_5_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
                '${cTitleWeather.call(hi).toUpperCase()} · ${cVerdictLabels[tier].call(hi)}',
                style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9))),
          ]),
          const SizedBox(height: 10),
          Text(cVerdictTiers[tier].call(hi),
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  height: 1.3,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _DashaCard extends StatelessWidget {
  final DailyCosmos cosmos;
  final bool hi;
  const _DashaCard({required this.cosmos, required this.hi});

  @override
  Widget build(BuildContext context) {
    final maha = planetInfo[cosmos.mahaLord]?.name.call(hi) ?? cosmos.mahaLord;
    final antar = planetInfo[cosmos.antarLord]?.name.call(hi) ?? cosmos.antarLord;
    final theme = cDashaThemeByLord[cosmos.mahaLord]?.call(hi) ?? '';
    final until = DateFormat('d MMM yyyy').format(cosmos.antarEnd);
    return _Card(
      title: cTitleDasha.call(hi),
      icon: Icons.timelapse_rounded,
      color: AppColors.dharmaPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$maha – $antar',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          Text(hi ? '$until तक' : 'until $until',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Text(theme, style: const TextStyle(fontSize: 14.5, height: 1.4)),
        ],
      ),
    );
  }
}

class _GocharCard extends StatelessWidget {
  final DailyCosmos cosmos;
  final bool hi;
  const _GocharCard({required this.cosmos, required this.hi});

  @override
  Widget build(BuildContext context) {
    final theme = cGocharThemes[cosmos.gocharHouse - 1].call(hi);
    return _Card(
      title: cTitleGochar.call(hi),
      icon: Icons.nightlight_round,
      color: AppColors.terracotta,
      child: Text(theme, style: const TextStyle(fontSize: 15, height: 1.45)),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String severity;
  final bool hi;
  const _AlertCard({required this.severity, required this.hi});

  @override
  Widget build(BuildContext context) {
    final phase = cSadeSatiPhase[severity]?.call(hi) ??
        cSadeSatiPhase['peak']!.call(hi);
    return _Card(
      title: cTitleAlert.call(hi),
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFF8A6D1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phase, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 8),
          Text('🪔 ${cSadeSatiRemedy.call(hi)}',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final DailyCosmos cosmos;
  final bool hi;
  const _HoursCard({required this.cosmos, required this.hi});

  String _fmt(Muhurat m) =>
      '${DateFormat('h:mm a').format(m.start)} – ${DateFormat('h:mm a').format(m.end)}';

  @override
  Widget build(BuildContext context) {
    Widget row(Muhurat m, bool good) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(good ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
                size: 16,
                color: good ? AppColors.sacredGreen : AppColors.terracotta),
            const SizedBox(width: 8),
            Expanded(
                child: Text(m.name.call(hi),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14))),
            Text(_fmt(m),
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65))),
          ]),
        );
    return _Card(
      title: cTitleHours.call(hi),
      icon: Icons.schedule_rounded,
      color: AppColors.sacredGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in cosmos.favHours) row(m, true),
          for (final m in cosmos.trickyHours) row(m, false),
        ],
      ),
    );
  }
}

class _LuckyCard extends StatelessWidget {
  final DailyCosmos cosmos;
  final bool hi;
  const _LuckyCard({required this.cosmos, required this.hi});

  @override
  Widget build(BuildContext context) {
    final colour = cLuckyColourByPlanet[cosmos.rulingPlanet]?.call(hi) ?? '—';
    final dir = cLuckyDirectionByPlanet[cosmos.rulingPlanet]?.call(hi) ?? '—';
    Widget bit(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
        );
    return _Card(
      title: cTitleLucky.call(hi),
      icon: Icons.auto_awesome_rounded,
      color: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            bit(cLabelColour.call(hi), colour),
            bit(cLabelNumber.call(hi), '${cosmos.luckyNumber}'),
            bit(cLabelDirection.call(hi), dir),
          ]),
          if (cosmos.luckyMantra.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(cLabelMantra.call(hi).toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
            const SizedBox(height: 2),
            Text(cosmos.luckyMantra,
                style: const TextStyle(
                    fontFamily: AppFonts.devanagari, fontSize: 16, height: 1.4)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.push('/japa'),
                icon: const Icon(Icons.grain_rounded, size: 18),
                label: Text(cChant.call(hi)),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeeperCard extends StatelessWidget {
  final bool hi;
  final DateTime? revealed;
  final VoidCallback onReveal;
  const _DeeperCard(
      {required this.hi, required this.revealed, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.deityRose.withValues(alpha: 0.16),
          AppColors.dharmaPurple.withValues(alpha: 0.10),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.deityRose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cDeeperTitle.call(hi),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 2),
                if (revealed != null)
                  Text(
                      '🌟 ${DateFormat('EEEE, d MMM').format(revealed!)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))
                else
                  Row(children: [
                    const KamalIcon(size: 14),
                    const SizedBox(width: 4),
                    Text('${cDeeperLocked.call(hi)} · $_revealCost',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65))),
                  ]),
              ],
            ),
          ),
          if (revealed == null)
            IconButton.filledTonal(
              onPressed: onReveal,
              icon: const Icon(Icons.lock_open_rounded),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        child: Text(text,
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Theme.of(context).colorScheme.primary)),
      );
}

/// The classic 12-Rashi daily horoscope: pick a moon sign → today's Chandra-
/// gochar prediction. Needs no birth details.
class _RashiHoroscope extends ConsumerWidget {
  const _RashiHoroscope();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final moonRashi = ref.watch(transitMoonRashiProvider);
    final selected = ref.watch(selectedRashiProvider);
    final scheme = Theme.of(context).colorScheme;

    final house = gocharHouseFrom(selected, moonRashi);
    final verdict = rashiVerdict(house);
    final color = _verdictColor(verdict);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(hi ? 'आज का राशिफल' : "Today's Horoscope"),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final sel = i == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref.read(selectedRashiProvider.notifier).state = i;
                  ref.read(sharedPrefsProvider).setInt(PrefKeys.rashi, i);
                },
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: sel
                        ? scheme.primary.withValues(alpha: 0.14)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: scheme.primary
                            .withValues(alpha: sel ? 0.6 : 0.18),
                        width: sel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RashiGlyph(index: i, size: 24),
                      const SizedBox(height: 3),
                      Text(signNames[i].call(hi),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? scheme.primary
                                  : scheme.onSurface
                                      .withValues(alpha: 0.7))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _RashiDetail(
            hi: hi, rashi: selected, house: house, verdict: verdict, color: color),
      ],
    );
  }
}

/// The detailed reading for the selected rashi: score, general + Love / Career
/// / Health / Money / Family (tone-tiered by the day) + lucky colour & number.
class _RashiDetail extends StatelessWidget {
  final bool hi;
  final int rashi;
  final int house;
  final Verdict verdict;
  final Color color;
  const _RashiDetail({
    required this.hi,
    required this.rashi,
    required this.house,
    required this.verdict,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = verdict.index; // 0 fav, 1 mixed, 2 hard
    final stars = rashiScore(house);
    final lord = rashiLords[rashi];
    final colour = cLuckyColourByPlanet[lord]?.call(hi) ?? '—';

    // Pick this rashi's line for the day from the tone's variant pool — differs
    // by sign and rotates day to day (deterministic, no RNG).
    String pick(List<List<NamePair>> pool, int aspectId) {
      final tier = pool[tone];
      final v = dailyVariant(rashi, aspectId, DateTime.now(), tier.length);
      return tier[v].call(hi);
    }

    Widget aspect(IconData icon, NamePair label, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.call(hi).toUpperCase(),
                        style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 1),
                    Text(text,
                        style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            RashiGlyph(index: rashi, size: 26),
            const SizedBox(width: 8),
            Text(signNames[rashi].call(hi),
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const Spacer(),
            for (var i = 0; i < 5; i++)
              Icon(i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16, color: AppColors.gold),
          ]),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(cVerdictLabels[tone].call(hi),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const SizedBox(height: 12),
          aspect(Icons.wb_sunny_rounded, cAspectGeneral,
              cGocharThemes[house - 1].call(hi)),
          aspect(Icons.favorite_rounded, cAspectLove, pick(cLove, 0)),
          aspect(Icons.work_rounded, cAspectCareer, pick(cCareer, 1)),
          aspect(Icons.favorite_border_rounded, cAspectHealth,
              pick(cHealth, 2)),
          aspect(Icons.savings_rounded, cAspectMoney, pick(cMoney, 3)),
          aspect(Icons.home_rounded, cAspectFamily, pick(cFamily, 4)),
          Divider(height: 8, color: scheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(
                '${cLabelColour.call(hi)}: $colour   ·   ${cLabelNumber.call(hi)}: ${rashiLuckyNumber[rashi]}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ],
      ),
    );
  }
}

/// Compact prompt (shown under the horoscope) to create a chart for the deep
/// personalized reading.
class _PersonalizedCta extends StatelessWidget {
  final bool hi;
  const _PersonalizedCta({required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.16),
          AppColors.terracotta.withValues(alpha: 0.10),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(cEmptyHeading.call(hi),
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 17)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(cEmptyBody.call(hi),
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => context.go('/astrology'),
            style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
            child: Text(cEmptyCta.call(hi),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
