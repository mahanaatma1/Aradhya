import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../astrology/astro_chart.dart';
import '../astrology/astrology_data.dart';
import '../astrology/astrology_providers.dart';
import '../panchang/panchang_names.dart';

/// "Jyotish" tab — Your Cosmic Story: a saved-chart summary, Kundli & Milan,
/// plus Panchang. Enhanced with a twilight cosmic hero and a rashi-chakra motif.
class JyotishHubScreen extends ConsumerWidget {
  const JyotishHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final birth = ref.watch(birthDetailsProvider);
    final chart = ref.watch(chartProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.catAstrology)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CosmicHero(hi: hi),
          const SizedBox(height: 16),

          if (birth != null && chart != null)
            _YourChartCard(name: birth.name, chart: chart, hi: hi),

          _BigCard(
            badge: birth == null
                ? (hi ? 'नया' : 'NEW')
                : (hi ? 'खुला' : 'OPEN'),
            icon: Icons.brightness_7_rounded,
            title: hi ? 'जन्म कुंडली' : 'Birth Kundli',
            subtitle: hi
                ? 'ग्रह, भाव, D1 और D9, दशाएँ, योग और दोष'
                : 'Planets, houses, D1 & D9, dashas, yogas & doshas',
            gradient: const [Color(0xFFE6C34A), Color(0xFFB8892E)],
            circle: const Color(0xFFF2DA86),
            buttonLabel: birth == null
                ? (hi ? 'कुंडली बनाएं' : 'Create Kundli')
                : (hi ? 'कुंडली खोलें' : 'Open Kundli'),
            onTap: () =>
                context.push(birth == null ? '/astrology' : '/astrology/kundli'),
          ),
          _BigCard(
            badge: hi ? 'कुंडली मिलान' : 'KUNDLI MILAN',
            icon: Icons.favorite_rounded,
            title: hi ? 'अनुकूलता परीक्षण' : 'Compatibility Test',
            subtitle: hi
                ? 'अष्टकूट गुण मिलान — दो कुंडलियों के बीच 36 अंकों का मिलान'
                : 'Ashtakoot Guna Milan — 36-point match between two charts',
            gradient: const [Color(0xFFD68AA6), Color(0xFF9C2950)],
            circle: const Color(0xFFE7A9BF),
            buttonLabel: hi ? 'मिलान करें' : 'Match Pair',
            onTap: () => context.push('/astrology/milan'),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
                hi
                    ? 'सभी गणनाएँ लाहिरी अयनांश (वैदिक / निरयन) पर आधारित हैं।'
                    : 'All calculations use Lahiri ayanamsa (Vedic / sidereal).',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }
}

/// A twilight "night sky" hero with a faint rashi-chakra and scattered stars.
class _CosmicHero extends StatelessWidget {
  final bool hi;
  const _CosmicHero({required this.hi});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B2A63), Color(0xFF7A2E52), Color(0xFFB23A18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Chakra motif, bleeding off the right edge
          Positioned(
            right: -46,
            top: -30,
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: _ChakraPainter()),
            ),
          ),
          // A few stars
          const Positioned(left: 26, top: 26, child: _Star(9, 0.9)),
          const Positioned(left: 70, top: 58, child: _Star(6, 0.6)),
          const Positioned(right: 120, bottom: 24, child: _Star(7, 0.7)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hi ? 'ज्योतिष' : 'JYOTISH',
                    style: TextStyle(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.goldBright)),
                const SizedBox(height: 6),
                Text(hi ? 'आपकी ज्योतिष गाथा' : 'Your Cosmic Story',
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1.05,
                        color: Color(0xFFFCEFE2))),
                const SizedBox(height: 8),
                Text(
                    hi
                        ? 'जन्म कुंडली · दशा · योग · दोष · अनुकूलता'
                        : 'Birth chart · Dasha · Yogas · Doshas · Compatibility',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: const Color(0xFFFCEFE2).withValues(alpha: 0.82))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final double size;
  final double opacity;
  const _Star(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome,
        size: size, color: AppColors.goldBright.withValues(alpha: opacity));
  }
}

/// Draws a faint concentric rashi-chakra (12 spokes + rings + dots).
class _ChakraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFF0D48A).withValues(alpha: 0.35);
    for (final f in [1.0, 0.74, 0.42]) {
      canvas.drawCircle(c, r * f, line);
    }
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.42),
        c + Offset(math.cos(a), math.sin(a)) * r,
        line,
      );
    }
    final dot = Paint()..color = const Color(0xFFF0D48A).withValues(alpha: 0.5);
    for (var i = 0; i < 12; i++) {
      final a = (i + 0.5) * math.pi / 6;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * (r * 0.87), 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(_ChakraPainter old) => false;
}

class _YourChartCard extends StatelessWidget {
  final String name;
  final BirthChart chart;
  final bool hi;
  const _YourChartCard(
      {required this.name, required this.chart, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moon = chart.byKey('moon');
    final naksIdx = (moon.graha.sidereal / (360 / 27)).floor() % 27;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(painter: _SmallChakra(scheme.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hi ? 'आपकी कुंडली' : 'YOUR CHART',
                        style: TextStyle(
                            letterSpacing: 1.5,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary)),
                    Text(name,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _bit(context, hi ? 'लग्न' : 'Lagna',
                  signNames[chart.lagnaRashi].call(hi)),
              _sep(scheme),
              _bit(context, hi ? 'चंद्र' : 'Moon',
                  signNames[moon.graha.rashi].call(hi)),
              _sep(scheme),
              _bit(context, hi ? 'नक्षत्र' : 'Nakshatra',
                  nakshatraNames[naksIdx].call(hi)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sep(ColorScheme scheme) => Container(
      width: 1, height: 32, color: scheme.outline.withValues(alpha: 0.22));

  Widget _bit(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _SmallChakra extends CustomPainter {
  final Color color;
  _SmallChakra(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.32;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color;
    canvas.drawCircle(c, r, p);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r * 0.4),
          c + Offset(math.cos(a), math.sin(a)) * r, p);
    }
  }

  @override
  bool shouldRepaint(_SmallChakra old) => old.color != color;
}

class _BigCard extends StatelessWidget {
  final String badge;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color circle;
  final String buttonLabel;
  final VoidCallback onTap;
  const _BigCard({
    required this.badge,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.circle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradient.last.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // decorative corner circle
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: circle.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          Icon(icon, color: const Color(0xFFFFF8EF), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(title,
                              style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  height: 1.1,
                                  color: Color(0xFFFFF8EF))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.92))),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: gradient.last,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(buttonLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
