/// Central place for the app's display identity. The internal Dart package is
/// still `divyavaani` (changing it would break every import), but everything
/// the user sees reads from here.
class Brand {
  Brand._();

  static const name = 'Aradhya';
  static const nameHi = 'आराध्य';

  /// The two-tone split used for the wordmark: "Ara" + "dhya".
  static const nameHead = 'Ara';
  static const nameTail = 'dhya';

  /// The Devanagari monogram shown inside the logo tile.
  static const monogram = 'आ';

  static const taglineEn = 'Devotion, every day';
  static const taglineHi = 'प्रतिदिन भक्ति';
}
