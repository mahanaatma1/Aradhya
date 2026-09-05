import { useMemo, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { BookOpen, ChevronDown } from 'lucide-react';
import { SceneCard } from '../components/cards/StoryCard.jsx';
import EntityCard from '../components/cards/EntityCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Chip from '../components/ui/Chip.jsx';
import Glyph from '../components/art/Glyph.jsx';
import { ContinueInAradhya } from '../components/app/MobileAppCTA.jsx';
import { CardSkeleton, EmptyState, ErrorState, RowSkeleton } from '../components/ui/States.jsx';
import { getEpic, listRecords } from '../services/contentService.js';
import { appConfig } from '../config/appConfig.js';
import { EPICS } from '../config/epics.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /ramayana and /mahabharata — one component, two routes.
 *
 * The two pages are structurally identical (books → arcs → scenes) and only the
 * data differs, so they share this file. Everything specific to an epic lives in
 * config/epics.js; nothing about the layout knows which one it is rendering.
 *
 * Scenes carry anchor ids (`#scene-<slug>`), which is how a search result for an
 * event lands on the event rather than the top of the page.
 */

export default function Epic({ epic }) {
  const config = EPICS[epic];

  const { data, loading, error, reload } = useAsync(
    () => Promise.all([getEpic(epic), listRecords({ tag: epic, kinds: ['entity'] })]),
    [epic],
  );
  const [structure, people] = data ?? [];

  useSeo({
    title: config.title,
    description: config.description,
    type: 'article',
  });

  const [openBook, setOpenBook] = useState(null);

  /**
   * Which book is open. First one by default — all of them expanded is a wall of
   * text — but a `#scene-…` or `#arc-…` link from search has to win, or the
   * anchor it points at would not exist in the DOM to scroll to.
   */
  const hashBook = useHashBook(structure);
  const activeBook = openBook ?? hashBook ?? structure?.books[0]?.no ?? null;

  const stats = useMemo(
    () =>
      structure
        ? [
            `${structure.books.length} books`,
            `${structure.arcCount} arcs`,
            `${structure.sceneCount} events`,
          ]
        : [],
    [structure],
  );

  return (
    <>
      <PageHeader
        eyebrow={config.eyebrow}
        title={config.title}
        titleHi={config.titleHi}
        lead={config.lead}
        meta={stats.map((s) => (
          <span key={s}>{s}</span>
        ))}
      >
        <Glyph
          name={config.glyph}
          size={300}
          strokeWidth={0.5}
          className="pointer-events-none absolute -right-10 -top-6 hidden text-terra/[0.07] lg:block"
        />
      </PageHeader>

      <div className="shell pb-section">
        {error ? (
          <ErrorState onRetry={reload} />
        ) : loading ? (
          <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_18rem]">
            <div className="surface p-6">
              <RowSkeleton count={5} />
            </div>
            <CardSkeleton className="h-64" />
          </div>
        ) : structure.books.length === 0 ? (
          <EmptyState
            title="This epic isn’t in the content set yet"
            message="The narrative pipeline covers it in stages; nothing is shown here until the rows are curated and cited."
          />
        ) : (
          <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_18rem] lg:gap-14">
            {/* Books → arcs → scenes */}
            <div className="min-w-0">
              {structure.books.map((book) => {
                const open = book.no === activeBook;
                return (
                  <section key={book.no} id={`book-${book.no}`} className="scroll-mt-28">
                    <button
                      type="button"
                      onClick={() => setOpenBook(open ? -1 : book.no)}
                      aria-expanded={open}
                      className="group flex w-full items-center gap-4 border-b border-ink/[0.08] py-5 text-left"
                    >
                      <span
                        className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md
                                   bg-terra/[0.08] font-display text-[0.9rem] font-semibold text-terra"
                      >
                        {book.no}
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block font-display text-[1.25rem] font-semibold text-ink">
                          {book.label}
                        </span>
                        <span className="mt-0.5 block text-[0.82rem] text-ink-faint">
                          {book.arcs.length} {book.arcs.length === 1 ? 'arc' : 'arcs'} ·{' '}
                          {book.arcs.reduce((n, a) => n + a.scenes.length, 0)} events
                        </span>
                      </span>
                      <ChevronDown
                        size={19}
                        strokeWidth={1.8}
                        aria-hidden="true"
                        className={`shrink-0 text-ink-faint transition-transform duration-300 ease-calm
                                    ${open ? 'rotate-180' : ''}`}
                      />
                    </button>

                    {open && (
                      <div className="animate-fade-in pt-7">
                        {book.arcs.map((arc) => (
                          <Arc key={arc.slug} arc={arc} people={people} />
                        ))}
                      </div>
                    )}
                  </section>
                );
              })}
            </div>

            <aside className="lg:sticky lg:top-28 lg:self-start">
              <ContinueInAradhya />
              <p className="mt-4 text-[0.8rem] leading-relaxed text-ink-faint">
                {appConfig.name} reads the whole epic offline, with audio and the passages behind
                each event.
              </p>

              {structure.cast.length > 0 && (
                <div className="mt-8">
                  <h2 className="eyebrow mb-4">Principal cast</h2>
                  <div className="space-y-3">
                    {structure.cast.slice(0, 6).map((person) => (
                      <EntityCard key={person.id} record={person} variant="compact" />
                    ))}
                  </div>
                </div>
              )}
            </aside>
          </div>
        )}
      </div>
    </>
  );
}

