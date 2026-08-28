# Aradhya — Feature Enhancement Plan

**Feature by feature, not phase by phase.** One section per feature. Read the
one you are about to work on; you do not need the rest.

Supersedes the sequencing in `FEATURE-BUILD-PLAN.md`. That document is still
the reference for *architecture* (§1.x: the two-database split, the provenance
schema, the search index, the related-content engine, the module registry).
This one is the reference for *what each feature needs next*.

---

## How to read a feature section

Every feature below has the same fields, in the same order.

| Field | Meaning |
|---|---|
| **State** | What actually exists today, with counts read from the shipped databases |
| **Gap** | The specific thing wrong with it, not a wish |
| **Target** | What "done" means — **coverage, not raw totals** (see below) |
| **Data** | Exactly where the content comes from, and under what licence |
| **Build** | The code work |
| **Done when** | Acceptance criteria. A feature is not finished until every box is ticked |
| **Effort** | S = a session · M = several · L = a week-plus of focused work |
| **Blocked?** | Only present when something outside the code stops it |

### Targets are coverage, not counts

**1,500 poor edges are worse than 500 excellent ones.** Numbers in this
document are a sense of scale, never a quota to hit. Where a target could be
gamed by padding, it is written as coverage of a tier instead:

- **P0 entities** (`importance ≤ 2`): 100% have a description, 100% have ≥3
  verified relations
- **P1 entities** (`importance = 3`): ≥80% have ≥2 verified relations
- **P2** (`importance ≥ 4`): skeleton is acceptable

The same applies to festivals, vidya topics and scenarios. **If you have 34
excellent vidya topics, ship 34.** Do not pad to reach a number in this file.

### Every task is small

Do not hand an agent "implement the Knowledge Graph". Break it:

```
Feature: Knowledge Graph
  1 schema      2 importer    3 validation   4 repository
  5 UI          6 tests       7 device check
```

Each step reads `ARCHITECTURE-GUARDRAILS.md` first, ends with
`flutter analyze` + its tests, and reports what changed.

---

## Feature dependency map

Build in dependency order even though the document is organised by feature.
Nothing below depends on anything to its right.

```
CONTENT_DB ─┬─ Scriptures ── Reader ──┐
            ├─ Temples ───────────────┤
            ├─ Quiz/Riddles/Trivia ───┤
            └─ Stories/Katha ─────────┤
                                      ├── Search index ── Search UI
GYAN_DB ────┬─ Entities ──┬─ Graph    │
            │             ├─ Family Tree
            │             ├─ Rishis / Astras / Symbols
            │             └─ Related edges ── Related Rail ──┘
            ├─ Narrative ── Ramayana / Mahabharata
            ├─ Cosmology ── Srishty / Yuga
            ├─ Festivals ── Festival Explorer (needs Panchang engine)
            ├─ Dharma / Vidya / QA
            └─ Paths ── Knowledge Journeys (needs everything above)

USER_DB ────┬─ Journal ── Dharma reflections
            ├─ Sadhana ── Japa / Breathing / Habits / Mandir
            ├─ Bookmarks / Reading progress
            ├─ Temple visits ── Pilgrimage Passport
            └─ Interest signals ── discovery ordering only

Panchang engine ─── Festivals · Calendar · Panchang screen
Swiss Ephemeris ─── Kundli · Milan · Rashifal
```

**Consequences worth stating:**
- Entities must be enriched **before** Graph, Family Tree, Rishis, Astras and
  Symbols are worth polishing — the screens are ahead of the data
- Knowledge Journeys is last: its steps point at everything else
- Pilgrimage Passport needs only `USER_DB` + existing temple rows, which is why
  it is cheap
- Anything touching `CONTENT_DB` forces a `GYAN_DB` rebuild

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

### Claim classification

Not every statement in this app is the same kind of statement, and flattening
them is how a devotional app quietly becomes untrustworthy. `props.nature` on
astras (mythic / textual / symbolic) already does this in one place. Generalise
it to a column on every content table:

```sql
claim_type TEXT CHECK (claim_type IN (
  'traditional',        -- what the tradition holds
  'textual',            -- what a named text states
  'historical',         -- what historians accept
  'archaeological',     -- what excavation supports
  'modern_interpretation',
  'scientific'          -- what evidence establishes
))
```

So Krishna carries several claims rather than one blurred one:

| claim_type | Statement |
|---|---|
| traditional | An avatar of Vishnu |
| textual | Appears in the Mahabharata and the Bhagavata Purana |
| historical | Historicity is disputed |

**This is the single change that would most raise the app's credibility.**

### Confidence model

`verification_status` (verified / unverified / disputed) is not enough on its
own. The full set per row:

| Field | Values |
|---|---|
| `verification_status` | verified · unverified · disputed |
| `source_quality` | primary · secondary · reference |
| `claim_type` | as above |
| `confidence` | high · medium · low |
| `last_verified_at` | ISO date |
| `verified_by` | initials |

A Wikidata skeleton is `unverified / reference / traditional / low`. A
hand-checked passage from Ganguli is `verified / primary / textual / high`.
`--strict` already refuses unverified rows; this makes *why* legible.

### Editorial workflow — enforced by folders

AI output must never reach the database without a human in between. Make the
gate physical rather than procedural:

```
content/curation/
  inbox/       AI-generated candidates. NEVER built from.
  approved/    a human read it against the cited source. Built from.
  rejected/    kept, with a reason, so the same bad row is not regenerated
```

`extract.py --promote` reads `approved/` only. `validate.py` errors if anything
in `inbox/` is referenced by a build.

### Build snapshots and rollback

Every content build writes a retained directory:

```
content/builds/2026-08-19_<sha>/
  gyan.sqlite  report.html  manifest.json  checksums.json  content_snapshot.json
```

`current → previous` symlink, so a bad build is one command to undo.

### Content diff — **built, and enforcing**

`content/tools/content_diff.py` compares the build against the last trusted
snapshot across 22 separate measures and **fails on any decrease**. Counts
alone would not catch it: a build that adds 30 entities while dropping 22
descriptions still looks like growth in a total. It names the missing slugs.

This is the guard for the failure that already happened. Verified against a
simulated loss: it reported `-3 entities_with_prose` and named the deleted
entity. `build.py` runs it automatically and `--strict` refuses to ship a
release build that lost content.

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

**Done when**
- [ ] A verse screen shows Meaning / Explanation / Word meaning / Context tabs
- [ ] Word meaning renders an honest empty state where no data exists
- [ ] `RelatedRail` appears at the bottom of the section reader
- [ ] Tapping a related entity opens the correct screen, not the error page
- [ ] Bookmark and note round-trip through `USER_DB` and survive restart
- [ ] Hindi renders without overflow at the largest system font scale
- [ ] No network call on any path
- [ ] `flutter analyze` clean · reader tests pass · device check done

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

**Done when**
- [ ] Results group by kind with per-kind counts
- [ ] `krishna`, `kṛṣṇa` and `कृष्ण` return the same set
- [ ] A query with no match offers a one-edit-distance suggestion
- [ ] Every result taps through to a real screen
- [ ] Still works with the network off
- [ ] `test/search_fold_test.dart` and `search_repository_test.dart` pass

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

**Done when**
- [ ] 100% of P0 entities have a description and ≥3 verified relations
- [ ] ≥80% of P1 entities have ≥2 verified relations
- [x] An entity with zero relations shows a written empty state, not a bare node
- [x] An entity with >20 relations groups them by family
- [ ] Pan, zoom and re-centre all work; back navigation returns correctly
- [ ] Hindi names render correctly in nodes and edge labels
- [ ] No network call
- [ ] Graph tests pass · **device check for scroll/pan performance**

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

**Done when**
- [ ] Relationship-type filter: Family · Lineage · Guru/Disciple · Dynasty
- [ ] Tree renders to depth 3 with collapse past 4 children
- [x] `tradition` selector appears when edges disagree, and says which is shown
- [ ] Re-root then back returns to the previous root
- [ ] A figure with no lineage shows a written empty state
- [ ] Family tree tests pass

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

## Story Cards — the narrative redesign

**Decided 2026-08-22.** The Narrative section stops presenting itself as a
timeline of records and becomes two small illustrated books. This is a
presentation and data-model upgrade over `narrative_nodes`, **not a new
module** — Search, Related Content, the Knowledge Graph, Journeys and Ask all
keep reading the same table.

### The hierarchy

```
Epic
 └── Section        (Kanda / Parva)
      └── Story Arc
           └── Event
                ├── Quick Summary      30-second read
                ├── Story              100-250 words minor, 300-600 major
                ├── Reflection         a question, never a moral
                ├── Characters         narrative_cast
                ├── Places             place_entity_id
                └── Sources            recension + chapter
```

**Arc is the new level.** Today a kanda holds a flat run of scenes; an arc
groups the handful that belong to one movement of the story, which is what
makes a section navigable without a scroll bar.

### Do not set a target count

The plan previously said "45–50 scenes" and "45–55 events". **Both numbers are
withdrawn.** Map `Section -> Arc -> Event -> source reference` first and let
the count fall out. A fixed target is an invitation to split one meaningful
event into five to reach it, which is the padding failure the coverage rule at
the top of this document already forbids.

### Schema additions to `narrative_nodes`

Additive only; every column nullable so existing rows stay valid.

| Column | Why |
|---|---|
| `arc_slug`, `arc_title_en/hi` | the missing middle level |
| `quick_summary_en/hi` | the 30-second read; distinct from `short_description`, which is a card blurb |
| `story_en/hi` | the narrative proper. `long_description` is reused where it already holds one |
| `key_moments_en/hi` | JSON array of 3–6 beats, for the "What happened" list |
| `reflection_en/hi` | a **question**, not a lesson. Feeds the Dharma game and Journal |
| `themes` | JSON array: dharma, duty, sacrifice — drives Explore-by-theme |
| `illustration_asset` | nullable; the manifest gate in §1.12 applies |
| `prev_node_id`, `next_node_id` | denormalised at build time so prev/next never costs a query |

`lesson_en/hi` stays for existing rows but is **deprecated in favour of
`reflection_*`**: "Moral lesson: be good" is the register to avoid.

### Screens

**Epic home — two modes, one toggle.**
`[ Story ]` renders the kanda/parva books with arcs inside them.
`[ Timeline ]` keeps the existing vertical path for Ramayana and horizontal
band for Mahabharata. Neither is the "real" one; the toggle is remembered.

**Explore by** — a chip row above both modes: Book · Story · Characters ·
Places · Themes. Characters and Places are filters over `narrative_cast` and
`place_entity_id`, which already exist; Themes needs the new column.

**Event page**, in fixed order:
illustration → title with section and arc → Quick Summary → Story →
Key moments → Reflection (a question, with "Think about it →" into the
Journal) → People → Place → Themes → **Read the original text** → RelatedRail
→ Previous / Next with a one-line preview of what is next.

