import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import Glyph from '../art/Glyph.jsx';
import { CardSkeleton } from '../ui/States.jsx';
import { gradientFor, relationLabel } from '../../config/taxonomy.js';
import { getGraphClusters, contentKeys } from '../../services/contentService.js';
import { useMediaQuery } from '../../hooks/index.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Everything is connected" — the knowledge graph, drawn live.
 *
 * Built from HTML nodes over an SVG edge layer rather than an image: the nodes
 * are real links with real text, so it is readable by a screen reader, indexable,
 * and sharp at any size. The edges use `vector-effect="non-scaling-stroke"` so a
 * stretched viewBox never thickens a line.
 *
 * Every node comes from the content set and only renders when the page behind it
 * exists (see getGraphClusters), so nothing here is a dead end.
 */

const RADIUS = 34; // percent of the frame

function positions(count) {
  return Array.from({ length: count }, (_, i) => {
    const angle = (-90 + (360 / count) * i) * (Math.PI / 180);
    return {
      x: 50 + RADIUS * Math.cos(angle) * 1.15, // wider than tall — matches the 16:9 frame
      y: 50 + RADIUS * Math.sin(angle),
    };
  });
}

function NodeChip({ record, relation, dimmed, onFocus, onBlur, small = false }) {
  const [from, to] = gradientFor(record.accent);
  return (
    <Link
      to={record.href}
      onMouseEnter={onFocus}
      onMouseLeave={onBlur}
      onFocus={onFocus}
      onBlur={onBlur}
      className={`group flex items-center gap-2 rounded-full border border-ink/[0.09] bg-card
                  py-1.5 pl-1.5 pr-3.5 shadow-card transition-all duration-300 ease-calm
                  hover:-translate-y-0.5 hover:border-terra/35 hover:shadow-lift
                  ${dimmed ? 'opacity-45' : 'opacity-100'}`}
    >
      <span
        className={`flex items-center justify-center rounded-full text-white/90
                    ${small ? 'h-7 w-7' : 'h-8 w-8'}`}
        style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
      >
        <Glyph name={record.glyph} size={small ? 14 : 16} />
      </span>
      <span className="min-w-0">
        <span
          className={`block truncate font-medium text-ink ${small ? 'text-[0.8rem]' : 'text-[0.86rem]'}`}
        >
          {record.title}
        </span>
        {relation && (
          <span className="block truncate text-[0.68rem] uppercase tracking-[0.1em] text-ink-faint">
            {relation}
          </span>
        )}
      </span>
    </Link>
  );
}

