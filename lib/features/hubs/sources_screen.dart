import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';

/// One licensed source: name, licence, and what it's used for.
class _Source {
  final String name;
  final String url;
  final String licenceEn;
  final String licenceHi;
  final String usedForEn;
  final String usedForHi;
  final bool attributionRequired;
  const _Source(this.name, this.url, this.licenceEn, this.licenceHi,
      this.usedForEn, this.usedForHi,
      {this.attributionRequired = false});
}

// Every entry here matches a row in `content/SOURCES.md`. Only sources whose
// content actually ships in the app are listed — the reference-only rows
// (Wikipedia, Wikidata, Gita Supersite) name what was checked against, never
// what was copied from.
const _sources = <_Source>[
  _Source(
    'OpenStreetMap',
    'https://www.openstreetmap.org/',
    'ODbL 1.0 — attribution required.',
    'ODbL 1.0 — उल्लेख अनिवार्य।',
    'Temple coordinates (latitude/longitude) only — no map tiles are rendered in this app; a temple opens in your own map app.',
    'केवल मंदिरों के निर्देशांक (अक्षांश/देशांतर) — इस ऐप में कोई मानचित्र टाइल नहीं दिखाई जाती; मंदिर आपके अपने मानचित्र ऐप में खुलता है।',
    attributionRequired: true,
  ),
  _Source(
    'data.gov.in',
    'https://data.gov.in/',
    'Government Open Data License — India (GODL). Attribution required.',
    'भारत सरकार मुक्त डेटा लाइसेंस (GODL)। उल्लेख अनिवार्य।',
    'Temple and tourism datasets.',
    'मंदिर एवं पर्यटन डेटासेट।',
    attributionRequired: true,
  ),
  _Source(
    'Wilson, Vishnu Purana',
    'https://archive.org/details/vishnupuranasys00wilsgoog',
    'Public domain (author d. 1860).',
    'सार्वजनिक डोमेन (लेखक निधन 1860)।',
    'Cosmology, yugas and dynastic lineage.',
    'सृष्टि-विज्ञान, युग और राजवंश-सूची।',
  ),
  _Source(
    'Ganguli, The Mahabharata',
    'https://archive.org/details/mahabharataofkri01ramauoft',
    'Public domain (published pre-1929, author d. 1908).',
    'सार्वजनिक डोमेन (1929 से पूर्व प्रकाशित, लेखक निधन 1908)।',
    'Complete 18-parva English translation.',
    'संपूर्ण अठारह पर्वों का अंग्रेज़ी अनुवाद।',
  ),
  _Source(
    'Dutt, The Ramayana',
    'https://archive.org/details/ramayanatranslat01valmuoft',
    'Public domain (published pre-1929).',
    'सार्वजनिक डोमेन (1929 से पूर्व प्रकाशित)।',
    'Prose translation of the Valmiki recension.',
    'वाल्मीकि रामायण का गद्य अनुवाद।',
  ),
  _Source(
    'Muller, The Upanishads',
    'https://archive.org/details/sacredbooksofeas01ml',
    'Public domain (author d. 1900).',
    'सार्वजनिक डोमेन (लेखक निधन 1900)।',
    'Principal Upanishads in English.',
    'प्रमुख उपनिषदों का अंग्रेज़ी अनुवाद।',
  ),
  _Source(
    'Telang, The Bhagavadgita',
    'https://archive.org/details/sacredbooksofeas08ml',
    'Public domain (published 1882).',
    'सार्वजनिक डोमेन (1882 में प्रकाशित)।',
    'Scholarly Gita translation.',
    'भगवद्गीता का शास्त्रीय अनुवाद।',
  ),
  _Source(
    'Rao, Elements of Hindu Iconography',
    'https://archive.org/details/elementsofhindui01raot',
    'Public domain (author d. 1919).',
    'सार्वजनिक डोमेन (लेखक निधन 1919)।',
    'Symbol Encyclopedia and deity iconography.',
    'प्रतीक-कोश एवं देव-प्रतिमा विज्ञान।',
  ),
  _Source(
    'Underhill, The Hindu Religious Year',
    'https://archive.org/details/hindureligiousye00undeuoft',
    'Public domain (published pre-1929).',
    'सार्वजनिक डोमेन (1929 से पूर्व प्रकाशित)।',
    'Festival calendar.',
    'पर्व-कैलेंडर।',
  ),
  _Source(
    'Gupte, Hindu Holidays and Ceremonials',
    'https://archive.org/details/hinduholidaysce00guptgoog',
    'Public domain (published pre-1929).',
    'सार्वजनिक डोमेन (1929 से पूर्व प्रकाशित)।',
    'Festival calendar.',
    'पर्व-कैलेंडर।',
  ),
  _Source(
    'Griffith, The Hymns of the Rigveda',
    'https://archive.org/details/hymnsofrigveda01grifuoft',
    'Public domain (author d. 1906).',
    'सार्वजनिक डोमेन (लेखक निधन 1906)।',
    'Rishi-to-sukta attributions.',
    'ऋषि-सूक्त संबंध।',
  ),
  _Source(
    'Wikidata',
    'https://www.wikidata.org/',
    'CC0 1.0 — no attribution legally required; credited anyway for traceability.',
    'CC0 1.0 — कानूनी रूप से उल्लेख अनिवार्य नहीं; फिर भी पारदर्शिता हेतु श्रेय दिया गया।',
    'Structural relationships between figures — never prose.',
    'पात्रों के बीच संरचनात्मक संबंध — कभी गद्य नहीं।',
  ),
];