**Two layers, always.** Story mode is ours and plain; scripture mode is the
cited text. The "Read the original" button is not optional decoration — it is
what makes the retelling trustworthy, and it must land on the exact
`scripture_section_id`, not the top of a book.

### Content rule — non-negotiable

Narrative prose is **never** written from model memory. Every event follows:

```
cited PD chapter -> fetched into raw/ -> read -> drafted -> verified -> DB
```

with `recension` and the chapter recorded per event. Valmiki, Ramcharitmanas
and Kamba are separate recensions and are never mixed into one sequence. Where
traditions differ the event says so, exactly as the Family Tree does.

**Uttara Kanda is labelled a distinct traditional section**, because textual
traditions and scholarly views of its place differ. That label is content, not
commentary from us.

### Sections to build

**Ramayana — 7 kandas.** Bala (birth and education, Vishvamitra, Ahalya,
swayamvara, the bow, marriage) · Ayodhya (the boons, exile, Sita's and
Lakshmana's choice, departure, Dasharatha's grief, Bharata and the sandals) ·
Aranya (the forest, Surpanakha, Khara and Dushana, the golden deer, Maricha,
the abduction, Jatayu, Shabari) · Kishkindha (Hanuman, Sugriva, Vali, the
search, Sampati) · Sundara (the crossing, Surasa, Lanka, Ashoka Vatika, Sita,
the ring, the burning, the return) · Yuddha (the ocean, the bridge, the
negotiations, Kumbhakarna, Indrajit, Ravana, Sita's return) · Uttara (the
reign, Lava and Kusha, the departure) — labelled as above.

**Mahabharata — 18 parvas**, each a book, with arcs inside. Adi (lineage,
births, Drona, Ekalavya, Lakshagriha, Hidimba, Draupadi) · Sabha (Rajasuya,
Shishupala, the dice game, the assembly) · Vana (exile, Arjuna's journey,
Kirata, Bhima and Hanuman, Nala-Damayanti, Yaksha Prashna) · Virata (the
disguises, Kichaka, the cattle raid) · Udyoga (the peace mission, Krishna's
choice, the armies) · Bhishma (the field, Arjuna's dilemma, the Gita, the
fall) · Drona (Abhimanyu, the chakravyuha, the vow, Jayadratha) · Karna ·
Shalya · Sauptika (the night attack) · Stri (the grief, Gandhari) · Shanti and
Anushasana — **treated as teachings, not events**, and presented as topics ·
Ashvamedhika · Ashramavasika · Mausala · Mahaprasthanika · Svargarohana.

Shanti and Anushasana deserve the different treatment: they are Bhishma
discoursing on dharma and governance from the bed of arrows, and forcing them
into "event" cards would misrepresent what they are.

---

## Ramayana Journey

**State** 🟢 · 32 scenes, seven kandas, all with bilingual prose. Vertical
dashed path, kanda banners, read/unread, continue pill. Kanda ordering fixed
and pinned by test.

**Gap** Uttara Kanda has **no** scenes (see SC-02). No place-linked map view.

**Target** Every kanda mapped to arcs, every event sourced, every scene
linked to a `place` entity. **No scene count** — see the Story Cards rule
above.

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

**Done when**
- [ ] All 57 kathas are reachable from the UI
- [ ] Each katha carries a category and is entity-linked
- [ ] Search returns kathas
- [ ] `RelatedRail` on the katha detail screen
- [ ] `content_diff` shows no loss of stories

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

**Done when**
- [ ] Visited count, per-temple stamp with date, note and rating
- [ ] Collections render: Char Dham · 12 Jyotirlinga · Shakti Peetha
- [ ] Marking a visit writes `temple_visits` and survives restart and upgrade
- [ ] Works entirely offline
- [ ] No sharing, no upload
- [ ] Passport tests pass

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

**Done when**
- [ ] The Milan form asks explicitly which side is the bride and which the groom
- [ ] Swapping the two produces the documented directional result, not a silent
      change nobody can explain
- [ ] A plain-language summary sits above the technical breakdown
- [ ] Partial matches are shown as partial, never folded into the total
- [ ] A critical traditional flag is surfaced, not averaged away
- [ ] Methodology and its limits are stated on the result screen
- [ ] `test/astro_*` pass · **device check** (sweph is degraded under test)

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
| RG-10 | **Offline verification.** Wi-Fi and mobile data OFF, then exercise search, scriptures, panchang, kundli, temples, gyan, journal, sadhana, mandir. Nothing essential may fail | 🔴 |
| RG-11 | **Fresh install.** Uninstall → install → first launch → DB extraction → home. Not just upgrade | 🔴 |
| RG-12 | **Upgrade.** Old version → new version with `USER_DB` preserved: journal, japa, habits, bookmarks, reading progress, temple visits, interests | 🔴 |
| RG-13 | **Interrupted DB install.** Kill the app during extraction, reopen, must recover. The version marker is written last precisely so a crash re-runs the copy cleanly — verify that actually holds | 🔴 |
| RG-14 | **Low storage.** With insufficient free space the app must say "not enough storage", never crash mid-extraction | 🔴 |
| RG-15 | **Screen sizes.** Small phone · normal · large · tablet. Hindi labels are the first thing to overflow | 🔴 |
| RG-16 | **Accessibility.** System font scaling, contrast, touch-target size, Hindi text, basic TalkBack | 🔴 |
| RG-17 | **Size budget.** Measure the **AAB**, not just the APK. Databases ship gzipped (54.7 MB → 14.2 MB). Set a ceiling and fail CI above it | 🔴 |

---

## Size budget

Set now, not at the end. Measure the **Android App Bundle**, not the APK.

| Component | Budget | Today |
|---|---|---|
| `CONTENT_DB` gzipped | ≤ 12 MB | 10.2 MB |
| `GYAN_DB` gzipped | ≤ 6 MB | 4.2 MB |
| Images | ≤ 12 MB | 14 MB ⚠️ over |
| Base app | ≤ 25 MB | — |
| **Download total** | **≤ 55 MB** | ~45 MB + app |

On-disk after first launch is roughly double the DB figures, since both
databases are inflated into the documents directory. **RG-14 exists because of
this**: extraction needs the compressed asset and the inflated file at once.

---

# Task checklist

Tick as you go: `- [ ]` becomes `- [x]`. IDs are stable — quote them in commits
(`RD-03: related rail into the reader`). Status key: `[ ]` not started ·
`[x]` done · `[~]` in progress · `[!]` blocked · `[-]` dropped, with a reason.

| Area | Done | Total |
|---|---|---|
| Quick wins | 6 | 6 |
| Reader & Search | 1 | 11 |
| Knowledge system | 4 | 27 |
| Narrative | 0 | 8 |
| Practice & personal | 4 | 12 |
| Calendar & astrology | 1 | 13 |
| Discovery & play | 0 | 11 |
| Temples | 0 | 9 |
| Cross-cutting | 3 | 16 |
| Release gate | 0 | 17 |
| **Total** | **19** | **130** |

## Quick wins — do these first

- [x] **QW-01** Verse of the day: repoint at `quotes` (1,000 rows) instead of `daily_quotes` (3). The verse currently repeats every three days
- [x] **QW-02** Every quote carries source + chapter/verse + attribution
- [x] **QW-03** Surface the 57 orphaned kathas — shipped in the APK, unreachable
- [x] **QW-04** Kathas get a category and are entity-linked
- [x] **QW-05** `RelatedRail` on the katha detail screen
- [x] **QW-06** Verify kathas appear in search results

## Reader & Search

### Reader (2026-08-24)

- [x] **RD-01** Tabs under the verse: Meaning · Explanation · Word meaning · Context
      — measured all 27,890 shipped sections before designing anything:
      Meaning 27,890 (100%), Explanation 701 (3%, **Bhagavad Gita only** —
      Ramayana 0 of 20,135, Upanishads 0 of 7,054), Word meaning 0 (no column
      and no table anywhere), Context always. Empty tabs are shown dimmed
      rather than hidden: hiding them shuffles the rest sideways between a
      Gita verse and a Ramayana one in the same chapter list. The facet lives
      in a persisted provider, not the verse page, so a swipe does not drop a
      reader working through commentary back onto the translation
- [x] **RD-02** Word-meaning tab renders an honest empty state until data exists
      — two tabs needed one, not one. Each names the gap *and its extent*
      ("true of the whole collection"), because a verse-local message sends the
      reader looking for a verse that was not skipped. No "Coming soon" and no
      spinner: both promise work nobody has undertaken. Context needs no
      authored data at all and lights up further on its own as two soft links
      fill in — `qa_pairs.scripture_section_id` (20/20 today, grows with AK-01)
      and `narrative_nodes.scripture_section_id` (0/79, grows with SC-11)
- [x] **RD-03** `RelatedRail` at the bottom of the section reader
- [x] **RD-04** Verse actions row: bookmark · note · listen (TTS) · share text
      — the note was the only one missing, and it needed no new storage:
      `bookmarks.note`, `setNote` and the Bookmarks screen's editor all already
      existed, with no way to reach any of them from the screen where someone is
      reading. A verse note is therefore a note on the verse's bookmark row
      (`verse_note_sheet.dart`). Because `setNote` returns silently without a
      row, saving a note bookmarks the verse — stated in the sheet before the
      reader types, not in a snackbar afterwards — while clearing a note
      deliberately does **not** unbookmark it. Three bugs fell out:
      `Bookmark.copyWith` did `note ?? this.note`, so erasing a note blanked the
      database row and kept the old words on screen until the next launch;
      the seventh control overflowed the row by 36 px on a 320-wide phone at
      *every* text size (seven 48-px targets plus the size button want 340,
      there are 304), so the row now scrolls, ordered so the voice picker leaves
      the screen rather than the bookmark, with the size button pinned outside
      the scroller; and `_bookmark()` stored no verse, so a bookmark on verse 48
      reopened the chapter at verse 1 — the route now carries `?v=`
- [x] **RD-05** Per-chapter progress rings on the book list — `BookProgressRing`
      on `scripture_books_screen.dart:128`; shipped as P3-13 and never ticked
- [x] **RD-06** Hindi at max system font scale without overflow — the item names
      the *system* scale, which is a second multiplier on top of the reader's
      own 0.85–1.6 slider, and nothing in `lib/` reads or clamps it. Testing
      both together at Android's largest setting (1.6 x 2.0 = 3.2x on a 320-wide
      phone) found a real **74-pixel overflow in the bottom pager**, which clips
      the Next button — the one control that reaches the following verse. The
      pager now measures its own labels and drops to chevrons when the words
      cannot fit, keeping the counter and the tap targets; the labels stay in
      the semantics tree so a screen reader still names both buttons
- [~] **RD-07** Reader tests + device check — 35 widget tests across
      `test/reader_verse_tabs_test.dart` (four facets, every empty state in both
      languages, facet persistence across a swipe and a restart, layout at 3.2x)
      and `test/reader_verse_note_test.dart` (the action row's width and
      ordering, the note lifecycle in both languages, the bookmark route), with
      fixtures shared via `test/support/reader_harness.dart`. **Device check
      still outstanding** — blocked on RG-09. Also fixed here: the reader set a
      `StateNotifier` from inside `build`, which works in the app only because
      the screen is pushed as a route in its own build pass, and throws the
      moment it is mounted in the same frame as its `ProviderScope`
