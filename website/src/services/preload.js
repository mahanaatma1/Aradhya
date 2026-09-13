/**
 * Per-page data, inlined into the HTML at build time.
 *
 * This is the piece that lets the prerender emit real body text instead of an
 * empty `#root`. The problem it solves:
 *
 *   A server render can only include content the components produce on their
 *   *first* render. Every page here gets its data through `useAsync`, which is
 *   effect-driven — so without a synchronous source, a server render emits
 *   nothing but skeletons.
 *
 * So the build renders each page with the content index already warm (in Node it
 * simply is), records every keyed `useAsync` result the page asked for, and
 * writes that map into the page's HTML. The browser reads the same map back
 * before React mounts, so the client's first render is identical to the server's:
 * no hydration mismatch, and no content → skeleton → content flash.
 *
 * Only what a page actually rendered is inlined, and only calls that opted in by
 * passing a `preloadKey`. A call without one behaves exactly as it always has, on
 * the server as well as the client, which keeps the two renders in step by
 * default rather than by vigilance.
 */

/** The script element the prerender writes and the browser reads. */
export const PRELOAD_ID = 'aradhya-preload';

/** Data available for this page's first render. Empty on a client-rendered page. */
let store = null;

/** Set while the build is rendering a page, to capture what that page used. */
let collecting = null;

function readFromDocument() {
  if (typeof document === 'undefined') return new Map();
  const el = document.getElementById(PRELOAD_ID);
  if (!el?.textContent) return new Map();
  try {
    return new Map(Object.entries(JSON.parse(el.textContent)));
  } catch {
    // A truncated or hand-edited blob must not take the page down: falling
    // through to the async path costs a skeleton, not the content.
    return new Map();
  }
}

/**
 * The value inlined for `key`, or `undefined` when there is none.
 *
 * `undefined` is the only miss signal, which is why loaders here return `null`
 * rather than `undefined` for "no such record".
 */
export function preloaded(key) {
  if (!key) return undefined;
  if (!store) store = readFromDocument();
  return store.get(key);
}

/**
 * Offer a synchronously-resolved value to the build's collector.
 *
 * A no-op in the browser. On the server this is how the page's data map gets
 * built — from the render itself rather than from a hand-kept list, so the two
 * cannot drift.
 */
export function offer(key, value) {
  if (collecting && key && value !== undefined) collecting.set(key, value);
}

/**
 * True while the build is collecting — i.e. inside the server render.
 *
 * `useAsync` asks before it probes a loader synchronously during render. That
 * probe is a render-phase call into the data layer, which is fine on the server
 * (one render, no concurrency, index already warm) and something the browser
 * should never do. Gating on the collector rather than sniffing for `window`
 * keeps the condition explicit and testable: only the build turns this on.
 */
export function isCollecting() {
  return collecting !== null;
}

/** Build-time only: start recording, render, then take what the page used. */
export function startCollecting() {
  collecting = new Map();
}

export function stopCollecting() {
  const collected = collecting;
  collecting = null;
  return collected ?? new Map();
}

/**
 * Build-time only: install a page's data before rendering it.
 *
 * The server render normally resolves straight from the warm index and needs no
 * store, but seeding it makes a second render of the same page (the lazy-route
 * warm-up pass) produce identical output.
 */
export function setPreload(entries) {
  store = entries instanceof Map ? new Map(entries) : new Map(Object.entries(entries ?? {}));
}

/** Build-time only: forget the current page's data before moving to the next. */
export function clearPreload() {
  store = null;
}
