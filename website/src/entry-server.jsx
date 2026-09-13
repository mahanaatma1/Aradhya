/**
 * Server entry — renders one route to HTML at build time.
 *
 * Used only by scripts/prerender.mjs, through a `vite build --ssr` bundle (which
 * is what lets plain Node import a tree full of JSX). Nothing here ships to the
 * browser.
 *
 * The interesting part is not the render, it is the contract with hydration.
 * Every page gets its data through `useAsync`, so a naive server render emits
 * skeletons; and a page whose HTML the browser cannot reproduce on its first
 * render is worse than no prerender at all, because React discards the markup
 * and the visitor watches real content collapse into a skeleton and back.
 *
 * So each route is rendered twice:
 *
 *   Pass A renders against the warm content index and records what every keyed
 *          `useAsync` call resolved to.
 *   Pass B renders again with *only* that recording available — the same
 *          situation the browser will be in — and the two HTML strings must be
 *          identical.
 *
 * Pass B is the whole point. It turns "the payload should be enough to
 * reproduce this page" from a claim into something the build checks, per page,
 * every time. A page that fails it is reported and shipped as the plain shell
 * rather than published broken.
 */

import { StrictMode } from 'react';
import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';

import App, { loadRoutes } from './App.jsx';
import { prefetchContent } from './services/contentService.js';
import {
  PRELOAD_ID,
  clearPreload,
  setPreload,
  startCollecting,
  stopCollecting,
} from './services/preload.js';

export { PRELOAD_ID };

/** Marker that App.jsx's RouteFallback renders — see the comment there. */
const FALLBACK_MARKER = 'data-ssr-fallback';

/**
 * How many times to re-render while a lazy boundary is still showing its
 * fallback.
 *
 * Measured at zero retries for every route: `loadRoutes()` awaits every page
 * module before the first render, and `App.jsx`'s `preloadable()` renders an
 * already-loaded module synchronously, so no boundary suspends. (`React.lazy`
 * could not do this — it suspends even on a loaded module, because resolution
 * goes through a microtask, and `renderToString` cannot wait for one. That is
 * why this file used to need the retries, and why App.jsx does not use it.)
 *
 * The loop stays as a guard rather than an optimisation: something that
 * suspends unexpectedly should cost that page its body and be reported, not
 * emit a skeleton into static HTML. If this budget is ever exhausted, the page
 * ships as the shell and the prerender says which one.
 */
const MAX_PASSES = 8;

/**
 * Fields the search index needs and no component renders.
 *
 * `haystack` is roughly as long as the summary it is built from, so dropping the
 * pair takes a meaningful bite out of every payload. Safe because searchService
 * reads the live index rather than this blob — and if that ever stopped being
 * true, pass B would fail and say so.
 */
const SEARCH_ONLY = new Set(['haystack', 'titleNorm']);

function strip(value) {
  if (Array.isArray(value)) return value.map(strip);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [key, inner] of Object.entries(value)) {
      if (!SEARCH_ONLY.has(key)) out[key] = strip(inner);
    }
    return out;
  }
  return value;
}

function renderOnce(pathname) {
  return renderToString(
    <StrictMode>
      <StaticRouter location={pathname}>
        <App />
      </StaticRouter>
    </StrictMode>,
  );
}

/** Render, retrying until no lazy boundary is still showing its fallback. */
async function renderResolved(pathname, { collect }) {
  let html = '';
  let collected = new Map();

  for (let pass = 1; pass <= MAX_PASSES; pass += 1) {
    if (collect) startCollecting();
    try {
      html = renderOnce(pathname);
    } finally {
      if (collect) collected = stopCollecting();
    }

    if (!html.includes(FALLBACK_MARKER)) {
      return { html, collected, suspended: false };
    }
    // Rendering the boundary kicked its import off; give it a turn to land.
    await new Promise((resolve) => setImmediate(resolve));
  }

  return { html, collected, suspended: true };
}

/**
 * Render `pathname`.
 *
 * Returns `{ html, preload, suspended, reproducible }`. The caller inlines
 * `html` and `preload` together, or falls back to the empty shell when
 * `suspended` (a route chunk never resolved) or `!reproducible` (pass B
 * disagreed) — either way the page still works, it just paints from JavaScript
 * as it did before.
 */
export async function renderRoute(pathname) {
  await prefetchContent();
  await loadRoutes();

  clearPreload();
  const first = await renderResolved(pathname, { collect: true });
  if (first.suspended) {
    return { html: '', preload: {}, suspended: true, reproducible: false };
  }

  const preload = strip(Object.fromEntries(first.collected));

  setPreload(preload);
  const second = await renderResolved(pathname, { collect: false });
  clearPreload();

  return {
    html: first.html,
    preload,
    suspended: false,
    reproducible: !second.suspended && second.html === first.html,
  };
}

/**
 * The payload as a script element.
 *
 * `type="application/json"` so the browser never executes it, and `<` escaped
 * regardless — a `</script>` inside a string would otherwise end the element
 * early, and JSON has no other way out of it.
 */
export function preloadScript(preload) {
  const json = JSON.stringify(preload).replace(/</g, '\\u003c');
  return `<script type="application/json" id="${PRELOAD_ID}">${json}</script>`;
}
