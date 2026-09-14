# Handoff: RG-01 for the non-scripture tables

**Owner:** the second session. **Not yours:** `scripture_sections` (27,890 rows —
Gita/Upanishads/Ramayana). That stays with the session already doing it.

**Goal:** every creative string the app reads out of `assets/db/content.sqlite`
is ours, so the Ishvarvaani fixture can be deleted before release.

---

## 0. Read this first: the verb is not "rewrite"

The instinct is to take each Ishvarvaani row and reword it. **Do not do that for
anything except the small lyric set.** Rewording someone else's row keeps their
selection, their sequence, and their factual errors, and it leaves you with text
whose provenance is "their sentence, edited" — which is exactly the thing RG-01
exists to remove. A rewrite also cannot be checked: `legal_own.py` can tell you
two strings differ, it cannot tell you the second one was not derived from the
first.

The correct verb differs per table. Three of them:

| Verb | Means | Applies to |
|---|---|---|
| **COPY** | move the rows unchanged; they are facts or PD | cities, scriptures, scripture_books |
| **REGENERATE** | write from a cited PD source, *fixture never opened* | quiz, trivia, riddles, quotes, stories, kathas, puja_vidhi |
| **REPLACE** | substitute the PD original for their transcription | aartis, chalisas, mantras, daily_quotes |

REGENERATE is the one that matters. It is also **less work than rewriting**,
because you generate from a source you can cite instead of agonising over how
far from their sentence is far enough.

---

## 0.5. The writing standard — read the example before you write anything

This is not negotiable and it is the thing most likely to go wrong. The project
owner has been explicit: **detailed, human-readable prose, no jargon.**

**Go read `content/legal/own/scripture_verses/bgc_2.json` before writing a single
row.** That is the approved register, already shipped, already reviewed. Match it.

What it does, concretely (verse 2.2, ~1,430 chars, three paragraphs):

- Opens with a plain observation — "This is Krishna's very first line of
  teaching in the entire Gita, and it opens with a question, not a lecture."
- Explains *why it matters* rather than restating what happened.
- Reaches for an everyday analogy: a mentor talking to an athlete who wants to
  quit before the championship. Not a scriptural cross-reference.
- Uses zero untranslated Sanskrit. Not "kshatriya-dharma" — "the work he was
  born to do." Not "moha" — "a mood that arrived rather than a permanent part of
  his character."
- Ends on the human point, not a doctrinal summary.

The authored Gita commentary runs **1,425–2,006 chars, averaging ~1,640**. That
length is deliberate. It is what "in detail" means here — room for three real
paragraphs that develop an idea, not a paragraph that restates the verse.

### RULE ZERO: everything is bilingual. No exceptions.

**Every reader-facing string must exist in both English and Hindi.** A row with
English but no Hindi is not done, does not pass review, and does not ship. Half
the audience reads Hindi first.

This is a real gap in the fixture today, not a hypothetical:

- `puja_vidhi` has `items_en`, `vidhi_en`, `benefits_en` with **no `_hi`
  counterpart at all** — the Hindi exists only inside the `data` JSON blob,
  where the Dart model never reads it.
- `stories.emotions`, `kathas.deity` and `puja_vidhi.category` are
  English-only free text, so the filter chips a Hindi reader sees are in English.

So the rule has two halves:

1. **Every new column you add gets an `_en` and a `_hi` from the start.** Never
   add one and plan to backfill the other.
2. **Fix the existing English-only columns while you are in there** — add
   `items_hi`, `vidhi_hi`, `benefits_hi`, and give the tag vocabularies
   (emotions, category, deity) a Hindi rendering.

**Hindi is a parallel rendering, not a translation.** Write it at the same length
and the same level of detail as the English — if the English story is 4,000
chars, the Hindi is too. Do not calque English sentence structure; write natural
Hindi as a Hindi speaker would tell it. Sanskrit-derived vocabulary that is
ordinary in Hindi (धर्म, यज्ञ) stays; it only needs glossing in English.

**Checklist gate:** `legal_gen.py` should fail any row where an `_en` field is
non-empty and its `_hi` twin is empty, or where the Hindi is under ~60% of the
English length — that ratio catches a stub Hindi translation of a full English
paragraph.

### The rules

1. **No untranslated Sanskrit in body prose.** If a term must appear, translate
   it inline the first time and then use the English. Terms belong in
   `word_meanings`, not scattered through the prose.
