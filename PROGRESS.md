# DivyaVaani — Progress Checklist

_Last updated: 2026-07-08_

## 🆕 2026-07-08 build — Phases 1–4 remaining features shipped
Added a **SharedPreferences user-state layer** (`lib/core/user/`): streak+points, japa, habits,
bookmarks, visited temples. New features, all `flutter analyze` clean + tests pass:
- **Phase 1:** Bookmarks (🔖 toggle on aarti/chalisa/mantra/story readers → Bookmarks screen);
  rich **Home dashboard** (real streak+points header, Panchang teaser card, sadhana quick-row).
  _Audio deferred_ — no bundled recordings and `mantras.audio_url` is empty (licensing, per plan).
- **Phase 2:** **Riddles** game (365 clue riddles, progressive reveal + scoring), **Japa** counter
  (mala 108 + haptics + lifetime totals), **guided Breathing** (3 pranayama patterns, animated orb),
  **Habits** (daily sadhana checklist). Real **streak + punya points** wired app-wide.
  _Local notifications deferred_ — needs `flutter_local_notifications` dep + platform config.
- **Phase 3 (panchang polish):** **Amanta/Purnimanta** month toggle, **named Ekadashis** (24),
  **Abhijit-void on Wednesday**. Fixed **calendar scroll lag** (memoized `monthFestivals`).
- **Phase 4:** **Temple Directory** (187, search + tag filters + visited toggle + detail),
  **Puja Vidhi** (23, steps/samagri/mantra/benefits), **Mandir** virtual puja (offer flower/diya/
  bhog/bell), first-run **Onboarding**. _Home-screen widgets + app-icon art deferred_ (native/art work).
- Also fixed: aarti/chalisa/katha/mantra lyrics had literal `\n` instead of real line breaks (DB fix)
  + bumped `assetVersion` 0.4.1 so devices re-copy the corrected DB.

---

_Prior baseline (2026-07-06):_

Tracks what's built vs. pending. See `PLAN.md` for the full plan and `reference/DESIGN-TOKENS.md`
for the design system.

---

## ✅ Research & Planning
- [x] Reverse-engineered Ishvarvaani — confirmed **offline, no backend**; mapped content DB, astrology approach, full feature list
- [x] Extracted exact **design system** (colors, fonts, shapes) from the live CSS
- [x] Downloaded & inspected **all 18 app images** + app icon
- [x] Wrote the full **build plan** → `PLAN.md`
- [x] Saved deliverables into repo → `reference/` (plan, tokens, 18 images, real content DB)

## ✅ Design (approved)
- [x] Live **HTML design-system mockup** → `design/design-system.html` (published as Artifact)
- [x] Palette, typography, stitched-card kit, 9 color-coded category tiles, 2 phone screens, light + dark

## ✅ Phase 0 — Flutter scaffold
- [x] Flutter project created (`divyavaani`, bundle id `com.sumerudigital.divyavaani`, Android + iOS)
- [x] Bundled **4 offline fonts** (Eczar, Ramaraja, Inter, Noto Sans Devanagari) → `assets/fonts/`
- [x] **Starter content DB** with public-domain Gita verses → `assets/db/content.sqlite`
- [x] **Theme system** — color tokens, light + dark `ThemeData`, `CategoryColors` extension
- [x] **EN/HI localization** (generated `L10n`, Hindi renders)
- [x] **Riverpod** state + **go_router** routing (Home + 9 category routes)
- [x] **Read-only SQLite loader** (asset → device copy → open read-only)
- [x] Reusable widgets: **StitchedCard**, **CategoryTile**, **DailyQuoteCard**
- [x] **Home screen** — verse-of-the-day + streak chip + 9-tile grid + EN/हिं toggle
- [x] Placeholder "Coming soon" screens for each category

## ✅ Verification
- [x] `flutter analyze` → **No issues found**
- [x] `flutter test` → **passing**
- [ ] **Run visually** — ⏸️ deferred (no Android emulator/device installed on this machine; iOS needs a Mac)

---

## 📱 Real app reference (from the native Android APK)
Pulled `com.ishvarvaani` APK from device (`reference/ishvarvaani-apk/`). It's a **React Native** app —
fuller than the website. Key references now captured:
- **UI screenshots** → `reference/ishvarvaani-screens/` (Home, Panchang, Astrology, Temple Directory,
  Puja Vidhi, virtual Mandir). Documented in `reference/UI-REFERENCE.md`.
