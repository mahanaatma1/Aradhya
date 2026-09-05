import { useReveal } from '../../hooks/index.js';

/**
 * Wraps children in a scroll-reveal container. `delay` staggers siblings; keep it
 * under ~250ms so a grid never feels like it is loading in.
 */
export default function Reveal({ as: Tag = 'div', delay = 0, className = '', children, ...rest }) {
  const ref = useReveal();
  return (
    <Tag
      ref={ref}
      className={`reveal ${className}`}
      style={delay ? { transitionDelay: `${delay}ms` } : undefined}
      {...rest}
    >
      {children}
    </Tag>
  );
}