2. **Explain, do not summarise.** A reader who knows nothing should finish
   understanding *why* it matters, not just what happened.
3. **Use ordinary analogies.** Mentors, families, work, money, arguments —
   things a reader lives. This is what makes it human-readable.
4. **Write full paragraphs.** No bullet fragments, no telegraphic notes, no
   encyclopaedia voice.
5. **Hindi is a parallel rendering, not a translation of the English.** Same
   register, natural Hindi. Do not calque English sentence structure.
6. **Never sacrifice length to finish faster.** A thin 300-char story body fails
   this bar even if it passes the licence check.

### What this means per table

- **stories / kathas** — full narrative prose. The fixture runs ~1,400 and
  ~1,050 chars; **ours should be longer, not shorter** — these are the rows a
  reader actually sits down with. Tell the story properly: who these people
  were, what they wanted, what went wrong, why it still gets retold.
- **puja_vidhi** — `vidhi_en` steps in plain instructional language a first-timer
  could follow. Say what to do and why that step is there. Not a terse list.
- **mantras** — `how_to_chant_*` is a real explanation: when, how many, what it
  is for, what to expect. `summary_*` gives the mantra a home — where it comes
  from, what it is used for.
- **trivia_facts** — one sentence, but a *self-contained interesting* sentence.
  No dangling references to things the reader cannot see.
- **knowledge_quiz** — questions in plain language, answerable without knowing
  Sanskrit. Distractors must be genuinely plausible, never filler.
- **quotes** — the translation should read as natural English, the way the Gita
  work reads, not word-for-word carryover from the Sanskrit.

---

## 1. Tier by tier

### COPY — cities (4,276), scriptures (3), scripture_books (130)

`cities` is name/state/country/lat/lon/tz. Coordinates are facts; a list of
Indian towns is not a creative selection. **Copy as-is.** One caveat: the rows
have no provenance. Re-derive lat/lon from an open dataset so the citation is
real — GeoNames (CC BY 4.0) or the OGD India dataset already in SOURCES.md.
Match on name+state, keep their row only where the open set has no entry, and
record the count of unmatched rows.

`scriptures` (3 rows) and `scripture_books` (130) are titles and slugs:
"Arjuna Vishada Yoga", `bgc_1`. Traditional names — nobody owns them. **Copy.**

**The one exception:** 24 of the 130 books have a `subtitle_en` like
"The Yoga of Arjuna's Dejection". That is a translation choice. 24 short strings
— rewrite those by hand, or take them from Telang (PD, already cited). Cheap.

### REPLACE — aartis (18), chalisas (10), mantras (36), daily_quotes (3)

The Hanuman Chalisa is Tulsidas, c. 1600. The Mahamrityunjaya is Rigveda. **The
devotional text itself is public domain** and needs no rewriting at all. What
you are replacing is Ishvarvaani's *transcription* of it — their romanisation,
their line breaks, their bracketed variants (`x2`, `(Maathe Par Sindoor…)`).

So: source the Devanagari from a PD edition, generate the IAST/romanisation
mechanically (`indic-transliteration`, already how transliteration is handled
elsewhere), and do the line breaks yourself.

The parts that ARE theirs and DO need authoring: `translation_en`,
`translation_hi`, `summary_en/hi`, `how_to_chant_en/hi` on mantras. That is 36
rows × ~6 fields, and the how-to-chant fields are the only genuinely creative
ones. Write them fresh from Vivekananda/Gopinatha Rao (both cited already).

Budget: **~250 authored strings**, all short. This is the smallest tier and the
best one to do first, because it exercises the pipeline end to end.

### REGENERATE — the large collections (~5,930 rows)

**Never open the fixture rows for these.** Generate from the corpus you already
own and then check for accidental collision.

- **knowledge_quiz (4,000)** — you already have `gyan.sqlite` with 816 entities,
  4,164 relations, 926 word_meanings, 139 festivals, 30 cosmology nodes, 18
  vidya topics, and 1,612 source citations. A quiz question is a mechanical
  projection of a cited fact: relation → question, entity aliases → distractors,
  `item_sources` → the citation. Generate them. Each row carries the source id
  of the fact it came from, which is provenance the fixture rows never had.
  4,000 rows is a generator, not a writing task.
- **trivia_facts (565)** — same mechanism, from the same tables. One sentence per
  cited fact.
