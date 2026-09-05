import StoryCard from '../cards/StoryCard.jsx';
import EntityCard from '../cards/EntityCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Reveal from '../ui/Reveal.jsx';
import Section from '../ui/Section.jsx';
import { getEpic } from '../../services/contentService.js';
import { routes } from '../../config/routes.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Read the great stories differently."
 *
 * The numbers on each card are counted from the content set at render time, so
 * they can never drift from what the site actually holds — if a book is added to
 * the pipeline, the card says so without anyone editing this file.
 */
export default function EpicsShowcase() {
  const { data, loading } = useAsync(
    () => Promise.all([getEpic('ramayana'), getEpic('mahabharata')]),
    [],
  );

  const [ramayana, mahabharata] = data ?? [];

  // Two big editorial cards: side by side from lg, swipeable below it.
  const epicRail = {
    label: 'The epics',
    stop: 'lg',
    cols: 'lg:grid-cols-2',
    itemWidth: 'w-[19rem] sm:w-[26rem]',
  };

  return (
    <Section
      eyebrow="The epics"
      title="Read the great stories differently."
      lead="Not one long wall of text. Each epic is broken into books, arcs and single events — so you can follow the thread, see who is in the room, and stop where you like."
      action={{ to: routes.stories, label: 'Both epics' }}
    >
      {loading ? (
        <CardRail {...epicRail} loading skeletonCount={2} skeletonClassName="h-[19rem]" />
      ) : (
        <>
          <CardRail {...epicRail}>
            <StoryCard
              to={routes.ramayana}
              eyebrow="Valmiki Ramayana"
              title="Ramayana"
              titleHi="रामायण"
              blurb="Exile, abduction and return — the story of Rama read as a sequence of events, each one with its cast and its source."
              meta={metaFor(ramayana)}
              glyph="bow"
              accent="epics"
              className="h-full"
            />
            <StoryCard
              to={routes.mahabharata}
              eyebrow="Vyasa Mahabharata"
              title="Mahabharata"
              titleHi="महाभारत"
              blurb="A quarrel over a throne that becomes a question about duty — including the eighteen chapters spoken between two armies."
              meta={metaFor(mahabharata)}
              glyph="chakra"
              accent="katha"
              className="h-full"
            />
          </CardRail>

          {/* The faces of the epics — the most-referenced cast, counted, not chosen. */}
          <PrincipalCast ramayana={ramayana} mahabharata={mahabharata} />
        </>
      )}
    </Section>
  );
}

function metaFor(epic) {
  if (!epic) return [];
  return [
    { label: 'Books', value: epic.books.length },
    { label: 'Arcs', value: epic.arcCount },
    { label: 'Events', value: epic.sceneCount },
  ];
}

function PrincipalCast({ ramayana, mahabharata }) {
  const cast = [...(ramayana?.cast ?? []).slice(0, 4), ...(mahabharata?.cast ?? []).slice(0, 4)];
  if (!cast.length) return null;

  return (
    <div className="mt-12">
      <Reveal>
        <p className="eyebrow mb-4">Who you will meet</p>
      </Reveal>
      <CardRail
        label="Who you will meet"
        cols="sm:grid-cols-2 lg:grid-cols-4"
        itemWidth="w-[14rem]"
        gap="gap-2.5 sm:gap-3"
      >
        {cast.map((person) => (
          <EntityCard
            key={person.id}
            record={person}
            variant="compact"
            className="h-full bg-card/60 sm:bg-transparent"
          />
        ))}
      </CardRail>
    </div>
  );
}
