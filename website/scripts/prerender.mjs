#!/usr/bin/env node
/**
 * Writes real per-URL HTML for every route in the sitemap.
 *
 * Each URL gets its own file containing:
 *
 *   - its own <title>, description, canonical, Open Graph, Twitter card and
 *     JSON-LD, so a crawler or chat client that never runs JavaScript still sees
 *     the right thing for that URL. Share /explore/hanuman and the unfurl says
 *     Hanuman.
 *   - the page's rendered body, and the data it was rendered from, so that same
 *     reader gets the actual article text rather than an empty #root.
 *
 * The tags come from config/seo.js — the same module hooks/useSeo.js uses at
 * runtime — so what a crawler reads before hydration and what it reads after
 * cannot disagree. The body comes from src/entry-server.jsx via the dist-ssr
 * bundle, which also *verifies* that the inlined data reproduces the HTML it
 * writes; a page that fails that check is shipped as the plain shell instead of
 * published in a state the browser would tear down on hydration.
 *
 * Runs after `vite build` and `vite build --ssr` (which produce the
 * dist/index.html shell and the dist-ssr renderer this reads). `npm run
 * prerender` runs it on its own against an existing build; without dist-ssr it
 * degrades to metadata only and says so.
 */

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { routes, staticSitemapEntries } from '../src/config/routes.js';
import { EPICS } from '../src/config/epics.js';
import { PAGE_META, buildMeta, entityJsonLd, siteJsonLd } from '../src/config/seo.js';
import { getRecord } from '../src/services/contentService.js';
import { entities, festivals, journeys } from '../src/data/mockContent.js';
// The pure string half of this script, kept separate so it is testable: this
// file runs the whole build on import, which a test cannot do. See
// scripts/lib/head.test.mjs.
import { outputPathFor, renderMeta, shellTemplate, stripOwnedTags } from './lib/head.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const distDir = join(here, '..', 'dist');
const shellPath = join(distDir, 'index.html');

/**
 * Ceiling on a page's inlined data, in bytes.
 *
 * The payload duplicates content that is also in the rendered HTML, so a page
 * whose data is enormous pays twice for one page's worth of text. Past this
 * point that trade stops being worth it and the page ships as the shell — it
 * still works, it just paints from JavaScript as the whole site used to.
 *
 * In practice this catches /explore, which renders the entire content set in one
 * grid. Every entry in that grid has its own prerendered page, so what is lost
 * is a page of links rather than a page of prose. Detail pages — the 242 URLs
 * this feature exists for — sit around 6 kB.
 */
const MAX_PRELOAD_BYTES = 128 * 1024;

/** Where a route's file goes, for this build's dist/. */
function outputPath(pathname) {
  return outputPathFor(distDir, pathname);
}

/**
 * Every URL to write, in sitemap order. Static pages come from the route
 * manifest and content pages from the same three collections the sitemap reads,
 * so the two scripts cannot cover different sets of URLs.
 */
async function collectPages() {
  const pages = [];

  for (const entry of staticSitemapEntries) {
    if (entry.path === routes.ramayana || entry.path === routes.mahabharata) {
      const epic = EPICS[entry.path.slice(1)];
      pages.push({
        pathname: entry.path,
        meta: { title: epic.title, description: epic.description, type: 'article' },
      });
      continue;
    }

    const meta = PAGE_META[entry.path];
    if (!meta) throw new Error(`No PAGE_META for sitemap route ${entry.path}`);
    pages.push({
      pathname: entry.path,
      meta,
      jsonLd: entry.path === routes.home ? siteJsonLd() : null,
    });
  }

  const seen = new Set(pages.map((page) => page.pathname));
  const missing = [];

  for (const row of [...entities, ...festivals, ...journeys]) {
    const pathname = routes.entity(row.slug);
    if (seen.has(pathname)) continue;
    seen.add(pathname);

    // Normalised through the service, so the title, summary and citation are
    // exactly the ones the page renders.
    const record = await getRecord(row.slug);
    if (!record) {
      missing.push(row.slug);
      continue;
    }

    pages.push({
      pathname,
      meta: { title: record.title, description: record.summary, type: 'article' },
      jsonLd: entityJsonLd(record),
    });
  }

  return { pages, missing };
}

/**
 * The SSR renderer, or null when it has not been built.
 *
 * Kept optional so `npm run prerender` still works on its own — it degrades to
 * the metadata-only behaviour this script had before bodies were rendered, which
 * is a fine outcome for a quick re-run, and a loud one for a real build.
 */
async function loadRenderer() {
  try {
    return await import('../dist-ssr/entry-server.js');
  } catch (error) {
    if (error?.code !== 'ERR_MODULE_NOT_FOUND') throw error;
    return null;
  }
}

const shell = readFileSync(shellPath, 'utf8');
const { html: stripped, removed } = stripOwnedTags(shell);

