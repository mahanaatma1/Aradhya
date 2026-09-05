import { useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import EntityCard from '../components/cards/EntityCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Chip from '../components/ui/Chip.jsx';
import { CardGridSkeleton, EmptyState, ErrorState } from '../components/ui/States.jsx';
import { getFacetCounts, listRecords } from '../services/contentService.js';
import { FACETS, facetLabel } from '../config/taxonomy.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /explore — browse the whole library, filtered by facet.
 *
 * The facet is a URL parameter so "Deities" is a linkable page rather than a
 * state you have to click your way back to.
 */
export default function Explore() {
  const [params, setParams] = useSearchParams();
  const facet = params.get('facet') ?? 'all';
  const sort = params.get('sort') === 'title' ? 'title' : 'importance';

  const label = facet === 'all' ? 'Everything' : facetLabel(facet);

  // The unfiltered page is the one that gets prerendered and indexed, so its copy
  // comes from the shared config; a facet only overrides it in the browser.
  useSeo(
    facet === 'all'
      ? PAGE_META[routes.explore]
      : {
          title: `${label} — explore`,
          description: `Browse ${label.toLowerCase()} in Aradhya — curated entries drawn from public-domain texts and open datasets, each one citing where it came from.`,
        },
  );

  const { data, loading, error, reload } = useAsync(
    () => Promise.all([listRecords({ facet, sort }), getFacetCounts()]),
    [facet, sort],
  );
  const [records, counts] = data ?? [];

  const tabs = useMemo(
    () => FACETS.filter((f) => f.id === 'all' || (counts?.[f.id] ?? 0) > 0),
    [counts],
  );

  const setParam = (key, value, fallback) => {
    const next = new URLSearchParams(params);
    if (value === fallback) next.delete(key);
    else next.set(key, value);
    setParams(next, { replace: true });
  };

  return (
    <>
      <PageHeader
        eyebrow="Library"
        title="Explore"
        lead="Everything the curated set holds, in one place. Every entry keeps the text or dataset it was drawn from, so you can check it rather than take our word for it."
        meta={
          records && (
            <>
              <span>
                {records.length.toLocaleString()} {records.length === 1 ? 'entry' : 'entries'}
                {facet !== 'all' && ` in ${label.toLowerCase()}`}
              </span>
              <button
                type="button"
                onClick={() => setParam('sort', sort === 'title' ? 'importance' : 'title', 'importance')}
                className="link-quiet font-medium"
              >
                {sort === 'title' ? 'Sort by prominence' : 'Sort A–Z'}
              </button>
            </>
          )
        }
      />

      <div className="shell pb-section">
        {/* Facets. Real links, so each one is crawlable and shareable. */}
        <div className="rail-mask -mx-4 mb-10 px-4 sm:mx-0 sm:px-0">
          <div className="no-scrollbar flex gap-2 overflow-x-auto pb-1">
            {tabs.map((tab) => (
              <Chip
                key={tab.id}
                to={tab.id === 'all' ? routes.explore : `${routes.explore}?facet=${tab.id}`}
                active={tab.id === facet}
                className="shrink-0"
              >
                {tab.label}
                {counts?.[tab.id] != null && (
                  <span className="ml-1.5 text-ink-faint">{counts[tab.id]}</span>
                )}
              </Chip>
            ))}
          </div>
        </div>

        {error ? (
          <ErrorState onRetry={reload} />
        ) : loading ? (
          <CardGridSkeleton count={9} />
        ) : records.length === 0 ? (
          <EmptyState
            title={`Nothing under ${label.toLowerCase()} yet`}
            message="This facet has no entries in the current content set. The library grows as the pipeline is curated."
            action={{ label: 'Browse everything', to: routes.explore }}
          />
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {records.map((record) => (
              <EntityCard key={record.id} record={record} />
            ))}
          </div>
        )}
      </div>
    </>
  );
}
