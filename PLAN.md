# DivyaVaani — Build Plan (Flutter, Android + iOS)

## Context

You want to build **DivyaVaani**, a Hindu spirituality + personal-growth app modeled on
[ishvarvaani.com](https://ishvarvaani.com/) (App Store `id6760190882`, Play `com.ishvarvaani`,
tagline *"Light for the Inner Journey"*). I reverse-engineered the live Ishvarvaani build to
understand exactly what it is and how it works, so this plan targets a proven design rather than a guess.

**Key finding — Ishvarvaani is 100% offline, no backend.** I inspected its production JS bundle and
data files: zero API calls, no Firebase/Supabase, "no data collected." All content ships *inside* the
app; astrology is computed on-device. This is the single most important architectural decision and we
will copy it — it means **no server, no hosting bill, no auth, works on a plane, trivial privacy story.**

Working dir: `d:\Project\PlayStore\DivyaVaani` (currently empty — greenfield).

### How Ishvarvaani is built (evidence)
- **Frontend:** React + Vite SPA (they wrap it for native; we will build fresh in **Flutter** per your choice).
- **Quiz content:** a bundled SQLite file `content.sqlite` (2.4 MB) read client-side via `sql.js` (WASM).
  Tables: `knowledge_quiz` (**4,000** Qs), `clue_riddles` (**365**), `trivia_facts` (**565**), `meta`.
  Every row is **bilingual EN/HI** (`question_en`/`question_hi`, etc.).
- **Scriptures / aartis / mantras / kathas:** embedded JSON in the app bundle (parva/kanda → section model).
- **Astrology:** computed on-device with the `cosinekitty/astronomy` library — Kundli, Milan, Panchang.
  **No paid astrology API.**
- **User data (streaks, bookmarks, japa count, temple visits):** stored locally on device only.
- Theme color `#a73015` (saffron/terracotta); fonts Inter, Eczar, Ramaraja, Noto Sans Devanagari.

### Full feature inventory to reach near-parity
Scriptures (Mahabharata / Bhagavad Gita / Ramayana, browsable book→section) · Katha (stories by emotion) ·
Aartis / Chalisas / Mantras (with audio) · Quiz game "Pauranik Prasna" (knowledge quiz + riddles + trivia) ·
Spiritual-archetype personality test (Warrior/Sage/Devotee/Yogi/Guardian/Ascetic…) ·
Astrology: Kundli (birth chart), Milan (compatibility), Panchang (Hindu calendar, location-based) ·
Temple directory + visit tracking · Japa counter · Guided breathing · Daily streak · Bookmarks ·
Puja Vidhi · Home-screen widgets (daily quote + panchang) · Bilingual EN/HI.

### Definitive reference: the native app (reverse-engineered in full)
We pulled the installed **Android APK** (`com.ishvarvaani`, a **React Native** app — the fuller product vs.
the website) and its native content DB. Complete UI screenshots and the design system are documented in
`reference/UI-REFERENCE.md` + `reference/ishvarvaani-screens/`; art in `reference/ishvarvaani-app-images/`.
**This is the target we build to.** Real app structure:

**5-tab bottom nav — Home · Mandir · Astrology · Yatra · Profile**
- **Home** (scroll): daily-quote card · Panchang card (→ Daily Panchang + Full Calendar) · Engage & Learn
  (Quiz, Japa) · Scriptures (Gita/Upanishads/Ramayana) · Spiritual Enlightenment (Mantras, Aartis) ·
  Puja Vidhi · Habits · Stories (by emotion) · header with EN/हिं toggle + streak + points.
- **Mandir**: interactive **virtual puja** — full-screen deity, offer Flower / Bhog / Diya, switch Deity.
- **Astrology (Jyotish)**: **Create Kundli** + **Kundli Milan** (Ashtakoot 36-point). Lahiri ayanamsa.
- **Yatra**: **Temple Directory** (187) — filters (Char Dham / Healing / Visited), Mark Visited, Map.
- **Profile**: settings, streak, bookmarks, japa history.
- Plus **Panchang** (Tithi/Nakshatra/Yoga/Karana + sun/moon + festivals calendar) and home-screen **widgets**.

**Native content DB (`ishvarvaani.sqlite`, 42 MB) — real counts:** scriptures **27,890 verses** ·
quiz 4000 · stories 100 · trivia 565 · clues 365 · quotes 999 · temples 187 · puja_vidhi 23 · mantras 36.
(Rows store JSON `data` blobs.) Extracted to `reference/ishvarvaani-apk/` — dev reference only, not shipped.

---

## Recommended architecture (DivyaVaani in Flutter)

