import { Link } from 'react-router-dom';
import { ArrowUpRight, MapPin } from 'lucide-react';
import TempleArt from '../art/TempleArt.jsx';
import { Badge } from '../ui/Chip.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * A sacred place.
 *
 * Two honesty notes, both deliberate:
 *
 * 1. The visual is a stylised architectural silhouette, not a photograph of the
 *    place named. Nothing on the card claims to show the actual site.
 * 2. Only fields present on the record are rendered — `location`, `deity` and
 *    `image` are all optional. When the app's structured temple directory is
 *    exposed to the web, those fields start arriving and the card fills out; it
 *    never invents a district, a deity or a founding date to look complete.
 */
export default function TempleCard({ record, className = '' }) {
  if (!record) return null;
  const [from, to] = gradientFor(record.accent ?? 'temples');

  return (
    <Link
      to={record.href}
      className={`surface group relative flex w-full flex-col overflow-hidden transition-all
                  duration-300 ease-calm hover:-translate-y-1 hover:border-terra/25
                  hover:shadow-lift ${className}`}
    >
      {/* Header plate: real photography when a licensed image exists, silhouette otherwise. */}
      <div
        className="relative flex h-36 items-end justify-center overflow-hidden"
        style={{ background: `linear-gradient(160deg, ${from}, ${to})` }}
      >
        {record.image ? (
          <img
            src={record.image.src}
            alt={record.image.alt ?? record.title}
            loading="lazy"
            decoding="async"
            className="h-full w-full object-cover"
          />
        ) : (
          <TempleArt
            seed={record.slug}
            className="h-[7.5rem] w-full text-white/60 transition-transform duration-500 ease-calm
                       group-hover:-translate-y-1 group-hover:text-white/75"
          />
        )}
        <span
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/25 to-transparent"
        />
      </div>

      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-start justify-between gap-3">
          <Badge>{record.badge}</Badge>
          <ArrowUpRight
            size={16}
            strokeWidth={1.8}
            aria-hidden="true"
            className="text-ink-faint opacity-0 transition-all duration-300 ease-calm
                       group-hover:translate-x-0.5 group-hover:text-terra group-hover:opacity-100"
          />
        </div>

        <h3 className="mt-2.5 text-[1.1rem] leading-snug text-ink">
          {record.title}
          {record.titleHi && (
            <span className="ml-2 font-deva text-[0.72em] font-normal text-ink-faint">
              {record.titleHi}
            </span>
          )}
        </h3>

        {record.location && (
          <p className="mt-1.5 flex items-center gap-1.5 text-[0.8rem] text-ink-faint">
            <MapPin size={13} strokeWidth={1.8} aria-hidden="true" />
            {record.location}
          </p>
        )}

        {record.summary && (
          <p className="mt-2 line-clamp-3 text-[0.88rem] leading-relaxed text-ink-soft">
            {record.summary}
          </p>
        )}
      </div>
    </Link>
  );
}
