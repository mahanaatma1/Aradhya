import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/stitched_border.dart';
import 'passport_providers.dart';
import 'passport_stamp.dart';

const _cover = Color(0xFF5C2E1E);
const _coverDeep = Color(0xFF3A1B10);
const _emboss = Color(0xFFD9A441);

/// The passport cover, embossed the way a real one is.
///
/// Gold on dark leather, everything stamped rather than printed, and the
/// stitched motif that runs through the rest of the app doing the job it does
/// on an actual document: holding the edge.
class PassportCover extends StatelessWidget {
  final String holder;
  final int visits;
  final bool hindi;

  /// Optional. When present the cover becomes a data page rather than just a
  /// title -- which is what stops it reading as an empty slab.
  final PassportStats? stats;

  const PassportCover({
    super.key,
    required this.holder,
    required this.visits,
    required this.hindi,
    this.stats,
  });

  /// Gold leaf is not a flat colour -- it catches light across its face. A
  /// shader across the glyphs is what separates embossed foil from yellow text.
  static const _foil = LinearGradient(
    colors: [
      Color(0xFFF6E3A8),
      Color(0xFFD9A441),
      Color(0xFFA8761F),
      Color(0xFFEBCE86),
    ],
    stops: [0.0, 0.38, 0.68, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Widget _foiled(Widget child) => ShaderMask(
        shaderCallback: (r) => _foil.createShader(r),
        blendMode: BlendMode.srcIn,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return StitchedCard(
      radius: 18,
      stitchColor: _emboss.withValues(alpha: 0.55),
      gradient: const LinearGradient(
        colors: [Color(0xFF6B3823), _cover, _coverDeep],
        stops: [0.0, 0.45, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: EdgeInsets.zero,
      child: CustomPaint(
        painter: _LeatherPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _foiled(Text(
                hindi ? 'तीर्थ यात्रा' : 'PILGRIMAGE',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 3.4,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )),
              const SizedBox(height: 12),
              // The emblem sits in a struck gold ring, the way a crest does.
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _CrestPainter(),
                  child: const Center(child: AppLogo(size: 54)),
                ),
              ),
              const SizedBox(height: 12),
              _foiled(Text(
                hindi ? 'यात्रा पासपोर्ट' : 'YATRA PASSPORT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 23,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )),
              const SizedBox(height: 5),
              _foiled(Text(
                Brand.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 4.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )),
              const SizedBox(height: 16),
              const _Rule(),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Field(
                    label: hindi ? 'यात्री' : 'HOLDER',
                    value: holder.isEmpty
                        ? (hindi ? 'श्रद्धालु' : 'Devotee')
                        : holder,
                  ),
                  const SizedBox(width: 18),
                  _Field(
                    label: hindi ? 'क्रमांक' : 'PASSPORT NO',
                    value: PassportStats.number(holder),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Field(
                    label: hindi ? 'दर्शन' : 'DARSHAN',
                    value: '$visits',
                  ),
                  const SizedBox(width: 18),
                  _Field(
                    label: hindi ? 'राज्य' : 'STATES',
                    value: '${stats?.states ?? 0}',
                  ),
                  const SizedBox(width: 18),
                  _Field(
                    label: hindi ? 'से' : 'SINCE',
                    value: stats?.sinceYear?.toString() ?? '—',
                  ),
                ],
              ),
              if (stats != null) ...[
                const SizedBox(height: 14),
                _RankStrip(visits: visits, hindi: hindi),
              ],
              const SizedBox(height: 14),
              // The line that says what the document is actually for.
              Text(
                hindi
                    ? 'यात्रा केवल स्थानों की नहीं, आत्मा की भी है।'
                    : 'A journey is not only of places, but of the soul.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.accent,
                  fontSize: 11.5,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: _emboss.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where this journey stands, and how far the next rung is.
///
/// The titles describe what someone is doing, not an honour the app is in any
/// position to confer -- a pilgrimage is not a loyalty tier.
class _RankStrip extends StatelessWidget {
  final int visits;
  final bool hindi;
  const _RankStrip({required this.visits, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final rank = YatraRank.forCount(visits);
    final next = YatraRank.next(visits);
    final span = next == null ? 1 : next.from - rank.from;
    final done = next == null ? 1.0 : ((visits - rank.from) / span).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hindi
                  ? 'स्तर ${YatraRank.levelFor(visits)} • ${rank.titleHi}'
                  : 'LEVEL ${YatraRank.levelFor(visits)} • '
                      '${rank.titleEn.toUpperCase()}',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 14,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF3DFB8),
              ),
            ),
            const Spacer(),
            Text(
              next == null
                  ? (hindi ? 'शिखर' : 'Highest')
                  : (hindi
                      ? '${next.from - visits} और ${next.titleHi} तक'
                      : '${next.from - visits} more to ${next.titleEn}'),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: _emboss.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: done.toDouble(),
            minHeight: 4,
            backgroundColor: Colors.black.withValues(alpha: 0.28),
            valueColor: const AlwaysStoppedAnimation(_emboss),
          ),
        ),
      ],
    );
  }
}

/// An ornamental rule with a centre diamond -- the divider a real cover uses
/// instead of a plain line.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    Widget side(bool left) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _emboss.withValues(alpha: left ? 0.0 : 0.55),
                  _emboss.withValues(alpha: left ? 0.55 : 0.0),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        side(true),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785,
          child: Container(width: 5, height: 5, color: _emboss),
        ),
        const SizedBox(width: 8),
        side(false),
      ],
    );
  }
}

