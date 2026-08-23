import 'narrative_models.dart';

/// Epic -> Section -> Arc -> Event: the Story Cards hierarchy (SC-02/03),
/// assembled in memory from rows the epic providers already hold.
///
/// The arc columns are populated for every narrative row, so this is a fold
/// over a list rather than a second query. Nothing here talks to a database.

/// One section of an epic as the tradition counts them, whether or not we have
/// written anything in it yet.
///
/// A canonical roster is used instead of reading labels off the rows, because
/// deriving the section list from the data gets two things wrong:
///
///  * **A section with nothing in it cannot appear at all.** The Uttara Kanda is
///    the live case (SC-15): it holds no scenes, and dropping it would present
///    the Ramayana as a six-kanda work. Same for three Mahabharata parvas.
///  * **`book_label_hi` disagrees with itself in the shipped data.** Book 1 is
///    both `बाल कांड` and `बालकांड`; book 2 both `अयोध्याकांड` and `अयोध्या कांड`.
///    Two authoring batches spelled them differently. Grouping on the label
///    draws the same kanda twice under two spellings; grouping on `book_no`
///    with the label from here draws it once.
class EpicSection {
  final int no;
  final String titleEn;
  final String titleHi;

  /// A note the tradition itself carries about this section, shown as content.
  /// This is not our commentary on the text.
  final String? noteEn;
  final String? noteHi;

  /// Discourse rather than narrative. The Shanti and Anushasana parvas are
  /// Bhishma teaching dharma and governance from the bed of arrows (SC-14);
  /// forcing them into event cards would misrepresent what they are.
  final bool teaching;

  const EpicSection({
    required this.no,
    required this.titleEn,
    required this.titleHi,
    this.noteEn,
    this.noteHi,
    this.teaching = false,
  });

  String title(bool hi) => hi ? titleHi : titleEn;
  String? note(bool hi) => hi ? (noteHi ?? noteEn) : noteEn;
}

/// The seven kandas of the Valmiki Ramayana.
const ramayanaSections = <EpicSection>[
  EpicSection(no: 1, titleEn: 'Bala Kanda', titleHi: 'बाल कांड'),
  EpicSection(no: 2, titleEn: 'Ayodhya Kanda', titleHi: 'अयोध्या कांड'),
  EpicSection(no: 3, titleEn: 'Aranya Kanda', titleHi: 'अरण्य कांड'),
  EpicSection(no: 4, titleEn: 'Kishkindha Kanda', titleHi: 'किष्किंधा कांड'),
  EpicSection(no: 5, titleEn: 'Sundara Kanda', titleHi: 'सुंदर कांड'),
  EpicSection(no: 6, titleEn: 'Yuddha Kanda', titleHi: 'युद्ध कांड'),
  // SC-15. The note is a statement about the textual tradition, which is why
  // it is phrased as what traditions hold rather than as a verdict of ours.
  EpicSection(
    no: 7,
    titleEn: 'Uttara Kanda',
    titleHi: 'उत्तर कांड',
    noteEn: 'Counted among the seven kandas, and treated as a distinct '
        'traditional section: textual traditions and scholarly views differ on '
        'its place in the Ramayana.',
    noteHi: 'सात कांडों में गिना जाता है, और एक भिन्न पारंपरिक खंड के रूप में '
        'प्रस्तुत: रामायण में इसके स्थान पर पाठ-परंपराएँ और विद्वानों के मत '
        'भिन्न हैं।',
  ),
];

