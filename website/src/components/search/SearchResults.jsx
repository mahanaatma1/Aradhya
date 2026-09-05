import { useMemo } from 'react';
import { SearchX } from 'lucide-react';
import EntityCard from '../cards/EntityCard.jsx';
import { CardGridSkeleton, EmptyState, ErrorState } from '../ui/States.jsx';
import { Chip } from '../ui/Chip.jsx';
import { searchContent, EXAMPLE_QUERIES } from '../../services/searchService.js';
import { FACETS } from '../../config/taxonomy.js';
import { routes } from '../../config/routes.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * Full results for /search: facet tabs across the top, then a grid of matches.
 *
 * Counts on the tabs come from the whole result set rather than the filtered
 * view, so a tab never claims to hold more than it shows — and the tabs that
 * would be empty are hidden instead of dead.
 */
export default function SearchResults({ query, facet = 'all', onFacetChange }) {
  const trimmed = query.trim();

  const { data, loading, error, reload } = useAsync(
    () => (trimmed ? searchContent(trimmed, { facet, limit: 60 }) : null),
    [trimmed, facet],
  );

  const tabs = useMemo(() => {
    const counts = data?.facetCounts ?? {};
    return FACETS.filter((f) => f.id === 'all' || f.id === facet || (counts[f.id] ?? 0) > 0).map(
      (f) => ({ ...f, count: counts[f.id] ?? 0 }),
    );
  }, [data, facet]);

  if (!trimmed) {
    return (
      <EmptyState
        title="What would you like to understand?"
        message="Search for a person, a place, a text, a festival or an idea — or browse the whole library."
        action={{ label: 'Browse the library', to: routes.explore }}
      />
    );
  }

  if (error) return <ErrorState onRetry={reload} />;

  return (
    <div>
      {/* Facet tabs */}
      <div className="no-scrollbar -mx-5 mb-8 overflow-x-auto px-5 sm:mx-0 sm:px-0">
        <div
          role="tablist"
          aria-label="Filter results"
          className="flex w-max gap-2 border-b border-ink/[0.08] pb-3 sm:w-auto sm:flex-wrap"
        >
          {tabs.map((tab) => {
            const selected = tab.id === facet;
            return (
              <button
                key={tab.id}
                type="button"
                role="tab"
                aria-selected={selected}
                onClick={() => onFacetChange(tab.id)}
                className={`flex items-center gap-2 rounded-full px-3.5 py-1.5 text-[0.84rem]
                            font-medium transition-all duration-200
                            ${
                              selected
                                ? 'bg-terra text-[#FFF4E9] shadow-card'
                                : 'text-ink-soft hover:bg-paper-2 hover:text-ink'
                            }`}
              >
                {tab.label}
                {tab.count > 0 && (
                  <span
                    className={`text-[0.72rem] font-semibold ${
                      selected ? 'text-[#FFF4E9]/70' : 'text-ink-faint'
                    }`}
                  >
                    {tab.count}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {loading && <CardGridSkeleton count={6} className="sm:grid-cols-2" />}

      {!loading && data && data.results.length === 0 && (
        <EmptyState
          icon={SearchX}
          title={`Nothing matched “${trimmed}”`}
          message="The library covers the epics, the major texts, deities, sacred places, festivals and practices. Try a name, or one of these."
          action={{ label: 'Browse the full library', to: routes.explore }}
        />
      )}

      {!loading && data && data.results.length > 0 && (
        <>
          <p className="mb-5 text-[0.84rem] text-ink-faint">
            {data.total} result{data.total === 1 ? '' : 's'}
            {facet !== 'all' && ' in this category'} for{' '}
            <span className="font-medium text-ink-soft">“{trimmed}”</span>
          </p>
          <div className="grid gap-4 sm:grid-cols-2">
            {data.results.map((record) => (
              <EntityCard key={record.id} record={record} />
            ))}
          </div>
        </>
      )}

      {/* Always leave a way back out to a working query. */}
      <div className="mt-10 flex flex-wrap items-center gap-2">
        <span className="mr-1 text-[0.78rem] text-ink-faint">Try</span>
        {EXAMPLE_QUERIES.map((q) => (
          <Chip key={q} to={`${routes.search}?q=${encodeURIComponent(q)}`}>
            {q}
          </Chip>
        ))}
      </div>
    </div>
  );
}
