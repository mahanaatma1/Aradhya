# Aradhya — website

The public knowledge layer for the Aradhya mobile app: a searchable, linkable
surface for the same curated content the app carries offline.

This is **not** a marketing page with a download button. The app is the full
offline experience; the website is how someone searching "who is Bhishma" or
"what is Ekadashi" finds that content at all, reads a real answer, and follows
the links outward. The download CTA exists, but it is the exit, not the point.

```bash
npm install
npm run dev        # http://localhost:5180
npm run build      # vite build + ssr bundle + sitemap + prerender → dist/
npm run serve      # http://localhost:5183 — serve dist/ the way a static host would
npm test           # vitest, once
npm run test:watch # vitest, watching
npm run content    # regenerate src/data/mockContent.js from content/data/
npm run sitemap    # regenerate dist/sitemap.xml on its own
npm run prerender  # rewrite per-route HTML into an existing dist/
npm run build:debug# the same build with development React, for hydration errors
npm run og         # rasterise public/og-image.svg → og-image.png (needs Chrome)
```

**Use `npm run serve`, not `npm run preview`, to check a build.** `vite preview`
rewrites every unmatched URL to `dist/index.html` *before* looking for a file on
disk, so it serves the home page at `/explore/arjuna` and hides everything the
prerender did — including hydration mismatches, which then appear as
unreproducible React errors. `scripts/serve-dist.mjs` resolves `/explore/arjuna`
to `dist/explore/arjuna/index.html` and falls back to `dist/404.html` with a real
404 status, which is what GitHub Pages, Netlify and Cloudflare Pages do.

Stack: Vite 6, React 18, React Router 6, Tailwind 3, `lucide-react`. Nothing
else — no UI kit, no animation library, no state manager, no analytics. Vitest,
Testing Library and jsdom are dev-only.

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
               seo.js        — page titles/descriptions + tag computation
               epics.js      — the two epics, shared by the page and the build
               taxonomy.js   — facets, category gradients, level labels
  services/    contentService.js  — async accessors over the content chunk
               searchService.js   — the local index and scoring
               preload.js         — per-page data inlined at build time
               appLinks.js        — the only place deep links are assembled
  hooks/       useAsync, useSeo, useReveal, …
  components/  art/ cards/ home/ layout/ search/ graph/ ui/
  pages/       one file per route; Epic.jsx serves /ramayana and /mahabharata
  entry-server.jsx  — renders one route to HTML for the prerender
  test/setup.js     — DOM matchers + unmount, loaded before every test file
scripts/       generate-sitemap.mjs · prerender.mjs · serve-dist.mjs
               lib/head.mjs — the prerender's HTML shaping, on its own so it
               can be tested (prerender.mjs runs a build on import)
               make-og-image.mjs · extract-content.py