**Offline-first, single Dart codebase → Android + iOS (+ later web/desktop for free).**

| Concern | Choice | Package |
|---|---|---|
| Local content DB | SQLite, read-only asset bundled at build | `sqflite` + `sqflite_common_ffi` (or `drift` for typed queries) |
| Key–value / user state | streaks, bookmarks, japa, settings | `shared_preferences` (small) / `isar` or `drift` (structured, queryable) |
| Astrology engine | **Swiss Ephemeris** on-device (more accurate than cosinekitty; industry standard) | `sweph` (bundles ephemeris data) |
| Audio (aartis/mantras) | streaming + offline playback, background | `just_audio` + `audio_service` |
| Location (panchang/kundli) | lat/long + timezone for calculations | `geolocator` + `flutter_timezone` |
| Home-screen widgets | native iOS/Android widgets from Flutter | `home_widget` (+ small SwiftUI / Glance widget code) |
| Local notifications | daily quote, streak reminder | `flutter_local_notifications` |
| State management | app-wide state | `riverpod` (recommended) |
| Routing | declarative, deep-linkable | `go_router` |
| i18n EN/HI | UI strings | `flutter_localizations` + ARB files; content bilingual in DB |
| Fonts / Devanagari | Eczar, Inter, Noto Sans Devanagari | `google_fonts` or bundled TTFs |

**No backend for v1.** Optional later: a thin analytics/crash layer (Firebase Crashlytics is fine and
still lets you claim minimal data collection) and remote content updates via a downloadable `.sqlite`.

---

## UI / Design system (extracted from the live app + app icon)

You specifically want to match Ishvarvaani's look. I pulled its exact design tokens from the production
CSS and its app icon, so we can reproduce the aesthetic 1:1 in Flutter rather than approximating.

**Design language: "sacred handcrafted journal."** Warm, tactile, artisanal — textured cream/kraft-paper
backgrounds, hand-drawn terracotta strokes with dashed "stitched" outlines (the `iV` app icon is a
terracotta monogram on kraft paper with a white dashed outline), serif display type, gold accents,
per-category color-coded gradient cards, soft glassmorphism overlays. Built with Tailwind — we recreate it
as a Flutter `ThemeData`.

**Color tokens (exact):**
- Paper background: `#FDF8F5` (warm variants `#FCF8F4`, `#F8F2E8`, `#FDF0DC`, `#F7ECDC`)
- Primary terracotta: `#A73015` (theme color); dark `#6E1F10`; browns `#983A18` `#753F2C` `#5C3B28` (also text)
- Secondary gold: `#C0A062`; bright gold `#D4AF37`
- Accent "dharma" purple: `#5A2EA8` / `#8B6AC7`
- Accent "deity" rose/maroon: `#9C2950` / `#E07A98` (ring `#A54325`)
- Sacred green: `#25533F`
- Feedback: error `#FF6B6B`, warn `#FF9F43`, highlight `#FDE57E`; muted text `#9CA3AF`

**Category gradient cards (135°) — each content type is color-coded:**
`#A73015→#6E1F10` (terracotta) · `#D4AF37→#A54325` (gold) · `#8B6AC7→#5A2EA8` (purple/dharma) ·
`#E07A98→#9C2950` (rose/deity) · hero `#FDF8F5→#F7ECDC→#F1D9B9`.

**Typography:** Display/headings **Eczar** (serif) · accents/quotes **Ramaraja** (serif) · body/UI **Inter** ·
Hindi/Sanskrit **Noto Sans Devanagari** · counters use tabular figures. All available via `google_fonts`
(bundle Noto Devanagari for offline).

**Shape & elevation:** very rounded cards (radii **18–28px**), pill/full-round buttons, 14px chips, 28px
bottom sheets. Soft shadows for cards; dramatic `0 24px 36px rgba(0,0,0,.35)` for modals. Glassmorphism
overlays via backdrop blur (4/8/12px) over translucent cream (`#FFFEFA` at 80–95%). Selected states =
colored ring + 2px offset.

**Flutter mapping:** one `ColorScheme`/`ThemeData` from these tokens; a `CategoryColors` theme extension for
the gradient set; reusable `SacredCard`, `GradientCategoryCard`, `GlassSheet` widgets; a paper-texture
background asset. *After you approve, I can build a live HTML mockup (Artifact) of this design system —
palette, type scale, and sample cards — so you can see the recreated UI before we write Flutter code.*

### Images & illustration system (only ~16 shared assets — bounded, not thousands)

Ishvarvaani ships exactly **18 custom illustrations**, all in one "hand-drawn on textured paper" style,
and reuses them across screens (I downloaded and inspected every one). The bulk content (verses, quizzes,
aartis) is **text**, not images. What we need to produce:

