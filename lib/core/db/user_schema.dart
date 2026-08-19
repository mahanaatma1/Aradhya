/// Schema for `aradhya_user.db` — the writable database holding everything the
/// user creates. It never leaves the device.
///
/// Why a database at all, when SharedPreferences already works:
///
///   * `japa_history_json` is unbounded and was re-encoded and rewritten in
///     full on **every bead tap**. `shared_preferences` rewrites its whole XML
///     file per `apply()`, so a 108-bead mala was 108 full-file writes.
///   * `habits_<YYYY-MM-DD>` created one preference key **per day, forever** —
///     a key-space leak with no upper bound.
///   * Bookmarks now need notes, tags, timestamps and sorting; journal entries
///     need date-range queries; reading progress needs percentages.
///
/// What stays in SharedPreferences: single scalars read synchronously during
/// widget build (`onboarded`, `user_name`, `ishta_deity`, `personality_result`,
/// `rashifal_rashi`, `birth_details_json`, locale, theme, font scale) plus the
/// streak/currency counters, which `StreakController` reads on the fast path.
/// Those are mirrored here for history, not moved.
library;

const int kUserSchemaVersion = 2;

/// v1 -> v2: the Pilgrimage Passport records how a visit felt, not only that
/// it happened. Purely additive -- ALTER TABLE ADD COLUMN keeps every existing
/// row and its note intact, which matters because this data exists nowhere
/// else and a user who loses a temple note has lost it permanently.
const List<String> kUserSchemaV2 = [
  'ALTER TABLE temple_visits ADD COLUMN rating INTEGER',
];