/// The eighteen parvas of the Mahabharata.
///
/// All eighteen are declared even though six carry no events yet, because the
/// shape of the work is itself information: a reader should be able to see that
/// the Ashvamedhika Parva exists and that we have not written it, rather than
/// be shown a twelve-parva Mahabharata.
const mahabharataSections = <EpicSection>[
  EpicSection(no: 1, titleEn: 'Adi Parva', titleHi: 'आदि पर्व'),
  EpicSection(no: 2, titleEn: 'Sabha Parva', titleHi: 'सभा पर्व'),
  EpicSection(no: 3, titleEn: 'Vana Parva', titleHi: 'वन पर्व'),
  EpicSection(no: 4, titleEn: 'Virata Parva', titleHi: 'विराट पर्व'),
  EpicSection(no: 5, titleEn: 'Udyoga Parva', titleHi: 'उद्योग पर्व'),
  EpicSection(no: 6, titleEn: 'Bhishma Parva', titleHi: 'भीष्म पर्व'),
  EpicSection(no: 7, titleEn: 'Drona Parva', titleHi: 'द्रोण पर्व'),
  EpicSection(no: 8, titleEn: 'Karna Parva', titleHi: 'कर्ण पर्व'),
  EpicSection(no: 9, titleEn: 'Shalya Parva', titleHi: 'शल्य पर्व'),
  EpicSection(no: 10, titleEn: 'Sauptika Parva', titleHi: 'सौप्तिक पर्व'),
  EpicSection(no: 11, titleEn: 'Stri Parva', titleHi: 'स्त्री पर्व'),
  EpicSection(
    no: 12,
    titleEn: 'Shanti Parva',
    titleHi: 'शांति पर्व',
    noteEn: 'Teachings rather than events: Bhishma on dharma and governance, '
        'from the bed of arrows.',
    noteHi: 'घटनाओं के बजाय उपदेश: शरशय्या से भीष्म का धर्म और राजनीति पर कथन।',
    teaching: true,
  ),
  EpicSection(
    no: 13,
    titleEn: 'Anushasana Parva',
    titleHi: 'अनुशासन पर्व',
    noteEn: 'Teachings rather than events: the instruction continues, and '
        'closes with Bhishma\'s passing.',
    noteHi: 'घटनाओं के बजाय उपदेश: शिक्षा जारी रहती है, और भीष्म के '
        'देहत्याग पर पूर्ण होती है।',
    teaching: true,
  ),
  EpicSection(no: 14, titleEn: 'Ashvamedhika Parva', titleHi: 'आश्वमेधिक पर्व'),
  EpicSection(no: 15, titleEn: 'Ashramavasika Parva', titleHi: 'आश्रमवासिक पर्व'),
  EpicSection(no: 16, titleEn: 'Mausala Parva', titleHi: 'मौसल पर्व'),
  EpicSection(
      no: 17, titleEn: 'Mahaprasthanika Parva', titleHi: 'महाप्रस्थानिक पर्व'),
  EpicSection(no: 18, titleEn: 'Svargarohana Parva', titleHi: 'स्वर्गारोहण पर्व'),
];

List<EpicSection> sectionsFor(String epic) =>
    epic == 'mahabharata' ? mahabharataSections : ramayanaSections;

/// What one section of this epic is called.
///
/// `book_no` is the column name. A reader who knows these works knows kandas and
/// parvas, so the chip that cuts an epic by section says the word the tradition
/// says.
String sectionWord(String epic, bool hindi) => epic == 'mahabharata'
    ? (hindi ? 'पर्व' : 'Parva')
    : (hindi ? 'कांड' : 'Kanda');

/// A run of events belonging to one movement of the story.
class StoryArc {
  final String slug;
  final String? titleEn;
  final String? titleHi;
  final int no;
  final List<NarrativeNode> events;

  const StoryArc({
    required this.slug,
    required this.no,
    required this.events,
    this.titleEn,
    this.titleHi,
  });

  String? title(bool hi) =>
      (hi && (titleHi?.isNotEmpty ?? false)) ? titleHi : titleEn;
}

/// One section with its arcs, ready to render.
class StorySection {
  final EpicSection section;
  final List<StoryArc> arcs;

  /// Set when this section is not in the canonical roster — see [buildStory].
  final bool unlisted;

  const StorySection({
    required this.section,
    required this.arcs,
    this.unlisted = false,
  });

  int get eventCount => arcs.fold(0, (n, a) => n + a.events.length);
  bool get isEmpty => eventCount == 0;

  String title(bool hi) => section.title(hi);
  String? note(bool hi) => section.note(hi);
  bool get teaching => section.teaching;
}

