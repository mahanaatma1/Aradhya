# DivyaVaani — UI Reference (from the real Ishvarvaani Android app)

Captured from the installed native app (`com.ishvarvaani`) on device via adb.
Screenshots: `reference/ishvarvaani-screens/`. Extracted art: `reference/ishvarvaani-app-images/`.
These are **style/layout reference only** — DivyaVaani ships its own art + content.

> The native app is **React Native** (the website was React/Vite — a smaller build). The native app is
> the fuller product and the truer reference for our Flutter build.

## App shell — 5-tab bottom navigation
`Home` · `Mandir` · `Astrology` · `Yatra` · `Profile`
Active tab = terracotta/blue tint; line icons; warm cream background throughout.

## Screen-by-screen

### Home (`05`,`07`,`08_home_top`)
Vertical scroll of cards, top→bottom:
1. **Header bar** — logo (iV), `Eng / हिंदी` pill toggle, streak 🔥 count, points 🪵 count.
2. **Daily quote card** (gold) — big serif quote + source (e.g. "— Rig Veda"); refresh / bookmark / share icons.
3. **Panchang card** (cream) — date block (6 · Monday · July 2026), month chip (JYESHTHA), "Upcoming: <festival>",
   `TAP TO VIEW PANCHANG`. Expands into the full Panchang (see below).
4. **Engage & Learn** — image tiles: **Quiz** (green doodled `?`), **Japa** (orange mala), …
5. **Scriptures** — image cards: **Bhagavad Gita**, **Upanishads**, **Ramayana** (illustrated scene + blurb).
6. **Spiritual Enlightenment** — image cards: **Mantras** (meditation art), **Aartis** (Varanasi ghat art).
7. **Puja Vidhi** card (diya icon) — "Festivals • Vrat • Sanskaras • Step-by-step procedures".
8. **Habits** card (calendar) — "Small challenges, big change".
9. **Stories** — color-coded emotion tiles: **Anger** (red), **Joy** (yellow), Peace, Love… (matches emotion art).

### Panchang (`09`) — the layout to replicate
Card with date + month chip + upcoming festival, then a **2-column grid**:
- **Tithi** — current + next, each with "Until <time>" / "Rest of the day".
- **Nakshatra** — current + next with transition times.
- **Yoga** — current + next.
- **Karana** — up to three, with transition times.
Then a **sun/moon panel**: Sunrise · Sunset · Moonrise · Moonset (tabular times).
Footer links: `View Panchang` · `View Full Calendar`. All computed (Lahiri ayanamsa) — no data.

**View Panchang → Daily Panchang page (`10`):** brown app bar "Daily Panchang"; **date-picker chip**
(Mon Jul 06 2026, tap to change day); **GPS Location** with lat/long; a "MAIN ATTRIBUTES" card —
Hindu Month (Jyeshtha), Paksha (Krishna Paksha) + Vara (Somavara), then Tithi / Nakshatra / Yoga / Karana
each as "current — upto <time> ↓ next — Full Day/Next". Scrolls to more (sun/moon, muhurat).

**View Full Calendar → Hindu Panchang calendar (`11`):** app bar "Hindu Panchang" + `Go To` date jump;
big month/year header (JULY 2026); weekday row (Sun–Sat, brown bar); month grid with **today circled** and
**color-coded festival dots**; below, a **FESTIVALS & VRATS** list (numbered day badges → festival name,
e.g. 10 Yogini Ekadashi, 16 Jagannath Rath Yatra).

### Astrology / Jyotish (`02`)
Eyebrow "JYOTISH", title "Your Cosmic Story", subtitle "Birth chart · Dasha · Yogas · Doshas · Compatibility".
Two big color-coded cards:
- **Create Your Kundli** (gold) — "Build your Vedic chart from birth date, time & place" → `Begin Now`.
- **Compatibility Test / Kundli Milan** (pink) — "Ashtakoot Guna Milan — 36-point match" → `Match Pair`.
Footer: "All calculations use Lahiri ayanamsa (Vedic / sidereal)."

### Yatra / Temple Directory (`01`)
Header "Temple Directory · N temples across India". Search bar. Filter chips: `Char Dham`,
`Healing Temples`, `Visited`. **Color-coded temple cards** (by deity/type): name, deity subtitle,
location (📍 city, state), tag chips (`Jyotirlinga`, `Shakti Peeth`, `Healing`), `Map` + `View details`,
and a `Mark Visited` / `✓ Visited` toggle button. 187 temples in DB.

### Mandir — virtual puja (`04`)
Full-screen illustrated deity in an ornate mandap (curtains, marigold garlands, offerings). Bottom control
bar: **Flower · Bhog · Diya · Deity** — interactive offerings; top-right share + info; close (×) top-left.
(Immersive "do puja from your phone" experience.)

### Puja Vidhi (`03`)
Header "Puja Vidhi · 23 PUJAS". Search. Filter chips: `All`, `Festivals`, `Tithi Vrat`, `Special`.
**Color-coded numbered cards** (by category, e.g. `PITRU (ANCESTORS)`, `HANUMAN`): title (Pitru Paksha,
Sundarkand Path…), category label, occasion/timing blurb, chevron → step-by-step detail. 23 in DB.

## Design language observed (confirms our tokens)
Warm cream ground · terracotta headings (serif) · **per-item color-coding** (gold/green/pink/red/teal
pastel card fills) · large rounded cards · pill toggles & chips · line icons · bilingual EN/हिंदी toggle
in the header. Matches `reference/DESIGN-TOKENS.md` and our Flutter theme.

## Extracted art (`reference/ishvarvaani-app-images/`, 48 images)
Deities + portrait variants (Ganesha, Hanuman, Krishna, Durga, Lakshmi, Shiva, Ram, Saraswati, Kartikeya,
Ayyappa, Dattatreya, Meenakshi), emotion illustrations (anger, fear, joy, love, peace, faith), puja items
(bhog, ladoo, diya on/off, currency), badges (japa, quiz, streak), backgrounds (quote_bg, pan), logo,
and home-screen widget previews (japa, panchang, quotes).
