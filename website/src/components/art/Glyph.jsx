/**
 * Hand-drawn motifs, as inline SVG.
 *
 * Everything is stroke-based line art on a 24-unit grid using `currentColor`, so
 * a glyph inherits its colour from whatever card it sits in and costs nothing to
 * download. This is deliberately not a photo library or an icon dependency —
 * the shapes are the app's own vocabulary: lotus, pothi, bow, chakra, shikhara,
 * diya, mala.
 */

const shapes = {
  // Padma — three petals over a base.
  lotus: (
    <>
      <path d="M12 4c1.9 2.1 2.8 4.2 2.8 6.2 0 1.6-.9 3-2.8 4.3-1.9-1.3-2.8-2.7-2.8-4.3C9.2 8.2 10.1 6.1 12 4Z" />
      <path d="M9.3 9.1C7.4 9.4 5.8 10.3 4.6 11.7c-1 1.2-1.2 2.5-.5 3.9 2.1.2 3.8-.2 5.1-1.2" />
      <path d="M14.7 9.1c1.9.3 3.5 1.2 4.7 2.6 1 1.2 1.2 2.5.5 3.9-2.1.2-3.8-.2-5.1-1.2" />
      <path d="M5 17.4c2 1.7 4.3 2.6 7 2.6s5-.9 7-2.6" />
    </>
  ),
  // Pothi — a palm-leaf manuscript bound between boards.
  scroll: (
    <>
      <path d="M3.5 6.5h17v11h-17z" />
      <path d="M3.5 9.5h17M3.5 14.5h17" />
      <path d="M7 12h4M14 12h3" />
      <path d="M12 4.5v2M12 17.5v2" />
    </>
  ),
  // Dhanush — bow with a drawn arrow.
  bow: (
    <>
      <path d="M6 3c5.5 1.6 9 5.1 9 9s-3.5 7.4-9 9" />
      <path d="M6 3v18" />
      <path d="M6 12h13" />
      <path d="m16 9 3 3-3 3" />
    </>
  ),
  // Chakra — eight-spoked wheel.
  chakra: (
    <>
      <circle cx="12" cy="12" r="8.2" />
      <circle cx="12" cy="12" r="2.4" />
      <path d="M12 3.8v5.8M12 14.4v5.8M3.8 12h5.8M14.4 12h5.8" />
      <path d="m6.2 6.2 3.6 3.6M14.2 14.2l3.6 3.6M17.8 6.2l-3.6 3.6M9.8 14.2l-3.6 3.6" />
    </>
  ),
  // Shikhara — a temple tower with its kalash.
  shikhara: (
    <>
      <path d="M12 2.4v1.8M11 4.2h2" />
      <path d="M12 5.2c-.9 0-1.4.6-1.4 1.3 0 .6.5 1 1.4 1s1.4-.4 1.4-1c0-.7-.5-1.3-1.4-1.3Z" />
      <path d="M7.6 20V13.4c0-3 1.9-5.2 4.4-5.9 2.5.7 4.4 2.9 4.4 5.9V20" />
      <path d="M9.6 13.6h4.8M4.4 20h15.2" />
      <path d="M10.4 20v-3.6c0-.9.7-1.6 1.6-1.6s1.6.7 1.6 1.6V20" />
    </>
  ),
  // Diya — oil lamp, lit.
  diya: (
    <>
      <path d="M12 3.2c1.5 1.7 2.2 3 2.2 4.1 0 1.2-.9 2.1-2.2 2.1s-2.2-.9-2.2-2.1c0-1.1.7-2.4 2.2-4.1Z" />
      <path d="M4 13.6h16c-.6 3.6-3.6 6-8 6s-7.4-2.4-8-6Z" />
      <path d="M12 11v2.6M6.4 15.8h11.2" />
    </>
  ),
  // Mala — a loop of beads with its tassel.
  mala: (
    <>
      <circle cx="12" cy="10.5" r="6.6" />
      <circle cx="12" cy="3.9" r="1.1" />
      <circle cx="18.6" cy="10.5" r="1" />
      <circle cx="5.4" cy="10.5" r="1" />
      <circle cx="16.7" cy="15.2" r="1" />
      <circle cx="7.3" cy="15.2" r="1" />
      <path d="M12 17.1v2.2M10.8 19.3h2.4M12 19.3v1.6" />
    </>
  ),
  // A compass rose, for curated journeys.
  compass: (
    <>
      <circle cx="12" cy="12" r="8.4" />
      <path d="m14.9 9.1-1.7 4.1-4.1 1.7 1.7-4.1z" />
      <path d="M12 2.6v1.8M12 19.6v1.8M2.6 12h1.8M19.6 12h1.8" />
    </>
  ),
  // Jyoti — a single flame.
  flame: (
    <>
      <path d="M12 2.8c3.4 3.4 5 6.1 5 8.4 0 3.1-2.2 5.4-5 5.4s-5-2.3-5-5.4c0-2.3 1.6-5 5-8.4Z" />
      <path d="M12 9.6c1.3 1.4 1.9 2.4 1.9 3.3 0 1.2-.8 2-1.9 2s-1.9-.8-1.9-2c0-.9.6-1.9 1.9-3.3Z" />
      <path d="M8.6 19.8h6.8" />
    </>
  ),
  // Shankha — conch.
  conch: (
    <>
      <path d="M17.8 5.4c1.6 2.1 2 4.8 1 7.6-1.3 3.7-4.6 6-8.3 6-2.6 0-4.6-1-6-2.7 2.3-.2 4-1 5.2-2.5" />
      <path d="M9.7 13.8c1.5-1.4 2.4-3.2 2.6-5.3.2-2.1 1-3.6 2.4-4.4 1.2-.7 2.3-.5 3.1.5" />
      <path d="M12.4 8.6c1.3.3 2.2 1 2.8 2.1" />
    </>
  ),
  // Trishula — trident.
  trishula: (
    <>
      <path d="M12 3.4v17.2" />
      <path d="M7.6 4.6v3.8c0 2 1.3 3.4 3.2 3.8M16.4 4.6v3.8c0 2-1.3 3.4-3.2 3.8" />
      <path d="M12 3.4 10.6 6M12 3.4 13.4 6" />
      <path d="M9.6 15.4h4.8" />
    </>
  ),
  // A figure, for people.
  figure: (
    <>
      <circle cx="12" cy="7.6" r="3.4" />
      <path d="M5.2 20.4c0-3.6 3-6.2 6.8-6.2s6.8 2.6 6.8 6.2" />
    </>
  ),
  // Sacred rivers.
  river: (
    <>
      <path d="M3 8.4c2-1.4 4-1.4 6 0s4 1.4 6 0 4-1.4 6 0" />
      <path d="M3 13c2-1.4 4-1.4 6 0s4 1.4 6 0 4-1.4 6 0" />
      <path d="M3 17.6c2-1.4 4-1.4 6 0s4 1.4 6 0 4-1.4 6 0" />
    </>
  ),
  // Sacred mountains.
  mountain: (
    <>
      <path d="M2.6 18.8 9 7.4l4 6.6 2.3-3.4 6.1 8.2z" />
      <path d="M6.6 13.4c1.4-.8 2.6-.8 3.6.2" />
    </>
  ),
  // An open book, for reflection.
  book: (
    <>
      <path d="M12 6.6C10.3 5.3 8 4.7 5 4.9v12.6c3-.2 5.3.4 7 1.7 1.7-1.3 4-1.9 7-1.7V4.9c-3-.2-5.3.4-7 1.7Z" />
      <path d="M12 6.6v12.6" />
    </>
  ),
  // Pranayama — nested breath arcs.
  breath: (
    <>
      <circle cx="12" cy="12" r="2" />
      <path d="M7.8 16.2a6 6 0 0 1 0-8.4M16.2 7.8a6 6 0 0 1 0 8.4" />
      <path d="M5 19a9.9 9.9 0 0 1 0-14M19 5a9.9 9.9 0 0 1 0 14" />
    </>
  ),
};

/** ॐ is drawn as type rather than a path — the letterform belongs to the font. */
function OmGlyph() {
  return (
    <text
      x="12"
      y="18.5"
      textAnchor="middle"
      fontSize="19"
      fill="currentColor"
      stroke="none"
      className="font-deva"
    >
      ॐ
    </text>
  );
}

/**
 * @param {{name: string, size?: number, className?: string, strokeWidth?: number}} props
 */
export default function Glyph({ name = 'lotus', size = 24, className = '', strokeWidth = 1.4 }) {
  const shape = name === 'om' ? <OmGlyph /> : (shapes[name] ?? shapes.lotus);
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
      focusable="false"
    >
      {shape}
    </svg>
  );
}

export const GLYPH_NAMES = [...Object.keys(shapes), 'om'];
