import { Link } from 'react-router-dom';
import SearchBox from '../components/search/SearchBox.jsx';
import Glyph from '../components/art/Glyph.jsx';
import Chip from '../components/ui/Chip.jsx';
import { EXAMPLE_QUERIES } from '../services/searchService.js';
import { routes } from '../config/routes.js';
import useSeo from '../hooks/useSeo.js';

/**
 * 404 — and also what a `/explore/:slug` that resolves to nothing renders.
 *
 * A missing page is a failed search, so it offers the search box rather than an
 * apology. Marked noindex so a mistyped URL cannot enter the index.
 */
export default function NotFound() {
  useSeo({
    title: 'Not found',
    description: 'That page doesn’t exist. Search Aradhya’s library instead.',
    noindex: true,
  });

  return (
    <div className="shell flex min-h-[70vh] flex-col items-center justify-center py-section text-center">
      <Glyph name="compass" size={72} strokeWidth={0.9} className="text-terra/40" />

      <p className="eyebrow mt-8">404</p>
      <h1 className="mt-3 text-display-md text-ink">This path leads nowhere.</h1>
      <p className="mt-4 max-w-md text-[1.02rem] leading-relaxed text-ink-soft">
        The page you were looking for isn’t here. It may have been renamed, or the link may have
        been wrong — try searching for it instead.
      </p>

      <div className="mt-9 w-full max-w-xl">
        <SearchBox variant="hero" autoFocus />
      </div>

      <div className="mt-7 flex flex-wrap justify-center gap-2">
        {EXAMPLE_QUERIES.slice(0, 4).map((query) => (
          <Chip key={query} to={`${routes.search}?q=${encodeURIComponent(query)}`}>
            {query}
          </Chip>
        ))}
      </div>

      <p className="mt-10 text-[0.9rem] text-ink-soft">
        Or go back to the{' '}
        <Link to={routes.home} className="link-quiet font-medium">
          home page
        </Link>{' '}
        and{' '}
        <Link to={routes.explore} className="link-quiet font-medium">
          browse the library
        </Link>
        .
      </p>
    </div>
  );
}
