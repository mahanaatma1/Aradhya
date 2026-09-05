import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * Run an async loader and expose {data, loading, error, reload}.
 *
 * Used for every contentService call, which is what gives the site its real
 * loading states instead of a blank flash. Results from a stale run are dropped,
 * so fast navigation can't paint the previous page's data.
 */
export function useAsync(loader, deps = [], { initial = null } = {}) {
  const [state, setState] = useState({ data: initial, loading: true, error: null });
  const runId = useRef(0);

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const run = useCallback(loader, deps);

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

  useEffect(execute, [execute]);

  return { ...state, reload: execute };
}

export default useAsync;