- **Master wallpaper** — `wall.jpeg`: cream linen texture, thin gold corner frame, painted lotus in the
  corner. Base background behind most screens.
- **Logo / app icon** — terracotta "iV" doodle with dashed "stitched" outline (`logo.png`, `favicon`).
- **Deity avatars (6)** — circular cartoon portraits on gold mandala rings: Krishna, Ganesha, Shiva,
  Hanuman, Durga, Rama (add Lakshmi, Saraswati as you expand). Reused in aartis/mantras/deity pickers.
- **Scripture covers (4)** — flat editorial vector scenes: Gita (Krishna+Arjuna chariot), Mahabharata,
  Ramayana, Upanishads (add more scriptures as needed).
- **Themed screen backgrounds (4)** — quiz (`quiz_bg`), personality/pauranik (`pp_bg`, `pt_bg`),
  panchang (`pan.png`).
- **Decorative** — one large `mandala.svg` watermark + an ornamental horizontal divider (`hor.png`).

*(All 18 originals are downloaded to the scratchpad for style reference — do NOT ship them; produce our own
branded equivalents to avoid copyright issues.)*

**Production plan:** commission or AI-generate a consistent illustration set (fix one style prompt: "warm
flat editorial illustration, textured paper, terracotta+gold palette, hand-drawn dashed outlines"), then
hand-tune. Budget ~20–30 images total for near-parity. Bundle as app assets (webp/png + one SVG); no CDN.

### Screen-by-screen UI (maps to Flutter routes)

- **Home** — hero paper gradient + mandala watermark; daily quote card; streak chip; grid of color-coded
  category cards (Scriptures, Aartis, Mantras, Quiz, Astrology, Panchang, Katha, Personality, Temples).
- **Scriptures** list → **Scripture** (books/parvas/kandas list, cover image) → **Book** (sections) →
  **Section reader** (serif body, EN/HI toggle, bookmark, font-size control).
- **Aartis / Chalisas / Mantras** — deity-avatar grid → lyrics reader with audio player (play/pause,
  transliteration toggle) + japa counter for mantras.
- **Katha** — emotion filter chips → story cards → story reader.
- **Quiz / Pauranik Prasna** — themed `quiz_bg`; mode select (Knowledge Quiz / Riddles / Trivia); question
  card with 4 options, correct/incorrect states, score + progress.
- **Personality test** — `pp_bg`; question flow → result screen showing archetype (Warrior/Sage/Devotee/…)
  with illustration + description + share.
- **Astrology** hub → **Kundli** (birth-detail form → chart + planets/dasha), **Milan** (two births →
  Ashtakoota score), **Panchang** (date+location → Tithi/Nakshatra/Yoga/Karana/timings).
- **Temples** — directory list/map, deity filter, "visited" toggle with count.
- **Utility** — Breathing (animated timer), Bookmarks, Puja Vidhi, Settings (language, notifications),
  About / Privacy / Terms.
- **Home-screen widgets (native)** — daily quote card + daily panchang.

---

## Content data model (bundled `content.sqlite`)

Reuse Ishvarvaani's proven quiz schema and extend it for the rest. All text columns bilingual (`_en`/`_hi`).

```
knowledge_quiz(id, question_en, question_hi, options, correct_key, category, difficulty)   -- options = JSON array
clue_riddles(id, answer_en, answer_hi, clues_en, clues_hi)
trivia_facts(id, fact_en, fact_hi, source)
scriptures(id, name_en, name_hi, slug)                                   -- Gita, Ramayana, Mahabharata
scripture_books(id, scripture_id, title_en, title_hi, slug, order_no)    -- parva / kanda / chapter
scripture_sections(id, book_id, number, title_en, title_hi, body_en, body_hi, order_no)
aartis(id, title_en, title_hi, deity, lyrics_hi, lyrics_en, transliteration, audio_asset)
chalisas(id, title_en, title_hi, deity, lyrics_hi, transliteration, audio_asset)
mantras(id, title_en, title_hi, sanskrit, transliteration, meaning_en, meaning_hi, audio_asset, count)
stories(id, title_en, title_hi, emotion, deity, body_en, body_hi)        -- 100 stories tagged by emotion
quotes(id, en, hi, source_en, source_hi)                                 -- ~1000 daily wisdom quotes
personality_quizzes(id, title, questions_json, archetypes_json)          -- scoring → archetype
temples(id, name, deity, city, state, lat, lng, tags, description, category)  -- 187; Char Dham/Jyotirlinga/Shakti Peeth/Healing
puja_vidhi(id, title_en, title_hi, category, deity, occasion_en, occasion_hi, steps_en, steps_hi, items_en, items_hi)  -- 23
cities(id, name, state, country, lat, lon, tz, utc_offset)              -- 4276; astrology birth-place picker
meta(key, value)                                                         -- counts, version, content_hash
```
> Structure mirrors the native app's tables (studied in `reference/ishvarvaani-apk/.../ishvarvaani.sqlite`,
> which stores each row as a JSON `data` blob). We normalize into typed columns above.
User-generated state (bookmarks, streak, japa totals, temple-visited flags, quiz progress, saved kundlis)
lives in a **separate writable DB / `isar`** so the bundled content DB stays read-only and swappable on update.

