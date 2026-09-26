-- ============================================================================
-- Aradhya — gyan.sqlite  (authoritative DDL)
--
-- This is the NEW, licence-clean content database. It ships as
-- assets/db/gyan.sqlite and is ATTACHed read-only to the existing
-- content.sqlite connection as `gyan` (see lib/core/db/content_database.dart).
--
-- content.sqlite is NEVER modified. Its rows are indexed into search_docs /
-- related_edges from here, which is how universal search and the related rail
-- span the legacy corpus without touching it.
--
-- Every content table carries:
--   * bilingual _en/_hi pairs                          (§1.11 bilingual contract)
--   * denormalized primary_source_* + last_verified_at (§1.3 provenance)
--   * verification_status                              (--strict gate)
--
-- Applied by content/tools/build.py. Do not hand-edit the built DB.
-- ============================================================================

PRAGMA encoding = 'UTF-8';
PRAGMA foreign_keys = ON;

-- ============================================================================
-- 1. PROVENANCE CORE
-- ============================================================================

-- One row per distinct source (a book, an edition, a dataset).
-- Populated from content/sources/registry.jsonl.
CREATE TABLE sources (
  id                    INTEGER PRIMARY KEY,
  slug                  TEXT NOT NULL UNIQUE,   -- 'ganguli-mahabharata'
  source_name           TEXT NOT NULL,          -- §3 source_name
  source_url            TEXT,                   -- §3 source_url
  source_type           TEXT NOT NULL           -- §3 source_type
      CHECK (source_type IN ('primary','secondary','reference','ai_summary')),
  source_language       TEXT,                   -- §3 source_language: 'sa','hi','en','mul'
  edition               TEXT,                   -- translator / press / year
  license_or_usage_note TEXT NOT NULL,          -- §3 license_or_usage_note
  retrieved_at          TEXT,                   -- ISO-8601
  checksum              TEXT                    -- sha256 of the raw/ file, if downloaded
);

-- Many-to-many: any content row -> any number of sources.
-- item_table is a plain string (not an FK) because it spans every content table.
CREATE TABLE item_sources (
  item_table                TEXT    NOT NULL,   -- 'entities' | 'narrative_nodes' | ...
  item_id                   INTEGER NOT NULL,
  source_id                 INTEGER NOT NULL REFERENCES sources(id),
  source_chapter_or_section TEXT,               -- §3 e.g. 'Sauptika Parva 13-15'
  quote                     TEXT,               -- the exact supporting line, if short
  last_verified_at          TEXT    NOT NULL,   -- §3 last_verified_at
  verified_by               TEXT,
  is_primary                INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (item_table, item_id, source_id, source_chapter_or_section)
);
CREATE INDEX ix_item_sources_item ON item_sources(item_table, item_id);

-- ============================================================================
-- 2. SHARED ENTITY CORE
--    Backs 4.1 Knowledge Graph, 4.2 Family Tree, 4.10 Symbols,
--    4.12 Ancient Weapons, 4.13 Rishi Encyclopedia.
-- ============================================================================

