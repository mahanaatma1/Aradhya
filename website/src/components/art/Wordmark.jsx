import { useId } from 'react';
import { appConfig } from '../../config/appConfig.js';

/**
 * The Aradhya lotus — the app's actual logo, ported shape-for-shape from
 * `_LotusPainter` in `lib/shared/widgets/app_logo.dart` so the website and the
 * installed app show the same mark. Same 512-unit design grid, same petal
 * angles, lengths, widths and gradients.
 *
 * Drawn rather than shipped as an image, for the same reason the app draws it:
 * it stays crisp at 20px in a phone mock and at 86px on a share card.
 */

const GRID = 512;
const CX = 256;
const CY = 300;

/** Tile geometry, as fractions of the rendered size — AppLogo's numbers. */
const TILE = {
  radius: 0.26,
  stitchInset: 0.11,
  stitchRadius: 0.26 * 0.62,
  stitchStroke: 0.014,
  stitchDash: 0.055,
  stitchGap: 0.04,
};

/** AppColors.kraft2 — the tile is warm cream in both themes, as in the app. */
export const LOGO_TILE_BG = '#FBEFDD';
/** AppColors.terracotta, for the stitched seam. */
const SEAM = '#A73015';

const round = (v) => Math.round(v * 100) / 100;

/**
 * One petal: rises from the centre point on the negative-y axis, mirrored
 * left/right. Identical to the Dart path — two cubics and a close.
 */
function petalPath(length, width) {
  const l = length;
  const w = width;
  return (
    `M${CX} ${CY}` +
    `C${round(CX - w)} ${round(CY - l * 0.55)} ${round(CX - w * 0.4)} ${CY - l} ${CX} ${CY - l}` +
    `C${round(CX + w * 0.4)} ${CY - l} ${round(CX + w)} ${round(CY - l * 0.55)} ${CX} ${CY}Z`
  );
}

/** Back to front, exactly the order the painter draws them in. */
const RINGS = [
  { tone: 'gold', angles: [-66, -33, 0, 33, 66], d: petalPath(194, 82) },
  { tone: 'terra', angles: [-42, -14, 14, 42], d: petalPath(178, 70) },
  { tone: 'core', angles: [0], d: petalPath(196, 58) },
];

/** The gold cradle the flower sits in, drawn last. */
const CRADLE =
  `M${CX - 150} ${CY + 6}Q${CX} ${CY + 70} ${CX + 150} ${CY + 6}` +
  `Q${CX} ${CY + 34} ${CX - 150} ${CY + 6}Z`;

const GRADIENTS = {
  gold: ['#EFCB6A', '#B48B3E'],
  terra: ['#B23A18', '#6E1F10'],
  core: ['#9A2E12', '#6E1F10'],
};

/**
 * The lotus on its own, with no tile — the app's `AppLogo(tile: false)`.
 *
 * `stitch` adds the dashed seam, which only makes sense inside a tile.
 * `bloom` plays the splash-screen opening once on mount: petals fan out of a
 * closed bud and the gold cradle grows in underneath. The keyframes and the
 * reasoning behind the nested groups are in src/index.css.
 */