- **clue_riddles (365)** — `answer` + 5 progressive clues. Answers are entity
  names from `entities`; clues are generated from that entity's relations and
  aliases, ordered specific→general.
- **quotes (1,000)** — these are translations of verses attributed to Rig Veda,
  Mahabharata, Gita, Upanishads, Hitopadesha. **Do not rewrite their English.**
  Take the verse each one cites, pull the PD translation (Griffith for Rigveda,
  Ganguli for Mahabharata, Telang for Gita, Muller for Upanishads — all already
  in SOURCES.md), and render it yourself the same way the scripture session
  renders verses. ~340 cite the Gita, which the other session is already
  translating — **reuse those, do not duplicate the work.** Coordinate on that.
  Caution: many of these attributions are wrong or unverifiable. Any quote whose
  cited verse you cannot actually locate in the PD source gets **dropped**, not
  guessed. Expect to lose 10-20% and land near 800 good rows. That is a better
  product than 1,000 with fake citations.

### ⭐ THE PRIORITY TABLES — stories (100), kathas (57), puja_vidhi (23)

**The project owner has singled these three out: they must be done properly,
data-rich, and as detailed as you can make them.** 180 rows total. This is the
most important writing in the whole handoff — it is the content a reader
actually sits down with, and it is the long pole of the schedule. Everything in
§0.5 applies here at full strength.

#### What is wrong with the fixture rows today

Read `stories` id 1 (Sati/Daksha, 2,273 chars) and you can see the failure modes
to avoid:

- **Jargon dropped in untranslated**: "Prajapati", "Yajna", "Rudra Tandava",
  "Dharma" — some glossed in parentheses, most not.
- **Wrong facts**: Daksha's sacrifice was at Kanakhala near Haridwar, not
  "the celestial realm of Kanyakubja". Kanyakubja is Kannauj and belongs to a
  different story entirely. **Do not inherit their errors** — this is exactly
  why we regenerate from a cited source instead of rewriting.
- **Summary voice, not narrative**: "The story serves as a chilling reminder
  that…" tells the reader what to feel instead of making them feel it.
- **Everything at one pace**: Sati's humiliation and death get one sentence.
  That is the emotional centre of the story and it should be the longest beat.

`kathas` id 1 is 1,196 chars and reads like a plot summary — a child is
sacrificed daily and it passes in half a sentence with no weight at all.

#### Do not mirror their table

**Two standing instructions from the project owner (2026-09-14):**

**1. Write our own titles.** Do not reuse the fixture's. Theirs read
`"Sakat Chauth Vrat Katha (Story of the Potter)"` — a label plus a
parenthetical. Ours name the story in our own words, in both languages:
`"Vat Savitri Vrat: Savitri and Satyavan"`. A title is short enough that an
identical one is conspicuous, and there is no reason for ours to match.

**2. Add kathas they do not have.** A one-for-one replacement table advertises
itself as a replacement. `gyan.festivals` holds 139 observances and **110 have
no katha at all**; 44 of those are already `verified` with a cited PD source
(95 from Underhill, 15 from Gupte). Chhath Puja, Nag Panchami, Hariyali Teej,
Guru Purnima, Onam and Pitru Paksha are all missing today.

So the target is **not 57 rows**. Write the 57 we need to retire, then add from
that list of 44 until the collection stands on its own — call it **70-80 rows**.
Order by how well-sourced each one is, never by filling a quota; a katha we
cannot ground in Underhill, Gupte or a PD Purana does not get written.

This also settles the legal question more cleanly than rewriting ever could.
A table with different titles, different row counts and entries they never had
is not a derivative of theirs in any sense a reviewer would need to weigh.

Match `legacy_id` to the fixture row a katha retires, and leave it NULL for the
new ones — that is what keeps the swap auditable while the two tables diverge.

#### Target length and shape

| Table | Fixture | **Our target** |
|---|---|---|
| stories | ~1,400 avg | **3,500–5,000 chars** |
| kathas | ~1,050 avg | **2,500–4,000 chars** |
| puja_vidhi `vidhi_en` | ~400 | **one full paragraph per step** |

Roughly **2.5–3× the fixture**. That is what "as much as you can" means here.
Not padding — more actual story: what the place looked like, what people
wanted, what they said, why it went the way it did.

**Structure every story and katha in beats**, each a real paragraph:

