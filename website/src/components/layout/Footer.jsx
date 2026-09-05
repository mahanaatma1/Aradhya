import { Link } from 'react-router-dom';
import { Instagram, Mail, Youtube } from 'lucide-react';
import Wordmark from '../art/Wordmark.jsx';
import { OrnamentBand } from '../art/Mandala.jsx';
import { footerNav, routes } from '../../config/routes.js';
import { appConfig } from '../../config/appConfig.js';

const SOCIAL_ICONS = { Instagram, YouTube: Youtube };

export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="relative mt-6 border-t border-ink/[0.08] bg-paper-2/50">
      <OrnamentBand className="absolute inset-x-0 top-0 h-3 w-full text-terra/20" />

      <div className="shell py-14 sm:py-16">
        <div className="grid gap-10 md:grid-cols-[1.3fr_2.2fr] lg:gap-16">
          {/* Brand */}
          <div>
            <Link to={routes.home} aria-label={`${appConfig.name} — home`} className="inline-block">
              <Wordmark size={58} showTagline />
            </Link>
            <p className="mt-4 max-w-xs text-[0.9rem] leading-relaxed text-ink-soft">
              A quiet place to explore India’s spiritual heritage — scriptures, stories, sacred
              places and daily practice, in one offline companion.
            </p>

            <div className="mt-5 flex items-center gap-2">
              {appConfig.social.map((s) => {
                const Icon = SOCIAL_ICONS[s.label] ?? Instagram;
                return (
                  <a
                    key={s.label}
                    href={s.url}
                    target="_blank"
                    rel="noreferrer noopener"
                    aria-label={`${appConfig.name} on ${s.label}`}
                    className="flex h-10 w-10 items-center justify-center rounded-full border
                               border-ink/12 bg-card/70 text-ink-soft transition-all duration-300
                               ease-calm hover:-translate-y-0.5 hover:border-terra/35 hover:text-terra"
                  >
                    <Icon size={17} strokeWidth={1.8} aria-hidden="true" />
                  </a>
                );
              })}
              <a
                href={`mailto:${appConfig.contactEmail}`}
                aria-label="Email us"
                className="flex h-10 w-10 items-center justify-center rounded-full border border-ink/12
                           bg-card/70 text-ink-soft transition-all duration-300 ease-calm
                           hover:-translate-y-0.5 hover:border-terra/35 hover:text-terra"
              >
                <Mail size={17} strokeWidth={1.8} aria-hidden="true" />
              </a>
            </div>
          </div>

          {/* Link columns */}
          <nav aria-label="Footer" className="grid grid-cols-2 gap-8 sm:grid-cols-4">
            {footerNav.map((column) => (
              <div key={column.heading}>
                <h2 className="text-[0.68rem] font-semibold uppercase tracking-[0.18em] text-ink-faint">
                  {column.heading}
                </h2>
                <ul className="mt-4 space-y-2.5">
                  {column.links.map((link) => (
                    <li key={link.to}>
                      <Link
                        to={link.to}
                        className="text-[0.88rem] text-ink-soft transition-colors duration-200
                                   hover:text-terra"
                      >
                        {link.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </nav>
        </div>

        <div className="hairline my-10" />

        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="font-display text-[0.94rem] text-ink">
            {appConfig.name} — {appConfig.promise}
          </p>
          <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-[0.8rem] text-ink-faint">
            <span>
              © {year} {appConfig.name}
            </span>
            <Link to={routes.privacy} className="transition-colors hover:text-terra">
              Privacy
            </Link>
            <Link to={routes.terms} className="transition-colors hover:text-terra">
              Terms
            </Link>
          </div>
        </div>

        {/* The sourcing promise, stated where it can be checked. */}
        <p className="mt-6 max-w-3xl text-[0.76rem] leading-relaxed text-ink-faint">
          Content is drawn from public-domain translations and open datasets, and every entry keeps
          the source it came from. Nothing here is written to fill a gap — where the tradition
          differs, {appConfig.name} says so instead of choosing for you.
        </p>
      </div>
    </footer>
  );
}