export function LotusMark({ size = 40, stitch = false, bloom = false, label, className = '' }) {
  // Gradient ids are document-global, so every instance needs its own or two
  // logos on one page would fight over them.
  const uid = useId().replace(/:/g, '');

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${GRID} ${GRID}`}
      className={`${bloom ? 'lotus-bloom' : ''} ${className}`}
      role={label ? 'img' : undefined}
      aria-label={label || undefined}
      aria-hidden={label ? undefined : 'true'}
      focusable="false"
    >
      <defs>
        {/*
          Flutter shades each petal with a gradient spanning the whole canvas
          rather than the petal, which is what gives the outer petals their
          darker tips. userSpaceOnUse across the full grid reproduces that;
          per-path objectBoundingBox would not.
        */}
        {Object.entries(GRADIENTS).map(([tone, [from, to]]) => (
          <linearGradient
            key={tone}
            id={`${uid}-${tone}`}
            gradientUnits="userSpaceOnUse"
            x1="0"
            y1="0"
            x2="0"
            y2={GRID}
          >
            <stop offset="0" stopColor={from} />
            <stop offset="1" stopColor={to} />
          </linearGradient>
        ))}
      </defs>

      {RINGS.map((ring) => (
        <g key={ring.tone} fill={`url(#${uid}-${ring.tone})`}>
          {ring.angles.map((angle) => (
            // The final angle lives on the outer group as a presentation
            // attribute, so the flower is open even if the animation never runs.
            // The bloom then works backwards from there — and since every
            // rotation shares the (256,300) centre, nesting them composes
            // cleanly. Fan-out and lengthening need different easings, hence two
            // groups rather than one transform.
            <g key={angle} transform={`rotate(${angle} ${CX} ${CY})`}>
              {bloom ? (
                <g className="lotus-fan" style={{ '--lotus-from': `${-angle}deg` }}>
                  <g className="lotus-grow">
                    <path d={ring.d} />
                  </g>
                </g>
              ) : (
                <path d={ring.d} />
              )}
            </g>
          ))}
        </g>
      ))}

      <path d={CRADLE} fill="#C7A24E" className={bloom ? 'lotus-cradle' : undefined} />

      {stitch && (
        <rect
          x={round(GRID * TILE.stitchInset)}
          y={round(GRID * TILE.stitchInset)}
          width={round(GRID * (1 - TILE.stitchInset * 2))}
          height={round(GRID * (1 - TILE.stitchInset * 2))}
          rx={round(GRID * TILE.stitchRadius)}
          fill="none"
          stroke={SEAM}
          strokeOpacity="0.38"
          strokeWidth={round(GRID * TILE.stitchStroke)}
          strokeDasharray={`${round(GRID * TILE.stitchDash)} ${round(GRID * TILE.stitchGap)}`}
        />
      )}
    </svg>
  );
}

/**
 * The logo as the app shows it in its header, profile and share cards: the
 * lotus on a warm cream tile, with the signature dashed seam inset from the
 * edge and a soft terracotta shadow underneath.
 */
export function LogoTile({ size = 44, bloom = false, className = '' }) {
  const radius = size * TILE.radius;
  return (
    <span
      className={`relative inline-grid shrink-0 place-items-center
                  ${bloom ? 'lotus-tile-in' : ''} ${className}`}
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: LOGO_TILE_BG,
        boxShadow: `0 ${round(size * 0.08)}px ${round(size * 0.2)}px rgba(167, 48, 21, 0.22)`,
      }}
      aria-hidden="true"
    >
      <LotusMark size={size} stitch bloom={bloom} />
    </span>
  );
}

/**
 * Tile + wordmark, in the proportions the share card uses (public/og-image.svg):
 * the lotus tile leads, the name is a little over half its height, and the
 * letterspaced tagline sits under it. `size` is the tile's side and everything
 * else derives from it, so callers set one number.
 *
 * `bloom` plays the app's splash opening once on mount.
 */
export default function Wordmark({
  size = 44,
  showTagline = false,
  bloom = false,
  className = '',
}) {
  const { wordmark, tagline } = appConfig;
  return (
    <span className={`inline-flex items-center ${className}`} style={{ gap: round(size * 0.23) }}>
      <LogoTile size={size} bloom={bloom} />
      <span className={`flex flex-col justify-center ${bloom ? 'lotus-word-in' : ''}`}>
        <span
          className="font-display font-semibold leading-none tracking-tight text-ink"
          style={{ fontSize: round(size * 0.535) }}
        >
          {wordmark.head}
          <span className="text-terra">{wordmark.tail}</span>
        </span>
        {showTagline && (
          <span
            className="font-body uppercase leading-none tracking-[0.18em] text-ink-faint"
            style={{ marginTop: round(size * 0.13), fontSize: Math.max(9, round(size * 0.221)) }}
          >
            {tagline}
          </span>
        )}
      </span>
    </span>
  );
}