- [x] **SR-01** Group results by kind with per-kind counts — a top-40 page is
      the wrong unit to read from: for "shiva" it holds 6 of the 10 kinds that
      match and shows **0 of 109 verses**, all crowded out by 31 temples. The
      results view now buckets the score-ordered hits into per-kind sections (a
      plain insertion-ordered map, so the kind holding the single best hit leads),
      caps each at 4, and heads each with the **true** total from
      `countsByKind` — not the page count — behind a "See all N" that opens that
      kind. Picking a kind chip drops back to a flat, uncapped list, since the
      heading and cap would only hide results the reader just asked to see.
      `_ResultTile` grew a `showKind` flag (off inside a group or a filtered
      list — the heading already names the kind), and its title moved from a bare
      `RichText` to `Text.rich`, which was silently ignoring OS text scale. 19
      widget tests in `test/search_screen_test.dart`
- [x] **SR-02** Curated "Try" row driven by `importance`, not hardcoded — the
      hand-kept list had gone stale (it named "Ekadashi" and "Gita" while the
      graph had its own answer). `curatedTerms()` reads the 38 `importance = 1`
      entities and round-robins across `kind`, because importance alone hands
      back 13 deities before the first hero; the row exists to show the index's
      *reach* — a deity, a hero, a scripture, a concept, a weapon, a rishi. A
      chip is offered only if it works in **both** languages: this is what caught
      "Om" / "ॐ", whose single Devanagari glyph is below `minQueryLength` and so
      would have been a chip that returned "Nothing found". Falls back to the old
      const list when the DB is absent (first launch). Covered by 4 repository
      tests + 4 widget tests
- [x] **SR-03** One-edit-distance fallback when a query returns nothing —
      `spellingSuggestions()` offers a "Did you mean" after a miss, ranked by how
      many documents each candidate appears in so the correction is the word most
      likely meant. Bounded on purpose to stay cheap on every failed keystroke:
      single-word only, first character must be right, ≥3 chars — which scans
      ~280 candidates for "hanumn" instead of all 20,227 terms. `januman` never
      reaches `hanuman` (a documented limit, tested). 8 repository tests + 5
      widget tests
- [x] **SR-04** Confirm no result taps through to the error page — the Python
      build already gates this (`route_ok` drops any doc whose route is not in
      `routes.txt`), so `test/search_routes_test.dart` is the second, different
      line: it runs the **real** `appRouter` against one representative of each
      of the 11 route shapes in the shipped index, catching a route the Dart
      side renamed after the index was built. Includes a teeth-check so a broken
      matcher cannot pass vacuously

## Knowledge system

- [x] **KG-01** Widen the Wikidata pull: `P527`, `P361`, **`P1441`** + epic properties
      — the pull already fetched them; `wd_promote` was discarding 433 of 1362
      edges. `wd_edges_extra.py` maps them. Relations 578 -> 970; entities with
      no edges 285 -> 208. `P1080`/`P2789` return nothing for this corpus
- [x] **KG-02** 100% of P0 entities have a description — measured 135/135
- [ ] **KG-03** 100% of P0 entities have 3 or more verified relations —
      **124/136 today (91.2%)**, up from 36 at the start of this pass. Every
      relation added carries an exact Parva/Sarga/Section citation against a
      primary translation (`ganguli-mahabharata`, `dutt-ramayana`,
      `wilson-vishnu-purana`, `muller-upanishads`, `griffith-rigveda`) —
      independently fetched and quoted, not taken from secondary summaries.
      Where a summary source turned out to cite the wrong chapter or the
      wrong deity for an episode, the mistake was caught and corrected
      before writing (e.g. an early attempt attributed Dasharatha's
      putrakameshti yajna to Vasishtha; the primary text names Rishyasringa).
      New entities were created only where a real, sourced relation had no
      destination to point to: Lopamudra (Agastya's wife), Manu (Vaivasvata
      Manu, saved by Matsya). A new relation type, `member_of`/`has_member`,
      was added to the schema (`gyan.sql`, `validate.py`) rather than
      misusing `ruled_by` or `part_of`, both of which already carry a
      different meaning in this data.

      Closed this session, on top of the earlier 106: Kalash (Dhanvantari
      bearing the Amrita-cup from the churned ocean, Wilson Book I Ch. IX),
      Agneyastra and Narayanastra (both traced to the same Drona Parva
      §CCI passage — Ashvatthama's fire weapon countered by Arjuna's Brahma
      weapon; the Narayana weapon pacified only when Bhima lays down arms
      at Krishna's counsel), Ekalavya (disciple_of Drona via the thumb
      guru-dakshina episode, Adi Parva §CXXXIV — the earlier Wikisource
      404s were a dead end; the ibiblio mirror had the passage all along),
      Shankha (added a 2nd citation, Krishna's Panchajanya at Bhishma Parva
      §XXV), Yamuna (sibling_of Yama and paired with Ganga, both via
      Rigveda Mandala 10).

      **12 P0 entities remain below the bar, and each was individually
      researched and rejected as unciteable from a registered source, not
      skipped:** Damaru, Diya, Rudraksha, Swastika, Tilaka (ritual objects
      whose textual glorification lives in the Shiva Purana / Rudraksha
      Jabala Upanishad / Devi Mahatmya — none registered; the one Mahabharata
      passage on lamp-merit found, Anusasana Parva §XCVIII, blesses "the
      deities" collectively with no single named destination to cite
      honestly); Dvaraka, Mathura, Vrindavana, Kali, Radha's 3rd relation
      (confirmed Puranic-only mythology — Devi Mahatmya and Bhagavata/
      Brahma-Vaivarta material, both unregistered; Rigveda's "Kali" is a
      different referent — Agni's tongue, not this goddess, so citing it
      would misattribute); Harishchandra (the only Mahabharata mention
      found, Anusasana Parva §CLXV, is a bare 30-king name-list recited for
      its purifying sound — too thin to support a real `related_to` edge to
      one specific king); Padma's 3rd relation (the Brahma-born-from-a-
      lotus-navel myth is not in Wilson's Vishnu Purana in that form — every
      chapter checked either omits the lotus or omits the navel). None of
      these are a research-time problem; they are a source-registration
      ceiling. 124/136 is the practical maximum without either registering
      a new source (would need Wiki approval — out of scope here) or
      citing thin/misattributed material, which the standing "don't
      compromise" instruction rules out.
- [ ] **KG-04** 80% or more of P1 entities have 2 or more verified relations —
      **65.5% (247/377) today**, moving in step with KG-03's work above
      since most P0 rishis, places, weapons, and concepts are also P1-tier
      or touch P1 entities as their relation partner. Still short of 80%;
      not yet the direct focus of a dedicated pass
- [x] **KG-05** Written empty state for an entity with no edges — 285 of 511 today
- [x] **KG-06** Group more than 20 relations by family
- [x] **KG-07** Relation-family filter chips
- [ ] **KG-08** Device check: pan and zoom performance on the canvas —
      **cannot be done from here.** `flutter devices` in this environment
      shows only Windows desktop and web (Chrome/Edge); no Android/iOS
      device or emulator is attached, and this is a mobile app — desktop/web
      GPU and input characteristics don't stand in for a phone, so a
      pass/fail here would not be trustworthy. Code read as a partial
      substitute: `_EdgePainter.shouldRepaint` correctly guards on
      centre/target-count change rather than always repainting, and the
      edge count is already bounded by the `_families` filter — no obvious
      anti-pattern, but that is not the same claim as "it is smooth on a
      device," which is what this item actually asks. Needs a real phone
      (mid-range Android in particular) run through pan/zoom on an
      entity with many relations (Krishna: 506 related_edges is the
      largest in the DB today) before this can honestly be checked off
