import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { Badge } from '../ui/Chip.jsx';
import SourceNote from '../ui/SourceNote.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * The two large editorial cards for the epics.
 *
 * Colour comes from the app's category gradients, the artwork is a single large
 * glyph rather than an illustration, and the numbers underneath are counted from
 * the content set — never written by hand.
 */
export default function StoryCard({
  to,
  eyebrow,
  title,
  titleHi,
  blurb,
  meta = [],
  glyph = 'bow',
  accent = 'epics',
  className = '',
}) {
  const [from, to2] = gradientFor(accent);

  return (
    <Link
      to={to}
      className={`group relative flex min-h-[19rem] flex-col justify-end overflow-hidden rounded-xl
                  p-6 text-white shadow-lift transition-all duration-500 ease-calm
                  hover:-translate-y-1.5 hover:shadow-float sm:min-h-[22rem] sm:p-9 ${className}`}
      style={{ background: `linear-gradient(150deg, ${from}, ${to2})` }}
    >
      {/* Oversized glyph, bled off the top-right corner. */}
      <Glyph
        name={glyph}
        size={260}
        strokeWidth={0.5}
        className="pointer-events-none absolute -right-14 -top-16 text-white/[0.13]
                   transition-transform duration-700 ease-calm group-hover:scale-105
                   group-hover:text-white/[0.18]"
      />
      <span
        aria-hidden="true"
        className="pointer-events-none absolute inset-[14px] rounded-[1.1rem] border border-dashed
                   border-white/25"
      />

      <div className="relative">
        {eyebrow && <Badge tone="onColor">{eyebrow}</Badge>}
        <h3 className="mt-4 font-display text-[1.7rem] font-semibold leading-[1.1] sm:text-[2.35rem]">
          {title}
          {titleHi && (
            <span className="ml-3 font-deva text-[0.5em] font-normal text-white/70">{titleHi}</span>
          )}
        </h3>
        <p className="mt-3 max-w-md text-[0.88rem] leading-relaxed text-white/85 sm:text-[0.95rem]">
          {blurb}
        </p>

        {meta.length > 0 && (
          <dl className="mt-5 flex flex-wrap gap-x-6 gap-y-3 border-t border-white/20 pt-4 sm:mt-6 sm:gap-x-8 sm:pt-5">
            {meta.map((m) => (
              <div key={m.label}>
                <dt className="text-[0.66rem] font-semibold uppercase tracking-[0.16em] text-white/60">
                  {m.label}
                </dt>
                <dd className="mt-0.5 font-display text-lg font-semibold">{m.value}</dd>
              </div>
            ))}
          </dl>
        )}

        <span className="mt-5 inline-flex items-center gap-2 text-[0.9rem] font-medium text-white sm:mt-6">
          Start reading
          <ArrowRight
            size={16}
            strokeWidth={2}
            aria-hidden="true"
            className="transition-transform duration-300 ease-calm group-hover:translate-x-1.5"
          />
        </span>
      </div>
    </Link>
  );
}

/**
 * A single narrative scene, as it appears in reading order on an epic page.
 * `cast` links only to entities the content set actually has a page for — the
 * caller resolves the slugs and passes records.
 */
export function SceneCard({ scene, cast = [], className = '' }) {
  return (
    <article
      id={`scene-${scene.slug}`}
      className={`surface scroll-mt-28 p-5 transition-shadow duration-300 hover:shadow-lift sm:p-6 ${className}`}
    >
      <div className="flex flex-wrap items-center gap-2.5">
        <span
          className="flex h-7 w-7 items-center justify-center rounded-full bg-terra/[0.09]
                     font-display text-[0.72rem] font-semibold text-terra"
        >
          {scene.seq ?? '·'}
        </span>
        <h3 className="text-[1.08rem] leading-snug text-ink">{scene.title}</h3>
        {scene.titleHi && (
          <span className="font-deva text-[0.85rem] text-ink-faint">{scene.titleHi}</span>
        )}
      </div>

      {scene.summary && (
        <p className="mt-3 text-[0.92rem] leading-relaxed text-ink-soft">{scene.summary}</p>
      )}

      {scene.lesson && (
        <p
          className="mt-4 border-l-2 border-gold/50 pl-4 text-[0.88rem] italic leading-relaxed
                     text-ink-soft"
        >
          {scene.lesson}
        </p>
      )}

      {cast.length > 0 && (
        <div className="mt-4 flex flex-wrap items-center gap-1.5">
          {cast.map((person) => (
            <Link
              key={person.slug}
              to={person.href}
              className="chip hover:border-terra/40 hover:bg-card hover:text-terra"
            >
              <Glyph name={person.glyph} size={13} />
              {person.title}
            </Link>
          ))}
        </div>
      )}

      <SourceNote source={scene.source} className="mt-4" />
    </article>
  );
}
