import { Link } from 'react-router-dom';
import { Download, Sparkles } from 'lucide-react';
import SearchBox from './SearchBox.jsx';
import Button from '../ui/Button.jsx';
import { Chip } from '../ui/Chip.jsx';
import Mandala from '../art/Mandala.jsx';
import { EXAMPLE_QUERIES } from '../../services/searchService.js';
import { getStats } from '../../services/contentService.js';
import { routes } from '../../config/routes.js';
import { appConfig } from '../../config/appConfig.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * The hero.
 *
 * Search is the point of this section, so everything else is sized to lead the
 * eye to it: the headline is short, the copy is one sentence, the CTAs sit below
 * the bar rather than above it, and the sacred-geometry backdrop is held at low
 * opacity behind a soft radial fade.
 */
export default function HeroSearch() {
  const { data: stats } = useAsync(() => getStats(), []);

  return (
    <section className="relative overflow-hidden pb-16 pt-28 sm:pb-20 sm:pt-32 lg:pt-40">
      {/* Backdrop: warm wash + turning yantra, both far behind the content. */}
      <div aria-hidden="true" className="pointer-events-none absolute inset-0 -z-10">
        <div
          className="absolute inset-x-0 top-0 h-[36rem] bg-gradient-to-b from-paper-3/80
                     via-paper/40 to-transparent"
        />
        <Mandala
          accent="rgb(var(--terra))"
          className="absolute left-1/2 top-[-14rem] h-[46rem] w-[46rem] -translate-x-1/2
                     opacity-[0.09] sm:h-[56rem] sm:w-[56rem] dark:opacity-[0.13]"
        />
        {/* Fades the geometry out exactly where the search bar sits. */}
        <div
          className="absolute inset-0"
          style={{
            background:
              'radial-gradient(58% 42% at 50% 46%, rgb(var(--paper) / 0.92) 32%, transparent 78%)',
          }}
        />
      </div>

      <div className="shell">
        <div className="mx-auto max-w-3xl text-center">
          <Link
            to={routes.about}
            className="group inline-flex items-center gap-2 rounded-full border border-ink/10
                       bg-card/70 px-4 py-1.5 text-[0.76rem] font-medium text-ink-soft backdrop-blur
                       transition-colors duration-300 hover:border-terra/30 hover:text-terra"
          >
            <Sparkles size={13} strokeWidth={1.9} className="text-terra" aria-hidden="true" />
            {appConfig.promise}
          </Link>

          <h1 className="mt-7 text-display-xl text-ink">
            Explore India’s
            <br className="hidden sm:block" />{' '}
            <span className="relative whitespace-nowrap">
              Spiritual Wisdom.
              {/* A hand-drawn underline rather than a highlight block. */}
              <svg
                viewBox="0 0 300 12"
                preserveAspectRatio="none"
                aria-hidden="true"
                className="absolute -bottom-1.5 left-0 h-2.5 w-full text-terra/35"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.4"
                strokeLinecap="round"
              >
                <path d="M3 8c48-4.5 96-6 149-5.5S252 5 297 8.5" />
              </svg>
            </span>
          </h1>

          <p className="mx-auto mt-7 max-w-2xl text-[1.02rem] leading-relaxed text-ink-soft sm:text-[1.1rem]">
            Scriptures, stories, temples, traditions and daily practices — thoughtfully brought
            together in one offline spiritual companion.
          </p>
        </div>

        {/* The search bar. */}
        <div className="mx-auto mt-10 max-w-2xl sm:mt-12">
          <SearchBox variant="hero" />

          <div className="mt-5 flex flex-wrap items-center justify-center gap-2">
            <span className="mr-1 text-[0.78rem] text-ink-faint">Try</span>
            {EXAMPLE_QUERIES.map((q) => (
              <Chip key={q} to={`${routes.search}?q=${encodeURIComponent(q)}`}>
                {q}
              </Chip>
            ))}
          </div>
        </div>

        <div className="mt-11 flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4">
          <Button to={routes.explore} size="lg" withArrow className="w-full sm:w-auto">
            Explore {appConfig.name}
          </Button>
          <Button
            href="#get-the-app"
            variant="secondary"
            size="lg"
            icon={Download}
            className="w-full sm:w-auto"
          >
            Get the App
          </Button>
        </div>

        {/* A quiet trust line, counted from the content set rather than claimed. */}
        <p className="mt-9 text-center text-[0.78rem] text-ink-faint">
          {stats
            ? `${stats.entities} people, places and ideas · ${stats.scenes} story events · ${stats.cited} cited entries`
            : 'Curated, cited and free to read'}
        </p>
      </div>
    </section>
  );
}