1. **The world before** — who these people are, what their life is like.
2. **The turn** — what disrupts it.
3. **The crisis** — the emotional centre. **Give this the most room.**
4. **The response** — what the human or the divine actually does.
5. **The aftermath** — what changed, what it cost.
6. **Why it is still told** — woven into the ending, never bolted on as a moral.

Concretely, for Sati/Daksha: Daksha's grudge should be a *scene*, not a stated
fact. Sati arriving and finding no seat and no offering set aside for her
husband should be visible. Her decision should be given the weight of a
decision. That is the difference between 1,400 and 4,000 chars, and it is all
narrative, not filler.

#### Data-rich: fields to add

These tables are thin on structured data. Add columns in `content/schema/gyan.sql`
and populate as you write — richer data is the other half of "data-rich":

**stories** — has only `emotions` today:
- `source_en` / `source_hi` — which Purana or parva it comes from
- `characters` — JSON list, linkable to `gyan.entities`; names in both scripts
- `themes` — beyond the 4-emotion vocabulary in use now, with Hindi labels
- `summary_en` / `summary_hi` — 1–2 sentences for cards and search
- `moral_en` / `moral_hi` — the takeaway, stored separately so the prose need
  not stop to state it
- `related_festivals` — links to `gyan.festivals` where one exists

**kathas** — add all of the above, plus:
- `vrat_vidhi_en/hi` — how the fast is actually kept: what to eat, what to
  avoid, when to break it. Currently missing entirely, and it is the single
  most practical thing a reader wants from a vrat katha.
- `when_en/hi` — which tithi/day it is observed on
- `phala_en/hi` — the fruit traditionally ascribed to the observance

**puja_vidhi** — the richest opportunity. Today `vidhi_en` is six terse lines:
- Expand each step into **a full paragraph: what to do, how to do it, and why
  that step is there.** "Boil milk in a new vessel until it overflows" becomes
  a paragraph explaining the overflow as the wish for abundance, what vessel,
  which direction to face, what people say while doing it.
- `items_en` needs a **Hindi counterpart (`items_hi`)** — it has none today
  even though the JSON blob carries one. Same for `vidhi_hi` and `benefits_hi`
  (see Rule Zero).
- Add `duration_en/hi`, `preparation_en/hi` (what to do the day before),
  `common_mistakes_en/hi`, `regional_variations_en/hi`, `significance_en/hi`.
- `key_mantra` should become a **list** of mantras with transliteration and
  meaning, not the single one it holds now.

**Note the `data` JSON blob** on `puja_vidhi` duplicates every column.
Regenerate it from the columns in `build.py` — never hand-edit both.

**Before adding columns**, check `lib/features/stories/story_models.dart` and
`lib/features/puja/puja_models.dart`. The Dart models read a fixed field list,
so new columns need reader changes to be visible. Add the column and the model
field together, or the content ships invisible.

#### Sources

Sati/Daksha and most `stories` are Puranic — Wilson's Vishnu Purana and
Ganguli's Mahabharata are both cited and PD. Vrat kathas are traditional and
orally transmitted; Gupte's *Hindu Holidays and Ceremonials* and Underhill's
*The Hindu Religious Year* (both PD, both already in SOURCES.md) cover the
observances and the ritual procedure for `puja_vidhi`. Every row still needs its
`item_sources` entry.

Where no PD source covers a katha, **say so in the row's disposition rather than
inventing detail.** Enriching a story is telling it fully; it is not making
things up. A retelling may set a scene, but it may not invent a fact — no new
characters, no invented place names, no numbers the source does not give.

---

### UNASSIGNED — temples (187)

**Not in your list, but nobody else's either:** `temples` (187 rows) has
`significance_en/hi` — free prose, plus a 7 KB JSON `data` blob per row. Nobody
assigned it. Confirm who owns it before release; it is the same problem.

---

## 2. Tooling

`content/tools/legal_own.py` (729 lines) is scripture-specific: it is hardcoded
to `scripture_sections`, `scripture_books`, book slugs, and `AUTHORED =
(body_en, body_hi, commentary_en, commentary_hi)`. Its stopword lists are Gita
vocabulary.

**Do not fork it and do not generalise it in place** — the scripture session is
actively editing it, and you will collide.

Build `content/tools/legal_gen.py` alongside it, importing the scoring core
(`_words`, `_longest_run`, `_strip_diacritics`, `_too_close`) and supplying a
per-table config: table name, key, authored field list, stopword set. Its job is
different from `legal_own.py`'s:

