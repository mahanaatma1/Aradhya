# Aradhya — What to Test

A running manual-QA checklist, kept in step with `reference/FEATURE-BUILD-PLAN.md`.

**How to use it:** each phase gets a section that appears *when that phase's code lands*. Test the newest section first, then re-run the **Regression sweep** at the bottom — that's the part that catches damage to things that were already working.

Automated tests cover logic (astrology, panchang, folding, migrations). This file covers what only a human on a real device can see: layout, feel, and whether data survived.

---

## 0. Before you test anything

```bash
flutter analyze            # must be: No issues found!
flutter test               # see "Known failing" below
py -m content.tools.validate
py -m content.tools.selftest
```

**Known failing (not your bug):** `test/panchang_test.dart` → *"Festivals for July 2026 match reference dates"*. Expects `Ekadashi`, gets `Apara Ekadashi`. Pre-existing, tracked as **G16**, fixed in Phase 5. Everything else must pass.

**Deploy to the phone** (no emulator on this machine):

```bash
C:\Android\platform-tools\adb.exe devices     # confirm the device is listed
flutter run                                    # or: flutter build apk --debug
```

---

## Phase 0 — Substrate (landed)

Phase 0 is plumbing. Almost nothing here is *visible*, so the test is mostly **"nothing broke, and my data survived."**

### 0.1 The upgrade path — most important test in this phase

This is the one that touches real user data, and it only happens once per device. Get it wrong and it is unrecoverable.

1. Install the **previous** build (before Phase 0) — `git stash` your work, build, install.
2. In that old build, generate real data:
   - tap through **at least one full japa mala** (108 beads)
   - tick 2-3 **habits**
   - **bookmark** an aarti, a mantra, a story, and a **shloka**
   - mark 2 **temples** as visited
   - read a scripture chapter partway, then leave
3. Restore Phase 0 (`git stash pop`), rebuild, **install over the top — do not uninstall.**
4. Verify **every single item above is still there**:

| Check | Expected |
|---|---|
| Japa today + lifetime totals | Identical numbers to before the upgrade |
| Japa heatmap | Same days filled |
| Habits for today | Same ones ticked |
| Bookmarks list | All four present, same titles |
| Visited temples | Both still marked |
| Reading position | "Continue reading" resumes the same verse |

> Losing anything here is a **stop-everything** bug. The migration runs once and there is no backup.

5. **Crash-safety:** force-stop the app during first launch after upgrade (fast — the migration is quick). Reopen. Data must still be complete and not duplicated. Japa totals must not double.

### 0.2 App still launches and behaves

- [ ] Cold start reaches Home with no error screen
- [ ] All 5 tabs open: Home · Rashifal · Astrology · Yatra · You
- [ ] Kundli still generates, and matches what it produced before Phase 0 (**sweph only runs in the real app** — tests fall back to a lower-precision path, so this can only be checked on device)
- [ ] Panchang shows today correctly for your location
- [ ] Language toggle EN ⇄ हिं still works everywhere

### 0.3 Bookmarked shloka no longer crashes (**G2**)

The headline user-visible fix in this phase.

- [ ] Open a scripture → bookmark a verse
- [ ] Go to **You → Bookmarks** → tap that verse
- [ ] It **opens the reader**. Previously this hit GoRouter's *"no routes for location"* error page.
- [ ] Bookmarks migrated from the old build show but are **not tappable** — that is correct, they carry no stored route. New bookmarks made after the upgrade *are* tappable.

### 0.4 Verse of the day no longer repeats every 3 days (**G3**)

- [ ] Home verse card shows a verse
- [ ] Tap **Change** several times — you should see plenty of variety (the pool went from 3 → 1,003)
- [ ] Some verses show **Devanagari + transliteration**, most show English/Hindi + a source line. Both are expected — only 3 verses in the data have Sanskrit.
- [ ] Change the device date forward a few days → the default verse changes each day

### 0.5 Temple citations now visible (**G8**)

- [ ] Yatra → open any temple → source links appear (official `.gov.in` / `.nic.in` / tourism links listed first)
- [ ] Tapping a source opens a browser
- [ ] **Offline**: the temple page itself still renders fully; only the outbound link fails

### 0.6 Vrat Kathas are finally reachable (**G4**)

57 kathas shipped in the database from day one but had no screen — `/katha` rendered the `stories` table instead.

