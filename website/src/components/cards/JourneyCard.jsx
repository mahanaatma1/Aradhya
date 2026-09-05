import { Link } from 'react-router-dom';
import { ArrowRight, Clock, Footprints } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { Badge } from '../ui/Chip.jsx';
import { LEVEL_LABELS, gradientFor } from '../../config/taxonomy.js';

/**
 * A curated journey: a small number of readings in a deliberate order.
 *
 * The step track is a preview of the path, not a record of the reader's progress
 * — progress belongs to the app, where it is stored on the device. The card says
 * as much rather than showing a half-filled bar the website cannot honour.
 */
export default function JourneyCard({ journey, className = '' }) {
  if (!journey) return null;
  const [from, to] = gradientFor(journey.accent ?? 'gyan');
  const steps = journey.steps ?? [];

  return (
    <Link
      to={journey.href}
      className={`surface group relative flex flex-col p-5 transition-all duration-300 ease-calm
                  hover:-translate-y-1 hover:border-terra/25 hover:shadow-lift sm:p-6 ${className}`}
    >
      <div className="flex items-start justify-between gap-4">
        <span
          className="flex h-10 w-10 items-center justify-center rounded-md text-white/90
                     transition-transform duration-300 ease-calm group-hover:-translate-y-0.5
                     sm:h-11 sm:w-11"
          style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
        >
          <Glyph name="compass" size={20} />
        </span>
        {journey.level && <Badge tone="terra">{LEVEL_LABELS[journey.level] ?? journey.level}</Badge>}
      </div>

      <h3 className="mt-4 text-[1.06rem] leading-snug text-ink sm:mt-5 sm:text-[1.15rem]">
        {journey.title}
      </h3>
      {journey.titleHi && (
        <p className="mt-1 font-deva text-[0.85rem] text-ink-faint">{journey.titleHi}</p>
      )}
      {journey.summary && (
        <p
          className="mt-2.5 line-clamp-3 text-[0.85rem] leading-relaxed text-ink-soft
                     sm:line-clamp-none sm:text-[0.9rem]"
        >
          {journey.summary}
        </p>
      )}

      {/* Step track — one segment per reading. */}
      {steps.length > 0 && (
        <div className="mt-5" aria-hidden="true">
          <span className="flex gap-1.5">
            {steps.map((step, i) => (
              <span
                key={step.no ?? i}
                className="h-1 flex-1 rounded-full bg-ink/[0.09] transition-colors duration-500"
                style={i === 0 ? { background: from } : undefined}
              />
            ))}
          </span>
        </div>
      )}

      {steps.length > 0 && (
        <ol className="mt-4 space-y-1.5">
          {steps.slice(0, 3).map((step, i) => (
            <li key={step.no ?? i} className="flex gap-2.5 text-[0.85rem] text-ink-soft">
              <span className="font-display text-[0.78rem] font-semibold text-terra/70">
                {String(step.no ?? i + 1).padStart(2, '0')}
              </span>
              <span className="truncate">{step.title}</span>
            </li>
          ))}
          {steps.length > 3 && (
            <li className="pl-[1.65rem] text-[0.8rem] text-ink-faint">
              + {steps.length - 3} more
            </li>
          )}
        </ol>
      )}

      <div
        className="mt-5 flex items-center gap-4 border-t border-ink/[0.07] pt-4 text-[0.78rem]
                   text-ink-faint sm:mt-6"
      >
        {journey.minutes && (
          <span className="flex items-center gap-1.5">
            <Clock size={13} strokeWidth={1.8} aria-hidden="true" />
            {journey.minutes} min
          </span>
        )}
        <span className="flex items-center gap-1.5">
          <Footprints size={13} strokeWidth={1.8} aria-hidden="true" />
          {steps.length} steps
        </span>
        <ArrowRight
          size={15}
          strokeWidth={1.9}
          aria-hidden="true"
          className="ml-auto text-terra opacity-0 transition-all duration-300 ease-calm
                     group-hover:translate-x-0.5 group-hover:opacity-100"
        />
      </div>
    </Link>
  );
}
