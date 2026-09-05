import EntityCard from './cards/EntityCard.jsx';
import { CardGridSkeleton } from './ui/States.jsx';
import { getRelated } from '../services/contentService.js';
import useAsync from '../hooks/useAsync.js';

/**
 * Related content for a detail page.
 *
 * The order is deliberate — declared relations first (they carry a stated,
 * directional label), then narrative appearances and festivals, then shared-tag
 * neighbours. A relation is only shown when the content set actually asserts it.
 */
export default function RelatedContent({
  slug,
  title = 'Everything is connected',
  lead,
  limit = 8,
  className = '',
}) {
  const { data, loading } = useAsync(() => getRelated(slug, limit), [slug, limit]);

  if (loading) return <CardGridSkeleton count={4} className="sm:grid-cols-2" />;
  if (!data?.length) return null;

  return (
    <section className={className} aria-label={title}>
      <div className="mb-6">
        <h2 className="text-display-sm text-ink">{title}</h2>
        {lead && <p className="mt-2 text-[0.95rem] text-ink-soft">{lead}</p>}
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        {data.map((record) => (
          <EntityCard key={record.id} record={record} showRelation />
        ))}
      </div>
    </section>
  );
}