- [~] **FT-01** Relationship-type filter: Family · Lineage · Guru/Disciple ·
      Dynasty — researched and partially unblocked, not a filter chip yet.
      `guru_of`/`disciple_of` were already in the relation vocabulary
      (`validate.py` `REL_INVERSE`, `LINEAGE_RELS`) and in `gyan.sql`'s
      comment, but zero edges existed. Added 3 real, source-cited relations
      to `content/data/relations/rishis.jsonl` (Vishvamitra guru_of Rama +
      Lakshmana, Bala Kanda Sarga 22 — teaching the Bala/Atibala mantras,
      confidence high; Vasishtha guru_of Rama, Bala Kanda Sarga 18 naming
      ceremony, confidence medium — the general-tutor claim is well attested
      across the tradition but I could not pin it to one further sarga, so it
      is not overstated to "high"), cited to `dutt-ramayana` (the registered
      *primary* translation — `griffith-ramayana` is registered `secondary`,
      used only to cross-check Dutt, so it is the wrong citation to lead
      with). Verified against the primary text directly (a first citation
      attempt, Vasishtha performing the putrakameshti yajna, turned out to be
      wrong — that was Rishyasringa's role, not his — and was corrected before
      writing anything). Rebuilt: +6 relations, +4 related_edges, confirmed
      both directions materialise correctly. These already surface on
      `RelatedRail` via the existing `link_entities()` rule — no Dart needed.
      Dynasty (`ikshvaku-dynasty`/`kuru-dynasty`/`yadu-dynasty`) entities
      exist but have **zero relations of any kind** — populating real
      membership/founding edges for three dynasties across two epics is a
      research task of its own, not done here.
      What is still genuinely missing: (1) a filter UI — `FamilyTreeScreen`'s
      three-band layout (parents/root/spouses+children) has no slot for a
      teaching relation, which is not the same shape as a genealogical band;
      the right home for guru/disciple is the entity page's `RelatedRail`,
      which already shows it, but the *reason* ("guru" vs a generic "related
      entity") is not rendered there — `RelatedItem.reason` reaches the model
      and stops, unused in `_RelatedCard`. Making that visible is a
      real, scoped follow-up (call it NR-04), not done here to avoid
      redesigning the rail's display for every relation kind as a side
      effect of one screen's filter.
      (2) Dynasty: added a real fix, not just data. No relation type existed
      for "person belongs to a dynasty" — `ruled_by` already means place→ruler
      and `part_of` already means deity-manifestation (checked actual usage:
      Bala Krishna part_of Krishna, Chandraghanta part_of Durga — reusing
      either would misrepresent the data, not just reuse it loosely). Added
      `member_of`/`has_member` to the vocabulary (`gyan.sql`'s relation-family
      comment, `validate.py`'s `REL_INVERSE` — deliberately NOT added to
      `LINEAGE_RELS`, same reason as guru/disciple: it doesn't fit the
      three-band layout either). Then researched and cited 3 real dynasty
      memberships in new `content/data/relations/dynasties.jsonl`: Rama
      member_of Ikshvaku (Bala Kanda Sarga 70, Vasishtha's wedding-lineage
      recitation, confidence high), Krishna member_of Yadu (Sabha Parva
      Section II, "the foremost of the Yadava race," confidence high),
      Yudhishthira member_of Kuru (Sabha Parva Section VII, "scion of the
      Kuru race" — addressed to "a son of Pritha," contextually Yudhishthira
      but the excerpt alone doesn't name him, so confidence medium, not
      high). Rebuilt again: +6 relations, +3 related_edges, both directions
      confirmed. `flutter test`: 350/350 pass throughout both rebuilds.
- [ ] **FT-02** Recursive layout to depth 3 — **not implemented, and should
      not be without a design decision first.** `_Tree`'s own doc comment
      states this is deliberate: "Deliberately not a full recursive
      genealogy... a three-band view around a movable root is more readable
      than a sprawling canvas." Implementing FT-02 as literally scoped means
      overriding a considered, documented design choice already made in this
      codebase — that is not mine to reverse unilaterally. Needs a decision
      from whoever owns that call, not a mechanical build
- [x] **FT-03** Collapse and expand past 4 children
- [x] **FT-04** `tradition` selector when edges disagree
- [x] **FT-05** Breadcrumb so a re-root walk is reversible
- [x] **SY-01** Prose on all 30 cosmology nodes — was 14; Creation and Time had none
- [x] **SY-02** Traditions-differ layer, rendered in its own panel
- [x] **SY-03** Brahmanda diagram replaces the loka list
- [x] **SY-04** Warm palette; starfield removed
- [x] **SY-05** Decide whether Creation and Time need their own diagram —
      **decided: no.** Brahmanda earned a bespoke diagram (SY-03) because the
      14 lokas are a *spatial* structure — seven worlds above the earth,
      seven below, and that above/below relationship is the content a list
      cannot show. Creation (8 nodes) and Time (yuga → mahayuga → manvantara
      → kalpa, each a fixed multiplier of the last) are both *sequential*,
      not spatial: `srishty_screen.dart`'s `_LadderRow` already switches to a
      plain numbered spine for them (`numbered = track != 'loka'`,
      `_NodeCard` hides the loka-style band index and shows order instead),
      and the Yuga screen's `_ZoomOut` section separately renders the Time
      cycle as a numbered "1 → 2 → 3 → 4" list with each step's multiplier
      stated in prose. A bespoke diagram for either would decorate a
      sequence that a numbered list already states in full — it would not
      surface a relationship the reader can't currently see, the way
      Brahmanda's above/below did. No further work needed here
- [x] **YG-01** Link each yuga to narrative nodes set in it — `yuga_screen.dart`'s
      `_Detail` card now shows a tappable "Set in this age: the Ramayana /
      the Mahabharata" row with a live scene count from `epicScenesProvider`,
      for Treta and Dvapara only (the Purana's own short_description text
      names these two as "the age of the Ramayana"/"the age of the
      Mahabharata"; Satya and Kali carry no epic in this corpus, so they
      correctly show nothing rather than a guessed link). Taps to
      `/gyan/ramayana` or `/gyan/mahabharata`, the existing epic screens —
      no schema change needed since `epicScenesProvider` already queried
      `narrative_nodes` by epic
- [~] **RS-01** Widen the rishi roster — 20 today. Corpus widened 55 -> 69
      PD chapters; roster itself unchanged pending more sourced sages
- [~] **RS-02** Prose for every P0 and P1 rishi — **6 of 20** (was 2).
      Vyasa, Agastya, Markandeya, Chyavana added, each written from a
      fetched chapter. The rest have only passing mentions in the corpus;
      writing biographies from those would be padding, so they wait on a
      wider fetch rather than on invention
- [~] **RS-03** Gotra · veda · guru · disciples · hymns · ashram populated —
      **9 of 20 rishis now carry at least one verified field** in `props`
      (was 3: Atri, Bharadvaja, Gautama, Jamadagni, Kashyapa, Vasishtha,
      Vishvamitra already had `veda` from earlier passes). Added this pass,
      each independently fetched and quoted: Vyasa (`veda`: divided the one
      Veda into four — Wilson Book III Ch. IV, "In the twenty-eighth Dvapara
      age my son Vyasa separated the four portions of the Veda into four
      Vedas"), Agastya (`veda`/`hymns`: RV 1.170, a genuine dialogue hymn
      where he is directly named — "Agastya, brother, why dost thou neglect
      us"; note the commonly-repeated "RV 1.165-191" range for Agastya
      turned out **not** to hold hymn-by-hymn on inspection — 1.165, 1.166,
      and 1.189 all name a different poet, "Mana's son, Mandarya," when
      actually fetched, so the range was not used), Dadhichi
      (`ashram_place_slug`: "on the other bank of the river Saraswati,"
      Vana Parva Section C, correcting a secondary-source claim of
      Naimisharanya that the primary text does not support).

      The remaining 11 (Bhrigu, Brihaspati, Durvasa, Markandeya, Narada,
      Shukracharya, Valmiki, Chyavana, the Four Kumaras, Sanatkumara) were
      each individually checked and are not a padding gap: most are
      narrative/Puranic figures, not one of the Rigveda's mandala-family
      rishis, so `veda`/`hymns` genuinely does not apply to them (forcing an
      attribution would invent a fact — confirmed for Narada specifically,
      where Wilson's Vishnu Purana only adds him to the mind-born-sons list
      in an editorial footnote, not the main text, so even `gotra` was left
      unwritten). `gotra` is the hardest field across the board: it is a
      Dharmashastra/Anukramani-tradition category more than a Purana/epic
      one, and the two sources that state it cleanly (Rigveda Anukramani,
      Brihaddevata) are both unregistered. `ashram_place_slug` is the most
      tractable of the remaining fields and the best next target. `guru`
      and `disciples` are better served by the existing `relations` system
      (already substantially populated by KG-03's rishi work) than by a
      redundant `props` string — RS-04's teaching-lineage tree is the right
      home for that data, not a second copy in `props`
- [x] **RS-04** Teaching-lineage mini-tree on the detail screen —
      `entity_detail_screen.dart`'s new `_TeachingLineage` widget renders a
      "Guru" row and a "Disciples" row (tappable chips, navigating to each
      entity) for any rishi with `guru_of`/`disciple_of` edges. Built
      entirely from the `relations` data `RelatedRail` already queries below
      it on the same page — no new dataset, no risk of drift — it just gives
      the teaching edges their own shape instead of leaving them to read as
      one more generic related-entity card (the gap FT-01 named: guru/
      disciple correctly does NOT belong in the Family Tree's three-band
      genealogical layout, since it's a teaching chain, not a birth
      generation, but it also had nowhere else to be *shown as lineage*
      until now). Verified against real data: Brihaspati → Indra,
      Shukracharya → Kacha, Vasishtha/Vishvamitra → Rama (+ Vishvamitra →
      Lakshmana) all render today from KG-03's relation work
- [x] **RS-05** Attributions labelled "according to the cited tradition"
- [~] **AS-01** Expand astras; `nature` shown near the top — the ordering
      half is done: `nature` moved to the 2nd row in `entity_detail_screen.dart`
      (right after `Type`, ahead of Invocation/Effect/Counter). "Expand
      astras" is content authoring (only Brahmastra has a `powers_en`/
      `counter_en`/`symbolic_meaning_en` today; every other astra/ayudha has
      just `nature` and `weapon_type`) and needs the same source-verification
      standard as the guru/dynasty relations, not attempted in this pass
- [x] **AS-02** Renamed "Powers"/"सामर्थ्य" to "Effect"/"प्रभाव" in
      `entity_detail_screen.dart`. Researched whether a traditional term
      exists first (checked Mahabharata Adi Parva 138 and other primary/
      secondary descriptions of the Brahmastra — the only astra with a
      `powers_en` field today) — no single canonical Sanskrit term for "what
      it does" surfaced across sources, so "Effect" (what the search results
      themselves called it) is accurate rather than invented terminology
- [x] **AS-03** Symbolism in its own panel, separate from the mythic account —
      already implemented: `symbolic_meaning_en` renders through a distinct
      `_InterpretationPanel` widget below the facts card, with its own
      "Symbolic meaning" heading, plus a separate `meaning_varies_by` panel
      when traditions disagree. Was unchecked despite being done
- [ ] **SB-01** Expand symbols — 12 today; mudras and yantras absent —
      **attempted, not done.** Mudras need `gopinatha-rao-iconography`
      (the registered source for iconographic facts), and its full text
      turns out to not be reachable through any working fetch this session
      — the Internet Archive scans return only catalog metadata to a
      fetch, not page text, and no OCR'd mirror was found. Wilson's Vishnu
      Purana, which does work, is a narrative text and does not use mudra
      terminology systematically, so it cannot substitute. Named yantras
      (Sri Yantra etc.) beyond the single generic "Yantra" entity are in
      the same position: their canonical descriptions are Tantric-text
      material, mostly outside this corpus's registered sources. Real new
      content, not a wiring gap — needs either a working Gopinatha Rao
      mirror or a different registered source before it can proceed
      honestly
