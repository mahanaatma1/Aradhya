import 'package:flutter/services.dart';

/// Smart formatter for a "DD-MM-YYYY" birth date. As the user types digits it
/// auto-inserts the dashes AND prevents an impossible day (>31) or month (>12):
/// e.g. a leading day digit of 4-9 becomes "04"-"09", "35" is read as day 03 /
/// month 05, and a month first digit of 2-9 becomes "02"-"09".
class SmartDateFormatter extends TextInputFormatter {
  const SmartDateFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = _format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static String _format(String raw) {
    final ds = raw.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    var i = 0;

    // ---- DAY (01-31) ----
    var day = '';
    if (i < ds.length) {
      if (int.parse(ds[i]) > 3) {
        day = '0${ds[i]}';
        i++;
      } else {
        day = ds[i];
        i++;
        if (i < ds.length) {
          final two = int.parse('$day${ds[i]}');
          if (two >= 1 && two <= 31) {
            day = '$day${ds[i]}';
            i++;
          } else {
            day = '0$day'; // reconsume next digit as month
          }
        }
      }
      b.write(day);
    }

    // ---- MONTH (01-12) ----
    if (day.length == 2 && i < ds.length) {
      b.write('-');
      var mon = '';
      if (int.parse(ds[i]) > 1) {
        mon = '0${ds[i]}';
        i++;
      } else {
        mon = ds[i];
        i++;
        if (i < ds.length) {
          final two = int.parse('$mon${ds[i]}');
          if (two >= 1 && two <= 12) {
            mon = '$mon${ds[i]}';
            i++;
          } else {
            mon = '0$mon'; // reconsume next digit as year
          }
        }
      }
      b.write(mon);

      // ---- YEAR ----
      if (mon.length == 2 && i < ds.length) {
        b.write('-');
        var year = ds.substring(i);
        if (year.length > 4) year = year.substring(0, 4);
        b.write(year);
      }
    }
    return b.toString();
  }
}

/// Smart formatter for a 24-hour "HH:MM" birth time. Prevents an impossible
/// hour (>23) or minute (>59) while typing.
class SmartTimeFormatter extends TextInputFormatter {
  const SmartTimeFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = _format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static String _format(String raw) {
    final ds = raw.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    var i = 0;

    // ---- HOUR (00-23) ----
    var hour = '';
    if (i < ds.length) {
      if (int.parse(ds[i]) > 2) {
        hour = '0${ds[i]}';
        i++;
      } else {
        hour = ds[i];
        i++;
        if (i < ds.length) {
          final two = int.parse('$hour${ds[i]}');
          if (two <= 23) {
            hour = '$hour${ds[i]}';
            i++;
          } else {
            hour = '0$hour'; // reconsume next digit as minute
          }
        }
      }
      b.write(hour);
    }

    // ---- MINUTE (00-59) ----
    if (hour.length == 2 && i < ds.length) {
      b.write(':');
      var min = '';
      if (int.parse(ds[i]) > 5) {
        min = '0${ds[i]}';
        i++;
      } else {
        min = ds[i];
        i++;
        if (i < ds.length) {
          min = '$min${ds[i]}'; // second digit 0-9 always valid (0-59)
          i++;
        }
      }
      b.write(min);
    }
    return b.toString();
  }
}

const dateMask = SmartDateFormatter();
const timeMask = SmartTimeFormatter();

/// Parses "DD-MM-YYYY" (also accepts / or .) → DateTime, or null if invalid.
DateTime? parseBirthDate(String s) {
  final parts = s.split(RegExp(r'[-/.]'));
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null) return null;
  if (parts[2].length != 4) return null;
  if (y < 1900 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  if (dt.month != m || dt.day != d) return null; // rejects 31-02, 30-04, etc.
  return dt;
}

/// Parses "HH:MM" (24-hour) → (hour, minute), or null if invalid.
(int, int)? parseBirthTime(String s) {
  final parts = s.split(RegExp(r'[:.]'));
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final mi = int.tryParse(parts[1]);
  if (h == null || mi == null) return null;
  if (h < 0 || h > 23 || mi < 0 || mi > 59) return null;
  return (h, mi);
}

/// Inline error text for a date field (null while still typing or valid).
String? dateErrorText(String s, [bool hi = false]) {
  if (s.length < 10) return null; // DD-MM-YYYY not complete yet
  return parseBirthDate(s) == null
      ? (hi ? 'यह वैध तिथि नहीं है' : 'Not a real date')
      : null;
}

/// Inline error text for a time field (null while still typing or valid).
String? timeErrorText(String s, [bool hi = false]) {
  if (s.length < 5) return null; // HH:MM not complete yet
  return parseBirthTime(s) == null
      ? (hi ? 'यह वैध समय नहीं है' : 'Not a real time')
      : null;
}
