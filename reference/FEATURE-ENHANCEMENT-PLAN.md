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
- [ ] `tradition` selector appears when edges disagree, and says which is shown
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

- [ ] **RD-01** Tabs under the verse: Meaning · Explanation · Word meaning · Context
- [ ] **RD-02** Word-meaning tab renders an honest empty state until data exists
- [x] **RD-03** `RelatedRail` at the bottom of the section reader
- [ ] **RD-04** Verse actions row: bookmark · note · listen (TTS) · share text
- [ ] **RD-05** Per-chapter progress rings on the book list
- [ ] **RD-06** Hindi at max system font scale without overflow
- [ ] **RD-07** Reader tests + device check
- [ ] **SR-01** Group results by kind with per-kind counts
- [ ] **SR-02** Curated "Try" row driven by `importance`, not hardcoded
- [ ] **SR-03** One-edit-distance fallback when a query returns nothing
- [ ] **SR-04** Confirm no result taps through to the error page

## Knowledge system

- [ ] **KG-01** Widen the Wikidata pull: `P1080`, `P527`, `P361`, `P2789` + epic properties
- [ ] **KG-02** 100% of P0 entities have a description
- [ ] **KG-03** 100% of P0 entities have 3 or more verified relations
- [ ] **KG-04** 80% or more of P1 entities have 2 or more verified relations
- [x] **KG-05** Written empty state for an entity with no edges — 285 of 511 today
- [x] **KG-06** Group more than 20 relations by family
- [x] **KG-07** Relation-family filter chips
- [ ] **KG-08** Device check: pan and zoom performance on the canvas
- [ ] **FT-01** Relationship-type filter: Family · Lineage · Guru/Disciple · Dynasty
- [ ] **FT-02** Recursive layout to depth 3
- [ ] **FT-03** Collapse and expand past 4 children
- [ ] **FT-04** `tradition` selector when edges disagree
- [ ] **FT-05** Breadcrumb so a re-root walk is reversible
- [x] **SY-01** Prose on all 30 cosmology nodes — was 14; Creation and Time had none
- [x] **SY-02** Traditions-differ layer, rendered in its own panel
- [x] **SY-03** Brahmanda diagram replaces the loka list
- [x] **SY-04** Warm palette; starfield removed
- [ ] **SY-05** Decide whether Creation and Time need their own diagram
- [ ] **YG-01** Link each yuga to narrative nodes set in it
- [ ] **RS-01** Widen the rishi roster — 20 today, 2 with prose
- [ ] **RS-02** Prose for every P0 and P1 rishi
- [ ] **RS-03** Gotra · veda · guru · disciples · hymns · ashram populated
- [ ] **RS-04** Teaching-lineage mini-tree on the detail screen
- [ ] **RS-05** Attributions labelled "according to the cited tradition"
- [ ] **AS-01** Expand astras; `nature` shown near the top
- [ ] **AS-02** Rename "Powers" to traditional effect unless the source says otherwise
- [ ] **AS-03** Symbolism in its own panel, separate from the mythic account
- [ ] **SB-01** Expand symbols — 12 today; mudras and yantras absent
- [ ] **SB-02** Drawn motif where no Unicode glyph exists
- [ ] **VD-01** Expand vidya topics **only where they pass the evidence bar** — 34 excellent beats 50 padded

## Narrative

- [ ] **RM-01** Ramayana 32 to 45–50 scenes; Uttara Kanda has one
- [ ] **RM-02** Every scene linked to a `place` entity
- [ ] **RM-03** Location-journey filter: Ayodhya to Mithila to Lanka
- [ ] **MB-01** Mahabharata 29 to 45–55 events; every parva represented
- [ ] **MB-02** Optional parva rail beside the arc chips
- [ ] **NR-01** Add `chronology_confidence` — narrative order is not historical order
- [ ] **ST-01** Merge stories and kathas into one categorised list
- [ ] **ST-02** Every story entity-linked

## Practice & personal

- [ ] **SD-01** Sadhana entry point on Home
- [ ] **SD-02** Inline per-practice goal editing
- [ ] **SD-03** Milestones rail
- [ ] **SD-04** Frame as personal practice, not a productivity score
- [ ] **KJ-01** Journal prompts to 150–200, each cited to a verse
- [ ] **MN-01** Mandir: offering animates onto the idol
- [ ] **MN-02** Mandir uses the user's `ishta_deity`
- [ ] **MN-03** Confirm Kamal stays optional gamification, never a purchase
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

- [ ] **PN-01** Tap any panchang element to see what it is and how it is calculated
- [ ] **PN-02** Link panchang elements to the Jyotisha vidya topics
- [ ] **CW-01** Calendar wheel — circular year, festivals as marks
- [ ] **FE-01** Festivals 58 to 100–150 **verified** rules
- [ ] **FE-02** Nakshatra-within-solar-month rule — Onam returns no date today
- [ ] **FE-03** Festival to story-node link
- [ ] **FE-04** Festival to puja vidhi link
- [x] **KM-01** **Milan asks which side is bride and which is groom** — `_varna` is asymmetric while the form says "Side 1 / Side 2"
- [ ] **KM-02** Plain-language summary above the technical breakdown
- [ ] **KM-03** Partial matches shown as partial, never folded into the total
- [ ] **KM-04** A critical traditional flag is surfaced, not averaged away
- [ ] **KM-05** Methodology and its limits stated on the result screen
- [ ] **RF-01** Rashifal content pass plus "traditional interpretation, not prediction"

## Discovery & play

- [ ] **QZ-01** Explanation after every quiz answer
- [ ] **QZ-02** Quiz difficulty and category filters
- [ ] **QZ-03** `RelatedRail` on the quiz result
- [ ] **QZ-04** Riddle answer links to its entity
- [ ] **QZ-05** Trivia fact links to its entity
- [ ] **QZ-06** `relate.py` rule: quiz, riddle and trivia to entity, capped at 2
- [ ] **DH-01** Dharma scenarios 12 to 50–60
- [ ] **AK-01** Ask pairs 20 to 300–500
- [ ] **AK-02** Retrieval falls back to the 27,890 indexed shlokas
- [ ] **AK-03** Confidence threshold tuned so weak matches still say *not sure*
- [ ] **JN-01** Knowledge Journeys 10 to 18–20 paths

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

- [ ] **RG-01** `content.sqlite` replaced — Ishvarvaani fixture gone
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
