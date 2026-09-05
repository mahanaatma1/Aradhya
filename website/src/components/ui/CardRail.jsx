import { Children } from 'react';
import Reveal from './Reveal.jsx';
import { CardSkeleton } from './States.jsx';

/**
 * Cards as a swipeable rail on phones, as a grid from `stop` upward.
 *
 * One list does both jobs: below the breakpoint it is a snap-scrolling flex row
 * that bleeds past the page gutter, so a half-visible card at the screen edge
 * tells you there is more; above it, the same element becomes an ordinary grid.
 * The cards sit in one <ul> in the DOM either way, so a crawler and a screen
 * reader see the same list at every width — and it stays a plain overflow
 * container, so a trackpad, a keyboard and a scrollbar drag all work.
 *
 * The reveal wraps the whole rail rather than each card, deliberately. useReveal
 * observes against the viewport, so a card parked off to the right of a rail is
 * not intersecting anything — per-card reveals would leave the rail looking
 * half-empty until you swiped it. One reveal for the group is honest; the
 * per-card stagger is the price.
 *
 * Where the rail turns into a grid. `none` stays a rail at every width.
 *
 * Each entry re-does the bleed at the breakpoints where the shell's gutter
 * changes (px-5 → sm:px-7 → lg:px-10). The negative margin, the padding and the
 * scroll-padding all have to stay equal to that gutter, or the first card stops
 * lining up with the heading above it.
 *
 * Breakpoints are looked up rather than interpolated, because Tailwind only
 * generates classes it can find as literal text in the source.
 */
const STOPS = {
  sm: {
    rail: 'sm:mx-0 sm:grid sm:overflow-visible sm:px-0 sm:pb-0 sm:pt-0 sm:[mask-image:none]',
    item: 'sm:w-auto',
  },
  lg: {
    // Still a rail on tablets, so the bleed has to follow the shell's wider gutter.
    rail: `sm:-mx-7 sm:px-7 sm:scroll-px-7
           lg:mx-0 lg:grid lg:overflow-visible lg:px-0 lg:pb-0 lg:pt-0 lg:[mask-image:none]`,
    item: 'lg:w-auto',
  },
  none: {
    rail: 'sm:-mx-7 sm:px-7 sm:scroll-px-7 lg:-mx-10 lg:px-10 lg:scroll-px-10',
    item: '',
  },
};

export default function CardRail({
  label,
  stop = 'sm',
  cols = 'sm:grid-cols-2 lg:grid-cols-4',
  itemWidth = 'w-[15rem]',
  gap = 'gap-4 sm:gap-5',
  loading = false,
  skeletonCount = 3,
  skeletonClassName = 'h-56',
  className = '',
  children,
}) {
  const { rail, item } = STOPS[stop] ?? STOPS.sm;

  // Same <li> shape for skeletons and real cards, so nothing shifts when the
  // content lands.
  const cells = loading
    ? Array.from({ length: skeletonCount }, (_, i) => (
        <CardSkeleton key={i} className={`h-full ${skeletonClassName}`} />
      ))
    : Children.toArray(children);

  return (
    <Reveal className={className}>
      <ul
        aria-label={loading ? 'Loading' : label}
        role={loading ? 'status' : undefined}
        className={`no-scrollbar rail-mask -mx-5 flex snap-x snap-mandatory scroll-px-5
                    overflow-x-auto px-5 pb-3 pt-1 ${gap} ${stop === 'none' ? '' : cols} ${rail}`}
      >
        {cells.map((cell, i) => (
          <li key={cell.key ?? i} className={`${itemWidth} shrink-0 snap-start ${item}`}>
            {cell}
          </li>
        ))}
      </ul>
    </Reveal>
  );
}
