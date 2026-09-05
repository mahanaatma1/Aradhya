import { Link } from 'react-router-dom';
import PageHeader from '../components/ui/PageHeader.jsx';
import { appConfig } from '../config/appConfig.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /terms — plain-language terms.
 *
 * Deliberately short and readable. Two points do real work: the content is
 * educational rather than authoritative, and the source texts are public domain
 * while the writing and software around them are not.
 */

const UPDATED = 'August 2026';

const SECTIONS = [
  {
    title: 'What you may do with it',
    body: `Read it, learn from it, quote it with attribution, and share links to it. ${appConfig.name} is free to use and there is nothing to subscribe to.`,
  },
  {
    title: 'What the content is',
    body: 'Educational and referential. It summarises what texts and traditions say, with a citation on each entry. It is not religious instruction, not a ruling on practice, and not a substitute for a teacher, a temple or your own tradition.',
  },
  {
    title: 'Where accuracy has limits',
    body: 'Sources disagree, translations differ, and regional practice varies enormously. The set records that variation where it can, but an entry can still be incomplete or wrong. Corrections with a passage cited are genuinely welcome and get checked.',
  },
  {
    title: 'Nothing here is medical, legal or financial advice',
    body: 'Some entries describe fasting, breathing practices and ritual observances as the tradition describes them. That is a description, not a recommendation. Use judgement, and ask a doctor about anything that affects your health.',
  },
  {
    title: 'Copyright, in two parts',
    body: 'The underlying scriptures and the translations drawn on are in the public domain or openly licensed, and each entry names which. The summaries, structure, artwork, software and design are ours. Quote freely with attribution; do not repackage the library wholesale.',
  },
  {
    title: 'The app is provided as it is',
    body: 'It is offered without warranty of any kind. Because it keeps your bookmarks, streaks and journal entries only on your device, uninstalling the app or losing the phone loses them — there is no copy for us to restore.',
  },
  {
    title: 'Changes',
    body: 'These terms may change as the app does. Material changes will be dated here, and the date above is when this version took effect.',
  },
];

export default function Terms() {
  useSeo(PAGE_META[routes.terms]);

  return (
    <>
      <PageHeader
        eyebrow="Terms"
        title="Terms of use"
        lead={`Short, and in plain language. Using ${appConfig.name} means these apply.`}
        meta={<span>Last updated {UPDATED}</span>}
      />

      <div className="shell pb-section">
        <div className="max-w-prose">
          <dl className="space-y-9">
            {SECTIONS.map((section) => (
              <div key={section.title}>
                <dt className="text-[1.08rem] font-medium text-ink">{section.title}</dt>
                <dd className="mt-2 text-[0.97rem] leading-[1.75] text-ink-soft">{section.body}</dd>
              </div>
            ))}
          </dl>

          <div className="mt-12 rounded-lg border border-dashed border-ink/15 bg-paper-2/50 p-6">
            <p className="text-[0.93rem] leading-relaxed text-ink-soft">
              Questions about any of this go to{' '}
              <a href={`mailto:${appConfig.contactEmail}`} className="link-quiet font-medium">
                {appConfig.contactEmail}
              </a>
              . For what happens to data, see the{' '}
              <Link to={routes.privacy} className="link-quiet font-medium">
                privacy page
              </Link>
              .
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
