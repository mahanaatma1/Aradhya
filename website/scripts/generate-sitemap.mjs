#!/usr/bin/env node
/**
 * Builds dist/sitemap.xml from two sources that already exist:
 *
 *   - `staticSitemapEntries` in src/config/routes.js — the hand-set pages, with
 *     the priority and change frequency each one deserves.
 *   - src/data/mockContent.js — every slug that /explore/:slug can actually
 *     resolve, which is entities, festivals and journeys.
 *
 * Nothing is listed here by hand, so a URL can never appear in the sitemap
 * unless the site can really render it. Run automatically after `vite build`;
 * `npm run sitemap` runs it on its own.
 *
 * Note the honest limitation: this is a client-rendered SPA, so a crawler that
 * does not execute JavaScript follows these URLs and finds the same shell HTML
 * each time. The sitemap is correct and useful for crawlers that do render
 * (Google does), but real per-page HTML needs the prerender step described in
 * the README.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { appConfig } from '../src/config/appConfig.js';
import { routes, staticSitemapEntries } from '../src/config/routes.js';
import { entities, festivals, journeys } from '../src/data/mockContent.js';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, '..', 'dist');
const outFile = join(outDir, 'sitemap.xml');

const origin = appConfig.siteUrl.replace(/\/+$/, '');
const today = new Date().toISOString().slice(0, 10);

/** Importance 1 is a headline entry; 3 is a supporting one. */
function priorityFor(importance) {
  if (importance === 1) return 0.8;
  if (importance === 2) return 0.7;
  return 0.6;
}

const detailEntries = [
  ...entities.map((row) => ({
    path: routes.entity(row.slug),
    priority: priorityFor(row.importance),
    changefreq: 'monthly',
  })),
  // Festivals move with the lunar calendar, so their pages are worth recrawling.
  ...festivals.map((row) => ({
    path: routes.entity(row.slug),
    priority: 0.6,
    changefreq: 'weekly',
  })),
  ...journeys.map((row) => ({
    path: routes.entity(row.slug),
    priority: 0.7,
    changefreq: 'monthly',
  })),
];

/**
 * A slug can exist in more than one collection — /explore/:slug resolves the
 * first match, so the sitemap keeps the first and drops the rest rather than
 * emitting the same <loc> twice.
 */
const seen = new Set();
const urls = [];
for (const entry of [...staticSitemapEntries, ...detailEntries]) {
  if (seen.has(entry.path)) continue;
  seen.add(entry.path);
  urls.push(entry);
}

const xml = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  ...urls.map((entry) =>
    [
      '  <url>',
      `    <loc>${origin}${entry.path}</loc>`,
      `    <lastmod>${today}</lastmod>`,
      `    <changefreq>${entry.changefreq}</changefreq>`,
      `    <priority>${entry.priority.toFixed(1)}</priority>`,
      '  </url>',
    ].join('\n'),
  ),
  '</urlset>',
  '',
].join('\n');

mkdirSync(outDir, { recursive: true });
writeFileSync(outFile, xml, 'utf8');

console.log(
  `sitemap.xml — ${urls.length} urls ` +
    `(${staticSitemapEntries.length} static, ${urls.length - staticSitemapEntries.length} content) ` +
    `→ dist/sitemap.xml`,
);