---

## Content sourcing strategy (the biggest cost — plan carefully)

This is where most of the effort and legal risk lives. Approach per content type:

- **Scriptures — use public-domain translations, cite them.**
  - *Mahabharata:* Kisari Mohan Ganguli translation (public domain).
  - *Ramayana:* Ralph T. H. Griffith or Romesh C. Dutt (public domain).
  - *Bhagavad Gita:* Edwin Arnold / public-domain editions; Sanskrit shlokas are public domain.
  - Pipeline: fetch public-domain source → clean/segment into book→section → store EN + Hindi. For Hindi,
    prefer existing public-domain Hindi editions; machine-translate + human-review only as fallback.
  - **Do NOT scrape copyrighted modern translations** (e.g. Gita Press/ISKCON specific translations) without license.
- **Quiz / riddles / trivia (4,000 + 365 + 565 target).** Generate with an LLM in structured batches,
  grounded on the sourced scriptures, then **verify** (a second pass + spot human review) before import.
  This is automatable — I can build a generation+validation workflow that outputs rows in the DB schema above.
- **Aartis / Chalisas / Mantras.** Traditional devotional texts are largely public domain; transliteration
  and English meaning can be generated + reviewed. **Audio** is the tricky part: either license a reciter,
  commission recordings, or use TTS as a stopgap (note licensing on any audio you ship).
- **Kathas by emotion.** LLM-drafted from public-domain source stories + human review.
- **Temples.** Seed from public/open datasets (name, deity, city, coords); this is factual data.
- **Personality archetypes.** Original quiz design (questions + scoring map) — author from scratch.

**Deliverable:** a `content/` toolchain (scripts + LLM workflow) that produces `content.sqlite` reproducibly,
plus a `SOURCES.md` crediting every public-domain source (required for licensing hygiene and store review).

---

## Astrology engine (on-device, no API)

- Use **`sweph`** (Swiss Ephemeris). Compute from birth date/time + geo-coordinates + timezone:
  - **Kundli:** planetary longitudes → Rashi/Nakshatra, Lagna, 12 houses, dasha (Vimshottari).
  - **Milan:** Ashtakoota (Guna Milan, 36-point) compatibility from two kundlis.
  - **Panchang:** Tithi, Nakshatra, Yoga, Karana, Vara, sunrise/sunset, auspicious timings for a date+location.
- All pure computation → deterministic, offline, testable with known reference charts.
- **Note:** Swiss Ephemeris is GPL/commercial dual-licensed — confirm the license fits a closed-source app
  (may need the commercial license) **before** committing; alternative is the MIT `cosinekitty/astronomy`
  logic ported to Dart (less feature-rich for Vedic specifics).

---

## Proposed project structure

```
DivyaVaani/
  lib/
    main.dart
    app/            (router, theme, localization)
    core/           (db access, providers, models)
    features/
      scriptures/  katha/  devotional/  quiz/  personality/
      astrology/   panchang/  temples/  japa/  breathing/
      streak/  bookmarks/  home/  widgets/
    l10n/           (app_en.arb, app_hi.arb)
  assets/
    db/content.sqlite
    audio/  images/  fonts/
  content/          (sourcing + generation toolchain, not shipped)
  ios/ android/     (native widget extensions)
  test/             (astrology reference-chart tests, DB smoke tests)
```

---

## Phased roadmap

> Live status is tracked in `PROGRESS.md`. ✅ = done, 🚧 = in progress.

**✅ Phase 0 — Foundations:** Flutter project, theme (tokens + Devanagari fonts), `go_router`, `riverpod`,
EN/HI localization, read-only SQLite loader, Home screen with 9-tile grid. Analyze clean, tests pass.

**🚧 Phase 1 — Content core (nav shell = 5 tabs, match native app):**
- Bottom-nav shell: Home · Mandir · Astrology · Yatra · Profile.
- Home dashboard: daily-quote card ✅(data) · Panchang card · Engage&Learn · Scriptures · Mantras/Aartis ·
  Puja Vidhi · Habits · Stories.