- **48 app images** → `reference/ishvarvaani-app-images/` (deities, emotions, puja items, badges, widgets).
- **Native content DB** `assets/custom/ishvarvaani.sqlite` (42 MB) →
  scriptures **27,890 verses** · quiz 4000 · stories 100 · trivia 565 · clues 365 · quotes 999 ·
  temples **187** · puja_vidhi **23** · mantras 36. (Row = JSON `data` blob.)
- **App structure:** 5-tab nav (Home · Mandir · Astrology · Yatra · Profile). Extra features beyond website:
  **virtual Mandir puja**, **Habits**, **Japa**, full **Panchang** detail, home-screen **widgets**.

### Revised feature targets (match the native app)
- Home dashboard: daily quote + panchang card + Engage&Learn (Quiz/Japa) + scriptures + devotional + stories
- **Panchang** (Tithi/Nakshatra/Yoga/Karana + sun/moon times) — spec captured, computed via Lahiri ayanamsa
- Astrology: Kundli + Kundli Milan (Ashtakoot 36-point) — Lahiri ayanamsa
- Yatra: Temple Directory (187) with filters + visited toggle
- Mandir: interactive virtual puja (Flower/Bhog/Diya/Deity)
- Puja Vidhi (23), Habits, Japa, home-screen widgets

## ⚠️ PRE-SHIP GATE — swap dev-fixture data before store submission
The bundled `assets/db/content.sqlite` currently contains **Ishvarvaani's extracted content**
(dev fixture, to build/test UI at full scale). This is **their copyrighted content** and **MUST NOT
be shipped**. Before any Play Store / App Store submission, regenerate `content.sqlite` from our own
`content/` pipeline (public-domain sources + our generated-and-verified data). Tracked below.

