#!/usr/bin/env node
/**
 * Writes real per-URL HTML for every route in the sitemap.
 *
 * What this does and does not do, precisely:
 *
 *   It does  — give each URL its own file with the correct <title>, description,
 *              canonical, Open Graph, Twitter card and JSON-LD baked into the
 *              HTML, so a crawler or a chat client that never runs JavaScript
 *              still sees the right thing for that URL. Share a link to
 *              /explore/hanuman and the unfurl says Hanuman.
 *
 *   It does not — prerender the body. Every page still ships the same empty
 *              #root and paints from JavaScript. Real body HTML needs the data
 *              available synchronously on first render, which is a data-layer
 *              change (per-page inlining plus hydration), not a build step. See
 *              the README's known-limitations section.
 *
 * The tags come from config/seo.js — the same module hooks/useSeo.js uses at
 * runtime — so what a crawler reads before hydration and what it reads after
 * cannot disagree.
 *
 * Runs after `vite build` (which is what produces the dist/index.html shell this
 * reads); `npm run prerender` runs it on its own against an existing build.
 */

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { routes, staticSitemapEntries } from '../src/config/routes.js';
import { EPICS } from '../src/config/epics.js';
import { PAGE_META, buildMeta, entityJsonLd, siteJsonLd } from '../src/config/seo.js';
import { getRecord } from '../src/services/contentService.js';
import { entities, festivals, journeys } from '../src/data/mockContent.js';

const here = dirname(fileURLToPath(import.meta.url));
const distDir = join(here, '..', 'dist');
const shellPath = join(distDir, 'index.html');

/** Escape for an attribute value or text node. */
function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Tokenise the head tags this script owns.
 *
 * Attribute regions allow quoted strings so a `>` inside a description does not
 * end the tag early. Only <meta>, <link> and the two element pairs we replace
 * are matched; everything else in the shell is left untouched.
 */
const TAG_RE = new RegExp(
  [
    // <meta …> / <link …>
    '<(meta|link)\\b((?:[^>"\']|"[^"]*"|\'[^\']*\')*)>',
    // <title>…</title> / <script …>…</script>
    '<(title|script)\\b((?:[^>"\']|"[^"]*"|\'[^\']*\')*)>([\\s\\S]*?)</\\3\\s*>',
  ].join('|'),
  'gi',
);

/** True for a tag whose job this script has taken over. */
function isOwnedTag(name, attrs) {
  if (name === 'title') return true;
  if (name === 'script') return /type\s*=\s*["']application\/ld\+json["']/i.test(attrs);
  if (name === 'link') return /rel\s*=\s*["']canonical["']/i.test(attrs);
  if (name === 'meta') {
    return (
      /name\s*=\s*["'](description|robots)["']/i.test(attrs) ||
      /property\s*=\s*["']og:/i.test(attrs) ||
      /name\s*=\s*["']twitter:/i.test(attrs)
    );
  }
  return false;
}

/**
 * Strip the tags this script owns out of the shell's <head>, and report how many
 * went. The count is asserted by the caller: a shell that stopped containing a
 * <title> would otherwise silently produce pages with two of them.
 */
function stripOwnedTags(html) {
  const headEnd = html.indexOf('</head>');
  if (headEnd === -1) throw new Error('dist/index.html has no </head> — is this a Vite build?');

  let removed = 0;
  const head = html.slice(0, headEnd).replace(TAG_RE, (match, tag, attrs, pair, pairAttrs) => {
    const name = (tag ?? pair).toLowerCase();
    if (!isOwnedTag(name, tag ? attrs : pairAttrs)) return match;
    removed += 1;
    return '';
  });

  // Collapse the blank lines the removals left behind.
  return { html: head.replace(/\r?\n[ \t]*(?=\r?\n)/g, '') + html.slice(headEnd), removed };
}

/** Render one page's head tags as HTML, in a stable order. */
function renderMeta(meta, jsonLd) {
  const lines = [`<title>${esc(meta.title)}</title>`];
  for (const [name, content] of Object.entries(meta.names)) {
    lines.push(`<meta name="${name}" content="${esc(content)}" />`);
  }
  for (const [property, content] of Object.entries(meta.properties)) {
    lines.push(`<meta property="${property}" content="${esc(content)}" />`);
  }
  lines.push(`<link rel="canonical" href="${esc(meta.canonical)}" />`);
  if (jsonLd) {
    // The id is what useSeo replaces on hydration, so the page never ends up
    // holding two structured-data blocks.
    lines.push(
      '<script type="application/ld+json" id="aradhya-jsonld">' +
        // </script> cannot appear inside a script element, and JSON has no other
        // way out of it.
        JSON.stringify(jsonLd).replace(/</g, '\\u003c') +
        '</script>',
    );
  }
  return lines.map((line) => `    ${line}`).join('\n');
}

/** Where a route's file goes: '/' → dist/index.html, '/about' → dist/about/index.html. */
function outputPathFor(pathname) {
  if (pathname === '/') return shellPath;
  return join(distDir, ...pathname.replace(/^\/+|\/+$/g, '').split('/'), 'index.html');
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

const shell = readFileSync(shellPath, 'utf8');
const { html: stripped, removed } = stripOwnedTags(shell);

if (removed === 0) {
  throw new Error(
    'Stripped no head tags from dist/index.html. The shell no longer looks like ' +
      'the one this script was written for — check index.html before shipping, ' +
      'or every page will carry duplicate metadata.',
  );
}

const marker = stripped.indexOf('</head>');
const before = stripped.slice(0, marker).replace(/[ \t]+$/, '');
const after = stripped.slice(marker);
const { pages, missing } = await collectPages();

for (const page of pages) {
  const meta = buildMeta({ ...page.meta, pathname: page.pathname });
  const html = `${before}${renderMeta(meta, page.jsonLd)}\n  ${after}`;

  const outFile = outputPathFor(page.pathname);
  mkdirSync(dirname(outFile), { recursive: true });
  writeFileSync(outFile, html, 'utf8');
}

const staticCount = staticSitemapEntries.length;
console.log(
  `prerender — ${pages.length} pages ` +
    `(${staticCount} static, ${pages.length - staticCount} content), ` +
    `${removed} shell tags replaced → dist/`,
);
if (missing.length) {
  console.warn(
    `prerender — ${missing.length} slug(s) in the content set do not resolve to a ` +
      `record and were skipped: ${missing.slice(0, 8).join(', ')}` +
      (missing.length > 8 ? ', …' : ''),
  );
}