if (removed === 0) {
  throw new Error(
    'Stripped no head tags from dist/index.html. The shell no longer looks like ' +
      'the one this script was written for — check index.html before shipping, ' +
      'or every page will carry duplicate metadata.',
  );
}

/**
 * Cut the shell into the pieces every page is assembled from, and get back the
 * function that puts one together. Throws if the shell no longer has the
 * markers this script writes into — see scripts/lib/head.mjs.
 */
const assemble = shellTemplate(stripped);

const renderer = await loadRenderer();
const { pages, missing } = await collectPages();

/** Pages that got metadata but no body, and why. */
const shellOnly = [];
let bodyCount = 0;
let payloadBytes = 0;

for (const page of pages) {
  const meta = buildMeta({ ...page.meta, pathname: page.pathname });
  const head = renderMeta(meta, page.jsonLd);

  let body = '';
  let payload = '';

  if (renderer) {
    let result;
    try {
      result = await renderer.renderRoute(page.pathname);
    } catch (error) {
      // One page that throws should cost that page its body, not the build its
      // other 253 pages. The reason is reported at the end.
      shellOnly.push({ pathname: page.pathname, why: `threw: ${error.message}` });
      result = null;
    }

    if (result) {
      const json = renderer.preloadScript(result.preload);
      const bytes = Buffer.byteLength(json, 'utf8');

      if (result.suspended) {
        shellOnly.push({ pathname: page.pathname, why: 'a route chunk never resolved' });
      } else if (!result.reproducible) {
        // The page rendered, but rendering it again from only the inlined data
        // produced different HTML — so the browser could not reproduce this
        // markup and React would discard it. Shipping the shell is the correct
        // outcome; this is a bug to fix, not a limit to accept.
        shellOnly.push({ pathname: page.pathname, why: 'inlined data did not reproduce the body' });
      } else if (bytes > MAX_PRELOAD_BYTES) {
        shellOnly.push({
          pathname: page.pathname,
          why: `payload ${(bytes / 1024).toFixed(0)} kB over the ${MAX_PRELOAD_BYTES / 1024} kB budget`,
        });
      } else {
        body = result.html;
        payload = `\n    ${json}`;
        bodyCount += 1;
        payloadBytes += bytes;
      }
    }
  }

  const outFile = outputPath(page.pathname);
  mkdirSync(dirname(outFile), { recursive: true });
  writeFileSync(outFile, assemble(head, body, payload), 'utf8');
}

/**
 * dist/404.html — the SPA fallback.
 *
 * This site is a client-rendered SPA, so a URL that has no prerendered file
 * (`/search`, a mistyped path, a slug removed from the content set) still has to
 * reach the router. Most static hosts serve 404.html for an unmatched path, and
 * because the shell boots the router the visitor lands on the real 404 page
 * rather than the host's.
 *
 * Deliberately body-less, unlike every other page here: this one file answers
 * every unmatched URL, so any body it carried would be the wrong page's content
 * for all but one of them.
 *
 * Marked noindex, since a crawler that gets here reached a URL that does not
 * exist, and given no canonical — for the same reason. useSeo sets both
 * correctly once the router resolves. A host that supports rewrites
 * (`try_files $uri $uri/ /index.html`) can use those instead; this file is the
 * fallback that needs no configuration.
 */
const notFoundMeta = buildMeta({
  title: 'Not found',
  description: 'That page doesn’t exist. Search Aradhya’s library instead.',
  noindex: true,
});
writeFileSync(
  join(distDir, '404.html'),
  assemble(renderMeta(notFoundMeta, null, { canonical: false }), '', ''),
  'utf8',
);

const staticCount = staticSitemapEntries.length;
console.log(
  `prerender — ${pages.length} pages ` +
    `(${staticCount} static, ${pages.length - staticCount} content) + 404.html, ` +
    `${removed} shell tags replaced → dist/`,
);

if (!renderer) {
  console.warn(
    'prerender — no dist-ssr/ bundle, so these pages carry metadata only and no ' +
      'body. Run `npm run build:ssr` (or `npm run build`) for the full output.',
  );
} else {
  console.log(
    `prerender — ${bodyCount}/${pages.length} pages with rendered bodies, ` +
      `${(payloadBytes / 1024).toFixed(0)} kB of inlined data ` +
      `(avg ${(payloadBytes / Math.max(bodyCount, 1) / 1024).toFixed(1)} kB/page)`,
  );
  for (const { pathname, why } of shellOnly) {
    console.warn(`prerender — ${pathname}: shell only, ${why}`);
  }
}

if (missing.length) {
  console.warn(
    `prerender — ${missing.length} slug(s) in the content set do not resolve to a ` +
      `record and were skipped: ${missing.slice(0, 8).join(', ')}` +
      (missing.length > 8 ? ', …' : ''),
  );
}