- `legal_own.py` asks *"is this authored replacement distinct enough from the
  row it supersedes?"* — a rewrite check.
- `legal_gen.py` asks *"did anything I generated independently land too close to
  a fixture row by accident?"* — a collision check, run once at the end.

Same maths, opposite intent. For generated content it should come back clean;
any hit is a bug in the generator worth looking at.

Thresholds: keep `MAX_RATIO 0.50` / `MAX_RUN 5`, but the short-string rule
matters far more here than it does for verses — trivia facts and quiz questions
are one sentence. `SHORT_N 8` / `MAX_RATIO_SHORT 0.34` / `MAX_RUN_SHORT 3`
already handles it. Anything under `MIN_N 4` expressive words cannot be scored
at all and needs a written disposition in `reviewed.json`, exactly as the
scripture side does. **Do not let the review bucket become a silent pass** —
that property is the main thing `legal_own.py` gets right, so preserve it.

---

## 3. Order of work — and a hard dependency

**The generator tier is BLOCKED until the Upanishads, Ramayana and Mahabharata
work lands in `gyan.sqlite`.** This is a deliberate decision by the project
owner, not a scheduling accident. Do not start it early.

Why: `knowledge_quiz`, `trivia_facts` and `clue_riddles` all read the same
tables. Generated today they would draw almost entirely on entity/relation rows,
which yields flat, repetitive questions — "X is the son of Y" four thousand
times over. The epic work is what puts *narrative* facts into the corpus: who
did what to whom, in what order, at which turning point. Those make questions
worth answering. Generating now would also mean regenerating later against the
better material, which is strictly more work.

### Do now — nothing downstream depends on the epics

1. **mantras / aartis / chalisas / daily_quotes** (~250 strings) — smallest,
   proves the pipeline end to end.
2. **cities / scriptures / scripture_books + the 24 subtitles** — mechanical,
   no writing judgement needed.
3. **stories / kathas / puja_vidhi** (180 rows of prose) — **this is the long
   pole and it has no dependency at all.** It is where the waiting time goes.
   Do not sit idle waiting on the epics; this work is the schedule.
4. **Build `legal_gen.py`** once step 1 has shown you what the config needs.

### Do after the epics land

5. **trivia_facts** (565) — same dependency, same reason as the quiz.
6. **clue_riddles** (365).
7. **knowledge_quiz** (4,000) — get the 565 right before running the 4,000.
8. **quotes** (~800) — this one was already waiting on the Gita work regardless,
   since ~340 rows reuse those translations.

That defers ~4,930 rows, but they are the generator-driven ones — the cheap
half. The expensive half (prose) is unblocked and should be underway throughout.

### Prerequisite check before starting the generator tier

Confirm `gyan.sqlite` actually has the epic material before generating. Today it
holds 816 entities, 4,164 relations, 10,069 related_edges, 79 narrative_nodes
and 184 narrative_cast rows. The gate is `narrative_nodes` and `relations`
growing substantially with Ramayana and Mahabharata content, and `item_sources`
covering it. If those numbers have not moved, the epics have not landed and the
generator tier is still blocked.

Land each table as its own commit so a bad generator run reverts cleanly.

---

## 4. Definition of done

- Every authored row has a row in `item_sources` naming the PD source it came
  from. Generated content that cannot cite is not done.
- **Bilingual coverage is complete.** No reader-facing `_en` field has an empty
  `_hi` twin, in any table, including the columns you added and the ones that
  were English-only before you started (`items`, `vidhi`, `benefits`, and the
  tag vocabularies). The Hindi is full-length prose, not a stub.
- **stories / kathas / puja_vidhi hit their length targets** — ~3,500–5,000
  chars for stories, ~2,500–4,000 for kathas, a full paragraph per vidhi step,
  in **both** languages. Anything near the fixture's length has not been
  enriched and is not done.
- **The prose bar is met, and it is a gate like any other.** Spot-check every
  prose table against `bgc_2.json`: full paragraphs, everyday analogies, no
  untranslated Sanskrit, and lengths at or above the fixture's. A row that is
  licence-clean but thin, jargon-heavy, or encyclopaedic **fails** and gets
  rewritten. Passing `legal_gen.py` is necessary, not sufficient.
- `legal_gen.py check <table>` passes on all tables, with every unscoreable
  string carrying a written disposition.
