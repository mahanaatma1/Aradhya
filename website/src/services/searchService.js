/**
 * Search.
 *
 * `searchContent(query, options)` is the only entry point the UI uses, and it is
 * async, so replacing the local index with an HTTP call is a change to this file
 * alone:
 *
 *     export async function searchContent(query, opts) {
 *       const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
 *       return res.json();          // { query, total, results, groups }
 *     }
 *
 * Queries arrive the way people type them into Google — "Who is Bhishma?",
 * "what is ekadashi", "tell me about Kurukshetra" — so the leading question
 * scaffolding is stripped before matching.
 */

import { __getIndex } from './contentService.js';
import { FACETS } from '../config/taxonomy.js';

/** Words that carry no signal in a spiritual-content query. */
const STOPWORDS = new Set([
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'am', 'be', 'been',
  'who', 'whom', 'whose', 'what', 'which', 'where', 'when', 'why', 'how',
  'tell', 'me', 'about', 'of', 'in', 'on', 'at', 'to', 'for', 'from', 'with',
  'do', 'does', 'did', 'can', 'could', 'please', 'show', 'find', 'search',
  'i', 'you', 'my', 'and', 'or', 'more', 'info', 'information', 'explain',
]);

const normalise = (s = '') =>
  s
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/['’]/g, '')
    .replace(/[^\p{L}\p{N}\s-]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();

/**
 * Split a raw query into the phrase we match on and its meaningful tokens.
 * "Who is Hanuman?" → { phrase: 'hanuman', tokens: ['hanuman'] }
 */
export function parseQuery(raw = '') {
  const cleaned = normalise(raw);
  const words = cleaned ? cleaned.split(' ') : [];
  const tokens = words.filter((w) => w.length > 1 && !STOPWORDS.has(w));
  return {
    raw: raw.trim(),
    cleaned,
    tokens: tokens.length ? tokens : words,
    phrase: (tokens.length ? tokens : words).join(' '),
  };
}

/* ------------------------------------------------------------------- scoring */

const KIND_BONUS = {
  entity: 6,
  collection: 5,
  festival: 4,
  journey: 3,
  arc: 2,
  scene: 1,
  practice: 1,
};

/**
 * Score one record against a parsed query. Higher is better; 0 drops the record.
 * The tiers deliberately step by wide margins so an exact title match can never
 * be outranked by a pile of weak summary hits.
 */
function score(record, q) {
  if (!q.phrase) return 0;

  const title = record.titleNorm;
  const hay = record.haystack;
  let s = 0;

  if (title === q.phrase) s += 1000;
  else if (title.startsWith(q.phrase)) s += 600;
  else if (record.slug === q.phrase.replace(/\s+/g, '-')) s += 900;
  else if (title.includes(q.phrase)) s += 380;

  // Alias hits matter a lot — "Partha" should find Arjuna.
  for (const alias of record.aliases ?? []) {
    const a = normalise(alias);
    if (a === q.phrase) s += 700;
    else if (a.startsWith(q.phrase)) s += 320;
  }

  if (record.titleHi && record.titleHi.includes(q.raw)) s += 700;

  let matched = 0;
  for (const token of q.tokens) {
    if (title.includes(token)) {
      s += 120;
      matched += 1;
    } else if ((record.tags ?? []).some((t) => normalise(t).includes(token))) {
      s += 55;
      matched += 1;
    } else if (hay.includes(token)) {
      s += 24;
      matched += 1;
    }
  }
  if (!s) return 0;

  // Every token has to land somewhere, otherwise "gita chapter 2" would match
  // anything containing "gita" alone as strongly as the Gita itself.
  if (matched === q.tokens.length && q.tokens.length > 1) s += 90;

  s += KIND_BONUS[record.kind] ?? 0;
  s += Math.max(0, 4 - (record.importance ?? 3)) * 8;
  return s;
}

/* -------------------------------------------------------------------- search */

/**
 * @param {string} query
 * @param {{facet?: string, limit?: number, groupLimit?: number}} [options]
 * @returns {Promise<{query: string, parsed: object, total: number,
 *   results: object[], groups: {facet: string, label: string, items: object[]}[],
 *   facetCounts: Record<string, number>}>}
 */
export async function searchContent(query, options = {}) {
  const { facet = 'all', limit = 40, groupLimit = 0 } = options;
  const parsed = parseQuery(query);
  const idx = await __getIndex();

  if (!parsed.phrase) {
    return { query, parsed, total: 0, results: [], groups: [], facetCounts: {} };
  }

  const scored = [];
  for (const record of idx.all) {
    const s = score(record, parsed);
    if (s > 0) scored.push({ record, score: s });
  }
  scored.sort((a, b) => b.score - a.score || a.record.title.localeCompare(b.record.title));

  // Facet counts are computed across the whole result set, not the filtered
  // view, so the tabs can show how much is hiding behind each one.
  const facetCounts = { all: scored.length };
  for (const { record } of scored) {
    facetCounts[record.facet] = (facetCounts[record.facet] ?? 0) + 1;
  }

  const filtered =
    facet === 'all' ? scored : scored.filter(({ record }) => record.facet === facet);

  const results = filtered.slice(0, limit).map(({ record, score: s }) => ({ ...record, score: s }));

  // Grouped view for the dropdown: best few per facet, facets in tab order.
  const groups = [];
  if (groupLimit > 0) {
    for (const f of FACETS) {
      if (f.id === 'all') continue;
      const items = results.filter((r) => r.facet === f.id).slice(0, groupLimit);
      if (items.length) groups.push({ facet: f.id, label: f.label, items });
    }
  }

  return { query, parsed, total: filtered.length, results, groups, facetCounts };
}

/**
 * Type-ahead for the search bar: a short, mixed list rather than a long one from
 * a single facet, so "ra" shows Rama, the Ramayana and Ram Navami together.
 */
export async function suggest(query, limit = 6) {
  const { results } = await searchContent(query, { limit: limit * 3 });
  const perFacet = new Map();
  const out = [];
  for (const r of results) {
    const used = perFacet.get(r.facet) ?? 0;
    if (used >= 2 && out.length >= 3) continue;
    perFacet.set(r.facet, used + 1);
    out.push(r);
    if (out.length >= limit) break;
  }
  return out;
}

/** The chips shown under the hero search before anyone types. */
export const EXAMPLE_QUERIES = [
  'Bhagavad Gita',
  'Hanuman',
  'Ekadashi',
  'Mahabharata',
  'Shiva',
  'Kurukshetra',
];

/**
 * Zero-query state for the dropdown: a fixed set of well-known starting points,
 * resolved against the real content set so nothing links to a missing page.
 */
const STARTING_POINTS = [
  'krishna', 'rama', 'shiva', 'hanuman', 'bhagavad-gita', 'kurukshetra',
];

export async function getStartingPoints() {
  const idx = await __getIndex();
  return STARTING_POINTS.map((slug) => idx.detailBySlug.get(slug)).filter(Boolean);
}

export default searchContent;
