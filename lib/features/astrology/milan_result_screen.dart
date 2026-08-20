import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/brand.dart';
import '../../core/providers/app_providers.dart';
import '../../app/theme/app_theme.dart';
import '../panchang/panchang_names.dart' show nakshatraNames;
import 'ashtakoot.dart';
import 'astrology_data.dart';
import 'milan_interpretations.dart';

// Warm "reveal" palette (dark terracotta with cream text).
const _bgTop = Color(0xFF5C1A0D);
const _bgBottom = Color(0xFF7A2413);
const _cream = Color(0xFFF6E7D4);
const _gold = Color(0xFFD9B36C);
Color get _muted => _cream.withValues(alpha: 0.68);
Color get _cardBg => Colors.white.withValues(alpha: 0.055);
Color get _cardBorder => _cream.withValues(alpha: 0.16);

/// Kundli Milan — Step 2: the full Ashtakoot compatibility result.
class MilanResultScreen extends ConsumerStatefulWidget {
  final MilanResult result;
  const MilanResultScreen({super.key, required this.result});
  @override
  ConsumerState<MilanResultScreen> createState() => _MilanResultScreenState();
}

class _MilanResultScreenState extends ConsumerState<MilanResultScreen> {
  bool _expanded = true;

  MilanResult get r => widget.result;

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final (vTitle, vBody) = milanVerdict(r.total, hi);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(hi ? 'अष्टकूट गुण मिलान' : 'ASHTAKOOT GUNA MILAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _gold,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: _cream),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _names(),
              const SizedBox(height: 20),
              Center(child: _gauge(hi)),
              const SizedBox(height: 22),
              Text(vTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      color: _cream,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(vBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _muted, fontSize: 14.5, height: 1.5)),
              const SizedBox(height: 26),

              _sectionTitle(hi ? '8 कूट' : '8 Koots'),
              const SizedBox(height: 6),
              for (final k in r.koots) _kootRow(k, hi),
              const SizedBox(height: 18),

              // Expand toggle
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _gold),
                  label: Text(
                      _expanded
                          ? (hi ? 'विस्तृत विश्लेषण छिपाएँ' : 'Hide Detailed Analysis')
                          : (hi ? 'विस्तृत विश्लेषण देखें' : 'Show Detailed Analysis'),
                      style: const TextStyle(
                          color: _gold, fontWeight: FontWeight.w700)),
                ),
              ),

              if (_expanded) ..._details(hi),

              const SizedBox(height: 20),
              _actions(context, hi),
              const SizedBox(height: 18),
              Text(milanDisclaimer(hi),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _cream.withValues(alpha: 0.45),
                      fontSize: 11.5,
                      height: 1.5,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  /// Role labels under the names.
  ///
  /// Varna and Tara are computed groom-first, so which chart held which role
  /// changes the score. Showing it means a reader can tell whether the result
  /// they are looking at matches the couple they entered.
  Widget _roleLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: _cream.withValues(alpha: 0.65)),
      );

  Widget _names() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(r.a.name,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: _cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
                _roleLabel(r.roleA == MilanRole.groom ? 'GROOM' : 'BRIDE'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.favorite_rounded, color: _gold, size: 20),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.b.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: _cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
                _roleLabel(r.roleA == MilanRole.groom ? 'BRIDE' : 'GROOM'),
              ],
            ),
          ),
        ],
      );

  Widget _gauge(bool hi) => SizedBox(
        width: 190,
        height: 190,
        child: CustomPaint(
          painter: _GaugePainter(r.total / 36),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmt(r.total),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: _cream,
                        fontSize: 52,
                        height: 1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(hi ? '36 में से' : 'of 36',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ),
      );

  Widget _kootRow(KootScore k, bool hi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _cream.withValues(alpha: 0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milanKootName(k.key, k.name, hi),
                    style: const TextStyle(
                        color: _cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(milanKootLine(k.key, k.got, k.max, hi),
                    style: TextStyle(
                        color: _muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${_fmt(k.got)} / ${_fmt(k.max)}',
              style: TextStyle(
                  color: _scoreColor(k.got, k.max),
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ---- Detailed analysis ----

  List<Widget> _details(bool hi) {
    return [
      const SizedBox(height: 18),
      _sectionTitle(hi ? 'आपकी ज्योतिषीय झलक' : 'Your Cosmic Profiles'),
      _sectionSub(hi
          ? 'तारों की भाषा में आप दोनों की एक झलक।'
          : 'A glance at each of you in the language of the stars.'),
      const SizedBox(height: 12),
      _personCard(r.a, hi),
      const SizedBox(height: 12),
      _personCard(r.b, hi),
      const SizedBox(height: 26),

      _sectionTitle(hi ? 'अनुकूलता · चार आयाम' : 'Compatibility · Four Dimensions'),
      _sectionSub(hi
          ? 'आठ कूट उन चार क्षेत्रों में पुनर्गठित, जिनमें रिश्ता सचमुच जिया जाता है।'
          : 'The eight koots regrouped into the four areas a relationship is actually lived.'),
      const SizedBox(height: 12),
      for (final d in milanDimensions) _dimensionCard(d, hi),
      const SizedBox(height: 20),

      ..._listSection(
        hi ? 'आपकी शक्तियाँ' : 'Where You Shine',
        hi
            ? 'वे बातें जहाँ कुंडली आप पर उदार है — इन्हें सराहें।'
            : 'The places the chart is generous to you — celebrate these.',
        milanShineItems(r, hi),
        _gold,
        Icons.auto_awesome_rounded,
      ),
      ..._listSection(
        hi ? 'ध्यान देने योग्य बातें' : 'Areas Asking for Awareness',
        hi
            ? 'कठिनाइयों को नाम देना उन्हें पार करना आसान बनाता है।'
            : 'Naming the honest stretches makes them easier to walk.',
        milanAwareItems(r, hi),
        const Color(0xFFE0A15A),
        Icons.self_improvement_rounded,
      ),

      const SizedBox(height: 6),
      _sectionTitle(hi
          ? 'रोज़मर्रा जीवन में यह कैसा दिखेगा'
          : 'What This Looks Like in Daily Life'),
      const SizedBox(height: 10),
      for (final item in milanDailyLife(r, hi)) _dailyRow(item.$1, item.$2),
      const SizedBox(height: 22),

      _manglikCard(hi),
      const SizedBox(height: 22),

      _closingCard(hi),
    ];
  }

  Widget _personCard(PersonMilan p, bool hi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  color: _cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _profileRow(hi ? 'चंद्र राशि' : 'Moon Sign', signNames[p.rashi].call(hi),
              milanMoonSignDesc(p.rashi, hi)),
          _profileRow(
              hi ? 'जन्म नक्षत्र' : 'Birth Star',
              '${nakshatraNames[p.nakshatra].call(hi)} · ${hi ? 'पाद' : 'Pada'} ${p.nakPada}',
              '${hi ? 'अधिष्ठाता देव' : 'Presiding deity'}: ${milanNakshatraDeity(p.nakshatra, hi)}'),
          _profileRow(hi ? 'योनि · पशु स्वभाव' : 'Yoni · Animal Nature',
              milanYoniName(p.yoni, hi), milanYoniDesc(p.yoni, hi)),
          _profileRow(hi ? 'वर्ण · स्वभाव' : 'Varna · Temperament',
              milanVarnaName(p.varnaRank, hi), milanVarnaDesc(p.varnaRank, hi)),
          _profileRow(hi ? 'गण · प्रकृति' : 'Gana · Nature',
              milanGanaName(p.gana, hi), milanGanaDesc(p.gana, hi)),
          _profileRow(hi ? 'नाड़ी · प्रकृति' : 'Nadi · Constitution',
              milanNadiName(p.nadi, hi), milanNadiDesc(p.nadi, hi),
              last: true),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value, String desc,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: _gold,
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: _cream, fontSize: 15.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(desc,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _dimensionCard(MilanDimension d, bool hi) {
    double got = 0, max = 0;
    for (final key in d.koots) {
      final k = r.koot(key);
      got += k.got;
      max += k.max;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.titleOf(hi),
                    style: const TextStyle(
                        color: _cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              Text('${_fmt(got)} / ${_fmt(max)}',
                  style: TextStyle(
                      color: _scoreColor(got, max),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(milanDimensionBody(d, got, max, hi),
              style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }

  List<Widget> _listSection(String title, String sub,
      List<(String, String)> items, Color accent, IconData icon) {
    if (items.isEmpty) return const [];
    return [
      _sectionTitle(title),
      _sectionSub(sub),
      const SizedBox(height: 12),
      for (final it in items)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(it.$1,
                        style: TextStyle(
                            color: accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(it.$2,
                  style: TextStyle(
                      color: _muted, fontSize: 13.5, height: 1.5)),
            ],
          ),
        ),
      const SizedBox(height: 8),
    ];
  }

  Widget _dailyRow(String label, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _cream, fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(body,
              style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _manglikCard(bool hi) {
    final (title, body) = milanManglikNote(r, hi);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFE0A15A), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: _cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _closingCard(bool hi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'तारों का अंतिम संदेश' : 'The Stars\' Closing Word',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: _gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(milanClosingWord(r.total, hi),
              style: const TextStyle(
                  color: _cream,
                  fontSize: 14,
                  height: 1.6,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, bool hi) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: Text(hi ? 'दोस्तों के साथ साझा करें' : 'Share with Friends'),
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _bgTop,
            minimumSize: const Size.fromHeight(52),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.bookmark_border_rounded, size: 18),
          label: Text(hi ? 'गैलरी में सहेजें' : 'Save to Gallery'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _cream,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: _cardBorder),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(hi ? 'दूसरी जोड़ी देखें' : 'Try Another Pairing',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ---- Share / save ----

  Future<Uint8List?> _captureCard() async {
    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: 0,
        // The card sets its own width; this only stops the screen's height
        // constraint from shearing off the bottom of a tall result.
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: key,
              child: MilanShareCard(result: r, hi: ref.read(isHindiProvider)),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      // Wait for real frames, not a guessed millisecond count.
      RenderRepaintBoundary? boundary;
      for (var i = 0; i < 12; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return null;
        final object = key.currentContext?.findRenderObject();
        if (object is RenderRepaintBoundary && !object.debugNeedsPaint) {
          boundary = object;
          break;
        }
      }
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  Future<void> _share() async {
    final hi = ref.read(isHindiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _captureCard();
      if (bytes == null) return;
      const name = 'aradhya_milan.png';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: 'image/png')],
        fileNameOverrides: const [name],
        text: hi
            ? '${r.a.name} ♥ ${r.b.name} — ${Brand.nameHi} पर ${_fmt(r.total)}/36 गुण'
            : '${r.a.name} ♥ ${r.b.name} — ${_fmt(r.total)}/36 guna on ${Brand.name}',
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(hi ? 'साझा नहीं किया जा सका: $e' : 'Could not share: $e')));
    }
  }

  Future<void> _save() async {
    final hi = ref.read(isHindiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _captureCard();
      if (bytes == null) return;
      final name =
          '${Brand.name}_Milan_${r.a.name}_${r.b.name}'.replaceAll(' ', '_');
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        await Gal.putImageBytes(bytes, name: name);
        messenger.showSnackBar(SnackBar(
            content: Text(
                hi ? 'आपकी गैलरी में सहेजा गया।' : 'Saved to your gallery.')));
      } else {
        final dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(bytes);
        messenger.showSnackBar(SnackBar(
            content: Text(hi
                ? 'यहाँ सहेजा गया: ${file.path}'
                : 'Saved to ${file.path}')));
      }
    } on GalException catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(hi
              ? 'सहेजा नहीं जा सका: ${e.type.message}'
              : 'Could not save: ${e.type.message}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(hi ? 'सहेजा नहीं जा सका: $e' : 'Could not save: $e')));
    }
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontFamily: AppFonts.display,
          color: _cream,
          fontSize: 20,
          fontWeight: FontWeight.w700));

  Widget _sectionSub(String t) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(t,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
      );

  Color _scoreColor(double got, double max) {
    if (max == 0) return _muted;
    final r = got / max;
    if (r >= 0.66) return const Color(0xFF8BD1A0); // soft green
    if (r > 0) return _gold;
    return const Color(0xFFE79A8C); // soft red
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  const _GaugePainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _cream.withValues(alpha: 0.15);
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = _gold;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;
}

/// A compact, self-contained card rendered off-screen and captured to a PNG for
/// sharing / saving. Fixed width so the exported image is consistent.
class MilanShareCard extends StatelessWidget {
  final MilanResult result;
  final bool hi;
  const MilanShareCard({super.key, required this.result, this.hi = false});

  String _f(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Color _sc(double got, double max) {
    if (max == 0) return _muted;
    final r = got / max;
    if (r >= 0.66) return const Color(0xFF8BD1A0);
    if (r > 0) return _gold;
    return const Color(0xFFE79A8C);
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final (vTitle, _) = milanVerdict(r.total, hi);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('DivyaVaani',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: _gold,
                  fontSize: 20,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(hi ? 'अष्टकूट गुण मिलान' : 'ASHTAKOOT GUNA MILAN',
              style: TextStyle(
                  color: _cream.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(r.a.name,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: _cream,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.favorite_rounded, color: _gold, size: 18),
              ),
              Flexible(
                child: Text(r.b.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        color: _cream,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _GaugePainter(r.total / 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_f(r.total),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            color: _cream,
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w700)),
                    Text(hi ? '36 में से' : 'of 36',
                        style: TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(vTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  color: _cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Divider(color: _cream.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),
          for (final k in r.koots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(milanKootName(k.key, k.name, hi),
                        style: const TextStyle(
                            color: _cream,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text('${_f(k.got)} / ${_f(k.max)}',
                      style: TextStyle(
                          color: _sc(k.got, k.max),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Divider(color: _cream.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),
          Text(hi ? 'DivyaVaani ऐप से बनाया गया' : 'Generated with the DivyaVaani app',
              style: TextStyle(
                  color: _cream.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }
}
