/**
 * One route manifest, three consumers: the router (src/App.jsx), the navigation
 * (Navbar/Footer) and the sitemap generator (scripts/generate-sitemap.mjs).
 * Adding a page here is enough to get it linked and indexed.
 */

export const routes = {
  home: '/',
  search: '/search',
  explore: '/explore',
  entity: (slug) => `/explore/${slug}`,
  scriptures: '/scriptures',
  stories: '/stories',
  ramayana: '/ramayana',
  mahabharata: '/mahabharata',
  temples: '/temples',
  practices: '/practices',
  journeys: '/journeys',
  about: '/about',
  privacy: '/privacy',
  terms: '/terms',
};

/** Primary navigation, in the order the header shows it. */
export const primaryNav = [
  { label: 'Explore', to: routes.explore },
  { label: 'Scriptures', to: routes.scriptures },
  { label: 'Stories', to: routes.stories },
  { label: 'Temples', to: routes.temples },
  { label: 'Practices', to: routes.practices },
  { label: 'Journeys', to: routes.journeys },
];

/** Footer columns. Deep links point at real routes and real content slugs. */
export const footerNav = [
  {
    heading: 'Explore',
    links: [
      { label: 'Scriptures', to: routes.scriptures },
      { label: 'Ramayana', to: routes.ramayana },
      { label: 'Mahabharata', to: routes.mahabharata },
      { label: 'Temples', to: routes.temples },
      { label: 'Deities', to: `${routes.explore}?facet=deities` },
      { label: 'Festivals', to: `${routes.explore}?facet=festivals` },
    ],
  },
  {
    heading: 'Practice',
    links: [
      { label: 'Meditation', to: `${routes.practices}#dhyana` },
      { label: 'Japa', to: `${routes.practices}#japa` },
      { label: 'Breathing', to: `${routes.practices}#pranayama` },
      { label: 'Puja', to: `${routes.practices}#puja` },
      { label: 'Journal', to: `${routes.practices}#journal` },
    ],
  },
  {
    heading: 'Learn',
    links: [
      { label: 'Journeys', to: routes.journeys },
      { label: 'Quiz', to: `${routes.journeys}#quiz` },
      { label: 'Trivia', to: `${routes.journeys}#trivia` },
      { label: 'Dharma', to: routes.entity('dharma') },
    ],
  },
  {
    heading: 'Company',
    links: [
      { label: 'About', to: routes.about },
      { label: 'Privacy', to: routes.privacy },
      { label: 'Terms', to: routes.terms },
      { label: 'Contact', to: `${routes.about}#contact` },
    ],
  },
];

/**
 * Static pages for the sitemap, with the priority/changefreq they deserve.
 * Entity pages are appended by the generator from the content set.
 */
export const staticSitemapEntries = [
  { path: routes.home, priority: 1.0, changefreq: 'weekly' },
  { path: routes.explore, priority: 0.9, changefreq: 'weekly' },
  { path: routes.scriptures, priority: 0.9, changefreq: 'monthly' },
  { path: routes.stories, priority: 0.9, changefreq: 'monthly' },
  { path: routes.ramayana, priority: 0.9, changefreq: 'monthly' },
  { path: routes.mahabharata, priority: 0.9, changefreq: 'monthly' },
  { path: routes.temples, priority: 0.8, changefreq: 'monthly' },
  { path: routes.practices, priority: 0.8, changefreq: 'monthly' },
  { path: routes.journeys, priority: 0.8, changefreq: 'monthly' },
  { path: routes.about, priority: 0.5, changefreq: 'yearly' },
  { path: routes.privacy, priority: 0.3, changefreq: 'yearly' },
  { path: routes.terms, priority: 0.3, changefreq: 'yearly' },
];

export default routes;