Dev-fixture data now loaded into `assets/db/content.sqlite` (**35 MB** — includes the native app's richer data):
**scripture_sections 27,890** (Gita 701 + Upanishads 7,054 + Valmiki Ramayana 20,135; sanskrit+translit+EN+HI+commentary)
· scripture_books 130 · stories 100 · temples 187 · puja_vidhi 23 · knowledge_quiz 4000 · clue_riddles 365 ·
trivia_facts 565 · quotes 1000 · mantras 36 · aartis 18 · chalisas 10 · cities 4276.
The DB loader (`content_database.dart`) has a **version marker** (`assetVersion`) so on-device copies refresh
when the bundled DB changes — bump it on every rebuild. (Astrology is computed, not data — Lahiri ayanamsa.)

## 🚧 Phase 1 — Content core (in progress)
- [x] Scriptures list → chapter → **section reader** (Devanagari + transliteration + translation, EN/हिं, A-/A+ font-size) — from DB, analyze clean, tests pass
- [x] Reusable `AsyncView` + scripture repository/providers
- [ ] **5-tab bottom-nav shell** (Home · Mandir · Astrology · Yatra · Profile) — match native app
- [ ] Home dashboard sections (quote card + panchang card + Engage&Learn + scriptures + devotional + stories)
- [x] Devotional readers: **Aartis · Chalisas · Mantras** (our card/reader UI, deity accents, **deity-filter chips + search + preview**, EN/हिं) — analyze clean
- [x] Scriptures upgraded: **real chapter names + descriptions** (Gita 18, Ramayana 6 kandas, Upanishad names), correct order, **bilingual commentary** shown in reader
- [x] **Stories** by emotion (100 stories, colour-coded emotion chips + reader) — analyze clean
- [x] **5-tab bottom-nav shell** (Home · Read · Play · Jyotish · You) via StatefulShellRoute + hub screens + Profile (language/theme)
- [ ] Audio playback (`just_audio`) · Bookmarks (writable user DB)

## ✅ Phase 3 — Panchang (done, verified)
- [x] **Pure-Dart astronomy engine** (Schlyter sun/moon + Lahiri ayanamsa) — no native deps, no API
- [x] Panchang screen: Tithi/Nakshatra/Yoga/Karana (+ transition times) · month/paksha/vara · sunrise/sunset/moonrise/moonset · date picker
- [x] **Verified against the real app** on 2 dates (Jul 6 & Sep 10 2026): names identical, times within 2–3 min
- [x] **Muhurats** — Auspicious (Abhijit, Brahma) + Inauspicious (Rahu Kaal, Yamaganda, Gulika) as two sections
- [x] **GPS location** via `geolocator` (falls back to New Delhi); shows live coords
- [x] **Full Calendar** — continuous **vertical scroll** of months, festivals as small text in each day cell,
      today circled, tap-a-date → panchang. Kshaya-tithi handling.
- [x] **Purnimanta lunar month** (proper new-moon calc, North-Indian; Savan starts ~Jul 30) — replaces heuristic
- [x] **Named festivals** (Holi, Raksha Bandhan, Janmashtami, Ganesh Chaturthi, Dussehra, Diwali, Dhanteras,
      Karva Chauth, Maha Shivratri, Rath Yatra, Guru Purnima…) — verified on 2026 dates via tests
- [x] Reverse-engineered their engine: **mhah-panchang (Meeus) + Lahiri**; astrology data documented below
- [ ] Amanta option toggle · specific Ekadashi names · Abhijit-void handling

## 🔭 Phase 3b — Astrology / Kundli (documented, next to build)
Their Kundli shows (captured in `reference/ishvarvaani-screens/kundli_*.png`):
- **Chart**: North/South Indian diagram, Rashi D1 + Navamsa D9, Lagna, Moon Sign, Nakshatra+Pada
- **Planetary Positions**: 9 grahas — sign + degree°′″ + house + nakshatra + retrograde; Ayanamsa (Lahiri)
- **Dasha**: Vimshottari Maha→Antar→Pratyantar with dates + readings
- **Yogas & Doshas**: Raja Yoga etc. + Mangal Dosha (Manglik) with LOW/MED/HIGH severity
- **Milan**: Ashtakoot 36-guna (8 kootas) + Mangal matching
- [ ] Build: 9-planet Meeus engine, houses/lagna, D9, Vimshottari, yoga/dosha detection, chart-diagram UI

## 🚧 Phase 2 — Engagement (in progress)
- [x] **Quiz game** — hub (counts) + Knowledge Quiz play (4000 Qs, score) + Trivia browse — analyze clean
- [ ] Riddles mode (365 clue riddles) · personality/archetype test
- [ ] Daily streak + points · Japa counter · guided breathing · Habits · local notifications

## 🔭 Later phases
- [ ] **Phase 3 — Astrology & Panchang** (same as native app, Lahiri ayanamsa): Daily Panchang + Full
      Calendar (ref screens 09–11), Kundli, Milan (Ashtakoot 36-pt), 4276-city picker. Golden tests.
- [ ] **Phase 4 — Mandir & Yatra**: virtual puja (Flower/Bhog/Diya/Deity), Temple Directory (187),
      Puja Vidhi (23), home-screen widgets, app icon/splash/onboarding.
- [ ] **Phase 5 — Content swap + Launch**: replace dev-fixture with our own data (see PRE-SHIP GATE),
      store assets, privacy/terms, Play + App Store submission.

## 📦 Reference assets secured (dev reference only — see PRE-SHIP GATE)
- `reference/ishvarvaani-apk/` — pulled APK + native DB (`ishvarvaani.sqlite`, 42 MB): scriptures 27,890 ·
  quiz 4000 · stories 100 · trivia 565 · clues 365 · quotes 999 · temples 187 · puja_vidhi 23 · mantras 36
- `reference/ishvarvaani-screens/` — 11 real UI screenshots · `reference/UI-REFERENCE.md` — screen-by-screen
- `reference/ishvarvaani-app-images/` — 48 app illustrations
- `reference/ishvarvaani-extracted/` — website content JSON · `reference/astrology_lists.json` — nakshatras/tithis/yogas

---

## Repo layout
```
DivyaVaani/
├── PLAN.md                     full build plan (updated with native-app reference)
├── PROGRESS.md                 this file
├── lib/
│   ├── app/theme/              app_colors, category_colors, app_theme
│   ├── app/router/             app_router (go_router: scriptures + quiz wired)
│   ├── core/db/                content_database (read-only loader)
│   ├── core/models/            daily_quote
│   ├── core/providers/         app_providers (riverpod)
│   ├── features/home/          home_screen, category
│   ├── features/scriptures/    models, repository, providers, list/books/reader screens
│   ├── features/quiz/          models, repository, providers, hub/play/trivia screens
│   ├── features/placeholder/   placeholder_screen
│   ├── shared/widgets/         stitched_border, category_tile, daily_quote_card, async_view
│   └── l10n/                   app_localizations (EN/HI)
├── assets/
│   ├── fonts/                  Eczar, Ramaraja, Inter, NotoSansDevanagari
│   └── db/content.sqlite       DEV FIXTURE (Ishvarvaani data) — swap before ship
├── content/                    our-own content pipeline (schema.sql + data/*.jsonl + build)
├── design/design-system.html   approved visual identity
├── reference/                  PLAN copy, DESIGN-TOKENS, UI-REFERENCE, screens/, app-images/,
│                               apk/ (native DB), extracted/ (website content), astrology_lists
├── android/  ios/  test/
```