/// Groups [nodes] into the canonical sections of [epic], each holding its arcs.
///
/// [nodes] is expected in narrative order (`ORDER BY sequence_no`), which is
/// what the epic providers return; arc and event order follow from it.
///
/// **No event is ever dropped.** A row whose `book_no` is not in the roster —
/// or is null — is returned in a section of its own, flagged [unlisted], rather
/// than being filtered away. Content vanishing quietly is the exact failure
/// this repo has already suffered once, and a section list is not the place to
/// repeat it.
List<StorySection> buildStory(String epic, List<NarrativeNode> nodes) {
  final byBook = <int?, List<NarrativeNode>>{};
  for (final n in nodes) {
    byBook.putIfAbsent(n.bookNo, () => []).add(n);
  }

  final out = <StorySection>[];
  for (final section in sectionsFor(epic)) {
    out.add(StorySection(
      section: section,
      arcs: _arcsOf(byBook.remove(section.no) ?? const []),
    ));
  }

  // Anything left over kept its own label, since the roster has none for it.
  final leftover = byBook.keys.toList()
    ..sort((a, b) => (a ?? 1 << 30).compareTo(b ?? 1 << 30));
  for (final bookNo in leftover) {
    final rows = byBook[bookNo]!;
    out.add(StorySection(
      section: EpicSection(
        no: bookNo ?? 0,
        titleEn: rows.first.bookLabelEn ?? 'Unplaced',
        titleHi: rows.first.bookLabelHi ?? rows.first.bookLabelEn ?? 'अवर्गीकृत',
      ),
      arcs: _arcsOf(rows),
      unlisted: true,
    ));
  }
  return out;
}

/// Every arc of an epic, in narrative order (SC-13).
///
/// Sections come from a roster because an empty section is a fact about the work.
/// Arcs do not: an arc exists because events were written into it, so an arc with
/// nothing in it is not a gap to report but a filter with no results, and it is
/// simply not offered.
///
/// Arcs are merged by slug. Nothing in the shipped data spans two sections, but
/// were an arc ever authored across a section boundary, flattening [buildStory]
/// would offer it as two identically-labelled chips each filtering to half of
/// it — a filter giving a quietly wrong answer, which is worse than none.
List<StoryArc> allArcs(String epic, List<NarrativeNode> nodes) {
  final merged = <String, StoryArc>{};
  for (final section in buildStory(epic, nodes)) {
    for (final arc in section.arcs) {
      // Pre-SC-02 rows carry no arc and land in one untitled group. An unlabelled
      // chip is not a filter, so those events are reachable by section only —
      // which is what the gap line above the row is for.
      if ((arc.title(false) ?? '').isEmpty) continue;
      final have = merged[arc.slug];
      merged[arc.slug] = have == null
          ? arc
          : StoryArc(
              slug: arc.slug,
              no: have.no,
              titleEn: have.titleEn,
              titleHi: have.titleHi,
              events: [...have.events, ...arc.events],
            );
    }
  }
  return merged.values.toList();
}

/// Groups one section's events by arc, in `arc_no` order.
///
/// Rows written before SC-02 carry no arc. They are collected into a single
/// untitled arc so they still render, rather than being hidden behind a
/// grouping key they never had.
List<StoryArc> _arcsOf(List<NarrativeNode> rows) {
  if (rows.isEmpty) return const [];

  final groups = <String, List<NarrativeNode>>{};
  for (final n in rows) {
    groups.putIfAbsent(n.arcSlug ?? '', () => []).add(n);
  }

  final arcs = [
    for (final entry in groups.entries)
      StoryArc(
        slug: entry.key,
        no: entry.value.first.arcNo ?? 0,
        titleEn: entry.value.first.arcTitleEn,
        titleHi: entry.value.first.arcTitleHi,
        events: entry.value,
      ),
  ];

  // Ties keep the order the rows arrived in, so an arc with no number sits
  // where its first event sits rather than jumping to the front.
  arcs.sort((a, b) => a.no.compareTo(b.no));
  return arcs;
}
