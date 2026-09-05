# Aradhya — website

The public knowledge layer for the Aradhya mobile app: a searchable, linkable
surface for the same curated content the app carries offline.

This is **not** a marketing page with a download button. The app is the full
offline experience; the website is how someone searching "who is Bhishma" or
"what is Ekadashi" finds that content at all, reads a real answer, and follows
the links outward. The download CTA exists, but it is the exit, not the point.

```bash
npm install
npm run dev      # http://localhost:5180
npm run build    # vite build + sitemap → dist/
npm run preview  # serve dist/
npm run content  # regenerate src/data/mockContent.js from content/data/
npm run sitemap  # regenerate dist/sitemap.xml on its own
```

Stack: Vite 6, React 18, React Router 6, Tailwind 3, `lucide-react`. Nothing
else — no UI kit, no animation library, no state manager, no analytics.

## Content comes from the app's pipeline, not from here

There is one curated knowledge base in this repo and the website reuses it
rather than keeping a second copy.

```
content/data/*.jsonl                     ← curated source of truth
   ├── py -m content.tools.build   → assets/db/gyan.sqlite.gz   (the app)
   └── py scripts/extract-content.py → src/data/mockContent.js  (this site)
```

`src/data/mockContent.js` is **generated — do not edit it by hand.** Rerun
`npm run content` after the JSONL changes. The extractor emits only rows whose
English verification status is `verified`, and carries each row's primary
citation across, so anything the site displays can be attributed.

Current export: 174 entities · 154 relations · 79 scenes · 42 arcs ·
10 journeys · 58 festivals · 24 quiz questions · 12 trivia facts · 6 riddles.

Deliberately, the website does **not** read the app's SQLite database. The app
must stay fully offline, so coupling the web build to a shipped binary asset
would constrain the thing that matters most about it. Same sources, two
independently built artefacts.

## Layout

```
src/
  config/      appConfig.js  — every outward-facing constant (see below)
               routes.js     — route table + the static sitemap entries
               taxonomy.js   — facets, category gradients, level labels
  services/    contentService.js  — async accessors over the content chunk
               searchService.js   — the local index and scoring
               appLinks.js        — the only place deep links are assembled
  hooks/       useAsync, useSeo, useReveal, …
  components/  art/ cards/ home/ layout/ search/ graph/ ui/
  pages/       one file per route; Epic.jsx serves /ramayana and /mahabharata
```

Two seams are worth knowing about, because both were built to be replaced:

**Search.** `searchContent(query, options)` in `services/searchService.js` is
the only entry point the UI calls, and it is async. Pointing the site at a real
search API is a change to that one function — the callers already await it, and
the return shape (`{ query, total, results, groups, facetCounts }`) is
documented at the top of the file. `appConfig.flags.liveSearch` gates the
switch-over.

**Content.** `contentService.loadContent()` dynamic-imports the data chunk, so
the 220 kB content bundle is never in the initial payload; `prefetchContent()`
in `main.jsx` warms it right after mount. Every accessor is async for the same
reason — swapping the local import for `fetch` touches one file.

## Configuration

`src/config/appConfig.js` holds every store URL, deep link, social handle, the
canonical origin and the privacy copy. Components read from it; nothing is
hardcoded. **The store URLs and the iOS app ID are placeholders** — search for
`TODO(launch)` in that file. `stores.*.available` is `false`, which is what the
CTA reads to decide whether to present a live link or a "coming soon" state.

Deep links are assembled only in `services/appLinks.js`, from the route
templates in `appConfig.deepLink.routes`. Do not build a platform-specific link
anywhere else.

## Ground rules this code follows

These are constraints on the content, not style preferences. They are why
several components look more cautious than they need to.

- **No fabricated scripture.** No component contains verse text. Where a
  quotation would go, the curated row supplies it with its citation attached, or
  nothing renders. `ScriptureCard` describes a collection and says plainly that
  the full text is in the app.
- **No invented temple facts.** `TempleCard` renders only the fields present on
  the record — location, deity and image are all optional — and its artwork is a
  stylised silhouette that never claims to be a photograph of the named place.
  When the app's structured temple directory reaches the web, the cards fill out
  on their own.
- **Precise privacy language.** `appConfig.privacy` keeps the app's posture and
  the website's posture as two separate sentences, because they are different
  surfaces. The site stores one browser preference (light/dark) and that is what
  it says. Neither claim should be upgraded without checking the shipped build.
- **No analytics.** There is no tracking script, no pixel, no beacon.
- **No large generated imagery.** All artwork is SVG drawn in code — the
  wordmark, the glyphs, the mandala, the temple silhouettes and the knowledge
  graph. `public/` holds four small text files and no raster assets.

## Known limitations — read before launch

**This is a client-rendered SPA, and that is the biggest gap.** `npm run build`
produces one `index.html` shell; every route resolves in the browser. Two
consequences:

1. A crawler that does not execute JavaScript follows all 254 sitemap URLs and
   finds the same empty shell each time. Google renders, so it will index, but
   for a site whose entire purpose is being found in search this should not rely
   on that. **Add a prerender/SSG step** — `vite-plugin-prerender`, or a small
   Puppeteer pass over the sitemap at build time, writing real HTML per route.
   The route list and the content set are already enumerable
   (`staticSitemapEntries` + `mockContent`), which is the hard part.
2. `useSeo` sets titles, descriptions and canonicals at runtime. Social
   scrapers (Slack, WhatsApp, Twitter, LinkedIn) generally do not run JS, so
   they will read whatever static tags are in `index.html` and ignore the
   per-page ones. Prerendering fixes this too.

**`public/og-image.svg` needs a PNG.** Most scrapers will not render an SVG
`og:image`. Rasterise it to ~1200×630 PNG and point the static tags in
`index.html` at that file. The SVG stays as the source.

**Other open items:**

- No tests. There is no test runner configured.
- No error boundary — a throw in a lazy page takes the shell with it.
- React Router logs two v7 future-flag warnings in dev; harmless, silenced by
  passing `future: { v7_startTransition: true, v7_relativeSplatPath: true }`.
- `siteUrl` is `https://aradhya.app`, which the sitemap, canonicals and OG tags
  all derive from. Change it there if the domain changes.

## Responsive behaviour worth knowing

Home-page preview sections use `components/ui/CardRail.jsx`: a swipeable
snap-scrolling rail on phones that becomes an ordinary grid at a configurable
breakpoint (`stop`). It is one `<ul>` at every width, so crawlers and screen
readers see the same list regardless of viewport.

One trade-off is baked in: the scroll reveal wraps the whole rail rather than
each card. `useReveal` observes against the viewport, so a card parked off to
the right of a rail is not intersecting anything — per-card reveals would leave
rails looking half-empty until swiped. The group reveals as one unit and the
per-card stagger is the price.

Listing pages (`/explore`, `/festivals`, `/journeys`, …) stay vertical grids on
purpose. 174 entities is not something to push along a horizontal strip.
