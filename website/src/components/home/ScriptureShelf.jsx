import { Link } from 'react-router-dom';
import { ArrowRight, Quote } from 'lucide-react';
import ScriptureCard from '../cards/ScriptureCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Reveal from '../ui/Reveal.jsx';
import Section from '../ui/Section.jsx';
import { getCollections, getTrivia, allSync, contentKeys } from '../../services/contentService.js';
import { routes } from '../../config/routes.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "From a verse to a deeper understanding."
 *
 * The panel underneath the cards is deliberately not a verse. Quoting scripture
 * means quoting a particular translation, and a translation belongs to whoever
 * made it — so the website shows a cited statement *about* the texts and leaves
 * verse text to the app, where every verse carries its translator's name.
 */
export default function ScriptureShelf() {
  const { data, loading } = useAsync(
    () => allSync([getCollections(), getTrivia(1)]),
    [],
    { preloadKey: contentKeys.homeScriptures },
  );

  const [collections, trivia] = data ?? [];
  const note = trivia?.[0];

  return (
    <Section
      eyebrow="Scriptures"
      title="From a verse to a deeper understanding."
      lead="Each text keeps its own shape — chapters where there are chapters, hymns where there are hymns — with meaning alongside the words rather than buried under them."
      action={{ to: routes.scriptures, label: 'All scriptures' }}
    >
      {loading ? (
        <CardRail
          label="Scriptures"
          loading
          skeletonCount={3}
          skeletonClassName="h-60"
          cols="sm:grid-cols-2 lg:grid-cols-3"
          itemWidth="w-[15.5rem]"
        />
      ) : (
        <CardRail
          label="Scriptures"
          cols="sm:grid-cols-2 lg:grid-cols-3"
          itemWidth="w-[15.5rem]"
        >
          {collections.map((collection) => (
            <ScriptureCard key={collection.id} collection={collection} className="h-full" />
          ))}
        </CardRail>
      )}

      {note && (
        <Reveal className="mt-12" delay={80}>
          <figure
            className="surface stitch relative mx-auto max-w-3xl px-7 py-9 text-center sm:px-12"
          >
            <Quote
              size={26}
              strokeWidth={1.4}
              aria-hidden="true"
              className="mx-auto mb-5 text-terra/45"
            />
            <blockquote className="font-display text-[1.18rem] leading-relaxed text-ink sm:text-[1.35rem]">
              {note.fact}
            </blockquote>
            <figcaption className="mt-5 text-[0.78rem] uppercase tracking-[0.16em] text-ink-faint">
              {note.source}
            </figcaption>

            <p className="mx-auto mt-7 max-w-md text-[0.84rem] leading-relaxed text-ink-soft">
              Verse text, transliteration and translation are read in the app, where each verse
              keeps the translation it came from.
            </p>
            <Link
              to={routes.entity('bhagavad-gita')}
              className="group mt-4 inline-flex items-center gap-1.5 text-[0.86rem] font-medium
                         text-terra transition-colors hover:text-terra-dark"
            >
              Start with the Bhagavad Gita
              <ArrowRight
                size={14}
                strokeWidth={2}
                aria-hidden="true"
                className="transition-transform duration-300 ease-calm group-hover:translate-x-1"
              />
            </Link>
          </figure>
        </Reveal>
      )}
    </Section>
  );
}
