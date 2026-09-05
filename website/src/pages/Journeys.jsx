import JourneyCard from '../components/cards/JourneyCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import Section from '../components/ui/Section.jsx';
import LearnByPlay from '../components/home/LearnByPlay.jsx';
import { CardGridSkeleton } from '../components/ui/States.jsx';
import { ContentNote } from '../components/ui/SourceNote.jsx';
import { getJourneys } from '../services/contentService.js';
import { LEVEL_LABELS } from '../config/taxonomy.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /journeys — guided paths, then the quiz and trivia surfaces.
 *
 * Journeys are grouped by level so a first-time reader can see where to start
 * without reading every card. The grouping is derived from the rows, so a level
 * with nothing in it does not appear.
 */
export default function Journeys() {
  useSeo(PAGE_META[routes.journeys]);

  const { data: journeys, loading } = useAsync(() => getJourneys(), []);

  const levels = journeys
    ? Object.keys(LEVEL_LABELS)
        .map((level) => ({ level, items: journeys.filter((j) => j.level === level) }))
        .filter((group) => group.items.length > 0)
    : [];

  // Any row whose level is not one of the three known values still gets shown.
  const known = new Set(Object.keys(LEVEL_LABELS));
  const other = journeys?.filter((j) => !known.has(j.level)) ?? [];

  return (
    <>
      <PageHeader
        eyebrow="Journeys"
        title="Where to start"
        titleHi="यात्रा"
        lead="A tradition this large has no obvious front door. These are paths through it — short, ordered, and built so each step makes the next one easier."
        meta={journeys && <span>{journeys.length} journeys</span>}
      />

      <div className="shell">
        {loading ? (
          <CardGridSkeleton count={6} />
        ) : (
          <>
            {levels.map((group, gi) => (
              <section key={group.level} className={gi > 0 ? 'mt-16' : ''}>
                <h2 className="text-display-sm text-ink">{LEVEL_LABELS[group.level]}</h2>
                <div className="mt-7 grid gap-5 lg:grid-cols-3">
                  {group.items.map((journey, i) => (
                    <Reveal key={journey.id} delay={i * 60}>
                      <JourneyCard journey={journey} className="h-full" />
                    </Reveal>
                  ))}
                </div>
              </section>
            ))}

            {other.length > 0 && (
              <section className="mt-16">
                <h2 className="text-display-sm text-ink">More paths</h2>
                <div className="mt-7 grid gap-5 lg:grid-cols-3">
                  {other.map((journey) => (
                    <JourneyCard key={journey.id} journey={journey} />
                  ))}
                </div>
              </section>
            )}

            <ContentNote className="mt-10 max-w-2xl">
              A journey is a reading order, not a course — there is no certificate at the end. Where
              you are up to is remembered by the app on your device.
            </ContentNote>
          </>
        )}
      </div>

      {/* The spec's quiz/trivia/riddle surfaces, with their own anchors so the
          footer's #quiz and #trivia links land properly. */}
      <div id="quiz" className="scroll-mt-24">
        <LearnByPlay />
      </div>
      <span id="trivia" aria-hidden="true" />

      <Section
        eyebrow="Why it is built this way"
        title="Recall, not consumption."
        lead="Reading something once teaches you where it was on the page. Being asked about it a week later teaches you the thing itself — which is the only reason the quizzes exist."
        tone="kraft"
        align="center"
      />
    </>
  );
}
