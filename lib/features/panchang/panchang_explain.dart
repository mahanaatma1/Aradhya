import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';

/// PN-01/PN-02: what a panchang element is, in plain language, and how it's
/// calculated -- plus, where one exists, the vidya topic id that goes deeper.
///
/// Deliberately category-level, not per-name: there are 30 tithis, 27
/// nakshatras and 27 yogas, each with its own lore, and writing that would be
/// a content-authoring project on the scale of the Knowledge Graph's rishi
/// work, not a UI feature. What this answers is the question a tap on any of
/// them is actually asking -- "what kind of thing is this, and where did the
/// number come from" -- which is one fixed explanation per category, always
/// true regardless of which of the 30/27/27 values today happens to show.
class PanchangExplanation {
  final String titleEn, titleHi;
  final String whatEn, whatHi;
  final String howEn, howHi;
  final int? vidyaTopicId;
  const PanchangExplanation({
    required this.titleEn,
    required this.titleHi,
    required this.whatEn,
    required this.whatHi,
    required this.howEn,
    required this.howHi,
    this.vidyaTopicId,
  });
}

// vidya_topics ids: 9 ayanamsa, 10 panchanga, 11 nakshatra-division.
const panchangExplanations = <String, PanchangExplanation>{
  'tithi': PanchangExplanation(
    titleEn: 'Tithi',
    titleHi: 'तिथि',
    whatEn:
        'A lunar day: the time it takes the Moon to gain 12° of ecliptic '
        'longitude on the Sun. A solar day is fixed by the clock; a tithi '
        'is fixed by the sky, so it runs a little short or a little long '
        'depending on how fast the Moon is moving that day.',
    whatHi:
        'एक चांद्र दिवस: वह समय जिसमें चंद्रमा सूर्य से 12° आगे बढ़ जाता है। '
        'सौर दिन घड़ी से नियत होता है; तिथि आकाश से — इसलिए यह चंद्रमा की गति '
        'के अनुसार कभी छोटी, कभी बड़ी होती है।',
    howEn:
        'Calculated as (Moon\'s longitude − Sun\'s longitude) ÷ 12°, rounded '
        'down. There are 30 tithis in a lunar month — 15 waxing (Shukla '
        'Paksha) and 15 waning (Krishna Paksha).',
    howHi:
        'गणना: (चंद्र-रेखांश − सूर्य-रेखांश) ÷ 12°, पूर्णांक तक। एक चांद्र मास में '
        '30 तिथियाँ होती हैं — 15 शुक्ल पक्ष में, 15 कृष्ण पक्ष में।',
    vidyaTopicId: 10,
  ),
  'nakshatra': PanchangExplanation(
    titleEn: 'Nakshatra',
    titleHi: 'नक्षत्र',
    whatEn:
        'One of 27 lunar mansions the Moon passes through in about a month '
        '— a fixed division of the sky, not a single star, each spanning '
        '13°20\' of the ecliptic.',
    whatHi:
        '27 नक्षत्रों में से एक, जिनसे चंद्रमा लगभग एक मास में गुजरता है — यह '
        'आकाश का एक नियत विभाजन है, अकेला तारा नहीं, प्रत्येक 13°20\' विस्तृत।',
    howEn:
        'Calculated from the Moon\'s sidereal longitude (its position '
        'against the fixed stars, corrected by the ayanamsa) divided by '
        '13°20\'.',
    howHi:
        'गणना: चंद्रमा के निरयण रेखांश (स्थिर तारों के सापेक्ष स्थिति, अयनांश '
        'द्वारा संशोधित) को 13°20\' से विभाजित करके।',
    vidyaTopicId: 11,
  ),
  'yoga': PanchangExplanation(
    titleEn: 'Yoga',
    titleHi: 'योग',
    whatEn:
        'One of 27 fixed divisions of the combined motion of the Sun and '
        'Moon — not the yoga of physical practice, but this panchang '
        'sense of the word: a joining of two quantities.',
    whatHi:
        'सूर्य और चंद्रमा की संयुक्त गति के 27 नियत विभाजनों में से एक — यह '
        'शारीरिक अभ्यास वाला योग नहीं, पंचांग का योग है: दो राशियों का योग।',
    howEn:
        'Calculated as (Sun\'s longitude + Moon\'s longitude) ÷ 13°20\', '
        'rounded down.',
    howHi:
        'गणना: (सूर्य-रेखांश + चंद्र-रेखांश) ÷ 13°20\', पूर्णांक तक।',
    vidyaTopicId: 10,
  ),
  'karana': PanchangExplanation(
    titleEn: 'Karana',
    titleHi: 'करण',
    whatEn: 'Half a tithi. Each tithi splits into two karanas.',
    whatHi: 'तिथि का आधा भाग। प्रत्येक तिथि दो करणों में बँटती है।',
    howEn:
        'Calculated the same way as tithi, but on a 6° step instead of '
        '12° — so a karana index runs from 0 to 59 across a lunar month, '
        'twice the tithi count.',
    howHi:
        'गणना तिथि जैसी ही है, पर 12° के बजाय 6° के चरण पर — इसलिए करण-सूचक '
        '0 से 59 तक चलता है, तिथि-संख्या से दोगुना।',
    vidyaTopicId: 10,
  ),
  'vara': PanchangExplanation(
    titleEn: 'Vara',
    titleHi: 'वार',
    whatEn: 'The weekday, each ruled by one of the seven classical '
        'planets (the five visible planets plus Sun and Moon).',
    whatHi:
        'सप्ताह का दिन, प्रत्येक सात शास्त्रीय ग्रहों में से एक द्वारा शासित '
        '(पाँच दृश्य ग्रह तथा सूर्य और चंद्रमा)।',
    howEn: 'Runs on the same seven-day cycle as the civil calendar; the '
        'names differ, the count does not.',
    howHi: 'नागरिक कैलेंडर के समान सात-दिवसीय चक्र पर चलता है; नाम भिन्न '
        'हैं, गणना नहीं।',
    vidyaTopicId: 10,
  ),
  'paksha': PanchangExplanation(
    titleEn: 'Paksha',
    titleHi: 'पक्ष',
    whatEn:
        'The fortnight: Shukla Paksha while the Moon waxes from new to '
        'full, Krishna Paksha while it wanes from full to new.',
    whatHi:
        'पखवाड़ा: अमावस्या से पूर्णिमा तक चंद्रमा के बढ़ने पर शुक्ल पक्ष, '
        'पूर्णिमा से अमावस्या तक घटने पर कृष्ण पक्ष।',
    howEn: 'Read directly from the tithi: tithis 1-15 are Shukla, 16-30 '
        'are Krishna.',
    howHi: 'तिथि से सीधे ज्ञात: तिथि 1-15 शुक्ल, 16-30 कृष्ण।',
    vidyaTopicId: 10,
  ),
  'month': PanchangExplanation(
    titleEn: 'Lunar month',
    titleHi: 'चांद्र मास',
    whatEn:
        'Named for the nakshatra the Moon is near at the month\'s full '
        'moon (in the Purnimanta system) or by which solar month (rashi) '
        'the new moon fell in (Amanta) — this screen\'s toggle switches '
        'between the two.',
    whatHi:
        'पूर्णिमा के समय चंद्रमा जिस नक्षत्र के निकट हो उसके नाम पर (पूर्णिमांत '
        'पद्धति), या अमावस्या जिस सौर मास (राशि) में पड़े उसके अनुसार (अमांत) — '
        'यह स्क्रीन दोनों के बीच टॉगल करती है।',
    howEn:
        'Amanta finds the most recent new moon before the date, then the '
        'solar rashi (sign) the Sun was in when that new moon happened. '
        'Purnimanta shifts the waning fortnight into the following '
        'month\'s name.',
    howHi:
        'अमांत उस तिथि से पूर्व निकटतम अमावस्या ढूँढ़ता है, फिर उस समय सूर्य '
        'जिस राशि में था वह लेता है। पूर्णिमांत कृष्ण पक्ष को अगले मास के नाम में '
        'खिसका देता है।',
    vidyaTopicId: 9,
  ),
  'muhurat': PanchangExplanation(
    titleEn: 'Muhurat',
    titleHi: 'मुहूर्त',
    whatEn:
        'A named window of the day held to be favourable or unfavourable '
        'for beginning something. Rahu Kala, Yamaganda and Gulika Kala '
        'are inauspicious; Brahma Muhurat (before sunrise) and Abhijit '
        '(around midday) are auspicious.',
    whatHi:
        'दिन का एक नामित काल जिसे किसी कार्य के आरंभ हेतु शुभ या अशुभ माना '
        'जाता है। राहुकाल, यमगंड और गुलिक काल अशुभ हैं; ब्रह्म मुहूर्त (सूर्योदय '
        'से पूर्व) और अभिजित (मध्याह्न के आसपास) शुभ हैं।',
    howEn:
        'The daylight span (sunrise to sunset) is split into eight equal '
        'parts; each inauspicious period occupies a fixed part of that '
        'span depending on the weekday. Abhijit is the fifteenth muhurta '
        '(1/15 of daylight) centred on midday, and is traditionally void '
        'on Wednesdays.',
    howHi:
        'दिन की अवधि (सूर्योदय से सूर्यास्त) को आठ बराबर भागों में बाँटा जाता '
        'है; प्रत्येक अशुभ काल सप्ताह के दिन के अनुसार एक नियत भाग में पड़ता '
        'है। अभिजित मध्याह्न-केंद्रित पंद्रहवाँ मुहूर्त है (दिन का 1/15), और '
        'परंपरा से बुधवार को शून्य माना जाता है।',
    vidyaTopicId: 10,
  ),
};

