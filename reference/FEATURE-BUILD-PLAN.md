# Build Plan — FEATURE-REFERENCE-PLAN.md + Remaining App Work

## Context

`reference/FEATURE-REFERENCE-PLAN.md` is a **data-source blueprint**, not a build plan. It names 20 features and says roughly where their content should come from, but defines no schema, no screens, no routes, and no sequence. This document turns it into something executable: for every feature — **where the data comes from, how it is stored, and what the screen looks like** — plus the unfinished work already sitting in the app.

Current reality (verified against code, not the stale `PLAN.md`/`PROGRESS.md`):

- The app ships as **Aradhya** (`lib/app/brand.dart`), **34 routes**, 5-tab shell. Astrology (Kundli/Milan on Swiss Ephemeris), Panchang, scriptures reader (27,890 verses), devotional readers, quiz/riddles/trivia, 187 temples, puja vidhi, japa, breathing, habits, stories, personality, Rashifal and Android home widgets are **built and working**.
- Of the 20 reference features, **15 do not exist at all**; 5 exist partially.
- Three things the reference doc assumes are absent: **provenance columns** (zero anywhere), a **search index** (no FTS, no aliases, no search screen), and a **writable user DB** (everything is SharedPreferences — including an unbounded japa history rewritten in full on every bead tap).

**Decisions taken (user, this session):** new features first, no blocking foundation refactor; content via an AI-extract + human-verify pipeline; replacing the Ishvarvaani dev-fixture DB is out of scope here, recorded as a risk.

**This plan goes beyond the reference doc's 20** in three places, because the doc treats each feature as standalone and the result would be seventeen disconnected drawers: a **related-content engine** (§1.10) that links every screen to every other, **Knowledge Journeys** (4.21) that answer "where do I start?", and a **module registry** (§1.9) so a new module is declared once rather than in four lists. An **asset manifest** (§1.12) also turns the placeholder-art copyright gate from a comment into a build failure. The **bilingual contract** (§1.11) is stated once and enforced by the build rather than left to review.

---

# PART 0 — Sourcing rules (read before any content work)

## 0.1 Three sources named in the reference doc are legal problems

The reference doc repeatedly names sources that **cannot be used as bulk content**. This matters more than usual: the app already carries one copyright fixture. Do not add a second.

| Source | Verdict | Correct use |
|---|---|---|
| **vedabase.io** | ❌ **Do not extract.** Prabhupada translations/purports are © Bhaktivedanta Book Trust, actively enforced. | Nothing. Remove from the source list. |
| **drikpanchang.com** | ❌ **Do not scrape.** Proprietary computed data, ToS forbids it. | Nothing — you already compute panchang yourself in [panchang_engine.dart](lib/features/panchang/panchang_engine.dart). Festival *dates* are derived, not fetched. |
| **gitasupersite.iitk.ac.in** | ⚠️ Reference only. Aggregates modern commentaries under their own rights. | Human cross-checking a verse number. Never bulk extraction. |
| **sanskritdocuments.org** | ⚠️ Per-document terms; most texts are freely redistributable **with attribution**, some are not. | Sanskrit source text, checked per file, attribution recorded in `sources`. |

## 0.2 The sources that actually work

| Source | Licence | What it gives us |
|---|---|---|
| **Wikidata** (query.wikidata.org, SPARQL) | **CC0 — public domain** | The single best acquisition path for the entity graph. `P22` father, `P25` mother, `P26` spouse, `P40` child, `P1080` fictional universe, plus multilingual labels and aliases in en/hi/sa. Machine-readable, no scraping, no licence risk. |
| **Wikipedia** | CC BY-SA 4.0 | Usable **but share-alike is viral** — if we paste text, our descriptions inherit BY-SA. Rule: use as a *lead* to the primary text, write our own prose, never paste. Record as `source_type='reference'`. |
| **archive.org** | Per-item; the pre-1929 scans we want are PD | The public-domain translations below. |
| **Kisari Mohan Ganguli, Mahabharata** (1883–96) | PD | Complete English Mahabharata. |
| **Manmatha Nath Dutt / R.T.H. Griffith, Ramayana** (1891–94 / 1870–74) | PD | Complete English Ramayana. |
| **Kashinath T. Telang, Bhagavad Gita** (SBE vol. 8, 1882); **Edwin Arnold, Song Celestial** (1885) | PD | Gita translations. |
| **Max Müller et al., Sacred Books of the East** (1879–1910) | PD | Upanishads, Vedic hymns. |
| **H.H. Wilson, Vishnu Purana** (1840) | PD | Cosmology, lineages, yugas — the backbone of Srishty + Yuga + Family Tree. |
| **data.gov.in** | GODL-India | Temple/tourism datasets. |
| **OpenStreetMap / Nominatim** | ODbL, attribution required | Coordinates. |

> **Rule of thumb:** *structure* comes from Wikidata (CC0), *substance* comes from public-domain translations, *prose* is written by us and cited to both. Nothing is pasted from a BY-SA or © source.

## 0.3 Where AI is allowed

Per reference doc §2, AI is **rank 4** — after source data exists:

- ✅ Rewriting a PD translation's archaic English into modern, warm app copy (`short_description`, `long_description`).
- ✅ Hindi translation of our own English copy.
- ✅ Summarising a cited passage into a card blurb.
- ❌ Inventing a relation, a lineage, a date, a citation, or a verse reference. `extract.py` **discards any output line whose `sources[]` is empty** before it is written — this is enforced in code, not left to the validator.

---

# PART 1 — Architecture

## 1.1 Three stores

```
assets/db/content.sqlite   legacy fixture, untouched (main)          read-only
assets/db/gyan.sqlite      new content + provenance + search index   read-only, ATTACH AS gyan
<docs>/aradhya_user.db     user-authored data                        read-write, own connection
```

New content goes in its own asset. Why not extend `content.sqlite`: [content_database.dart](lib/core/db/content_database.dart) re-copies the **entire** 38 MB asset whenever `assetVersion` changes, so every content patch would rewrite 45+ MB. It also quarantines licence-clean content from the fixture, so purging the fixture later is a delete, not surgery.

Additive changes only — no signature breaks:

```dart
static const assetVersion     = '0.4.0-devfixture-native'; // FIX: says 0.4.2, DB says 0.4.0
static const gyanAssetVersion = '1.0.0';                   // BUILD_STAMP:gyan — rewritten by build.py
// after openReadOnlyDatabase(dest):
await db.execute("ATTACH DATABASE ? AS gyan", [gyanDest]);
```

Two independent `.version` markers so a Gyan patch never re-copies the fixture. `build.py` must finish with `PRAGMA journal_mode=DELETE; VACUUM;` — a WAL file cannot be opened read-only on device.

## 1.2 One shared entity core

Knowledge Graph (4.1), Family Tree (4.2), Symbols (4.10), Weapons (4.12) and Rishis (4.13) are all *"a named thing with descriptions, aliases, citations, and typed links to other named things."* One substrate, five presentations. Family Tree is **not a dataset** — it is `relations` filtered to `father_of | mother_of | spouse_of | guru_of`.

```sql
CREATE TABLE entities (
  id INTEGER PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  kind TEXT NOT NULL CHECK (kind IN ('deity','avatar','rishi','king','asura','human',
       'place','river','mountain','scripture','festival','weapon','symbol',
       'concept','dynasty','yuga','loka','vidya')),
  title_en TEXT NOT NULL, title_hi TEXT, title_sa TEXT, title_iast TEXT,
  category TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,   -- <=200 chars, card blurb
  long_description_en  TEXT,          long_description_hi  TEXT,
  region TEXT, tradition TEXT, tags TEXT,        -- tags = JSON array
  props TEXT,                                    -- kind-specific JSON, schema-checked at build
  image_asset TEXT, glyph TEXT,
  importance INTEGER NOT NULL DEFAULT 3,         -- 1 major..5 minor; drives search boost + tier
  wikidata_qid TEXT,                             -- provenance + re-sync key
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT,
  verification_status TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed'))
);
CREATE INDEX ix_entities_kind ON entities(kind, importance);

CREATE TABLE entity_aliases (
  entity_id INTEGER NOT NULL REFERENCES entities(id),
  alias TEXT NOT NULL,
  alias_fold TEXT NOT NULL,          -- lowercased + diacritic-folded, for search
  script TEXT, lang TEXT, alias_kind TEXT
);
CREATE INDEX ix_alias_fold ON entity_aliases(alias_fold);

CREATE TABLE relations (
  id INTEGER PRIMARY KEY,
  src_id INTEGER NOT NULL REFERENCES entities(id),
  rel_type TEXT NOT NULL,
  dst_id INTEGER NOT NULL REFERENCES entities(id),
  ordinal INTEGER,                   -- birth order among siblings
  tradition TEXT,                    -- §4.2: lineages differ by tradition
  note_en TEXT, note_hi TEXT,
  confidence TEXT NOT NULL DEFAULT 'high'
      CHECK (confidence IN ('high','medium','low','disputed'))
);
CREATE INDEX ix_rel_src ON relations(src_id, rel_type);
CREATE INDEX ix_rel_dst ON relations(dst_id, rel_type);
```

`rel_type` vocabulary lives in `validate.py`, not SQL, so it can grow: **lineage** `father_of` `mother_of` `spouse_of` `sibling_of`; **teaching** `guru_of` `disciple_of`; **epic** `wields` `killed_by` `incarnation_of` `mount_of` `consort_of`; **text** `authored` `appears_in`; **place** `located_in` `ruled_by` `worshipped_at`; **generic** `related_to` `symbol_of` `part_of`. `build.py` materialises inverse edges so every query is single-direction.

`props` holds kind-specific fields instead of 40 mostly-null columns, validated against `content/schema/kinds/*.schema.json`:

```jsonc
"weapon": {"weapon_type":"astra","invocation":"mantra","powers_en":[…],
           "counter_en":"…","symbolic_meaning_en":"…","nature":"mythic"}
"symbol": {"visual_form_en":"…","common_usage_en":"…","meaning_varies_by":["shaiva","vaishnava"]}
"rishi":  {"gotra":"…","ashram_place_slug":"naimisharanya","hymns":["RV 3.62.10"],"veda":"rigveda"}
"deity":  {"vahana_slug":"garuda","consort_slugs":["lakshmi"],"ayudha_slugs":["sudarshana-chakra"]}
```

## 1.3 Provenance — normalized, with a denormalized fast path

Reference doc §3 lists 16 fields per entry. Do **not** flatten all 16: `temples.data` already proves the cardinality (12 source URLs on one temple), and flat columns would duplicate licence text thousands of times.

- Descriptive fields → columns on the content table.
- Citation fields → `sources` registry + `item_sources` join.
- `aliases` → `entity_aliases`; `related_items` → `relations` (both needed as rows anyway).
- **`primary_source_name` / `_ref` / `_url` denormalized onto every content table** so a card renders a citation line without a join. `build.py` derives it, so it cannot disagree.

```sql
CREATE TABLE sources (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  source_name TEXT NOT NULL, source_url TEXT,
  source_type TEXT NOT NULL CHECK (source_type IN ('primary','secondary','reference','ai_summary')),
  source_language TEXT, edition TEXT,
  license_or_usage_note TEXT NOT NULL,
  retrieved_at TEXT, checksum TEXT
);

CREATE TABLE item_sources (
  item_table TEXT NOT NULL, item_id INTEGER NOT NULL,
  source_id INTEGER NOT NULL REFERENCES sources(id),
  source_chapter_or_section TEXT, quote TEXT,
  last_verified_at TEXT NOT NULL, verified_by TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (item_table, item_id, source_id, source_chapter_or_section)
);
CREATE INDEX ix_item_sources_item ON item_sources(item_table, item_id);
```

New tables are born with this. Retrofitting legacy tables is deferred (per decision) — see Risk 1.

## 1.4 Writable store — `aradhya_user.db`

Rule: **prefs for O(1) scalars read every frame; SQLite for collections and anything needing sort, date-range, join or search.**

Stays in prefs: `onboarded`, `user_name`, `ishta_deity`, `personality_result`, `rashifal_rashi`, `birth_details_json`, locale, theme, font scale, and the streak/currency scalars (`StreakController._load()` reads synchronously — prefs stay the fast path, history mirrors to DB).