/// Where every non-original piece of data in the app comes from, and what
/// each source's licence requires (TM-04 / RG-06). OpenStreetMap's ODbL
/// licence requires this specifically for the temple coordinates it
/// supplied — this screen is that attribution, not a map: no OSM tiles are
/// rendered anywhere in the app.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'स्रोत' : 'Sources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            hi
                ? 'यह ऐप स्वयं मूल पाठ नहीं लिखता। यहाँ हर तथ्य किसी सार्वजनिक-डोमेन अनुवाद या खुले डेटासेट से आता है, नीचे सूचीबद्ध। जिन स्रोतों को कानूनन उल्लेख चाहिए, वे सबसे ऊपर हैं।'
                : "This app does not write its own scripture. Every fact traces back to a public-domain translation or an open dataset, listed below. Sources whose licence legally requires attribution are listed first.",
            style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 18),
          for (final s in _sources) _SourceCard(source: s, hi: hi),
          const SizedBox(height: 18),
          _FontsCard(hi: hi),
          const SizedBox(height: 8),
          Text(
            hi
                ? 'पूरी सूची और हर विशिष्ट उद्धरण content/SOURCES.md में उपलब्ध है।'
                : 'The complete list, with every specific citation, is in content/SOURCES.md.',
            style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

/// Typography attribution (TY-03). All four bundled families are licensed
/// under the SIL Open Font License 1.1, which permits embedding in a shipped
/// app; the full licence text for each is in assets/fonts/LICENSES/.
class _FontsCard extends StatelessWidget {
  final bool hi;
  const _FontsCard({required this.hi});

  static const _fonts = <(String, String)>[
    ('Eczar', 'Rosetta Type Foundry'),
    ('Ramaraja', 'Silicon Andhra / Sorkin Type'),
    ('Inter', 'The Inter Project Authors'),
    ('Noto Sans Devanagari', 'The Noto Project Authors (Google)'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'फ़ॉन्ट' : 'Typefaces',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5)),
          const SizedBox(height: 6),
          Text(
            hi
                ? 'सभी चार फ़ॉन्ट SIL ओपन फ़ॉन्ट लाइसेंस 1.1 के अंतर्गत हैं, जो ऐप में एम्बेड करने की अनुमति देता है। पूर्ण लाइसेंस पाठ assets/fonts/LICENSES/ में है।'
                : 'All four are licensed under the SIL Open Font License 1.1, which permits embedding in this app. The full licence text for each is bundled at assets/fonts/LICENSES/.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 8),
          for (final (family, foundry) in _fonts)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('$family — $foundry',
                  style: TextStyle(fontSize: 13, color: scheme.onSurface)),
            ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final _Source source;
  final bool hi;
  const _SourceCard({required this.source, required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: source.attributionRequired
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(source.name,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5)),
              ),
              if (source.attributionRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hi ? 'उल्लेख अनिवार्य' : 'Attribution required',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(hi ? source.licenceHi : source.licenceEn,
              style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface.withValues(alpha: 0.65))),
          const SizedBox(height: 4),
          Text(hi ? source.usedForHi : source.usedForEn,
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: scheme.onSurface)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(Uri.parse(source.url),
                mode: LaunchMode.externalApplication),
            child: Text(source.url,
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.secondary,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
