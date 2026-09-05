import Reveal from './Reveal.jsx';
import { OrnamentBand } from '../art/Mandala.jsx';

/**
 * The masthead every inner page opens with.
 *
 * It carries the page's single <h1>, so the sections below it can use <h2> and
 * the heading order stays correct for a screen reader and a crawler alike.
 */
export default function PageHeader({
  eyebrow,
  title,
  titleHi,
  lead,
  meta,
  children,
  className = '',
}) {
  return (
    <header className={`relative overflow-hidden pb-10 pt-28 sm:pb-14 sm:pt-36 ${className}`}>
      <OrnamentBand className="absolute inset-x-0 bottom-0 h-3 w-full text-terra/15" />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-gradient-to-b from-terra/[0.05]
                   via-transparent to-transparent"
      />

      <div className="shell relative">
        <Reveal>
          {eyebrow && <p className="eyebrow mb-3">{eyebrow}</p>}
          <h1 className="text-display-lg text-ink">
            {title}
            {titleHi && (
              <span className="ml-3 font-deva text-[0.55em] font-normal text-ink-faint">
                {titleHi}
              </span>
            )}
          </h1>
          {lead && (
            <p className="mt-5 max-w-prose text-[1.05rem] leading-relaxed text-ink-soft">{lead}</p>
          )}
          {meta && (
            <div className="mt-6 flex flex-wrap items-center gap-x-6 gap-y-2 text-[0.84rem] text-ink-faint">
              {meta}
            </div>
          )}
          {children}
        </Reveal>
      </div>
    </header>
  );
}
