import { useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import SearchBox from '../components/search/SearchBox.jsx';
import SearchResults from '../components/search/SearchResults.jsx';
import useSeo from '../hooks/useSeo.js';

/**
 * /search — the results page.
 *
 * The query and the facet live in the URL, which makes a search shareable, gives
 * the back button something to do, and means a link from Google can land
 * straight on a result set.
 */
export default function Search() {
  const [params, setParams] = useSearchParams();
  const query = params.get('q') ?? '';
  const facet = params.get('facet') ?? 'all';

  useSeo({
    title: query ? `${query} — search` : 'Search',
    description: query
      ? `Results for “${query}” across scriptures, stories, deities, places, festivals and practices in Aradhya.`
      : 'Search scriptures, deities, stories, temples, festivals and practices across Aradhya’s curated library.',
    // A results page is not something to index — the entries behind it are.
    noindex: true,
  });

  const setFacet = useCallback(
    (next) => {
      const nextParams = new URLSearchParams(params);
      if (next === 'all') nextParams.delete('facet');
      else nextParams.set('facet', next);
      setParams(nextParams, { replace: true });
    },
    [params, setParams],
  );

  return (
    <div className="pt-28 sm:pt-32">
      <div className="shell">
        <h1 className="text-display-sm text-ink">Search</h1>
        <div className="mt-5 max-w-2xl">
          <SearchBox variant="hero" initialQuery={query} autoFocus={!query} />
        </div>
      </div>

      <div className="shell mt-12 pb-section">
        <SearchResults query={query} facet={facet} onFacetChange={setFacet} />
      </div>
    </div>
  );
}
