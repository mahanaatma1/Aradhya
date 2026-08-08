-- ============================================================================
-- Aradhya — LEGACY content.sqlite schema  (REFERENCE ONLY — NEVER APPLIED)
--
-- Dumped from the shipped assets/db/content.sqlite so the pipeline can read it
-- without guessing. build.py opens this DB READ-ONLY to build search_docs and
-- related_edges; it never writes to it.
--
-- WARNING: this DB is the Ishvarvaani dev fixture.
--   meta.data_source = 'DEV FIXTURE (Ishvarvaani) - replace before store submission'
-- It is a release blocker (RG-01/RG-02), tracked outside this plan.
--
-- Superseded content/schema.sql, which had drifted from reality (declared
-- knowledge_quiz.category/.difficulty, trivia_facts.source and
-- scripture_sections.title_* — none of which exist here).
-- ============================================================================

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE daily_quotes (
  id INTEGER PRIMARY KEY,
  sanskrit TEXT, transliteration TEXT,
  en TEXT NOT NULL, hi TEXT,
  source_en TEXT, source_hi TEXT
);
CREATE TABLE knowledge_quiz (
            id           INTEGER PRIMARY KEY,
            question_en  TEXT NOT NULL,
            question_hi  TEXT,
            options      TEXT NOT NULL,
            correct_key  TEXT NOT NULL
        );
CREATE TABLE clue_riddles (
            id        INTEGER PRIMARY KEY,
            answer    TEXT NOT NULL,
            clues_en  TEXT NOT NULL,
            clues_hi  TEXT
        );
CREATE TABLE trivia_facts (
            id      INTEGER PRIMARY KEY,
            fact_en TEXT NOT NULL,
            fact_hi TEXT
        );
CREATE TABLE quotes (id INTEGER PRIMARY KEY, en TEXT, hi TEXT, source_en TEXT, source_hi TEXT);
CREATE TABLE kathas (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, deity TEXT, body_en TEXT, body_hi TEXT);
CREATE TABLE mantras (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, deity TEXT, type_en TEXT, sanskrit TEXT, iast TEXT, translation_en TEXT, translation_hi TEXT, summary_en TEXT, summary_hi TEXT, how_to_chant_en TEXT, how_to_chant_hi TEXT, audio_url TEXT);
CREATE TABLE aartis (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, deity TEXT, lyrics_en TEXT, lyrics_hi TEXT);
CREATE TABLE chalisas (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, deity TEXT, lyrics_en TEXT, lyrics_hi TEXT);
CREATE TABLE cities (id INTEGER PRIMARY KEY, name TEXT, state TEXT, country TEXT, lat REAL, lon REAL, tz TEXT, utc_offset REAL);
CREATE TABLE stories (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, emotions TEXT, body_en TEXT, body_hi TEXT);
CREATE TABLE temples (id INTEGER PRIMARY KEY, name_en TEXT, name_hi TEXT, deity_en TEXT, deity_hi TEXT, location_en TEXT, significance_en TEXT, significance_hi TEXT, category TEXT, state TEXT, district TEXT, lat REAL, lon REAL, data TEXT);
CREATE TABLE puja_vidhi (id INTEGER PRIMARY KEY, title_en TEXT, title_hi TEXT, deity TEXT, category TEXT, when_en TEXT, when_hi TEXT, items_en TEXT, vidhi_en TEXT, key_mantra TEXT, benefits_en TEXT, data TEXT);
CREATE TABLE scriptures (id INTEGER PRIMARY KEY, name_en TEXT, name_hi TEXT, slug TEXT UNIQUE, cover TEXT, order_no INTEGER);
CREATE TABLE scripture_books (id INTEGER PRIMARY KEY, scripture_id INTEGER, title_en TEXT, title_hi TEXT, subtitle_en TEXT, subtitle_hi TEXT, slug TEXT, order_no INTEGER);
CREATE TABLE scripture_sections (id INTEGER PRIMARY KEY, book_id INTEGER, number TEXT, body_en TEXT, body_hi TEXT, sanskrit TEXT, transliteration TEXT, commentary_en TEXT, commentary_hi TEXT, order_no INTEGER);

-- Row counts at dump time:
--   aartis = 0 cols
--   chalisas = 0 cols
--   cities = 0 cols
--   clue_riddles = 0 cols
--   daily_quotes = 0 cols
--   kathas = 0 cols
--   knowledge_quiz = 0 cols
--   mantras = 0 cols
--   meta = 0 cols
--   puja_vidhi = 0 cols
--   quotes = 0 cols
--   scripture_books = 0 cols
--   scripture_sections = 0 cols
--   scriptures = 0 cols
--   stories = 0 cols
--   temples = 0 cols
--   trivia_facts = 0 cols
