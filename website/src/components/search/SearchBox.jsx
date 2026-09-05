import { useCallback, useEffect, useId, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Loader2, Search, X } from 'lucide-react';
import SearchSuggestion from './SearchSuggestion.jsx';
import { getStartingPoints, searchContent } from '../../services/searchService.js';
import { routes } from '../../config/routes.js';
import { useDebounced, useDismiss } from '../../hooks/index.js';

/**
 * The search control — the most important element on the site.
 *
 * A combobox, implemented to the ARIA pattern: the input owns the listbox,
 * ↑/↓ move the selection, Enter opens it, Escape closes, and every option is
 * also a real link. Results are grouped by category, with a trailing
 * "See all results" row that hands off to /search.
 *
 * Nothing here knows where results come from — `searchContent` is the seam.
 */

const PLACEHOLDER = 'Search scriptures, deities, stories, temples, festivals...';

/** How many suggestions the dropdown shows before deferring to the results page. */
const MAX_SUGGESTIONS = 7;

export default function SearchBox({
  variant = 'hero',
  autoFocus = false,
  initialQuery = '',
  placeholder = PLACEHOLDER,
  onNavigate,
  className = '',
}) {
  const navigate = useNavigate();
  const listboxId = useId();
  const inputRef = useRef(null);
  const listRef = useRef(null);

  const [query, setQuery] = useState(initialQuery);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [groups, setGroups] = useState([]);
  const [total, setTotal] = useState(0);
  const [starting, setStarting] = useState([]);
  const [active, setActive] = useState(-1);

  const debounced = useDebounced(query, 150);
  const hasQuery = debounced.trim().length > 0;
  const wrapRef = useDismiss(open, () => setOpen(false));

  const hero = variant === 'hero';

  /* Well-known entry points for the empty state, resolved against real content. */
  useEffect(() => {
    if (!open || starting.length) return;
    let live = true;
    getStartingPoints().then((rows) => {
      if (live) setStarting(rows);
    });
    return () => {
      live = false;
    };
  }, [open, starting.length]);

  /* Query → suggestions. The runId guard keeps a slow response from overwriting
     a newer one. */
  useEffect(() => {
    if (!hasQuery) {
      setGroups([]);
      setTotal(0);
      setLoading(false);
      return undefined;
    }
    let live = true;
    setLoading(true);
    searchContent(debounced, { limit: 24, groupLimit: 3 })
      .then((res) => {
        if (!live) return;
        // Trim across groups so the panel stays a glance, not a page.
        let budget = MAX_SUGGESTIONS;
        const trimmed = [];
        for (const group of res.groups) {
          if (budget <= 0) break;
          const items = group.items.slice(0, budget);
          budget -= items.length;
          trimmed.push({ ...group, items });
        }
        setGroups(trimmed);
        setTotal(res.total);
        setActive(trimmed.length ? 0 : -1);
      })
      .catch(() => {
        if (live) {
          setGroups([]);
          setTotal(0);
        }
      })
      .finally(() => {
        if (live) setLoading(false);
      });
    return () => {
      live = false;
    };
  }, [debounced, hasQuery]);

  /** Flat option list, in the order the keyboard walks it. */
  const options = useMemo(() => {
    if (!hasQuery) return starting.map((record) => ({ kind: 'record', record }));
    const rows = groups.flatMap((g) => g.items.map((record) => ({ kind: 'record', record })));
    if (total > 0) rows.push({ kind: 'all' });
    return rows;
  }, [hasQuery, starting, groups, total]);

  useEffect(() => {
    if (active >= options.length) setActive(options.length - 1);
  }, [options.length, active]);

  /* Keep the highlighted option in view when arrowing through a long list. */
  useEffect(() => {
    if (!open) return;
    listRef.current?.querySelector('[data-active="true"]')?.scrollIntoView({ block: 'nearest' });
  }, [active, open]);

  const close = useCallback(() => {
    setOpen(false);
    setActive(-1);
  }, []);

  const goToResults = useCallback(
    (q) => {
      const term = (q ?? query).trim();
      if (!term) return;
      close();
      inputRef.current?.blur();
      navigate(`${routes.search}?q=${encodeURIComponent(term)}`);
      onNavigate?.();
    },
    [query, close, navigate, onNavigate],
  );

  const choose = useCallback(
    (option) => {
      if (!option) return goToResults();
      if (option.kind === 'all') return goToResults();
      close();
      inputRef.current?.blur();
      navigate(option.record.href);
      onNavigate?.();
      return undefined;
    },
    [close, goToResults, navigate, onNavigate],
  );

  function onKeyDown(event) {
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      if (!open) {
        setOpen(true);
        return;
      }
      if (!options.length) return;
      const step = event.key === 'ArrowDown' ? 1 : -1;
      setActive((i) => (i + step + options.length) % options.length);
      return;
    }
    if (event.key === 'Enter') {
      event.preventDefault();
      choose(open && active >= 0 ? options[active] : null);
      return;
    }
    if (event.key === 'Escape') {
      if (open) {
        event.stopPropagation();
        close();
      }
      return;
    }
    if (event.key === 'Tab') close();
  }

  const showPanel = open && (hasQuery || starting.length > 0);
  let optionIndex = -1;

  return (
    <div ref={wrapRef} className={`relative ${className}`}>
      <form
        role="search"
        onSubmit={(e) => {
          e.preventDefault();
          choose(open && active >= 0 ? options[active] : null);
        }}
      >
        <div
          className={`group relative flex items-center gap-3 rounded-full border bg-card
                      transition-all duration-300 ease-calm
                      ${
                        showPanel
                          ? 'border-terra/35 shadow-float'
                          : 'border-ink/12 shadow-card hover:border-terra/25 hover:shadow-lift'
                      }
                      ${hero ? 'h-[3.9rem] pl-5 pr-2 sm:h-[4.35rem] sm:pl-7 sm:pr-3' : 'h-11 pl-4 pr-1.5'}`}
        >
          <Search
            size={hero ? 21 : 17}
            strokeWidth={1.9}
            aria-hidden="true"
            className="shrink-0 text-ink-faint transition-colors duration-300 group-focus-within:text-terra"
          />

          <input
            ref={inputRef}
            type="search"
            role="combobox"
            aria-expanded={showPanel}
            aria-controls={listboxId}
            aria-autocomplete="list"
            aria-activedescendant={
              showPanel && active >= 0 ? `${listboxId}-opt-${active}` : undefined
            }
            aria-label="Search Aradhya"
            autoComplete="off"
            autoCorrect="off"
            spellCheck="false"
            // eslint-disable-next-line jsx-a11y/no-autofocus
            autoFocus={autoFocus}
            enterKeyHint="search"
            placeholder={placeholder}
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setOpen(true);
            }}
            onFocus={() => setOpen(true)}
            onKeyDown={onKeyDown}
            className={`min-w-0 flex-1 bg-transparent text-ink outline-none placeholder:text-ink-faint/80
                        [&::-webkit-search-cancel-button]:hidden
                        ${hero ? 'text-[0.98rem] sm:text-[1.06rem]' : 'text-[0.9rem]'}`}
          />

          {loading && (
            <Loader2
              size={16}
              className="shrink-0 animate-spin text-ink-faint"
              aria-hidden="true"
            />
          )}

          {query && !loading && (
            <button
              type="button"
              onClick={() => {
                setQuery('');
                inputRef.current?.focus();
              }}
              aria-label="Clear search"
              className="shrink-0 rounded-full p-1.5 text-ink-faint transition-colors
                         hover:bg-ink/[0.06] hover:text-ink"
            >
              <X size={15} strokeWidth={2} aria-hidden="true" />
            </button>
          )}

          <button
            type="submit"
            aria-label="Search"
            className={`shrink-0 rounded-full bg-terra text-[#FFF4E9] transition-all duration-300
                        ease-calm hover:bg-terra-dark active:scale-95
                        ${hero ? 'h-11 w-11 sm:h-12 sm:w-12' : 'h-8 w-8'}
                        flex items-center justify-center`}
          >
            <ArrowRight size={hero ? 19 : 15} strokeWidth={2} aria-hidden="true" />
          </button>
        </div>
      </form>

      {/* Dropdown */}
      <div
        ref={listRef}
        id={listboxId}
        role="listbox"
        aria-label="Search suggestions"
        className={`absolute left-0 right-0 top-[calc(100%+0.6rem)] z-40 max-h-[26rem] overflow-y-auto
                    rounded-lg border border-ink/[0.09] bg-card p-1.5 shadow-float
                    transition-all duration-200 ease-calm
                    ${
                      showPanel
                        ? 'pointer-events-auto translate-y-0 opacity-100'
                        : 'pointer-events-none -translate-y-1 opacity-0'
                    }`}
        hidden={!showPanel}
      >
        {!hasQuery && starting.length > 0 && (
          <p className="px-3 pb-1.5 pt-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-ink-faint">
            Start anywhere
          </p>
        )}

        {!hasQuery &&
          starting.map((record) => {
            optionIndex += 1;
            const i = optionIndex;
            return (
              <SearchSuggestion
                key={record.id}
                id={`${listboxId}-opt-${i}`}
                record={record}
                active={i === active}
                onHover={() => setActive(i)}
                onSelect={close}
              />
            );
          })}

        {hasQuery &&
          groups.map((group) => (
            <div key={group.facet}>
              <p className="px-3 pb-1.5 pt-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-ink-faint">
                {group.label}
              </p>
              {group.items.map((record) => {
                optionIndex += 1;
                const i = optionIndex;
                return (
                  <SearchSuggestion
                    key={record.id}
                    id={`${listboxId}-opt-${i}`}
                    record={record}
                    active={i === active}
                    onHover={() => setActive(i)}
                    onSelect={close}
                  />
                );
              })}
            </div>
          ))}

        {hasQuery && !loading && total === 0 && (
          <div className="px-4 py-6 text-center">
            <p className="text-[0.92rem] font-medium text-ink">No match for “{debounced.trim()}”</p>
            <p className="mt-1.5 text-[0.82rem] leading-relaxed text-ink-soft">
              Try a name — Hanuman, Kurukshetra, Ekadashi — or open the full library.
            </p>
          </div>
        )}

        {hasQuery &&
          total > 0 &&
          (() => {
            optionIndex += 1;
            const i = optionIndex;
            return (
              <button
                type="button"
                id={`${listboxId}-opt-${i}`}
                role="option"
                aria-selected={i === active}
                data-active={i === active || undefined}
                onMouseMove={() => setActive(i)}
                onClick={() => goToResults()}
                className={`mt-1 flex w-full items-center justify-between gap-3 rounded-md border-t
                            border-ink/[0.07] px-3.5 py-3 text-left text-[0.86rem] font-medium
                            text-terra transition-colors duration-150
                            ${i === active ? 'bg-terra/[0.07]' : 'hover:bg-paper-2/70'}`}
              >
                See all {total} result{total === 1 ? '' : 's'}
                <ArrowRight size={15} strokeWidth={2} aria-hidden="true" />
              </button>
            );
          })()}
      </div>
    </div>
  );
}
