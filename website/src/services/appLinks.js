/**
 * App links.
 *
 * Every "Open in Aradhya" / "Get the App" affordance goes through here so no
 * component ever contains a store URL or a URI scheme. Change appConfig.js and
 * the whole site follows.
 */

import { appConfig } from '../config/appConfig.js';

const { deepLink, stores } = appConfig;

/** 'ios' | 'android' | 'desktop' — from the UA, only used to pick a CTA. */
export function detectPlatform() {
  if (typeof navigator === 'undefined') return 'desktop';
  const ua = navigator.userAgent || '';
  if (/iPad|iPhone|iPod/.test(ua) || (ua.includes('Mac') && navigator.maxTouchPoints > 1)) {
    return 'ios';
  }
  if (/Android/i.test(ua)) return 'android';
  return 'desktop';
}

export const isMobile = () => detectPlatform() !== 'desktop';

/**
 * Build the in-app destination for a piece of content.
 * @param {{kind?: string, slug?: string, query?: string, universal?: boolean}} target
 */
export function buildDeepLink(target = {}) {
  const { kind = 'home', slug = '', query = '', universal = false } = target;

  const template = deepLink.routes[kind] ?? deepLink.routes.home;
  const path = template
    .replace('{slug}', encodeURIComponent(slug))
    .replace('{query}', encodeURIComponent(query));

  return universal
    ? `${deepLink.universal}/${path}`.replace(/\/+$/, '')
    : `${deepLink.scheme}://${path}`;
}

/** Store URL for a platform; falls back to the Play listing on desktop. */
export function getStoreUrl(platform = detectPlatform()) {
  if (platform === 'ios') return stores.ios.url;
  return stores.android.url;
}

/** True when at least one listing is live — gates the download buttons. */
export const hasLiveStore = () => stores.android.available || stores.ios.available;

/**
 * Try the app, fall back to the store.
 *
 * There is no reliable cross-browser way to detect whether a custom scheme
 * resolved, so this uses the usual heuristic: navigate to the scheme, and if the
 * page is still visible a moment later assume nothing handled it and send the
 * visitor to the store instead.
 */
export function openInApp(target = {}, { fallbackDelay = 1200 } = {}) {
  if (typeof window === 'undefined') return () => {};

  const started = Date.now();
  const timer = window.setTimeout(() => {
    // Still here, and the tab never went to the background: no app installed.
    if (document.visibilityState === 'visible' && Date.now() - started < fallbackDelay + 400) {
      window.location.href = getStoreUrl();
    }
  }, fallbackDelay);

  const cancel = () => window.clearTimeout(timer);
  document.addEventListener('visibilitychange', cancel, { once: true });
  window.addEventListener('pagehide', cancel, { once: true });

  window.location.href = buildDeepLink(target);
  return cancel;
}

/** Kind understood by the app, derived from a website content record. */
export function deepLinkKindFor(record) {
  switch (record?.kind) {
    case 'scene':
    case 'arc':
      return 'scene';
    case 'journey':
      return 'journey';
    case 'festival':
      return 'festival';
    case 'collection':
      return 'scripture';
    default:
      return 'entity';
  }
}

export default { buildDeepLink, openInApp, getStoreUrl, detectPlatform, isMobile };