Moves to SQLite: `bookmarks_json` (needs notes/tags/timestamps) · `japa_history_json` (**unbounded**, and [japa.dart:128](lib/core/user/japa.dart#L128) re-encodes the whole blob per bead tap — `shared_preferences` rewrites the entire XML per `apply`) · `habits_<dayStamp>` (**one prefs key per day, forever** — a key-space leak) · `temples_visited` · `scripture_pos_<bookId>`.

Schema v1 in `lib/core/db/user_schema.dart`:

| Table | Purpose |
|---|---|
| `bookmarks` | 4.5 — `note`, `tags`, `created_at`, plus a resolved `route` (structurally prevents the G2 bug class) |
| `reading_progress` | 4.4 — `last_section_idx`, `sections_total`, `sections_read`, `last_read_at`, `completed_at` |
| `sadhana_sessions` | 4.16 — one row per practice: `day_stamp`, `practice`, `count`, `duration_s`, `meta` |
| `sadhana_goals` | 4.16 — target + `reminder_min` per practice |
| `journal_entries` | 4.17 — `body`, `mood`, `lesson`, `prompt_text` (frozen copy), `is_private` default 1 |
| `reminders` | notification handles for 4.16 / 4.17 / 4.18 |
| `temple_visits` | visit dates for Yatra history |
| `currency_ledger` | audit trail for Punya / Kamal |
| `user_meta` | `schema_version`, `migrated_from_prefs` |

**Migration (lossless).** `_migrateFromPrefs` runs in one transaction and sets its flag last, so a crash re-runs cleanly. Habits keys are enumerable via `prefs.getKeys().where(startsWith(...))`, so nothing is lost despite one key per historical day. Bookmark routes resolve at migration time; unresolvable rows are kept with `route=''`, shown but not tappable — **never dropped**. **Legacy prefs keys are not deleted in v1** — dormant for one release so a rollback still has data; delete in v2.

`BookmarksController`, `JapaController`, `HabitsController`, `VisitedController` keep their exact public API (`toggle`, `addCounts`, `state`) — only the persistence body changes, so no call site across 110 Dart files is touched.

## 1.5 Universal Search — portable inverted index, built offline

`sqflite` uses the **system** SQLite, where FTS5 availability varies by Android version and OEM. Rather than swapping the whole DB stack to `sqlite3_flutter_libs` for a 35k-row corpus, build a plain B-tree inverted index at content-build time. The expensive part — normalization and alias expansion — has to happen in `build.py` for *any* backend; storage is a swappable detail behind `SearchRepository`.

```sql
CREATE TABLE search_docs (
  doc_id INTEGER PRIMARY KEY,
  src TEXT NOT NULL,            -- 'content' (legacy) | 'gyan'
  kind TEXT NOT NULL,           -- 'temple','mantra','shloka','entity','festival','city',…
  ref_table TEXT NOT NULL, ref_id INTEGER NOT NULL,
  title_en TEXT NOT NULL, title_hi TEXT,
  subtitle_en TEXT, subtitle_hi TEXT, snippet_en TEXT, snippet_hi TEXT,
  route TEXT NOT NULL,          -- resolved deep link
  boost REAL NOT NULL DEFAULT 1.0
);
CREATE UNIQUE INDEX ix_docs_ref ON search_docs(src, ref_table, ref_id);

CREATE TABLE search_tokens (
  token TEXT NOT NULL, doc_id INTEGER NOT NULL,
  field INTEGER NOT NULL,       -- 0=title 1=alias 2=tag 3=subtitle 4=body
  tf INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX ix_tokens ON search_tokens(token, doc_id);
```

**Folding** — one algorithm, two implementations (`content/tools/common.py` and `lib/features/search/search_fold.dart`), pinned by a golden test against a shared fixture so they cannot drift: NFKD → strip combining marks → lowercase → strip punctuation → for Latin also emit an ASCII-simplified variant (`ṛ→ri`, `ṣ→sh`, `ś→sh`, `ā→a`) so `krishna` and `kṛṣṇa` both hit → for Devanagari keep as-is plus emit IAST as an alias token. Prefix search is a range scan at query time, not stored:

```sql
SELECT t.doc_id, SUM(t.tf * CASE t.field WHEN 0 THEN 10 WHEN 1 THEN 8
                                         WHEN 2 THEN 4 WHEN 3 THEN 3 ELSE 1 END) AS score
FROM gyan.search_tokens t
WHERE t.token >= ?1 AND t.token < ?1 || CHAR(1114111)
GROUP BY t.doc_id ORDER BY score DESC LIMIT 200;
```

**Spanning the legacy DB without touching it** — the move that honours "defer the retrofit" while still delivering search over 34k existing rows: `build.py` opens `content.sqlite` **read-only**, extracts titles/deities/tags from `temples`, `mantras`, `aartis`, `chalisas`, `stories`, `kathas`, `puja_vidhi`, `scripture_sections`, `cities`, `quotes`, and writes their `search_docs`/`search_tokens` rows **into `gyan.sqlite`**.

Staleness guard: `gyan.meta.indexed_content_version` records the `content.sqlite` version the index was built against. Build fails on mismatch; the app degrades via `searchIndexStaleProvider` rather than crashing.

## 1.6 Navigation — the `/gyan` hub

Fifteen modules need one home. `/gyan` (ज्ञान) is a hub modelled on [jyotish_hub_screen.dart](lib/features/hubs/jyotish_hub_screen.dart) — `_CosmicHero` + `_BigCard` grid, the proven pattern in this codebase.

- **Stage 1 (Phase 1):** `/gyan` is a pushed route entered from a new Home "Explore Gyan" section (4 featured tiles + See all) and a You-tab tile. **Zero change to [nav_scaffold.dart](lib/app/shell/nav_scaffold.dart).** All 15 modules ship this way.
- **Stage 2 (Phase 4, optional, own commit):** promote Gyan to a tab by merging `/cosmos` into `/jyotish` — both are jyotish, and that redundancy is the only slack in the bar. `/cosmos` survives as a pushed route for deep links and the home widget. New bar: **Home · Gyan · Jyotish · Yatra · You**. Not a sixth tab: 5 tabs at 58 px already crowd the Hindi labels.

Routes added to [app_router.dart](lib/app/router/app_router.dart):

```
/search                        ?q= deep link
/gyan                          hub
  /gyan/graph                            4.1
  /gyan/entity/:entityId                 shared detail for every entity kind
  /gyan/lineage/:entityId                4.2
  /gyan/rishis · /astras · /symbols      4.13 · 4.12 · 4.10 (one EntityListScreen(kind:))
  /gyan/srishty · /srishty/:nodeId       4.6
  /gyan/yuga                             4.14
  /gyan/ramayana · /mahabharata · /scene/:nodeId   4.7 · 4.8
  /gyan/vidya · /vidya/:topicId          4.15
/dharma · /dharma/play/:scenarioId       4.11 (beside /quiz)
/festivals · /festivals/:festivalId      4.18 (with panchang/calendar)
/ask                                     4.19
/journal · /journal/new · /journal/entry/:entryId   4.17
/sadhana                                 4.16 (absorbs japa/breathing/habits; those routes stay)
/mandir                                  G1
/scriptures/book/:bookId                 G2 — redirect alias resolving scriptureId, fixes the crash
```

## 1.7 Design tokens for the new surfaces

[category_colors.dart](lib/app/theme/category_colors.dart) is a `ThemeExtension` with 9 fixed `CategoryStyle` fields — adding is additive (plus the `copyWith`/`lerp` bodies). Four new gradients; two modules deliberately **reuse** existing ones because they belong to the same domain:

| Token | Gradient | Used by |
|---|---|---|
| `gyan` | `#3E7F8E → #1D4552` teal | Gyan hub, Knowledge Graph, entity screens |
| `srishty` | `#4A3A7A → #1E1440` cosmic indigo | Srishty Universe, Yuga Explorer |
| `epics` | `#8A6A4F → #4A3220` manuscript sepia | Ramayana Journey, Mahabharata Timeline |
| `sadhana` | `#3F7A5E → #25533F` sacred green | Sadhana Tracker, Karma Journal, Mandir |
| *(reuse `panchang`)* | `#E0762A → #A7430F` | Festival Explorer — same calendar domain |
| *(reuse `personality`)* | `#A85A8C → #5C2549` | Dharma Decision Game — same reflective register |

Everything else stays on the existing vocabulary: paper `#FDF8F5`, cards 18–28 px radius, chips 14 px, pill buttons, soft shadow, **Eczar** for display, **Ramaraja** for quotes/Sanskrit accents, **Inter** for UI, **Noto Sans Devanagari** for Hindi, and the signature dashed [stitched_border.dart](lib/shared/widgets/stitched_border.dart) for selected/featured states.

**Two new shared widgets, built once in Phase 1 and reused by every module below:**

- `SourceChip` — the citation line. A small gold-outlined pill: `📜 Vishnu Purana 1.3.12 ›`, tapping opens a bottom sheet with full source name, edition, licence note, `last_verified_at`, and an "Open source" link. Renders **only when `primary_source_name` is non-null**, so legacy content shows nothing rather than an empty state.
- `VerificationChip` — amber `⚠ Unverified` pill, shown only when `verification_status != 'verified'` and `meta.build_profile = 'dev'`. Makes content debt visible in-product instead of in a spreadsheet.

## 1.8 Content pipeline — `content/`, Python 3

Python over Dart: `sqlite3` is stdlib; `jsonschema` / `indic-transliteration` / `unidecode` / `rapidfuzz` / `SPARQLWrapper` are one-line installs; extraction is text/HTTP heavy; none of it ships to the device. Windows-safe: `pathlib` throughout, no shell pipelines, entry point `python -m content.tools.build`, with `content/make.ps1` wrapping common invocations.

```
content/
  README.md  SOURCES.md(generated)  requirements.txt  make.ps1
  schema/  gyan.sql  legacy_content.sql(reference only)  kinds/*.schema.json
  sources/ registry.jsonl  excluded.jsonl
  raw/     GITIGNORED — downloaded text + sha256 sidecars
  queries/ wikidata/*.rq       -- the SPARQL used per module, version-controlled
  data/    entities/ relations/ cosmology/ narrative/ dharma/ vidya/
           festivals/ ask/ journal/  + existing quiz|riddles|trivia.jsonl
  tools/   common.py fetch.py wikidata.py extract.py validate.py build.py
           index.py relate.py report.py
  build/   GITIGNORED — report.html, build logs
```

**Every JSONL line, every module, carries the §3 block.** Full example — `content/data/entities/astras.jsonl`:

```json
{
  "slug": "brahmastra",
  "kind": "weapon",
  "wikidata_qid": "Q862072",
  "title": {"en":"Brahmastra","hi":"ब्रह्मास्त्र","sa":"ब्रह्मास्त्र","iast":"brahmāstra"},
  "category": "astra",
  "short_description": {
    "en": "The astra presided over by Brahma, invoked by mantra and described as irresistible once released.",
    "hi": "ब्रह्मा द्वारा अधिष्ठित अस्त्र, जो मंत्र से आह्वान किया जाता है…"},
  "long_description": {"en":"…","hi":"…"},
  "aliases": [
    {"alias":"Brahma Astra","script":"latn","lang":"en","alias_kind":"spelling"},
    {"alias":"ब्रह्मास्त्र","script":"deva","lang":"sa","alias_kind":"primary"},
    {"alias":"brahmāstra","script":"iast","lang":"sa","alias_kind":"transliteration"}],
  "tags": ["astra","brahma","mahabharata","ramayana"],
  "region": "pan-india", "tradition": null, "importance": 1,
  "props": {"weapon_type":"astra","invocation":"mantra",
            "powers_en":["Described as unstoppable once discharged"],
            "counter_en":"Traditionally neutralised only by another Brahmastra or by withdrawal",
            "symbolic_meaning_en":"The destructive potential of knowledge without restraint",
            "nature":"mythic"},
  "related_items": [
    {"rel_type":"wielded_by","dst_slug":"arjuna","confidence":"high"},
    {"rel_type":"wielded_by","dst_slug":"ashwatthama","confidence":"high"},
    {"rel_type":"mentioned_in","dst_slug":"mahabharata","confidence":"high"}],
  "sources": [
    {"source_slug":"ganguli-mahabharata","source_chapter_or_section":"Sauptika Parva, Section 13–15",
     "quote":null,"is_primary":true,"last_verified_at":"2026-07-20","verified_by":"TS"},
    {"source_slug":"wikidata","source_chapter_or_section":"Q862072",
     "is_primary":false,"last_verified_at":"2026-07-20","verified_by":"TS"}],
  "verification": {"status":"verified","by":"TS","at":"2026-07-20","notes":""}
}
```

`content/sources/registry.jsonl`:

```json
{"slug":"ganguli-mahabharata","source_name":"The Mahabharata, tr. Kisari Mohan Ganguli","source_url":"https://archive.org/details/...","source_type":"primary","source_language":"en","edition":"P.C. Roy, Calcutta, 1883-1896","license_or_usage_note":"Public domain (published pre-1929).","retrieved_at":"2026-07-18","checksum":"sha256:..."}
{"slug":"wikidata","source_name":"Wikidata","source_url":"https://www.wikidata.org/","source_type":"reference","source_language":"mul","edition":null,"license_or_usage_note":"CC0 1.0 Universal - public domain dedication.","retrieved_at":"2026-07-18","checksum":null}
```

**Six stages:**

1. **`wikidata.py`** — runs the versioned SPARQL in `queries/wikidata/`, emits entity skeletons (slug, qid, labels en/hi/sa, aliases) and relation edges. CC0, no scraping, re-runnable to pick up upstream fixes.
2. **`fetch.py`** — downloads whitelisted PD texts into `raw/`, records `sha256` + `retrieved_at` into `registry.jsonl`. Refuses any domain in `excluded.jsonl` (vedabase, drikpanchang, the Ishvarvaani fixture). Idempotent on checksum. `raw/` is gitignored — checksums make it reproducible without committing scans.
3. **`extract.py`** — the AI step. Fills descriptions/props from `raw/`, `status='unverified'`, every claim carrying the `source_slug` + section the model was shown. **Empty `sources[]` ⇒ the line is discarded in code.**
4. **`validate.py`** — the gate, exits non-zero on: schema conformance · unknown `source_slug` · no primary/secondary source · bad or future `last_verified_at` · dangling `dst_slug` · exact title dupe within a kind · empty `license_or_usage_note` or excluded domain · empty `vidya_topics.caution_*` (§4.15 medical rule) · empty `festivals.region` (§4.18) · emitted `route` not matching `content/tools/routes.txt` · `indexed_content_version` mismatch · **missing `title_hi` or `short_description_hi` (error under `--strict`, warning in dev)**. Warnings: near-dupe (rapidfuzz > 0.90), missing `long_description_hi`, unmaterialisable relation inverse.
5. **`build.py`** — `data/` + read-only `content.sqlite` → `gyan.sqlite`. Resolves slugs→ids, materialises inverse relations, denormalizes `primary_source_*`, builds the search index via `index.py` and the cross-module related-content edges via `relate.py` (§1.10), writes `meta`, runs `journal_mode=DELETE; VACUUM; integrity_check`, regenerates `SOURCES.md`, rewrites the Dart const. Flags: `--strict` (release: refuse `status != 'verified'`, and refuse any asset still flagged `replace_before_ship`), `--allow-unverified` (dev), `--modules a,b,c` (module ids come from the registry in §1.9).
6. **`report.py`** — the **content health dashboard**, written to `content/build/report.html` after every build and printed as a summary table to the console. Per module: total · verified · unverified · disputed · missing Hindi · missing `long_description` · entities with no image · **broken relations** (dangling `dst_slug`, or a lineage edge with no materialisable inverse) · **duplicate aliases** across different entities (a real search-quality bug — two entities answering to "Vasu") · items with only a `reference`-type source and no primary/secondary · assets referenced but absent from the manifest. Each row links to the offending `data/*.jsonl` line number. This is the artefact that keeps a 5,000-row corpus honest; `validate.py` says *stop*, `report.py` says *what to work on next*.

**Version stamping** closes the drift permanently: `build.py` writes `meta.content_version = "{semver}+{date}.{git_sha}"` plus `indexed_content_version` and per-table counts, then regex-rewrites the single `// BUILD_STAMP:gyan` line. `test/db_version_test.dart` asserts both bundled DBs' `meta.content_version` equal their Dart consts — which also catches today's `0.4.2` vs `0.4.0` mismatch.

`SOURCES.md` is **generated, never hand-edited**: primary/secondary/reference sections with licence + "cited by N items across…", an excluded-sources table, a verbatim attribution block for the About screen (needed for Play compliance anyway), and a verification-status table.

## 1.9 Module registry — one declaration, four consumers

The same 17 modules currently need to be listed in four places: the Gyan hub tile grid, the search filter chips, `build.py --modules`, and the coming-soon gating. Four lists drift. **One `const` list drives all four.**

```dart
// lib/features/gyan/gyan_modules.dart
class GyanModule {
  final String id;          // 'astras' — matches search_docs.kind AND build.py --modules
  final String route;       // '/gyan/astras'
  final String titleEn, titleHi, blurbEn, blurbHi;
  final IconData icon;
  final CategoryStyle Function(CategoryColors) style;
  final String backingTable; // 'entities' — used by report.py and the empty-state check
  final bool shipped;        // false → the hub tile renders the coming-soon state
  const GyanModule({...});
}

const gyanModules = <GyanModule>[
  GyanModule(id: 'graph', route: '/gyan/graph', titleEn: 'Knowledge Graph', …, shipped: false),
  GyanModule(id: 'rishis', route: '/gyan/rishis', …),
  … // 17 entries
];
```

**Deliberately not a plugin system.** Dynamic module loading buys nothing here: `go_router` needs its routes registered at compile time for deep links and tree-shaking, Flutter has no runtime code loading, and the DB is one bundled file. A static registry gets the maintainability win — add a module in one place, and the hub tile, the search chip, the pipeline flag and the health report all pick it up — without inventing an abstraction layer that only ever has one implementation. Routes stay explicit in [app_router.dart](lib/app/router/app_router.dart); a test asserts every `GyanModule.route` resolves against `appRouter.configuration`, and `build.py` reads the exported `content/tools/modules.json` (emitted from the Dart list by that same test) so the two sides cannot drift.

## 1.10 Related-content engine — the connective tissue

**The single highest-value addition to this plan.** Right now every screen is a dead end. It should not be: open Hanuman and the app already owns the Hanuman Chalisa, Sundara Kanda scenes, ~14 Hanuman temples, his mantras, his gada, his place in the Vanara lineage, quiz questions about him, and Hanuman Jayanti. None of that is connected.

**Precompute the edges at build time**, exactly like the search index — not runtime joins. Same table lives in `gyan.sqlite`, same trick spans the legacy DB without modifying it:

```sql
CREATE TABLE related_edges (
  src_src   TEXT NOT NULL, src_table TEXT NOT NULL, src_id INTEGER NOT NULL,
  dst_src   TEXT NOT NULL, dst_table TEXT NOT NULL, dst_id INTEGER NOT NULL,
  dst_kind  TEXT NOT NULL,          -- drives the group header + glyph
  reason    TEXT NOT NULL,          -- 'deity','relation:wields','cast','tag','festival_deity'
  weight    REAL NOT NULL,
  title_en  TEXT NOT NULL, title_hi TEXT,
  subtitle_en TEXT, subtitle_hi TEXT,
  route     TEXT NOT NULL           -- denormalized: one query renders the whole rail, no N+1
);
CREATE INDEX ix_related_src ON related_edges(src_src, src_table, src_id, weight DESC);
```

`relate.py` builds it with deterministic rules (reproducible, no randomness, no model):

| Rule | Example | Weight |
|---|---|---|
| entity ↔ legacy content by **folded deity name/alias** (`chalisas.deity`, `aartis.deity`, `mantras.deity`, `temples.deity_en`, `puja_vidhi.deity`) | Hanuman → Hanuman Chalisa, 14 temples | 0.90 |
| entity ↔ `narrative_nodes` via `narrative_cast` | Hanuman → Sundara Kanda scenes | 0.85 |
| entity ↔ `festivals` via `deity_entity_id` | Hanuman → Hanuman Jayanti | 0.80 |
| entity ↔ entity via `relations` | Hanuman → Rama, Vanara lineage, gada | 0.75 |
| verse ↔ entity where an alias appears in the translation | Gita 11.x → Arjuna | 0.50 |
| tag overlap (Jaccard ≥ 0.3) | bhakti topics ↔ bhakti path | 0.40 |
| quiz/trivia ↔ entity by alias in the question text | noisy — hard-capped at 2 per source | 0.30 |

Capped at **12 edges per source**, minimum weight 0.3, deduped by `(dst_table, dst_id)` keeping the highest weight. `report.py` lists any entity with zero outbound edges — usually a sign its aliases are wrong.

**UI — one widget, every detail screen.** `RelatedRail(src:, table:, id:)` renders at the bottom of *every* detail page in the app: entity, scene, festival, temple, mantra, aarti, puja, story, verse. Horizontally scrolling 140 px cards grouped under small kind headers (`In the epics` · `Temples` · `Chant` · `Festivals` · `Learn more`), each card carrying its kind glyph on that kind's category gradient. Above it, a thin gold rule and the heading *"Continue exploring"* in Eczar. Because `route` is denormalized, the rail is a single indexed query — it can render synchronously on first frame with no skeleton.

This is what turns 17 modules into one app rather than a drawer of seventeen apps, and it works entirely offline.

## 1.11 Bilingual contract (EN / HI, with Sanskrit alongside)

The app is bilingual end to end, and that is a **content requirement, not a translation task done at the end**.

**Data.** Every content table carries `_en` / `_hi` pairs for `title`, `short_description`, `long_description`, and every module-specific prose field (`lesson_*`, `caution_*`, `ritual_summary_*`, `consequence_*`, `blurb_*`). `entities` additionally carries `title_sa` (Devanagari canonical) and `title_iast` — so a deity shows *Krishna · कृष्ण · कृष्णः · kṛṣṇa* without conflating Hindi with Sanskrit. `entity_aliases.lang` / `.script` mean every spelling in every script is searchable, which is what makes `krishna`, `कृष्ण` and `kṛṣṇa` return the same row.

**Derived surfaces inherit it.** `search_docs` stores `title_en/hi`, `subtitle_en/hi`, `snippet_en/hi`; `related_edges` stores `title_en/hi`, `subtitle_en/hi`. Both render in the active language from one indexed query — no runtime join, no fallback flash.

**Enforcement.** Missing `title_hi` or `short_description_hi` is an **error under `build.py --strict`**, so an English-only entry cannot reach a release build. It stays a warning in dev so work in progress isn't blocked. `report.py` tracks Hindi coverage per module as a first-class metric.

**Verification is per-language.** The `verification` block gets `status_en` and `status_hi`. English is verified against the cited source; **Hindi is verified for register, not just accuracy** — machine-translated Hindi reads flat and occasionally wrong for devotional content, and this is a spiritual app where tone carries meaning. An entry can legitimately be `verified` in English and `unverified` in Hindi; `--strict` requires both.

**Typography risk in the new dense screens.** Devanagari needs ~15–20% more line-height than Latin and its words are frequently longer. Existing screens handle this, but several new surfaces are tight: 56 px family-tree node cards, knowledge-graph edge label chips, timeline arc bands, `modern_status` chips, and the 5-tab bar (already the reason Gyan is not a sixth tab). **Every new screen is laid out in Hindi first, then checked in English** — the reverse order produces overflow that only shows up after the fact.

**The convention itself must be settled before the modules are written — see G14 below, which moves to Phase 1 for exactly this reason.**

## 1.12 Asset manifest — and why it matters more here than usual

`assets/images/` holds 52 files whose licence status is the app's **top release blocker**: [reference_art.dart](lib/shared/reference_art.dart) flags them as Ishvarvaani placeholders, and the filenames match `reference/ishvarvaani-app-images/` 1:1. Today the only record of that is a comment. Make it data.

```jsonc
// assets/manifest.json — one row per shipped asset
{"id":"deity_hanuman_full","path":"assets/images/hanuman.png","category":"deity",
 "subject_slug":"hanuman","theme":"light","w":1024,"h":1536,"bytes":214553,
 "license":"PLACEHOLDER-ISHVARVAANI","source_url":null,"artist":null,
 "version":1,"replace_before_ship":true}
```

`validate.py` enforces: every file under `assets/images/` has a manifest row · every `entities.image_asset` / `narrative_nodes.image_asset` resolves to one · every row has a non-empty `license` · **`build.py --strict` refuses to produce a release build while any row has `replace_before_ship: true`.** That converts the copyright gate from a note in `PROGRESS.md` into a build failure, which is the only kind of gate that actually holds. It also gives the art replacement effort a worklist with exact dimensions, and lets `reference_art.dart` resolve by `subject_slug` instead of a hand-maintained switch.

---

# PART 2 — The 17 new features, in detail

Each entry: **where the data comes from → how it is stored → what the screen looks like.**

---

## 4.1 Sanatan Knowledge Graph · `/gyan/graph` · teal

**Data.** Two-pass acquisition.
*Pass 1 — skeleton from Wikidata (CC0).* A SPARQL query over `wdt:P31/P279*` for Hindu deities, epic characters, sages, sacred places, dynasties, plus `P22/P25/P26/P40` edges and `rdfs:label`/`skos:altLabel` in en/hi/sa. Gives ~600 entities and ~2,000 raw edges with zero licence risk, already multilingual.
*Pass 2 — substance from PD texts.* `extract.py` reads Ganguli's Mahabharata, Dutt's Ramayana, Wilson's Vishnu Purana and SBE Upanishads from `raw/`, writes our own `short_description` / `long_description`, and attaches the citing parva/kanda/chapter to each entity.
*Human verify.* Every relation with `confidence != 'high'` and every entity with `importance <= 2` is eyeballed against the cited passage before `--strict` will ship it.
**Target: ~500 entities, ~1,500 relations, ~2,000 aliases.** Ship at 150 verified entities; grow.

**Storage.** `entities` + `relations` + `entity_aliases` + `item_sources`. Nothing bespoke.

**UI.** *Graph screen* — a full-bleed `InteractiveViewer` on paper ground with a subtle mandala watermark. The focused entity sits centre as a 72 px circular node (deity art from `image_asset` if present, else an Eczar monogram on a category gradient); up to 12 neighbours orbit it, positioned by relation family — lineage above, teaching left, epic right, place below — connected by 1.2 px gold curves. Each edge carries a tiny centred label chip (`father of`, `guru of`). Tapping a neighbour **re-centres with a 350 ms animated transition** rather than pushing a route, so exploration feels continuous; a breadcrumb rail along the top keeps the path back. Pinch to zoom, double-tap to fit. A bottom sheet peeks the focused entity's name, `SourceChip`, and a "Full page ›" button to `/gyan/entity/:id`. Filter chips on the app bar toggle relation families on/off.

*Entity detail (`/gyan/entity/:id`, shared by 4.1/4.2/4.10/4.12/4.13)* — `SliverAppBar` with the deity/symbol art or a gradient wash by `kind`, title in Eczar with the Devanagari `title_sa` beneath in Noto, then IAST in muted Ramaraja italic. Below: an alias wrap-chip row · `short_description` in 17 px Inter · a `SourceChip` row · a stitched-border "Props" card whose rows are driven by `kind` (a weapon shows Type / Wielder / Powers / Counter / Symbolism; a rishi shows Gotra / Veda / Ashram / Hymns) · a **Connections** section grouping `relations` by family, each row a tappable avatar + name + relation label · "Appears in" linking to `narrative_nodes` and `scripture_sections` · bookmark action in the app bar (writes `kind='entity'` to the new `bookmarks` table).

---

## 4.2 Family Tree · `/gyan/lineage/:entityId` · teal

**Data.** Free — it is `relations` filtered to `father_of | mother_of | spouse_of | sibling_of | guru_of`. Wikidata supplies the spine; Wilson's Vishnu Purana (Book IV is entirely dynastic lists) and the Mahabharata Adi Parva supply the citations and the cases Wikidata gets wrong. **Where traditions disagree, store both edges with different `tradition` values** rather than picking a winner — §4.2 explicitly calls for this.

**Storage.** No new table. `relations.tradition` and `relations.ordinal` (birth order) carry the whole feature.

**UI.** A dedicated pan/zoom canvas (`CustomPainter`, not a widget tree — a 5-generation Kuru tree is ~80 nodes). Generations run **top-to-bottom**, siblings left-to-right by `ordinal`. Node = 56 px rounded-rect card, cream `#FFFDF9`, 1 px gold border, name in Eczar 13 px with Devanagari beneath; the root node gets the stitched dashed outline. Spouse pairs are joined by a short horizontal double line; children descend from the midpoint. Long-press a node to **re-root** the tree there. A segmented control at the top switches `tradition` when more than one exists for the visible edges, with an inline note — *"Lineage as given in the Vishnu Purana"* — and a `SourceChip`. Collapse/expand chevrons on any node with >4 children keep the canvas readable. Entry points: a "View lineage" button on any entity detail that has ≥2 lineage edges, plus a Gyan-hub tile that opens a picker of the 12 major dynasties (Ikshvaku, Kuru, Yadu, Bhrigu…).

---

## 4.3 Universal Search · `/search` · (no gradient — paper)

**Data.** Not authored. `index.py` derives it: for `gyan.sqlite` from `entities`+`entity_aliases`+every satellite; for `content.sqlite` (read-only) from temples, mantras, aartis, chalisas, stories, kathas, puja_vidhi, scripture_sections, cities, quotes. ~35k docs total.

**Storage.** `search_docs` + `search_tokens` in `gyan.sqlite` (§1.5).

**UI.** Pushed over the shell, opens with the keyboard up. A pill search field in the app bar (cream, 1 px gold border, terracotta cursor). **Empty state:** "Recent" chips from a prefs-backed list of the last 8 queries, then a "Try" row of curated suggestions (`Hanuman` · `कृष्ण` · `Brahmastra` · `Ekadashi` · `Kedarnath`). **Typing:** debounced 180 ms; a horizontal filter-chip row appears — `All · Verses · Temples · Deities · Mantras · Festivals · Stories` driven by `search_docs.kind`, each showing its result count. Results are a grouped list; each row = a 40 px leading kind-glyph on that kind's category gradient, title with the matched span highlighted in terracotta, a one-line snippet, and a faint kind label on the right. Devanagari results render in Noto and correctly fold, so typing `krishna`, `kṛṣṇa` or `कृष्ण` returns the same set. Tapping pushes `search_docs.route` directly. If `searchIndexStaleProvider` is set, a thin amber bar reads *"Search index is out of date"* — degrade, never crash.

---

## 4.6 Srishty Universe · `/gyan/srishty` · cosmic indigo

**Data.** Wilson's *Vishnu Purana* (1840, PD) Books I–II are the primary spine — sarga/pratisarga, the seven lokas and seven talas, Jambudvipa and the dvipas, the measures of cosmic time. Cross-checked against SBE Upanishad passages for the pancha-kosha and the five elements. Wikidata contributes almost nothing here; this is a text-extraction module. **Where a version is not universal, `tradition` is set and the UI says so** (§4.6). ~60–90 nodes.

**Storage.**
```sql
CREATE TABLE cosmology_nodes (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  track TEXT NOT NULL CHECK (track IN ('creation','loka','time_cycle','yuga')),
  parent_id INTEGER REFERENCES cosmology_nodes(id),
  order_no INTEGER NOT NULL,
  title_en TEXT NOT NULL, title_hi TEXT, title_sa TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en TEXT, long_description_hi TEXT,
  duration_years TEXT,          -- TEXT: kalpa-scale values exceed int64
  attributes TEXT,              -- JSON: dharma_ratio, guardians, symbolic_meaning
  entity_id INTEGER REFERENCES entities(id),
  tradition TEXT, tags TEXT, region TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT,
  verification_status TEXT NOT NULL DEFAULT 'unverified'
);
CREATE INDEX ix_cosmo_track ON cosmology_nodes(track, order_no);
```

**UI.** A **vertical scrolling cosmos**, not a list. Background is a deep indigo→violet gradient with a slow parallax starfield (a `CustomPainter` with ~120 seeded dots at three depths, offset by scroll position — cheap, no package). Content is a top-to-bottom stack of the 14 lokas: Satyaloka at the top, Bhūloka centred and marked with a subtle terracotta ring ("you are here"), the seven talas descending into darkening indigo. Each loka is a translucent glass card (backdrop blur 8 px over `#FFFEFA` at 12% on this dark ground) showing name in Eczar gold, Devanagari beneath, one-line description, and a guardian avatar if `entity_id` is set. Tapping expands it inline to reveal `long_description`, `attributes` rows, and a `SourceChip`. A segmented control at the top switches **track**: `Creation · Lokas · Time`. The Creation track renders instead as a numbered vertical timeline of sarga stages with a connecting gold thread. A persistent footer note reads *"As described in the Vishnu Purana"* with the tradition label.

---

## 4.7 Ramayana Journey · `/gyan/ramayana` · sepia

**Data.** Manmatha Nath Dutt's *Ramayana* (1891–94, PD) as the canonical Valmiki spine — 7 kandas, ~100 curated scenes. Griffith's verse translation cross-checks. `recension='valmiki'` throughout; **Ramcharitmanas and Kamba scenes, if added later, get their own `recension` value and are never mixed into the Valmiki sequence** (§4.7). Places link to `entities` of `kind='place'` (Ayodhya, Chitrakuta, Panchavati, Kishkindha, Lanka), characters to `narrative_cast`.

**Storage.**
```sql
CREATE TABLE narrative_nodes (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  epic TEXT NOT NULL CHECK (epic IN ('ramayana','mahabharata')),
  recension TEXT NOT NULL,          -- 'valmiki' | 'ramcharitmanas' | 'kamba' | 'critical_ed'
  book_label_en TEXT, book_label_hi TEXT, book_no INTEGER,
  sequence_no INTEGER NOT NULL,     -- narrative order, NOT a historical date
  title_en TEXT NOT NULL, title_hi TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en TEXT, long_description_hi TEXT,
  lesson_en TEXT, lesson_hi TEXT,
  place_entity_id INTEGER REFERENCES entities(id),
  scripture_section_id INTEGER,     -- soft link into main.scripture_sections
  image_asset TEXT, tags TEXT, region TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);
CREATE INDEX ix_narr_seq ON narrative_nodes(epic, recension, sequence_no);

CREATE TABLE narrative_cast (
  node_id INTEGER NOT NULL REFERENCES narrative_nodes(id),
  entity_id INTEGER NOT NULL REFERENCES entities(id),
  role TEXT,                        -- 'protagonist','antagonist','witness'
  PRIMARY KEY (node_id, entity_id)
);
```

**UI.** A **journey path**, not a chapter list. A vertical sepia scroll where scenes alternate left and right of a hand-drawn dashed path (the stitched motif, rendered as a `CustomPainter` bezier). Each scene is a card: a small circular scene number in gold, title in Eczar, one-line description, a row of 3 overlapping character avatars from `narrative_cast`, and a place pin chip. Kanda boundaries are full-width sepia banners with the kanda name in Devanagari + English and a thin ornamental rule. **Read scenes get a filled gold node, unread hollow** — progress comes from `reading_progress` keyed on the epic. A floating "Continue" pill jumps to the first unread scene.

*Scene detail (`/gyan/scene/:id`)* — hero art if present, title, the narrative prose, then a distinct **"Lesson"** panel in a warm kraft card with a Ramaraja-italic pull-quote, a cast row (tappable → entity detail), a place chip (tappable → the place entity, and → the temple if one maps), a `SourceChip`, and — when `scripture_section_id` is set — a **"Read the verse"** button that deep-links into the existing [section_reader_screen.dart](lib/features/scriptures/section_reader_screen.dart). Prev/next scene arrows in the bottom bar.

---

## 4.8 Mahabharata Timeline · `/gyan/mahabharata` · sepia

**Data.** Ganguli's complete *Mahabharata* (1883–96, PD) — 18 parvas, ~120 curated events. **`sequence_no` is narrative order only; no absolute historical dates are claimed** (§4.8 is explicit). Harivamsa and Vishnu Purana fill genealogical gaps.

**Storage.** Same `narrative_nodes` + `narrative_cast` as 4.7, `epic='mahabharata'`, `recension='critical_ed'`.

**UI.** Same data, **different presentation** — a horizontal-scrolling timeline rather than a vertical path, because the Mahabharata reads as arcs. A fixed left rail lists the 18 parvas; the main area is a horizontally scrolling band with a continuous gold spine, event nodes spaced by `sequence_no`, and coloured arc-bands above the spine grouping events into narrative arcs (Dice Game, Exile, War, Aftermath). Pinch horizontally to compress/expand density. Tapping an event opens the same `NarrativeNodeScreen` as 4.7 — one component, two entry animations. A "Kurukshetra: 18 days" sub-view renders the war parvas as a day-by-day strip with the commander of each side per day.

---

## 4.10 Symbol Encyclopedia · `/gyan/symbols` · teal

**Data.** ~80–120 symbols (Om, swastika, trishula, chakra, conch, lotus, kalash, damaru, veena, tilaka forms, mudras, yantras). Sourced from PD iconography scholarship on archive.org — **T.A. Gopinatha Rao, *Elements of Hindu Iconography* (1914–16, PD)** is the single best source and covers most of the list — plus museum collection descriptions for visual form. §4.10 warns meanings vary by tradition, so `props.meaning_varies_by` is populated and the UI renders it.

**Storage.** `entities` with `kind='symbol'`; `glyph` holds the Unicode character where one exists (ॐ, 卐, 🔱); `props` holds `visual_form_en`, `common_usage_en`, `meaning_varies_by`.

**UI.** A 2-column grid of square tiles on paper. Each tile: the `glyph` rendered large (56 px) in terracotta on cream, or `image_asset` art if no glyph, with the name beneath in Eczar and a faint category label. A filter chip row: `All · Sacred marks · Weapons & tools · Yantras · Mudras`. Tapping opens the shared entity detail, where the symbol renders as a large centred glyph inside a gold-ringed circle, followed by **Meaning**, **Visual form**, **Common usage**, and — when `meaning_varies_by` is non-empty — a distinct kraft-coloured panel headed *"Meanings vary"* listing each tradition's reading separately with its own `SourceChip`. This is the module where the educational, non-absolute tone matters most; the copy voice is "in the Shaiva tradition this is read as…", never "this means…".

---

## 4.11 Dharma Decision Game · `/dharma` · rose/plum (reuses `personality`)

**Data.** ~60 scenarios, each anchored to a real dilemma in the Gita, Mahabharata or Ramayana — Yudhishthira and the half-truth, Arjuna's despondency, Karna's loyalty, Rama's decision at Ayodhya, Vibhishana's defection. `context` and `reflection` are written by us from the PD translations; **choices carry a `guna` tag, not a score — there is no "correct" answer** (§4.11: reflection, not moral authority). Each scenario carries a mandatory `disclaimer`.

**Storage.**
```sql
CREATE TABLE dharma_scenarios (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  title_en TEXT NOT NULL, title_hi TEXT,
  category TEXT,                       -- 'family','duty','truth','war','wealth'
  difficulty INTEGER NOT NULL DEFAULT 2,
  context_en TEXT NOT NULL, context_hi TEXT,
  reflection_en TEXT NOT NULL, reflection_hi TEXT,
  based_on_node_id INTEGER REFERENCES narrative_nodes(id),
  disclaimer_en TEXT, disclaimer_hi TEXT,
  tags TEXT, region TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);

CREATE TABLE dharma_choices (
  id INTEGER PRIMARY KEY,
  scenario_id INTEGER NOT NULL REFERENCES dharma_scenarios(id),
  choice_key TEXT NOT NULL,            -- 'A'..'D'
  label_en TEXT NOT NULL, label_hi TEXT,
  consequence_en TEXT NOT NULL, consequence_hi TEXT,
  guna TEXT,                           -- 'sattva'|'rajas'|'tamas'
  order_no INTEGER NOT NULL
);
```
User choices go to `aradhya_user.db` as `journal_entries` rows with `prompt_id` set — a dharma reflection *is* a journal entry, which means 4.11 and 4.17 share one history.

**UI.** Hub screen: a plum-gradient hero, a "Scenario of the day" `_BigCard`, and a grid of category tiles with a completed-count ring on each. *Play screen:* full-bleed plum-to-maroon gradient, the scenario title in Eczar, the context in generous 17 px Inter with a decorative opening drop-cap. Choices are large stitched-outline cards that fill terracotta on tap. **On selection there is no ✓/✗** — the card expands to reveal `consequence`, then the screen scrolls to a cream **Reflection** panel with the scripture-based commentary in Ramaraja, a `SourceChip`, and a "Read the passage ›" link to the source scene or verse. A footer chip carries the disclaimer. Bottom actions: *Journal this* (pre-fills a `journal_entries` row) and *Next scenario*. Entry points: a tile on the Quiz hub and one on `/gyan`.

---

## 4.12 Ancient Weapons (Astras) · `/gyan/astras` · teal

**Data.** ~70–100 astras and divine implements. Ganguli's Mahabharata (Drona, Karna and Sauptika parvas are dense with astra descriptions), Dutt's Ramayana (Bala Kanda's weapon-conferral episode), plus Vishnu Purana for the ayudhas of Vishnu. Wikidata supplies the wielder links. **`props.nature` is mandatory and labels each entry `mythic` / `symbolic` / `textual`** — §4.12 requires the distinction and the UI shows it.

**Storage.** `entities` with `kind='weapon'`; `props` = `weapon_type`, `invocation`, `powers_en[]`, `counter_en`, `symbolic_meaning_en`, `nature`. Wielders are `relations` of type `wields`.

**UI.** A list of wide cards, each with a left-edge 4 px gradient stripe coloured by `weapon_type` (astra / shastra / ayudha / divine tool), the name in Eczar with Devanagari beneath, wielder avatars on the right, and a small `nature` chip. Filter chips: `All · Astras · Hand weapons · Divine implements`, plus a "By wielder" toggle that regroups the list under deity headers. Detail uses the shared entity screen with a weapon-specific props card laid out as labelled rows — **Type · Invocation · Powers · Counter · Symbolism** — where Powers renders as a bulleted list and **Symbolism sits in its own kraft panel** to keep the mythic and the interpretive visually separate. A standing footer line reads *"Descriptions are from the epics and are mythic, not historical."*

---

## 4.13 Rishi Encyclopedia · `/gyan/rishis` · teal

**Data.** ~120 sages: the Saptarishi sets, Vedic hymn-composers, Upanishadic teachers, epic sages. Wikidata gives the roster and guru-disciple edges; **Griffith's Rig Veda (1896, PD)** supplies hymn attributions (the rishi of each sukta is recorded in the tradition itself); SBE Upanishads supply teaching lineages; the Puranas supply the stories and gotra data.

**Storage.** `entities` with `kind='rishi'`; `props` = `gotra`, `veda`, `ashram_place_slug`, `hymns[]`. Students are `relations` of type `guru_of`.

**UI.** An alphabetical list with a sticky index rail (Devanagari or Latin depending on locale), each row showing a circular portrait or Eczar monogram, name, gotra, and a "N teachings" count. A featured horizontal rail at the top carries the Saptarishi. Detail (shared entity screen) shows a **Teaching lineage** mini-tree — a compact 2-generation projection of `guru_of` edges rendered inline, with "See full lineage ›" opening 4.2 — plus an **Ashram** card linking to the place entity and its map, and a **Hymns** list where each `RV x.y.z` reference is a chip that, where the verse exists in `scripture_sections`, deep-links into the reader.

---

## 4.14 Yuga Explorer · `/gyan/yuga` · cosmic indigo

**Data.** Vishnu Purana Book I ch. 3 and the Mahabharata Shanti Parva give the yuga durations, the dharma ratios (4/4, 3/4, 2/4, 1/4), characteristics and transitions. Small, precise dataset — 4 yugas + the manvantara/kalpa wrappers ≈ 20 nodes. §4.14 requires making clear this is a **doctrinal cosmological model, not scientific chronology**.

**Storage.** `cosmology_nodes` with `track='yuga'` (shares 4.6's table). `duration_years` stays TEXT.

**UI.** A **circular yuga wheel** as the hero — a `CustomPainter` ring divided into four arcs sized proportionally to duration (Satya's arc visibly dominates), each arc filled with a gradient from bright gold to deep indigo as dharma declines. A small marker sits in the Kali arc labelled *"present age, by this reckoning"*. Tapping an arc slides in a detail card below: duration, dharma ratio rendered as a 4-segment bar, moral characteristics, major events (linked to `narrative_nodes` where they exist), and the transition rule. Beneath the wheel, a "Zoom out" expander nests yuga → mahayuga → manvantara → kalpa, each step showing the multiplier, ending on a card that puts a kalpa in plain words. A persistent footer disclaimer states this is a traditional cosmological model and is not being equated with scientific chronology.

---

## 4.15 Vedic Science · `/gyan/vidya` · teal

**Data.** ~80 topics across Ayurveda (dinacharya, ritucharya, doshas), Jyotisha (the astronomy already computed in-app), Shulba Sutra geometry, Yoga Sutras (Vivekananda's 1896 translation is PD), Vyakarana, and Vedic metrics. Sources: PD editions on archive.org and university repositories. **`caution_*` is `NOT NULL` and `validate.py` fails the build if it is empty** — this is the §4.15 medical-advice rule enforced in the schema, not in a review checklist. `modern_status` labels each claim honestly.

**Storage.**
```sql
CREATE TABLE vidya_topics (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  discipline TEXT NOT NULL,           -- 'ayurveda','jyotisha','shulba','yoga','vyakarana','chandas'
  title_en TEXT NOT NULL, title_hi TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en TEXT, long_description_hi TEXT,
  practical_use_en TEXT, practical_use_hi TEXT,
  caution_en TEXT NOT NULL, caution_hi TEXT,          -- REQUIRED
  modern_status TEXT NOT NULL CHECK (modern_status IN
      ('corroborated','partially_corroborated','not_evaluated','contested')),
  tags TEXT, region TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);
```

**UI.** Discipline tabs across the top (Ayurveda · Jyotisha · Ganita · Yoga · Bhasha), each with its own accent, and a card list beneath. Every card shows a **`modern_status` chip in a deliberately unglamorous colour set** — green `corroborated`, amber `partially`, grey `not evaluated`, red-outline `contested` — so the honesty is visible at a glance rather than buried. Detail page order is fixed and non-negotiable: What it says → Where it comes from (`SourceChip`) → How it was used → **Caution** (always rendered, always in a bordered warning panel with the `#FF9F43` accent) → Modern status with a one-line plain explanation. No card in this module may render without its caution panel; a widget-level assertion enforces it in debug builds.

---

## 4.17 Karma Journal · `/journal` · sacred green

**Data.** Two halves. *Prompts* are content: ~200 reflection prompts in `gyan.journal_prompts`, each grounded in a cited verse (Gita 2.47 on action without attachment, 12.13 on friendliness, Yoga Sutra 1.33 on the four attitudes) and tagged by theme. *Entries* are the user's own and never leave the device.

**Storage.** Prompts in `gyan.sqlite`; entries in `aradhya_user.db`:
```sql
CREATE TABLE journal_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  day_stamp TEXT NOT NULL,
  prompt_id INTEGER,             -- → gyan.journal_prompts
  prompt_text TEXT,              -- frozen copy: prompts may change between builds
  body TEXT NOT NULL,
  mood TEXT,                     -- 'shanti','krodha','harsha','vishada','bhaya'
  lesson TEXT,
  tags TEXT,
  is_private INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE INDEX ix_journal_day ON journal_entries(day_stamp DESC);
```

**UI.** A warm cream ledger. Top: today's prompt in a stitched-border card — the prompt in Ramaraja italic, its source verse beneath as a `SourceChip`, and a "Write" button; a refresh icon draws a different prompt. Below: a **mood strip** of 5 hand-drawn glyphs (reusing the [enlighten_art.dart](lib/shared/enlighten_art.dart) CustomPaint style, not emoji) for one-tap logging, then a reverse-chronological entry list where each row shows the date in Eczar, the mood glyph, and a two-line excerpt. A month heatmap sits above the list, styled exactly like the existing japa heatmap so the app reads as one system. *Editor:* distraction-free — prompt pinned at the top, a full-height text field on lined paper texture, mood selector and an optional one-line "Lesson learned" field at the bottom, autosave on pause. Privacy is stated plainly on first open: *"Entries stay on this device. Nothing is uploaded."* Export-to-text lives in the overflow menu; there is no share-by-default anywhere.

---

## 4.18 Festival Explorer · `/festivals` · panchang orange

**Data.** **Dates are computed, never fetched.** `festivals` stores the *rule* (`lunar_month`, `paksha`, `tithi`, or a `solar_rule`); the existing [panchang_engine.dart](lib/features/panchang/panchang_engine.dart) resolves it to a real date for the user's location. This sidesteps drikpanchang entirely and makes the feature correct for any year. Descriptive content (ritual summary, fast rules, the story) comes from PD sources and temple-trust pages; `region` is `NOT NULL` because §4.18 is explicit that dates vary by region and tradition. ~150 festivals and vrats. This module **replaces the hardcoded `lib/features/panchang/festivals.dart`**.

**Storage.**
```sql
CREATE TABLE festivals (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  title_en TEXT NOT NULL, title_hi TEXT, title_sa TEXT,
  category TEXT,                         -- 'major','vrat','jayanti','regional'
  lunar_month TEXT, paksha TEXT CHECK (paksha IN ('shukla','krishna') OR paksha IS NULL),
  tithi INTEGER, solar_rule TEXT,
  region TEXT NOT NULL, tradition TEXT,
  deity_entity_id INTEGER REFERENCES entities(id),
  story_node_id INTEGER REFERENCES narrative_nodes(id),
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  ritual_summary_en TEXT, ritual_summary_hi TEXT,
  fast_rules_en TEXT, fast_rules_hi TEXT,
  tags TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);
CREATE INDEX ix_fest_month ON festivals(lunar_month, paksha, tithi);
```

**UI.** Two modes on one screen, toggled by a segmented control. *Upcoming* (default): a chronological list of the next ~40 resolved festivals, grouped under month headers, each row showing the resolved date in a gold-ringed date badge, name, deity avatar, region chip, and a "days away" counter; today and this week are visually lifted. *Browse*: filter chips for `All · Major · Vrat · Jayanti` plus a region selector, over a searchable list. Detail page: a deity-gradient hero with the resolved date large in Eczar and the tithi rule beneath in small caps (*"Kartika, Krishna Paksha, Amavasya"*), then **When** (with a "varies by region" note when `region` differs from the user's), **Ritual**, **Fast rules**, **The story behind it** (links to `narrative_nodes`), the deity link, related puja vidhi from the existing `puja_vidhi` table, and a `SourceChip`. Actions: *Remind me* (writes a `reminders` row → `flutter_local_notifications`) and *Add to calendar*. Entry points: the existing `_FestivalBanner` on Home starts linking here, plus a tile on `/panchang` and `/calendar`.

---

## 4.19 Offline "Ask the Scriptures" · `/ask` · teal

**Data.** Two layers, retrieval-first per §4.19. *Layer 1* is the existing corpus — 27,890 `scripture_sections` already indexed by Phase 1, restricted to `kind='shloka'`. *Layer 2* is ~400 curated `qa_pairs` for the questions people actually ask ("What does the Gita say about fear?", "क्या कर्म का फल निश्चित है?"), each pinned to a specific verse. **No generation, no model on device** — the answer is always a real passage plus our written explanation, and low-confidence matches return an explicit *not sure* state rather than a guess.

**Storage.**
```sql
CREATE TABLE qa_pairs (
  id INTEGER PRIMARY KEY,
  question_en TEXT NOT NULL, question_hi TEXT,
  question_fold TEXT NOT NULL,           -- normalized, for matching
  answer_en TEXT NOT NULL, answer_hi TEXT,
  explanation_en TEXT, explanation_hi TEXT,
  passage_sa TEXT, passage_translit TEXT,
  scripture_section_id INTEGER,          -- soft link into main.scripture_sections
  confidence TEXT NOT NULL CHECK (confidence IN ('high','medium','low','needs_review')),
  related_qa_ids TEXT,                   -- JSON array
  tags TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);
CREATE INDEX ix_qa_fold ON qa_pairs(question_fold);
```

**UI.** A calm, near-empty screen: a single large question field on paper with the app logo faint above it, and beneath it a wrap of suggested questions drawn from high-confidence `qa_pairs`. On submit, a brief "consulting" animation (a slowly turning gold chakra, ~600 ms) then the answer card: **the verse first** — Devanagari in Noto at 20 px, transliteration in muted Ramaraja italic, translation in Inter — then our explanation, then a `SourceChip` with the exact chapter and verse, then "Read in context ›" opening the reader at that verse, then related questions as chips. When the best match is weak, the screen says so plainly — *"I could not find a clear passage for this. Here are the closest verses."* — followed by ranked candidates. No answer is ever presented without its source. A standing footer reads *"Answers are passages from the scriptures, selected — not generated."*

---

## 4.4 Reading Progress (upgrade) · no new screen

**Data.** User's own. Structure comes from the existing `scripture_books` / `scripture_sections`.

**Storage.** `reading_progress` in `aradhya_user.db`, migrated from `scripture_pos_<bookId>` prefs keys. `sections_total` is backfilled lazily on next open of each book.

**UI.** A **Continue reading** card at the top of `/scriptures` — cover thumbnail, book name, a thin terracotta progress bar with "34% · Chapter 6, verse 12", and a resume button. Per-chapter rings on the book list. A "Your reading" section in the You tab with total verses read, current streak, and a per-scripture progress row. The reader itself gains a slim progress bar under the app bar and writes `last_read_at` on every section change.

---

## 4.5 Bookmarks and Notes (upgrade) · `/bookmarks`

**Data.** User's own. Bookmarks link by `(src, kind, ref_id)` and never duplicate content (§4.5).

**Storage.** `bookmarks` in `aradhya_user.db` — adds `note`, `tags`, `created_at`, `updated_at`, and the resolved `route`.

**UI.** The existing screen gains: filter chips by `kind` (now including `entity`, `festival`, `scene`), sort by recent/title, an inline **note** affordance — tapping the note icon expands a small text field on the card, saved on blur — a tag wrap-chip row, and search across notes via the same fold function. Every bookmark row is tappable because `route` was resolved at write time, which is the structural fix for the G2 crash class.

---

## 4.16 Sadhana Tracker (consolidation) · `/sadhana` · sacred green

**Data.** User's own; practice suggestions cited to the Gita and Yoga Sutras.

**Storage.** `sadhana_sessions` + `sadhana_goals` + `reminders`, absorbing `japa_history_json`, `habits_<day>`, `breathing_last`/`breathing_streak`.

**UI.** One hub replacing three disconnected screens. Top: a **today ring** — a circular progress meter showing today's practices completed against goals, with the day's Punya earned in the centre. Below: a practice list where each row (Japa · Breathing · Reading · Habits · Mandir) shows its own mini 7-day sparkline, current streak, and a one-tap start button that pushes the existing `/japa`, `/breathing`, `/habits` screens — **those routes stay registered**, so deep links and home widgets keep working. Then a unified **year heatmap** across all practices (the existing japa heatmap widget, generalised), a **Goals** section where each practice gets a target and an optional reminder time (writes `reminders` → `flutter_local_notifications`), and a **Milestones** rail. Entry from the You tab and a Home "Engage & Learn" tile.

---

## 4.21 Knowledge Journeys · `/journey` · teal

**The feature that turns Aradhya from a reference app into a learning platform.** Everything above is *lookup* — the user must already know what to search for. A journey answers "where do I start?", which is the question a newcomer to Sanatan Dharma actually has.

**Data.** Almost no new authoring: a journey is a **curated playlist over content that already exists**. Each step points at a real row — a Gita chapter in `scripture_sections`, a Ramayana scene, an entity, a temple, a mantra, a dharma scenario. The authoring cost is the curation and a one-line "why this step" blurb, not new prose. Ten launch paths:

*Beginner:* What is Dharma? · Who is Vishnu? · The Dashavatara · Shiva · Devi
*Core:* The Gita's central teaching · The Ramayana in 12 scenes · The Mahabharata in 15 events
*Deeper:* The Upanishads · Building a daily practice

**Storage.**
```sql
CREATE TABLE learning_paths (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  title_en TEXT NOT NULL, title_hi TEXT,
  level TEXT NOT NULL CHECK (level IN ('beginner','core','deeper')),
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  est_minutes INTEGER, cover_asset TEXT, order_no INTEGER NOT NULL, tags TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at TEXT, verification_status TEXT NOT NULL DEFAULT 'unverified'
);

CREATE TABLE path_steps (
  id INTEGER PRIMARY KEY,
  path_id INTEGER NOT NULL REFERENCES learning_paths(id),
  step_no INTEGER NOT NULL,
  title_en TEXT NOT NULL, title_hi TEXT,
  blurb_en TEXT, blurb_hi TEXT,          -- one line: why this step, here
  src TEXT NOT NULL, ref_table TEXT NOT NULL, ref_id INTEGER NOT NULL,
  route TEXT NOT NULL, est_minutes INTEGER,
  optional INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX ix_path_steps ON path_steps(path_id, step_no);
```
Progress lives in `aradhya_user.db`: `path_progress(path_id, step_no, completed_at)`.

**UI.** *Journey list:* tall cover cards on paper, each with a level chip, step count, estimated total minutes, and a terracotta progress ring. In-progress paths float to the top with a "Continue — step 4 of 12" strip.

*Path detail:* the vertical stepper reuses **the same dashed-path painter as the Ramayana Journey (4.7)**, so the two feel like one idea. Each step is a card with a kind glyph (verse · scene · deity · temple · practice), the step title, the "why this step" blurb in Ramaraja italic, an estimated read time, and a completion tick. Completed steps fill the path node gold. A "Continue" pill jumps to the first incomplete step; finishing a step returns to the journey with an animated node fill and advances automatically.

**One deliberate departure from the suggestion: steps are not locked.** Gating access to scripture behind a progress mechanic is the wrong register for this app — someone who came to read the Gita today should be able to. Steps show a **suggested order with progress**, not a permission system. The pull is "you're 4 of 12 in", not "you may not proceed."

Entry points: a hero card at the top of `/gyan`, a "Start here" card on Home for users with no reading history, and a tile in You.

---

## 4.22 Interest signals (local personalization) · no screen of its own

**Scoped deliberately small.** A local, resettable interest profile that orders *discovery*, and nothing else.

**Storage.** `aradhya_user.db`:
```sql
CREATE TABLE interest_signals (
  topic TEXT PRIMARY KEY,        -- a tag ('bhakti') or an entity slug ('hanuman')
  score REAL NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
```
Increment on open (+1), dwell > 20 s (+2), bookmark (+5), journey step completed (+3), quiz answered on that topic (+1). Multiply all scores by 0.98 nightly so interests drift instead of ossifying. Never leaves the device — it is the same privacy posture as the journal.

**What it may influence:** the order of Home discovery rails, which `related_edges` surface first in a tie, the daily journal prompt's theme, and quiz topic weighting.

**What it must never influence:** which scriptures, verses, deities or traditions are *available* or visible. Narrowing someone's exposure to canon based on tap behaviour is the wrong thing for this app to do — an engagement loop borrowed from a domain where it doesn't belong. Discovery ordering only; the library stays whole.

Requirements: a plain-language "Why am I seeing this?" line on any personalized rail, and a **Reset personalization** button in the You tab. Ships last, and the app must be fully usable with the table empty.

---

# PART 3 — Leftover work in the existing app

| # | Leftover | Fix | Phase |
|---|---|---|---|
| **G1** | **Mandir / virtual puja never built.** Assets (`vitual.png`, `bhog.png`, `ondiya.png`, `offdiya.png`) exist; prefs keys `offering_total_days`/`offering_streak`/`offering_last` are declared but never read or written; Kamal was designed as its currency but is only spent in Rashifal (`_revealCost = 5`). | Build `/mandir`: full-bleed idol of the user's `ishta_deity` on a warm shrine gradient, an offering bar along the bottom (diya · flower · bhog · incense), each offering animating onto the idol and costing Kamal **outside** the free windows (4–12 AM, 6–9 PM), an aarti-play button wired to the existing TTS, and an offering-streak ring. Offerings write `sadhana_sessions(practice='mandir')`, retiring the dead prefs keys and finally giving Kamal a sink. | 3 |
| **G2** | [bookmarks_screen.dart:110](lib/features/bookmarks/bookmarks_screen.dart#L110) pushes `/scriptures/book/$bookId`; the real route is `/scriptures/:scriptureId/book/:bookId`. **Shloka bookmarks crash to the GoRouter error page.** | Add a redirect route that resolves `scriptureId` from `bookId`, and store the resolved `route` on every new bookmark so the class of bug cannot recur. | 0 |
| **G3** | `daily_quotes` has **3 rows** — verse-of-the-day cycles every 3 days — while the unused `quotes` table has **1,000** of the same shape. | Point the provider at `quotes` with a day-of-year modulo. | 0 |
| **G4** | `kathas` (57 rows) is orphaned; `/katha` serves `stories` instead. | Either surface kathas as a second section on the stories screen or merge; either way they get indexed in Phase 1. | 0 |
| **G5** | **No indexes at all** on `content.sqlite` — `scripture_sections.book_id` (27,890 rows) and `cities.name` (4,276) are unindexed. | `CREATE INDEX` on the checked-in asset via the sqlite3 CLI, then `VACUUM` + version bump. **Cannot** be done at runtime on a read-only connection. | 0 |
| **G6** | `cities` search is prefix-only (`LIKE 'q%'`), so typing "mumbai" never finds "Navi Mumbai". | Solved free by `search_docs` — no `content.sqlite` schema change. | 1 |
| **G8** | `temples.data` carries `sources[]` (10–12 real URLs) and `confidence` on **all 187 rows**, and `Temple.fromRow` throws both away. | Parse them and render `SourceChip`s on the temple detail. The only provenance the app already owns — free win. | 0 |
| **G9** | No audio playback: no player dependency, `mantras.audio_url` empty on all 36 rows; TTS substitutes. | Add `just_audio` + real recordings. Genuinely blocked on content, not code. | 7 |
| **G10** | No local-notification dependency at all — blocks every reminder in 4.16/4.17/4.18. | Add `flutter_local_notifications`, backed by the `reminders` table. | 3 |
| **G11** | `assetVersion` says `0.4.2-devfixture-native`; the DB's `meta.content_version` says `0.4.0`. | Fix the const, then let `build.py` stamp it and `test/db_version_test.dart` guard it forever. | 0 |
| **G12** | Reader font size is in-memory only ([scripture_providers.dart:57](lib/features/scriptures/scripture_providers.dart#L57)). | One prefs key. | 3 |
| **G13** | No dark theme — `main.dart` hardcodes `ThemeMode.light`, though `themeModeProvider` exists and is unused and `AppColors` already defines a full warm-espresso dark ramp. | Wire the provider, add the selector to the You tab. Most of the work is already done. | 7 |
| **G14** | Nav labels hardcoded English in [nav_scaffold.dart](lib/app/shell/nav_scaffold.dart); the ARB has 19 keys while the rest of the app is bilingual via inline ternaries. | Pick **one** convention and apply it — either grow the ARB or formalise the ternary in a `Tr` helper. The current split is the actual problem. **Must be settled before the new modules are written**, not after (§1.11). | **1** |
| **G17** | Adhika (intercalary) months were computed correctly but not labelled, so festivals falling inside one took the nija month's names and appeared twice in a year. | `lunarMonth` now reports `adhika`; those months name their Ekadashis Padmini / Parama. **Done** — found while fixing G16. | 5 |
| **G18** | A vriddhi tithi spans two sunrises and so fired its festival on both days. | `monthFestivals` skips the repeat. **Done** — found while fixing G16. | 5 |
| **G16** | **Pre-existing failing test** (confirmed present before any Phase-0 work): `test/panchang_test.dart` — *"Festivals for July 2026 match reference dates"* expects `Ekadashi` but `lib/features/panchang/festivals.dart` returns `Apara Ekadashi`. Either the name or the expectation is wrong. | Resolve when 4.18 replaces `festivals.dart` — the correct name is a content question, and `festivals.title_en` becomes the single source of truth. | 5 |
| **G15** | `assets/db/content.sqlite.bak` is **git-tracked** (38 MB duplicate in history); `flutter_0*.log` and `flutter_01.png` are committed at root. | `git rm --cached`, `.gitignore` `assets/db/build/` and `content/raw/`. | 0 |

---

# PART 4 — Sequencing

Effort: **S** = a few focused sessions · **M** = a substantial chunk · **L** = the big ones.

### Phase 0 — Substrate & unblockers · M
*No new content UI. Everything after depends on it.*
`content/` skeleton (`schema/gyan.sql`, `tools/`, `sources/registry.jsonl`) · `ContentDatabase` ATTACH + dual version markers + **G11** fix + `test/db_version_test.dart` · `UserDatabase` v1 + prefs migration (four controllers rewired internally, public APIs untouched) · the **module registry** (§1.9) and the **asset manifest** (§1.12) — both are cheap now and expensive to retrofit · quick wins **G2 G3 G4 G5 G8** · repo hygiene **G15**.

### Phase 1 — Universal Search (4.3) + related rail + Gyan hub shell · M
`index.py`, indexing the ~34k legacy rows immediately — large value for almost no new content · **`relate.py` over legacy content only** (temple ↔ chalisa ↔ mantra ↔ puja by folded deity name) plus the `RelatedRail` widget: this alone connects the app that already exists, before a single new entity is authored · `lib/features/search/` + `/search` + Home header icon · `/gyan` hub driven by the module registry (unbuilt tiles use the already-present `comingSoon` string) · shared `SourceChip` and `VerificationChip` widgets · **`report.py` HTML dashboard** — stand it up before content authoring begins, not after · **G6** free.

**G14 moves here from Phase 7** — settle the bilingual UI convention (grown ARB *or* a formalised `Tr` helper over the existing ternaries) and get the nav labels out of `nav_scaffold.dart` **before** 17 modules of new screens are written. Deciding this afterwards means writing every new screen's strings twice. This is the single cheapest re-ordering in the plan.

*Optional proof-of-concept:* 2–3 Knowledge Journeys (4.21) built purely over existing scriptures/stories/temples/mantras. No new content needed, and it validates the format before Phase 5 scales it.

### Phase 2 — Entity substrate + five encyclopedias · L
*Must ship together — one substrate, one `EntityDetailScreen`, one `EntityListScreen`. Splitting means building the substrate five times.*
4.1 Knowledge Graph · 4.13 Rishis · 4.12 Astras · 4.10 Symbols · 4.2 Family Tree. Wikidata pull is the first task. Heaviest UI: the Family Tree canvas. **Extend `relate.py` to the entity rules** (§1.10) — the moment entities exist, the rails built in Phase 1 get an order of magnitude richer for free.

### Phase 3 — Personal & writable features · M
*Depends only on Phase 0 — can run parallel to Phase 2.*
4.17 Karma Journal · 4.5 Bookmarks + Notes · 4.4 Reading Progress · 4.16 Sadhana consolidation · **G1 Mandir** · **G10** notifications · **G12**.

### Phase 4 — Narrative & cosmology · L
*Depends on Phase 2 — scenes and lokas link to entities.*
4.7 Ramayana Journey · 4.8 Mahabharata Timeline (shared `narrative_nodes`, two presentations) · 4.6 Srishty Universe · 4.14 Yuga Explorer (shared `cosmology_nodes`) · optional nav promotion (§1.6 Stage 2), isolated in its own commit.

### Phase 5 — Curated & interactive · M
4.18 Festival Explorer (reuses `panchang_engine`, replaces hardcoded `festivals.dart`) · 4.11 Dharma Decision Game · 4.15 Vedic Science · **4.21 Knowledge Journeys** — lands here because the best paths point at Phase 4's scenes and Phase 2's entities, though the Phase 1 proof-of-concept should already have proved the format.

### Phase 6 — Ask the Scriptures (4.19) · M–L
Last: needs the Phase 1 index and curated `qa_pairs`.

### Phase 7 — Polish & optimization (4.20) · M
**G13** dark theme · **G9** audio · **4.22 interest signals** (last, and the app must be fully usable with the table empty) · Hindi typography sweep across every new screen · perf pass · golden tests for the fold function · device matrix · release checklist. *(G14 moved to Phase 1.)*

---

# PART 5 — Risks

1. **Two-tier provenance is user-visible.** A Gyan entity shows "— Vishnu Purana 1.3.12"; a legacy mantra shows nothing. Mitigated by G8 (187 temples get free source chips) and by rendering the citation row only when present. Expect the question; a legacy retrofit is an eventual Phase 8.
2. **The index lives in a different file from half the data it indexes.** Rebuilding `content.sqlite` without rebuilding `gyan.sqlite` makes legacy results deep-link to wrong rows. Guarded by `indexed_content_version` (build hard-fail + runtime degrade), but it must be on the release checklist.
3. **The Ishvarvaani fixture (out of scope, recorded).** `meta.data_source` says *"DEV FIXTURE (Ishvarvaani) - replace before store submission"*, and `reference/ishvarvaani-apk/base.apk` is committed. Universal Search makes that content **more** prominent, not less. Top release blocker; nothing here depends on it, and nothing here makes it worse except by raising visibility.
4. **`extract.py` is the real cost, not the Flutter code.** 500 entities × 2–3 human-verified citations is the bottleneck. Design consequence: **ship each module at 60–100 verified entries rather than waiting for completeness** — `--strict`, the `VerificationChip` and `report.py` make partial content safe and the debt visible.
5. **Installed footprint.** 38 MB asset + 38 MB documents copy ≈ 76 MB today; `gyan.sqlite` (est. 8–15 MB with the index) → ~110 MB. Consider gzipping both assets and inflating on copy before the Play listing.
6. **Wikipedia's CC BY-SA is viral.** Using it as a *lead* is fine; pasting its prose would licence our descriptions under BY-SA. The pipeline rule (write our own, cite the PD text) exists specifically to avoid this, and `validate.py` cannot detect a violation — it is a discipline, not a check.
7. **`SQLITE_MAX_ATTACHED` is 10.** We use one attachment. Do not let this grow into per-module DB files.
8. **`related_edges` can go bad quietly.** Name-matching is the whole engine, and Sanskrit names collide — "Vasu", "Indra", "Kumara" and "Devi" are epithets shared by many entities, so a naive fold match will happily wire Durga's aarti onto a minor river goddess. Mitigations: alias matching requires the alias be marked `primary` or `epithet` (never a bare `spelling`), quiz/trivia matching is capped at 2 per source, and `report.py` lists duplicate aliases across entities as a first-class defect. Spot-check the rails for the 20 highest-`importance` entities before every release — a wrong recommendation is more visible to users than a missing one.
9. **Personalization is the one feature here that can quietly make the app worse.** 4.22 is scoped to discovery ordering for exactly this reason. Resist the drift toward "the user seems to like Hanuman, show more Hanuman" — a spirituality app that narrows what a person is exposed to based on tap behaviour is failing at its actual job. If in doubt, ship without it; nothing else depends on it.

---

# PART 6 — Verification

**Per phase, before moving on:**
- `flutter analyze` clean, `flutter test` green — the astrology/panchang suites are the best-covered code and must not regress.
- `python -m content.tools.validate` exits 0; `report.py` shows the expected verified counts.
- `test/db_version_test.dart` passes — proves the DB↔Dart version stamps agree.
- Golden test pins `search_fold.dart` against `common.py` on a shared fixture: `Kṛṣṇa` / `Krishna` / `कृष्ण` / `Krsna` must all fold together.
- A route test regenerates `content/tools/routes.txt` from `appRouter.configuration.routes` and diffs it, so a route rename can never silently break every indexed deep link. The same test exports `content/tools/modules.json` from the module registry (§1.9) and asserts every `GyanModule.route` resolves.
- `report.py`'s HTML dashboard shows zero broken relations, zero duplicate aliases, and zero manifest-missing assets before a phase is called done.

**Phase 0 specifically:** install the previous build, upgrade over it, and confirm the prefs→SQLite migration preserves japa history, habit days, bookmarks and visited temples; kill the app mid-migration and confirm it re-runs cleanly; confirm the legacy prefs keys still exist afterwards.

**End-to-end on a real device** (no emulator — deploy via `C:\Android\platform-tools\adb.exe`):
- Search `krishna`, `कृष्ण`, `mumbai`, `brahmastra` → results span temples, verses, cities and entities; every result taps through to a real screen.
- Open a bookmarked shloka → lands in the reader (G2 fixed). Open a temple → source chips render (G8). Verse of the day changes across more than 3 consecutive days (G3).
- Walk `/gyan` → every tile opens a real screen or the coming-soon state; entity → relation → entity round-trips; Family Tree pans, re-roots, and switches tradition.
- Every Vedic Science detail renders its caution panel; every Ask answer shows a source; no Dharma choice shows a right/wrong mark.
- Festival dates resolve correctly for two different locations and match the existing Panchang screen for the same day.
- Journal entry survives restart; a sadhana reminder actually fires; a Mandir offering deducts Kamal outside the free window and not inside it.
- **Related rail:** open Hanuman and confirm the rail surfaces the Chalisa, his temples, Sundara Kanda scenes and Hanuman Jayanti — and that nothing in it is wrong. Repeat for Shiva, Durga and Krishna, the four most epithet-collision-prone entities.
- **Journey:** complete three steps of a path, force-quit, reopen — progress holds and "Continue" lands on step four. Every step opens a real screen.
- Personalization off (empty `interest_signals`) must leave every screen fully usable; **Reset personalization** must actually empty the table.
- Confirm astrology/panchang still work — `sweph` falls back to Schlyter under `flutter test`, so the Swiss Ephemeris path is **only** verifiable in the running app.

---

# PART 7 — Task checklist

Tick as you go. `- [ ]` → `- [x]`. Task IDs are stable — reference them in commit messages (`P0-14: add gyan ATTACH`) so history maps back to the plan.

**Status key:** `[ ]` not started · `[x]` done · `[~]` in progress · `[!]` blocked (add a note) · `[-]` dropped (add why)

| Phase | Done | Total |
|---|---|---|
| 0 — Substrate & unblockers | **40 ✅** | 40 |
| 1 — Search · related · hub | **29 ✅** | 29 |
| 2 — Entity substrate | **22 ✅** | 22 |
| 3 — Personal & writable | **11 ✅** | 24 |
| 4 — Narrative & cosmology | 20 | 20 |
| 5 — Curated & interactive | 7 | 26 |
| 6 — Ask the Scriptures | 0 | 9 |
| 7 — Polish & optimization | 0 | 16 |
| Release gate | 0 | 8 |
| **Total** | **142** | **194** |

---

## Phase 0 — Substrate & unblockers

### Content pipeline skeleton
- [x] **P0-01** Create `content/` tree: `schema/`, `sources/`, `queries/wikidata/`, `data/`, `tools/`, `raw/`, `build/`
- [x] **P0-02** `content/requirements.txt` — jsonschema, requests, unidecode, indic-transliteration, rapidfuzz, SPARQLWrapper
- [x] **P0-03** `content/make.ps1` — Windows wrappers for validate / build / report
- [x] **P0-04** `content/schema/gyan.sql` — provenance core (`sources`, `item_sources`)
- [x] **P0-05** `content/schema/gyan.sql` — entity core (`entities`, `entity_aliases`, `relations`) + indexes
- [x] **P0-06** `content/schema/gyan.sql` — satellites (`cosmology_nodes`, `narrative_nodes`, `narrative_cast`, `dharma_*`, `vidya_topics`, `festivals`, `qa_pairs`, `learning_paths`, `path_steps`, `journal_prompts`)
- [x] **P0-07** `content/schema/gyan.sql` — search + related (`search_docs`, `search_tokens`, `related_edges`, `meta`)
- [x] **P0-08** `content/schema/kinds/*.schema.json` — one JSON Schema per entity kind + per satellite
- [x] **P0-09** `content/schema/legacy_content.sql` — document the shipped `content.sqlite` (reference only, never applied)
- [x] **P0-10** `content/sources/registry.jsonl` — seed the PD sources (Ganguli, Dutt, Griffith, Telang, Wilson, Müller, Gopinatha Rao, Wikidata)
- [x] **P0-11** `content/sources/excluded.jsonl` — vedabase.io, drikpanchang.com, the Ishvarvaani fixture, with reasons
- [x] **P0-12** `tools/common.py` — fold(), slugify(), transliterate(), JSONL read/write
- [x] **P0-13** `tools/validate.py` — all 14 error checks + 3 warnings
- [x] **P0-14** `tools/build.py` — slug→id resolution, inverse relations, `primary_source_*` denormalization, meta stamping, `journal_mode=DELETE; VACUUM; integrity_check`
- [x] **P0-15** `tools/build.py` — `--strict` / `--allow-unverified` / `--modules` flags
- [x] **P0-16** `tools/build.py` — regenerate `SOURCES.md`; regex-rewrite the `// BUILD_STAMP:gyan` line
- [x] **P0-17** `.gitignore` — `content/raw/`, `content/build/`, `assets/db/build/`

### DB layer
- [x] **P0-18** Generate an empty-but-valid `assets/db/gyan.sqlite` so the app runs before any content exists
- [x] **P0-19** `ContentDatabase` — `ATTACH DATABASE … AS gyan` after `openReadOnlyDatabase`
- [x] **P0-20** `ContentDatabase` — `gyanAssetVersion` const + independent `.version` marker (a Gyan patch must not re-copy the 38 MB fixture)
- [x] **P0-21** **G11** — fix `assetVersion` `0.4.2` → `0.4.0-devfixture-native`
- [x] **P0-22** `test/db_version_test.dart` — both DBs' `meta.content_version` must equal their Dart consts
- [x] **P0-23** Add `gyan.sqlite` to `pubspec.yaml` assets

### Writable user DB
- [x] **P0-24** `lib/core/db/user_schema.dart` — v1 DDL (9 tables)
- [x] **P0-25** `lib/core/db/user_database.dart` — open, `onCreate`, `onUpgrade`, `user_meta`
- [x] **P0-26** `_migrateFromPrefs` — single transaction, flag set last, idempotent
- [x] **P0-27** Rewire `BookmarksController` internals (public API unchanged) — resolve `route` at write time
- [x] **P0-28** Rewire `JapaController` — kills the per-bead full-blob rewrite
- [x] **P0-29** Rewire `HabitsController` — enumerate `habits_*` keys, ends the key-space leak
- [x] **P0-30** Rewire `VisitedController` → `temple_visits` with dates
- [x] **P0-31** Migration test: upgrade-over-install preserves japa history, habit days, bookmarks, visited temples; crash mid-migration re-runs cleanly; legacy prefs keys survive

### Module registry & asset manifest
- [x] **P0-32** `lib/features/gyan/gyan_modules.dart` — the 17-entry `const` registry (§1.9)
- [x] **P0-33** Registry test — every `GyanModule.route` resolves against `appRouter.configuration`; exports `content/tools/modules.json`
- [x] **P0-34** `assets/manifest.json` for all 52 images + manifest checks in `validate.py`; `--strict` refuses any `replace_before_ship: true`

### Quick wins (bundled-content fixes)
- [x] **P0-35** **G2** — add the `/scriptures/book/:bookId` redirect resolving `scriptureId`; fixes the shloka-bookmark crash
- [x] **P0-36** **G3** — point verse-of-the-day at `quotes` (1,000 rows) instead of `daily_quotes` (3)
- [x] **P0-37** **G4** — surface or merge the orphaned `kathas` (57 rows)
- [x] **P0-38** **G5** — `CREATE INDEX` on `scripture_sections.book_id` and `cities.name` via sqlite3 CLI, then `VACUUM` + version bump
- [x] **P0-39** **G8** — parse `sources[]` + `confidence` in `Temple.fromRow`
- [x] **P0-40** **G15** — `git rm --cached assets/db/content.sqlite.bak`; delete `flutter_0*.log`, `flutter_01.png`

---

## Phase 1 — Universal Search · Related rail · Gyan hub

### Search
- [x] **P1-01** `tools/index.py` — extract `search_docs`/`search_tokens` from `content.sqlite` (read-only): temples, mantras, aartis, chalisas, stories, kathas, puja_vidhi, scripture_sections, cities, quotes
- [x] **P1-02** `tools/index.py` — extract from `gyan.sqlite` tables + `entity_aliases`
- [x] **P1-03** `tools/index.py` — `boost` from `importance` / temple `confidence`; `indexed_content_version` stamp
- [x] **P1-04** `lib/features/search/search_fold.dart` — the Dart half of the fold
- [x] **P1-05** Golden test pinning `search_fold.dart` to `common.py` (`Kṛṣṇa` / `Krishna` / `कृष्ण` / `Krsna` fold together)
- [x] **P1-06** `SearchRepository` — prefix range scan, field weighting, multi-term intersect
- [x] **P1-07** `SearchScreen` — pill field, keyboard-up, debounce 180 ms
- [x] **P1-08** Recent searches (prefs, last 8) + curated "Try" suggestions
- [x] **P1-09** Kind filter chips with per-kind counts
- [x] **P1-10** Result rows — kind glyph, matched-span highlight, snippet, tap → `search_docs.route`
- [x] **P1-11** `/search` route with `?q=` deep link
- [x] **P1-12** Home header search icon; app-bar icons on `/gyan`, `/temples`, `/scriptures`; You-tab tile
- [x] **P1-13** `searchIndexStaleProvider` + amber banner (degrade, never crash)
- [x] **P1-14** **G6** — verify "mumbai" now finds "Navi Mumbai"

### Related rail
- [x] **P1-15** `tools/relate.py` — legacy rules only (deity-name fold across temples/chalisas/aartis/mantras/puja)
- [x] **P1-16** `relate.py` — cap 12/source, min weight 0.3, dedupe by `(dst_table, dst_id)`
- [x] **P1-17** `RelatedRail(src:, table:, id:)` widget — grouped horizontal cards, single indexed query, no skeleton
- [x] **P1-18** Wire `RelatedRail` into temple, mantra, aarti/chalisa, story, puja and verse detail screens

### Hub & shared chrome
- [x] **P1-19** `GyanHubScreen` — hero + tile grid driven by `gyanModules`
- [x] **P1-20** Coming-soon tile state for `shipped: false`
- [x] **P1-21** Home "Explore Gyan" section (4 featured tiles + See all)
- [x] **P1-22** `SourceChip` widget + source bottom sheet (name, edition, licence, `last_verified_at`, open link)
- [x] **P1-23** `VerificationChip` widget (dev builds only)
- [x] **P1-24** `category_colors.dart` — add `gyan`, `srishty`, `epics`, `sadhana` + `copyWith`/`lerp`
- [x] **P1-25** `tools/report.py` — HTML dashboard to `content/build/report.html`
- [x] **P1-26** *(optional)* 2–3 Knowledge Journeys over existing content, to validate the format early

### Bilingual convention (G14 — moved up from Phase 7)
- [x] **P1-27** Decide and document **one** i18n convention (grown ARB *or* a `Tr` helper wrapping the existing ternaries); apply it to the screens built so far
- [x] **P1-28** Nav labels out of `nav_scaffold.dart`; verify the 5-tab bar does not overflow with Hindi labels
- [x] **P1-29** Lay out `SearchScreen`, `GyanHubScreen` and `RelatedRail` **in Hindi first**, then check English

---

## Phase 2 — Entity substrate + five encyclopedias

### Content acquisition
- [x] **P2-01** `queries/wikidata/*.rq` — deities, epic characters, sages, places, dynasties, weapons, symbols
- [x] **P2-02** `tools/wikidata.py` — entity skeletons (slug, qid, labels + aliases en/hi/sa)
- [x] **P2-03** `tools/wikidata.py` — relation edges from `P22/P25/P26/P40` + epic properties
- [x] **P2-04** `tools/fetch.py` — pull the PD texts into `raw/` with sha256 + `retrieved_at`
- [x] **P2-05** `tools/extract.py` — descriptions + `props` from `raw/`; **discard any line with empty `sources[]`**
- [x] **P2-06** Human-verify pass: all `importance <= 2` entities and all non-`high` relations
- [x] **P2-07** Ship gate — 150 verified entities minimum — **met: 165 entities, 165/165 verified and cited, 397 aliases, 74 relations**. Long-term target remains 500 entities / 1,500 relations.

### UI
- [x] **P2-08** `EntityListScreen(kind:)` — shared list with per-kind layout variants
- [x] **P2-09** `EntityDetailScreen` — hero, alias chips, descriptions, `SourceChip`, `RelatedRail`
- [x] **P2-10** Per-kind `props` renderers (weapon / symbol / rishi / deity)
- [x] **P2-11** Connections section — relations grouped by family, tappable
- [x] **P2-12** Bookmark support for `kind='entity'`
- [x] **P2-13** `KnowledgeGraphScreen` — `InteractiveViewer`, orbital layout by relation family
- [x] **P2-14** Graph node + edge painter, edge label chips
- [x] **P2-15** Animated re-centre on neighbour tap (350 ms) + breadcrumb rail
- [x] **P2-16** Relation-family filter chips
- [x] **P2-17** `FamilyTreeScreen` — generational `CustomPainter` layout, spouse joins, `ordinal` sibling order
- [x] **P2-18** Family tree: long-press re-root, collapse/expand >4 children
- [x] **P2-19** Family tree: `tradition` segmented control + inline "as given in…" note
- [x] **P2-20** `/gyan/rishis` · `/astras` · `/symbols` list configs (Saptarishi rail, weapon-type stripes, glyph grid)
- [x] **P2-21** Register all Phase-2 routes; flip `shipped: true` in the registry
- [x] **P2-22** Extend `relate.py` with the entity rules; verify no epithet collisions (Risk 8)

---

## Phase 3 — Personal & writable features

### Notifications
- [x] **P3-01** Add `flutter_local_notifications`; Android channel + POST_NOTIFICATIONS permission; iOS permission flow
- [x] **P3-02** `reminders` table wiring + reschedule-on-boot

### Karma Journal (4.17)
- [x] **P3-03** `journal_prompts` content — 200 prompts, each cited to a verse
- [x] **P3-04** `KarmaJournalScreen` — today's prompt card, mood strip, entry list, month heatmap
- [x] **P3-05** `JournalEditorScreen` — lined-paper field, autosave on pause, mood + lesson
- [x] **P3-06** Mood glyphs as `CustomPaint` (match `enlighten_art.dart` style, not emoji)
- [x] **P3-07** Privacy statement on first open; export-to-text in overflow
- [x] **P3-08** `/journal`, `/journal/new`, `/journal/entry/:entryId` routes

### Bookmarks & Notes (4.5)
- [x] **P3-09** Inline note editing on bookmark cards
- [x] **P3-10** Tags, kind filter chips, sort by recent/title
- [x] **P3-11** Search across notes using the shared fold

### Reading Progress (4.4)
- [x] **P3-12** Lazy `sections_total` backfill on book open
- [x] **P3-13** "Continue reading" card on `/scriptures` + per-chapter rings
- [x] **P3-14** Progress bar under the reader app bar; write `last_read_at` per section change
- [x] **P3-15** "Your reading" section in the You tab

### Sadhana Tracker (4.16)
- [x] **P3-16** `SadhanaHubScreen` — today ring, practice rows with sparklines + streaks
- [x] **P3-17** Generalise the japa heatmap to all practices
- [x] **P3-18** Goals + per-practice reminder times
- [x] **P3-19** Milestones rail; keep `/japa`, `/breathing`, `/habits` registered for deep links and widgets

### Mandir (G1)
- [x] **P3-20** `MandirScreen` — `ishta_deity` idol on shrine gradient
- [x] **P3-21** Offering bar (diya · flower · bhog · incense) with onto-idol animation
- [x] **P3-22** Kamal cost outside free windows (4–12 AM, 6–9 PM); free inside
- [x] **P3-23** Offering streak ring; write `sadhana_sessions(practice='mandir')`; retire the dead `offering_*` prefs keys
- [x] **P3-24** **G12** — persist reader font scale

---

## Phase 4 — Narrative & cosmology

- [x] **P4-01** `narrative_nodes` + `narrative_cast` content pipeline
- [x] **P4-02** Ramayana content — 7 kandas, ~100 scenes, `recension='valmiki'`, cited to Dutt/Griffith
- [x] **P4-03** Mahabharata content — 18 parvas, ~120 events, cited to Ganguli
- [x] **P4-04** Link scenes to `place_entity_id`, `narrative_cast`, `scripture_section_id`
- [x] **P4-05** `NarrativeScreen(epic:'ramayana')` — vertical dashed-path painter, alternating scene cards
- [x] **P4-06** Kanda banner dividers; read/unread gold nodes; "Continue" pill
- [x] **P4-07** `NarrativeNodeScreen` — prose, Lesson panel, cast row, place chip, `SourceChip`, "Read the verse"
- [x] **P4-08** Prev/next scene navigation
- [x] **P4-09** `NarrativeScreen(epic:'mahabharata')` — horizontal timeline, parva rail, arc bands
- [x] **P4-10** Pinch-to-compress timeline density
- [x] **P4-11** "Kurukshetra: 18 days" sub-view
- [x] **P4-12** `cosmology_nodes` content — creation stages, 14 lokas, time cycles (Wilson's Vishnu Purana)
- [x] **P4-13** `SrishtyUniverseScreen` — parallax starfield painter (~120 seeded dots, 3 depths)
- [x] **P4-14** Loka stack as glass cards; "you are here" marker on Bhūloka
- [x] **P4-15** Inline expand → `long_description`, `attributes`, `SourceChip`
- [x] **P4-16** Track segmented control (Creation · Lokas · Time) + creation timeline variant
- [x] **P4-17** Yuga content — 4 yugas + manvantara/kalpa wrappers
- [x] **P4-18** `YugaExplorerScreen` — proportional arc wheel painter, dharma-ratio bar, present-age marker
- [x] **P4-19** "Zoom out" nesting yuga → mahayuga → manvantara → kalpa + standing disclaimer
- [x] **P4-20** *(optional)* Nav promotion — merge `/cosmos` into `/jyotish`, make `/gyan` a tab. **Own commit, trivially revertible**

---

## Phase 5 — Curated & interactive

### Festival Explorer (4.18)
- [x] **P5-01** `festivals` content — ~150 festivals/vrats with rule fields, `region` NOT NULL
- [x] **P5-02** Date resolution through `panchang_engine.dart` (computed, never fetched)
- [x] **P5-03** `FestivalExplorerScreen` — Upcoming mode with date badges + days-away
- [x] **P5-04** Browse mode — category chips + region selector + search
- [x] **P5-05** `FestivalDetailScreen` — When / Ritual / Fast rules / Story / deity / puja vidhi / `SourceChip`
- [ ] **P5-06** "Remind me" → `reminders`; "Add to calendar"
- [x] **P5-07** `_FestivalBanner` and the calendar app bar now open `/festivals`.
  `panchang/festivals.dart` is **deliberately kept**, not replaced: it answers a
  different question — *what falls on this specific day* — which the per-day
  calendar marks and the home widget need, and which a rule table does not
  answer without resolving all 58 rules per day. The two agree because both
  resolve through the same engine; `test/festival_resolver_test.dart` pins that

### Dharma Decision Game (4.11)
- [ ] **P5-08** `dharma_scenarios` + `dharma_choices` content — ~60 scenarios, `guna` tags, mandatory disclaimers
- [ ] **P5-09** `DharmaHubScreen` — scenario of the day, category tiles with completion rings
- [ ] **P5-10** `DharmaScenarioScreen` — context, stitched choice cards, no right/wrong marking
- [ ] **P5-11** Consequence expansion + cream Reflection panel with `SourceChip`
- [ ] **P5-12** "Journal this" → pre-filled `journal_entries` row
- [ ] **P5-13** Entry tiles on the Quiz hub and `/gyan`

### Vedic Science (4.15)
- [ ] **P5-14** `vidya_topics` content — ~80 topics, every one with `caution_*` and `modern_status`
- [ ] **P5-15** `VedicScienceScreen` — discipline tabs, `modern_status` chips
- [ ] **P5-16** `VidyaTopicScreen` — fixed section order ending in the caution panel
- [ ] **P5-17** Debug-mode widget assertion: no vidya card renders without its caution panel

### Knowledge Journeys (4.21)
- [ ] **P5-18** `learning_paths` + `path_steps` schema and loader
- [ ] **P5-19** Curate 10 launch paths (beginner / core / deeper) over existing content
- [ ] **P5-20** One-line "why this step" blurb per step, bilingual
- [ ] **P5-21** `path_progress` table in `aradhya_user.db`
- [ ] **P5-22** `JourneyListScreen` — cover cards, level chips, progress rings, in-progress float-to-top
- [ ] **P5-23** `PathDetailScreen` — reuse the 4.7 dashed-path painter; step cards with kind glyphs
- [ ] **P5-24** Continue pill; step completion animation; auto-advance. **No locking** — suggested order only
- [ ] **P5-25** Entry points: `/gyan` hero, Home "Start here" for users with no history, You tile
- [x] **P5-26** **G16** — resolved. Krishna-paksha Ekadashis were named from the
  amanta month against a purnimanta-indexed table. The failing assertion expected a
  bare `Ekadashi`, which the engine has never emitted, so it masked two further bugs:
  **G17** the adhika (leap) month was computed but not labelled, so its festivals
  inherited nija-month names and appeared twice — its Ekadashis are now Padmini and
  Parama; **G18** a vriddhi tithi spanning two sunrises fired its festival on both
  days. Suite is green at 133 tests. Commit `f36bbc6`.

---

## Phase 6 — Ask the Scriptures (4.19)

- [ ] **P6-01** `qa_pairs` content — ~400 curated pairs, each pinned to a verse, bilingual questions
- [ ] **P6-02** `question_fold` normalization matching the shared fold
- [ ] **P6-03** Retrieval over `search_tokens` restricted to `kind='shloka'`
- [ ] **P6-04** Ranking + confidence thresholds; curated `qa_pairs` layer on top
- [ ] **P6-05** `AskScripturesScreen` — single field, suggested questions, chakra "consulting" animation
- [ ] **P6-06** Answer card — verse first (Devanagari → transliteration → translation), then explanation, then `SourceChip`
- [ ] **P6-07** Explicit *not sure* state with ranked candidates — never a guess
- [ ] **P6-08** "Read in context ›" deep link into the reader at that verse
- [ ] **P6-09** Related-question chips + the standing "selected, not generated" footer

---

## Phase 7 — Polish & optimization (4.20)

- [ ] **P7-01** **G13** — wire `themeModeProvider`, drop the hardcoded `ThemeMode.light`
- [ ] **P7-02** **G13** — theme selector in the You tab; verify the dark ramp on every new screen
- [ ] **P7-03** Hindi typography sweep — every new screen checked for Devanagari overflow (tree nodes, graph edge chips, timeline bands, status chips)
- [ ] **P7-04** Hindi register review — devotional tone, not just literal accuracy, across all `_hi` content
- [ ] **P7-05** **G9** — add `just_audio`; source real recordings; populate `mantras.audio_url`
- [ ] **P7-06** **G9** — player UI with TTS fallback
- [ ] **P7-07** **4.22** — `interest_signals` table, increments, nightly 0.98 decay
- [ ] **P7-08** **4.22** — apply to discovery-rail ordering, related-edge tie-breaks, prompt theme, quiz weighting **only**
- [ ] **P7-09** **4.22** — "Why am I seeing this?" line + Reset personalization in You
- [ ] **P7-10** Verify the app is fully usable with `interest_signals` empty
- [ ] **P7-11** Performance pass — cold start, scroll jank on the graph/tree/timeline canvases
- [ ] **P7-12** Asset gzip + inflate-on-copy (footprint, Risk 5)
- [ ] **P7-13** Widget tests for the new screens (currently only astrology/panchang are covered)
- [ ] **P7-14** Device matrix pass on real hardware
- [ ] **P7-15** Spot-check related rails for the 20 highest-`importance` entities (Risk 8)
- [ ] **P7-16** Release checklist doc, including the `indexed_content_version` rebuild rule (Risk 2)

---

## Release gate — must all be green before any store build

- [ ] **RG-01** `assets/db/content.sqlite` replaced with our own content — the Ishvarvaani fixture is gone
- [ ] **RG-02** `meta.data_source` no longer says "DEV FIXTURE"
- [ ] **RG-03** All 52 placeholder images replaced; **zero** manifest rows with `replace_before_ship: true`
- [ ] **RG-04** `reference/ishvarvaani-apk/base.apk` and the reference DBs removed from the shipped tree (and ideally from git history)
- [ ] **RG-05** `build.py --strict` passes — no unverified content in the release DB
- [ ] **RG-06** `SOURCES.md` attribution block rendered in the About screen
- [ ] **RG-07** `indexed_content_version` matches; search deep links verified after the content swap
- [ ] **RG-08** Privacy policy states that journal, progress and personalization never leave the device