- `validate.py` and `build.py` pass; `content_snapshot.json` regenerated.
- The app reads zero creative strings from `content.sqlite`. Verify by grepping
  the Dart layer — ~30 files currently touch these tables
  (`quiz_repository.dart`, `story_providers.dart`, `devotional_providers.dart`,
  `puja_providers.dart`, `riddles_providers.dart` and friends). Each needs
  repointing from `main.` to `gyan.`; `content_database.dart` already attaches
  both, so this is a table-prefix change, not a rearchitecture.
- Then, and only then, `assets/db/content.sqlite` is deleted and the ~38 MB
  leaves the APK. That deletion is the actual RG-01 gate.

---

## 5. Two things to get right

**Provenance beats wording.** The question at review is never "is this different
enough" — it is "where did this come from". A generated row citing Ganguli is
safe even if it happens to read like the fixture. A rewritten row with no
citation is not safe however different it reads. Build the citation in as you
generate; do not plan to add it afterwards.

**Sacred content has a second bar.** Legally clean and *correct* are different
tests. A generated quiz question with a wrong answer, or a katha with the wrong
deity, is worse than a licence problem. Generate only from facts that carry a
source id, and drop anything you cannot ground — for `quotes` that is explicitly
expected to cost ~200 rows.

---

## 6. Blocked: the 26 Ekadashi kathas

Searched 2026-09-14, no usable source found. **Do not write these from memory
and do not paraphrase the fixture.** The project owner has ruled out shipping a
reduced fallback for them, so they stay unwritten until a source appears.

The narratives (King Vaikhanasa, Prince Lumpaka, Malyavan and Pushpavati, Sage
Medhavi, the Fowler Krodhana) are **Padma Purana, Uttara Khanda**. What was
checked:

- **Padma Purana in English** — the only complete translation is Motilal
  Banarsidass, 1988-1990. In copyright. The unattributed archive.org upload
  `purana-padma-purana-eng` carries no translator or date and is almost
  certainly that same text; wisdomlib hosts it too. Not usable.
- **Manmatha Nath Dutt** (d. 1912, everything PD) translated Markandeya (1896),
  Bhagavata (1896), Vishnu (1894), Harivamsha (1897), Agni (1903) and Garuda
  (1908) — **but never the Padma Purana**, and none of the others carries the
  Ekadashi origin stories.
- **Garuda Purana**, Dutt 1908 — has "The Ekadashi Vratam" (ch. CXXV) and
  "Bhaimi Ekadashi and Dvadashi" (ch. CXXVII), but these are *observance rules*,
  not origin narratives. Useful for `vrat_vidhi_*`, useless for `body_*`.
- **Underhill and Gupte** give the date, the fast and the significance for many
  Ekadashis — the observance, never the story.

**Second search, 2026-09-14 — also negative.** The owner asked for a harder
look before accepting the block. Everything below was checked and ruled out:

- **Sacred Books of the Hindus** (Panini Office, Allahabad, 1911-1920s, 30 vols,
  all PD) — the most promising lead, since it is exactly the right era and
  carries Puranas. It has Garuda (vol. 9, Wood & Subrahmanyam 1911), Matsya
  (vol. 17, 1916-17) and Devi Bhagavatam (vol. 26). **No Padma Purana, no
  Skanda, no Brahma Vaivarta.**
- **Matsya Purana**, Taluqdar of Oudh 1916, chapters 1-128 — searched the text.
  Contains the Madana Dvadasi fast (ch. VII) in detail but **no Ekadashi at
  all**, named or otherwise.
- **Brahma Vaivarta Purana**, Rajendra Nath Sen, Panini Office 1920 — genuinely
  PD and in English, but the archive.org OCR is too corrupted to confirm
  Ekadashi content either way. If anyone wants one more attempt, a clean scan of
  Sen 1920 is the single remaining candidate worth the effort.
- **"Ekadashi Mahatmya", Jagaditechhu Press 1890** — right era, wrong language:
  the scan is **Marathi in Devanagari**, not English. A translator could work
  from it, but that is a different project.
- **Skanda Purana** — its Ekadashi chapter exists, but every English translation
  is modern (Motilal Banarsidass); wisdomlib hosts that same text.

Conclusion: no public-domain English source for the Ekadashi origin narratives
was found in two searches. Unless someone turns up a clean Sen 1920 scan that
proves to carry them, **the 26 Ekadashi rows are out of scope** and the owner
has ruled out shipping a reduced version.

