import { beforeAll, describe, expect, it } from 'vitest';

import {
  EXAMPLE_QUERIES,
  getStartingPoints,
  parseQuery,
  searchContent,
  suggest,
} from './searchService.js';
import { prefetchContent } from './contentService.js';

/**
 * Search runs against the real content set, not a fixture.
 *
 * A fixture would test the scoring arithmetic and nothing else. What actually
 * matters is that the queries people type land on the right page out of 376
 * records — which only the real index can show. The cost is that these tests
 * are coupled to the content; the assertions below stay on the handful of
 * records prominent enough that a change to them would be deliberate.
 */
beforeAll(async () => {
  await prefetchContent();
});

describe('parseQuery', () => {
  it('strips the question scaffolding people type into a search box', () => {
    expect(parseQuery('Who is Bhishma?').phrase).toBe('bhishma');
    expect(parseQuery('what is ekadashi').phrase).toBe('ekadashi');
    expect(parseQuery('tell me about Kurukshetra').phrase).toBe('kurukshetra');
  });

  it('folds case, punctuation and diacritics so Rāma matches rama', () => {
    expect(parseQuery('Rāma!').phrase).toBe('rama');
    expect(parseQuery("Krishna's flute").tokens).toEqual(['krishnas', 'flute']);
  });

  it('keeps the raw query, which the Hindi title match needs unfolded', () => {
    expect(parseQuery('  अर्जुन  ').raw).toBe('अर्जुन');
  });

  /**
   * Every word being a stopword is the one case where dropping them all would
   * turn a real query into an empty one and return the whole library.
   */
  it('falls back to the words themselves when every word is a stopword', () => {
    expect(parseQuery('who is the').tokens).toEqual(['who', 'is', 'the']);
  });

  it('treats an empty query as empty rather than as a match-all', () => {
    expect(parseQuery('').phrase).toBe('');
    expect(parseQuery('   ').phrase).toBe('');
    expect(parseQuery().phrase).toBe('');
  });
});

describe('searchContent', () => {
  it('returns nothing for an empty query instead of the whole library', async () => {
    const { total, results } = await searchContent('');
    expect(total).toBe(0);
    expect(results).toEqual([]);
  });

  it('puts an exact title match first', async () => {
    const { results } = await searchContent('Hanuman');
    expect(results[0].slug).toBe('hanuman');
  });

  it('answers a question the way it was asked', async () => {
    const { results } = await searchContent('Who is Arjuna?');
    expect(results[0].slug).toBe('arjuna');
  });

  it('finds a record by its alias — Partha is Arjuna', async () => {
    const { results } = await searchContent('Partha');
    expect(results[0].slug).toBe('arjuna');
  });

  it('finds a record by its Hindi title', async () => {
    const { results } = await searchContent('अर्जुन');
    expect(results[0].slug).toBe('arjuna');
  });

  it('matches a slug written as words', async () => {
    const { results } = await searchContent('bhagavad gita');
    expect(results[0].slug).toBe('bhagavad-gita');
  });

  it('ranks the exact match above the records that merely mention it', async () => {
    const { results } = await searchContent('Kurukshetra');
    expect(results[0].slug).toBe('kurukshetra');
    expect(results.length).toBeGreaterThan(1);
  });

  it('returns nothing for a query with no match, rather than the closest thing', async () => {
    const { total } = await searchContent('zzzzqqqq');
    expect(total).toBe(0);
  });

  it('honours the limit', async () => {
    const { results } = await searchContent('rama', { limit: 3 });
    expect(results.length).toBeLessThanOrEqual(3);
  });

  it('filters to one facet without changing what the other tabs would show', async () => {
    const all = await searchContent('rama');
    const scriptures = await searchContent('rama', { facet: 'scriptures' });

    expect(scriptures.results.every((r) => r.facet === 'scriptures')).toBe(true);
    // Counts describe the whole result set, so the tabs can say how much is
    // hiding behind each one even while one is selected.
    expect(scriptures.facetCounts).toEqual(all.facetCounts);
    expect(scriptures.facetCounts.all).toBe(all.total);
  });

  it('counts each facet as often as it appears', async () => {
    const { results, facetCounts } = await searchContent('rama', { limit: 1000 });
    const counted = {};
    for (const r of results) counted[r.facet] = (counted[r.facet] ?? 0) + 1;
    for (const [facet, n] of Object.entries(counted)) {
      expect(facetCounts[facet], facet).toBe(n);
    }
  });

  it('groups only when asked, in tab order, capped per facet', async () => {
    const flat = await searchContent('rama');
    expect(flat.groups).toEqual([]);

    const { groups } = await searchContent('rama', { groupLimit: 2 });
    expect(groups.length).toBeGreaterThan(0);
    for (const g of groups) {
      expect(g.items.length).toBeLessThanOrEqual(2);
      expect(g.items.every((i) => i.facet === g.facet)).toBe(true);
      expect(g.label).toBeTruthy();
    }
  });

  it('carries the score, which the results page uses for its ordering', async () => {
    const { results } = await searchContent('Hanuman');
    expect(results[0].score).toBeGreaterThan(0);
    const scores = results.map((r) => r.score);
    expect([...scores].sort((a, b) => b - a)).toEqual(scores);
  });

  it('gives every result the fields a card needs to render', async () => {
    const { results } = await searchContent('Shiva');
    for (const r of results.slice(0, 5)) {
      expect(r.title, r.id).toBeTruthy();
      expect(r.href, r.id).toMatch(/^\//);
      expect(r.facet, r.id).toBeTruthy();
    }
  });

  /** Every chip under the hero is a promise that the query returns something. */
  it('finds results for each of the example queries', async () => {
    for (const q of EXAMPLE_QUERIES) {
      const { total } = await searchContent(q);
      expect(total, `"${q}" found nothing`).toBeGreaterThan(0);
    }
  });
});

describe('suggest', () => {
  it('caps the list at the limit', async () => {
    expect((await suggest('ra', 6)).length).toBeLessThanOrEqual(6);
  });

  /**
   * The dropdown exists to show the shape of the library, so "ra" should not
   * come back as six deities. This is the mixing rule, not a ranking rule.
   */
  it('mixes facets rather than filling up from the best-scoring one', async () => {
    const facets = new Set((await suggest('ra', 6)).map((r) => r.facet));
    expect(facets.size).toBeGreaterThan(1);
  });

  it('returns nothing for an empty query', async () => {
    expect(await suggest('')).toEqual([]);
  });
});

describe('getStartingPoints', () => {
  it('resolves every starting point to a real record', async () => {
    const points = await getStartingPoints();
    expect(points.length).toBeGreaterThan(0);
    for (const p of points) {
      expect(p.href, p.slug).toMatch(/^\/explore\//);
      expect(p.title, p.slug).toBeTruthy();
    }
  });
});
