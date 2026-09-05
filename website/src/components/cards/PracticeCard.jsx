import Glyph from '../art/Glyph.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * A practice tool. These live in the app — a website cannot keep a japa count or
 * a private journal — so the card describes the practice and hands off, rather
 * than pretending to be the tool.
 */
export default function PracticeCard({ practice, className = '' }) {
  const [from, to] = gradientFor(practice.accent);

  return (
    <article
      id={practice.slug ?? practice.id}
      className={`surface stitch group relative flex scroll-mt-28 flex-col p-5 transition-all
                  duration-300 ease-calm hover:-translate-y-1 hover:shadow-lift sm:p-6 ${className}`}
    >
      <span
        className="flex h-11 w-11 items-center justify-center rounded-md text-white/90
                   transition-transform duration-300 ease-calm group-hover:-translate-y-0.5
                   sm:h-12 sm:w-12"
        style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
      >
        <Glyph name={practice.glyph} size={21} />
      </span>

      <h3 className="mt-4 text-[1.02rem] text-ink sm:mt-5 sm:text-[1.12rem]">
        {practice.title}
        {practice.titleHi && (
          <span className="ml-2.5 font-deva text-[0.72em] font-normal text-ink-faint">
            {practice.titleHi}
          </span>
        )}
      </h3>
      <p
        className="mt-2 line-clamp-3 text-[0.85rem] leading-relaxed text-ink-soft
                   sm:line-clamp-none sm:text-[0.9rem]"
      >
        {practice.summary ?? practice.blurb}
      </p>
    </article>
  );
}
