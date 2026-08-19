# Architecture guardrails

**Read this before changing anything structural.** It exists because an agent
that can see a working implementation can decide to "improve" it and break six
unrelated features. Every rule below is here because the alternative was tried,
or because something depends on it that is not obvious from the code.

If a task seems to require breaking one of these, **stop and ask**. Do not
route around it.

---

## The three stores

Refer to them by their logical names. Filenames can change; the contract must
not.

| Logical name | File today | Access | Holds |
|---|---|---|---|
| `CONTENT_DB` | `assets/db/content.sqlite` | read-only, bundled | Legacy fixture: 27,890 scripture sections, 187 temples, mantras, aartis, chalisas, stories, kathas, puja vidhi, quiz, riddles, trivia, quotes |
| `GYAN_DB` | `assets/db/gyan.sqlite` | read-only, bundled, `ATTACH`ed as `gyan` | Everything we authored: entities, relations, narrative, cosmology, festivals, dharma, vidya, qa, paths — plus the search index and related edges |
| `USER_DB` | `<docs>/aradhya_user.db` | read-write, own connection | Everything the user creates. Never shipped, never uploaded |

### DO NOT

- **Do not merge the three.** `CONTENT_DB` is re-copied whole whenever its
  version changes; folding our content into it would rewrite 45+ MB on every
  content patch, and would mix licence-clean content with the fixture that has
  to be deleted before release.
- **Do not create a fourth database, or one per feature.** `SQLITE_MAX_ATTACHED`
  is 10 and we use one attachment. Adding per-module files is how that limit
  gets hit and how the search index stops being able to span everything.
- **Do not write to `CONTENT_DB` or `GYAN_DB` at runtime.** They are opened
  read-only. Anything the user creates goes in `USER_DB`.
- **Do not put user data in a bundled database.** It would be wiped by the next
  content update.
- **Do not modify the legacy schema.** The search index spans it by reading it
  read-only at build time. Changing its shape breaks 33,245 indexed documents.

---

## Offline is a hard constraint, not a preference

The app must work with the network off, permanently. Not "degrade gracefully" —
**work**.

### DO NOT

- **Do not add a network call to any runtime path.** Network is a build-time
  tool only (`fetch_pd.py`, `wd_pull.py`), and those run on a developer machine.
- **Do not add Firebase, analytics, crash reporting or a remote config.**
- **Do not add voice search**, however convenient. It needs Google speech
  services and would put a hole in the offline guarantee for one feature.
- **Do not fetch images, fonts or audio at runtime.**
- **Do not add an on-device LLM.** Ask the Scriptures is retrieval-only, and
  that is the feature's entire integrity claim.

---

## Do not rewrite the calculation engines

Two subsystems are the most correct code in the repo and the least safe to
touch casually.

### Panchang (`lib/features/panchang/`)

- **Do not replace the engine.** It computes tithi, nakshatra, yoga, karana and
  lunar months from first principles. Festival dates derive from it.
- **Do not fetch panchang data from anywhere.** drikpanchang is proprietary and
  forbidden; a fetched date is right for one year and a rule is right forever.
- Three real bugs were fixed here (krishna-paksha Ekadashi naming, adhika-month
  labelling, vriddhi tithi firing twice) and each is pinned by a test. If a
  change makes `test/panchang_test.dart` fail, the change is wrong until proven
  otherwise.
- **An adhika (leap) month looks like a bug and is not.** A lunation containing
  no sankranti is intercalary; the month "sticking" is correct output.

### Astrology (`lib/features/astrology/`)

- **Do not replace Swiss Ephemeris** or rewrite the position calculations.
- `sweph` falls back to a lower-precision implementation under `flutter test`.
  **Astrology correctness cannot be verified by the test suite** — it needs a
  device run. Do not conclude from green tests that a change is safe.

---

## Content pipeline

Direction of flow is fixed:

```
sources (registry) → raw/ → curation/ → data/ → GYAN_DB
```

### DO NOT

