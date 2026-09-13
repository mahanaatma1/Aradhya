import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/daily_quote.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../panchang/festivals.dart';
import '../panchang/panchang_engine.dart';
import '../panchang/panchang_providers.dart';

/// Fully-qualified provider names (must match the Kotlin classes + manifest).
const _pkg = 'com.sumerudigital.divyavaani';
const _panchangProviderName = '$_pkg.PanchangWidgetProvider';
const _verseProviderName = '$_pkg.VerseWidgetProvider';

const _widgetSize = Size(360, 178);

/// Home-screen widgets exist only on Android/iOS.
bool get _widgetsSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Render the current Panchang + Verse to images and push them to any pinned
/// home-screen widgets. Safe to call whenever the app is in the foreground.
Future<void> refreshHomeWidgets(WidgetRef ref) async {
  if (!_widgetsSupported) return;
  try {
    final hi = ref.read(isHindiProvider);

    // Panchang (computed on-device for the effective location).
    final loc = ref.read(effectiveLocationProvider);
    final p = computePanchang(
      date: DateTime.now(),
      lat: loc.lat,
      lonEast: loc.lon,
      tzOffset: DateTime.now().timeZoneOffset,
      amanta: ref.read(amantaSystemProvider),
    );
    final fest =
        festivalOnDay(DateTime.now(), DateTime.now().timeZoneOffset);
    await HomeWidget.renderFlutterWidget(
      _PanchangWidgetView(p: p, hi: hi, festival: fest),
      key: 'panchang_widget',
      logicalSize: _widgetSize,
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _panchangProviderName);

    // Verse of the day (await so a just-changed verse is reflected).
    final verse = await ref.read(verseOfTheDayProvider.future);
    if (verse != null) {
      await HomeWidget.renderFlutterWidget(
        _VerseWidgetView(quote: verse, hi: hi),
        key: 'verse_widget',
        logicalSize: _widgetSize,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _verseProviderName);
    }
  } catch (_) {
    // Widgets are best-effort; never let a render failure break the app.
  }
}

/// Ask the launcher to pin the Panchang widget to the home screen.
Future<void> pinPanchangWidget(WidgetRef ref) async {
  if (!_widgetsSupported) return;
  await refreshHomeWidgets(ref);
  await HomeWidget.requestPinWidget(
      name: 'PanchangWidgetProvider',
      androidName: 'PanchangWidgetProvider',
      qualifiedAndroidName: _panchangProviderName);
}

/// Ask the launcher to pin the Verse-of-the-day widget to the home screen.
Future<void> pinVerseWidget(WidgetRef ref) async {
  if (!_widgetsSupported) return;
  await refreshHomeWidgets(ref);
  await HomeWidget.requestPinWidget(
      name: 'VerseWidgetProvider',
      androidName: 'VerseWidgetProvider',
      qualifiedAndroidName: _verseProviderName);
}

String _time(DateTime? d) {
  if (d == null) return '—';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
}

/// A wrapper giving rendered widgets text direction + a solid canvas.
class _Frame extends StatelessWidget {
  final Widget child;
  const _Frame({required this.child});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(size: _widgetSize, child: child),
      );
}

/// The Panchang widget — the two-panel reference layout at a fixed size.
class _PanchangWidgetView extends StatelessWidget {
  final Panchang p;
  final bool hi;
  final FestivalHit? festival;
  const _PanchangWidgetView(
      {required this.p, required this.hi, this.festival});

  static const _bg = Color(0xFFF7F5F2);
  static const _accent = Color(0xFFC97A3E);
  static const _ink = Color(0xFF3A2A20);
  static const _label = Color(0xFF9C8B79);
  static const _muted = Color(0xFFAD9C89);
  static const _line = Color(0xFFE2D8C7);
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _Frame(
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT
            Expanded(
              flex: 42,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _eyebrow(hi ? 'पंचांग' : 'PANCHANG'),
                    const SizedBox(height: 2),
                    Text('${now.day}',
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            height: 1.0,
                            color: _accent)),
                    Text(
                        '${hi ? p.vara(true) : _weekdays[now.weekday - 1]}, ${_months[now.month - 1]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _ink)),
                    const SizedBox(height: 5),
                    Text('${p.month(hi)} · ${p.paksha(hi)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _label)),
                    const SizedBox(height: 5),
                    Row(children: [
                      _mini(hi ? 'उदय' : 'RISE', _time(p.sunrise)),
                      const SizedBox(width: 14),
                      _mini(hi ? 'अस्त' : 'SET', _time(p.sunset)),
                    ]),
                    if (festival != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('🪔 ${festival!.name(hi)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(width: 1, color: _line),
            // RIGHT
            Expanded(
              flex: 58,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      _el(hi ? 'तिथि' : 'TITHI', p.tithi),
                      _el(hi ? 'नक्षत्र' : 'NAKSHATRA', p.nakshatra),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _el(hi ? 'योग' : 'YOGA', p.yoga),
                      _el(hi ? 'करण' : 'KARANA', p.karana),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eyebrow(String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 18, tile: false),
          const SizedBox(width: 6),
          Text(t,
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: _accent)),
        ],
      );

  Widget _mini(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: _label)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12, color: _ink)),
        ],
      );

  Widget _el(String label, PElement el) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: _label)),
            Text(el.current(hi),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _ink)),
            Text(
                el.endTime == null ? 'all day' : 'till ${_time(el.endTime)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: _muted)),
          ],
        ),
      );
}

/// The Verse-of-the-day widget — the terracotta hero card, fixed size.
class _VerseWidgetView extends StatelessWidget {
  final DailyQuote quote;
  final bool hi;
  const _VerseWidgetView({required this.quote, required this.hi});

  static const _on = Color(0xFFF7EFE6);

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC97A3E), Color(0xFF9C5A28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                (hi ? 'आज का श्लोक' : 'VERSE OF THE DAY').toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: _on.withValues(alpha: 0.82))),
            const SizedBox(height: 8),
            if (quote.sanskrit != null) ...[
              Text(quote.sanskrit!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: AppFonts.devanagari,
                      fontSize: 15,
                      height: 1.4,
                      color: _on)),
              const SizedBox(height: 4),
            ],
            Text(quote.text(hi),
                maxLines: quote.sanskrit != null ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: hi ? AppFonts.devanagari : AppFonts.display,
                    fontSize: 14,
                    height: 1.35,
                    color: _on)),
            const Spacer(),
            Row(
              children: [
                if (quote.source(hi) != null)
                  Expanded(
                    child: Text('— ${quote.source(hi)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _on.withValues(alpha: 0.85))),
                  )
                else
                  const Spacer(),
                const AppLogo(size: 24),
                const SizedBox(width: 6),
                Text(hi ? Brand.nameHi : Brand.name,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _on)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
