// Vimshottari Dasha — the 120-year planetary period system, computed from the
// Moon's nakshatra. Pure math (deterministic), verified against reference dates.

const _order = [
  'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury'
];
const _years = {
  'ketu': 7.0, 'venus': 20.0, 'sun': 6.0, 'moon': 10.0, 'mars': 7.0,
  'rahu': 18.0, 'jupiter': 16.0, 'saturn': 19.0, 'mercury': 17.0,
};
const _yearDays = 365.25;
const _total = 120.0;

DateTime _plusDays(DateTime t, double days) =>
    t.add(Duration(seconds: (days * 86400).round()));

class DashaPeriod {
  final String lord;
  final DateTime start;
  final DateTime end;
  const DashaPeriod(this.lord, this.start, this.end);
  double get days => end.difference(start).inSeconds / 86400.0;
}

/// Maha Dashas from birth (first one is the running balance).
List<DashaPeriod> mahaDashas(DateTime birthUtc, double moonSidereal) {
  final span = 360 / 27;
  final nak = (moonSidereal / span).floor() % 27;
  final frac = (moonSidereal % span) / span;
  final startIdx = nak % 9;
  final firstLord = _order[startIdx];

  final periods = <DashaPeriod>[];
  var t = birthUtc;
  // Balance of the first (running) maha dasha.
  final balance = _years[firstLord]! * (1 - frac);
  var end = _plusDays(t, balance * _yearDays);
  periods.add(DashaPeriod(firstLord, t, end));
  t = end;
  // Subsequent full maha dashas (two cycles cover any lifespan).
  for (var k = 1; k <= 12; k++) {
    final lord = _order[(startIdx + k) % 9];
    end = _plusDays(t, _years[lord]! * _yearDays);
    periods.add(DashaPeriod(lord, t, end));
    t = end;
  }
  return periods;
}

/// Sub-periods (antar / pratyantar) inside a period of [lord] spanning [days].
List<DashaPeriod> _subPeriods(String lord, DateTime start, double days) {
  final startIdx = _order.indexOf(lord);
  final out = <DashaPeriod>[];
  var t = start;
  for (var k = 0; k < 9; k++) {
    final sub = _order[(startIdx + k) % 9];
    final dur = days * _years[sub]! / _total;
    final end = _plusDays(t, dur);
    out.add(DashaPeriod(sub, t, end));
    t = end;
  }
  return out;
}

/// The nine antar-dashas (bhuktis) inside a maha-dasha.
List<DashaPeriod> antarDashas(DashaPeriod maha) =>
    _subPeriods(maha.lord, maha.start, maha.days);

class CurrentDasha {
  final DashaPeriod maha;
  final DashaPeriod antar;
  final DashaPeriod pratyantar;
  const CurrentDasha(this.maha, this.antar, this.pratyantar);
}

/// The Maha/Antar/Pratyantar dasha active at [at].
CurrentDasha currentDasha(
    DateTime birthUtc, double moonSidereal, DateTime at) {
  final mahas = mahaDashas(birthUtc, moonSidereal);
  final maha = mahas.firstWhere((p) => at.isBefore(p.end), orElse: () => mahas.last);
  final antars = _subPeriods(maha.lord, maha.start, maha.days);
  final antar =
      antars.firstWhere((p) => at.isBefore(p.end), orElse: () => antars.last);
  final praty = _subPeriods(antar.lord, antar.start, antar.days);
  final pratyantar =
      praty.firstWhere((p) => at.isBefore(p.end), orElse: () => praty.last);
  return CurrentDasha(maha, antar, pratyantar);
}