```

Tests sit beside what they test (`seo.test.js` next to `seo.js`). 143 of them,
covering metadata computation, search, the content accessors, the preload store,
`useAsync`, and the prerender's HTML shaping.

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

## Page metadata has one definition

`src/config/seo.js` holds every page's title and description, plus `buildMeta()`,
which turns them into the full tag set (title, description, robots, canonical,
Open Graph, Twitter). Two callers use it:

- `hooks/useSeo.js` applies the result to `document.head` on navigation.
- `scripts/prerender.mjs` writes the same tags into static HTML at build time.

So a page's copy is edited in exactly one place, and a prerendered `<title>`
cannot disagree with the one the app sets a moment later. `index.html`'s own tags
are the home page's, kept in sync by hand — the comments there say so.

Content pages (`/explore/:slug`) are absent from `PAGE_META` on purpose: their
metadata is read off the record through `getRecord()`, so it cannot contradict
what the page renders. `/search` and `/404` are absent because neither is
indexed.

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
  graph. The one raster file in `public/` is `og-image.png`, which exists only
  because scrapers will not render an SVG `og:image`; it is generated from
  `og-image.svg` by `npm run og`, so the SVG remains the source.

## What the build produces

`npm run build` runs four steps, and the last three matter as much as the first:

1. `vite build` — the bundle and one `dist/index.html` shell.
2. `vite build --ssr` — `dist-ssr/entry-server.js`, the renderer step 4 calls.
   It exists because Node cannot import JSX.
3. `generate-sitemap.mjs` — `dist/sitemap.xml`, 254 URLs (12 static + 242
   content), enumerated from `staticSitemapEntries` and the content set so a URL
   cannot be listed unless the site can render it.
4. `prerender.mjs` — one HTML file per sitemap URL (`dist/about/index.html`,
   `dist/explore/hanuman/index.html`, …), each with its own title, description,
   canonical, Open Graph, Twitter card and JSON-LD baked in, **plus the page's
   rendered body and the data it was rendered from**, plus `dist/404.html`.

Current output: 253 of 254 pages ship real body HTML, with an average of 7.1 kB
of inlined data each. `/explore` is the exception — it renders the whole content
set in one grid, so its payload is 266 kB, past the 128 kB budget in
`prerender.mjs`, and it ships as the shell. Every entry in that grid has its own
prerendered page, so what is lost there is a page of links rather than prose.

The prerender strips the shell's own metadata before writing each page, and
**throws if it finds nothing to strip** — otherwise a change to `index.html`
would silently produce pages carrying two titles. It asserts on the body markers
the same way. Its JSON-LD block reuses the `aradhya-jsonld` id that `useSeo`
replaces on hydration, for the same reason.

### How a page gets a body

Pages get their data through `useAsync`, which is effect-driven — so a server
render would normally emit skeletons. Three pieces change that:

- **`contentService` accessors are synchronous once the index is built.** They
  return `T | Promise<T>` via `withIndex()`. In Node the whole set is loaded up
  front, so every accessor answers immediately. Callers `await` regardless, so
  nothing else had to change.
- **`useAsync` probes its loader during render, but only while the build says
  so** (`preload.isCollecting()`). Whatever it resolves, it offers to a
  collector — so the inlined data is a record of what the page *actually*
  rendered and cannot drift from a hand-kept list. Opting in is per-call, via a
  `preloadKey` from `contentService.contentKeys`.
- **The browser reads the same map back before React mounts**, so the client's
  first render is identical to the server's: no mismatch, and no
  content → skeleton → content flash.

`entry-server.jsx` renders each page twice: once against the warm index, then
again with *only* the collected payload available, and requires the two to be
byte-identical. A page that fails that check ships as the shell rather than as
markup the browser would tear down. That second pass is also what licenses
stripping the search-only `haystack` and `titleNorm` fields from the payload.

Two constraints fall out of this and are easy to trip over:

- **`React.lazy` cannot be used for routes.** It only begins its import on first
  render, and it suspends even when the module is already loaded, because
  resolution goes through a microtask. `App.jsx` uses a `preloadable()` wrapper
  that holds the module in a closure, so an already-loaded route renders
  synchronously. `main.jsx` awaits the current route's chunk before hydrating —
  hydrating into a Suspense fallback is a mismatch, and React's answer to a
  mismatch is to discard the server's markup.
- **Minified React errors are unreadable, and Vite pins `NODE_ENV=production`
  for every build** — `--mode development` does not change it, and `--minify
  false` only stops the bundler minifying. `npm run build:debug` overrides it
  through `define`, which is what actually swaps in development React and prints
  the server value, the client value and the offending element. Never deploy
  that output.

### Anything not on the sitemap still has to reach the router

`/search`, a mistyped path and a slug that left the content set have no
prerendered file, and this is a client-rendered SPA, so the host has to hand
them to the shell rather than serve its own 404. Two mechanisms cover that, and
either one is enough:

- `dist/404.html` — written by the prerender, `noindex`, and with no canonical
  (one file is served at every unmatched URL, so any canonical it named would be
  wrong). Most static hosts serve it for an unmatched path; because it boots the
  router, the visitor lands on the real 404 page and `useSeo` corrects both tags.
  This is what GitHub Pages uses, and it needs no configuration.
- `public/_redirects` — `/* /index.html 200` for Netlify and Cloudflare Pages.
  Vercel uses `vercel.json` rewrites, Firebase uses `firebase.json`, nginx uses
  `try_files $uri $uri/ /index.html`.

## Known limitations — read before launch

- **The store URLs and the iOS app ID are placeholders.** Search for
  `TODO(launch)` in `config/appConfig.js`. `stores.*.available` is `false`,
  which is what the CTA reads to present a "coming soon" state instead of a dead
  link. This is the one item that must change before launch.
- **`/explore` ships without a prerendered body** — 266 kB of payload against a
  128 kB budget. Every entry it lists has its own prerendered page, so this
  costs a page of links, not prose. Narrowing what the grid asks for (as
  `getEpicSummary` did for the epic cards) would bring it under.
- **Search needs JavaScript.** Prerendered pages are readable without it, and
  the `<noscript>` text says exactly that rather than claiming more.
- **`siteUrl` is `https://aradhya.app`**, which the sitemap, canonicals and OG
  tags all derive from. Change it there if the domain changes.
- **`public/og-image.png` is committed** (413 kB, 1200×630) and regenerated by
  `npm run og`, which needs a local Chrome or Edge. It is deliberately not part
  of `npm run build` — the card changes rarely.
- **Two `npm audit` advisories are open, both dev-only, neither fixable without
  a breaking major.** `@vitest/mocker` (path traversal via redirect mock) is
  fixed in `vitest@5`; it affects the test runner, not the site. `react-router`
  6.x has an open-redirect advisory and an SSR-hydration one, both fixed in
  `react-router-dom@7`. Neither reaches this site: every `to=` and `navigate()`
  target is built from the route table or a content slug, never from user input,
  and the hydration advisory applies to `createBrowserRouter`'s data APIs, which
  this site does not use. Worth upgrading deliberately, not by `--force`.

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

## If a page throws

`components/ui/ErrorBoundary.jsx` wraps the router outlet in `Layout`, so a
render failure loses the page but keeps the header and footer — the visitor can
navigate away instead of staring at a white screen. It resets on the location
key, so navigating away is enough to clear it. Errors go to the console and
nowhere else; there is no reporting service, by design.

When debugging reveals or anything IntersectionObserver-driven, note that
observer callbacks are tied to the rendering lifecycle: a page in a hidden tab or
pane is not compositing frames, so reveals legitimately never fire there. Confirm
`requestAnimationFrame` is ticking before concluding the code is at fault.
