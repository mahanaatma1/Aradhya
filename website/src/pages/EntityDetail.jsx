import { Link, useParams } from 'react-router-dom';
import { CalendarDays, ChevronRight, Clock, Compass, MapPin, Sparkles } from 'lucide-react';
import Glyph from '../components/art/Glyph.jsx';
import Chip, { Badge } from '../components/ui/Chip.jsx';
import SourceNote, { ContentNote } from '../components/ui/SourceNote.jsx';
import RelatedContent from '../components/RelatedContent.jsx';
import { ContinueInAradhya } from '../components/app/MobileAppCTA.jsx';
import { CardGridSkeleton, ErrorState, Skeleton } from '../components/ui/States.jsx';
import NotFound from './NotFound.jsx';
import { getRecord, contentKeys } from '../services/contentService.js';
import { gradientFor } from '../config/taxonomy.js';
import { routes } from '../config/routes.js';
import { appConfig } from '../config/appConfig.js';
import { entityJsonLd } from '../config/seo.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /explore/:slug — the page a Google search lands on.
 *
 * This is the whole point of the website: someone searches "Who is Bhishma?",
 * arrives here, reads a sourced summary, follows a relation or two, and takes the
 * thread into the app.
 *
 * Nothing on this page is written by hand. Every field rendered exists on the
 * record, and a field that is missing is simply absent rather than filled in.
 */
export default function EntityDetail() {
  const { slug } = useParams();
  const {
    data: record,
    loading,
    error,
    reload,
  } = useAsync(() => getRecord(slug), [slug], { preloadKey: contentKeys.record(slug) });

  useSeo({
    title: record?.title,
    description: record?.summary,
    type: 'article',
    // A slug we cannot resolve must not be indexed as a real page.
    noindex: !loading && !record,
    jsonLd: record ? entityJsonLd(record) : null,
  });

  if (loading) return <DetailSkeleton />;
  if (error) {
    return (
      <div className="shell py-section pt-36">
        <ErrorState onRetry={reload} />
      </div>
    );
  }
  if (!record) return <NotFound />;

  const [from, to] = gradientFor(record.accent);

  return (
    <article className="pb-section">
      {/* Coloured plate: the same gradient the record carries everywhere else. */}
      <header
        className="relative overflow-hidden pb-12 pt-28 text-white sm:pb-16 sm:pt-36"
        style={{ background: `linear-gradient(150deg, ${from}, ${to})` }}
      >
        <Glyph
          name={record.glyph}
          size={340}
          strokeWidth={0.45}
          className="pointer-events-none absolute -right-16 -top-10 text-white/[0.11]"
        />

        <div className="shell relative">
          <Breadcrumb record={record} />

          <div className="mt-6 flex flex-wrap items-center gap-3">
            <Badge tone="onColor">{record.badge}</Badge>
            {record.kind === 'journey' && record.level && (
              <Badge tone="onColor">{record.level}</Badge>
            )}
          </div>

          <h1 className="mt-4 font-display text-[2.4rem] font-semibold leading-[1.08] sm:text-[3.4rem]">
            {record.title}
          </h1>
          {record.titleHi && (
            <p className="mt-2 font-deva text-[1.35rem] text-white/75 sm:text-[1.7rem]">
              {record.titleHi}
            </p>
          )}
          {record.summary && (
            <p className="mt-6 max-w-2xl text-[1.05rem] leading-relaxed text-white/85">
              {record.summary}
            </p>
          )}

          {record.aliases?.length > 0 && (
            <p className="mt-5 text-[0.86rem] text-white/70">
              <span className="uppercase tracking-[0.14em] text-white/50">Also called</span>{' '}
              {record.aliases.join(' · ')}
            </p>
          )}
        </div>
      </header>

      <div className="shell mt-12">
        <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_20rem] lg:gap-14">
          <div className="min-w-0">
            {/* Long-form detail, when the curated row carries it. */}
            {record.detail && (
              <section>
                <h2 className="text-display-sm text-ink">In more depth</h2>
                <p className="mt-4 whitespace-pre-line text-[1.02rem] leading-[1.75] text-ink-soft">
                  {record.detail}
                </p>
              </section>
            )}

            {record.meaning && (
              <section className="mt-10">
                <h2 className="text-display-sm text-ink">What the name means</h2>
                <p className="mt-4 text-[1.02rem] leading-[1.75] text-ink-soft">{record.meaning}</p>
              </section>
            )}

            <FestivalFacts record={record} />
            <JourneySteps record={record} />

            {record.summaryHi && (
              <section className="mt-10">
                <h2 className="text-display-sm text-ink">हिंदी में</h2>
                <p className="mt-4 font-deva text-[1.05rem] leading-[1.85] text-ink-soft">
                  {record.summaryHi}
                </p>
              </section>
            )}

            {/* No detail body at all — say so instead of padding the page. */}
            {!record.detail && !record.meaning && record.kind === 'entity' && (
              <ContentNote>
                This entry is a sourced summary. The fuller treatment — with the passages it rests
                on — is in the app.
              </ContentNote>
            )}

            <SourceNote source={record.source} className="mt-10" />

            {record.tags?.length > 0 && (
              <div className="mt-8 flex flex-wrap items-center gap-1.5">
                {record.tags.slice(0, 10).map((tag) => (
                  <Chip key={tag} to={`${routes.search}?q=${encodeURIComponent(tag)}`}>
                    {tag}
                  </Chip>
                ))}
              </div>
            )}
          </div>

          <aside className="lg:sticky lg:top-28 lg:self-start">
            <ContinueInAradhya record={record} />
            <p className="mt-4 text-[0.8rem] leading-relaxed text-ink-faint">
              {appConfig.name} holds this entry offline, alongside the text it comes from and
              everything connected to it.
            </p>
          </aside>
        </div>

        <RelatedContent
          slug={record.slug}
          lead="Follow a thread — each of these is stated in the curated set, not guessed at."
          className="mt-16"
        />
      </div>
    </article>
  );
}

