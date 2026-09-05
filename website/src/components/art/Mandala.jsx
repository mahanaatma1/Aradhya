/**
 * Sacred-geometry backdrop for the hero.
 *
 * Two nested SVG figures — a yantra of overlapping vesicas inside a petalled
 * ring — turning in opposite directions at a pace you notice only if you look
 * for it. Held far back with low opacity so it never competes with the search
 * bar, and stilled entirely under prefers-reduced-motion (see index.css).
 */

function petals(count, radius, length) {
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const angle = (360 / count) * i;
    out.push(
      <ellipse
        key={i}
        cx="0"
        cy={-radius}
        rx={length * 0.34}
        ry={length}
        transform={`rotate(${angle})`}
      />,
    );
  }
  return out;
}

function spokes(count, inner, outer) {
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const a = ((360 / count) * i * Math.PI) / 180;
    out.push(
      <line
        key={i}
        x1={Math.sin(a) * inner}
        y1={-Math.cos(a) * inner}
        x2={Math.sin(a) * outer}
        y2={-Math.cos(a) * outer}
      />,
    );
  }
  return out;
}

export default function Mandala({ className = '', accent = 'currentColor' }) {
  return (
    <svg
      viewBox="-300 -300 600 600"
      className={className}
      fill="none"
      stroke={accent}
      strokeWidth="0.9"
      aria-hidden="true"
      focusable="false"
    >
      {/* Outer petalled ring, turning slowly clockwise. */}
      <g className="origin-center animate-spin-slow" opacity="0.85">
        <circle r="286" />
        <circle r="268" strokeDasharray="2 9" />
        <g opacity="0.75">{petals(24, 232, 30)}</g>
        <circle r="196" />
      </g>

      {/* Inner yantra, counter-turning. */}
      <g
        className="origin-center animate-spin-slow"
        style={{ animationDirection: 'reverse', animationDuration: '200s' }}
      >
        <g opacity="0.9">{petals(8, 118, 72)}</g>
        <circle r="150" strokeDasharray="14 10" />
        <circle r="96" />
        <g opacity="0.6">{spokes(16, 96, 150)}</g>
        {/* Interlocking triangles — the shatkona at the centre of a shri yantra. */}
        <path d="M0 -86 74.5 43 -74.5 43Z" opacity="0.8" />
        <path d="M0 86 74.5 -43 -74.5 -43Z" opacity="0.8" />
        <circle r="34" />
        <circle r="7" fill={accent} stroke="none" opacity="0.5" />
      </g>
    </svg>
  );
}

/**
 * A single band of temple-plinth ornament, used as a section divider. Drawn as a
 * repeating pattern so it stretches to any width without distorting.
 */
export function OrnamentBand({ className = '' }) {
  return (
    <svg
      viewBox="0 0 120 12"
      preserveAspectRatio="none"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth="0.7"
      aria-hidden="true"
      focusable="false"
    >
      <defs>
        <pattern id="aradhya-plinth" width="20" height="12" patternUnits="userSpaceOnUse">
          <path d="M0 9h20" />
          <path d="M10 9 6 4h8z" />
          <circle cx="10" cy="2.4" r="1.1" />
          <path d="M0 11.4h20" strokeDasharray="2 2.4" />
        </pattern>
      </defs>
      <rect width="120" height="12" fill="url(#aradhya-plinth)" stroke="none" />
    </svg>
  );
}
