import { Link } from 'react-router-dom';
import PracticeCard from '../components/cards/PracticeCard.jsx';
import PageHeader from '../components/ui/PageHeader.jsx';
import Reveal from '../components/ui/Reveal.jsx';
import PhoneMock from '../components/art/PhoneMock.jsx';
import { ContinueInAradhya } from '../components/app/MobileAppCTA.jsx';
import { PRACTICES } from '../config/taxonomy.js';
import { PAGE_META } from '../config/seo.js';
import { routes } from '../config/routes.js';
import { appConfig } from '../config/appConfig.js';
import useSeo from '../hooks/useSeo.js';

/**
 * /practices — the five daily tools.
 *
 * These are app features rather than content, so nothing here is loaded from the
 * content set. The page is honest about the split: a website can describe a japa
 * count but cannot keep one, and everything a practice records is written to the
 * device, not to us.
 */
export default function Practices() {
  useSeo(PAGE_META[routes.practices]);

  return (
    <>
      <PageHeader
        eyebrow="Practice"
        title="Daily practice"
        titleHi="साधना"
        lead="Reading is where it starts. These are the small repeated things that make it yours — sitting, counting, breathing, offering, and writing down what stayed with you."
      />

      <div className="shell pb-section">
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {PRACTICES.map((practice, i) => (
            <Reveal key={practice.id} delay={i * 55}>
              <PracticeCard practice={practice} className="h-full" />
            </Reveal>
          ))}
        </div>

        {/* What the app keeps, stated in the same words as the privacy page. */}
        <section className="mt-16">
          <div className="surface stitch grid items-center gap-10 p-7 sm:p-10 lg:grid-cols-[1.15fr_0.85fr]">
            <div>
              <h2 className="text-display-sm text-ink">What a practice remembers</h2>
              <p className="mt-4 text-[1rem] leading-relaxed text-ink-soft">
                {appConfig.privacy.appSummary}
              </p>
              <p className="mt-4 text-[1rem] leading-relaxed text-ink-soft">
                So the streak on your phone is a fact about your phone. There is nothing to sign
                into and no copy of it on a server — which is also the trade: it lives with the
                install, and does not follow you to a new device.
              </p>

              <div className="mt-7 flex flex-wrap items-center gap-x-6 gap-y-3">
                <Link to={routes.privacy} className="link-quiet text-[0.9rem] font-medium">
                  Read the privacy page
                </Link>
                <Link to={routes.journeys} className="link-quiet text-[0.9rem] font-medium">
                  Or start with a journey
                </Link>
              </div>

              <ContinueInAradhya className="mt-8 max-w-md" />
            </div>

            <div className="flex justify-center lg:justify-end">
              <PhoneMock className="max-w-[220px]" />
            </div>
          </div>
        </section>
      </div>
    </>
  );
}