- **Do not hand-edit `content/data/*.jsonl`.** It is generated. `extract.py
  --promote` regenerates `core.jsonl` from `content/curation/`, and prose
  written directly into `data/` **has already been silently destroyed once** —
  22 of 27 enriched entities lost their descriptions that way. Authored prose
  belongs in `content/curation/`.
- **Do not commit `content/raw/`.** It is gitignored; sha256 in the manifest is
  what makes it reproducible.
- **Do not add a source without a registry entry** carrying its licence.
- **Do not paste Wikipedia prose.** CC BY-SA share-alike would infect the whole
  corpus. Use it as a lead to the primary text, never as text.
- **Do not extract from** vedabase.io (© BBT), drikpanchang (proprietary),
  GRETIL (non-commercial), Vedic Heritage Portal (permission required), or
  sanskritdocuments.org in bulk (per-document terms).
- **Do not let AI invent** a relation, a date, a lineage, a citation or a verse
  reference. AI rewrites and translates sourced material. That is all.
- **Do not name the translator in user-facing prose.** Griffith, Ganguli and
  Wilson are provenance and already appear in the source chip.

### Always

- Run `content_diff` after a build. It fails on any measure that decreased.
- A citation must be read off the page it cites. **34 out of 34 labels guessed
  from URLs were wrong** the first time this was done.

---

## Search and related content

- **Do not switch to FTS5.** `sqflite` uses the system SQLite and FTS5
  availability varies by Android version and OEM. The inverted index is
  deliberate.
- **Do not build the index at runtime.** It is a build-time artifact.
- **Do not rebuild `CONTENT_DB` without rebuilding `GYAN_DB`.** The index spans
  both; a mismatch makes every legacy result deep-link to the wrong row.
  `indexed_content_version` guards it and the build fails on mismatch.
- **Do not weaken the alias rules in `relate.py`.** Ambiguous tokens (`devi`,
  `mata`, `bhagwan`, `ji`, `baba`) are refused outright, and only `primary` or
  `epithet` aliases are matched. A wrong recommendation is far more visible to
  a user than a missing one.

---

## User data and privacy

- **Do not upload anything, ever.** Journal entries, reading progress, temple
  visits and interest signals stay on the device.
- **Do not add sharing by default** anywhere near the journal.
- **Do not let personalization change what is visible.** `interest_signals` may
  reorder discovery. It must never hide, remove or gate content. If that
  distinction blurs, delete the feature.
- **Do not delete legacy prefs keys** until a release has shipped that no
  longer reads them; a rollback still needs the data.

---

## UI conventions

- **Do not introduce a second navigation pattern.** `/gyan` and the other four
  tabs are shell branches; navigate to them with `go`, not `push` — `push`
  stacks a screen above the shell and leaves the wrong tab highlighted.
- **Do not add a sixth tab.** Five at 58 px already crowd the Hindi labels.
- **Do not bundle raster art for icons.** Drawn motifs (`gyan_motifs.dart`)
  need no licence, scale to any size and take the tile's colour.
- **Do not lay out in English first.** Devanagari needs ~15–20% more
  line-height and its words are longer; English-first layouts overflow in Hindi
  after the fact.
- **Do not remove a caution panel, a source chip or a disclaimer** to tidy a
  screen. The vidya caution is enforced four ways on purpose.
- **Do not add right/wrong marking to the Dharma game.** There is no correct
  answer and the feature's whole design rests on that.

---

## Testing

- **No feature is complete without its test.**
- **Do not delete or weaken a test to make a build pass.** Every test in this
  repo was written because something broke.
- Green tests do **not** prove: astrology correctness, gzip DB inflate on
  device, notification delivery past OEM battery policy, or scroll performance
  on the graph and tree canvases. Those need hardware.

---

## When a rule is genuinely wrong

Rules here are load-bearing, not sacred. If one blocks something valuable:

1. Say which rule and why it blocks the work.
2. Say what would break if it were relaxed.
3. Get agreement before changing it.
4. Update this file in the same commit.

Silently routing around a guardrail is the failure mode this document exists to
prevent.
