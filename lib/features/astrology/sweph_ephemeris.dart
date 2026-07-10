import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

/// Swiss Ephemeris backend (arc-second precision, Lahiri sidereal). When it is
/// available it supersedes the built-in Schlyter approximation — this is what
/// makes navamsa (D9) reliable at cusps. If the native library can't load
/// (e.g. in headless `flutter test`), everything falls back to Schlyter.
///
/// Uses the Moshier ephemeris (SEFLG_MOSEPH) for planets so no planetary data
/// files are required; the small `seas_18.se1` asset is loaded for house/
/// ascendant maths (it's bundled with the sweph package).

bool _ready = false;
bool get swephReady => _ready;

/// Set to the initialisation error message when Swiss Ephemeris fails to load,
/// so we can surface *why* it fell back (shown on the Kundli screen).
String swephError = '';

class _RootBundleAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async =>
      (await rootBundle.load(assetPath)).buffer.asUint8List();
}

/// Initialise Swiss Ephemeris in Lahiri sidereal mode. Call once at startup.
/// Never throws — on failure we keep the Schlyter fallback and record why.
Future<void> initSwephEphemeris() async {
  if (_ready) return;
  try {
    final dir = await getApplicationSupportDirectory();
    await Sweph.init(
      epheFilesPath: '${dir.path}/ephe_files',
      epheAssets: const ['packages/sweph/assets/ephe/seas_18.se1'],
      assetLoader: _RootBundleAssetLoader(),
    );
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    _ready = true;
    swephError = '';
  } catch (e) {
    swephError = e.toString();
    _ready = false;
  }
}

double _rev(double x) => (x % 360 + 360) % 360;

double _jd(DateTime utc) {
  // [utc] already carries the UTC instant in its raw fields (BirthDetails.utc
  // is a non-UTC-flagged DateTime holding UTC values, matching dayNumber()).
  // Do NOT call .toUtc() — that would re-apply the device timezone offset.
  final hours = utc.hour +
      utc.minute / 60 +
      utc.second / 3600 +
      utc.millisecond / 3600000;
  return Sweph.swe_julday(
      utc.year, utc.month, utc.day, hours, CalendarType.SE_GREG_CAL);
}

final _flags = SwephFlag.SEFLG_SIDEREAL |
    SwephFlag.SEFLG_MOSEPH |
    SwephFlag.SEFLG_SPEED;

const _bodies = <String, HeavenlyBody>{
  'sun': HeavenlyBody.SE_SUN,
  'moon': HeavenlyBody.SE_MOON,
  'mars': HeavenlyBody.SE_MARS,
  'mercury': HeavenlyBody.SE_MERCURY,
  'jupiter': HeavenlyBody.SE_JUPITER,
  'venus': HeavenlyBody.SE_VENUS,
  'saturn': HeavenlyBody.SE_SATURN,
};

typedef GrahaRaw = ({String key, double sidereal, double tropical, bool retro});

/// Sidereal (Lahiri) longitudes for all nine grahas, or null if unavailable.
List<GrahaRaw>? swephGrahas(DateTime utc) {
  if (!_ready) return null;
  try {
    final jd = _jd(utc);
    final ayan = Sweph.swe_get_ayanamsa_ut(jd);
    final out = <GrahaRaw>[];
    _bodies.forEach((key, body) {
      final c = Sweph.swe_calc_ut(jd, body, _flags);
      final sid = _rev(c.longitude);
      final retro =
          key != 'sun' && key != 'moon' && c.speedInLongitude < 0;
      out.add(
          (key: key, sidereal: sid, tropical: _rev(sid + ayan), retro: retro));
    });
    // Rahu = mean node; Ketu is exactly opposite. The nodes are always
    // retrograde in Vedic astrology, so they're marked accordingly.
    final rahu = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MEAN_NODE, _flags);
    final rSid = _rev(rahu.longitude);
    out.add((key: 'rahu', sidereal: rSid, tropical: _rev(rSid + ayan), retro: true));
    final kSid = _rev(rSid + 180);
    out.add((key: 'ketu', sidereal: kSid, tropical: _rev(kSid + ayan), retro: true));
    return out;
  } catch (_) {
    return null;
  }
}

/// Sidereal ascendant (Lahiri) in degrees, or null if unavailable.
double? swephAscSidereal(DateTime utc, double lat, double lonEast) {
  if (!_ready) return null;
  try {
    final jd = _jd(utc);
    final h =
        Sweph.swe_houses_ex2(jd, SwephFlag.SEFLG_SIDEREAL, lat, lonEast, Hsys.W);
    return _rev(h.ascmc[0]);
  } catch (_) {
    return null;
  }
}
