#!/usr/bin/env node
/**
 * Rasterise public/og-image.svg → public/og-image.png.
 *
 * Why this exists: most link unfurlers (Slack, WhatsApp, Twitter/X, LinkedIn,
 * Facebook) will not render an SVG `og:image`. They need a raster file, so the
 * SVG stays the source of truth and this produces the PNG that ships.
 *
 * Why a browser rather than a library: the card is set in Eczar and Inter, the
 * same faces the site and the app use. A standalone rasteriser has neither font
 * and silently falls back to whatever it can find — the headline comes out in a
 * generic sans and stops looking like Aradhya. Chrome loads the real webfonts,
 * and it is the only renderer here that also honours the tile's drop-shadow
 * filter.
 *
 * This is not part of `npm run build`. It needs a local Chrome or Edge, which a
 * CI box may not have, and the card changes about once a year — so it is a
 * deliberate step you run when the SVG changes, and the PNG is committed.
 *
 *     npm run og
 */

import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const svgPath = join(root, 'public', 'og-image.svg');
const pngPath = join(root, 'public', 'og-image.png');

const WIDTH = 1200;
const HEIGHT = 630;

/* --------------------------------------------------------------- the browser */

/**
 * Chrome and Edge share the same headless screenshot flags, so either will do.
 * CHROME_PATH wins, for a machine that keeps its browser somewhere unusual.
 */
function findBrowser() {
  const candidates = [
    process.env.CHROME_PATH,
    process.env.PUPPETEER_EXECUTABLE_PATH,
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/microsoft-edge',
  ];
  return candidates.find((p) => p && existsSync(p)) ?? null;
}

/* ------------------------------------------------------------------ the page */

/**
 * The SVG goes inline rather than in an <img>, because an <img> gets its own
 * document and would not see the fonts this page loads. `margin: 0` and an
 * exactly-sized viewport mean the screenshot needs no cropping.
 */
function pageHtml(svg) {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Eczar:wght@400;500;600&family=Inter:wght@400;500;600;700&display=block">
<style>
  html, body { margin: 0; padding: 0; width: ${WIDTH}px; height: ${HEIGHT}px; overflow: hidden; }
  svg { display: block; }
</style>
</head>
<body>
${svg}
</body>
</html>`;
}

/* ------------------------------------------------------------------- the run */

const browser = findBrowser();
if (!browser) {
  console.error(
    'og: no Chrome or Edge found. Set CHROME_PATH to a Chromium-based browser and rerun.\n' +
      '    The committed public/og-image.png is unchanged.',
  );
  process.exit(1);
}

const svg = readFileSync(svgPath, 'utf8');
const work = mkdtempSync(join(tmpdir(), 'aradhya-og-'));
const htmlPath = join(work, 'card.html');
writeFileSync(htmlPath, pageHtml(svg), 'utf8');

try {
  execFileSync(
    browser,
    [
      // `=new` matters: the old headless mode is gone in current Chrome, and
      // asking for it is one of the ways this hangs instead of failing.
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--force-device-scale-factor=1',
      `--window-size=${WIDTH},${HEIGHT}`,
      // A throwaway profile. Without it, an already-running Chrome adopts the
      // command line, never takes the screenshot, and this call hangs forever.
      `--user-data-dir=${join(work, 'profile')}`,
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-extensions',
      // Fonts come over the network, so give the page real time to settle.
      // virtual-time-budget fast-forwards timers rather than sleeping.
      '--virtual-time-budget=8000',
      `--screenshot=${pngPath}`,
      // file:// so the inline SVG's gradients and filter resolve normally.
      `file://${htmlPath.replace(/\\/g, '/')}`,
    ],
    { stdio: ['ignore', 'ignore', 'pipe'], timeout: 90_000 },
  );
} catch (err) {
  // Chrome writes progress chatter to stderr and still exits non-zero on some
  // builds, so trust the file rather than the exit code.
  if (!existsSync(pngPath)) {
    console.error('og: chrome failed and wrote nothing.\n' + (err.stderr?.toString() ?? err.message));
    process.exit(1);
  }
} finally {
  rmSync(work, { recursive: true, force: true });
}

const bytes = statSync(pngPath).size;
console.log(
  `og-image.png — ${WIDTH}×${HEIGHT}, ${(bytes / 1024).toFixed(0)} kB → public/og-image.png`,
);
if (bytes > 800 * 1024) {
  console.warn('og: over 800 kB; some unfurlers skip images that large.');
}
