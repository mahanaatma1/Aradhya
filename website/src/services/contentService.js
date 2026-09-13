/**
 * The website's read model.
 *
 * Everything the pages render passes through here, normalised into one `record`
 * shape so cards, search and the knowledge graph can treat an entity, a festival
 * and a journey identically.
 *
 * The API is async on purpose. Today it resolves against the generated content
 * set (src/data/mockContent.js, built from the app's curated pipeline); swapping
 * in a real HTTP API means changing `loadContent()` and nothing else, because no
 * caller assumes the data is already in memory.
 */

import {
  EPIC_LABELS,
  FACET_ACCENT,
  PRACTICES,
  SCRIPTURE_COLLECTIONS,
  categoryLabel,
  isTirtha,
} from '../config/taxonomy.js';

/* ------------------------------------------------------------------ loading */

let indexPromise = null;

/**
 * The built index, the moment it exists.
 *
 * Its purpose is to let the accessors below answer *synchronously* once the
 * content is in memory. That matters in exactly one place: the build's server
 * render, where the whole set is loaded up front, so every page can render its
 * real content on the first pass instead of a skeleton. See services/preload.js.
 */
let readyIndex = null;

/**
 * Kick the content chunk off early (called once on app mount) so the first
 * keystroke in the hero search has nothing to wait for.
 */
export function prefetchContent() {
  return getIndex();
}

async function loadContent() {
  // A single dynamic import keeps ~270 KB of curated data out of the entry
  // bundle. Replace this body with `fetch('/api/content')` for a live backend.
  return import('../data/mockContent.js');
}

function getIndex() {
  if (readyIndex) return readyIndex;
  if (!indexPromise) {
    indexPromise = loadContent().then((data) => {
      readyIndex = buildIndex(data);
      return readyIndex;
    });
  }
  return indexPromise;
}

/**
 * Run `fn` against the index — synchronously if the index is already built,
 * otherwise once it is.
 *
 * Every accessor goes through this, which is why they return `T | Promise<T>`
 * rather than always a promise. Callers are unaffected: `await` on a plain value
 * yields the value. What it buys is a synchronous first render when the data is
 * already there, and nothing changes for a live HTTP backend — `readyIndex`
 * simply stays null until the first response lands, so every call is a promise.
 */
function withIndex(fn) {
  const idx = readyIndex;
  return idx ? fn(idx) : getIndex().then(fn);
}

/**
 * `Promise.all` that stays synchronous when nothing is pending.
 *
 * Several pages need two or three accessors at once. Wrapping those in
 * `Promise.all` would make the combined result a promise even when every part
 * resolved instantly, which would cost those pages the synchronous first render
 * that `withIndex` just bought them. Same call shape, same result, minus the
 * unnecessary tick.
 */
export function allSync(values) {
  return values.some((v) => typeof v?.then === 'function') ? Promise.all(values) : values;
}

/* ------------------------------------------------------------ record shaping */

