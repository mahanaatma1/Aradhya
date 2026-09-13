import { CloudOff, Download, HardDrive, Plane } from 'lucide-react';
import PhoneMock from '../art/PhoneMock.jsx';
import Reveal from '../ui/Reveal.jsx';
import Button from '../ui/Button.jsx';
import Mandala from '../art/Mandala.jsx';
import { appConfig } from '../../config/appConfig.js';
import { getStats, contentKeys } from '../../services/contentService.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Your spiritual library. Wherever you are." — the offline-first section.
 *
 * The three points describe how the app actually works: the library is bundled
 * into the download, and personal state is written to a database on the device.
 * The wording of the second point comes from appConfig.privacy so it cannot
 * drift from the privacy page.
 */

const POINTS = [
  {
    icon: Plane,
    title: 'No signal needed',
    body: 'The library ships inside the app. Aeroplane mode, a temple basement, a train through nowhere — it reads the same.',
  },
  {
    icon: HardDrive,
    title: 'Yours, on your device',
    body: appConfig.privacy.appSummary,
  },
  {
    icon: CloudOff,
    title: 'Nothing to log into',
    body: 'Open it and read. There is no feed to catch up on and no notification asking for your attention.',
  },
];

export default function OfflineFirst() {
  const { data: stats } = useAsync(() => getStats(), [], { preloadKey: contentKeys.stats });

  return (
    <section className="relative overflow-hidden py-section">
      <Mandala
        accent="rgb(var(--gold))"
        className="pointer-events-none absolute -left-40 top-1/2 h-[36rem] w-[36rem]
                   -translate-y-1/2 opacity-[0.07]"
      />

      <div className="shell relative">
        <div className="grid items-center gap-12 lg:grid-cols-[1.05fr_0.95fr] lg:gap-16">
          <Reveal>
            <p className="eyebrow mb-3">Offline first</p>
            <h2 className="text-display-md text-ink">
              Your spiritual library.
              <br />
              Wherever you are.
            </h2>
            <p className="mt-5 max-w-lg text-[1.02rem] leading-relaxed text-ink-soft">
              {appConfig.name} was built the other way round from most apps: everything is on the
              phone first, and the internet is optional rather than assumed.
            </p>

            <ul className="mt-9 space-y-6">
              {POINTS.map((point) => (
                <li key={point.title} className="flex gap-4">
                  <span
                    className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md
                               bg-terra/[0.08] text-terra"
                  >
                    <point.icon size={19} strokeWidth={1.7} aria-hidden="true" />
                  </span>
                  <div className="min-w-0">
                    <h3 className="text-[1.02rem] text-ink">{point.title}</h3>
                    <p className="mt-1 text-[0.92rem] leading-relaxed text-ink-soft">
                      {point.body}
                    </p>
                  </div>
                </li>
              ))}
            </ul>

            {stats && (
              <p className="mt-8 rounded-md border border-dashed border-ink/15 bg-paper-2/50 px-4 py-3 text-[0.82rem] leading-relaxed text-ink-soft">
                What travels with you: {stats.entities} entries, {stats.scenes} story events,{' '}
                {stats.festivals} festivals and {stats.journeys} guided journeys — plus the daily
                panchang, which is calculated on the device rather than fetched.
              </p>
            )}

            <Button href="#get-the-app" size="lg" icon={Download} className="mt-8">
              Get the app
            </Button>
          </Reveal>

          <Reveal delay={120} className="flex justify-center lg:justify-end">
            <div className="relative">
              {/* A soft plate behind the phone so it does not float in space. */}
              <span
                aria-hidden="true"
                className="absolute inset-x-[-12%] inset-y-[8%] rounded-[3rem] bg-gradient-to-b
                           from-terra/[0.07] to-transparent blur-2xl"
              />
              <PhoneMock className="relative" />
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
