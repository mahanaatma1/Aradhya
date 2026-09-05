import TempleCard from '../components/cards/TempleCard.jsx';
import EntityCard from '../components/cards/EntityCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import { ContentNote } from '../components/ui/SourceNote.jsx';
import { CardGridSkeleton } from '../components/ui/States.jsx';
import { getSacredGeography, getTemples } from '../services/contentService.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /temples — pilgrimage sites and sacred geography.
 *
 * The honesty constraint here is the important one: these are the tirthas the
 * curated set covers, with sourced summaries. No temple facts are invented — no
 * timings, no founding dates, no deity attributions beyond what the row carries —
 * and the note below says exactly what this page is and is not.
 */
export default function Temples() {
  useSeo(PAGE_META[routes.temples]);

  const { data, loading } = useAsync(
    () => Promise.all([getTemples(), getSacredGeography()]),
    [],
  );
  const [tirthas, geography] = data ?? [];

  return (
    <>
      <PageHeader
        eyebrow="Sacred places"
        title="Places that hold their stories"
        titleHi="तीर्थ"
        lead="A tirtha is a crossing — a place where the distance between here and elsewhere is said to be thinner. These are the ones the library covers, and why each one is kept."
        meta={
          tirthas && (
            <>
              <span>{tirthas.length} pilgrimage sites</span>
              {geography?.length > 0 && <span>{geography.length} rivers and mountains</span>}
            </>
          )
        }
      />

      <div className="shell pb-section">
        {loading ? (
          <CardGridSkeleton count={8} />
        ) : (
          <>
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {tirthas.map((temple, i) => (
                <Reveal key={temple.id} delay={Math.min(i, 7) * 45}>
                  <TempleCard record={temple} className="h-full" />
                </Reveal>
              ))}
            </div>

            <ContentNote className="mt-9 max-w-2xl">
              These entries describe places and their significance in the texts. Per-temple
              records — deity, town, state, timings — live in the app’s temple directory; nothing of
              that kind is stated here unless the curated set carries it. The artwork on each card
              is a drawn silhouette, not a photograph of the named place.
            </ContentNote>

            {geography?.length > 0 && (
              <section className="mt-16">
                <h2 className="text-display-sm text-ink">Rivers and mountains</h2>
                <p className="mt-3 max-w-prose text-[0.98rem] leading-relaxed text-ink-soft">
                  Sacred geography that is not a pilgrimage site in itself — the waters and heights
                  the stories keep returning to.
                </p>
                <div className="mt-7 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  {geography.map((place) => (
                    <EntityCard key={place.id} record={place} variant="compact" />
                  ))}
                </div>
              </section>
            )}
          </>
        )}
      </div>
    </>
  );
}
