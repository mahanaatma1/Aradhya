import { act, renderHook, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';

import { useAsync } from './useAsync.js';
import { clearPreload, setPreload, startCollecting, stopCollecting } from '../services/preload.js';

afterEach(() => {
  clearPreload();
  stopCollecting();
});

describe('useAsync', () => {
  it('starts in a loading state and settles with the data', async () => {
    const { result } = renderHook(() => useAsync(() => Promise.resolve('done'), []));

    expect(result.current).toMatchObject({ data: null, loading: true, error: null });
    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.data).toBe('done');
  });

  it('takes the initial value while it waits', async () => {
    const { result } = renderHook(() =>
      useAsync(() => Promise.resolve([1]), [], { initial: [] }),
    );
    expect(result.current.data).toEqual([]);
    // Let it settle inside the test: a state update that lands afterwards is
    // both an act() warning and a leak into whatever runs next.
    await waitFor(() => expect(result.current.data).toEqual([1]));
  });

  it('reports an error without leaving the caller mid-load', async () => {
    const boom = new Error('nope');
    // The hook logs failures in DEV, which is wanted behaviour and worth
    // asserting — silencing it here keeps a passing run quiet enough that
    // real output means something.
    const logged = vi.spyOn(console, 'error').mockImplementation(() => {});

    const { result } = renderHook(() => useAsync(() => Promise.reject(boom), [], { initial: [] }));

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.error).toBe(boom);
    expect(result.current.data).toEqual([]);
    expect(logged).toHaveBeenCalledWith('[useAsync]', boom);
  });

  it('re-runs when its deps change', async () => {
    const loader = vi.fn((slug) => Promise.resolve(slug));
    const { result, rerender } = renderHook(({ slug }) => useAsync(() => loader(slug), [slug]), {
      initialProps: { slug: 'rama' },
    });

    await waitFor(() => expect(result.current.data).toBe('rama'));
    rerender({ slug: 'sita' });
    await waitFor(() => expect(result.current.data).toBe('sita'));
  });

  it('does not re-run when something else re-renders the component', async () => {
    const loader = vi.fn(() => Promise.resolve('x'));
    const { result, rerender } = renderHook(() => useAsync(loader, ['fixed']));

    await waitFor(() => expect(result.current.loading).toBe(false));
    const calls = loader.mock.calls.length;
    rerender();
    rerender();
    expect(loader).toHaveBeenCalledTimes(calls);
  });

  /**
   * Fast navigation is the case this protects: page A's loader can settle after
   * page B's, and painting A's data onto B is a visible, wrong-content bug.
   */
  it('drops a stale run rather than painting the previous page’s data', async () => {
    let resolveFirst;
    const first = new Promise((resolve) => {
      resolveFirst = resolve;
    });

    const { result, rerender } = renderHook(({ slug }) => useAsync(
      () => (slug === 'rama' ? first : Promise.resolve('sita')),
      [slug],
    ), { initialProps: { slug: 'rama' } });

    rerender({ slug: 'sita' });
    await waitFor(() => expect(result.current.data).toBe('sita'));

    // The first page's loader lands late. It must not win.
    await act(async () => {
      resolveFirst('rama');
      await first;
    });
    expect(result.current.data).toBe('sita');
  });

  it('reloads on demand', async () => {
    let n = 0;
    const { result } = renderHook(() => useAsync(() => Promise.resolve(++n), []));

    await waitFor(() => expect(result.current.data).toBe(1));
    act(() => {
      result.current.reload();
    });
    await waitFor(() => expect(result.current.data).toBe(2));
  });
});

/**
 * The prerender path.
 *
 * A page whose data is inlined has to render it on the *first* render — not
 * after an effect. Anything later is a hydration mismatch, and React's answer
 * to that is to throw the server's markup away and repaint, which is the flash
 * the whole prerender exists to avoid.
 */
