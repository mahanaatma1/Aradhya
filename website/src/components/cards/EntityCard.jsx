import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { Badge } from '../ui/Chip.jsx';
import { gradientFor, relationLabel } from '../../config/taxonomy.js';

/**
 * The workhorse card. Every content record — a deity, a person, a place, a
 * festival, a scene, a concept — renders through this, which is why a search
 * result and a related-content row look identical.
 *
 * `variant`:
 *   default — glyph plate, badge, title, summary
 *   compact — one line high, for dense rails and related rows
 *   tile    — square-ish, glyph-forward, for grids of many entities
 */
export default function EntityCard({
  record,
  variant = 'default',
  showRelation = false,
  className = '',
}) {
  if (!record) return null;
  const [from, to] = gradientFor(record.accent);
  const plate = { background: `linear-gradient(135deg, ${from}, ${to})` };

  const relation =
    showRelation && record.relation
      ? relationLabel(record.relation.type, record.relation.inverse)
      : null;

  if (variant === 'compact') {
    return (
      <Link
        to={record.href}
        className={`group flex items-center gap-3.5 rounded-md px-3 py-2.5 transition-colors
                    duration-200 hover:bg-paper-2/70 ${className}`}
      >
        <span
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[0.6rem] text-white/90"
          style={plate}
        >
          <Glyph name={record.glyph} size={17} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-baseline gap-2">
            <span className="truncate text-[0.94rem] font-medium text-ink">{record.title}</span>
            {record.titleHi && (
              <span className="hidden shrink-0 font-deva text-xs text-ink-faint sm:inline">
                {record.titleHi}
              </span>
            )}
          </span>
          <span className="mt-0.5 block truncate text-[0.8rem] text-ink-faint">
            {relation ? `${relation} · ` : ''}
            {record.badge}
          </span>
        </span>
        <ArrowUpRight
          size={15}
          strokeWidth={1.8}
          aria-hidden="true"
          className="shrink-0 text-ink-faint opacity-0 transition-all duration-300 ease-calm
                     group-hover:translate-x-0.5 group-hover:text-terra group-hover:opacity-100"
        />
      </Link>
    );
  }

  if (variant === 'tile') {
    return (
      <Link
        to={record.href}
        className={`surface group relative flex flex-col items-start p-4 transition-all duration-300
                    ease-calm hover:-translate-y-1 hover:border-terra/25 hover:shadow-lift ${className}`}
      >
        <span
          className="mb-3.5 flex h-10 w-10 items-center justify-center rounded-[0.7rem] text-white/90
                     transition-transform duration-300 ease-calm group-hover:-translate-y-0.5"
          style={plate}
        >
          <Glyph name={record.glyph} size={19} />
        </span>
        <span className="text-[0.97rem] font-semibold leading-snug text-ink">{record.title}</span>
        {record.titleHi && (
          <span className="mt-0.5 font-deva text-[0.8rem] text-ink-faint">{record.titleHi}</span>
        )}
        <span className="mt-2 text-[0.74rem] font-medium uppercase tracking-[0.12em] text-ink-faint">
          {record.badge}
        </span>
      </Link>
    );
  }

  return (
    <Link
      to={record.href}
      className={`surface group relative flex gap-4 p-5 transition-all duration-300 ease-calm
                  hover:-translate-y-1 hover:border-terra/25 hover:shadow-lift ${className}`}
    >
      <span
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md text-white/90
                   transition-transform duration-300 ease-calm group-hover:-translate-y-0.5"
        style={plate}
      >
        <Glyph name={record.glyph} size={21} />
      </span>

      <span className="min-w-0 flex-1">
        <span className="flex flex-wrap items-center gap-2">
          <Badge>{relation ?? record.badge}</Badge>
          {record.titleHi && (
            <span className="font-deva text-[0.82rem] text-ink-faint">{record.titleHi}</span>
          )}
        </span>
        <h3 className="mt-2 text-[1.06rem] leading-snug text-ink">{record.title}</h3>
        {record.summary && (
          <p className="mt-1.5 line-clamp-2 text-[0.88rem] leading-relaxed text-ink-soft">
            {record.summary}
          </p>
        )}
      </span>

      <ArrowUpRight
        size={16}
        strokeWidth={1.8}
        aria-hidden="true"
        className="mt-1 shrink-0 text-ink-faint opacity-0 transition-all duration-300 ease-calm
                   group-hover:translate-x-0.5 group-hover:text-terra group-hover:opacity-100"
      />
    </Link>
  );
}
