import { SearchX, TriangleAlert } from 'lucide-react';
import Button from './Button.jsx';

/**
 * Loading, empty and error states.
 *
 * Every async surface on the site uses these three so a slow network, a query
 * with no matches and a failed content load never look like a broken page.
 */

export function Skeleton({ className = '' }) {
  return <span className={`skeleton block ${className}`} aria-hidden="true" />;
}

/** Placeholder in the shape of a card, so grids don't jump when data lands. */
export function CardSkeleton({ className = '' }) {
  return (
    <div className={`surface p-5 ${className}`} aria-hidden="true">
      <Skeleton className="h-11 w-11 rounded-md" />
      <Skeleton className="mt-5 h-4 w-2/3" />
      <Skeleton className="mt-2.5 h-3 w-full" />
      <Skeleton className="mt-2 h-3 w-4/5" />
    </div>
  );
}

export function CardGridSkeleton({ count = 6, className = 'sm:grid-cols-2 lg:grid-cols-3' }) {
  return (
    <div className={`grid gap-5 ${className}`} role="status" aria-label="Loading">
      {Array.from({ length: count }, (_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  );
}

export function RowSkeleton({ count = 4 }) {
  return (
    <div className="divide-y divide-ink/[0.07]" role="status" aria-label="Loading">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="flex items-center gap-4 py-4">
          <Skeleton className="h-9 w-9 shrink-0 rounded-md" />
          <div className="min-w-0 flex-1">
            <Skeleton className="h-3.5 w-1/3" />
            <Skeleton className="mt-2 h-3 w-3/4" />
          </div>
        </div>
      ))}
    </div>
  );
}

export function EmptyState({
  icon: Icon = SearchX,
  title = 'Nothing here yet',
  message,
  action,
  className = '',
}) {
  return (
    <div className={`surface stitch relative px-6 py-14 text-center ${className}`}>
      <span
        className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full
                   bg-paper-2 text-ink-faint"
      >
        <Icon size={22} strokeWidth={1.6} aria-hidden="true" />
      </span>
      <h3 className="text-lg text-ink">{title}</h3>
      {message && (
        <p className="mx-auto mt-2 max-w-md text-sm leading-relaxed text-ink-soft">{message}</p>
      )}
      {action && (
        <div className="mt-6 flex justify-center">
          <Button variant="secondary" size="sm" to={action.to} onClick={action.onClick} withArrow>
            {action.label}
          </Button>
        </div>
      )}
    </div>
  );
}

/**
 * Shown when the content set itself fails to load. It says what happened rather
 * than pretending the library is empty, and offers a retry.
 */
export function ErrorState({ onRetry, className = '' }) {
  return (
    <EmptyState
      icon={TriangleAlert}
      title="This didn’t load"
      message="The content library couldn’t be reached. Check your connection and try again — the app itself works fully offline."
      action={onRetry ? { label: 'Try again', onClick: onRetry } : undefined}
      className={className}
    />
  );
}