- [ ] Home → **Katha** → a **Stories / Vrat Katha** toggle appears at the top
- [ ] Switch to **Vrat Katha** → 57 kathas listed (Satyanarayan, Santoshi Mata, Ahoi, Ekadashi…)
- [ ] Deity chips appear: All · Vishnu · Shiva · Ganesha · … · **Other**
- [ ] Tapping a chip filters; tapping it again clears
- [ ] **Other** shows the rare deities that have no chip of their own — it must not be empty
- [ ] Open a katha → it reads correctly in both EN and हिं
- [ ] Arriving from a Home *emotion* tile (e.g. "stories about fear") shows **no** toggle — that is intentional
- [ ] Known limitation, not a bug: Vishnu's epithets (Damodara, Narayan, Purushottam, Vamana, Satyanarayan…) appear as separate entries rather than folding into Vishnu. Fixing that needs the cited alias table from Phase 2.

### 0.7 Speed (**G5** — 8 indexes added)

Compare against the old build if you can:

- [ ] Opening a long chapter (Gita, Ramayana) feels quicker
- [ ] Birth-place picker responds faster as you type
- [ ] App size **went down** slightly (36.65 MB vs 37.98 MB for the content DB)

### 0.8 Build gates (run on your machine, not the phone)

```bash
py -m content.tools.build            # dev build → succeeds
py -m content.tools.build --strict   # release build → MUST FAIL
```

- [ ] `--strict` aborts with *"55 placeholder asset(s) — release blocked (RG-03)"*.
      **This failing is correct.** It means a release build cannot be produced while the artwork is still borrowed from Ishvarvaani.

---

## Phase 1 — Search · Related rail · Gyan hub (not started)

Fill in as it lands. Planned checks:

- [ ] Search `krishna`, `कृष्ण`, `kṛṣṇa`, `krsna` → **all four return the same results**
- [ ] Search `mumbai` → finds **Navi Mumbai** (prefix-only search was the old bug, **G6**)
- [ ] Results span temples, verses, mantras, cities — tapping any result opens a real screen, never an error page
- [ ] Open Hanuman → **Related rail** shows the Chalisa, his temples, his mantras — and **nothing wrong**
- [ ] Repeat the related-rail check for **Shiva, Durga, Krishna** — these have the most shared epithets and are where bad matches will appear first (Risk 8)
- [ ] Hindi layout: run the whole app in हिं and check nothing overflows

---

## Phase 2 onward

Sections get added as each phase lands. See `reference/FEATURE-BUILD-PLAN.md` PART 6 for the full per-phase verification plan.

---

## Regression sweep — run after *every* phase

Quick pass over everything that already worked. Ten minutes, catches most breakage.

**Core journeys**
- [ ] Onboarding (fresh install): language → name → Ishta Devata
- [ ] Home renders every section without a gap or error tile
- [ ] Scriptures: list → chapters → reader; font size, TTS "Listen", bookmark
- [ ] Aarti / Chalisa / Mantra readers open; EN ⇄ हिं toggle works
- [ ] Quiz plays and scores; Riddles reveal clues; Trivia scrolls
- [ ] Japa: beads count, mala rolls over at 108, streak and heatmap update
- [ ] Breathing: full cycle including the hold phase
- [ ] Habits tick and persist across restart
- [ ] Kundli: create → chart, D1/D9, Dasha, Yogas, Life Areas
- [ ] Milan: two charts → 36-guna result
- [ ] Panchang: today + full calendar scroll
- [ ] Yatra: search, filters, temple detail, map link, visited toggle
- [ ] Puja Vidhi opens
- [ ] Rashifal: daily reading, Kamal spend on reveal
- [ ] Profile: streak, Punya, Kamal, bookmarks, language

**Cross-cutting**
- [ ] **Bilingual:** switch to हिं and walk every screen — no English left behind, no clipped Devanagari
- [ ] **Offline:** turn on airplane mode. Everything except map links and source links must work fully
- [ ] **Restart persistence:** force-stop and reopen — streak, japa, habits, bookmarks, kundli all intact
- [ ] **Home widgets** (Android): Panchang and Verse widgets still render and update

---

## How to report a bug

Include: **what you did → what you expected → what happened**, plus the screen, the language (EN/हिं), and whether you were online. If it involves data loss, say whether it was a fresh install or an upgrade — that distinction usually identifies the cause immediately.

```bash
adb logcat -s flutter          # app logs while reproducing
```
