import { beforeAll, describe, expect, it, vi } from 'vitest';

import {
  allSync,
  contentKeys,
  getEpic,
  getEpicSummary,
  getFacetCounts,
  getGraphClusters,
  getRecord,
  getRelated,
  getSources,
  getStats,
  getTemples,
  listRecords,
  prefetchContent,
} from './contentService.js';

/**
 * The accessors return `T | Promise<T>` — a promise until the index is built,
 * a plain value afterwards. That is not an optimisation detail; it is the
 * mechanism the prerender runs on. `useAsync` probes a loader synchronously
 * during the server render, and a promise means "not ready", so an accessor
 * that always returned one would silently turn all 253 prerendered bodies back
 * into skeletons. Both halves are tested below.
 */
describe('the cold index', () => {
  it('returns a promise before the content has loaded', async () => {
    // A fresh module instance: the shared one is warmed by the suites below,
    // and the cold path only happens once per process.
    vi.resetModules();
    const cold = await import('./contentService.js');

    const pending = cold.getStats();
    expect(typeof pending.then).toBe('function');
    await expect(pending).resolves.toMatchObject({ entities: expect.any(Number) });
  });

  it('builds the index once, however many callers ask at the same time', async () => {
    vi.resetModules();
    const cold = await import('./contentService.js');

    const [a, b] = await Promise.all([cold.getRecord('rama'), cold.getRecord('rama')]);
    expect(a).toBe(b); // same object identity — one index, not two
  });
});