function Breadcrumb({ record }) {
  return (
    <nav aria-label="Breadcrumb">
      <ol className="flex flex-wrap items-center gap-1.5 text-[0.82rem] text-white/70">
        <li>
          <Link to={routes.home} className="transition-colors hover:text-white">
            Home
          </Link>
        </li>
        <ChevronRight size={13} aria-hidden="true" className="text-white/40" />
        <li>
          <Link
            to={`${routes.explore}?facet=${record.facet}`}
            className="transition-colors hover:text-white"
          >
            {record.badge}
          </Link>
        </li>
        <ChevronRight size={13} aria-hidden="true" className="text-white/40" />
        <li aria-current="page" className="text-white">
          {record.title}
        </li>
      </ol>
    </nav>
  );
}

/** Festival fields, each rendered only when the row has it. */
function FestivalFacts({ record }) {
  if (record.kind !== 'festival') return null;

  const facts = [
    { icon: CalendarDays, label: 'When', value: record.when },
    { icon: MapPin, label: 'Kept in', value: record.region?.split(',').join(', ') },
    { icon: Sparkles, label: 'Tradition', value: record.tradition },
  ].filter((f) => f.value);

  if (!facts.length && !record.ritual) return null;

  return (
    <section className="mt-10">
      <h2 className="text-display-sm text-ink">How it is kept</h2>

      {facts.length > 0 && (
        <dl className="mt-5 grid gap-4 sm:grid-cols-3">
          {facts.map((fact) => (
            <div key={fact.label} className="surface p-4">
              <dt className="flex items-center gap-2 text-[0.72rem] uppercase tracking-[0.14em] text-ink-faint">
                <fact.icon size={13} strokeWidth={1.8} aria-hidden="true" />
                {fact.label}
              </dt>
              <dd className="mt-2 text-[0.95rem] capitalize text-ink">{fact.value}</dd>
            </div>
          ))}
        </dl>
      )}

      {record.ritual && (
        <p className="mt-5 text-[1.02rem] leading-[1.75] text-ink-soft">{record.ritual}</p>
      )}

      <ContentNote className="mt-6">
        Dates follow the lunar calendar and differ by region and tradition. The app calculates the
        panchang on your device for the place you are in.
      </ContentNote>
    </section>
  );
}

/** A journey's steps, in order. */
function JourneySteps({ record }) {
  if (record.kind !== 'journey' || !record.steps?.length) return null;

  return (
    <section className="mt-10">
      <h2 className="text-display-sm text-ink">The path</h2>
      <div className="mt-3 flex flex-wrap items-center gap-x-6 gap-y-2 text-[0.84rem] text-ink-faint">
        <span className="flex items-center gap-1.5">
          <Compass size={14} strokeWidth={1.8} aria-hidden="true" />
          {record.steps.length} steps
        </span>
        {record.minutes && (
          <span className="flex items-center gap-1.5">
            <Clock size={14} strokeWidth={1.8} aria-hidden="true" />
            about {record.minutes} minutes
          </span>
        )}
      </div>

      <ol className="mt-6 space-y-4 border-l border-dashed border-terra/35 pl-6">
        {record.steps.map((step) => (
          <li key={step.no} className="relative">
            <span
              aria-hidden="true"
              className="absolute -left-[1.93rem] top-1 flex h-6 w-6 items-center justify-center
                         rounded-full bg-terra/[0.1] font-display text-[0.7rem] font-semibold text-terra"
            >
              {step.no}
            </span>
            <h3 className="text-[1.02rem] text-ink">{step.title}</h3>
            {step.blurb && (
              <p className="mt-1 text-[0.93rem] leading-relaxed text-ink-soft">{step.blurb}</p>
            )}
          </li>
        ))}
      </ol>

      <ContentNote className="mt-6">
        Your place in a journey is remembered by the app on your device — this page shows the path,
        not your progress through it.
      </ContentNote>
    </section>
  );
}

function DetailSkeleton() {
  return (
    <div className="pb-section">
      <div className="bg-paper-2 pb-14 pt-32 sm:pt-40">
        <div className="shell">
          <Skeleton className="h-3 w-40" />
          <Skeleton className="mt-6 h-4 w-24 rounded-full" />
          <Skeleton className="mt-5 h-12 w-2/3" />
          <Skeleton className="mt-4 h-4 w-full max-w-2xl" />
          <Skeleton className="mt-2 h-4 w-4/5 max-w-xl" />
        </div>
      </div>
      <div className="shell mt-12">
        <Skeleton className="h-5 w-48" />
        <Skeleton className="mt-4 h-3 w-full" />
        <Skeleton className="mt-2 h-3 w-full" />
        <Skeleton className="mt-2 h-3 w-3/4" />
        <div className="mt-12">
          <CardGridSkeleton count={4} className="sm:grid-cols-2" />
        </div>
      </div>
    </div>
  );
}
