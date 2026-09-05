import { forwardRef } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

/**
 * The site's one button. Renders as <Link>, <a> or <button> depending on which
 * of `to` / `href` / neither is given, so callers never have to think about it.
 *
 * Variants: primary (terracotta seal) · secondary (outlined paper) · ghost ·
 * quiet (text with a sliding arrow).
 */

const BASE =
  'group relative inline-flex select-none items-center justify-center gap-2 whitespace-nowrap ' +
  'font-medium transition-all duration-300 ease-calm disabled:pointer-events-none disabled:opacity-50';

const VARIANTS = {
  primary:
    'rounded-full bg-terra text-[#FFF4E9] shadow-lift hover:bg-terra-dark hover:shadow-float ' +
    'active:scale-[0.985]',
  secondary:
    'rounded-full border border-ink/15 bg-card/80 text-ink backdrop-blur hover:border-terra/40 ' +
    'hover:text-terra hover:shadow-card active:scale-[0.985]',
  ghost: 'rounded-full text-ink-soft hover:bg-ink/[0.05] hover:text-ink',
  quiet: 'text-terra hover:text-terra-dark',
};

const SIZES = {
  sm: 'h-9 px-4 text-[0.82rem]',
  md: 'h-11 px-6 text-[0.9rem]',
  lg: 'h-[3.25rem] px-8 text-[0.97rem]',
};

const Button = forwardRef(function Button(
  {
    as,
    to,
    href,
    variant = 'primary',
    size = 'md',
    withArrow = false,
    icon: Icon,
    className = '',
    children,
    ...rest
  },
  ref,
) {
  const sizing = variant === 'quiet' ? 'text-[0.9rem] gap-1.5' : SIZES[size];
  const classes = `${BASE} ${VARIANTS[variant]} ${sizing} ${className}`;

  const content = (
    <>
      {Icon && <Icon size={17} strokeWidth={1.8} aria-hidden="true" />}
      <span>{children}</span>
      {withArrow && (
        <ArrowRight
          size={16}
          strokeWidth={1.9}
          aria-hidden="true"
          className="transition-transform duration-300 ease-calm group-hover:translate-x-1"
        />
      )}
    </>
  );

  if (to) {
    return (
      <Link ref={ref} to={to} className={classes} {...rest}>
        {content}
      </Link>
    );
  }
  if (href) {
    const external = /^https?:/.test(href);
    return (
      <a
        ref={ref}
        href={href}
        className={classes}
        {...(external ? { target: '_blank', rel: 'noreferrer noopener' } : {})}
        {...rest}
      >
        {content}
      </a>
    );
  }

  const Tag = as ?? 'button';
  return (
    <Tag ref={ref} className={classes} {...rest}>
      {content}
    </Tag>
  );
});

export default Button;