- ✅ Scriptures reader (list → chapter → section, Devanagari + transliteration + translation, EN/हिं, font-size).
- Devotional readers: Aartis · Chalisas · Mantras (with audio via `just_audio`) · Stories (by emotion).
- Bookmarks (writable user DB).

**🚧 Phase 2 — Engagement:** ✅ Quiz game (Knowledge Quiz play + Trivia) — add Riddles; personality/
archetype test; daily streak + points; Japa counter; guided breathing; Habits; local notifications.

**Phase 3 — Astrology & Panchang (same as native app, Lahiri ayanamsa — nothing extra):**
- **Panchang**: Daily Panchang (Tithi/Nakshatra/Yoga/Karana + sunrise/sunset/moonrise/moonset, GPS + date
  picker) and **Full Calendar** (month grid, festival dots, Festivals & Vrats list). Ref: screens 09–11.
- **Kundli** (Lagna, Rashi, Nakshatra, planets, Vimshottari Dasha) + **Milan** (Ashtakoot 36-point + Mangal
  Dosha). Compute on-device (`sweph`/Swiss Ephemeris; native app used Time4J). 4276-city birth-place picker.
- Golden reference-chart tests.

**Phase 4 — Mandir, Yatra & polish:**
- **Mandir**: interactive virtual puja (deity + Flower/Bhog/Diya offerings).
- **Yatra**: Temple Directory (187, filters + visited toggle + map).
- Puja Vidhi (23). Home-screen **widgets** (daily quote + panchang). App icon, splash, onboarding.

**Phase 5 — Content swap + Launch:**
- **Replace all dev-fixture data with our own** (public-domain scriptures + generated-and-verified quiz/
  stories/aartis; original art). Regenerate `content.sqlite` from the `content/` pipeline. See PRE-SHIP GATE.
- Store assets, privacy/terms, Play Console + App Store Connect, internal testing, submit both stores.

### Content sourcing note (updated)
We now have the native app's full data as a **structure + quality benchmark** (dev fixture only). For the
shipped build we still produce our own: public-domain scriptures (Gita/Ramayana/Mahabharata/Upanishads),
LLM-generated-and-verified quiz/trivia/stories, public-domain devotional lyrics, temple data from Wikidata.
The 27,890-verse native scripture set shows the target depth; our pipeline fills it from public-domain sources.

---

## Store / launch checklist

- Google Play: developer account, app signing, data-safety form (declare "no data collected" if true),
  content rating (IARC), listing (icon/feature graphic/screenshots), internal→closed→production track.
- App Store: Apple Developer account ($99/yr), App Privacy nutrition label, screenshots per device size,
  TestFlight, review notes.
- Legal: **Privacy Policy + Terms** pages (Ishvarvaani has `/privacy`, `/terms`), `SOURCES.md` for content
  attribution, confirm Swiss Ephemeris + any audio licenses.
- Branding: finalize the name "DivyaVaani" availability on both stores + trademark/package id
  (`com.<you>.divyavaani`).

---

## Key risks / decisions to watch

1. **Content licensing** — biggest risk. Stick to public-domain sources + original/LLM-generated-and-reviewed
   content; document everything. Audio recordings are the hardest to license cleanly.
2. **Swiss Ephemeris license** — verify closed-source use before Phase 3 (may need commercial license or the
   MIT alternative).
3. **Quiz accuracy** — LLM-generated Q&A must be verified against scripture; a wrong "correct answer" erodes trust.
4. **Home-screen widgets** — the one place Flutter needs real native code (SwiftUI + Android Glance); budget time.
5. **App size** — bundled DB + audio + ephemeris can grow large; consider on-first-run download of audio packs.
6. **Store review** — religious content + astrology are allowed but need accurate metadata and a clean privacy story.

---

## Verification (how we'll know each phase works)

- **DB:** unit test opens `content.sqlite`, asserts row counts match `meta` (e.g. 4000 quiz rows), spot-checks
  a bilingual row renders in both EN and HI.
- **Astrology:** golden tests — compute Kundli/Panchang for known birth data and assert against published
  reference charts (tithi, nakshatra, lagna) within tolerance.
- **Content pipeline:** re-run the generator → identical `content.sqlite` hash (reproducible build).
- **End-to-end:** run on Android emulator + iOS simulator, walk each feature; verify audio plays in background,
  streak increments across a day boundary, widget updates, offline mode (airplane mode) fully functional.
- **Pre-launch:** Play internal testing + TestFlight build installs and passes a manual QA script on real devices.