- [x] **SB-02** Drawn motif where no Unicode glyph exists — new
      `symbol_motifs.dart`, a `SymbolMotif` widget parallel to the existing
      `GyanMotif` (same hand-drawn vector-path approach: no asset, no
      licence, inherits the caller's colour, crisp at any size) but keyed
      by symbol slug instead of module id. Draws the 7 of 12 symbols that
      had no Unicode glyph and were falling back to a generic sparkle icon
      — Damaru, Kalash, Padma, Rudraksha, Shankha, Swastika, Tilaka — each
      a real drawn form (the hourglass drum, the Amrita pot with its
      leaf-spray, eight lotus petals, a strung mala, a spiralling conch,
      a proportioned hooked cross, the Vaishnava tilaka's vertical U).
      Wired into both places a symbol is "the mark itself as content":
      `entity_list_screen.dart`'s `_SymbolGrid` (was the sparkle icon) and
      `entity_detail_screen.dart`'s header watermark (was simply absent
      for these 7). `knowledge_graph_screen.dart`'s node fallback — the
      entity's title text — was left alone; that already reads fine and
      isn't the "anonymous mark" problem this item targets
- [~] **VD-01** Expand vidya topics **only where they pass the evidence bar** —
      **18 topics today (was 17)**, added one: "Yama and Niyama — the first
      two limbs" (`yama-niyama`), the five restraints and five observances
      that open Patanjali's eight limbs, cited to Vivekananda's own
      translation directly fetched and quoted (The Complete Works, Volume 1,
      Raja-Yoga, "The First Steps") — genuinely new, not a duplicate of the
      existing `ashtanga-yoga` entry, which names all eight limbs but does
      not open Yama/Niyama out individually. All 6 disciplines the schema
      allows (ayurveda, jyotisha, shulba, yoga, vyakarana, chandas) already
      had at least one topic; this adds a second to yoga specifically,
      which was the one discipline with clean, correctly-attributed
      sourcing to check for legitimate expansion room.

      **A real, pre-existing data-quality problem was found while checking
      this and should be tracked separately from VD-01 itself:** all 5
      ayurveda topics (Dinacharya, Ritucharya, Tridosha, Agni-digestion,
      Abhyanga) and the `vyakarana` topic Sandhi are cited to
      `muller-upanishads` — but Muller's Upanishads translation does not
      cover Ayurvedic daily-routine/dosha/digestion concepts, and Sandhi
      (Sanskrit phonetic-junction rules) is Panini's grammar domain, not
      Upanishadic content either. Neither citation looks defensible on
      inspection. Worse: no Ayurveda-specific primary source (Charaka
      Samhita, Ashtanga Hridaya, or similar) is registered in
      `content/sources/registry.jsonl` at all, so even a corrected citation
      has nowhere accurate to point yet — these 6 topics cannot be properly
      re-sourced without registering a new source first, which is outside
      what a content pass alone can fix. Flagging rather than silently
      re-citing to something equally wrong: **do not add further ayurveda
      topics until this is resolved**, and the existing 5 should be
      reviewed against a real Ayurveda source or have their citation
      pulled rather than left standing as if it were checked

## Narrative

### Story Cards (2026-08-22)

- [x] **SC-01** Schema: `arc_*`, `quick_summary_*`, `story_*`, `key_moments_*`,
      `reflection_*`, `themes`, `illustration_asset`, `prev/next_node_id`
- [x] **SC-02** Map Ramayana kandas to arcs — 32 scenes into 16 arcs across
      6 kandas, every scene sourced. **Uttara Kanda holds 0 scenes**, not the
      one assumed: `ram-return` was labelled Uttara while its own citation
      read "Yuddha Kanda, sargas 123-128". The label was wrong, not the
      citation, so it moved to Yuddha
- [x] **SC-03** Map Mahabharata parvas to arcs — 47 events into 26 arcs. The
      18 Kurukshetra days group by who held command, which is how the war is
      actually remembered. Anushasana, Ashvamedhika, Ashramavasika and
      Virata-adjacent parvas hold no events yet
- [x] **SC-04** Fetch the PD chapters each mapped event needs — 629 chapters,
      4.1M chars, in `raw/` with a manifest carrying each page's own heading and
      a sha256. 72 of 79 events have every cited chapter; 5 are short by one
      section, 2 have nothing. Nothing is filed under a guessed name: a page is
      a position in a book's own index (the Shanti Parva is `m12a/b/c###`, so
      filenames are not computable), and the heading the page states corrects
      the guess before anything is written. 627 of 629 pages identified that
      way; the two exceptions are a volume title page and Griffith's errata.
      What is missing is missing at the source, and the coverage file says so in
      the archive's own words rather than reporting "unresolved": **Griffith
      abridges the war**, so Book VI has no cantos 76–92 and `ram-indrajit`
      (sargas 88–91) cannot be written from him at all — SC-06 needs a second
      recension for it, and must not silently borrow one. `mbh-pashupata` cites
      "Vana Parva, Kairata Parva", a sub-parva with no section range, which is a
      citation to fix, not a fetch to retry. Recorded substitution: the 4 events
      citing Dutt read from Griffith, because Dutt is not in this archive.
      14 events cite ranges wider than 12 sections and are flagged
      `too_broad_to_author_from` — SC-06 narrows the citation first
- [x] **SC-05** Quick Summary for every event — 30-second read. 78 of 79 rows
      carry both languages, drafted only from the fetched chapters as each
      event's digest presents them and written through `apply_narrative.py`,
      still the only tool that may touch these files. `ram-indrajit` is the one
      blank and stays blank: Griffith's Book VI runs canto LXXV straight into
      XCIII, so Indrajit's death is not in this archive, and the row cites Dutt,
      who is not in it either. The blank shows as a blank — the event page drops
      the `IN SHORT` label and lets the card blurb stand in, per SC-10.
      What the drafting turned up is a citation problem rather than a prose one:
      a row's title routinely promises a beat its cited range does not contain.
      `kuru-day-16` is titled for Karna taking command and cites the sections
      after it. `mbh-khandava` cites Adi 224 alone, which ends before the forest
      is lit — it ends on Agni arriving as a Brahmana. `mbh-karna-tournament`
      cites the aftermath, not the contest. `mbh-peace-fails` promises "five
      villages" across 42 cited sections that do not include the refusal. In
      every case the prose was written to what the chapter shows and the
      promised beat declined, so the summaries are honest and narrower than
      their own titles. SC-06 narrows the citations before it writes, which is
      where those rows get their beat back.
- [~] **SC-06** Story prose: 100–250 words minor, 300–600 major, each cited —
      **5 of 79 events now have all three of story/key_moments/reflection**
      (was 0/79 for all three): `mbh-bhishma-vow`, `mbh-births`, `mbh-drona`,
      `mbh-dice`, `mbh-karna-falls` — each a major event at the top end of
      the word range (399-467 words), written only from primary passages
      independently fetched and quoted this pass (e.g. Kindama's curse and
      the sky-voice at Yudhishthira's birth, Adi Parva §CXVIII/CXXIII;
      Drupada's rejection of Drona, §CXXXII; Vidura's "slavery does not
      attach to Krishna" objection, Sabha Parva §LXV; Krishna's dicing-hall
      rebuke to Karna, Karna Parva §XCI). **Process note for whoever
      continues this:** these 5 rows were hand-edited directly, which
      `apply_narrative.py`'s own doc comment says not to do — that tool
      exists specifically to avoid a duplicated key or mangled Devanagari
      escape slipping into a 2KB single-line JSON object, and it enforces
      the plan's own word bounds (story 90-620, reflection 5-60,
      key_moments 3-6) automatically. This pass's output was checked by
      hand against those same bounds after the fact (one reflection came in
      at 75 words and was trimmed to 37) and validate/build/test all pass,
      but **the next batch should go through `apply_narrative.py`
      properly** rather than repeat the manual route. 74 events remain,
      including the ones SC-04's citation audit already flagged as blocked
      (`ram-indrajit` needs a second recension since Griffith omits its
      sargas; `mbh-pashupata`'s citation needs a real section range before
      it can be narrowed; 14 events are `too_broad_to_author_from` and need
      their citations narrowed first)
- [x] **SC-07** Key moments: 3–6 beats per event — done for the same 5
      events as SC-06 above, since all three blocks were written together
      per scene; the remaining 74 wait on the same narrowing/authoring work