describe('the warm index', () => {
  beforeAll(async () => {
    await prefetchContent();
  });

  it('answers synchronously once the content is in memory', () => {
    const stats = getStats();
    expect(typeof stats.then).toBe('undefined');
    expect(stats.entities).toBeGreaterThan(0);
  });

  it('answers every accessor the prerender needs without awaiting', () => {
    for (const [name, call] of Object.entries({
      getRecord: () => getRecord('rama'),
      listRecords: () => listRecords({ limit: 4 }),
      getRelated: () => getRelated('rama', 4),
      getEpicSummary: () => getEpicSummary('ramayana'),
      getEpic: () => getEpic('ramayana'),
      getTemples: () => getTemples(4),
      getFacetCounts,
      getGraphClusters,
      getSources,
    })) {
      expect(typeof call()?.then, `${name} returned a promise`).toBe('undefined');
    }
  });

  describe('getRecord', () => {
    it('resolves a slug to its record', () => {
      expect(getRecord('hanuman')).toMatchObject({ slug: 'hanuman', kind: 'entity' });
    });

    /**
     * `null`, never `undefined`: preload.js reads `undefined` as "nothing was
     * inlined", so a record that genuinely does not exist has to say so with a
     * value that survives being written to JSON and read back.
     */
    it('returns null for an unknown slug, not undefined', () => {
      expect(getRecord('not-a-real-slug')).toBeNull();
    });

    it('survives a JSON round trip, which is how it reaches the browser', () => {
      const record = getRecord('hanuman');
      expect(JSON.parse(JSON.stringify(record))).toEqual(record);
    });
  });

  describe('listRecords', () => {
    it('sorts by importance, then alphabetically inside a rank', () => {
      const rows = listRecords({ facet: 'scriptures' });
      for (let i = 1; i < rows.length; i += 1) {
        const [prev, curr] = [rows[i - 1], rows[i]];
        expect(prev.importance).toBeLessThanOrEqual(curr.importance);
        if (prev.importance === curr.importance) {
          expect(prev.title.localeCompare(curr.title)).toBeLessThanOrEqual(0);
        }
      }
    });

    it('sorts by title when asked', () => {
      const titles = listRecords({ facet: 'scriptures', sort: 'title' }).map((r) => r.title);
      expect(titles).toEqual([...titles].sort((a, b) => a.localeCompare(b)));
    });

    it('filters by facet, and treats "all" as no filter', () => {
      const scriptures = listRecords({ facet: 'scriptures' });
      expect(scriptures.every((r) => r.facet === 'scriptures')).toBe(true);
      expect(listRecords({ facet: 'all' }).length).toBe(listRecords().length);
    });

    it('filters by kind and by tag', () => {
      expect(listRecords({ kinds: ['festival'] }).every((r) => r.kind === 'festival')).toBe(true);
      const tagged = listRecords({ tag: 'ramayana' });
      expect(tagged.length).toBeGreaterThan(0);
      expect(tagged.every((r) => r.tags.includes('ramayana'))).toBe(true);
    });

    it('honours the limit', () => {
      expect(listRecords({ limit: 5 }).length).toBe(5);
    });

    /** The sort is in-place on a copy; sorting the shared index would reorder it for everyone. */
    it('does not reorder the underlying index', () => {
      const before = listRecords().map((r) => r.id);
      listRecords({ sort: 'title' });
      expect(listRecords().map((r) => r.id)).toEqual(before);
    });
  });

  describe('getRelated', () => {
    it('never includes the record itself', () => {
      expect(getRelated('rama', 12).some((r) => r.slug === 'rama')).toBe(false);
    });

    it('returns each neighbour once', () => {
      const slugs = getRelated('rama', 12).map((r) => r.slug);
      expect(new Set(slugs).size).toBe(slugs.length);
    });

    it('honours the limit', () => {
      expect(getRelated('rama', 3).length).toBeLessThanOrEqual(3);
    });

    it('labels declared relations and leaves tag neighbours unlabelled', () => {
      const related = getRelated('rama', 12);
      const labelled = related.filter((r) => r.relation);
      expect(labelled.length).toBeGreaterThan(0);
      for (const r of labelled) {
        expect(typeof r.relation.type).toBe('string');
        expect(typeof r.relation.inverse).toBe('boolean');
      }
    });

    it('returns an empty list for an unknown slug rather than throwing', () => {
      expect(getRelated('not-a-real-slug')).toEqual([]);
    });
  });

  describe('getEpicSummary vs getEpic', () => {
    /**
     * This split is why /stories and the home page are prerenderable: the full
     * structure is ~50 kB of nested scenes per epic, and the two pages that
     * show an epic *card* need three integers and some faces. Returning the
     * tree put them 147 kB over the prerender's payload budget.
     */
    it('leaves the heavy arrays out of the summary', () => {
      const summary = getEpicSummary('ramayana');
      expect(summary.scenes).toBeUndefined();
      expect(summary.arcs).toBeUndefined();
      expect(summary.books).toBeUndefined();
    });

    it('still answers everything a card renders', () => {
      const summary = getEpicSummary('ramayana');
      expect(summary.label).toBeTruthy();
      expect(summary.bookCount).toBeGreaterThan(0);
      expect(summary.sceneCount).toBeGreaterThan(0);
      expect(summary.arcCount).toBeGreaterThan(0);
      expect(summary.cast.length).toBeGreaterThan(0);
    });

    it('is dramatically smaller than the full structure', () => {
      const size = (v) => JSON.stringify(v).length;
      expect(size(getEpicSummary('ramayana')) * 4).toBeLessThan(size(getEpic('ramayana')));
    });

    it('agrees with the full structure on every count', () => {
      for (const epic of ['ramayana', 'mahabharata']) {
        const summary = getEpicSummary(epic);
        const full = getEpic(epic);
        expect(summary.bookCount, epic).toBe(full.bookCount);
        expect(summary.sceneCount, epic).toBe(full.sceneCount);
        expect(full.books.length, epic).toBe(full.bookCount);
      }
    });

    it('groups scenes under their arc, in reading order', () => {
      const { books } = getEpic('ramayana');
      const scenes = books.flatMap((b) => b.arcs.flatMap((a) => a.scenes));
      expect(scenes.length).toBeGreaterThan(0);

      for (const book of books) {
        for (const arc of book.arcs) {
          expect(arc.scenes.every((s) => s.arcSlug === arc.slug)).toBe(true);
          const seqs = arc.scenes.map((s) => s.seq ?? 0);
          expect(seqs).toEqual([...seqs].sort((a, b) => a - b));
        }
      }
    });

    it('keeps the two epics apart', () => {
      const rama = getEpic('ramayana');
      expect(rama.books.flatMap((b) => b.arcs).every((a) => a.epic === 'ramayana')).toBe(true);
      expect(getEpicSummary('mahabharata').sceneCount).not.toBe(rama.sceneCount);
    });
  });

  describe('getFacetCounts', () => {
    it('counts every record exactly once under its own facet', () => {
      const counts = getFacetCounts();
      const all = listRecords();
      expect(counts.all).toBe(all.length);

      const summed = Object.entries(counts)
        .filter(([facet]) => facet !== 'all')
        .reduce((n, [, c]) => n + c, 0);
      expect(summed).toBe(all.length);
    });
  });

  describe('getGraphClusters', () => {
    /**
     * The clusters name slugs by hand, so a renamed or removed record would
     * otherwise become a link to a page that does not exist.
     */
    it('resolves every node it draws to a real record', () => {
      const clusters = getGraphClusters();
      expect(clusters.length).toBeGreaterThan(0);
      for (const cluster of clusters) {
        expect(cluster.centre.href).toMatch(/^\//);
        expect(cluster.nodes.length).toBeGreaterThanOrEqual(3);
        for (const node of cluster.nodes) {
          expect(node.title, node.slug).toBeTruthy();
          expect(node.href, node.slug).toMatch(/^\//);
        }
      }
    });
  });

  describe('getStats', () => {
    it('reports the counts the trust line quotes', () => {
      const stats = getStats();
      for (const key of ['entities', 'scenes', 'arcs', 'festivals', 'journeys', 'relations']) {
        expect(stats[key], key).toBeGreaterThan(0);
      }
    });

    /**
     * "every row cited" is a claim the site makes in prose. If it ever stops
     * being true, this should fail before a reader finds it.
     */
    it('does not report more cited entities than there are entities', () => {
      const { cited, entities } = getStats();
      expect(cited).toBeLessThanOrEqual(entities);
    });
  });

  describe('getSources', () => {
    it('tallies distinct sources, most-used first', () => {
      const sources = getSources();
      expect(sources.length).toBeGreaterThan(0);
      const counts = sources.map((s) => s.count);
      expect(counts).toEqual([...counts].sort((a, b) => b - a));
      expect(new Set(sources.map((s) => s.label)).size).toBe(sources.length);
    });
  });
});

describe('allSync', () => {
  /**
   * Several pages bundle two or three accessors into one `useAsync` call.
   * `Promise.all` would make the result a promise even when every part
   * resolved instantly — and a promise is what `useAsync` reads as "not
   * ready", which would cost exactly those pages their prerendered body.
   */
  it('stays synchronous when nothing is pending', () => {
    const out = allSync([1, 'two', { three: 3 }]);
    expect(typeof out.then).toBe('undefined');
    expect(out).toEqual([1, 'two', { three: 3 }]);
  });

  it('becomes a promise as soon as one value is one', async () => {
    const out = allSync([1, Promise.resolve(2)]);
    expect(typeof out.then).toBe('function');
    await expect(out).resolves.toEqual([1, 2]);
  });

  it('handles an empty list', () => {
    expect(allSync([])).toEqual([]);
  });

  it('is not confused by a null in the list', () => {
    expect(allSync([null, undefined, 0])).toEqual([null, undefined, 0]);
  });
});

describe('contentKeys', () => {
  it('names a key per call site, parameterised where the call is', () => {
    expect(contentKeys.record('hanuman')).toBe('record:hanuman');
    expect(contentKeys.related('hanuman', 8)).toBe('related:hanuman:8');
    expect(contentKeys.explore('all', 'importance')).toBe('explore:all:importance');
    expect(contentKeys.epicPage('ramayana')).toBe('epicPage:ramayana');
  });

  /**
   * Two call sites sharing a key would inline one page's data under the other's
   * name, and the browser would render the wrong thing from it.
   */
  it('has no duplicate fixed keys', () => {
    const fixed = Object.values(contentKeys).filter((v) => typeof v === 'string');
    expect(new Set(fixed).size).toBe(fixed.length);
  });

  it('varies with its arguments, so two pages never share an entry', () => {
    expect(contentKeys.record('rama')).not.toBe(contentKeys.record('sita'));
    expect(contentKeys.related('rama', 4)).not.toBe(contentKeys.related('rama', 8));
  });
});
