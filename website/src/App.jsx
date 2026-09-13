import { Suspense, createElement } from 'react';
import { Route, Routes, matchRoutes } from 'react-router-dom';
import Layout from './components/layout/Layout.jsx';
import Home from './pages/Home.jsx';
import { CardGridSkeleton } from './components/ui/States.jsx';
import { routes } from './config/routes.js';

/**
 * Routing.
 *
 * Home is imported eagerly — it is the page most visitors land on, and a lazy
 * chunk there would only add a round trip before the hero paints. Everything
 * else is split, so a visitor who never opens /journeys never downloads it.
 */

/**
 * A code-split page that can be loaded *before* it is rendered.
 *
 * `React.lazy` cannot do this, and the difference decides whether the prerender
 * works at all. `lazy` only starts its import on first render, and it suspends
 * even when the module is already in hand, because it resolves through a
 * microtask. During hydration that is fatal: the client renders the Suspense
 * fallback where the server wrote the article, React finds a skeleton where it
 * expected prose, and discards the server's markup to re-render from scratch —
 * the exact flash the prerender exists to prevent.
 *
 * Keeping the module in a variable makes the already-loaded case synchronous, so
 * a caller that awaits `preload()` gets a first render identical to the
 * server's. Until then this behaves like `lazy`: throwing the pending promise is
 * what a Suspense boundary reads as "not ready yet".
 */
function preloadable(load) {
  let mod = null;
  let pending = null;

  function preload() {
    if (!pending) {
      pending = load().then((loaded) => {
        mod = loaded;
        return loaded;
      });
    }
    return pending;
  }

  function Page(props) {
    if (!mod) throw preload();
    return createElement(mod.default, props);
  }

  Page.preload = preload;
  return Page;
}

/** One wrapper per module, so the two epic routes share a chunk and a promise. */
const wrappers = new Map();
function componentFor(load) {
  let component = wrappers.get(load);
  if (!component) {
    component = preloadable(load);
    wrappers.set(load, component);
  }
  return component;
}

const loadEpic = () => import('./pages/Epic.jsx');

/**
 * The split routes, as data.
 *
 * Written this way so `preloadRoute` can find the chunk for a URL with the
 * router's own matcher rather than a second hand-written table that would
 * quietly drift out of step with this one.
 */
const PAGES = [
  { path: routes.search, load: () => import('./pages/Search.jsx') },
  { path: routes.explore, load: () => import('./pages/Explore.jsx') },
  { path: '/explore/:slug', load: () => import('./pages/EntityDetail.jsx') },
  { path: routes.scriptures, load: () => import('./pages/Scriptures.jsx') },
  { path: routes.stories, load: () => import('./pages/Stories.jsx') },
  { path: routes.ramayana, load: loadEpic, props: { epic: 'ramayana' } },
  { path: routes.mahabharata, load: loadEpic, props: { epic: 'mahabharata' } },
  { path: routes.temples, load: () => import('./pages/Temples.jsx') },
  { path: routes.practices, load: () => import('./pages/Practices.jsx') },
  { path: routes.journeys, load: () => import('./pages/Journeys.jsx') },
  { path: routes.about, load: () => import('./pages/About.jsx') },
  { path: routes.privacy, load: () => import('./pages/Privacy.jsx') },
  { path: routes.terms, load: () => import('./pages/Terms.jsx') },
  { path: '*', load: () => import('./pages/NotFound.jsx') },
].map((page) => ({ ...page, Component: componentFor(page.load) }));

/**
 * Load the chunk one URL needs.
 *
 * The browser awaits this before hydrating a prerendered page; skipping it means
 * hydrating against a skeleton. Home resolves immediately — it is not split.
 */
export function preloadRoute(pathname) {
  if (pathname === routes.home) return Promise.resolve();
  const matches = matchRoutes(PAGES, pathname);
  const page = matches?.[matches.length - 1]?.route;
  return page ? page.Component.preload() : Promise.resolve();
}

/** Load every chunk. Build-time only — see src/entry-server.jsx. */
export function loadRoutes() {
  return Promise.all(PAGES.map((page) => page.Component.preload()));
}

/**
 * Held space while a route chunk arrives — never a blank screen.
 *
 * The marker attribute is read by the build. Under `renderToString` a page that
 * has not loaded renders this instead, and there is no other way to tell that
 * apart from a page that legitimately rendered a skeleton. Finding it on the
 * final pass tells the build to fall back to the empty shell rather than publish
 * a page of skeletons. See scripts/prerender.mjs.
 */
function RouteFallback() {
  return (
    <div className="shell pb-section pt-36" data-ssr-fallback="">
      <CardGridSkeleton count={6} />
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path={routes.home} element={<Home />} />

        <Route
          path="*"
          element={
            <Suspense fallback={<RouteFallback />}>
              <Routes>
                {PAGES.map(({ path, Component, props }) => (
                  <Route key={path} path={path} element={<Component {...props} />} />
                ))}
              </Routes>
            </Suspense>
          }
        />
      </Route>
    </Routes>
  );
}
