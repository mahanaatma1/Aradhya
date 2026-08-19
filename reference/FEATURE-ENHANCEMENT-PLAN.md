# Aradhya — Feature Enhancement Plan

**Feature by feature, not phase by phase.** One section per feature. Read the
one you are about to work on; you do not need the rest.

Supersedes the sequencing in `FEATURE-BUILD-PLAN.md`. That document is still
the reference for *architecture* (§1.x: the two-database split, the provenance
schema, the search index, the related-content engine, the module registry).
This one is the reference for *what each feature needs next*.

---

## How to read a feature section

Every feature below has the same seven fields, in the same order.

| Field | Meaning |
|---|---|
| **State** | What actually exists today, with counts read from the shipped databases |
| **Gap** | The specific thing wrong with it, not a wish |
| **Target** | What "done" means, in numbers where numbers apply |
| **Data** | Exactly where the content comes from, and under what licence |
| **Build** | The code work |
| **Effort** | S = a session · M = several · L = a week-plus of focused work |
| **Blocked?** | Only present when something outside the code stops it |

**Status key:** 🟢 solid · 🟡 works, needs depth · 🟠 foundation only ·
🔴 not built · ⚠️ release risk

---

## Decisions taken (2026-08-19)

Three questions were asked and answered. Everything below assumes them.

