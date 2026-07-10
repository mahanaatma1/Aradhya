# DivyaVaani — Design Tokens & Content Schema (extracted from Ishvarvaani)

> Reference only. Reverse-engineered from the live ishvarvaani.com build for the DivyaVaani rebuild.
> Produce our own branded illustrations; do not ship Ishvarvaani's original assets.

## Color palette

| Role | Hex |
|---|---|
| Paper background | `#FDF8F5` (variants `#FCF8F4` `#F8F2E8` `#FDF0DC` `#F7ECDC`) |
| Primary terracotta | `#A73015` (theme) · dark `#6E1F10` |
| Browns / text | `#983A18` `#753F2C` `#5C3B28` |
| Secondary gold | `#C0A062` · bright `#D4AF37` |
| Dharma purple | `#5A2EA8` / `#8B6AC7` |
| Deity rose/maroon | `#9C2950` / `#E07A98` · ring `#A54325` |
| Sacred green | `#25533F` |
| Error / warn / highlight | `#FF6B6B` / `#FF9F43` / `#FDE57E` |
| Muted text | `#9CA3AF` |

### Category gradients (135°)
- Terracotta: `#A73015 → #6E1F10`
- Gold: `#D4AF37 → #A54325`
- Purple/dharma: `#8B6AC7 → #5A2EA8`
- Rose/deity: `#E07A98 → #9C2950`
- Hero paper: `#FDF8F5 → #F7ECDC (60%) → #F1D9B9`

## Typography
- Display/headings: **Eczar** (serif)
- Accents/quotes: **Ramaraja** (serif)
- Body/UI: **Inter**
- Hindi/Sanskrit: **Noto Sans Devanagari**
- Counters: tabular figures

## Shape & elevation
- Radii: chips 14px · cards **18–28px** · buttons pill/full · sheets 28px
- Card shadow soft; modal `0 24px 36px rgba(0,0,0,.35)`
- Glassmorphism: backdrop blur 4/8/12px over translucent cream `#FFFEFA` @ 80–95%
- Selected: colored ring + 2px offset

## Image assets (18 total — see ./ishvarvaani-images/)
- Master wallpaper: `wall.jpeg` (linen + gold corner frame + lotus)
- Logo: `logo.png` (terracotta "iV" doodle, dashed stitched outline)
- Deity avatars (6): `pkrishna` `pganesha` `pshiva` `phanuman` `pdurga` `pram`
- Scripture covers (4): `bhagavadgita` `mahabharata` `ramayana` `upanishads`
- Themed backgrounds (4): `quiz_bg` `pp_bg` `pt_bg` `pan`
- Decorative: `mandala.svg` `hor.png`

## Content DB schema (ishvarvaani-content.sqlite — 2.4 MB, bilingual EN/HI)
```sql
CREATE TABLE knowledge_quiz (id INTEGER PRIMARY KEY, question_en TEXT NOT NULL,
    question_hi TEXT, options TEXT NOT NULL, correct_key TEXT NOT NULL);   -- 4000 rows
CREATE TABLE clue_riddles  (id INTEGER PRIMARY KEY, answer TEXT NOT NULL,
    clues_en TEXT NOT NULL, clues_hi TEXT);                                -- 365 rows
CREATE TABLE trivia_facts  (id INTEGER PRIMARY KEY, fact_en TEXT NOT NULL,
    fact_hi TEXT);                                                         -- 565 rows
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
-- meta: quiz_count=4000, clue_count=365, trivia_count=565
```
Scriptures/aartis/mantras/kathas are NOT in this DB — they were bundled as JSON in the JS.
For DivyaVaani we extend this schema (see PLAN.md → Content data model).

## Tech signals observed
- React + Vite SPA; Tailwind CSS
- `sql.js` (SQLite WASM) for the quiz DB
- `cosinekitty/astronomy` for astrology (Kundli/Milan/Panchang) — all on-device
- No backend, no API calls, no analytics hosts. "No data collected."
- Native apps: iOS `id6760190882` (dev Aayushi Rawat, Lifestyle), Android `com.ishvarvaani`
- Instagram: @ishvar_vaani_app
