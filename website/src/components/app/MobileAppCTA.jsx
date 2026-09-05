import { useEffect, useState } from 'react';
import { ArrowRight, Smartphone } from 'lucide-react';
import Mandala from '../art/Mandala.jsx';
import { LogoTile } from '../art/Wordmark.jsx';
import { appConfig } from '../../config/appConfig.js';
import {
  deepLinkKindFor,
  detectPlatform,
  hasLiveStore,
  isMobile,
  openInApp,
} from '../../services/appLinks.js';

/**
 * The app hand-off.
 *
 * Store listings are not live yet, so the buttons say so rather than linking to
 * a 404 — `appConfig.stores.*.available` is the single switch that turns them
 * into real links. Nothing about this component needs editing at launch.
 */

/** Platform detection has to happen after mount, or SSR/prerender would bake it in. */
function usePlatform() {
  const [platform, setPlatform] = useState('desktop');
  useEffect(() => setPlatform(detectPlatform()), []);
  return platform;
}

function StoreButton({ store, platform }) {
  const live = store.available;
  const label = live ? `Download on ${store.label}` : `${store.label} — coming soon`;

  const shared =
    'group flex items-center gap-3 rounded-full px-5 py-3 text-left transition-all duration-300 ease-calm';

  if (!live) {
    return (
      <span
        className={`${shared} cursor-default border border-white/25 text-white/60`}
        aria-disabled="true"
      >
        <Smartphone size={19} strokeWidth={1.7} aria-hidden="true" />
        <span>
          <span className="block text-[0.68rem] uppercase tracking-[0.14em] text-white/45">
            Coming soon
          </span>
          <span className="block text-[0.92rem] font-medium">{store.label}</span>
        </span>
      </span>
    );
  }

  return (
    <a
      href={store.url}
      target="_blank"
      rel="noreferrer noopener"
      aria-label={label}
      className={`${shared} bg-[#FFF7EE] text-[#2b1a12] shadow-lift hover:-translate-y-0.5
                  hover:shadow-float`}
      data-platform={platform}
    >
      <Smartphone size={19} strokeWidth={1.7} aria-hidden="true" />
      <span>
        <span className="block text-[0.68rem] uppercase tracking-[0.14em] text-[#2b1a12]/55">
          Download on
        </span>
        <span className="block text-[0.92rem] font-semibold">{store.label}</span>
      </span>
    </a>
  );
}

export default function MobileAppCTA() {
  const platform = usePlatform();
  const mobile = platform !== 'desktop';

  return (
    <section id="get-the-app" className="scroll-mt-24 py-section">
      <div className="shell">
        <div
          className="stitch stitch-on-color relative overflow-hidden rounded-2xl px-6 py-14 text-center
                     text-white shadow-float sm:px-12 sm:py-16"
          style={{ background: 'linear-gradient(150deg, #A73015, #6E1F10 62%, #3f1108)' }}
        >
          <Mandala
            accent="#FFF4E9"
            className="pointer-events-none absolute -right-32 -top-32 h-[34rem] w-[34rem] opacity-[0.09]"
          />

          <div className="relative mx-auto max-w-2xl">
            <div className="flex justify-center">
              <LogoTile size={54} />
            </div>

            <h2 className="mt-6 font-display text-[2rem] font-semibold leading-tight sm:text-[2.6rem]">
              Carry {appConfig.name} with you.
            </h2>
            <p className="mx-auto mt-4 max-w-lg text-[1rem] leading-relaxed text-white/80">
              The full library, the daily panchang and your own practice — on your phone, working
              whether or not you have signal.
            </p>

            <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
              {/* iOS first on iOS, Android first everywhere else. */}
              {(platform === 'ios'
                ? [appConfig.stores.ios, appConfig.stores.android]
                : [appConfig.stores.android, appConfig.stores.ios]
              ).map((store) => (
                <StoreButton key={store.label} store={store} platform={platform} />
              ))}
            </div>

            {mobile && hasLiveStore() && (
              <button
                type="button"
                onClick={() => openInApp({ kind: 'home' })}
                className="group mt-6 inline-flex items-center gap-2 text-[0.9rem] font-medium
                           text-white/85 underline decoration-white/30 underline-offset-4
                           transition-colors hover:text-white"
              >
                Already installed? Open in {appConfig.name}
                <ArrowRight
                  size={15}
                  strokeWidth={2}
                  aria-hidden="true"
                  className="transition-transform duration-300 ease-calm group-hover:translate-x-1"
                />
              </button>
            )}

            {!hasLiveStore() && (
              <p className="mt-7 text-[0.82rem] text-white/60">
                {appConfig.name} is in final testing. Follow{' '}
                <a
                  href={appConfig.social[0].url}
                  target="_blank"
                  rel="noreferrer noopener"
                  className="underline decoration-white/40 underline-offset-4 hover:text-white"
                >
                  {appConfig.social[0].handle}
                </a>{' '}
                for the release.
              </p>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}

/**
 * "Continue this journey in Aradhya →" — the hand-off at the end of a piece of
 * content. Tries the app first and falls back to the store, which is the only
 * honest way to do this in a browser.
 *
 * Until a listing is live the store fallback would dead-end, so this renders as
 * a link to the download section instead of a broken promise.
 */
export function ContinueInAradhya({ record, className = '' }) {
  const [mobile, setMobile] = useState(false);
  useEffect(() => setMobile(isMobile()), []);

  const canDeepLink = mobile && hasLiveStore();
  const label = record ? `Continue this in ${appConfig.name}` : `Open ${appConfig.name}`;

  const inner = (
    <>
      <span
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md bg-terra/[0.09]
                   text-terra"
      >
        <Smartphone size={20} strokeWidth={1.7} aria-hidden="true" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-[0.97rem] font-medium text-ink">{label}</span>
        <span className="mt-0.5 block text-[0.82rem] text-ink-soft">
          {record
            ? 'Full text, audio and related readings — offline, on your phone.'
            : 'The whole library, offline on your phone.'}
        </span>
      </span>
      <ArrowRight
        size={17}
        strokeWidth={1.9}
        aria-hidden="true"
        className="shrink-0 text-terra transition-transform duration-300 ease-calm
                   group-hover:translate-x-1"
      />
    </>
  );

  const shell = `surface group flex w-full items-center gap-4 p-4 text-left transition-all
                 duration-300 ease-calm hover:-translate-y-0.5 hover:border-terra/30
                 hover:shadow-lift ${className}`;

  if (canDeepLink) {
    return (
      <button
        type="button"
        className={shell}
        onClick={() =>
          openInApp(
            record
              ? { kind: deepLinkKindFor(record), slug: record.slug }
              : { kind: 'home' },
          )
        }
      >
        {inner}
      </button>
    );
  }

  return (
    <a href="#get-the-app" className={shell}>
      {inner}
    </a>
  );
}
