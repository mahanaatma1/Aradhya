import { BookOpen } from 'lucide-react';

/**
 * The citation line under a piece of content.
 *
 * Every factual row in the curated set carries the public-domain text or open
 * dataset it was drawn from. Showing it is the point: a reader can check the
 * claim, and nothing on the page is asserted without a stated origin.
 *
 * Renders nothing when a record has no source, rather than inventing one.
 */
export default function SourceNote({ source, prefix = 'Source', className = '' }) {
  if (!source?.label) return null;
  return (
    <p
      className={`flex items-start gap-2 text-[0.76rem] leading-relaxed text-ink-faint ${className}`}
    >
      <BookOpen size={13} strokeWidth={1.7} className="mt-[3px] shrink-0" aria-hidden="true" />
      <span>
        <span className="font-medium">{prefix}:</span> {source.label}
        {source.section && <span className="text-ink-faint/80"> · {source.section}</span>}
      </span>
    </p>
  );
}

/**
 * A standing note for surfaces that summarise rather than quote — used where the
 * spec's rule matters most: no scripture text is reproduced here unless it came
 * from the curated set with its citation attached.
 */
export function ContentNote({ children, className = '' }) {
  return (
    <p
      className={`rounded-md border border-dashed border-ink/15 bg-paper-2/50 px-4 py-3
                  text-[0.78rem] leading-relaxed text-ink-soft ${className}`}
    >
      {children}
    </p>
  );
}