/// Leather is grain and a darkened edge, not a flat gradient.
class _LeatherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // The card is rounded; the grain, the vignette and the embossed frame all
    // paint to the full rect, so without this the corners come out square and
    // the shadow shows through them.
    canvas.clipRRect(RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(18)));
    final rnd = math.Random(7);
    final grain = Paint()..strokeWidth = 0.6;
    for (var i = 0; i < 130; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 4 + rnd.nextDouble() * 14;
      final a = rnd.nextDouble() * math.pi;
      grain.color =
          Colors.white.withValues(alpha: 0.012 + rnd.nextDouble() * 0.022);
      canvas.drawLine(Offset(x, y),
          Offset(x + math.cos(a) * len, y + math.sin(a) * len), grain);
    }

    // Vignette: the edges of a bound cover sit lower than its face.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // A blind-embossed frame, inset from the stitching.
    final inset = const EdgeInsets.all(9).deflateRect(Offset.zero & size);
    final rrect = RRect.fromRectAndRadius(inset, const Radius.circular(11));
    canvas.drawRRect(
        rrect.shift(const Offset(0, 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.22));
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _emboss.withValues(alpha: 0.30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The gold ring the emblem is struck into, with rays behind it.
class _CrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    for (var i = 0; i < 48; i++) {
      final a = i / 48 * 2 * math.pi;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.66),
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.82),
        Paint()
          ..strokeWidth = 0.7
          ..color = _emboss.withValues(alpha: i.isEven ? 0.30 : 0.13),
      );
    }
    canvas.drawCircle(
        c,
        r * 0.88,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _emboss.withValues(alpha: 0.62));
    canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _emboss.withValues(alpha: 0.34));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 8.5,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: _emboss.withValues(alpha: 0.65),
              )),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF3DFB8),
              )),
        ],
      ),
    );
  }
}

/// A page of stamps, the way a passport fills up.
///
/// Stamps overlap slightly and sit at their own angles, because a page of
/// perfectly aligned circles reads as a grid of badges, not as a document
/// somebody has actually travelled with.
class StampPage extends StatelessWidget {
  final List<PassportEntry> entries;
  final bool hindi;
  final int pageNumber;

  const StampPage({
    super.key,
    required this.entries,
    required this.hindi,
    this.pageNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    return PassportPaper(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hindi ? 'दर्शन मुद्रा' : 'DARSHAN STAMPS',
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w800,
                  color: kStampInk.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Text(
                pageNumber.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: kStampInk.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              for (final e in entries)
                PassportStamp(
                  templeId: e.templeId,
                  place: e.name(hindi),
                  date: e.visitedAt,
                  state: e.state,
                  size: 96,
                ),
            ],
          ),
          const SizedBox(height: 10),
          MachineReadableStrip(
            line1: _mrz1(entries.length),
            line2: _mrz2(entries),
          ),
        ],
      ),
    );
  }

  /// Machine-readable zone, in the real format's shape. It encodes nothing
  /// private -- only the count and the visited temple ids, which are already
  /// on the page above it.
  static String _mrz1(int n) =>
      'P<IND<ARADHYA<<YATRA<<<<<<<<<<<<<<<<<<<<<'
          .padRight(44, '<')
          .substring(0, 40);

  static String _mrz2(List<PassportEntry> e) {
    final ids = e.take(6).map((x) => x.templeId.toString().padLeft(4, '0'));
    return '${ids.join('<')}<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
        .padRight(40, '<')
        .substring(0, 40);
  }
}

/// The share card: one image, the passport cover and the most recent stamps,
/// carrying the Aradhya logo and wordmark so it is recognisable when it lands
/// in somebody else's chat.
class PassportShareCard extends StatelessWidget {
  final String holder;
  final int visits;
  final List<PassportEntry> recent;
  final bool hindi;
  final PassportStats? stats;
  final int jyotirlinga;
  final int dham;

  const PassportShareCard({
    super.key,
    required this.holder,
    required this.visits,
    required this.recent,
    required this.hindi,
    this.stats,
    this.jyotirlinga = 0,
    this.dham = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDF8F5), Color(0xFFF0E2D2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PassportCover(
              holder: holder, visits: visits, hindi: hindi, stats: stats),
          const SizedBox(height: 12),

          // What the journey adds up to, in four numbers somebody can read at
          // a glance in a chat thread.
          Row(
            children: [
              _ShareStat(
                  value: '$visits', label: hindi ? 'दर्शन' : 'Darshan'),
              _ShareStat(
                  value: '${stats?.states ?? 0}',
                  label: hindi ? 'राज्य' : 'States'),
              _ShareStat(
                  value: '$jyotirlinga',
                  label: hindi ? 'ज्योतिर्लिंग' : 'Jyotirlinga'),
              _ShareStat(
                  value: '$dham', label: hindi ? 'धाम' : 'Dham'),
            ],
          ),
          const SizedBox(height: 12),

          if (recent.isNotEmpty)
            StampPage(
              entries: recent.take(5).toList(),
              hindi: hindi,
              pageNumber: 1,
            ),
          const SizedBox(height: 12),
          Text(
            hindi
                ? 'श्रद्धा की यात्रा — एक बार में एक दर्शन।'
                : 'A journey of faith, one darshan at a time.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.accent,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF5A4632),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 26, tile: false),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: Brand.nameHead,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A3B2A),
                      ),
                    ),
                    TextSpan(
                      text: Brand.nameTail,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC08A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            hindi ? Brand.taglineHi : Brand.taglineEn,
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.2,
              color: Color(0xFF7A6A58),
            ),
          ),
        ],
      ),
    );
  }
}

/// One number on the share card, sized to be legible after a chat app has had
/// its way with the image.
class _ShareStat extends StatelessWidget {
  final String value;
  final String label;
  const _ShareStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2A18),
                )),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A6A4F),
                )),
          ],
        ),
      );
}