describe('useAsync with inlined data', () => {
  it('has its data on the first render, with no loading state at all', () => {
    setPreload({ 'record:hanuman': { title: 'Hanuman' } });

    const states = [];
    renderHook(() => {
      const state = useAsync(() => Promise.resolve(null), ['hanuman'], {
        preloadKey: 'record:hanuman',
      });
      states.push(state);
      return state;
    });

    expect(states[0]).toMatchObject({
      data: { title: 'Hanuman' },
      loading: false,
      error: null,
    });
    expect(states.every((s) => s.loading === false)).toBe(true);
  });

  it('does not call the loader at all when the value was inlined', () => {
    setPreload({ stats: { entities: 174 } });
    const loader = vi.fn(() => Promise.resolve(null));

    renderHook(() => useAsync(loader, [], { preloadKey: 'stats' }));
    expect(loader).not.toHaveBeenCalled();
  });

  it('uses an inlined null rather than reloading — absent is an answer', () => {
    setPreload({ 'record:ghost': null });
    const loader = vi.fn(() => Promise.resolve('should not run'));

    const { result } = renderHook(() =>
      useAsync(loader, [], { preloadKey: 'record:ghost' }),
    );

    expect(result.current.data).toBeNull();
    expect(result.current.loading).toBe(false);
    expect(loader).not.toHaveBeenCalled();
  });

  it('falls back to loading normally when this page inlined nothing', async () => {
    setPreload({ 'record:someone-else': { title: 'X' } });

    const { result } = renderHook(() =>
      useAsync(() => Promise.resolve('fetched'), [], { preloadKey: 'record:hanuman' }),
    );

    expect(result.current.loading).toBe(true);
    await waitFor(() => expect(result.current.data).toBe('fetched'));
  });

  it('ignores inlined data for a call that did not opt in', async () => {
    setPreload({ 'record:hanuman': { title: 'Hanuman' } });

    const { result } = renderHook(() => useAsync(() => Promise.resolve('fetched'), []));
    expect(result.current.loading).toBe(true);
    await waitFor(() => expect(result.current.data).toBe('fetched'));
  });

  /**
   * A page that arrives with data still re-runs its loader when the user
   * navigates within it — the inlined value is the first render's answer, not
   * a permanent one.
   */
  it('still re-runs when the deps change afterwards', async () => {
    setPreload({ 'record:rama': { title: 'Rama' } });

    const { result, rerender } = renderHook(
      ({ slug }) => useAsync(() => Promise.resolve({ title: slug }), [slug], {
        preloadKey: `record:${slug}`,
      }),
      { initialProps: { slug: 'rama' } },
    );

    expect(result.current.data).toEqual({ title: 'Rama' });
    rerender({ slug: 'sita' });
    await waitFor(() => expect(result.current.data).toEqual({ title: 'sita' }));
  });
});

/**
 * The build's collector.
 *
 * Only inside a server render does `useAsync` probe its loader synchronously.
 * That probe is what produces the inlined blob: whatever the page resolves, it
 * offers, so the data written into the HTML is a record of what the page
 * actually rendered rather than a hand-kept list that can drift.
 */
describe('useAsync while the build is collecting', () => {
  it('resolves a synchronous loader during render and records what it used', () => {
    startCollecting();

    const { result } = renderHook(() =>
      useAsync(() => ({ entities: 174 }), [], { preloadKey: 'stats' }),
    );

    expect(result.current).toMatchObject({ data: { entities: 174 }, loading: false });
    expect(Object.fromEntries(stopCollecting())).toEqual({ stats: { entities: 174 } });
  });

  it('records nothing for a call that did not opt in', async () => {
    startCollecting();
    const { result } = renderHook(() => useAsync(() => ({ entities: 174 }), []));
    expect(stopCollecting().size).toBe(0);
    // Un-keyed, so the value arrives through the effect even here.
    await waitFor(() => expect(result.current.data).toEqual({ entities: 174 }));
  });

  it('leaves an async loader to the normal path, and records nothing', async () => {
    startCollecting();

    const { result } = renderHook(() =>
      useAsync(() => Promise.resolve('later'), [], { preloadKey: 'stats' }),
    );

    expect(result.current.loading).toBe(true);
    expect(stopCollecting().size).toBe(0);
    await waitFor(() => expect(result.current.data).toBe('later'));
  });

  /**
   * A loader that throws during the probe must not take the render down: the
   * async path below it hits the same error and reports it properly.
   */
  it('does not let a throwing loader escape the render', async () => {
    startCollecting();
    const boom = new Error('nope');
    const logged = vi.spyOn(console, 'error').mockImplementation(() => {});

    const { result } = renderHook(() =>
      useAsync(() => {
        throw boom;
      }, [], { preloadKey: 'stats' }),
    );

    expect(stopCollecting().size).toBe(0);
    await waitFor(() => expect(result.current.error).toBe(boom));
    expect(logged).toHaveBeenCalledWith('[useAsync]', boom);
  });

  it('is off outside a render, so the browser never probes during render', async () => {
    const loader = vi.fn(() => 'sync value');
    const { result } = renderHook(() => useAsync(loader, [], { preloadKey: 'stats' }));

    // Not collecting and nothing inlined: the value arrives through the effect,
    // so the first render is a loading state exactly as it always was.
    expect(result.current.loading).toBe(true);
    await waitFor(() => expect(result.current.data).toBe('sync value'));
  });
});
