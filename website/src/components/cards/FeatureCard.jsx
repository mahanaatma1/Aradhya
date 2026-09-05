import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * One of the eight doors on the home page.
 *
 * The hover is deliberately small: the glyph plate lifts a couple of pixels, the
 * card rises, and an arrow fades in. No glass, no glow.
 */
export default function FeatureCard({ door, className = '' }) {
  const [from, to] = gradientFor(door.accent);

  return (
    <Link
      to={door.to}
      className={`surface stitch group relative flex flex-col overflow-hidden p-5 transition-all
                  duration-300 ease-calm hover:-translate-y-1.5 hover:border-terra/25
                  hover:shadow-lift sm:p-6 ${className}`}
    >
      {/* A wash of the category colour that warms on hover. */}
      <span
        aria-hidden="true"
        className="pointer-events-none absolute -right-10 -top-12 h-32 w-32 rounded-full opacity-[0.07]
                   blur-2xl transition-opacity duration-500 group-hover:opacity-[0.16]"
        style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
      />

      <span
        className="relative flex h-11 w-11 items-center justify-center rounded-md text-white/90
                   shadow-card transition-transform duration-300 ease-calm
                   group-hover:-translate-y-1 group-hover:rotate-[-3deg] sm:h-12 sm:w-12"
        style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
      >
        <Glyph name={door.glyph} size={22} />
      </span>

      <h3 className="relative mt-4 text-[1.05rem] text-ink sm:mt-5 sm:text-[1.15rem]">
        {door.title}
      </h3>
      <p className="relative mt-2 text-[0.85rem] leading-relaxed text-ink-soft sm:text-[0.9rem]">
        {door.blurb}
      </p>

      <span className="relative mt-auto pt-4 sm:pt-5">
        <ArrowRight
          size={17}
          strokeWidth={1.8}
          aria-hidden="true"
          className="translate-x-[-4px] text-terra opacity-0 transition-all duration-300 ease-calm
                     group-hover:translate-x-0 group-hover:opacity-100"
        />
      </span>
    </Link>
  );
}
