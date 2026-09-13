import ScriptureCard from '../components/cards/ScriptureCard.jsx';
import EntityCard from '../components/cards/EntityCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import { ContentNote } from '../components/ui/SourceNote.jsx';
import { CardGridSkeleton } from '../components/ui/States.jsx';
import { getCollections, listRecords, allSync, contentKeys } from '../services/contentService.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /scriptures — the shelf.
 *
 * No verse text appears on this page. Reproducing a verse means reproducing a
 * particular translation, and the curated set keeps translations with their
 * attribution inside the app; here the collections are described and linked.
 */
export default function Scriptures() {
  useSeo(PAGE_META[routes.scriptures]);

  const { data, loading } = useAsync(
    () => allSync([getCollections(), listRecords({ facet: 'scriptures', kinds: ['entity'] })]),
    [],
    { preloadKey: contentKeys.scripturesPage },
  );
  const [collections, texts] = data ?? [];

  return (
    <>
      <PageHeader
        eyebrow="Scriptures"
        title="The texts"
        titleHi="शास्त्र"
        lead="Each text keeps its own shape — chapters where there are chapters, hymns where there are hymns. Start with whichever one you were looking for."
      />

      <div className="shell pb-section">
        {loading ? (
          <CardGridSkeleton count={6} />
        ) : (
          <>
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {collections.map((collection, i) => (
                <Reveal key={collection.id} delay={i * 50}>
                  <ScriptureCard collection={collection} className="h-full" />
                </Reveal>
              ))}
            </div>

            <ContentNote className="mt-8 max-w-2xl">
              Verse text, transliteration and translation are read in the app, where every verse
              carries the translation it came from. This page describes the texts rather than
              quoting them.
            </ContentNote>

            {texts?.length > 0 && (
              <section className="mt-16">
                <h2 className="text-display-sm text-ink">Every text in the library</h2>
                <p className="mt-3 max-w-prose text-[0.98rem] leading-relaxed text-ink-soft">
                  Individual works the curated set covers, each with a sourced summary of what it
                  is and where it sits in the tradition.
                </p>
                <div className="mt-7 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  {texts.map((text) => (
                    <EntityCard key={text.id} record={text} variant="compact" />
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
