import StoryCard from '../components/cards/StoryCard.jsx';
import EntityCard from '../components/cards/EntityCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import { CardSkeleton } from '../components/ui/States.jsx';
import { getEpic } from '../services/contentService.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/** /stories — the doorway to both epics, and the cast they share. */
export default function Stories() {
  useSeo(PAGE_META[routes.stories]);

  const { data, loading } = useAsync(
    () => Promise.all([getEpic('ramayana'), getEpic('mahabharata')]),
    [],
  );
  const [ramayana, mahabharata] = data ?? [];

  const totals = data
    ? {
        scenes: ramayana.sceneCount + mahabharata.sceneCount,
        arcs: ramayana.arcCount + mahabharata.arcCount,
      }
    : null;

  return (
    <>
      <PageHeader
        eyebrow="Stories"
        title="The great epics"
        titleHi="महाकाव्य"
        lead="Two stories long enough to hold a whole tradition inside them. Read in order, or drop into the event you came for."
        meta={
          totals && (
            <>
              <span>{totals.scenes} events</span>
              <span>{totals.arcs} arcs</span>
              <span>2 epics</span>
            </>
          )
        }
      />

      <div className="shell pb-section">
        {loading ? (
          <div className="grid gap-5 lg:grid-cols-2">
            <CardSkeleton className="h-[22rem]" />
            <CardSkeleton className="h-[22rem]" />
          </div>
        ) : (
          <>
            <div className="grid gap-5 lg:grid-cols-2">
              <Reveal>
                <StoryCard
                  to={routes.ramayana}
                  eyebrow={`${ramayana.books.length} books`}
                  title="Ramayana"
                  titleHi="रामायण"
                  blurb="Exile, abduction and return — read as a sequence of events, each with its cast and its source."
                  meta={[
                    { label: 'Books', value: ramayana.books.length },
                    { label: 'Arcs', value: ramayana.arcCount },
                    { label: 'Events', value: ramayana.sceneCount },
                  ]}
                  glyph="bow"
                  accent="epics"
                  className="h-full"
                />
              </Reveal>
              <Reveal delay={90}>
                <StoryCard
                  to={routes.mahabharata}
                  eyebrow={`${mahabharata.books.length} books`}
                  title="Mahabharata"
                  titleHi="महाभारत"
                  blurb="A quarrel over a throne that becomes a question about duty — including the words spoken between two armies."
                  meta={[
                    { label: 'Books', value: mahabharata.books.length },
                    { label: 'Arcs', value: mahabharata.arcCount },
                    { label: 'Events', value: mahabharata.sceneCount },
                  ]}
                  glyph="chakra"
                  accent="katha"
                  className="h-full"
                />
              </Reveal>
            </div>

            <EpicCast epic={ramayana} title="The Ramayana’s cast" />
            <EpicCast epic={mahabharata} title="The Mahabharata’s cast" />
          </>
        )}
      </div>
    </>
  );
}

/** Cast ordered by how often the content set actually places them in a scene. */
function EpicCast({ epic, title }) {
  if (!epic?.cast?.length) return null;

  return (
    <section className="mt-16">
      <h2 className="text-display-sm text-ink">{title}</h2>
      <p className="mt-3 max-w-prose text-[0.95rem] text-ink-soft">
        Ordered by how many events they appear in — counted, not ranked by hand.
      </p>
      <div className="mt-7 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {epic.cast.map((person) => (
          <EntityCard key={person.id} record={person} variant="compact" />
        ))}
      </div>
    </section>
  );
}
