/**
 * SEO copy and tag computation, in plain JS so two very different callers can
 * share it:
 *
 *   - `hooks/useSeo.js` applies the result to document.head at runtime.
 *   - `scripts/prerender.mjs` writes the same tags into static HTML at build
 *     time, running in plain Node with no JSX transform.
 *
 * That second caller is why the page copy lives here rather than inline in each
 * page component: a prerendered <title> that disagrees with the one the app sets
 * a moment later is worse than having no prerender at all.
 */

import { appConfig } from './appConfig.js';
import { routes } from './routes.js';

export const DEFAULT_DESCRIPTION =
  'Search and explore India’s spiritual heritage — scriptures, epics, deities, sacred places, festivals and daily practice, with a source on every entry.';

/**
 * The share card. A raster file, not the SVG it is drawn from — most unfurlers
 * will not render SVG. Regenerate with `npm run og` after editing the SVG.
 */
export const OG_IMAGE = '/og-image.png';
export const OG_IMAGE_SIZE = { width: 1200, height: 630 };

/** Describes the card itself, which is the same brand card on every page. */
export const OG_IMAGE_ALT = 'Aradhya — Explore India’s Spiritual Wisdom';

/**
 * Title and description for every route whose copy is fixed.
 *
 * Content routes (`/explore/:slug`) are absent on purpose — their metadata comes
 * from the record itself, so it can never contradict the page. `/search` and
 * `/404` are absent because neither is indexed.
 */
export const PAGE_META = {
  [routes.home]: {
    // Home takes the brand-first title, so it deliberately has no page name.
    title: null,
    description:
      'Search India’s spiritual heritage — scriptures, the Ramayana and Mahabharata, deities, sacred places, festivals and daily practice. Every entry keeps its source. Free, offline app for Android and iOS.',
  },
  [routes.explore]: {
    title: 'Explore',
    description:
      'Browse everything in Aradhya’s curated library — deities, people, places, scriptures, festivals, stories and practices, each with its source.',
  },
  [routes.scriptures]: {
    title: 'Scriptures',
    description:
      'The Bhagavad Gita, Vedas, Upanishads, Puranas, stotras and mantras — how each text is shaped, and where to begin with it.',
  },
  [routes.stories]: {
    title: 'Stories',
    description:
      'The Ramayana and the Mahabharata, broken into books, arcs and single events — with the cast of each, and a source on every entry.',
  },
  [routes.temples]: {
    title: 'Temples & sacred places',
    description:
      'Char Dham, the Jyotirlingas, Shakti Peethas and the cities along the sacred rivers — why each place matters and which stories happened there.',
  },
  [routes.practices]: {
    title: 'Practices',
    description:
      'Meditation, japa, breathing, puja and reflection — the daily practices in Aradhya, and how each one works. Counts and journal entries stay on your device.',
  },
  [routes.journeys]: {
    title: 'Journeys',
    description:
      'Guided paths through Indian spiritual knowledge — a few minutes at a time, in an order that builds. Plus quizzes, trivia and riddles to make it stick.',
  },
  [routes.about]: {
    title: 'About',
    description:
      'What Aradhya is, where its content comes from, and the rules it follows: every entry cites a public-domain source, and where traditions differ it says so.',
  },
  [routes.privacy]: {
    title: 'Privacy',
    description:
      'Precisely what Aradhya’s app and website do with data: an on-device database, one browser preference, no analytics, and the one third-party request the site makes.',
  },
  [routes.terms]: {
    title: 'Terms of use',
    description:
      'Plain-language terms for Aradhya: free to use, educational rather than authoritative, public-domain sources cited on every entry, and provided as it is.',
  },
};

/**
 * Compute every head tag for one page.
 *
 * Returns data rather than DOM or HTML, so the runtime hook and the prerender
 * can each render it their own way and cannot drift apart.
 *
 * @param {{title?: string|null, description?: string, image?: string,
 *   type?: string, noindex?: boolean, pathname?: string}} options
 */
export function buildMeta({
  title,
  description = DEFAULT_DESCRIPTION,
  image,
  type = 'website',
  noindex = false,
  pathname = '/',
} = {}) {
  // "Hanuman — Aradhya", and "Aradhya — Explore. Understand. Practice." at root.
  const fullTitle = title
    ? `${title} — ${appConfig.name}`
    : `${appConfig.name} — ${appConfig.promise}`;
  const url = `${appConfig.siteUrl}${pathname}`;
  const ogImage = `${appConfig.siteUrl}${image ?? OG_IMAGE}`;

  return {
    title: fullTitle,
    canonical: url,
    /** <meta name="…"> */
    names: {
      description,
      robots: noindex ? 'noindex, follow' : 'index, follow',
      'twitter:card': 'summary_large_image',
      'twitter:title': fullTitle,
      'twitter:description': description,
      'twitter:image': ogImage,
    },
    /** <meta property="…"> */
    properties: {
      'og:title': fullTitle,
      'og:description': description,
      'og:type': type,
      'og:url': url,
      'og:image': ogImage,
      'og:image:width': String(OG_IMAGE_SIZE.width),
      'og:image:height': String(OG_IMAGE_SIZE.height),
      'og:image:alt': OG_IMAGE_ALT,
      'og:site_name': appConfig.name,
      'og:locale': 'en_IN',
    },
  };
}

export default buildMeta;

/**
 * The site-wide WebSite node, with the search action that lets Google offer a
 * sitelinks searchbox. Home only — repeating it on every page is not useful.
 */
export function siteJsonLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: appConfig.name,
    alternateName: appConfig.nameHi || undefined,
    url: appConfig.siteUrl,
    description: appConfig.promise,
    potentialAction: {
      '@type': 'SearchAction',
      target: `${appConfig.siteUrl}${routes.search}?q={search_term_string}`,
      'query-input': 'required name=search_term_string',
    },
  };
}

/**
 * Structured data for one content record.
 *
 * Lives here rather than in EntityDetail.jsx so the prerender can emit the same
 * node the page would, from the same normalised record. Only fields the record
 * actually has are included — an absent citation stays absent rather than
 * becoming an empty string.
 *
 * @param {object} record a normalised record from contentService
 */
export function entityJsonLd(record) {
  const node = {
    '@context': 'https://schema.org',
    '@type': record.kind === 'festival' ? 'Event' : 'DefinedTerm',
    name: record.title,
    alternateName: record.titleHi || undefined,
    description: record.summary,
    url: `${appConfig.siteUrl}${record.href}`,
    inDefinedTermSet: record.kind === 'festival' ? undefined : `${appConfig.siteUrl}${routes.explore}`,
  };

  if (record.source?.label) {
    node.citation = record.source.section
      ? `${record.source.label}, ${record.source.section}`
      : record.source.label;
  }
  return node;
}