/// Opens a bottom sheet with the explanation, and a link into the vidya
/// topic if one is set. Call from any tap handler with the explanation key
/// (one of the keys in [panchangExplanations]).
void showPanchangExplanation(BuildContext context, WidgetRef ref, String key) {
  final exp = panchangExplanations[key];
  if (exp == null) return;
  final hi = ref.read(localeProvider).languageCode == 'hi';
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ExplanationSheet(exp: exp, hindi: hi),
  );
}

class _ExplanationSheet extends StatelessWidget {
  final PanchangExplanation exp;
  final bool hindi;
  const _ExplanationSheet({required this.exp, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              hindi ? exp.titleHi : exp.titleEn,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 22),
            ),
            const SizedBox(height: 14),
            Text(hindi ? 'क्या है' : 'WHAT IT IS',
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            Text(hindi ? exp.whatHi : exp.whatEn,
                style: const TextStyle(fontSize: 14.5, height: 1.5)),
            const SizedBox(height: 16),
            Text(hindi ? 'कैसे गणना होती है' : 'HOW IT\'S CALCULATED',
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            Text(hindi ? exp.howHi : exp.howEn,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: scheme.onSurface.withValues(alpha: 0.8))),
            if (exp.vidyaTopicId != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(hindi ? 'ज्योतिष विद्या में और पढ़ें' : 'Read more in Vidya'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/gyan/vidya/${exp.vidyaTopicId}');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
