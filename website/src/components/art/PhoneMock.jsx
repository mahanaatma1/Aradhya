import { CATEGORY_GRADIENTS } from '../../config/taxonomy.js';
import Glyph from './Glyph.jsx';
import { LogoTile } from './Wordmark.jsx';

/**
 * A miniature of the app's home screen inside a phone frame.
 *
 * Built from live DOM rather than a screenshot: it stays crisp at any size,
 * follows the site's light/dark theme, weighs nothing, and cannot go stale
 * against a shipped build the way an exported PNG does. The tiles use the same
 * category gradients as the app (lib/app/theme/category_colors.dart).
 */

const TILES = [
  { label: 'Scriptures', glyph: 'scroll', accent: 'scriptures' },
  { label: 'Ramayana', glyph: 'bow', accent: 'epics' },
  { label: 'Mantras', glyph: 'om', accent: 'mantras' },
  { label: 'Japa', glyph: 'mala', accent: 'sadhana' },
];

export default function PhoneMock({ className = '' }) {
  return (
    <div
      className={`relative aspect-[10/19.5] w-full max-w-[276px] rounded-[2.4rem] border border-ink/15
                  bg-gradient-to-b from-[#2b1a12] to-[#160d08] p-[7px] shadow-float ${className}`}
      aria-hidden="true"
    >
      {/* Screen */}
      <div className="relative flex h-full flex-col overflow-hidden rounded-[2rem] bg-paper">
        {/* status bar */}
        <div className="flex items-center justify-between px-4 pt-3 text-[9px] font-semibold text-ink-soft">
          <span>9:41</span>
          <span className="flex items-center gap-1">
            {/* An aeroplane, because the point of the section is that it works offline. */}
            <svg width="9" height="9" viewBox="0 0 24 24" fill="currentColor">
              <path d="M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z" />
            </svg>
            <span className="inline-block h-[7px] w-[13px] rounded-[2px] border border-current" />
          </span>
        </div>

        {/* app bar */}
        <div className="flex items-center gap-2 px-4 pb-2 pt-3">
          <LogoTile size={20} />
          <span className="font-display text-[13px] font-semibold text-ink">
            Ara<span className="text-terra">dhya</span>
          </span>
          <span className="ml-auto rounded-full bg-paper-2 px-2 py-[3px] text-[8px] font-semibold text-ink-soft">
            आ
          </span>
        </div>

        {/* verse of the day */}
        <div className="relative mx-3 overflow-hidden rounded-lg border border-ink/[0.07] bg-card p-3 shadow-card">
          <span className="absolute inset-[5px] rounded-md border border-dashed border-terra/25" />
          <p className="text-[7.5px] font-semibold uppercase tracking-[0.18em] text-terra">
            Verse of the day
          </p>
          <p className="mt-1.5 font-deva text-[11px] leading-snug text-ink">
            योगः कर्मसु कौशलम्
          </p>
          <p className="mt-1 text-[8px] leading-snug text-ink-soft">
            Bhagavad Gita · Chapter 2
          </p>
        </div>

        {/* panchang strip */}
        <div className="mx-3 mt-2.5 flex items-center gap-2 rounded-md bg-paper-2 px-2.5 py-2">
          <Glyph name="diya" size={13} className="text-[#A7430F]" />
          <div className="min-w-0">
            <p className="truncate text-[8px] font-semibold text-ink">Shukla Paksha · Ekadashi</p>
            <p className="truncate text-[7px] text-ink-faint">Sunrise 6:12 · Sunset 18:44</p>
          </div>
        </div>

        {/* category tiles */}
        <div className="mt-3 grid grid-cols-2 gap-2 px-3">
          {TILES.map((tile) => {
            const [from, to] = CATEGORY_GRADIENTS[tile.accent];
            return (
              <div
                key={tile.label}
                className="relative flex h-[46px] flex-col justify-between overflow-hidden rounded-md p-2"
                style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
              >
                <span className="absolute inset-[4px] rounded border border-dashed border-white/35" />
                <Glyph name={tile.glyph} size={13} className="relative text-white/90" />
                <span className="relative text-[8px] font-semibold text-white">{tile.label}</span>
              </div>
            );
          })}
        </div>

        {/* streak row */}
        <div className="mx-3 mt-2.5 flex items-center gap-1.5 rounded-md border border-ink/[0.07] bg-card px-2.5 py-2">
          <Glyph name="flame" size={12} className="text-terra" />
          <span className="text-[8px] font-semibold text-ink">12-day streak</span>
          <span className="ml-auto flex gap-[3px]">
            {[1, 1, 1, 1, 1, 0, 0].map((on, i) => (
              <span
                key={i}
                className={`h-[7px] w-[7px] rounded-[2px] ${on ? 'bg-terra/70' : 'bg-ink/10'}`}
              />
            ))}
          </span>
        </div>

        {/* bottom nav — the app's five tabs */}
        <div className="mt-auto flex items-end justify-between border-t border-ink/[0.07] bg-card px-3 pb-3 pt-2">
          {[
            { g: 'lotus', l: 'Home', on: true },
            { g: 'diya', l: 'Mandir' },
            { g: 'chakra', l: 'Jyotish' },
            { g: 'shikhara', l: 'Yatra' },
            { g: 'figure', l: 'You' },
          ].map((tab) => (
            <span
              key={tab.l}
              className={`flex flex-col items-center gap-1 ${tab.on ? 'text-terra' : 'text-ink-faint'}`}
            >
              <Glyph name={tab.g} size={13} />
              <span className="text-[6.5px] font-medium">{tab.l}</span>
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
