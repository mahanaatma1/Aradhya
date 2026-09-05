import { Link } from 'react-router-dom';

/**
 * Chip — a small pill. Renders as a link, a button, or plain text depending on
 * what it is given, so the same look serves example queries, tags and facets.
 */
export function Chip({ to, onClick, active = false, className = '', children, ...rest }) {
  const interactive = Boolean(to || onClick);
  const classes = [
    'chip',
    interactive && 'hover:border-terra/40 hover:bg-card hover:text-terra',
    active && 'border-terra/45 bg-terra/[0.08] text-terra',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  if (to) {
    return (
      <Link to={to} className={classes} {...rest}>
        {children}
      </Link>
    );
  }
  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={classes} {...rest}>
        {children}
      </button>
    );
  }
  return (
    <span className={classes} {...rest}>
      {children}
    </span>
  );
}

/** Badge — the category label that sits on a card. */
export function Badge({ tone = 'quiet', className = '', children }) {
  const tones = {
    quiet: 'bg-paper-2/80 text-ink-soft',
    terra: 'bg-terra/[0.09] text-terra',
    gold: 'bg-gold/[0.14] text-[rgb(var(--gold))]',
    onColor: 'bg-white/20 text-white backdrop-blur-[2px]',
  };
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-[3px] text-[0.66rem] font-semibold
                  uppercase tracking-[0.13em] ${tones[tone]} ${className}`}
    >
      {children}
    </span>
  );
}

export default Chip;