export default function KnowledgeGraph() {
  const { data: clusters, loading } = useAsync(() => getGraphClusters(), [], {
    preloadKey: contentKeys.graph,
  });
  const [which, setWhich] = useState(0);
  const [hovered, setHovered] = useState(-1);
  const wide = useMediaQuery('(min-width: 768px)');

  const cluster = clusters?.[Math.min(which, (clusters?.length ?? 1) - 1)];
  const coords = useMemo(() => positions(cluster?.nodes.length ?? 0), [cluster?.nodes.length]);

  if (loading || !cluster) return <CardSkeleton className="h-[26rem]" />;

  const centre = cluster.centre;
  const [cFrom, cTo] = gradientFor(centre.accent);

  return (
    <div>
      {/* Cluster switcher */}
      {clusters.length > 1 && (
        <div className="mb-7 flex flex-wrap justify-center gap-2">
          {clusters.map((c, i) => (
            <button
              key={c.id}
              type="button"
              onClick={() => {
                setWhich(i);
                setHovered(-1);
              }}
              aria-pressed={i === which}
              className={`rounded-full px-4 py-1.5 text-[0.83rem] font-medium transition-all
                          duration-200 ${
                            i === which
                              ? 'bg-terra text-[#FFF4E9] shadow-card'
                              : 'border border-ink/12 text-ink-soft hover:border-terra/30 hover:text-terra'
                          }`}
            >
              {c.label}
            </button>
          ))}
        </div>
      )}

      {wide ? (
        <div
          className="surface stitch relative mx-auto aspect-[16/9] w-full max-w-4xl"
          role="group"
          aria-label={`${centre.title} and related entries`}
        >
          {/* Edge layer */}
          <svg
            viewBox="0 0 100 100"
            preserveAspectRatio="none"
            className="absolute inset-0 h-full w-full"
            aria-hidden="true"
          >
            {coords.map((p, i) => (
              <line
                key={cluster.nodes[i].id}
                x1="50"
                y1="50"
                x2={p.x}
                y2={p.y}
                stroke="rgb(var(--terra))"
                strokeWidth={hovered === i ? 1.6 : 1}
                strokeDasharray={hovered === i ? '0' : '3 3'}
                strokeOpacity={hovered === -1 ? 0.3 : hovered === i ? 0.75 : 0.12}
                vectorEffect="non-scaling-stroke"
                className="transition-all duration-300"
              />
            ))}
            <circle
              cx="50"
              cy="50"
              r="26"
              fill="none"
              stroke="rgb(var(--gold))"
              strokeOpacity="0.18"
              strokeDasharray="2 6"
              vectorEffect="non-scaling-stroke"
            />
          </svg>

          {/* Centre */}
          <Link
            to={centre.href}
            className="group absolute left-1/2 top-1/2 flex -translate-x-1/2 -translate-y-1/2
                       flex-col items-center gap-2.5 rounded-xl px-5 py-4 text-center"
          >
            <span
              className="flex h-16 w-16 items-center justify-center rounded-lg text-white/90 shadow-lift
                         transition-transform duration-300 ease-calm group-hover:-translate-y-1
                         group-hover:shadow-float"
              style={{ background: `linear-gradient(135deg, ${cFrom}, ${cTo})` }}
            >
              <Glyph name={centre.glyph} size={28} />
            </span>
            <span>
              <span className="block font-display text-[1.05rem] font-semibold text-ink">
                {centre.title}
              </span>
              <span className="block text-[0.72rem] uppercase tracking-[0.14em] text-ink-faint">
                {centre.badge}
              </span>
            </span>
          </Link>

          {/* Satellites */}
          {cluster.nodes.map((node, i) => (
            <div
              key={node.id}
              className="absolute max-w-[13rem] -translate-x-1/2 -translate-y-1/2"
              style={{ left: `${coords[i].x}%`, top: `${coords[i].y}%` }}
            >
              <NodeChip
                record={node}
                relation={node.edge ? relationLabel(node.edge) : null}
                dimmed={hovered !== -1 && hovered !== i}
                onFocus={() => setHovered(i)}
                onBlur={() => setHovered(-1)}
              />
            </div>
          ))}
        </div>
      ) : (
        /* Narrow screens: the same relationships as a spine, which reads better
           than a squashed circle. */
        <div className="surface p-5">
          <Link to={centre.href} className="group flex items-center gap-3">
            <span
              className="flex h-12 w-12 items-center justify-center rounded-md text-white/90"
              style={{ background: `linear-gradient(135deg, ${cFrom}, ${cTo})` }}
            >
              <Glyph name={centre.glyph} size={22} />
            </span>
            <span>
              <span className="block font-display text-[1.1rem] font-semibold text-ink">
                {centre.title}
              </span>
              <span className="block text-[0.72rem] uppercase tracking-[0.14em] text-ink-faint">
                {centre.badge}
              </span>
            </span>
          </Link>

          <ul className="mt-4 space-y-2.5 border-l border-dashed border-terra/35 pl-5">
            {cluster.nodes.map((node) => (
              <li key={node.id} className="relative">
                <span
                  aria-hidden="true"
                  className="absolute -left-[1.42rem] top-1/2 h-px w-4 -translate-y-1/2
                             border-t border-dashed border-terra/35"
                />
                <NodeChip
                  record={node}
                  relation={node.edge ? relationLabel(node.edge) : null}
                  dimmed={false}
                  small
                />
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