**Consequence for the fixture:** `main.kathas` cannot be fully retired while
these 26 have no replacement. Either the fixture keeps shipping for them alone
— which does not clear RG-01 — or the app ships without them. That is a product
decision, not a content one, and it needs an explicit answer before release.

### What IS writable now

| Bucket | Rows | Sources |
|---|---|---|
| Epic/Puranic | **27** | Ganguli, Wilson, Dutt-Ramayana, Underhill, Gupte |
| Folk/local | **4** | Check individually; Underhill/Gupte where they reach |
| New, no fixture row | **44 candidates** | Underhill (95 festivals), Gupte (15) |
| Ekadashi | 26 | **BLOCKED** |

Start with the 27. They are the larger half, they have no blockers, and Vat
Savitri is already done as the reference.

---

## 7. Where the remaining kathas can and cannot come from

Checked 2026-09-14 against the actual texts, not from memory. The 57 fixture
kathas split three ways, and the split is about **what kind of text each story
lives in**, not about how hard anyone looked.

### Written: 12 rows, all from cited public-domain sources

Vat Savitri, Holika Dahan, Navratri, Govardhan, Maha Shivratri, Janmashtami,
Dussehra, Bhai Dooj, Ganesh Chaturthi, Karva Chauth, Hartalika Teej, Dhanteras.

These are **Puranic or epic** narratives, which is why they were writable:
Wilson's Vishnu Purana, Ganguli's Mahabharata and Dutt's Ramayana all carry
them, and Underhill and Gupte supply the observance. 41,398 chars EN and 37,124
HI, averaging 3.5x the fixture rows they retire.

### Blocked: 26 Ekadashi rows — Padma Purana, no PD English

See section 6. Two searches, both negative.

### Blocked: 19 rows — folk vrat kathas, not in any PD text

This is a **different** blocker from the Ekadashi one and worth understanding
separately, because no amount of searching Puranas will fix it.

Sakat Chauth, Ahoi Ashtami, the Diwali Sahukar's-daughter katha, Kajli Teej,
Santoshi Maa, Satyanarayan, Somvati Amavasya, Purnima, Sawan Somvar, Solah
Somvar, Vaibhav Lakshmi, Pradosh, and the seven weekday vrats.

What was actually checked:

- **Underhill, The Hindu Religious Year (1921)** — full text searched. Has
  Somvati Amavasya as a line ("the new moon falling on a Monday, is auspicious
  for almsgiving") and the planetary character of the weekdays. **Absent:**
  Sakat Chauth, Ahoi Ashtami, Satyanarayan, Solah Somvar, Santoshi Mata, Kajli
  Teej, Vaibhav Lakshmi. The book is organised around solar, lunar and planetary
  festivals, not around women's devotional vrats.
- **Gupte, Hindu Holidays and Ceremonials (1919)** — full text searched. Names
  Sankashti Chaturthi, Satya Narayan and Solah Somvar, but as **ritual
  description only** — no narrative. Its own introduction files them as
  "women's vratas" and describes procedure rather than story. **Absent:** Sakat
  Chauth, Ahoi Ashtami, Kajli Teej, the weekday narratives, the Sahukar katha.

**Why:** these are *oral folk* vrat kathas. They are told aloud by women at the
observance and were largely written down in twentieth-century Hindi pamphlet
literature — the Gita Press and Lakshmi Prakashan booklets — all of which is
modern and in copyright. Santoshi Maa is the clearest case: the observance
spread nationally after a 1975 film. There is no pre-1929 English source
because these did not enter English-language scholarship at all.

**So the honest position:** 12 of 57 are done. The other 45 are blocked for two
different reasons, neither of which more searching will solve. What would
unblock them is a **different kind of source**, and that is a decision for the
project owner, not a research problem:

1. **A Sanskrit or Hindi PD source plus our own translation.** The 1890
   Marathi *Ekadashi Mahatmya* scan is real and public domain; so are Devanagari
   vrat-katha collections of that era. Translating from them is legitimate and
   is how the Gita work is already being done — but it is a translation project,
   not a retelling one.
2. **Author them as our own tellings of oral tradition**, citing the tradition
   rather than a text. Defensible for genuinely oral material — nobody owns a
   folk tale — but it cannot be distinctness-checked against a source, so it
   needs a different review standard.
3. **Ship 12 and drop the rest**, which leaves `content.sqlite` undeletable
   unless the app drops those entries too.

Do not quietly pick one. Each has a different legal and editorial shape.
