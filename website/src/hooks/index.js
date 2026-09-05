import { useCallback, useEffect, useRef, useState } from 'react';

/** Debounce a fast-changing value (search input) before it triggers work. */
export function useDebounced(value, delay = 180) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}

/** Reactive media query. */
export function useMediaQuery(query) {
  const [matches, setMatches] = useState(
    () => typeof window !== 'undefined' && window.matchMedia(query).matches,
  );
  useEffect(() => {
    const mq = window.matchMedia(query);
    const onChange = (e) => setMatches(e.matches);
    setMatches(mq.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, [query]);
  return matches;
}

export const usePrefersReducedMotion = () =>
  useMediaQuery('(prefers-reduced-motion: reduce)');

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

export function useTheme() {
  const [theme, setTheme] = useState(
    () => document.documentElement.dataset.theme || 'light',
  );

  const apply = useCallback((next) => {
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch {
      /* private mode — the in-memory value still works for this session */
    }
    setTheme(next);
  }, []);

  const toggle = useCallback(
    () => apply(theme === 'dark' ? 'light' : 'dark'),
    [apply, theme],
  );

  return { theme, setTheme: apply, toggle, isDark: theme === 'dark' };
}
