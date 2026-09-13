import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';

/**
 * `useLayoutEffect` in the browser, `useEffect` on the server.
 *
 * The build renders these components in Node, where a layout effect never runs
 * and React warns about it. Swapping the import there keeps the console clean
 * without giving up the pre-paint timing that matters in the browser.
 */
const useIsomorphicLayoutEffect = typeof window === 'undefined' ? useEffect : useLayoutEffect;

/** Debounce a fast-changing value (search input) before it triggers work. */
export function useDebounced(value, delay = 180) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}

/**
 * Reactive media query.
 *
 * The first render always reports `false`, never the live value, even though
 * `matchMedia` is available in the browser at that point. That is deliberate:
 * prerendered pages hydrate, and Node has no viewport, so reading the real value
 * on render one would make the client's first output disagree with the HTML the
 * build wrote — React would then discard the server markup for that subtree.
 * Reporting `false` on both sides keeps them identical.
 *
 * The correction runs in a layout effect, so it lands before the browser paints
 * and the swap is not visible. Components that branch on this therefore render
 * their narrow layout once, invisibly, before settling — which is also the
 * layout a crawler reading the static HTML gets, and for a graph or a rail that
 * is the more readable of the two.
 */
export function useMediaQuery(query) {
  const [matches, setMatches] = useState(false);
  useIsomorphicLayoutEffect(() => {
    const mq = window.matchMedia(query);
    const onChange = (e) => setMatches(e.matches);
    setMatches(mq.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, [query]);
  return matches;
}

export const usePrefersReducedMotion = () => useMediaQuery('(prefers-reduced-motion: reduce)');


/** True once the page has scrolled past `threshold` — drives the nav treatment. */
export function useScrolled(threshold = 12) {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    let frame = 0;
    const onScroll = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => setScrolled(window.scrollY > threshold));
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener('scroll', onScroll);
    };
  }, [threshold]);
  return scrolled;
}

/** Freeze the page behind an open drawer or dialog, without a layout jump. */
export function useLockBodyScroll(locked) {
  useEffect(() => {
    if (!locked) return undefined;
    const { overflow, paddingRight } = document.body.style;
    const gap = window.innerWidth - document.documentElement.clientWidth;
    document.body.style.overflow = 'hidden';
    if (gap > 0) document.body.style.paddingRight = `${gap}px`;
    return () => {
      document.body.style.overflow = overflow;
      document.body.style.paddingRight = paddingRight;
    };
  }, [locked]);
}

/**
 * Reveal-on-scroll. Returns a ref to attach to the element; the observer adds
 * `.is-in` once it enters the viewport and then stops watching.
 */
export function useReveal({ threshold = 0.12, rootMargin = '0px 0px -8% 0px' } = {}) {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return undefined;
    if (!('IntersectionObserver' in window)) {
      el.classList.add('is-in');
      return undefined;
    }
    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-in');
          io.unobserve(entry.target);
        }
      },
      { threshold, rootMargin },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [threshold, rootMargin]);
  return ref;
}

/** Close on Escape, and on a click outside the returned ref. */
export function useDismiss(active, onDismiss) {
  const ref = useRef(null);
  useEffect(() => {
    if (!active) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') onDismiss();
    };
    const onPointer = (e) => {
      if (ref.current && !ref.current.contains(e.target)) onDismiss();
    };
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', onPointer);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('pointerdown', onPointer);
    };
  }, [active, onDismiss]);
  return ref;
}

/** Light/dark, persisted. Mirrors the app, which follows the system by default. */
const THEME_KEY = 'aradhya-theme';

/**
 * The theme switch.
 *
 * Note what this deliberately does *not* return: the current theme. There is no
 * React state here at all, because `html[data-theme]` is already the single
 * source of truth — the inline script in index.html sets it before first paint
 * and every themed style reads it. Mirroring it into state bought nothing and
 * cost correctness twice over: the initialiser touched `document`, which the
 * build's server render cannot do, and any component that rendered off the
 * mirror would emit light-theme markup on the server and dark-theme markup on
 * the client, breaking hydration on a prerendered page.
 *
 * So a control that needs to look different per theme does it in CSS, keyed on
 * that attribute (see `.theme-light-only` / `.theme-dark-only` in index.css).
 * That renders correctly before React mounts, rather than one frame after it.
 */
export function useTheme() {
  const setTheme = useCallback((next) => {
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch {
      /* private mode — the attribute still holds for this session */
    }
  }, []);

  // Read at click time rather than from a render-time snapshot, so this stays
  // right even if something else changed the attribute.
  const toggle = useCallback(() => {
    setTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark');
  }, [setTheme]);

  return { setTheme, toggle };
}
