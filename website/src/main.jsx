import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App.jsx';
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

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <App />
    </BrowserRouter>
  </StrictMode>,
);
