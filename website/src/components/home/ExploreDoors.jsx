import FeatureCard from '../cards/FeatureCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Section from '../ui/Section.jsx';
import { EXPLORE_DOORS } from '../../config/taxonomy.js';
import { routes } from '../../config/routes.js';

/**
 * "One place to explore." — the eight doors into the library.
 *
 * These are product navigation, not content, so they come from the taxonomy
 * rather than the content set. Every `to` points at a route that exists.
 *
 * Eight doors stacked one per screen is a long scroll on a phone, so below `sm`
 * they become a swipeable rail.
 */
export default function ExploreDoors() {
  return (
    <Section
      id="explore"
      eyebrow="Explore"
      title="One place to explore."
      lead="Scriptures, epics, sacred places, deities, festivals and daily practice — each one a way in, none of them a dead end."
      action={{ to: routes.explore, label: 'Browse everything' }}
      tone="kraft"
      ornament
    >
      <CardRail
        label="Ways to explore"
        cols="sm:grid-cols-2 lg:grid-cols-4"
        itemWidth="w-[14.5rem]"
      >
        {EXPLORE_DOORS.map((door) => (
          <FeatureCard key={door.id} door={door} className="h-full" />
        ))}
      </CardRail>
    </Section>
  );
}
