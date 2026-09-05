import TempleCard from '../cards/TempleCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Section from '../ui/Section.jsx';
import { ContentNote } from '../ui/SourceNote.jsx';
import { getTemples } from '../../services/contentService.js';
import { routes } from '../../config/routes.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * The temples section — a horizontal rail at every width, per the spec.
 *
 * `stop="none"` keeps it a rail even on a wide screen, because ten places read
 * better as a strip you push along than as a grid three rows deep.
 *
 * These are the tirthas the curated set covers — sites and cities. The note at
 * the end says so rather than implying a complete temple directory.
 */
export default function TempleRail() {
  const { data: temples, loading } = useAsync(() => getTemples(10), []);

  const rail = {
    label: 'Sacred places',
    stop: 'none',
    itemWidth: 'w-[15.5rem] sm:w-[19rem]',
  };

  return (
    <Section
      eyebrow="Sacred places"
      title="Places that hold their stories."
      lead="Char Dham, Jyotirlingas, Shakti Peethas and the cities along the rivers — why each place matters, and which story happened there."
      action={{ to: routes.temples, label: 'All places' }}
    >
      {loading ? (
        <CardRail {...rail} loading skeletonCount={4} skeletonClassName="h-72" />
      ) : (
        <CardRail {...rail}>
          {temples.map((temple) => (
            <TempleCard key={temple.id} record={temple} className="h-full" />
          ))}
        </CardRail>
      )}

      <ContentNote className="mt-7 max-w-2xl">
        These are pilgrimage sites and sacred cities. Individual temple records — deity, town,
        state, timings — live in the app’s temple directory, and are not reproduced here unless
        the curated set carries them.
      </ContentNote>
    </Section>
  );
}
