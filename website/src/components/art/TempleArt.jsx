/**
 * Temple silhouettes.
 *
 * Three architectural profiles — nagara shikhara, dravida vimana with gopuram,
 * and a domed shrine — chosen per card from a stable hash of the slug so a rail
 * of cards doesn't read as one shape repeated. These are stylised profiles, not
 * depictions of any particular temple, and carry no factual claim; when the
 * app's structured temple records (with real photography rights) are wired up,
 * TempleCard renders an <img> instead and this becomes the fallback.
 */

const VARIANTS = [
  // Nagara — a curvilinear north-Indian shikhara.
  (
    <g key="nagara">
      <path d="M100 18c-1.9 0-3 1.3-3 2.8 0 1.3 1.1 2.2 3 2.2s3-.9 3-2.2c0-1.5-1.1-2.8-3-2.8Z" />
      <path d="M100 8v9M97 14h6" />
      <path d="M84 100V56c0-16 6.8-27 16-31 9.2 4 16 15 16 31v44z" />
      <path d="M76 100V72c0-10 3.6-17 8-19M124 100V72c0-10-3.6-17-8-19" />
      <path d="M64 100V82c0-7 3-11 8-12M136 100V82c0-7-3-11-8-12" />
      <path d="M92 100V84c0-4.4 3.6-8 8-8s8 3.6 8 8v16" />
      <path d="M52 100h96M46 104h108" />
    </g>
  ),
  // Dravida — a stepped vimana flanked by gopuram gateways.
  (
    <g key="dravida">
      <path d="M100 14v8M96 20h8" />
      <path d="M92 26h16l-3 8H95z" />
      <path d="M88 34h24l-3 12H91zM82 46h36l-4 14H86zM76 60h48l-5 16H81zM70 76h60l-6 24H76z" />
      <path d="M38 100V76l8-8h14l8 8v24M124 100V76l8-8h14l8 8v24" />
      <path d="M46 68h20M132 68h20" />
      <path d="M30 100h140M24 104h152" />
    </g>
  ),
  // A domed shrine with a colonnaded mandapa.
  (
    <g key="dome">
      <path d="M100 16v7M97 22h6" />
      <path d="M100 26c-2 0-3.4 1.5-3.4 3.2 0 1.5 1.4 2.6 3.4 2.6s3.4-1.1 3.4-2.6c0-1.7-1.4-3.2-3.4-3.2Z" />
      <path d="M78 62c0-13 9.8-24 22-24s22 11 22 24z" />
      <path d="M74 62h52M78 62v38M122 62v38" />
      <path d="M86 100V76a14 14 0 0 1 28 0v24" />
      <path d="M56 100V70M68 100V70M132 100V70M144 100V70" />
      <path d="M50 70h24l4-8M126 70h24l-4-8" />
      <path d="M44 100h112M38 104h124" />
    </g>
  ),
];

/** Deterministic variant pick — same slug, same silhouette, every render. */
function pick(seed = '') {
  let hash = 0;
  for (let i = 0; i < seed.length; i += 1) hash = (hash * 31 + seed.charCodeAt(i)) % 9973;
  return VARIANTS[hash % VARIANTS.length];
}

export default function TempleArt({ seed = '', className = '' }) {
  return (
    <svg
      viewBox="0 0 200 112"
      preserveAspectRatio="xMidYMax meet"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {pick(seed)}
    </svg>
  );
}
