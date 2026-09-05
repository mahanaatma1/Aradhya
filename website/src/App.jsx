import { Suspense, lazy } from 'react';
import { Route, Routes } from 'react-router-dom';
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

const Search = lazy(() => import('./pages/Search.jsx'));
const Explore = lazy(() => import('./pages/Explore.jsx'));
const EntityDetail = lazy(() => import('./pages/EntityDetail.jsx'));
const Scriptures = lazy(() => import('./pages/Scriptures.jsx'));
const Stories = lazy(() => import('./pages/Stories.jsx'));
const Epic = lazy(() => import('./pages/Epic.jsx'));
const Temples = lazy(() => import('./pages/Temples.jsx'));
const Practices = lazy(() => import('./pages/Practices.jsx'));
const Journeys = lazy(() => import('./pages/Journeys.jsx'));
const About = lazy(() => import('./pages/About.jsx'));
const Privacy = lazy(() => import('./pages/Privacy.jsx'));
const Terms = lazy(() => import('./pages/Terms.jsx'));
const NotFound = lazy(() => import('./pages/NotFound.jsx'));

/** Held space while a route chunk arrives — never a blank screen. */
function RouteFallback() {
  return (
    <div className="shell pb-section pt-36">
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
                <Route path={routes.search} element={<Search />} />
                <Route path={routes.explore} element={<Explore />} />
                <Route path="/explore/:slug" element={<EntityDetail />} />
                <Route path={routes.scriptures} element={<Scriptures />} />
                <Route path={routes.stories} element={<Stories />} />
                <Route path={routes.ramayana} element={<Epic epic="ramayana" />} />
                <Route path={routes.mahabharata} element={<Epic epic="mahabharata" />} />
                <Route path={routes.temples} element={<Temples />} />
                <Route path={routes.practices} element={<Practices />} />
                <Route path={routes.journeys} element={<Journeys />} />
                <Route path={routes.about} element={<About />} />
                <Route path={routes.privacy} element={<Privacy />} />
                <Route path={routes.terms} element={<Terms />} />
                <Route path="*" element={<NotFound />} />
              </Routes>
            </Suspense>
          }
        />
      </Route>
    </Routes>
  );
}
