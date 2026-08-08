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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
  lesson_en            TEXT,          lesson_hi TEXT,
  place_entity_id      INTEGER REFERENCES entities(id),
  scripture_section_id INTEGER,       -- soft link into main.scripture_sections (no FK: other DB)
  image_asset          TEXT,
  tags TEXT, region TEXT,
  primary_source_name  TEXT, primary_source_ref TEXT, primary_source_url TEXT,
  last_verified_at     TEXT,
  verification_status  TEXT NOT NULL DEFAULT 'unverified'
      CHECK (verification_status IN ('unverified','verified','disputed'))
);
CREATE INDEX ix_narr_seq ON narrative_nodes(epic, recension, sequence_no);

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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
      CHECK (verification_status IN ('unverified','verified','disputed'))
);
CREATE INDEX ix_qa_fold ON qa_pairs(question_fold);

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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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
      CHECK (verification_status IN ('unverified','verified','disputed'))
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

-- ============================================================================
-- 5. META
--    Stamped by build.py. content_version must equal
--    ContentDatabase.gyanAssetVersion -- asserted by test/db_version_test.dart.
-- ============================================================================

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
