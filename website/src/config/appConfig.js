/**
 * Every outward-facing constant lives here. Store listings, deep links, social
 * handles and the canonical origin are all read from this file — nothing is
 * hardcoded in a component. Swap the placeholders below when the listings go
 * live and the whole site follows.
 */

export const appConfig = {
  name: 'Aradhya',
  nameHi: 'आराध्य',
  /** Two-tone wordmark split, same as the app's Brand.nameHead / nameTail. */
  wordmark: { head: 'Ara', tail: 'dhya' },
  monogram: 'आ',
  tagline: 'Devotion, every day',
  taglineHi: 'प्रतिदिन भक्ति',
  promise: 'Explore. Understand. Practice.',

  /** Canonical origin, used for <link rel=canonical>, OG urls and the sitemap. */
  siteUrl: 'https://aradhya.app',

  /** TODO(launch): replace with the real listing URLs. */
  stores: {
    android: {
      label: 'Google Play',
      // Android application id from android/app/build.gradle.
      packageId: 'com.sumerudigital.divyavaani',
      url: 'https://play.google.com/store/apps/details?id=com.sumerudigital.divyavaani',
      available: false,
    },
    ios: {
      label: 'App Store',
      appId: '',
      url: 'https://apps.apple.com/app/aradhya/id0000000000',
      available: false,
    },
  },

  /**
   * Deep linking. `scheme` opens the installed app; `universal` is the https
   * fallback that App Links / Universal Links claim. `buildDeepLink` in
   * services/appLinks.js is the only thing that should read these.
   */
  deepLink: {
    scheme: 'aradhya',
    universal: 'https://aradhya.app/open',
    /** Route templates the app understands, keyed by website content kind. */
    routes: {
      entity: 'explore/{slug}',
      scene: 'story/{slug}',
      journey: 'journey/{slug}',
      festival: 'festival/{slug}',
      scripture: 'scripture/{slug}',
      search: 'search?q={query}',
      home: '',
    },
  },

  social: [
    { label: 'Instagram', handle: '@aradhya.app', url: 'https://instagram.com/' },
    { label: 'YouTube', handle: 'Aradhya', url: 'https://youtube.com/' },
  ],

  contactEmail: 'hello@aradhya.app',

  /**
   * Honest privacy posture. The app keeps user state on-device; the website is a
   * separate surface and gets described separately. Do not upgrade either of
   * these claims without checking the shipped build.
   */
  privacy: {
    appSummary:
      'Aradhya reads its library from files bundled inside the app. Your bookmarks, streaks, japa counts and journal entries are written to a database on your own device.',
    websiteSummary:
      'This website is a static site. It loads its content and fonts, and stores nothing about you beyond a single browser preference for light or dark reading.',
  },

  /** Feature flags for surfaces that are still mock-only. */
  flags: {
    /** Flip on once searchService points at a live API. */
    liveSearch: false,
  },
};

export default appConfig;
