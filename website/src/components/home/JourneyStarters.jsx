import JourneyCard from '../cards/JourneyCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Section from '../ui/Section.jsx';
import { getJourneys } from '../../services/contentService.js';
import { routes } from '../../config/routes.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Don't know where to start?" — the guided journeys.
 *
 * Steps, timings and levels all come from the curated journey rows; this section
 * picks the first three and links to the rest.
 *
 * These cards are tall, so they stay a rail all the way up to `lg` rather than
 * becoming a two-up grid that leaves one orphan.
 */
export default function JourneyStarters() {
  const { data: journeys, loading } = useAsync(() => getJourneys(3), []);

  const rail = {
    label: 'Journeys',
    stop: 'lg',
    cols: 'lg:grid-cols-3',
    itemWidth: 'w-[17rem] sm:w-[19rem]',
  };

  return (
    <Section
      eyebrow="Journeys"
      title="Don’t know where to start?"
      lead="A curated path, a few minutes at a time, in an order that makes sense. Begin at the beginning and the rest follows."
      action={{ to: routes.journeys, label: 'All journeys' }}
      tone="kraft"
      ornament
    >
      {loading ? (
        <CardRail {...rail} loading skeletonCount={3} skeletonClassName="h-80" />
      ) : (
        <CardRail {...rail}>
          {journeys.map((journey) => (
            <JourneyCard key={journey.id} journey={journey} className="h-full" />
          ))}
        </CardRail>
      )}
    </Section>
  );
}