CREATE TABLE entities (
  id                    INTEGER PRIMARY KEY,
  slug                  TEXT NOT NULL UNIQUE,   -- 'hanuman', 'brahmastra', 'om'
  kind                  TEXT NOT NULL
      CHECK (kind IN ('deity','avatar','rishi','king','asura','human',
                      'place','river','mountain','scripture','festival',
                      'weapon','symbol','concept','dynasty','yuga','loka','vidya')),
  title_en              TEXT NOT NULL,
  title_hi              TEXT,                   -- --strict: NOT NULL in effect
  title_sa              TEXT,                   -- Devanagari canonical (Sanskrit, not Hindi)
  title_iast            TEXT,                   -- 'kṛṣṇa'
  category              TEXT,                   -- sub-grouping within kind
  short_description_en  TEXT NOT NULL,          -- <= 200 chars, card blurb
  short_description_hi  TEXT,                   -- --strict: NOT NULL in effect
  long_description_en   TEXT,
  long_description_hi   TEXT,
  region                TEXT,                   -- 'pan-india', 'tamil-nadu'
  tradition             TEXT,                   -- 'vaishnava','shaiva','valmiki'
  tags                  TEXT,                   -- JSON array
  props                 TEXT,                   -- kind-specific JSON (schema/kinds/*.schema.json)
  image_asset           TEXT,                   -- must resolve in assets/manifest.json
  glyph                 TEXT,                   -- symbols: the Unicode char, if any
  importance            INTEGER NOT NULL DEFAULT 3,  -- 1 major .. 5 minor; search boost + tiering
  wikidata_qid          TEXT,                   -- provenance + re-sync key
  primary_source_name   TEXT,                   -- denormalized from item_sources by build.py
  primary_source_ref    TEXT,
  primary_source_url    TEXT,
  last_verified_at      TEXT,
  verification_status   TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  -- CM-01/CM-02: what kind of statement this row's substance is, and how
  -- trustworthy its source is. Nullable — additive on existing rows, no
  -- backfill required. See "Claim classification" / "Confidence model" in
  -- the plan doc for the full rationale.
  claim_type             TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality          TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_entities_kind ON entities(kind, importance);
CREATE INDEX ix_entities_cat  ON entities(kind, category);

-- Every spelling in every script. This is what makes 'krishna', 'kṛṣṇa' and
-- 'कृष्ण' return the same row.
CREATE TABLE entity_aliases (
  entity_id  INTEGER NOT NULL REFERENCES entities(id),
  alias      TEXT    NOT NULL,
  alias_fold TEXT    NOT NULL,   -- lowercased + diacritic-folded (common.fold)
  script     TEXT,               -- 'deva' | 'latn' | 'iast' | 'taml'
  lang       TEXT,               -- 'sa' | 'hi' | 'en' | 'ta'
  alias_kind TEXT                -- 'primary'|'epithet'|'transliteration'|'spelling'|'regional'
);
CREATE INDEX ix_alias_entity ON entity_aliases(entity_id);
CREATE INDEX ix_alias_fold   ON entity_aliases(alias_fold);

-- Typed edges. The Family Tree (4.2) is a PROJECTION of this table filtered to
-- the lineage rel_types -- it is not a separate dataset.
--
-- rel_type vocabulary lives in validate.py (not a CHECK) so it can grow:
--   lineage : father_of mother_of spouse_of sibling_of child_of
--   teaching: guru_of disciple_of
--   epic    : wields wielded_by killed_by incarnation_of mount_of consort_of
--   text    : authored appears_in mentioned_in
--   place   : located_in ruled_by worshipped_at
--   dynasty : member_of has_member -- a person to the `kind='dynasty'`
--             entity they belong to. NOT the same as ruled_by (place -> its
--             ruler): a dynasty entity is a lineage, not a place, and someone
--             can be a member without ever having reigned.
--   generic : related_to symbol_of associated_with part_of
-- build.py materialises inverse pairs so every query is single-direction.
CREATE TABLE relations (
  id         INTEGER PRIMARY KEY,
  src_id     INTEGER NOT NULL REFERENCES entities(id),
  rel_type   TEXT    NOT NULL,
  dst_id     INTEGER NOT NULL REFERENCES entities(id),
  ordinal    INTEGER,           -- birth order among siblings, etc.
  tradition  TEXT,              -- §4.2: lineages differ by tradition -- store both, label both
  note_en    TEXT,
  note_hi    TEXT,
  confidence TEXT NOT NULL DEFAULT 'high'
      CHECK (confidence IN ('high','medium','low','disputed'))
);
CREATE INDEX ix_rel_src ON relations(src_id, rel_type);
CREATE INDEX ix_rel_dst ON relations(dst_id, rel_type);

-- ============================================================================
-- 3. SATELLITES
-- ============================================================================

-- 4.6 Srishty Universe + 4.14 Yuga Explorer
CREATE TABLE cosmology_nodes (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  track                TEXT NOT NULL CHECK (track IN ('creation','loka','time_cycle','yuga')),
  parent_id            INTEGER REFERENCES cosmology_nodes(id),
  order_no             INTEGER NOT NULL,
  title_en             TEXT NOT NULL, title_hi TEXT, title_sa TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en  TEXT,          long_description_hi  TEXT,
  duration_years       TEXT,          -- TEXT: kalpa-scale values exceed int64
  attributes           TEXT,          -- JSON: dharma_ratio, guardians, symbolic_meaning
  entity_id            INTEGER REFERENCES entities(id),
  tradition            TEXT, tags TEXT, region TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_cosmo_track ON cosmology_nodes(track, order_no);

-- 4.7 Ramayana Journey + 4.8 Mahabharata Timeline
CREATE TABLE narrative_nodes (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  epic                 TEXT NOT NULL CHECK (epic IN ('ramayana','mahabharata')),
  recension            TEXT NOT NULL,   -- 'valmiki'|'ramcharitmanas'|'kamba'|'critical_ed'
  book_label_en        TEXT,            -- 'Bala Kanda' / 'Adi Parva'
  book_label_hi        TEXT,
  book_no              INTEGER,
  sequence_no          INTEGER NOT NULL,-- NARRATIVE order. Not a historical date (§4.8).
  title_en             TEXT NOT NULL, title_hi TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en  TEXT,          long_description_hi  TEXT,
  -- Deprecated in favour of reflection_*: a lesson states a moral, and
  -- "Moral lesson: be good" is the register this feature must avoid. Kept so
  -- existing rows stay valid; new content writes reflection_* instead.
  lesson_en            TEXT,          lesson_hi TEXT,

  -- ---- Story Cards (SC-01) -------------------------------------------
  -- All nullable: every column here is additive so the rows written before
  -- this migration remain valid without a backfill.
  --
  -- The arc is the missing middle level. A kanda holds a flat run of scenes
  -- today; an arc groups the handful belonging to one movement of the story,
  -- which is what makes a section navigable without a scroll bar.
  arc_slug             TEXT,
  arc_title_en         TEXT,          arc_title_hi TEXT,
  arc_no               INTEGER,       -- order of the arc within its section

  -- The 30-second read. Deliberately distinct from short_description, which
  -- is a card blurb and is often a fragment rather than a summary.
  quick_summary_en     TEXT,          quick_summary_hi TEXT,

  -- The narrative proper: 100-250 words for a minor event, 300-600 for a
  -- major one. long_description is reused where it already holds one.
  story_en             TEXT,          story_hi TEXT,

  -- JSON array of 3-6 beats, for the "What happened" list.
  key_moments_en       TEXT,          key_moments_hi TEXT,

  -- A QUESTION, never a moral. Feeds the Dharma game and the Journal.
  reflection_en        TEXT,          reflection_hi TEXT,

  -- JSON array: dharma, duty, sacrifice. Drives Explore-by-theme.
  themes               TEXT,

  illustration_asset   TEXT,          -- manifest gate in 1.12 applies

  -- Denormalised at build time so paging never costs a query.
  prev_node_id         INTEGER,       next_node_id INTEGER,
  -- --------------------------------------------------------------------

  -- NR-01: sequence_no orders the narrative telling, not real-world time --
  -- a Ramayana scene comes before another because the poem tells it first,
  -- not because it happened first by any dateable calendar. 'traditional' is
  -- the default because that is what every node authored so far actually is:
  -- an ordering handed down by the text, not derived from an external date.
  chronology_confidence TEXT NOT NULL DEFAULT 'traditional'
      CHECK (chronology_confidence IN ('traditional','disputed','confirmed')),

  place_entity_id      INTEGER REFERENCES entities(id),
  scripture_section_id INTEGER,       -- soft link into main.scripture_sections (no FK: other DB)
  image_asset          TEXT,
  tags TEXT, region TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_narr_seq ON narrative_nodes(epic, recension, sequence_no);
-- Story mode groups by section then arc; the timeline still uses ix_narr_seq.
CREATE INDEX ix_narr_arc ON narrative_nodes(epic, book_no, arc_no, sequence_no);

CREATE TABLE narrative_cast (
  node_id   INTEGER NOT NULL REFERENCES narrative_nodes(id),
  entity_id INTEGER NOT NULL REFERENCES entities(id),
  role      TEXT,   -- 'protagonist','antagonist','witness'
  PRIMARY KEY (node_id, entity_id)
);
CREATE INDEX ix_cast_entity ON narrative_cast(entity_id);

-- 4.11 Dharma Decision Game
CREATE TABLE dharma_scenarios (
  id                  INTEGER PRIMARY KEY,
  slug                TEXT NOT NULL UNIQUE,
  title_en            TEXT NOT NULL, title_hi TEXT,
  category            TEXT,          -- 'family','duty','truth','war','wealth'
  difficulty          INTEGER NOT NULL DEFAULT 2,
  context_en          TEXT NOT NULL, context_hi TEXT,
  reflection_en       TEXT NOT NULL, reflection_hi TEXT,
  based_on_node_id    INTEGER REFERENCES narrative_nodes(id),
  disclaimer_en       TEXT, disclaimer_hi TEXT,   -- §4.11 reflection, not authority
  tags TEXT, region TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at    TEXT,
  verification_status TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type           TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality       TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);

-- No 'correct' answer: choices carry a guna, never a score. (§4.11)
CREATE TABLE dharma_choices (
  id             INTEGER PRIMARY KEY,
  scenario_id    INTEGER NOT NULL REFERENCES dharma_scenarios(id),
  choice_key     TEXT NOT NULL,           -- 'A'..'D'
  label_en       TEXT NOT NULL, label_hi TEXT,
  consequence_en TEXT NOT NULL, consequence_hi TEXT,
  guna           TEXT CHECK (guna IN ('sattva','rajas','tamas') OR guna IS NULL),
  order_no       INTEGER NOT NULL
);
CREATE INDEX ix_choice_scenario ON dharma_choices(scenario_id, order_no);

-- 4.15 Vedic Science. caution_en is NOT NULL by design -- the §4.15
-- medical-advice rule is enforced by the schema, not by a review checklist.
CREATE TABLE vidya_topics (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  discipline           TEXT NOT NULL,  -- 'ayurveda','jyotisha','shulba','yoga','vyakarana','chandas'
  title_en             TEXT NOT NULL, title_hi TEXT,
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  long_description_en  TEXT,          long_description_hi  TEXT,
  practical_use_en     TEXT,          practical_use_hi     TEXT,
  caution_en           TEXT NOT NULL, caution_hi TEXT,
  modern_status        TEXT NOT NULL CHECK (modern_status IN
      ('corroborated','partially_corroborated','not_evaluated','contested')),
  tags TEXT, region TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_vidya_discipline ON vidya_topics(discipline);

-- 4.18 Festival Explorer.
-- Stores the RULE, not the date. panchang_engine.dart resolves it per year and
-- per location -- which is why no panchang site needs to be scraped.
-- region is NOT NULL: §4.18 is explicit that dates vary by region/tradition.
CREATE TABLE festivals (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  title_en             TEXT NOT NULL, title_hi TEXT, title_sa TEXT,
  category             TEXT,          -- 'major','vrat','jayanti','regional'
  lunar_month          TEXT,          -- 'kartika'
  paksha               TEXT CHECK (paksha IN ('shukla','krishna') OR paksha IS NULL),
  tithi                INTEGER,       -- 1..15
  solar_rule           TEXT,          -- for Makar Sankranti etc.
  region               TEXT NOT NULL,
  tradition            TEXT,
  deity_entity_id      INTEGER REFERENCES entities(id),
  story_node_id        INTEGER REFERENCES narrative_nodes(id),
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  ritual_summary_en    TEXT,          ritual_summary_hi TEXT,
  fast_rules_en        TEXT,          fast_rules_hi TEXT,
  tags TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_fest_month ON festivals(lunar_month, paksha, tithi);

-- 4.19 Ask the Scriptures. Retrieval-first: the answer is always a stored
-- passage. 'needs_review' is a first-class state (§4.19).
CREATE TABLE qa_pairs (
  id                   INTEGER PRIMARY KEY,
  question_en          TEXT NOT NULL, question_hi TEXT,
  question_fold        TEXT NOT NULL,   -- normalized, for matching
  answer_en            TEXT NOT NULL, answer_hi TEXT,
  explanation_en       TEXT,          explanation_hi TEXT,
  passage_sa           TEXT,
  passage_translit     TEXT,
  scripture_section_id INTEGER,         -- soft link into main.scripture_sections
  confidence           TEXT NOT NULL
      CHECK (confidence IN ('high','medium','low','needs_review')),
  related_qa_ids       TEXT,            -- JSON array
  tags TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_qa_fold ON qa_pairs(question_fold);

-- RD-02 Word meaning tab: one row per Sanskrit word in a verse, in reading
-- order. A verse with no rows here just means the tab is still empty for it --
-- the reader-facing empty state in verse_tabs.dart is unaffected by this table
-- existing; it starts checking word_meanings once this ships.
CREATE TABLE word_meanings (
  id                   INTEGER PRIMARY KEY,
  scripture_section_id INTEGER NOT NULL,  -- soft link into main.scripture_sections
  order_no             INTEGER NOT NULL,
  sanskrit             TEXT NOT NULL,
  meaning_en           TEXT NOT NULL, meaning_hi TEXT
);
CREATE INDEX ix_word_meanings_section ON word_meanings(scripture_section_id, order_no);

-- RG-01 scripture rewrite: our own translation and commentary for a verse,
-- keyed on main.scripture_sections.id. The app reads these first and falls
-- back to the fixture only for verses not yet rewritten (the Ramayana today).
-- Sanskrit and transliteration are public domain and stay in the fixture.
CREATE TABLE scripture_overrides (
  section_id    INTEGER PRIMARY KEY,  -- soft link into main.scripture_sections
  body_en       TEXT NOT NULL, body_hi TEXT NOT NULL,
  commentary_en TEXT,          commentary_hi TEXT
);

-- RG-01 Ramayana: one prose retelling per sarga. The reader shows it in the
-- Explanation tab of every verse of that sarga that has no commentary of its own.
CREATE TABLE sarga_retellings (
  book_id      INTEGER NOT NULL,     -- soft link into main.scripture_books
  sarga        TEXT NOT NULL,        -- the part of scripture_sections.number before the dot
  title_en     TEXT NOT NULL, title_hi TEXT NOT NULL,
  retelling_en TEXT NOT NULL, retelling_hi TEXT NOT NULL,
  PRIMARY KEY (book_id, sarga)
);

-- 4.17 Karma Journal -- the PROMPTS are content; the entries live in
-- aradhya_user.db and never leave the device.
CREATE TABLE journal_prompts (
  id                  INTEGER PRIMARY KEY,
  slug                TEXT NOT NULL UNIQUE,
  prompt_en           TEXT NOT NULL, prompt_hi TEXT,
  theme               TEXT,          -- 'gratitude','restraint','duty','anger','service'
  scripture_section_id INTEGER,
  tags TEXT,
  primary_source_name TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at    TEXT,
  verification_status TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type           TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality       TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_prompt_theme ON journal_prompts(theme);

-- 4.21 Knowledge Journeys -- a curated playlist over content that already
-- exists. Steps point at rows in EITHER database via (src, ref_table, ref_id).
CREATE TABLE learning_paths (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  title_en             TEXT NOT NULL, title_hi TEXT,
  level                TEXT NOT NULL CHECK (level IN ('beginner','core','deeper')),
  short_description_en TEXT NOT NULL, short_description_hi TEXT,
  est_minutes          INTEGER,
  cover_asset          TEXT,
  order_no             INTEGER NOT NULL,
  tags TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_paths_level ON learning_paths(level, order_no);

CREATE TABLE path_steps (
  id          INTEGER PRIMARY KEY,
  path_id     INTEGER NOT NULL REFERENCES learning_paths(id),
  step_no     INTEGER NOT NULL,
  title_en    TEXT NOT NULL, title_hi TEXT,
  blurb_en    TEXT,          blurb_hi TEXT,   -- one line: why this step, here
  src         TEXT NOT NULL CHECK (src IN ('content','gyan')),
  ref_table   TEXT NOT NULL,
  ref_id      INTEGER NOT NULL,
  route       TEXT NOT NULL,
  est_minutes INTEGER,
  optional    INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX ix_path_steps ON path_steps(path_id, step_no);

-- ============================================================================
-- 4. DERIVED: SEARCH + RELATED
--    Both are built by index.py / relate.py and span BOTH databases.
--    content.sqlite is opened read-only and never written.
-- ============================================================================

CREATE TABLE search_docs (
  doc_id      INTEGER PRIMARY KEY,
  src         TEXT NOT NULL,        -- 'content' (legacy DB) | 'gyan'
  kind        TEXT NOT NULL,        -- 'temple','mantra','shloka','entity','festival','city',...
  ref_table   TEXT NOT NULL,
  ref_id      INTEGER NOT NULL,
  title_en    TEXT NOT NULL, title_hi TEXT,
  subtitle_en TEXT,          subtitle_hi TEXT,
  snippet_en  TEXT,          snippet_hi  TEXT,   -- ~140 chars for the result row
  route       TEXT NOT NULL,        -- resolved deep link; validated against routes.txt
  boost       REAL NOT NULL DEFAULT 1.0
);
CREATE UNIQUE INDEX ix_docs_ref  ON search_docs(src, ref_table, ref_id);
CREATE INDEX        ix_docs_kind ON search_docs(kind);

-- Plain B-tree inverted index. Deliberately NOT FTS5: sqflite uses the system
-- SQLite, where FTS5 availability varies by Android version and OEM build.
-- The valuable part (folding + alias expansion) happens in the pipeline anyway,
-- so storage is a swappable detail behind SearchRepository.
--
-- Terms are INTERNED. Measured on the real corpus: 572k postings but only 21k
-- distinct terms, so storing the text inline cost ~6 MB once the table and its
-- index are counted. A term dictionary drops that to ~0.4 MB and makes the
-- posting index four small integers.
--
-- Prefix search stays cheap: scan search_terms (21k rows) for the prefix range,
-- then look the postings up by term_id.
CREATE TABLE search_terms (
  id    INTEGER PRIMARY KEY,
  token TEXT NOT NULL UNIQUE   -- folded; or raw Devanagari
);

-- WITHOUT ROWID, so the postings live in the primary key's B-tree and there is
-- no second copy. An ordinary table plus an index on (term_id, doc_id) stores
-- every posting twice; at 428k postings that was ~9 MB of pure duplication, and
-- the PK order is already the exact lookup order.
--
-- No `tf` column: term frequency is 1 for every posting here, because terms are
-- de-duplicated per (document, field) when the index is built. Scoring uses the
-- field weight alone.
CREATE TABLE search_tokens (
  term_id INTEGER NOT NULL,
  doc_id  INTEGER NOT NULL,
  field   INTEGER NOT NULL,   -- 0=title 1=alias 2=tag 3=subtitle 4=body
  PRIMARY KEY (term_id, doc_id, field)
) WITHOUT ROWID;

-- Precomputed cross-module recommendations (§1.10). Denormalized title/route so
-- one indexed query renders a whole rail -- no cross-DB join, no N+1.
CREATE TABLE related_edges (
  src_src     TEXT NOT NULL, src_table TEXT NOT NULL, src_id INTEGER NOT NULL,
  dst_src     TEXT NOT NULL, dst_table TEXT NOT NULL, dst_id INTEGER NOT NULL,
  dst_kind    TEXT NOT NULL,        -- drives the group header + glyph
  reason      TEXT NOT NULL,        -- 'deity','relation:wields','cast','tag','festival_deity'
  weight      REAL NOT NULL,
  title_en    TEXT NOT NULL, title_hi TEXT,
  subtitle_en TEXT,          subtitle_hi TEXT,
  route       TEXT NOT NULL
);
CREATE INDEX ix_related_src ON related_edges(src_src, src_table, src_id, weight DESC);

-- RG-01 kathas. Our own retellings of the vrat kathas, replacing the
-- Ishvarvaani fixture rows of `main.kathas` one for one (`legacy_id` is the
-- row each supersedes, so the swap is auditable and reversible).
--
-- The fixture carried a title, a deity string and one ~1,000-char body. Three
-- things are new here and all three are what a reader actually wants:
--   * `vrat_vidhi_*` -- how the fast is kept. The fixture had nothing at all,
--     which is the single biggest gap: the app could tell you the story of the
--     vrat but not how to observe it.
--   * `key_moments_*` -- JSON array, same shape as narrative_nodes, so a katha
--     can render the same beat-list UI the epics already use.
--   * `festival_slug` -- soft link to festivals(slug) rather than a FK, because
--     a katha may be told for an observance we have no festival row for yet.
--     Resolved at read time; a miss is an empty rail, not an error.
--
-- Every _en column has a _hi twin and both are populated: a row with English
-- and no Hindi fails review (RG-01 bilingual rule). `body_hi` is a parallel
-- retelling, not a translation of `body_en`, so the lengths run close but the
-- sentences do not correspond.
CREATE TABLE kathas (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  legacy_id            INTEGER,       -- main.kathas.id this replaces
  title_en             TEXT NOT NULL, title_hi TEXT NOT NULL,
  deity_en             TEXT,          deity_hi TEXT,   -- JSON arrays
  festival_slug        TEXT,          -- soft link to festivals(slug)
  entity_slugs         TEXT,          -- JSON array, soft links to entities(slug)
  when_en              TEXT,          when_hi TEXT,
  summary_en           TEXT NOT NULL, summary_hi TEXT NOT NULL,
  body_en              TEXT NOT NULL, body_hi TEXT NOT NULL,
  vrat_vidhi_en        TEXT,          vrat_vidhi_hi TEXT,
  phala_en             TEXT,          phala_hi TEXT,
  moral_en             TEXT,          moral_hi TEXT,
  key_moments_en       TEXT,          key_moments_hi TEXT,  -- JSON arrays
  reflection_en        TEXT,          reflection_hi TEXT,
  themes_en            TEXT,          themes_hi TEXT,       -- JSON arrays
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_kathas_order ON kathas(order_no);
CREATE INDEX ix_kathas_festival ON kathas(festival_slug);
CREATE INDEX ix_kathas_legacy ON kathas(legacy_id);


-- RG-01 reference tables carried over from the fixture. These are facts, not
-- creative expression: a list of Indian towns with coordinates, and the
-- traditional names of scriptures and their chapters. Nobody owns any of it, so
-- these are copied rather than rewritten -- the one exception being the 24
-- scripture_books subtitles, which ARE a translation choice and are authored
-- here (see subtitle_en/hi below).
CREATE TABLE cities (
  id           INTEGER PRIMARY KEY,
  name         TEXT NOT NULL,
  state        TEXT,
  country      TEXT NOT NULL DEFAULT 'India',
  lat          REAL NOT NULL,
  lon          REAL NOT NULL,
  tz           TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  utc_offset   REAL NOT NULL DEFAULT 5.5
);
CREATE INDEX ix_cities_name ON cities(name);
CREATE INDEX ix_cities_state ON cities(state);

CREATE TABLE scriptures (
  id           INTEGER PRIMARY KEY,
  name_en      TEXT NOT NULL, name_hi TEXT,
  slug         TEXT NOT NULL UNIQUE,
  cover        TEXT,
  order_no     INTEGER NOT NULL DEFAULT 0
);

-- subtitle_en/hi are ours: "The Yoga of Arjuna's Dejection" is a rendering
-- choice, not a traditional name, so the 24 non-empty ones are authored rather
-- than carried over.
CREATE TABLE scripture_books (
  id           INTEGER PRIMARY KEY,
  scripture_id INTEGER NOT NULL REFERENCES scriptures(id),
  title_en     TEXT NOT NULL, title_hi TEXT,
  subtitle_en  TEXT,          subtitle_hi TEXT,
  slug         TEXT NOT NULL UNIQUE,
  order_no     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX ix_sbooks_scripture ON scripture_books(scripture_id, order_no);


-- RG-01 devotional texts. The Sanskrit and the lyrics are public domain --
-- the Hanuman Chalisa is Tulsidas c.1600, the Mahamrityunjaya is Rigveda --
-- so what is replaced here is not the text but the fixture's TRANSCRIPTION of
-- it: its romanisation, its line breaks, its bracketed repeat markers. The
-- devanagari is set cleanly and the IAST is generated mechanically from it.
--
-- The authored fields are the ones the fixture actually owned: translation_*,
-- summary_* and how_to_chant_* on mantras. Those are written fresh.
CREATE TABLE mantras (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  legacy_id            INTEGER,
  title_en             TEXT NOT NULL, title_hi TEXT NOT NULL,
  deity_en             TEXT,          deity_hi TEXT,
  type_en              TEXT,          type_hi TEXT,
  sanskrit             TEXT NOT NULL,          -- public domain, set clean
  iast                 TEXT,                   -- mechanical transform of sanskrit
  translation_en       TEXT NOT NULL, translation_hi TEXT NOT NULL,
  summary_en           TEXT,          summary_hi TEXT,
  how_to_chant_en      TEXT,          how_to_chant_hi TEXT,
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_mantras_order ON mantras(order_no);

-- Aartis and chalisas share a shape: a traditional hymn with a deity and two
-- script renderings. `kind` keeps them in one table rather than two identical
-- ones, since the reader screen treats them the same way.
CREATE TABLE devotional_lyrics (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  legacy_id            INTEGER,
  kind                 TEXT NOT NULL CHECK (kind IN ('aarti','chalisa')),
  title_en             TEXT NOT NULL, title_hi TEXT NOT NULL,
  deity_en             TEXT,          deity_hi TEXT,
  lyrics_hi            TEXT NOT NULL,          -- devanagari, public domain
  lyrics_en            TEXT NOT NULL,          -- our romanisation of the same
  summary_en           TEXT,          summary_hi TEXT,
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_lyrics_kind ON devotional_lyrics(kind, order_no);


-- RG-01 stories. The fixture's 100 rows are Puranic and epic narratives told at
-- ~1,400 chars -- plot summaries. Ours are full retellings from the cited
-- public-domain sources, at the same bar as gyan.kathas.
--
-- Two fixes to the fixture's shape, both of which the app needed anyway:
--   * `emotions` was one English-only free-text column with 57 distinct tags,
--     most used once ("absorption", "exchange", "validation"). A Hindi reader
--     saw English filter chips. Here it is a JSON array in both scripts, drawn
--     from a controlled vocabulary so the chips are finite and translatable.
--   * there was no source column at all. Every row now carries provenance.
CREATE TABLE stories (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  legacy_id            INTEGER,          -- main.stories.id this replaces
  title_en             TEXT NOT NULL, title_hi TEXT NOT NULL,
  summary_en           TEXT NOT NULL, summary_hi TEXT NOT NULL,
  body_en              TEXT NOT NULL, body_hi TEXT NOT NULL,
  moral_en             TEXT,          moral_hi TEXT,
  reflection_en        TEXT,          reflection_hi TEXT,
  key_moments_en       TEXT,          key_moments_hi TEXT,   -- JSON arrays
  emotions_en          TEXT,          emotions_hi TEXT,      -- JSON arrays
  themes_en            TEXT,          themes_hi TEXT,        -- JSON arrays
  characters_en        TEXT,          characters_hi TEXT,    -- JSON arrays
  entity_slugs         TEXT,          -- JSON array, soft links to entities(slug)
  scripture_ref        TEXT,          -- where in the source it sits
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_stories_order ON stories(order_no);
CREATE INDEX ix_stories_legacy ON stories(legacy_id);

-- RG-01 puja procedures. The fixture had items/vidhi/benefits in English only
-- -- the Hindi existed solely inside a `data` JSON blob the Dart model never
-- read -- and vidhi_en was six terse lines. Here every column is bilingual and
-- the steps are written as instructions a first-timer could actually follow.
CREATE TABLE puja_vidhi (
  id                   INTEGER PRIMARY KEY,
  slug                 TEXT NOT NULL UNIQUE,
  legacy_id            INTEGER,
  title_en             TEXT NOT NULL, title_hi TEXT NOT NULL,
  deity_en             TEXT,          deity_hi TEXT,         -- JSON arrays
  category_en          TEXT,          category_hi TEXT,
  when_en              TEXT,          when_hi TEXT,
  duration_en          TEXT,          duration_hi TEXT,
  preparation_en       TEXT,          preparation_hi TEXT,
  items_en             TEXT,          items_hi TEXT,         -- JSON arrays
  vidhi_en             TEXT NOT NULL, vidhi_hi TEXT NOT NULL,-- JSON arrays of steps
  key_mantras          TEXT,          -- JSON: [{sanskrit, iast, en, hi}]
  benefits_en          TEXT,          benefits_hi TEXT,
  significance_en      TEXT,          significance_hi TEXT,
  common_mistakes_en   TEXT,          common_mistakes_hi TEXT,
  regional_variations_en TEXT,        regional_variations_hi TEXT,
  festival_slug        TEXT,          -- soft link to festivals(slug)
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_puja_order ON puja_vidhi(order_no);
CREATE INDEX ix_puja_festival ON puja_vidhi(festival_slug);


-- RG-01 quotes. The fixture shipped 1,000, and the honest number that can be
-- grounded is far smaller: 617 of them cite only a book ("Rig Veda",
-- "Mahabharata") with no chapter or verse, and a further set cite works we hold
-- no public-domain translation of at all (Yoga Vashistha, Hitopadesha, Chanakya
-- Niti, Srimad Bhagavatam, the medical samhitas).
--
-- A quote whose citation cannot be checked is worse than a missing quote: it
-- puts words in a scripture's mouth and invites the reader to trust them. So
-- this table holds only quotes we can point at a specific verse in a specific
-- public-domain edition. Everything else is dropped rather than carried over.
--
-- Quotes are a MIXTURE, not all verses: scripture lines with a chapter and
-- verse, teachings pulled from the stories and kathas we wrote, and traditional
-- sayings that have no single author. `kind` says which, and `verse_ref` is
-- null for everything that is not a numbered verse.
--
-- The one rule that holds across all four kinds: the attribution has to be
-- true. A traditional saying attributed to "Traditional" is honest; the same
-- line attributed to a named text we cannot check is not, which is why the
-- fixture's Chanakya Niti and Yoga Vashistha rows were not carried over.
CREATE TABLE quotes (
  id                   INTEGER PRIMARY KEY,
  legacy_id            INTEGER,
  -- `kind` is what shape of quote this is, because they are not all verses:
  --   'verse'      a scripture verse, with verse_ref and Sanskrit
  --   'teaching'   a line drawn from a story or katha we wrote
  --   'saying'     a traditional proverb or maxim, no single author
  --   'invocation' a mantra's meaning, rendered as a line
  kind                 TEXT NOT NULL DEFAULT 'verse'
      CHECK (kind IN ('verse','teaching','saying','invocation')),
  text_en              TEXT NOT NULL, text_hi TEXT NOT NULL,
  sanskrit             TEXT,          iast TEXT,
  source_title_en      TEXT NOT NULL, source_title_hi TEXT,
  -- Null for anything that is not a numbered verse. A proverb has no chapter.
  verse_ref            TEXT,
  source_slug          TEXT,
  scripture_verse_number TEXT,
  themes_en            TEXT,          themes_hi TEXT,   -- JSON arrays
  order_no             INTEGER NOT NULL DEFAULT 0,
  primary_source_name  TEXT, primary_source_ref TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed')),
  claim_type            TEXT CHECK (claim_type IN
      ('traditional','textual','historical','archaeological',
       'modern_interpretation','scientific') OR claim_type IS NULL),
  source_quality        TEXT CHECK (source_quality IN
      ('primary','secondary','reference') OR source_quality IS NULL)
);
CREATE INDEX ix_quotes_order ON quotes(order_no);
CREATE INDEX ix_quotes_source ON quotes(source_slug);

-- ============================================================================
-- 5. META
--    Stamped by build.py. content_version must equal
--    ContentDatabase.gyanAssetVersion -- asserted by test/db_version_test.dart.
-- ============================================================================

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
