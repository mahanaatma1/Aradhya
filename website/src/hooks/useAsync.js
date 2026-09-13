import { useCallback, useEffect, useRef, useState } from 'react';

import { isCollecting, offer, preloaded } from '../services/preload.js';

/**
 * Data this call can have on its very first render, or `undefined` if none.
 *
 * Two sources, in order:
 *
 *   1. The blob the build inlined into this page's HTML. This is the browser's
 *      only source, and it is what makes hydration match the prerendered body.
 *   2. A synchronous probe of the loader — but only inside the build's render,
 *      where the content index is warm and a `contentService` accessor returns a
 *      plain value rather than a promise. That call is also what *produces* the
 *      blob: whatever the page resolves, it offers to the collector, so the
 *      inlined data is a record of what the page actually rendered and cannot
 *      drift from it.
 *
 * A promise means the data is not ready, so the caller falls through to the
 * normal effect-driven path and shows its loading state, exactly as before.
 */
function resolveSync(preloadKey, loader) {
  if (!preloadKey) return undefined;

  const inlined = preloaded(preloadKey);
  if (inlined !== undefined) return inlined;
  if (!isCollecting()) return undefined;

  let value;
  try {
    value = loader();
  } catch {
    // Let the async path below hit the same error and report it properly.
    return undefined;
  }
  if (value === undefined || typeof value?.then === 'function') return undefined;

  offer(preloadKey, value);
  return value;
}

/**
 * Run an async loader and expose {data, loading, error, reload}.
 *
 * Used for every contentService call, which is what gives the site its real
 * loading states instead of a blank flash. Results from a stale run are dropped,
 * so fast navigation can't paint the previous page's data.
 *
 * Pass a `preloadKey` (from `contentService.contentKeys`) to opt this call into
 * build-time inlining: the prerender records what it resolved to and writes it
 * into the page's HTML, and here that value becomes the *first* render's data —
 * so the prerendered body hydrates without a mismatch and without a
 * content → skeleton → content flash. See services/preload.js.
 *
 * Opting in is per-call and deliberate. Without a key the hook behaves exactly
 * as it always has, on the server as well as in the browser, so an un-keyed call
 * on a prerendered page cannot desynchronise the two renders.
 */
export function useAsync(loader, deps = [], { initial = null, preloadKey = null } = {}) {
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const run = useCallback(loader, deps);

  const [state, setState] = useState(() => {
    const ready = resolveSync(preloadKey, loader);
    return ready === undefined
      ? { data: initial, loading: true, error: null }
      : { data: ready, loading: false, error: null };
  });

  const runId = useRef(0);

  /**
   * The loader the first render already had data for.
   *
   * Comparing against the current `run` — rather than flipping a one-shot flag —
   * is what makes the skip survive StrictMode's mount/unmount/remount without
   * also swallowing a genuine deps change: same loader, nothing to do; different
   * loader, real run.
   */
  const settledFor = useRef(state.loading ? null : run);

  const execute = useCallback(() => {
    const id = ++runId.current;
    setState((s) => ({ ...s, loading: true, error: null }));
    Promise.resolve()
      .then(run)
      .then((data) => {
        if (id === runId.current) setState({ data, loading: false, error: null });
      })
      .catch((error) => {
        if (id === runId.current) setState({ data: initial, loading: false, error });
        if (import.meta.env.DEV) console.error('[useAsync]', error);
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [run]);

  useEffect(() => {
    if (settledFor.current === run) return;
    execute();
  }, [execute, run]);

  return { ...state, reload: execute };
}

export default useAsync;