1. **Artwork → AI-generated**, with typography improved alongside. See
   [Artwork & Iconography](#artwork--iconography) for the conditions this
   places on you, which are real and non-optional for Play.
2. **Audio → deferred.** TTS remains the only voice. Every audio-dependent
   feature is marked 🔴 **Blocked** rather than planned, so nothing pretends
   to be schedulable that isn't.
3. **Scope → every feature, honestly graded**, including the ones I would
   advise against building.

---

## Corrections to the August 15 audit

The external audit was taken from the **15 Aug APK**. Substantial work has
shipped since, so these rows are out of date. Current reality:

| Audited as | Actually |
|---|---|
| 🔴 Mandir / Virtual Puja "not implemented" | **Built** — `lib/features/mandir/`, 727 lines, offerings + Kamal windows + streak |
| 🟠 Ramayana Journey "foundation" | **Built** — 32 scenes, vertical path, all with bilingual prose |
| 🟠 Mahabharata Timeline "foundation" | **Built** — 29 events + 18 war days, all with bilingual prose |
| 🟢 Dharma Game "foundation" | **Built** — hub, play screen, journal integration |
| 🟢 Ask Scriptures "foundation" | **Built** — retrieval, not-sure state, read-in-context |
| 🟢 Knowledge Journeys "foundation" | **Built** — 10 paths, 49 steps |
| 🟢 Related Content "foundation" | **Built** — 2,958 edges, rail on every detail screen |
| 🟡 Festivals "basic" | **Built** — Festival Explorer, 58 rule-based festivals, reminders |
| "510 entities, 578 relations" | 511 / 578 / 2,120 aliases — audit was accurate here |

The audit's **analysis** is sound even where its status column is stale, and
its source-licensing section is the most valuable part of it. Those verdicts
are absorbed into [Source registry](#source-registry--legal-verdicts) below.

---

## Source registry — legal verdicts

This table governs every "Data" field in this document. It merges our existing
`content/sources/registry.jsonl` with the audit's findings.

| Source | Verdict | Use for | Notes |
|---|---|---|---|
| **Wikidata** | 🟢 CC0 | Entity skeletons, relations, aliases, multilingual labels | Already the backbone. 511 entities came from here |
| **Internet Sacred Text Archive** | 🟢 PD works | Ganguli, Griffith, Wilson, Müller | Verify the *edition* is pre-1929, not just the host. 55 chapters fetched |
| **Wikimedia Commons** | 🟡 per-file | Images, if the AI route is ever reversed | Every file has its own licence. Prefer PD or CC-BY over CC-BY-SA |
| **Internet Archive** | 🟡 per-item | PD scans | Verify the specific item, never "archive.org = free" |
| **Project Gutenberg** | 🟡 per-work | PD texts | Status varies by jurisdiction; do not assume safe in India |
| **OpenStreetMap** | 🟡 ODbL | Temple coordinates | **Attribution required** and share-alike on derived data |
| **data.gov.in** | 🟡 GODL-India | Temple/tourism datasets | Attribution required |
| **sanskritdocuments.org** | 🔴 do not bulk-copy | Reference only | Per-document terms; Gita material is explicitly non-commercial |
| **GRETIL** | 🔴 do not use | Research only | Explicitly excludes commercial use |
| **Vedic Heritage Portal** | 🔴 do not scrape | Fact-checking only | Reproduction needs written permission |
| **Wikipedia** | 🔴 never paste | A lead to the primary text | CC BY-SA share-alike would infect our whole corpus |
| **vedabase.io** | 🔴 never | Nothing | © BBT, actively enforced |
| **drikpanchang.com** | 🔴 never | Nothing | Proprietary; we compute panchang ourselves |

**The pipeline rule, unchanged:** structure from Wikidata (CC0) → substance
from public-domain translations → *we* write the prose → cited → human
verified. AI rewrites and translates sourced material. AI never invents a
relation, a date, a lineage or a citation.

**One rule added this session:** never name the translator in user-facing
prose. Griffith, Ganguli and Wilson are provenance and already appear in the
source chip. "Griffith opens on a king" credits a Victorian Englishman with
Valmiki's choice. Name the text.

---

# Part 1 — The reading core

These three are the app's centre of gravity. Everything else connects to them.

## Scriptures & the Reader

**State** 🟡 · 27,890 sections across Gita, Upanishads, Valmiki Ramayana.
Sanskrit, transliteration, EN, HI, commentary all present. Reader works.
Reading progress and bookmarks-with-notes shipped.

**Gap** The reader is a page-turner sitting on top of the richest content in
the app, and it is a dead end. A verse knows nothing about the person in it,
the story around it, or the mantra drawn from it — even though `related_edges`
already holds 2,958 links and the entity graph holds 511 figures.

**Target** The reader becomes the place people stay. Verse → Sanskrit →
transliteration → meaning → explanation → **and then out** into the graph.

**Data** No new content needed for the structure. `relate.py` already emits
verse↔entity edges by alias match (weight 0.50); they are capped and unused
in the reader. Word-by-word meaning for the Gita is a separate authoring job —
see [Mantra Analyzer](#mantra-analyzer) for the same problem in miniature.

**Build**
- Tabs under the verse: **Meaning · Explanation · Word meaning · Context**
- `RelatedRail` at the bottom of the section reader (it is on every other
  detail screen and missing here, which is the single biggest connective gap)
- Verse actions row: bookmark · note · listen (TTS) · share text
- "Continue reading" already exists; add per-chapter progress rings
- Fix: word-meaning tab renders an honest empty state until data exists

**Effort** M (L if word-meaning authoring is included)

---

## Universal Search

**State** 🟢 · 33,245 documents, 20,207 terms, 433k postings. Folding handles
`krishna` / `kṛṣṇa` / `कृष्ण` identically. Kind filters, recents, deep links.

**Gap** UX polish only. The engine is the strongest single piece of
infrastructure in the app.

**Target** Search feels like the front door rather than a utility.

**Data** None. `index.py` derives everything at build time.

**Build**
- Group results by kind with counts, rather than one flat list
- Curated "Try" row driven by `importance`, not hardcoded
- Typo tolerance: one-edit-distance fallback when a query returns nothing
- Keep it 100% offline. **No voice search** — it needs Google speech services
  and would break the offline guarantee for one convenience

**Effort** S

---

## Related Content (the connective tissue)

**State** 🟢 · 2,958 edges. Per-kind cap added this session after Shiva's rail
came out as twelve temples and nothing else. Entity↔festival rule implemented.

**Gap** It is not everywhere yet. Missing from the **scripture reader**, the
**quiz answer screen**, **riddles** and **trivia** — which are exactly the
screens where a curious tap should lead somewhere.

**Target** Every detail screen in the app ends with "Continue exploring".

**Data** None. `relate.py` builds it.

**Build**
- Add `RelatedRail` to: section reader, quiz result, riddle answer, trivia card
- Extend `relate.py`: quiz/riddle/trivia → entity by alias (already capped at
  2 per source to control noise)
- **Before every release**, spot-check rails for: Krishna, Shiva, Rama,
  Hanuman, Durga, Devi, Indra, Ganesha, Vishnu, Lakshmi. The audit flags this
  and it is already in `RELEASE-CHECKLIST.md` §6

**Effort** S

---

# Part 2 — The knowledge system

## Knowledge Graph

**State** 🟠 · 511 entities, 578 relations, 2,120 aliases. Orbital layout,
animated re-centre, breadcrumbs. Panning fixed this session (`constrained:
false` — the canvas was being clipped, not panned).

**Gap** **285 of 511 entities have no relations at all**, and only 27 have
prose. The screen is good; the graph behind it is thin in patches. A tap onto
a minor deity shows a lone node.

**Target** Every entity with `importance ≤ 3` has at least three typed
relations and a real description. 1,200+ relations.

**Data**
- **Relations** — Wikidata (CC0). The existing pull used `P22/P25/P26/P40/P3373`.
  Add `P1080` (fictional universe), `P527` (has part), `P361` (part of),
  `P2789` (connects with), plus epic properties. Re-run `content/tools/wd_pull.py`
- **Prose** — public-domain texts already in `content/raw/` (55 chapters).
  Extend the `enrich_majors.py` pattern
- **Rule learned the hard way:** a chapter that *names* a figure is not a
  chapter *about* them. Bhishma's most frequent chapter in our corpus is the
  Gita section, where he is named but is not the subject

**Build**
- Filter chips by relation family (lineage / teaching / epic / place)
- Group the rail beneath the graph by family with headers
- Empty state when an entity has no edges — say so rather than showing a dot

**Effort** L (mostly content)

---

## Family Tree

**State** 🟠 · Projection of `relations`. Real genealogical brackets added this
session — stem, rail, drop per child, double line for marriage, siblings on a
rule rather than a descent bracket.

**Gap** 512 lineage edges exist but they cluster on the major dynasties. Deep
trees (Kuru, Ikshvaku) render well; most figures show two or three nodes.
Multi-generation layout is still one generation up and one down.

**Target** Five generations navigable. Twelve dynasties reachable from a picker.

**Data** Wikidata for the spine; Wilson's Vishnu Purana **Book IV is entirely
dynastic lists** and is the correct source for the Ikshvaku and Yadu lines.
Already fetched: `vp101`, `vp102`, `vp108` (Book IV chapters VIII, IX, XV).

**Build**
- Recursive layout to depth 3 with collapse/expand past 4 children
- `tradition` segmented control when edges disagree — the data model already
  carries it and no screen exposes it
- Long-press re-root works; add a breadcrumb so the walk is reversible

**Effort** M

---

## Srishty (Cosmology)

**State** 🟡 · 30 nodes across creation / loka / time_cycle / yuga. All 14
lokas now carry bilingual prose. Depth ladder added this session — spine,
node per world, filled above the earth, hollow below, ring on Bhuloka.

**Gap** The **8 creation stages have no long descriptions** (only the lokas
were done). The creation track is the philosophically richest part and the
thinnest on screen.

**Target** All 30 nodes with prose. Creation track reads as a genuine sequence.

**Data** Wilson's Vishnu Purana Book I, chapters II–III — **already fetched**
(`vp036`, `vp037`). The sarga sequence is laid out there directly.

**Build**
- Creation track: numbered stages on a connecting thread (the ladder painter
  already supports `numbered: true`)
- Keep the tradition note; the Patala ordering disagreement between Wilson and
  the Bhagavata is already surfaced and is a model for how to handle others

**Effort** S

---

## Yuga Explorer

**State** 🟢 · Rebuilt this session onto the app's paper-and-gold palette.
Proportional wheel, length bars, dharma as four quarters, zoom-out to
mahayuga/manvantara/kalpa, standing disclaimer.

**Gap** Only the four yugas have `dharma_ratio`. No linked events.

**Target** Each age links to narrative nodes set in it.

**Data** Vishnu Purana Book I ch. 3 (fetched) and Mahabharata Shanti Parva for
the durations and characteristics.

**Build** Link `cosmology_nodes` → `narrative_nodes` by tag; render a "what
happens in this age" row.

**Effort** S

---

## Rishis

**State** 🟠 · 20 rishis. **Only 2 have prose** (Vishvamitra, Vasishtha).
Others are one line each, 40–120 characters.

**Gap** The thinnest encyclopedia in the app.

**Target** 60–80 rishis, each with gotra, veda, guru, disciples, hymns, ashram,
and a real description.

**Data**
- **Roster + guru/disciple edges** — Wikidata `P31/P279* → Q755990`. Our pull
  found only 11; widen with `P1441` (present in work) against the Vedas
- **Hymn attribution** — Griffith's Rig Veda (PD). The rishi of each sukta is
  recorded in the tradition itself
- **Stories** — Mahabharata Adi Parva and the Puranas, already partly fetched
- **Honesty requirement from the audit, adopted:** label attributions "according
  to the cited tradition", never as historical fact

**Build** Teaching-lineage mini-tree on the detail screen (2-generation
projection of `guru_of`), ashram → place entity → map, hymn chips deep-linking
into the reader where the verse exists.

**Effort** L (content-bound)

---

## Astras (Weapons)

**State** 🟠 · Entities of `kind='weapon'` with `props.nature`. Wielders as
`wields` relations.

**Gap** Small set; `nature` (mythic/textual/symbolic) is populated but the
detail screen does not lead with it.

**Target** 70–100 astras.

**Data** Ganguli's Drona, Karna and Sauptika parvas are dense with astra
description — **`m07`, `m08` already fetched**. Bala Kanda's weapon-conferral
episode for the Ramayana side. Vishnu Purana for the ayudhas.

**Build** Weapon-type stripe on list rows; props card laid out as
Type · Invocation · Powers · Counter · Symbolism, with **Symbolism in its own
panel** so the mythic and the interpretive stay visually separate. Standing
footer: "Descriptions are from the epics and are mythic, not historical."

**Effort** M

---

## Symbols

**State** 🟡 · 12 symbols, **all now carrying a Unicode glyph** (was 1 of 8).
`meaning_varies_by` populated where true.

**Gap** Small set. Mudras and yantras absent entirely.

**Target** 60–80 symbols.

**Data** T. A. Gopinatha Rao, *Elements of Hindu Iconography* (1914–16, PD) is
the single best source and covers most of the list. Already in the registry.

**Build** The "Meanings vary" panel already exists and is the right pattern —
extend it. Grid stays glyph-led; where no codepoint exists, use a drawn motif
(the `GyanMotif` painter established this session) rather than bundled art.

**Effort** M

---

## Vidya (Vedic Science)

**State** 🟢 · 17 topics across six disciplines. Every one carries a mandatory
caution and an honest `modern_status`. Enforced four ways: schema, validate,
widget assert, unit test.

**Gap** Small set — and this is the one feature where that is **correct**.

**Target** 40–50, chosen for quality. Not 80.

**Data** PD editions: Vivekananda's Yoga Sutras (1896), Griffith's Rig Veda,
Shulba Sutra scholarship. **Never** present traditional medical claims as
treatment.

**Build** Nothing structural. The fixed section order ending in the caution
panel is correct and should not be reordered.

**Effort** M · **Quality over quantity — do not pad this one.**

---

# Part 3 — Narrative

## Ramayana Journey

**State** 🟢 · 32 scenes, seven kandas, all with bilingual prose. Vertical
dashed path, kanda banners, read/unread, continue pill. Kanda ordering fixed
and pinned by test.

**Gap** Uttara Kanda has one scene. No place-linked map view.

**Target** 45–50 scenes; every scene linked to a `place` entity.

**Data** Griffith (fetched, 13 cantos located by probing). Dutt's Ramayana for
cross-check. **Method note:** Griffith writes ś as the digraph `s'`
(`Vis'vámitra`) and usually calls Hanuman "the Vánar chief" — plain-name
scanning misses both. Probe by canto title, then verify.

**Build** The audit's location-journey idea is good and cheap: Ayodhya →
Mithila → Chitrakuta → Panchavati → Kishkindha → Lanka as a place filter over
the existing path.

**Effort** M

---

## Mahabharata

**State** 🟢 · 29 main events + 18 war days, all with bilingual prose. Vertical
path shared with the Ramayana. Four arcs, pinned by test. Kurukshetra
day-by-day grouped by commander.

**Gap** 29 events across 18 parvas. Shanti and Anushasana are one scene each.

**Target** 45–55 events; every parva represented.

**Data** Ganguli, fully available. 24 chapters fetched; the parva structure
makes it easy to find more by probing `m01`–`m18`.

**Build** Optional parva rail alongside the arc chips.

**Effort** M

---

## Stories & Katha

**State** 🟡 · 100 stories + **57 orphaned kathas**. `/katha` serves `stories`;
the katha table is not surfaced.

**Gap** 57 rows of content shipped in the APK and unreachable. This is free
content sitting unused.

**Target** Merged, categorised, entity-linked.

**Data** Already in `content.sqlite`.

**Build** Second section on the stories screen or a merged list with a
category chip. Then index them (they already are) and add `RelatedRail`.

**Effort** S · **Best value-per-hour in this document.**

---

# Part 4 — Practice & the personal

## Sadhana

**State** 🟡 · Hub exists with today-ring, practice rows, sparklines, heatmap,
goals, reminders. Japa, breathing, habits, reading and mandir all write
`sadhana_sessions`.

**Gap** The four practices still *feel* separate because their own screens are
unchanged and the hub is a layer above them.

**Target** The hub is where practice starts; the individual screens are where
it happens.

**Data** User's own.

**Build** Entry from Home; per-practice goal editing inline; milestone rail.

**Effort** S

---

## Karma Journal

**State** 🟢 · Prompt card, mood strip (drawn glyphs, not emoji), entry list,
month heatmap, lined editor, autosave, privacy statement.

**Gap** Prompt corpus is small.

**Target** 150–200 prompts, each cited to a verse.

**Data** Gita 2.47, 12.13, Yoga Sutra 1.33 etc. — PD translations already
fetched.

**Build** Nothing structural. **Never add sharing by default.**

**Effort** S

---

## Mandir / Virtual Puja

**State** 🟢 · **Built** (the audit has this as 🔴). Idol on shrine gradient,
offering bar, Kamal cost outside free windows, streak ring, sessions written.

**Gap** Single idol; offerings do not animate onto the image.

**Target** Ishta-deity aware, with the offering animation the plan specified.

**Data** Deity art — see [Artwork](#artwork--iconography). Currently
placeholder, so this feature is **gated on the same blocker as everything
visual**.

**Build** Offering fly-to-idol animation; aarti TTS playback already wired.

**⚠️ Audit's warning, adopted:** keep Punya/Kamal as optional gamification.
Never let a user pay real money for a virtual offering.

**Effort** S

---

## Pilgrimage Passport

**State** 🔴 · `temple_visits` table exists and records dates. No screen.

**Target** My Yatra: visited count, per-temple stamp, collections
(Char Dham, 12 Jyotirlinga, Shakti Peetha), note + rating per visit.

**Data** Temple metadata already in `content.sqlite` (187 rows). Collections
are a curation job over existing rows — no new content needed.

**Build** New screen; the write path already exists.

**Effort** M · **Highest-value unbuilt feature**, because the data is already
there.

---

# Part 5 — Calendar & astrology

## Panchang

**State** 🟢 · Own engine, Swiss Ephemeris. Three bugs fixed this session:
krishna-paksha Ekadashi naming, adhika-month labelling (Padmini/Parama), and
vriddhi tithi firing twice.

**Gap** Presentation is a data dump. Nothing explains what a tithi *is*.

**Target** Each element tappable → "what this is / how it is calculated".

**Data** Our own engine. **Never** drikpanchang.

**Build** Explanation sheets per element; link to the Jyotisha vidya topics
(`ayanamsa`, `panchanga`, `nakshatra-division` already written).

**Effort** S

---

## Calendar & the Wheel

**State** 🟡 calendar · 🔴 wheel.

**Target** A circular year: months around the ring, festivals as marks,
tap-to-month.

**Data** Computed.

**Build** `CustomPainter`. The Yuga wheel written this session is a working
template for proportional arcs and hit-testing.

**Effort** M

---

## Festival Explorer

**State** 🟢 · 58 festivals as **rules**, not dates. Upcoming + Browse,
one-off reminders, region field mandatory.

**Gap** 58 of a target 150. Onam and nakshatra-based festivals return no date
(honestly, rather than guessing).

**Target** 120–150; nakshatra rules implemented.

**Data** Underhill (1921) and Gupte (1919), both PD, both registered. Dates
always computed.

**Build** Nakshatra-within-solar-month resolution for Onam and Thiruvonam-type
rules. Story link → narrative node. Puja vidhi link.

**Effort** M

---

## Kundli, Milan & Rashifal

**State** 🟢 · Swiss Ephemeris, D1/D9, dashas, yogas, doshas, Ashtakoot 36.

**Gap** Two real ones:
1. **Milan does not ask which side is the bride and which the groom.** The
   inputs say "Side 1 / Side 2", and `_varna` is asymmetric — swapping the
   order can change the score. The code comment already admits "Side A is
   treated as the groom".
2. Interpretation is technical before it is human.

**Target** Explicit roles; plain-language summary above the technical detail.

**Data** Own computation. Rashifal content needs a quality pass and a clear
"traditional interpretation, not prediction" disclaimer.

**Build** Role selector on the Milan form. Consider adopting three ideas from
the South-Indian Porutham spec reviewed earlier: **Rajju as a critical flag**
(one factor that must never be averaged away), **birth-time accuracy** with a
boundary-risk check, and **partial ≠ matched** in the score display.

**Effort** M

---

# Part 6 — Discovery & play

## Quiz · Riddles · Trivia

**State** 🟢 content, 🟡 presentation · 4,000 quiz questions, 365 riddles,
565 trivia facts.

**Gap** All three are dead ends. A correct answer teaches nothing further.

**Target** Every question, riddle and fact links to the entity it is about.

**Data** Existing. Linking is a `relate.py` rule (already capped at 2 per
source because question text is noisy).

**Build** Explanation after each answer; `RelatedRail` on results; difficulty
and category filters for the quiz.

**Effort** S · **Second-best value-per-hour here.**

---

## Dharma Decision Game

**State** 🟢 · 12 scenarios, 36 choices. No scoring anywhere. Guna tags with
their meaning spelled out. Reflections write to the journal.

**Target** 50–60 scenarios.

**Data** Ganguli, Dutt, Telang — all fetched. Each scenario anchored to a real
dilemma.

**Build** Nothing structural. **Never add right/wrong.**

**Effort** M

---

## Ask the Scriptures

**State** 🟡 · 20 curated pairs, all pinned to a unique Gita verse. Retrieval,
explicit not-sure state, read-in-context. Three loader bugs fixed (bilingual
fold, tokenisation, verse-ref resolution).

**Gap** 20 pairs, and retrieval runs only over them — not over the 27,890
indexed verses.

**Target** 300–500 pairs; retrieval extended to `kind='shloka'`.

**Data** Curated Q&A written from PD translations.

**Build** Extend `AskRepository` to fall back to the shloka index when no
curated pair clears the threshold. **Never generate.** The "selected, not
generated" footer is the feature's whole integrity.

**Effort** L

---

## Knowledge Journeys

**State** 🟢 · 10 paths, 49 steps, progress, no locking.

**Target** 18–20 paths.

**Data** Curation over existing rows. Cheapest content in the app — the only
new writing is the one-line "why this step".

**Effort** S

---

# Part 7 — Temples

## Temple system

**State** 🟡 · 187 temples with coordinates, deity, significance. Map works.
`temples.data` carries 10–12 real source URLs and a confidence score per row.

**Gap** Detail page is thin next to the data behind it.

**Target** Hero → why visit → history → deity → architecture → festivals →
traditions → map → nearby → sources.

**Data**
- Existing `temples.data` (already parsed for source chips)
- **OpenStreetMap** for coordinates — **ODbL, attribution required in About**
- data.gov.in tourism datasets (GODL-India, attribution required)

**Build** Nearby-temples query by coordinate; festival link via
`deity_entity_id`; architecture section (below).

**Effort** M

---

## Temple Architecture

**State** 🔴

**Target** Nagara / Dravida / Vesara, and the parts: garbhagriha, mandapa,
shikhara/vimana, gopuram, prakara.

**Data** Gopinatha Rao (PD) covers iconography; architecture needs a separate
PD source — **to verify before authoring**.

**Build** A section inside Temples, not a separate module. Diagrams as drawn
paths (`CustomPainter`), consistent with the motif system.

**Effort** M

---

# Part 8 — Cross-cutting

## Artwork & Iconography

**⚠️ This is the release blocker.** 52 images in `assets/images/`, all flagged
`replace_before_ship`. `build.py --strict` refuses to produce a release build
while any remain — that gate is already enforced.

**Decision taken: AI-generated.** Proceeding as instructed. Three conditions
are not optional, because Play requires you to hold distribution rights:

1. **Use a generator whose terms grant commercial use and output ownership.**
   Check the specific plan you are on — several free tiers forbid commercial
   use outright.
2. **Record provenance per asset** in `assets/manifest.json`: tool, model,
   date, prompt. The manifest schema already exists and validate enforces it.
3. **No living artist's style, no real person's likeness, no existing logo.**

**Icon system.** Do not generate 30 unrelated icons. The audit's master-prompt
approach is right — one visual language, then per-module prompts.

**Note on what already exists:** the Gyan tiles now use **drawn vector motifs**
(`lib/features/gyan/gyan_motifs.dart`) — lotus, quartered wheel, bow, discus,
balance, conch. These need no licence, scale to any size, and take the tile's
colour. Keep them for iconography; use AI images for **deity and temple
artwork**, where photographic richness actually matters.

**Typography** (you asked for this explicitly). Current stack: Eczar (display),
Ramaraja (accent), Inter (UI), Noto Sans Devanagari (Hindi). Work needed:
- Devanagari needs ~15–20% more line-height than Latin; several dense screens
  are set to Latin metrics
- Establish a type scale rather than per-widget font sizes — sizes currently
  range 9.5–28 with no system
- Verify Ramaraja and Eczar licences permit embedding (both are OFL, but
  confirm and record it in the About screen)

**Effort** L

---

## Audio

**State** 🔴 **Blocked — deferred by decision.** `mantras.audio_url` is empty
on all 36 rows. No player dependency.

Affected and **not scheduled**: mantra audio, aarti/chalisa audio, Sanskrit
Pronunciation Trainer, Gita recitation.

TTS remains the only voice. When this is revisited, the only safe routes are
your own recordings, commissioned work with written rights, or a recording
whose *performance* is separately public domain — the text being ancient does
not make a modern recital free.

---

## Mantra Analyzer

**State** 🟠 · 36 mantras with text and translation.

**Gap** No word-by-word breakdown.

**Target** Per-word meaning, traditional context, associated deity, source.

**Data** Word-by-word Sanskrit is **authoring work**, not a fetch. Requires
someone who reads Sanskrit. **This needs your input: do you have a Sanskrit
reader available, or should this stay unbuilt?**

**Build** Word-chip layout; deity link; `RelatedRail`.

**Effort** M · partly blocked on the question above

---

## Home & Personalization

**State** 🟢 · Verse of the day, festival banner, discovery rails, streak.
Interest signals built with hard limits: ordering only, never visibility;
reset actually clears the table; empty profile leaves everything usable.

**Gap** Verse of the day still reads `daily_quotes` (**3 rows**) while `quotes`
holds **1,000**. The verse repeats every three days.

**Target** Rotate 1,000 by day-of-year.

**Data** Already shipped in the APK.

**Build** Repoint the provider. Ensure every quote carries source + attribution.

**Effort** S · **Fix this first. It is a one-line change with daily visible
impact.**

---

## Content integrity

**⚠️ Added this session after a real loss.** `extract.py --promote` regenerates
`core.jsonl` from `content/curation/`, and it **silently wiped prose written
directly into `core.jsonl`** — 22 of 27 enriched entities lost their
descriptions. Build green, validate clean, app quietly thinner.

**Rules now:**
1. Authored prose belongs in `content/curation/`, never in generated `data/`
2. `test/content_integrity_test.dart` enforces floors on entity prose, scene
   counts, graph density and bilingual coverage
3. Run it before every build, not just before release

---

# Part 9 — Release gate

Nothing ships until all of these are green. Detail in `RELEASE-CHECKLIST.md`.

| # | Item | State |
|---|---|---|
| RG-01 | `content.sqlite` replaced — Ishvarvaani fixture gone | 🔴 |
| RG-02 | `meta.data_source` no longer says "DEV FIXTURE" | 🔴 |
| RG-03 | All 52 placeholder images replaced, zero `replace_before_ship` | 🔴 |
| RG-04 | `reference/ishvarvaani-apk/` out of the shipped tree | 🔴 |
| RG-05 | `build.py --strict` passes | 🔴 (335 unverified rows) |
| RG-06 | `SOURCES.md` attribution rendered in About — incl. OSM/ODbL | 🔴 |
| RG-07 | `indexed_content_version` matches after any content swap | 🟢 |
| RG-08 | Privacy policy states journal/progress/interests stay on device | 🔴 |
| **RG-09** | **Run the app on a real device.** Nothing in this repo has ever been executed on hardware. The gzip DB inflate path carries 16 MB and has only run under `flutter test` | 🔴 |

---

# Suggested order (advisory, not a phase plan)

Work feature by feature. If you want a sequence, this is the value order:

1. **Verse of the day** — one line, daily impact
2. **Katha merge** — 57 rows of shipped content currently unreachable
3. **RelatedRail into the reader, quiz, riddles, trivia** — makes the app feel connected
4. **Milan bride/groom roles** — a wrong answer presented confidently
5. **Pilgrimage Passport** — data already exists
6. **Srishty creation prose** — source already fetched
7. **Entity relations + prose** — the biggest content lift, and the one that makes the graph real
8. **Artwork** — the actual release blocker
9. **Device run** — before any of it is trusted

---

## Open questions for you

1. **Sanskrit reader** — is one available for the Mantra Analyzer's
   word-by-word meanings and for verifying Devanagari register? Several
   features are quality-capped without one.
2. **AI image tool** — which one? I need to record it in the asset manifest and
   confirm its terms permit commercial distribution.
3. **Temple architecture source** — I have no verified PD source for Nagara /
   Dravida / Vesara descriptions. Do you have one, or should I research and
   propose options before authoring?
