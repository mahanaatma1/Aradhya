import { describe, expect, it } from 'vitest';

import {
  DEFAULT_DESCRIPTION,
  OG_IMAGE,
  PAGE_META,
  buildMeta,
  entityJsonLd,
  siteJsonLd,
} from './seo.js';
import { appConfig } from './appConfig.js';
import { routes, staticSitemapEntries } from './routes.js';

/**
 * These tags are written twice — by hooks/useSeo.js at runtime and by
 * scripts/prerender.mjs at build time — from this one module. A crawler reads
 * the prerendered copy, so a mistake here is not a visible bug; it is 254 pages
 * that quietly say the wrong thing.
 */
describe('buildMeta', () => {
  it('puts the page name first and the brand second', () => {
    const meta = buildMeta({ title: 'Hanuman', pathname: '/explore/hanuman' });
    expect(meta.title).toBe('Hanuman — Aradhya');
  });

  it('falls back to the brand promise at the root, where there is no page name', () => {
    const meta = buildMeta({ title: null, pathname: '/' });
    expect(meta.title).toBe(`${appConfig.name} — ${appConfig.promise}`);
  });

  it('builds an absolute canonical from the configured origin', () => {
    const meta = buildMeta({ pathname: '/temples' });
    expect(meta.canonical).toBe('https://aradhya.app/temples');
  });

  it('gives og:url and the canonical the same value', () => {
    const meta = buildMeta({ pathname: '/explore/sita' });
    expect(meta.properties['og:url']).toBe(meta.canonical);
  });

  it('repeats the title and description across og and twitter', () => {
    const meta = buildMeta({ title: 'About', description: 'What Aradhya is.' });
    expect(meta.properties['og:title']).toBe(meta.title);
    expect(meta.names['twitter:title']).toBe(meta.title);
    expect(meta.properties['og:description']).toBe('What Aradhya is.');
    expect(meta.names['twitter:description']).toBe('What Aradhya is.');
  });

  it('makes the share image absolute — unfurlers do not resolve relative ones', () => {
    const meta = buildMeta({});
    expect(meta.properties['og:image']).toBe(`${appConfig.siteUrl}${OG_IMAGE}`);
    expect(meta.names['twitter:image']).toBe(meta.properties['og:image']);
  });

  it('indexes by default and only noindexes when asked', () => {
    expect(buildMeta({}).names.robots).toBe('index, follow');
    expect(buildMeta({ noindex: true }).names.robots).toBe('noindex, follow');
  });

  it('falls back to the site description rather than emitting an empty one', () => {
    expect(buildMeta({}).names.description).toBe(DEFAULT_DESCRIPTION);
  });

  it('works with no arguments at all, since the 404 path relies on the defaults', () => {
    const meta = buildMeta();
    expect(meta.title).toContain(appConfig.name);
    expect(meta.canonical).toBe(`${appConfig.siteUrl}/`);
  });
});

describe('PAGE_META', () => {
  /**
   * The prerender throws on a sitemap route with no copy. That is the right
   * behaviour, but it fails at build time, after a change has been made and
   * pushed — catching it here is cheaper.
   */
  it('covers every static route in the sitemap', () => {
    const missing = staticSitemapEntries
      .map((entry) => entry.path)
      .filter((path) => path !== routes.ramayana && path !== routes.mahabharata)
      .filter((path) => !PAGE_META[path]);
    expect(missing).toEqual([]);
  });

  it('gives every page a description, because a missing one silently defaults', () => {
    for (const [path, meta] of Object.entries(PAGE_META)) {
      expect(meta.description, `${path} has no description`).toBeTruthy();
    }
  });

  it('keeps descriptions inside the length search results actually show', () => {
    for (const [path, meta] of Object.entries(PAGE_META)) {
      expect(meta.description.length, `${path} is ${meta.description.length} chars`)
        .toBeLessThanOrEqual(320);
    }
  });

  it('does not repeat a description across two pages', () => {
    const seen = new Map();
    for (const [path, meta] of Object.entries(PAGE_META)) {
      expect(seen.get(meta.description), `${path} duplicates ${seen.get(meta.description)}`)
        .toBeUndefined();
      seen.set(meta.description, path);
    }
  });
});

describe('structured data', () => {
  it('describes the site with a search action pointing at the real search route', () => {
    const node = siteJsonLd();
    expect(node['@type']).toBe('WebSite');
    expect(node.potentialAction.target).toBe(
      `${appConfig.siteUrl}${routes.search}?q={search_term_string}`,
    );
  });

  it('types a festival as an Event and everything else as a DefinedTerm', () => {
    const base = { title: 'X', summary: 'Y', href: '/explore/x' };
    expect(entityJsonLd({ ...base, kind: 'festival' })['@type']).toBe('Event');
    expect(entityJsonLd({ ...base, kind: 'entity' })['@type']).toBe('DefinedTerm');
  });

  it('cites the source when the record has one, with its section', () => {
    const node = entityJsonLd({
      kind: 'entity',
      title: 'Hanuman',
      summary: 'A devotee.',
      href: '/explore/hanuman',
      source: { label: 'Valmiki Ramayana', section: 'Sundara Kanda' },
    });
    expect(node.citation).toBe('Valmiki Ramayana, Sundara Kanda');
  });

  it('cites the label alone when there is no section', () => {
    const node = entityJsonLd({
      kind: 'entity',
      title: 'Hanuman',
      summary: 'A devotee.',
      href: '/explore/hanuman',
      source: { label: 'Valmiki Ramayana' },
    });
    expect(node.citation).toBe('Valmiki Ramayana');
  });

  /**
   * An absent citation has to stay absent. Emitting `citation: ""` would be a
   * claim that the record is uncited, in a format Google reads.
   */
  it('omits the citation entirely when the record has no source', () => {
    const node = entityJsonLd({
      kind: 'entity',
      title: 'Dharma',
      summary: 'A concept.',
      href: '/explore/dharma',
    });
    expect('citation' in node).toBe(false);
  });

  it('survives JSON round-tripping, which is how the prerender writes it', () => {
    const node = entityJsonLd({
      kind: 'entity',
      title: 'Rama',
      summary: 'A prince.',
      href: '/explore/rama',
    });
    expect(JSON.parse(JSON.stringify(node))).toEqual({
      '@context': 'https://schema.org',
      '@type': 'DefinedTerm',
      name: 'Rama',
      description: 'A prince.',
      url: 'https://aradhya.app/explore/rama',
      inDefinedTermSet: 'https://aradhya.app/explore',
    });
  });
});
