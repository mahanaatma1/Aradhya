import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import Reveal from './Reveal.jsx';
import { OrnamentBand } from '../art/Mandala.jsx';

/**
 * A page section with the site's standard rhythm: eyebrow, display heading,
 * optional lead paragraph, optional "see all" link, then children.
 *
 * `tone` picks the ground — plain paper, the warmer kraft, or a full-bleed
 * band that separates the page into chapters.
 */
const TONES = {
  paper: '',
  kraft: 'bg-paper-2/60',
  card: 'bg-card/70',
};

export default function Section({
  id,
  eyebrow,
  title,
  titleHi,
  lead,
  action,
  tone = 'paper',
  ornament = false,
  align = 'left',
  className = '',
  headerClassName = '',
  children,
}) {
  const centred = align === 'center';

  return (
    <section id={id} className={`relative scroll-mt-24 py-section ${TONES[tone]} ${className}`}>
      {ornament && (
        <OrnamentBand className="absolute inset-x-0 top-0 h-3 w-full text-terra/20" />
      )}
      <div className="shell">
        {(eyebrow || title || lead || action) && (
          <Reveal
            className={`mb-10 flex flex-col gap-5 sm:mb-14 ${
              centred ? 'items-center text-center' : 'md:flex-row md:items-end md:justify-between'
            } ${headerClassName}`}
          >
            <div className={centred ? 'max-w-2xl' : 'max-w-2xl'}>
              {eyebrow && <p className="eyebrow mb-3">{eyebrow}</p>}
              {title && (
                <h2 className="text-display-md text-ink">
                  {title}
                  {titleHi && (
                    <span className="ml-3 font-deva text-[0.62em] font-normal text-ink-faint">
                      {titleHi}
                    </span>
                  )}
                </h2>
              )}
              {lead && (
                <p className="mt-4 max-w-prose text-[1.02rem] leading-relaxed text-ink-soft">
                  {lead}
                </p>
              )}
            </div>

            {action && (
              <Link
                to={action.to}
                className="group inline-flex shrink-0 items-center gap-1.5 text-sm font-medium
                           text-terra transition-colors hover:text-terra-dark"
              >
                {action.label}
                <ArrowRight
                  size={15}
                  strokeWidth={2}
                  className="transition-transform duration-300 ease-calm group-hover:translate-x-1"
                />
              </Link>
            )}
          </Reveal>
        )}
        {children}
      </div>
    </section>
  );
}
