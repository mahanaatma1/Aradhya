import { Link } from 'react-router-dom';
import PracticeCard from '../cards/PracticeCard.jsx';
import CardRail from '../ui/CardRail.jsx';
import Section from '../ui/Section.jsx';
import { PRACTICES } from '../../config/taxonomy.js';
import { routes } from '../../config/routes.js';
import { appConfig } from '../../config/appConfig.js';

/**
 * "Knowledge becomes meaningful when practiced." — section 8.
 *
 * The five practices are app features, so they come from the taxonomy. The cards
 * describe them and hand off; a website cannot hold a japa count or a private
 * journal, and this section does not pretend otherwise.
 */
export default function PracticeStrip() {
  return (
    <Section
      eyebrow="Practice"
      title="Knowledge becomes meaningful when practiced."
      lead="Reading is where it starts. The app carries the small daily things — sitting, counting, breathing, offering, writing down what stayed with you."
      action={{ to: routes.practices, label: 'See the practices' }}
    >
      <CardRail label="Practices" cols="sm:grid-cols-2 lg:grid-cols-3" itemWidth="w-[14.5rem]">
        {PRACTICES.map((practice) => (
          <PracticeCard key={practice.id} practice={practice} className="h-full" />
        ))}

        {/* Sixth cell: where practice data actually lives. The wording is the
            same sentence the privacy page uses, read from appConfig, so the two
            can't drift apart. */}
        <div
          className="flex h-full flex-col justify-center rounded-lg border border-dashed
                     border-terra/30 bg-terra/[0.04] p-5"
        >
          <p className="font-display text-[1.05rem] text-ink">Kept on your device</p>
          <p className="mt-2 text-[0.86rem] leading-relaxed text-ink-soft sm:text-[0.88rem]">
            {appConfig.privacy.appSummary}
          </p>
          <Link to={routes.privacy} className="link-quiet mt-3 self-start text-[0.82rem] font-medium">
            How privacy works
          </Link>
        </div>
      </CardRail>
    </Section>
  );
}
