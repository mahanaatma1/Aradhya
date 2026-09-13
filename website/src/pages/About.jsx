import { Link } from 'react-router-dom';
import { BookOpen, Database, Mail, ShieldCheck } from 'lucide-react';
import PageHeader from '../components/ui/PageHeader.jsx';
import Section from '../components/ui/Section.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import { RowSkeleton } from '../components/ui/States.jsx';
import { getSources, getStats, allSync, contentKeys } from '../services/contentService.js';
import { appConfig } from '../config/appConfig.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useAsync from '../hooks/useAsync.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /about — what this is, where the content comes from, and what it is not.
 *
 * The source list is generated from the content set, so the page cannot claim a
 * text it does not actually cite, and the counts cannot go stale.
 */

const PRINCIPLES = [
  {
    icon: BookOpen,
    title: 'Every entry names its source',
    body: 'Each row is drawn from a public-domain translation or an open dataset, and carries that citation with it. If a claim has no source, it is not in the set.',
  },
  {
    icon: ShieldCheck,
    title: 'Where traditions differ, we say so',
    body: 'A great deal of this material is told differently in different regions and sampradayas. The set records the variation rather than picking a winner and presenting it as the fact.',
  },
  {
    icon: Database,
    title: 'The app is the full experience',
    body: 'This website is a way in — searchable, linkable, readable from a search result. The app holds the whole library, works without a connection, and keeps your practice on your device.',
  },
];

export default function About() {
  useSeo(PAGE_META[routes.about]);

  const { data, loading } = useAsync(() => allSync([getStats(), getSources()]), [], {
    preloadKey: contentKeys.aboutPage,
  });
  const [stats, sources] = data ?? [];

  return (
    <>
      <PageHeader
        eyebrow="About"
        title="Explore. Understand. Practice."
        lead={`${appConfig.name} is an attempt at something specific: a calm, sourced, offline place to read India’s spiritual heritage — without a feed, an algorithm, or anyone’s opinion in the way.`}
      />

      <div className="shell">
        <div className="grid gap-6 lg:grid-cols-3">
          {PRINCIPLES.map((principle, i) => (
            <Reveal key={principle.title} delay={i * 70}>
              <div className="surface h-full p-6">
                <span
                  className="flex h-11 w-11 items-center justify-center rounded-md bg-terra/[0.08]
                             text-terra"
                >
                  <principle.icon size={19} strokeWidth={1.7} aria-hidden="true" />
                </span>
                <h2 className="mt-5 text-[1.08rem] text-ink">{principle.title}</h2>
                <p className="mt-2.5 text-[0.93rem] leading-relaxed text-ink-soft">
                  {principle.body}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>

      {/* The set, counted. */}
      <Section
        eyebrow="The library"
        title="What is actually in here."
        lead="These numbers are counted from the content set every time this page renders, so they cannot drift from what the site holds."
        tone="kraft"
        ornament
        className="mt-16"
      >
        {stats && (
          <dl className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {[
              { label: 'Entries', value: stats.entities, note: 'people, places, deities, ideas' },
              { label: 'Relationships', value: stats.relations, note: 'stated, not inferred' },
              { label: 'Story events', value: stats.scenes, note: `across ${stats.arcs} arcs` },
              { label: 'Festivals', value: stats.festivals, note: `and ${stats.journeys} journeys` },
            ].map((stat) => (
              <div key={stat.label} className="surface p-6">
                <dd className="font-display text-[2.4rem] font-semibold leading-none text-terra">
                  {stat.value.toLocaleString()}
                </dd>
                <dt className="mt-3 text-[0.95rem] font-medium text-ink">{stat.label}</dt>
                <p className="mt-1 text-[0.82rem] text-ink-faint">{stat.note}</p>
              </div>
            ))}
          </dl>
        )}

        {stats && (
          <p className="mt-7 text-[0.88rem] text-ink-soft">
            {stats.cited} of {stats.entities} entries carry a primary citation. The rest are
            structural — a category or a grouping — and assert nothing that would need one.
          </p>
        )}
      </Section>

      {/* Sources, generated from the set. */}
      <Section
        eyebrow="Sources"
        title="Where it comes from."
        lead="The texts and datasets behind the library, with how many entries draw on each. All public domain or openly licensed."
      >
        {loading ? (
          <div className="surface p-6">
            <RowSkeleton count={6} />
          </div>
        ) : (
          <div className="surface overflow-hidden">
            <ul className="divide-y divide-ink/[0.07]">
              {sources.map((source) => (
                <li
                  key={source.label}
                  className="flex items-center justify-between gap-4 px-5 py-4 sm:px-6"
                >
                  <span className="min-w-0 text-[0.95rem] text-ink">{source.label}</span>
                  <span className="shrink-0 text-[0.82rem] text-ink-faint">
                    {source.count} {source.count === 1 ? 'entry' : 'entries'}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="mt-8 max-w-2xl rounded-lg border border-dashed border-ink/15 bg-paper-2/50 p-6">
          <h3 className="text-[1rem] text-ink">What this is not</h3>
          <p className="mt-2.5 text-[0.92rem] leading-relaxed text-ink-soft">
            Not a religious authority, and not a substitute for a teacher or your own tradition’s
            practice. It does not tell you what to believe, and it will not answer a question the
            sources do not answer. Where something is contested, it is marked as contested.
          </p>
        </div>
      </Section>

      {/* Contact — the footer links here. */}
      <Section id="contact" eyebrow="Contact" title="Get in touch." tone="kraft" ornament>
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <a
            href={`mailto:${appConfig.contactEmail}`}
            className="surface group flex items-center gap-4 p-5 transition-all duration-300 ease-calm
                       hover:-translate-y-0.5 hover:border-terra/30 hover:shadow-lift"
          >
            <span
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md
                         bg-terra/[0.08] text-terra"
            >
              <Mail size={19} strokeWidth={1.7} aria-hidden="true" />
            </span>
            <span className="min-w-0">
              <span className="block text-[0.95rem] font-medium text-ink">Email</span>
              <span className="block truncate text-[0.84rem] text-ink-soft">
                {appConfig.contactEmail}
              </span>
            </span>
          </a>

          {appConfig.social.map((social) => (
            <a
              key={social.label}
              href={social.url}
              target="_blank"
              rel="noreferrer noopener"
              className="surface group flex items-center gap-4 p-5 transition-all duration-300 ease-calm
                         hover:-translate-y-0.5 hover:border-terra/30 hover:shadow-lift"
            >
              <span
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md
                           bg-terra/[0.08] font-display text-[0.9rem] font-semibold text-terra"
              >
                {social.label[0]}
              </span>
              <span className="min-w-0">
                <span className="block text-[0.95rem] font-medium text-ink">{social.label}</span>
                <span className="block truncate text-[0.84rem] text-ink-soft">{social.handle}</span>
              </span>
            </a>
          ))}
        </div>

        <p className="mt-8 text-[0.9rem] text-ink-soft">
          Found something wrong? Corrections are the most useful thing you can send — cite the
          passage and it will be checked against the source.{' '}
          <Link to={routes.privacy} className="link-quiet font-medium">
            How we handle data
          </Link>
        </p>
      </Section>
    </>
  );
}
