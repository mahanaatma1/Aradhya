import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * A scripture collection — Gita, Upanishads, Vedas, Puranas, Stotras, Mantras.
 *
 * The card describes what the collection is and where it sits in the tradition.
 * It carries no verse text: quotations only ever come from the curated set with
 * their citation attached, so there is nothing to fabricate here.
 */
export default function ScriptureCard({ collection, className = '' }) {
  const [from, to] = gradientFor(collection.accent);

  return (
    <Link
      id={collection.slug ?? collection.id}
      to={collection.href}
      className={`surface stitch group relative flex flex-col scroll-mt-28 overflow-hidden p-5
                  transition-all duration-300 ease-calm hover:-translate-y-1
                  hover:border-terra/25 hover:shadow-lift sm:p-6 ${className}`}
    >
      <span
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 top-0 h-[3px] opacity-70"
        style={{ background: `linear-gradient(90deg, ${from}, ${to})` }}
      />

      <div className="flex items-start justify-between gap-4">
        <span
          className="flex h-11 w-11 items-center justify-center rounded-md text-white/90
                     transition-transform duration-300 ease-calm group-hover:-translate-y-0.5
                     sm:h-12 sm:w-12"
          style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
        >
          <Glyph name={collection.glyph} size={21} />
        </span>
        <ArrowUpRight
          size={16}
          strokeWidth={1.8}
          aria-hidden="true"
          className="mt-1 text-ink-faint opacity-0 transition-all duration-300 ease-calm
                     group-hover:translate-x-0.5 group-hover:text-terra group-hover:opacity-100"
        />
      </div>

      <h3 className="mt-4 text-[1.08rem] text-ink sm:mt-5 sm:text-[1.2rem]">
        {collection.title}
        {collection.titleHi && (
          <span className="ml-2.5 font-deva text-[0.72em] font-normal text-ink-faint">
            {collection.titleHi}
          </span>
        )}
      </h3>
      {/* Clamped in the rail so a long summary can't make one card twice the
          height of its neighbours; the grid has the room to show it all. */}
      <p
        className="mt-2 line-clamp-3 text-[0.85rem] leading-relaxed text-ink-soft
                   sm:line-clamp-none sm:text-[0.9rem]"
      >
        {collection.summary}
      </p>

      {/* Says plainly where the full text lives, instead of implying it is here. */}
      <p
        className="mt-auto pt-4 text-[0.72rem] font-medium uppercase tracking-[0.13em] text-ink-faint
                   sm:pt-5 sm:text-[0.76rem]"
      >
        {collection.entitySlug ? 'Read the overview' : 'Full text in the app'}
      </p>
    </Link>
  );
}