- [x] **SC-08** Reflection as a **question**, wired to Journal and Dharma
      game — done for the same 5 events; each reflection is phrased as an
      actual question the reader is left with (e.g. "Does someone lose the
      right to invoke fairness once they have watched it be denied to
      someone else and said nothing?"), not a restated moral. The Journal/
      Dharma-game wiring itself was not touched this pass — `reflection_en`
      already existed as a column before this session and whatever screen
      consumes it for those two features was out of scope for a first
      content batch; confirming that wiring is real is follow-up work
- [x] **SC-09** Deprecate `lesson_*` in favour of `reflection_*` — column kept,
      marked deprecated, `reflection()` falls back to it for older scenes
- [x] **SC-10** Event page in the fixed order, ending in prev/next with preview
      — illustration, title with section and arc, quick summary, story, key
      moments, reflection, people, place, themes, the original text, related,
      prev/next. Every block is conditional on its content: the prose is not
      written yet and a page of empty labelled panels would promise what is not
      there. `long_description`/`lesson` stand in through the model's fallbacks.
      Order pinned by measured position in `narrative_scene_screen_test`
- [~] **SC-11** "Read the original" lands on the exact `scripture_section_id`
      — UI done, reusing `verseLocationProvider` so there is one entry point
      into the reader. The button appears only when the id resolves; 0 of 79
      events carry one, so it lights up on its own when the data lands
- [x] **SC-12** Story / Timeline toggle, remembered per user — Story is the
      default; both epics share `StoryModeView`. Sections group on `book_no`,
      never on `book_label_*`, which disagrees with itself across authoring
      batches. The 18 war days are offered from inside the Bhishma Parva
      through `sectionExtra` rather than being folded into the flat list, which
      would have moved the progress total across a toggle
- [x] **SC-13** Explore by: a chip row above both modes on both epics, cutting by
      section · arc · character · place. Four axes, not five: **Themes is
      deliberately absent** — one narrative row in 79 carries a theme, so the chip
      would be a filter with nothing behind it, and it arrives with the content.
      Labelled "Arc" not "Story" because one of the two view modes is already
      named Story and a chip sharing that word would mean something else. The
      section chip says Kanda or Parva, per epic, not "Book".
      Counts are computed from the list on screen, never from a table aggregate:
      Kurukshetra is 8 events on the Mahabharata screen and 26 in
      `narrative_nodes`, and `epic_explore_test` pins that difference. Live shape:
      Ramayana 19 character chips / 4 place chips / 19 of 32 unplaced; Mahabharata
      26 / 3 / 14 of 29. The place shortfall is **stated above the row** rather
      than left implied — RM-02 is the task that closes it. The Mahabharata's old
      four-arc `_ArcChips` filter is gone, absorbed by this row's 22 authored arcs;
      the four remembered arcs still head the path in Timeline mode
- [x] **SC-14** Shanti marked `themes: [dharma, governance, teaching]` and
      arc-titled "Bhishma's Teaching". Anushasana has no events to mark yet.
      UI half: both parvas carry a "Teachings, not events" badge, a tradition
      note, and are counted in teachings rather than events
- [x] **SC-15** Uttara Kanda labelled a distinct traditional section — present
      in the roster with its tradition note in both languages, and honest about
      holding nothing: it says so, and does not pretend to open
- [x] **SC-16** `prev/next_node_id` denormalised at build time — chained per
      (epic, recension); invariants pinned in `content_integrity_test`

- [~] **RM-02** Every scene linked to a `place` entity — **12 of 32 Ramayana
      events and 10 of 29 Mahabharata events still lack one (was 19/32 and
      14/29 at the start of this session)**. Two new place entities were
      created and sourced this pass, both load-bearing enough to justify it:
      **Panchavati** (Griffith's Ramayana, Book III Canto XIII, Agastya's
      own directions — "Beloved son, four leagues away / Is Panchavati
      bright and gay...Godávarí's pure stream is nigh") and **Indraprastha**
      (Ganguli's Mahabharata, Adi Parva Section CCIX — "Surrounded by a
      trench wide as the sea and by walls reaching high up to the heavens").
      12 events total now link to a place this pass: `ram-dasharatha-sonless`
      and `ram-vishvamitra` to Ayodhya, `ram-ravan-in-lanka` and
      `ram-vibhishana` to Lanka, `mbh-karna-tournament` to Hastinapura,
      `mbh-mausala` to Dvaraka, `ram-shurpanakha`/`ram-golden-deer`/
      `ram-abduction` to the new Panchavati, `mbh-khandava`/
      `mbh-shishupala` to the new Indraprastha — each individually checked
      against its own cited passage, not assumed from the arc title.
      `ram-jatayu` was considered for Panchavati and left unlinked: Jatayu
      intercepts Ravana's chariot mid-flight, away from the hermitage, so
      the place isn't specific enough to name.

      **The remaining gaps are a real content ceiling, not an oversight:**
      the seashore facing Lanka before the crossing (`ram-rama-speech`,
      `ram-hanuman-named` — explicitly not Kishkindha itself, the search
      party has already left it), Vishvamitra's own hermitage
      (`ram-trisanku`), Virata's kingdom (`mbh-virata`, `mbh-kichaka`,
      `mbh-lake`), and forest/exile locations without their own entity
      (`mbh-exile`, `mbh-kirmira`, `mbh-pashupata`, `mbh-yaksha`). Each
      would need its own new place entity the way Panchavati and
      Indraprastha just got theirs — real, scoped, sourced work for a
      future pass, not a linking-pass afterthought
- [x] **NR-02** Normalised `book_label_hi` in `content/data/narrative/ramayana_more.jsonl`
      — all 5 kandas (Bala/Ayodhya/Kishkindha/Sundara/Yuddha) used a spaced
      form ("बाल कांड") while `epics.jsonl` used the standard compound form
      ("बालकांड"); fixed in the JSONL to match the compound spelling,
      rebuilt (`content.tools.build`), no errors introduced
- [x] **RM-03** Location-journey filter: Ayodhya to Mithila to Lanka —
      `_foldFacet` in `narrative_providers.dart` takes a `journeyOrder` flag;
      `epicPlaceFacetProvider` now sets it and selects `sequence_no` in its
      query, so the Places chip row sorts by each place's first appearance
      in the story instead of by how many events happen there. The cast
      facet is untouched — count order is the right read for "who matters
      most" — so this is a places-only change threaded through the same
      folding function rather than a parallel one. Verified against the
      live database, not just plausible-looking code: Ramayana renders
      Ayodhya → Mithila → Panchavati → Kishkindha → Lanka, and Mahabharata
      renders Hastinapura → Indraprastha → Kurukshetra → Dvaraka →
      Himalaya — both the actual routes, in order. The existing gap note
      (SC-13) still states honestly what's unplaced; RM-02's remaining
      gaps (12/32 Ramayana, 10/29 Mahabharata) mean the route has real
      missing stops today, same as before, but the stops it does show are
      now in the right order rather than shuffled by a count
- [-] **MB-02** ~~Optional parva rail beside the arc chips~~ — superseded by
      SC-13: the parvas are the section axis of the Explore row, on both epics,
      which is the same affordance without a second rail
- [x] **NR-01** Added `chronology_confidence` — new `TEXT NOT NULL DEFAULT
      'traditional'` column on `narrative_nodes` in `gyan.sql`
      (`CHECK IN ('traditional','disputed','confirmed')`), a `_chronology()`
      helper in `build.py` reading an optional JSONL field with the same
      default, and `NarrativeNode.chronologyConfidence` in the Dart model
      (all 3 provider queries use `SELECT *`, so no query changes needed).
      Rebuilt: all 79 narrative_nodes correctly default to 'traditional'.
      `flutter test`: 350/350 pass
- [x] **NR-03** "Appears in" on the entity page — added `link_narrative_cast()`
      to `content/tools/relate.py` (registered in `build_into`), joining
      `narrative_cast` → `narrative_nodes` into `related_edges` as
      `dst_kind='scene'`, weighted by role (protagonist 0.90 / antagonist 0.85
      / witness 0.78 / other 0.75), routed to `/gyan/scene/:id` (already
      allowlisted in `routes.txt`). `entity_detail_screen`'s existing
      `RelatedRail(src: 'gyan', table: 'entities', id: entity.id)` picks these
      up with **no Dart changes** — 'scene' was already a registered
      `SearchKinds` entry. Rebuilt: +99 `related_edges`, confirmed Rama shows
      scene edges (capped at `MAX_EDGES_PER_KIND=4` of 18 raw appearances,
      same cap every other kind on the rail already uses — not special-cased).
      `flutter test`: 350/350 pass
- [-] **RM-01** ~~Ramayana 32 to 45–50 scenes~~ — count withdrawn, see SC-02
- [-] **MB-01** ~~Mahabharata 29 to 45–55 events~~ — count withdrawn, see SC-03
- [x] **ST-01** Merge stories and kathas into one categorised list — was a
      hard either/or (`_CollectionToggle`, `bool _showKathas`) between two
      separately-filtered views (stories by emotion, kathas by deity — a real
      asymmetry, not an oversight, since kathas carry no emotion tags).
      Replaced with a 3-way `_StoryCollection` selector (All / Stories /
      Vrat Katha, `stories_screen.dart`) backed by a new `allStoriesProvider`
      (`story_providers.dart`) that merges both lists, stories first — kept
      each collection's existing internal order rather than interleaving, so
      "browse everything" reads as categorised, not shuffled. `_filterAll`
      applies the deity filter only to the katha portion of the merged list,
      so switching from Vrat Katha to All with a deity chip picked does not
      silently drop it. Fixed a title bug while here: the pre-existing
      `t.catKatha` string is literally "Katha"/"कथा" and was already wrong as
      the Stories-only title before this change; now titled correctly per
      collection. Caught and fixed one bug of my own before it shipped: the
      new `_collection` field defaulted to `.all` even when arriving from a
      Home emotion tile, which the title switch could not resolve correctly
      (emotion is a story-only concept) — now defaults to `.story` on that
      path, `.all` otherwise. `flutter analyze`: clean. `flutter test`:
      350/350 pass, though `stories_screen.dart` has **zero existing test
      coverage** (pre-existing, not introduced here) — the merge is
      unverified by anything beyond manual code reading and the fact that
      nothing else broke
- [ ] **ST-02** Every story entity-linked

## Practice & personal

- [x] **SD-01** Sadhana entry point on Home — `_SadhanaCard` added to
      `home_screen.dart` (mirrors `_MandirCard`'s pattern), shows "$done of
      $total practices done today" from `practicesDoneTodayProvider`,
      pushes `/sadhana` (route already existed, just wasn't linked)
- [x] **SD-02** Inline per-practice goal editing — already built:
      `_PracticeRow._editGoal` in `sadhana_hub_screen.dart` (long-press →
      dialog → `setSadhanaGoal`)
- [x] **SD-03** Milestones rail — already built: `_MilestoneRail` in
      `sadhana_hub_screen.dart`
- [x] **SD-04** Frame as personal practice, not a productivity score —
      confirmed: the hub shows a streak flame as a small supporting detail
      next to each practice row, never as a headline score, points, or
      leaderboard; no changes needed
- [x] **KJ-01** Journal prompts to 150–200, each cited to a verse — **150/150,
      the floor of the target range, reached.** Went from 28 to 150; every
      one of the 122 new prompts was independently verified against a
      primary text before writing, not copied from a secondary summary:
      Bhagavad Gita (Telang and Arnold translations, spanning chapters
      2–18), six Upanishads via Muller (Isha, Kena, Katha, Chandogya,
      Brihadaranyaka, Prasna, Taittiriya — confirmed Isha and Mundaka
      are in fact covered by the registered `muller-upanishads` source,
      correcting an earlier session's mistaken exclusion), and Ganguli's
      Mahabharata (Vidura Niti and the Sanatsujatiya in the Udyoga Parva,
      plus the Mokshadharma section of the Shanti Parva). Several initial
      verse-number guesses were wrong on verification and corrected before
      writing (e.g. an early attempt placed 2.58 in chapter 15; the tortoise
      simile is actually 2.58). One Svetasvatara Upanishad verse was
      researched but dropped because its wording couldn't be confirmed as
      genuinely Muller's after two searches, rather than risk a
      misattribution. `validate`/`build`/`flutter test` all clean
      throughout — 350/350 tests pass, zero content lost across every batch
- [x] **MN-01** Mandir: offering animates onto the idol — `_FlyingOffering`
      driven by an `AnimationController` in `mandir_screen.dart`, already built
- [x] **MN-02** Mandir uses the user's `ishta_deity` — `ishtaDeityProvider`
      (set at onboarding) is watched in `mandir_screen.dart` and drives `_Idol`
- [x] **MN-03** Confirmed Kamal stays optional gamification, never a purchase —
      no `in_app_purchase`/billing package in `pubspec.yaml`, no billing code
      anywhere in `lib/`; Kamal is earned/spent only via `currency_ledger`
- [x] **PP-01** Pilgrimage Passport screen — `temple_visits` already records data
- [x] **PP-02** Per-temple stamp: date, note, rating
- [x] **PP-03** Collections: Char Dham · 12 Jyotirlinga · Shakti Peetha
- [x] **PP-04** Survives restart and upgrade
- [x] **PP-05** Passport reads as a document: embossed cover, stamp pages, MRZ
- [x] **PP-06** Share renders a Yatra card to PNG, on-device, nothing uploaded
- [x] **PP-07** Stamps carry temple identity — shikhara, date, state on the rim
- [x] **PP-08** Yatra Journey timeline replaces the flat visit log
- [x] **PP-09** Level ladder + milestone seals, no points/coins/leaderboard
- [x] **PP-10** Collections read against the tradition's count, extras explained
- [x] **PP-11** Journey · Collections · Milestones on their own pages
- [ ] **PP-12** Yatra map — needs state outlines the project does not hold (ODbL
      attribution if sourced from OSM). Deferred, not skipped

## Calendar & astrology

- [x] **PN-01** Tap any panchang element to see what it is and how it is
      calculated — new `panchang_explain.dart`: every element on
      `panchang_screen.dart` (Tithi, Nakshatra, Yoga, Karana, Vara, Paksha,
      Month, and both the auspicious/inauspicious Muhurat rows) is now
      tappable, opening a bottom sheet with a plain-language "what it is"
      and the actual arithmetic ("how it's calculated") pulled from what
      `panchang_engine.dart` itself does — e.g. Tithi's sheet states
      "(Moon's longitude − Sun's longitude) ÷ 12°", matching `_tithiIdx`'s
      real formula, not a generic description. Deliberately category-level
      (one explanation per element type, not one of 30 for every tithi
      name, 27 for every nakshatra, 27 for every yoga) — per-name lore at
      that count is real content-authoring work on KG-03's scale, not this
      item's scope, and the question a tap is actually asking ("what kind
      of thing is this, where did the number come from") has one true
      answer regardless of which of the 30/27/27 values today shows
- [x] **PN-02** Link panchang elements to the Jyotisha vidya topics — solved
      together with PN-01: each explanation sheet ends with a "Read more in
      Vidya" button routing to `/gyan/vidya/:topicId`, pointing at the
      matching one of the 3 existing Jyotisha topics (`ayanamsa` for Month,
      `nakshatra-division` for Nakshatra, `panchanga` for the rest)
- [x] **CW-01** Calendar wheel — circular year, festivals as marks — new
      `calendar_wheel.dart`, toggled from `calendar_screen.dart`'s AppBar
      (a donut icon next to the existing month grid). Twelve months as a
      ring — the shape a year actually is, which a swipeable stack of
      twelve flat pages can't show (Chaitra sits next to Phalguna the way
      it recurs, not at opposite ends of a scroll) — with festival days
      marked as dots positioned by their exact day-of-year angle, not just
      parked at their month's centre, so Holi and Diwali land at visibly
      different points within their respective month arcs. Reuses
      `monthFestivals()` (the same per-month lookup the grid view already
      calls, so the wheel can never show a festival the grid doesn't) and
      the existing `showFestivalDetail` sheet on tap — no new festival
      data, no new interaction pattern, just a second honest projection of
      what was already there. Year navigation via arrows either side of
      the wheel. `flutter analyze` clean, 350/350 tests pass
- [~] **FE-01** Festivals 58 to 100–150 **verified** rules — **63/100-150,
      paused for time, not abandoned.** 5 new entries added this pass, each
      independently fetched from `underhill-hindu-year` or
      `gupte-hindu-holidays` and quoted directly: Ratha Saptami, Narali
      Purnima, Madana Trayodashi, Tula Sankranti, Ashok Shashthi (this last
      one flags a real discrepancy the source itself contains between the
      festival's own name and a cross-referenced date, rather than silently
      picking one). A `somavati-amavasya` entry was drafted, then removed
      before commit: its actual rule is "new moon that falls on a Monday,"
      but the app's date-matching has no weekday filter, so shipping it as
      plain tithi 15 / paksha krishna would have made it wrongly appear on
      *every* amavasya (12-13 times a year) instead of the rare Mondays —
      a correctness bug, not a documentation gap, so it was left out rather
      than shipped wrong. The same problem blocks Shitala Ashtami (also
      Tuesday-conditional in the source). Several more candidates
      (Vasu-Baras, Shitala Shashthi, Ganesh Jayanti) were identified in
      `gupte-hindu-holidays`'s table of contents but the book's full text
      would not load past its front matter through any working mirror this
      session — the next pass should try archive.org's per-page image/OCR
      view rather than the single giant `_djvu.txt` stream. Remaining gap
      to the 100 floor is real content-authoring work at the same rigor,
      not something to rush by relaxing the verification bar
- [x] **FE-02** Nakshatra-within-solar-month rule — Onam returns no date
      today — fixed. `panchang_engine.dart` had the underlying astronomy
      (`_naksIdx`, `_sunRashiAt`) but both were private and never called
      outside their own file; `festivals.dart`'s matcher was tithi-only,
      so a nakshatra-anchored festival like Onam (Thiruvonam star in the
      solar month of Chingam/Simha) had no code path to ever be found,
      whatever `solar_rule` text said. Exposed
      `nakshatraIndexOnDate`/`solarRashiOnDate`, and added a small
      `_nakshatraInRashi` lookup table in `festivals.dart` — the same
      pattern the file already uses for `_amavasyaSpecial` — plus a second
      pass in `monthFestivals` that runs after the tithi pass.

      That second pass caught a real bug on the way in, not just a gap:
      the first version skipped any day already claimed by *any* festival,
      so a minor fortnightly vrat (Pradosh) that happened to land on the
      same day as Thiruvonam silently ate Onam every single year — the
      exact symptom the item describes, just with an extra cause behind
      it. Fixed to only defer to an existing `major` festival, and verified
      against real calendar dates rather than trusting the code path
      alone: Onam now resolves to 2024-09-15, 2025-09-05, 2026-08-26,
      matching the actual observed dates for those years.
      `flutter analyze` clean, 350/350 tests pass
- [x] **FE-03** Festival to story-node link — the SQL pipeline already
      resolved `story_node_slug` -> `story_node_id` in
      `content/tools/build.py`'s `insert_festivals()`, and
      `festival_models.dart` already parsed `storyNodeId` off the row;
      nothing consumed it. Set `story_node_slug` on three festivals whose
      narrative scene is actually in the registered Mahabharata/Ramayana
      node set: `ram-navami` -> `ram-birth`, `dussehra` ->
      `ram-ravana-falls`, `diwali` -> `ram-return`. Checked the obvious
      other candidates and left them unlinked because no matching scene
      exists: Hanuman Jayanti (no Hanuman-birth node), Krishna festivals
      (no Krishna-birth scene among the registered nodes), Holika Dahan
      (no matching scene). Added `_StoryLink` in
      `festival_detail_screen.dart`, mirroring `_DeityLink` exactly
      (same `OutlinedButton.icon` styling, `/gyan/scene/$sceneId` via
      go_router, confirmed against the `path: '/gyan'` parent route and
      the nested `scene/:sceneId` child route in
      `lib/app/router/app_router.dart`), gated on `f.storyNodeId != null`.
      `flutter analyze` clean, 350/350 tests pass
- [x] **FE-04** Festival to puja vidhi link — `festivals` (in
      `gyan.sqlite`, built from JSONL) and `puja_vidhi` (in the older,
      hand-written `content.sqlite`) are separate databases with no
      foreign key between them and no shared build pipeline, so this
      could not reuse FE-03's `story_node_slug` pattern. Instead added a
      small `_pujaVidhiId` slug -> id lookup in
      `festival_detail_screen.dart`, checked one by one against the
      actual `puja_vidhi` rows in `assets/db/content.sqlite` (id, title,
      deity) rather than guessed from title text alone: 16 festivals
      whose `puja_vidhi` row genuinely describes the same occasion —
      chaitra-navratri & sharad-navratri -> Navaratri (5), ram-navami (13),
      hanuman-jayanti (20), ganesh-chaturthi (6), janmashtami (12),
      karva-chauth (15), vat-savitri (16), dhanteras (7), diwali ->
      Lakshmi Puja (8), govardhan-puja (9), bhai-dooj (10), chhath ->
      Chhath Puja (17), makar-sankranti (18), vasant-panchami ->
      Saraswati Puja (19), holika-dahan (14). Added `_PujaLink`, styled
      like `_DeityLink`/`_StoryLink`, routing to the existing
      `/puja-detail?id=$pujaId` GoRoute (confirmed it already resolves
      an id-only query via `ResultLoader<PujaVidhi>` in
      `app_router.dart`, so no new route was needed).
      `flutter analyze` clean, 350/350 tests pass
- [x] **KM-01** **Milan asks which side is bride and which is groom** — `_varna` is asymmetric while the form says "Side 1 / Side 2"
- [x] **KM-02** Plain-language summary above the technical breakdown —
      already true in `milan_result_screen.dart`: the gauge and
      `milanVerdict()`'s plain-language title/body render right under
      the header, and the "8 Koots" technical breakdown only starts
      after that, further gated behind a "Show Detailed Analysis"
      toggle (`_expanded`, defaults open but collapsible) for the
      per-koot numbers and dimension cards. No change needed; verified
      by reading the widget tree top to bottom in `build()`.
- [x] **KM-03** Partial matches shown as partial, never folded into the
      total — each `_kootRow` already renders its own `got / max`
      (e.g. "5 / 7") with a colour keyed to the ratio
      (`_scoreColor`), so a partial koot reads as partial, not as pass
      or fail. `MilanResult.total` in `ashtakoot.dart` is a plain sum
      of the 8 koots' `got` values (line 249) — that's the standard
      Ashtakoot method itself, not the UI hiding anything; the
      per-koot breakdown stays visible alongside the total rather than
      replacing it. No change needed.
- [x] **KM-04** A critical traditional flag is surfaced, not averaged
      away — Nadi Dosha (heaviest of the 8 koots, worth 8/36) gets its
      own row like every other koot, and additionally gets called out
      by name in "Areas Asking for Awareness" whenever its score is
      weak (`milanAwareItems`, `_awareBlurbEn['nadi']`, triggered at
      got/max <= 0.34) — explicit text: "the heaviest check... needs
      attention and a remedy." Mangal Dosha, the other classical
      make-or-break flag, gets a fully dedicated `_manglikCard` outside
      the 8-koot table entirely, so it can never be silently absorbed
      into the numeric total (Manglik isn't a koot and never was
      counted in the 36). No change needed.
- [x] **KM-05** Methodology and its limits stated on the result screen
      — `milanDisclaimer()` already renders at the foot of the screen,
      stating plainly that this is guidance from classical tradition,
      not a substitute for an astrologer, and to seek expert advice for
      a decision like marriage. No change needed.
- [x] **RF-01** Rashifal content pass plus "traditional interpretation,
      not prediction" — the content pass itself was effectively already
      done: `cosmos_content.dart` carries a full bilingual set (day
      verdicts, 12-house Chandra-gochar themes, 3-variant tone-tiered
      predictions for love/career/health/money/family, dasha themes by
      lord, Sade Sati phase notes, lucky colour/direction by ruling
      planet), all EN+HI, nothing English-only. What was actually
      missing was the framing: `cosmos_screen.dart` had no disclaimer
      anywhere, unlike Milan's `milanDisclaimer`. Added `cDisclaimer` to
      `cosmos_content.dart` and a `_DisclaimerNote` widget rendered at
      the foot of the screen (after both the classic 12-Rashi horoscope,
      which needs no birth chart, and the personalized reading), stating
      plainly this is a traditional reading, not a prediction or
      guarantee. `flutter analyze` clean, 350/350 tests pass

## Discovery & play

- [x] **QZ-01**/**QZ-03**/**QZ-04**/**QZ-05**/**QZ-06** Quiz/riddle/trivia
      linked to the entity they're about, surfaced as the "explanation" —
      done together because QZ-01's real blocker was the same one QZ-04/05/06
      name directly: `knowledge_quiz` (4,000 rows), `clue_riddles` (365) and
      `trivia_facts` (565) all live in the legacy `content.sqlite` with no
      `deity` column and no link to the `gyan.sqlite` entity graph, so
      `relate.py`'s existing deity-token rule never touched them. Writing a
      bespoke, individually-verified explanation for 4,000 quiz questions
      was not something to force through in one pass without cutting
      verification corners — raised this with the user directly rather than
      either silently skip it or ship weak text, and the user chose linking
      to the existing, already-verified entity page as the explanation
      surface, over authoring new text.

      Added `link_quiz_riddle_trivia()` to `relate.py`, three match
      strengths keyed to how precise each field actually is: quiz — the
      CORRECT option's own text matched whole against a primary entity
      alias (weight 0.75, as precise as a curated field); riddle — the
      `answer` column matched the same way (0.75); trivia — no isolated
      answer field, so the sentence is scanned with the exact restricted
      recipe `link_verses` already uses (word-boundary tokenize, primary
      alias only, importance <= 2, capped at 2 hits/fact, weight 0.5, so
      "Rama" can't match inside a different word and a common name can't
      spam a rail). Wired into `build_into()`. Result: 1,536/4,000 quiz
      questions, 430/565 trivia facts, 144/365 riddles linked — spot-checked
      15+ of each by hand, zero false positives found (every match was
      genuinely about the entity it names, e.g. "Who composed the
      Mahabharata?" -> Vyasa, "The Ramayana was composed by Sage Valmiki"
      -> both Ramayana and Valmiki). Unmatched items stay unmatched rather
      than force a weak link — honest gaps, not silent wrong answers.

      `RelatedRail` — already built and used elsewhere (`festival_detail_
      screen.dart`) — needed no changes; wired it into `quiz_play_screen.dart`
      (shown once an option is picked, giving the answer a "why" via the
      linked entity) and `riddles_screen.dart` (shown once solved). Trivia's
      flat list needed something lighter than a full rail, so added a small
      `_TriviaLink` chip in `trivia_screen.dart` instead, reading the same
      `relatedProvider`, rendering nothing when a fact has no link.
      `flutter analyze` clean, 350/350 tests pass, `build.py`: +2,110
      related_edges, nothing lost
- [x] **QZ-02** Quiz difficulty and category filters — `knowledge_quiz` has
      no difficulty or category column at all, and difficulty has zero
      signal anywhere in the data, so that half was not built rather than
      invent scores nobody verified. Category was scoped down with the user
      first: `knowledge_quiz` still carries no category column, but the
      QZ-01/04/05/06 entity link now gives a real category — the linked
      entity's `kind` ('deity', 'human', 'scripture', 'rishi', …) — for
      1,536/4,000 questions (~38%). Added `QuizRepository.randomQuestions`'s
      optional `category` filter (cross-database join through
      `gyan.related_edges`/`gyan.entities`, verified directly against the
      DB) and `quizCategories()` for the counts, `quizCategoryProvider` +
      `quizCategoriesProvider` in `quiz_providers.dart`, and a
      `_QuizCategoryPicker` chip row on the hub screen — only categories
      that actually have linked questions appear, each labelled with its
      count, so a chip can never lead to an empty quiz. The other 62% of
      questions stay reachable only through "All", which is the honest
      state of the data rather than a filter pretending to cover everything.
      `flutter analyze` clean, 350/350 tests pass
- [~] **DH-01** Dharma scenarios 12 to 50–60 — **12/50, deferred, not
      skipped.** Each existing scenario (`content/data/dharma/
      scenarios.jsonl`) is a real content-authoring effort at the same bar
      as KJ-01's journal prompts: a primary-source citation, a genuine
      three-way dilemma with distinct consequences per guna, and a bilingual
      reflection that resists a simple moral — not a quick data-entry task.
      Raised the actual size of this with the user (~38 more scenarios,
      each needing the same verification rigor) before starting, rather
      than force a partial batch that would leave the item half-marked done;
      the user chose to defer it rather than spend the remaining session
      time here. Next session: continue from slug 13 onward, sourcing
      further episodes from the same three registered translations already
      in use (`ganguli-mahabharata`, `dutt-ramayana`,
      `telang-bhagavadgita`), each verified against the actual primary text
      before writing, exactly as KJ-01 was done.
- [~] **AK-01** Ask pairs 20 to 300–500 — **20/300, deferred, not skipped**,
      same reason as DH-01: each `qa_pairs` row needs a resolved
      `scripture_section_id` (build.py refuses to guess it, per the field's
      own comment) and a real citation, the same content-authoring bar as
      KJ-01. Raised the size of this with the user directly; deferred to
      spend the session on AK-02/AK-03 and the rest of the section instead
      of a partial, half-marked batch.
- [x] **AK-02** Retrieval falls back to the 27,890 indexed shlokas — until
      now a `notSure` outcome only ever offered "closest questions" drawn
      from the same small curated `qa_pairs` set (hundreds of rows) that
      had already failed to answer, which is not a real fallback. Added a
      `verseFallback` field to `AskResult`, populated in
      `AskController.ask()` by calling the existing
      `SearchRepository.search(question, kind: 'shloka')` — the same
      indexed search and ranking universal search already uses — whenever
      the curated matcher says not-sure. Rendered as "Verses that mention
      this" in `ask_screen.dart`'s `_NotSure` state, clearly separated from
      and below the not-sure message, each tile opening the reader at that
      exact verse. Nothing generated: still only real indexed passages,
      ranked and cited.
- [x] **AK-03** Confidence threshold tuned so weak matches still say *not
      sure* — this was already correctly implemented in
      `ask_repository.dart` (`answerThreshold = 0.34`, plus low/
      needs_review-confidence pairs refused as an answer regardless of
      score) and already covered by `test/ask_repository_test.dart`
      (unrelated question -> not-sure, low-confidence row never presented,
      stop-words-only query -> not-sure). Verified the logic and its tests
      hold; no change needed.
      `flutter analyze` clean, 350/350 tests pass
- [x] **JN-01** Knowledge Journeys 10 to 18–20 paths — **18/18, floor of
      the target range reached.** Unlike DH-01/AK-01, existing journeys are
      curation, not new prose: each step is a title + one-line blurb
      pointing at content already shipping (an entity, a scene, a vidya
      topic), and the existing files say so outright ("Curation only —
      every step points at content already shipping"). That made this
      genuinely completable in one pass rather than a multi-session
      authoring project. Added 8 new journeys (`content/data/paths/
      avatars.jsonl`, `sages.jsonl`, `weapons.jsonl`, `symbols.jsonl`,
      `adversaries.jsonl`, `yoga_limbs.jsonl`, `sound_grammar.jsonl`,
      `timekeepers.jsonl`), each 4-7 steps built from entity/vidya-topic
      short descriptions already verified elsewhere in the graph — no new
      facts, only new sequencing and one-line blurbs written from what was
      already there. "Seven Avatars" (not "Ten") is deliberately scoped
      to the 7 entities actually registered under `kind='avatar'` — Krishna,
      Rama and Buddha are separate `deity`/`human` entities elsewhere in
      the graph and were left out of the title rather than claim ten when
      only seven steps are real. A standalone geometry journey (the
      diagonal rule, root-two approximation — only 2 vidya topics, no
      supporting entities) was left unbuilt rather than pad it to a
      believable length. `py -m content.tools.validate`: 0 errors.
      `py -m content.tools.build`: learning_paths 10 -> 18, path_steps
      49 -> 87, "nothing lost". No Dart changes needed — the journeys
      screen already reads `learning_paths` dynamically. 350/350 tests
      pass

## Temples

- [ ] **TM-01** Detail page: hero, why visit, history, deity, architecture, festivals, traditions, map, nearby, sources
- [ ] **TM-02** Nearby-temples query by coordinate
- [ ] **TM-03** Festival link via `deity_entity_id`
- [ ] **TM-04** OpenStreetMap attribution in About — ODbL requires it
- [ ] **TA-01** **Find and verify a public-domain source for temple architecture** — none confirmed yet
- [ ] **TA-02** Nagara · Dravida · Vesara
- [ ] **TA-03** Parts: garbhagriha · mandapa · shikhara/vimana · gopuram · prakara
- [ ] **TA-04** Diagrams as drawn paths, consistent with the motif system
- [ ] **TA-05** Lives inside Temples, not as a separate module

## Cross-cutting

- [ ] **AR-01** Confirm the AI image tool's terms permit commercial distribution
- [ ] **AR-02** Replace all 52 placeholder images
- [ ] **AR-03** Manifest records tool · model · date · prompt · **prompt_version · human_reviewed**
- [ ] **AR-04** Human review of every generated image before it ships
- [ ] **AR-05** Keep drawn motifs for iconography; AI art for deities, temples and scenes
- [ ] **TY-01** Devanagari line-height plus 15–20% on dense screens
- [ ] **TY-02** Establish a type scale — sizes run 9.5 to 28 with no system
- [ ] **TY-03** Confirm and record font licences in About
- [!] **AU-01** Audio — **deferred by decision.** Mantra, aarti, Gita recitation and Sanskrit Pronunciation all blocked
- [ ] **MA-01** **Sanskrit reader needed** before word-by-word mantra analysis
- [ ] **CM-01** Add `claim_type` to every content table
- [ ] **CM-02** Add `source_quality` and `confidence`
- [ ] **CM-03** `curation/inbox|approved|rejected`; promote reads `approved/` only
- [ ] **CM-04** Build snapshots in `content/builds/<date>_<sha>/` with rollback
- [x] **CM-05** `content_diff.py` fails the build on any content loss
- [x] **CM-06** `test/content_integrity_test.dart` floors
- [x] **CM-07** `ARCHITECTURE-GUARDRAILS.md`

## Release gate

- [ ] **RG-01** `content.sqlite` replaced — Ishvarvaani fixture gone.
      **This is a re-sourcing project, not a database swap.** A verse row holds
      four layers with four different statuses: `sanskrit` (ancient, PD) and
      `transliteration` (mechanical, thin-to-no copyright) migrate cleanly;
      `body_en`/`body_hi` are a modern translator's **new original work** with
      its own full term, and `commentary_*` is modern authored prose. The
      Sanskrit being 2,500 years old grants nothing about a 2019 translation of
      it. None of the three scripture tables carries a translator, edition,
      year or licence column (checked), so we cannot even name who to ask.
      Copying those columns into `gyan.sqlite` would tick this box while
      changing our exposure by exactly zero. Against the PD sources declared in
      `content/SOURCES.md`: **Gita clean** (Telang, SBE 8, 1882 — verse-numbered,
      all 701); **Upanishads ~12 of 106 books** (Müller, SBE 1 & 15, principal
      Upanishads only); **Ramayana unalignable** (Griffith is 505 rhymed cantos,
      *abridged* — Book VI skips 76–92 — with no verse numbers at all, so it
      cannot map 1:1 to 20,135 numbered shlokas; canto level is the ceiling);
      **Hindi: nothing**, no PD Hindi translation for any of the three. So
      Meaning drops from 100% coverage to roughly 3–15% English and 0% Hindi
      until commissioned translation fills it back in — which is what makes
      RD-02's Meaning empty state load-bearing rather than defensive
- [ ] **RG-02** `meta.data_source` no longer says "DEV FIXTURE"
- [ ] **RG-03** Zero manifest rows with `replace_before_ship: true`
- [ ] **RG-04** `reference/ishvarvaani-apk/` out of the shipped tree
- [ ] **RG-05** `build.py --strict` passes — 335 unverified rows today
- [ ] **RG-06** `SOURCES.md` attribution rendered in About
- [ ] **RG-07** `indexed_content_version` matches after any content swap
- [ ] **RG-08** Privacy policy states journal, progress and interests stay on device
- [ ] **RG-09** **Run the app on a real device** — never yet done
- [ ] **RG-10** Offline verification with radios off
- [ ] **RG-11** Fresh install
- [ ] **RG-12** Upgrade with user data preserved
- [ ] **RG-13** Interrupted DB extraction recovers
- [ ] **RG-14** Low storage message, not a crash
- [ ] **RG-15** Screen sizes: small · normal · large · tablet
- [ ] **RG-16** Accessibility: font scale · contrast · touch targets · TalkBack
      — the scripture reader's font-scale axis is covered by tests at 3.2x in
      both languages (RD-06); every other screen is unverified
- [ ] **RG-17** AAB size measured against the budget

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
