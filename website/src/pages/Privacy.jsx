import { Link } from 'react-router-dom';
import { Cookie, Globe, Smartphone } from 'lucide-react';
import PageHeader from '../components/ui/PageHeader.jsx';
import { appConfig } from '../config/appConfig.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /privacy — written against what the code actually does.
 *
 * The rule for this page: no blanket reassurance. "We never collect any data" is
 * the sentence every app says and most of them are wrong, so instead each surface
 * is described separately and the one genuine third-party request the website
 * makes (Google Fonts) is disclosed rather than glossed over.
 *
 * If you add analytics, a font self-host, a contact form or an embed, this page
 * and appConfig.privacy must be updated in the same commit.
 */

const UPDATED = 'August 2026';

export default function Privacy() {
  useSeo(PAGE_META[routes.privacy]);

  return (
    <>
      <PageHeader
        eyebrow="Privacy"
        title="What happens to your data"
        lead="Short version: the app keeps your things on your phone, and this website has no analytics. The longer version below is specific, because a vague privacy page is worth nothing."
        meta={<span>Last updated {UPDATED}</span>}
      />

      <div className="shell pb-section">
        <div className="max-w-prose space-y-12">
          <Block
            icon={Smartphone}
            title={`The ${appConfig.name} app`}
            points={[
              {
                heading: 'Your library is bundled, not fetched',
                body: `${appConfig.name} reads its content from files packaged inside the app. Opening a scripture, a story or a temple entry does not contact a server.`,
              },
              {
                heading: 'Your practice stays on the device',
                body: appConfig.privacy.appSummary,
              },
              {
                heading: 'No account, and nothing to sign into',
                body: 'There is no login, no profile and no sync. Which is also the limitation: your data lives with the install and does not follow you to a new phone.',
              },
              {
                heading: 'No analytics and no crash reporting',
                body: 'At the time of writing the app contains no analytics library, no crash reporter and no advertising SDK, and no code that makes a network request. Tapping a link to a website or a store listing hands you to your browser, which is the only way it leaves the app.',
              },
              {
                heading: 'The panchang is calculated, not downloaded',
                body: 'Tithi, nakshatra and sunrise are computed on the device from your date and location. Location, if you grant it, is used for that calculation and is not transmitted.',
              },
            ]}
          />

          <Block
            icon={Globe}
            title="This website"
            points={[
              {
                heading: 'A static site',
                body: appConfig.privacy.websiteSummary,
              },
              {
                heading: 'One stored preference',
                body: 'Choosing light or dark writes the value “light” or “dark” to your browser’s local storage under the key aradhya-theme. That is the only thing this site stores, it never leaves your browser, and clearing site data removes it.',
              },
              {
                heading: 'No analytics, no cookies, no pixels',
                body: 'There is no analytics script, no cookie banner because there are no cookies, no advertising network, no social embed, and no third-party tag manager. Search happens in your browser against a content file — your queries are not sent anywhere.',
              },
              {
                heading: 'One third-party request, disclosed',
                body: 'Typefaces are requested from Google Fonts (fonts.googleapis.com and fonts.gstatic.com). Like any request to any server, that tells Google your IP address and browser. It is the one outside connection this site makes, and self-hosting the fonts to remove it is on the list.',
              },
              {
                heading: 'Server logs',
                body: 'Whoever serves these files keeps ordinary access logs — IP address, time, page, user agent — as every web server does. They are used to keep the site running and for nothing else.',
              },
            ]}
          />

          <Block
            icon={Cookie}
            title="If you write to us"
            points={[
              {
                heading: 'Only what you send',
                body: `Emailing ${appConfig.contactEmail} means we have your email and whatever you wrote, for as long as the correspondence is useful. There is no mailing list to be added to.`,
              },
              {
                heading: 'Children',
                body: 'The app and site are suitable for general audiences and neither asks for personal details, so there is nothing collected from a child that could be handed back.',
              },
              {
                heading: 'Changes to this page',
                body: 'If a future version adds anything that collects data, this page changes in the same release — not afterwards. The date at the top is when it was last true.',
              },
            ]}
          />

          <div className="rounded-lg border border-dashed border-terra/30 bg-terra/[0.04] p-6">
            <h2 className="text-[1.02rem] text-ink">A note on what this page is</h2>
            <p className="mt-2.5 text-[0.93rem] leading-relaxed text-ink-soft">
              This describes the current build honestly rather than describing an ideal. Store
              listings also publish their own data-safety declarations, and those are written from
              the same facts.
            </p>
            <div className="mt-5 flex flex-wrap gap-x-6 gap-y-2">
              <Link to={routes.terms} className="link-quiet text-[0.9rem] font-medium">
                Terms of use
              </Link>
              <a
                href={`mailto:${appConfig.contactEmail}`}
                className="link-quiet text-[0.9rem] font-medium"
              >
                Ask a question about this
              </a>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

function Block({ icon: Icon, title, points }) {
  return (
    <section>
      <div className="flex items-center gap-3">
        <span
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md bg-terra/[0.08]
                     text-terra"
        >
          <Icon size={19} strokeWidth={1.7} aria-hidden="true" />
        </span>
        <h2 className="text-display-sm text-ink">{title}</h2>
      </div>

      <dl className="mt-6 space-y-6">
        {points.map((point) => (
          <div key={point.heading}>
            <dt className="text-[1rem] font-medium text-ink">{point.heading}</dt>
            <dd className="mt-1.5 text-[0.95rem] leading-[1.7] text-ink-soft">{point.body}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