const norm = (s = '') =>
  s
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '') // strip diacritics so 'Rama' matches 'Rāma'
    .replace(/['’]/g, '')
    .trim();

function makeRecord(fields) {
  const keywords = [
    fields.title,
    fields.titleHi,
    ...(fields.aliases ?? []),
    ...(fields.tags ?? []),
    fields.badge,
    fields.summary,
  ]
    .filter(Boolean)
    .map(norm);

  return {
    ...fields,
    titleNorm: norm(fields.title),
    haystack: keywords.join(' • '),
  };
}

function entityRecord(e) {
  const facet = isTirtha(e) ? 'temples' : e.facet;
  return makeRecord({
    id: `entity:${e.slug}`,
    kind: 'entity',
    facet,
    slug: e.slug,
    title: e.title,
    titleHi: e.titleHi,
    summary: e.summary,
    summaryHi: e.summaryHi,
    detail: e.detail,
    meaning: e.meaning,
    badge: categoryLabel(e.category),
    category: e.category,
    entityKind: e.kind,
    aliases: e.aliases ?? [],
    tags: e.tags ?? [],
    importance: e.importance ?? 3,
    glyph: e.glyph,
    accent: FACET_ACCENT[facet] ?? 'scriptures',
    source: e.source,
    href: `/explore/${e.slug}`,
  });
}

function festivalRecord(f) {
  return makeRecord({
    id: `festival:${f.slug}`,
    kind: 'festival',
    facet: 'festivals',
    slug: f.slug,
    title: f.title,
    titleHi: f.titleHi,
    summary: f.summary,
    badge: 'Festival',
    when: f.when,
    region: f.region,
    tradition: f.tradition,
    deity: f.deity,
    ritual: f.ritual,
    tags: [f.tradition, f.region, 'festival'].filter(Boolean),
    importance: 2,
    glyph: 'diya',
    accent: 'panchang',
    href: `/explore/${f.slug}`,
  });
}

function journeyRecord(j) {
  return makeRecord({
    id: `journey:${j.slug}`,
    kind: 'journey',
    facet: 'journeys',
    slug: j.slug,
    title: j.title,
    titleHi: j.titleHi,
    summary: j.summary,
    badge: 'Journey',
    level: j.level,
    minutes: j.minutes,
    steps: j.steps ?? [],
    tags: j.tags ?? [],
    importance: 2,
    glyph: 'compass',
    accent: 'gyan',
    href: `/explore/${j.slug}`,
  });
}

function sceneRecord(s) {
  const epic = EPIC_LABELS[s.epic] ?? s.epic;
  return makeRecord({
    id: `scene:${s.slug}`,
    kind: 'scene',
    facet: 'stories',
    slug: s.slug,
    title: s.title,
    titleHi: s.titleHi,
    summary: s.summary,
    badge: s.book ? `${epic} · ${s.book}` : epic,
    epic: s.epic,
    book: s.book,
    bookNo: s.bookNo,
    seq: s.seq,
    arcSlug: s.arcSlug,
    arcTitle: s.arcTitle,
    cast: s.cast ?? [],
    place: s.place,
    lesson: s.lesson,
    source: s.source,
    tags: [s.epic, s.book].filter(Boolean),
    importance: 2,
    glyph: 'bow',
    accent: s.epic === 'ramayana' ? 'epics' : 'katha',
    // Scenes live on their epic's page rather than getting a thin page of
    // their own; the anchor scrolls straight to the card.
    href: `/${s.epic}#scene-${s.slug}`,
  });
}

function arcRecord(a) {
  return makeRecord({
    id: `arc:${a.slug}`,
    kind: 'arc',
    facet: 'stories',
    slug: a.slug,
    title: a.title,
    summary: a.summary,
    badge: `${EPIC_LABELS[a.epic] ?? a.epic} · ${a.book}`,
    epic: a.epic,
    book: a.book,
    bookNo: a.bookNo,
    no: a.no,
    sceneCount: a.sceneCount,
    tags: [a.epic, a.book].filter(Boolean),
    importance: 2,
    glyph: 'bow',
    accent: a.epic === 'ramayana' ? 'epics' : 'katha',
    href: `/${a.epic}#arc-${a.slug}`,
  });
}

function collectionRecord(c) {
  return makeRecord({
    id: `collection:${c.id}`,
    kind: 'collection',
    facet: 'scriptures',
    slug: c.id,
    title: c.title,
    titleHi: c.titleHi,
    summary: c.blurb,
    badge: 'Scripture',
    tags: ['scripture', c.id],
    importance: 1,
    glyph: c.glyph,
    accent: c.accent,
    entitySlug: c.entitySlug,
    href: c.entitySlug ? `/explore/${c.entitySlug}` : `/scriptures#${c.id}`,
  });
}

function practiceRecord(p) {
  return makeRecord({
    id: `practice:${p.id}`,
    kind: 'practice',
    facet: 'practices',
    slug: p.id,
    title: p.title,
    titleHi: p.titleHi,
    summary: p.blurb,
    badge: 'Practice',
    tags: ['practice', 'sadhana', p.id],
    importance: 2,
    glyph: p.glyph,
    accent: p.accent,
    href: `/practices#${p.id}`,
  });
}

/* ------------------------------------------------------------- index building */

function buildIndex(data) {
  const entityRecords = data.entities.map(entityRecord);
  const festivalRecords = data.festivals.map(festivalRecord);
  const journeyRecords = data.journeys.map(journeyRecord);
  const sceneRecords = data.scenes.map(sceneRecord);
  const arcRecords = data.arcs.map(arcRecord);
  const collectionRecords = SCRIPTURE_COLLECTIONS.map(collectionRecord);
  const practiceRecords = PRACTICES.map(practiceRecord);

  const all = [
    ...entityRecords,
    ...sceneRecords,
    ...arcRecords,
    ...festivalRecords,
    ...journeyRecords,
    ...collectionRecords,
    ...practiceRecords,
  ];

  const byId = new Map(all.map((r) => [r.id, r]));
  const entityBySlug = new Map(entityRecords.map((r) => [r.slug, r]));

  /**
   * `/explore/:slug` resolves against this. Arcs and scenes are deliberately
   * absent — two arc slugs collide with entity slugs (abhimanyu, karna) and
   * both already have a home on their epic's page.
   */
  const detailBySlug = new Map();
  for (const r of [...entityRecords, ...festivalRecords, ...journeyRecords]) {
    if (!detailBySlug.has(r.slug)) detailBySlug.set(r.slug, r);
  }

  // Undirected adjacency, so a relation stated one way is browsable both ways.
  const adjacency = new Map();
  const link = (from, to, type, inverse) => {
    if (!adjacency.has(from)) adjacency.set(from, []);
    adjacency.get(from).push({ slug: to, type, inverse });
  };
  for (const rel of data.relations) {
    link(rel.src, rel.dst, rel.type, false);
    link(rel.dst, rel.src, rel.type, true);
  }

  // An entity's appearances in the narrative, and the festivals kept for it.
  const appearances = new Map();
  for (const scene of sceneRecords) {
    for (const slug of scene.cast) {
      if (!appearances.has(slug)) appearances.set(slug, []);
      appearances.get(slug).push(scene);
    }
    if (scene.place) {
      if (!appearances.has(scene.place)) appearances.set(scene.place, []);
      appearances.get(scene.place).push(scene);
    }
  }
  const festivalsByDeity = new Map();
  for (const f of festivalRecords) {
    if (!f.deity) continue;
    if (!festivalsByDeity.has(f.deity)) festivalsByDeity.set(f.deity, []);
    festivalsByDeity.get(f.deity).push(f);
  }

  const byTag = new Map();
  for (const r of all) {
    for (const tag of r.tags ?? []) {
      if (!byTag.has(tag)) byTag.set(tag, []);
      byTag.get(tag).push(r);
    }
  }

  return {
    raw: data,
    all,
    byId,
    entities: entityRecords,
    entityBySlug,
    detailBySlug,
    scenes: sceneRecords,
    arcs: arcRecords,
    festivals: festivalRecords,
    journeys: journeyRecords,
    collections: collectionRecords,
    practices: practiceRecords,
    adjacency,
    appearances,
    festivalsByDeity,
    byTag,
    quiz: data.quizQuestions ?? [],
    trivia: data.triviaFacts ?? [],
    riddles: data.riddles ?? [],
  };
}

/* ----------------------------------------------------------------- accessors */

/**
 * Preload keys — one per `useAsync` call site that opts into build-time inlining.
 *
 * A page passes one of these as its `preloadKey`; the build records what that
 * call resolved to and writes it into the page's HTML under the same string, and
 * the browser reads it back before React mounts. They are named after call sites
 * rather than accessors because that is what they identify: several pages bundle
 * two or three accessors into one call, and three separate places ask for
 * `stats` with the identical loader and should share one entry.
 *
 * Kept here, beside the accessors, so a key and the call it names cannot drift.
 */
export const contentKeys = {
  // Content detail — the 242 pages this matters most for.
  record: (slug) => `record:${slug}`,
  related: (slug, limit) => `related:${slug}:${limit}`,

  // Listing and section pages.
  explore: (facet, sort) => `explore:${facet}:${sort}`,
  epicPage: (epic) => `epicPage:${epic}`,
  storiesPage: 'storiesPage',
  scripturesPage: 'scripturesPage',
  templesPage: 'templesPage',
  journeysPage: 'journeysPage',
  aboutPage: 'aboutPage',

  // Home. `stats` and `graph` are each asked for by more than one component.
  stats: 'stats',
  graph: 'graph',
  homeEpics: 'homeEpics',
  homeTemples: 'homeTemples',
  homeJourneys: 'homeJourneys',
  homeScriptures: 'homeScriptures',
  homePlay: 'homePlay',
};

/** Full record for a `/explore/:slug` page, or null when the slug is unknown. */
export function getRecord(slug) {
  return withIndex((idx) => idx.detailBySlug.get(slug) ?? null);
}

/**
 * Browse listing.
 * @param {{facet?: string, tag?: string, kinds?: string[], limit?: number, sort?: 'importance'|'title'}} opts
 */
export function listRecords(opts = {}) {
  const { facet, tag, kinds, limit, sort = 'importance' } = opts;
  return withIndex((idx) => {
    let rows = idx.all;
    if (kinds?.length) rows = rows.filter((r) => kinds.includes(r.kind));
    if (facet && facet !== 'all') rows = rows.filter((r) => r.facet === facet);
    if (tag) rows = rows.filter((r) => r.tags?.includes(tag));

    rows = [...rows].sort(
      sort === 'title'
        ? (a, b) => a.title.localeCompare(b.title)
        : (a, b) => a.importance - b.importance || a.title.localeCompare(b.title),
    );
    return limit ? rows.slice(0, limit) : rows;
  });
}

/** How many records sit behind each facet — drives the counts on the tabs. */
export function getFacetCounts() {
  return withIndex((idx) => {
    const counts = { all: idx.all.length };
    for (const r of idx.all) counts[r.facet] = (counts[r.facet] ?? 0) + 1;
    return counts;
  });
}

/**
 * Related content for a detail page: declared relations first (they carry a
 * label), then narrative appearances, festivals, and finally shared-tag
 * neighbours to fill the row.
 */
export function getRelated(slug, limit = 8) {
  return withIndex((idx) => {
    const seen = new Set([slug]);
    const out = [];

    const push = (record, relation) => {
      if (!record || seen.has(record.slug) || out.length >= limit) return;
      seen.add(record.slug);
      out.push(relation ? { ...record, relation } : record);
    };

    for (const edge of idx.adjacency.get(slug) ?? []) {
      push(idx.entityBySlug.get(edge.slug), {
        type: edge.type,
        inverse: edge.inverse,
      });
    }
    for (const scene of idx.appearances.get(slug) ?? []) {
      push(scene, { type: 'appears_in', inverse: true });
    }
    for (const festival of idx.festivalsByDeity.get(slug) ?? []) {
      push(festival, { type: 'kept_for', inverse: true });
    }

    if (out.length < limit) {
      const self = idx.detailBySlug.get(slug);
      for (const tag of self?.tags ?? []) {
        for (const neighbour of idx.byTag.get(tag) ?? []) {
          push(neighbour, null);
        }
      }
    }
    return out.slice(0, limit);
  });
}

/**
 * An epic at a glance: its label, what it contains, and its principal cast.
 *
 * Split from `getEpic` because the pages that show an epic *card* — the home
 * showcase and /stories — need three integers and a handful of faces, while the
 * full structure below is 50 kB of nested scenes per epic. Returning the tree to
 * render `books.length` meant those two pages carried ~124 kB of prerendered
 * data they never read.
 */
export function getEpicSummary(epic) {
  return withIndex((idx) => {
    const { scenes, arcs, ...summary } = summarise(idx, epic);
    return summary;
  });
}

/**
 * The shared half of both accessors.
 *
 * Returns `scenes` and `arcs` alongside the summary because `getEpic` needs them
 * to build its tree — both callers drop them, which is the whole point: those two
 * arrays are the 50 kB per epic that the summary exists to avoid.
 */
function summarise(idx, epic) {
  const scenes = idx.scenes.filter((s) => s.epic === epic);
  const arcs = idx.arcs.filter((a) => a.epic === epic);

  return {
    epic,
    label: EPIC_LABELS[epic] ?? epic,
    bookCount: new Set(arcs.map((a) => a.bookNo)).size,
    sceneCount: scenes.length,
    arcCount: arcs.length,
    /** Principal cast, most-referenced first — the faces of the epic. */
    cast: castOf(idx, scenes, 12),
    scenes,
    arcs,
  };
}

/** Scenes for an epic, already in reading order, grouped by book then arc. */
export function getEpic(epic) {
  return withIndex((idx) => {
    const { scenes, arcs, ...summary } = summarise(idx, epic);

    const books = [];
    for (const arc of arcs) {
      let book = books.find((b) => b.no === arc.bookNo);
      if (!book) {
        book = { no: arc.bookNo, label: arc.book, arcs: [] };
        books.push(book);
      }
      book.arcs.push({
        ...arc,
        scenes: scenes
          .filter((s) => s.arcSlug === arc.slug)
          .sort((a, b) => (a.seq ?? 0) - (b.seq ?? 0)),
      });
    }

    return { ...summary, books };
  });
}

function castOf(idx, scenes, limit) {
  const tally = new Map();
  for (const s of scenes) {
    for (const slug of s.cast) tally.set(slug, (tally.get(slug) ?? 0) + 1);
  }
  return [...tally.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([slug, count]) => {
      const record = idx.entityBySlug.get(slug);
      return record ? { ...record, appearances: count } : null;
    })
    .filter(Boolean)
    .slice(0, limit);
}

export function getJourneys(limit) {
  return withIndex((idx) => (limit ? idx.journeys.slice(0, limit) : idx.journeys));
}

export function getFestivals(limit) {
  return withIndex((idx) => (limit ? idx.festivals.slice(0, limit) : idx.festivals));
}

export function getCollections() {
  return withIndex((idx) => idx.collections);
}

export function getPractices() {
  return withIndex((idx) => idx.practices);
}

/**
 * Pilgrimage sites. These are the tirthas the curated set covers — cities and
 * sites, not individual temple buildings. The app's temple directory holds the
 * structured per-temple records (name, deity, town, state); when that is exposed
 * this function is the seam to widen, and TempleCard already renders a
 * `location` field when one is present.
 */
export function getTemples(limit) {
  return withIndex((idx) => {
    const rows = idx.entities
      .filter((e) => e.facet === 'temples')
      .sort((a, b) => a.importance - b.importance || a.title.localeCompare(b.title));
    return limit ? rows.slice(0, limit) : rows;
  });
}

/** Sacred geography that is not a tirtha — rivers and mountains. */
export function getSacredGeography(limit) {
  return withIndex((idx) => {
    const rows = idx.entities.filter((e) => e.facet === 'places');
    return limit ? rows.slice(0, limit) : rows;
  });
}

export function getQuiz(limit = 1) {
  return withIndex((idx) => idx.quiz.slice(0, limit));
}

export function getTrivia(limit = 3) {
  return withIndex((idx) => idx.trivia.slice(0, limit));
}

export function getRiddles(limit = 1) {
  return withIndex((idx) => idx.riddles.slice(0, limit));
}

/**
 * The two clusters the "Everything is connected" section draws. Nodes are named
 * by slug and resolved against the real content set, so a node only renders as a
 * link when the page behind it actually exists.
 */
const GRAPH_CLUSTERS = [
  {
    id: 'gita',
    centre: 'krishna',
    label: 'The Gita, and everyone in it',
    nodes: ['bhagavad-gita', 'arjuna', 'dharma', 'mahabharata-text', 'kurukshetra'],
  },
  {
    id: 'hanuman',
    centre: 'hanuman',
    label: 'One devotee, five ways in',
    nodes: ['rama', 'ramayana-text', 'sita', 'lanka', 'bhakti'],
  },
];

export function getGraphClusters() {
  return withIndex((idx) =>
    GRAPH_CLUSTERS.map((cluster) => {
      const centre = idx.detailBySlug.get(cluster.centre);
      const nodes = cluster.nodes
        .map((slug) => idx.detailBySlug.get(slug))
        .filter(Boolean)
        .map((record) => ({
          ...record,
          edge: (idx.adjacency.get(cluster.centre) ?? []).find((e) => e.slug === record.slug)?.type,
        }));
      return { ...cluster, centre, nodes };
    }).filter((c) => c.centre && c.nodes.length >= 3),
  );
}

/** Counts used as trust signals ("174 entities, every row cited"). */
export function getStats() {
  return withIndex((idx) => ({
    entities: idx.entities.length,
    scenes: idx.scenes.length,
    arcs: idx.arcs.length,
    festivals: idx.festivals.length,
    journeys: idx.journeys.length,
    relations: idx.raw.relations.length,
    cited: idx.entities.filter((e) => e.source).length,
  }));
}

/** Distinct primary sources behind the set — shown on /about. */
export function getSources() {
  return withIndex((idx) => {
    const tally = new Map();
    for (const r of [...idx.entities, ...idx.scenes]) {
      if (!r.source?.label) continue;
      tally.set(r.source.label, (tally.get(r.source.label) ?? 0) + 1);
    }
    return [...tally.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([label, count]) => ({ label, count }));
  });
}

/** Internal: searchService needs the built index. Not part of the public API. */
export const __getIndex = getIndex;