/**
 * Find the book that holds whatever the URL's hash points at, so a deep link to
 * a single event opens the section containing it. Returns null for no hash, an
 * unknown target, or `#book-n` (which the default already handles).
 */
function useHashBook(structure) {
  const { hash } = useLocation();

  return useMemo(() => {
    if (!structure || !hash) return null;
    const target = decodeURIComponent(hash.slice(1));

    const bookMatch = target.match(/^book-(\d+)$/);
    if (bookMatch) return Number(bookMatch[1]);

    const arcSlug = target.startsWith('arc-') ? target.slice(4) : null;
    const sceneSlug = target.startsWith('scene-') ? target.slice(6) : null;
    if (!arcSlug && !sceneSlug) return null;

    for (const book of structure.books) {
      for (const arc of book.arcs) {
        if (arcSlug && arc.slug === arcSlug) return book.no;
        if (sceneSlug && arc.scenes.some((s) => s.slug === sceneSlug)) return book.no;
      }
    }
    return null;
  }, [structure, hash]);
}

/** One arc, with its scenes in reading order. */
function Arc({ arc, people }) {
  // Resolve cast slugs to records once per arc, so SceneCard only ever links to
  // an entity that has a page.
  const bySlug = useMemo(() => new Map((people ?? []).map((p) => [p.slug, p])), [people]);

  return (
    <section id={`arc-${arc.slug}`} className="mb-12 scroll-mt-28">
      <div className="mb-5 flex flex-wrap items-baseline gap-x-3 gap-y-1">
        <h3 className="font-display text-[1.35rem] font-semibold text-ink">{arc.title}</h3>
        <Chip>
          <BookOpen size={12} strokeWidth={1.8} aria-hidden="true" />
          {arc.sceneCount} {arc.sceneCount === 1 ? 'event' : 'events'}
        </Chip>
      </div>

      {arc.summary && (
        <p className="mb-6 max-w-prose text-[0.98rem] leading-[1.75] text-ink-soft">
          {arc.summary}
        </p>
      )}

      <div className="space-y-4">
        {arc.scenes.map((scene) => (
          <SceneCard
            key={scene.slug}
            scene={scene}
            cast={scene.cast.map((slug) => bySlug.get(slug)).filter(Boolean)}
          />
        ))}
      </div>
    </section>
  );
}
