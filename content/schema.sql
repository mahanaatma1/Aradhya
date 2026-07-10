-- DivyaVaani content database schema.
-- The build script (build.py) creates assets/db/content.sqlite from this
-- schema + the data files in content/data/. Structure mirrors the proven
-- Ishvarvaani layout (studied in reference/ishvarvaani-content.sql) but all
-- rows are our own original / public-domain content.

PRAGMA encoding = 'UTF-8';

-- Quiz game -----------------------------------------------------------------
CREATE TABLE knowledge_quiz (
  id           INTEGER PRIMARY KEY,
  question_en  TEXT NOT NULL,
  question_hi  TEXT,
  options      TEXT NOT NULL,   -- JSON: [{"key":"A","en":"...","hi":"..."}, ...]
  correct_key  TEXT NOT NULL,   -- "A".."D"
  category     TEXT,            -- our addition: topic tag
  difficulty   INTEGER          -- our addition: 1 easy .. 3 hard
);

CREATE TABLE clue_riddles (
  id        INTEGER PRIMARY KEY,
  answer    TEXT NOT NULL,
  clues_en  TEXT NOT NULL,      -- JSON array of progressive clues
  clues_hi  TEXT
);

CREATE TABLE trivia_facts (
  id      INTEGER PRIMARY KEY,
  fact_en TEXT NOT NULL,
  fact_hi TEXT,
  source  TEXT
);

-- Daily quote ---------------------------------------------------------------
CREATE TABLE daily_quotes (
  id INTEGER PRIMARY KEY,
  sanskrit TEXT, transliteration TEXT,
  en TEXT NOT NULL, hi TEXT,
  source_en TEXT, source_hi TEXT
);

-- Scriptures ----------------------------------------------------------------
CREATE TABLE scriptures (
  id INTEGER PRIMARY KEY, name_en TEXT, name_hi TEXT,
  slug TEXT UNIQUE, cover TEXT, order_no INTEGER
);

CREATE TABLE scripture_books (
  id INTEGER PRIMARY KEY, scripture_id INTEGER,
  title_en TEXT, title_hi TEXT, slug TEXT, order_no INTEGER
);

CREATE TABLE scripture_sections (
  id INTEGER PRIMARY KEY, book_id INTEGER, number TEXT,
  title_en TEXT, title_hi TEXT, body_en TEXT, body_hi TEXT,
  sanskrit TEXT, transliteration TEXT, order_no INTEGER
);

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