/// Executed in order on create. Each statement is separate so `Database.execute`
/// can run them one at a time (sqflite does not accept multi-statement SQL).
const List<String> kUserSchemaV1 = <String>[
  // ---------------------------------------------------------------- bookmarks
  //
  // `route` is resolved and stored at WRITE time. That is the structural fix
  // for the crash where the bookmarks screen pushed an unregistered path:
  // if a route cannot be built, the bug surfaces when the bookmark is created,
  // not when the user later taps it.
  '''
  CREATE TABLE bookmarks (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    src        TEXT    NOT NULL DEFAULT 'content',  -- 'content' | 'gyan'
    kind       TEXT    NOT NULL,                    -- aarti|chalisa|mantra|story|shloka|temple|entity|…
    ref_id     INTEGER NOT NULL,
    title_en   TEXT    NOT NULL,                    -- cached so the list renders offline
    title_hi   TEXT,
    subtitle   TEXT,
    route      TEXT    NOT NULL DEFAULT '',         -- '' = shown but not tappable, never dropped
    note       TEXT,
    tags       TEXT,                                -- JSON array
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE (src, kind, ref_id)
  )''',
  'CREATE INDEX ix_bm_created ON bookmarks(created_at DESC)',
  'CREATE INDEX ix_bm_kind    ON bookmarks(kind)',

  // --------------------------------------------------------- reading progress
  '''
  CREATE TABLE reading_progress (
    book_id          INTEGER PRIMARY KEY,
    scripture_id     INTEGER,
    last_section_idx INTEGER NOT NULL DEFAULT 0,
    sections_total   INTEGER NOT NULL DEFAULT 0,   -- snapshot; % = read/total
    sections_read    INTEGER NOT NULL DEFAULT 0,
    last_read_at     INTEGER NOT NULL,
    completed_at     INTEGER
  )''',
  'CREATE INDEX ix_progress_recent ON reading_progress(last_read_at DESC)',

  // ------------------------------------------------------------------ sadhana
  //
  // One row per completed practice, replacing three separate prefs schemes
  // (japa history JSON, per-day habit keys, breathing streak scalars).
  '''
  CREATE TABLE sadhana_sessions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    day_stamp  TEXT    NOT NULL,                   -- 'YYYY-MM-DD', matches dayStamp()
    practice   TEXT    NOT NULL,                   -- japa|breathing|reading|mandir|habit:<key>
    count      INTEGER NOT NULL DEFAULT 0,         -- beads, rounds, offerings
    duration_s INTEGER NOT NULL DEFAULT 0,
    meta       TEXT,                               -- JSON: mantra id, habit key, offering type
    created_at INTEGER NOT NULL
  )''',
  'CREATE INDEX ix_sadhana_day      ON sadhana_sessions(day_stamp)',
  'CREATE INDEX ix_sadhana_practice ON sadhana_sessions(practice, day_stamp)',

  '''
  CREATE TABLE sadhana_goals (
    practice     TEXT PRIMARY KEY,
    target_count INTEGER,
    target_s     INTEGER,
    reminder_min INTEGER,                          -- minutes past midnight; NULL = off
    active       INTEGER NOT NULL DEFAULT 1
  )''',

  // ------------------------------------------------------------ karma journal
  //
  // `prompt_text` is a frozen copy of the prompt as shown. Prompts live in
  // gyan.sqlite and can change between content builds; an entry must keep the
  // question it was actually answering.
  '''
  CREATE TABLE journal_entries (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    day_stamp   TEXT    NOT NULL,
    prompt_id   INTEGER,                           -- → gyan.journal_prompts.id
    prompt_text TEXT,
    body        TEXT    NOT NULL,
    mood        TEXT,                              -- shanti|krodha|harsha|vishada|bhaya
    lesson      TEXT,
    tags        TEXT,
    is_private  INTEGER NOT NULL DEFAULT 1,        -- private by default, always
    created_at  INTEGER NOT NULL,
    updated_at  INTEGER NOT NULL
  )''',
  'CREATE INDEX ix_journal_day ON journal_entries(day_stamp DESC)',

  // ---------------------------------------------------------------- reminders
  '''
  CREATE TABLE reminders (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    kind          TEXT    NOT NULL,                -- sadhana|journal|festival|mandir
    ref_key       TEXT,
    minute_of_day INTEGER NOT NULL,
    weekdays      TEXT    NOT NULL DEFAULT '1234567',
    enabled       INTEGER NOT NULL DEFAULT 1,
    notif_id      INTEGER NOT NULL                 -- flutter_local_notifications handle
  )''',

  // ----------------------------------------------------------- temple visits
  '''
  CREATE TABLE temple_visits (
    temple_id  INTEGER PRIMARY KEY,
    visited_at INTEGER NOT NULL,
    note       TEXT,
    rating     INTEGER          -- 1..5, optional; added in v2
  )''',

  // -------------------------------------------------------- currency ledger
  //
  // Punya and Kamal balances stay in prefs for synchronous reads; this is the
  // audit trail, so "where did my Kamal go?" is answerable.
  '''
  CREATE TABLE currency_ledger (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    day_stamp  TEXT    NOT NULL,
    reason     TEXT    NOT NULL,                   -- daily_visit|japa_mala|habit|rashifal_reveal|offering
    punya      INTEGER NOT NULL DEFAULT 0,
    kamal      INTEGER NOT NULL DEFAULT 0,         -- negative = spent
    created_at INTEGER NOT NULL
  )''',
  'CREATE INDEX ix_ledger_day ON currency_ledger(day_stamp DESC)',

  // ---------------------------------------------------------- learning paths
  '''
  CREATE TABLE path_progress (
    path_id      INTEGER NOT NULL,
    step_no      INTEGER NOT NULL,
    completed_at INTEGER NOT NULL,
    PRIMARY KEY (path_id, step_no)
  )''',

  // ------------------------------------------------------- personalization
  //
  // Local, resettable, and deliberately narrow: it may order discovery
  // surfaces, never filter what content is reachable.
  '''
  CREATE TABLE interest_signals (
    topic      TEXT PRIMARY KEY,                   -- a tag, or an entity slug
    score      REAL NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL
  )''',

  // --------------------------------------------------------------- app meta
  'CREATE TABLE user_meta (key TEXT PRIMARY KEY, value TEXT)',
];

/// Keys used in `user_meta`.
class UserMetaKeys {
  UserMetaKeys._();

  /// Set to '1' only after the SharedPreferences import completes inside its
  /// transaction. If the app dies mid-migration the flag is absent, so the
  /// whole import re-runs cleanly on next launch.
  static const migratedFromPrefs = 'migrated_from_prefs';

  /// Timestamp of that migration, for support questions.
  static const migratedAt = 'migrated_at';
}
