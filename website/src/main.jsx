import { StrictMode } from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App, { preloadRoute } from './App.jsx';
import { prefetchContent } from './services/contentService.js';
import './index.css';

/**
 * Entry point.
 *
 * The content chunk is warmed the moment the shell mounts rather than when the
 * first component asks for it, so typing into the hero search finds an index
 * that is already in memory. It is fire-and-forget: every consumer awaits
 * loadContent() itself, so a slow or failed prefetch changes nothing except
 * timing.
 *
 * The router's v7 flags are opted into now: `v7_startTransition` renders route
 * updates inside a transition, and `v7_relativeSplatPath` fixes relative link
 * resolution inside splat routes (which App.jsx uses for its lazy branch). Both
 * are v7's behaviour, so taking them here makes the upgrade a version bump.
 */
prefetchContent();

const container = document.getElementById('root');

const tree = (
  <StrictMode>
    <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <App />
    </BrowserRouter>
  </StrictMode>
);

/**
 * Hydrate what the build prerendered; mount from scratch when there is nothing.
 *
 * Which one applies is read off the DOM rather than a build flag, because both
 * cases are real in the same deployment: `scripts/prerender.mjs` writes body
 * HTML for the pages it can, and serves the empty shell for `/search`, for a
 * page whose payload was too large to inline, and for any URL with no file of
 * its own. `createRoot` on prerendered markup would throw it away and repaint
 * from nothing, which is the flash this whole path exists to avoid.
 *
 * Hydration waits for the page's own chunk. Without that wait the first render
 * is the Suspense fallback — a skeleton where the server wrote the article —
 * and React responds to that mismatch by discarding the markup, which is the
 * same flash by a different route. Nothing is lost by waiting: the text is
 * already on screen and already readable, and its links are real anchors.
 *
 * The data matches for the same reason: the build inlined what each page
 * resolved, and `useAsync` reads it during that first render. See
 * services/preload.js.
 */
if (container.hasChildNodes()) {
  preloadRoute(window.location.pathname).then(() => hydrateRoot(container, tree));
} else {
  createRoot(container).render(tree);
}
