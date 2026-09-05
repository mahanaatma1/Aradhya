import { useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Navbar from './Navbar.jsx';
import Footer from './Footer.jsx';
import MobileAppCTA from '../app/MobileAppCTA.jsx';
import ErrorBoundary from '../ui/ErrorBoundary.jsx';

/**
 * Page frame: header, content, app hand-off, footer.
 *
 * The download section lives here rather than on the home page so the header's
 * "Get the App" anchor works from every route.
 *
 * The error boundary wraps only the outlet, so a page that throws still leaves
 * the visitor a header to navigate away with — and navigating away resets it,
 * because the location key is its reset key.
 */
export default function Layout() {
  useScrollBehaviour();
  const { key } = useLocation();

  return (
    <div className="flex min-h-dvh flex-col">
      <Navbar />
      <main id="main" className="flex-1">
        <ErrorBoundary resetKey={key} where="a page">
          <Outlet />
        </ErrorBoundary>
      </main>
      <MobileAppCTA />
      <Footer />
    </div>
  );
}

/**
 * Scroll on navigation: top for a new page, the target for a #hash.
 *
 * Anchors need a retry because most sections render from an async content load,
 * so the element usually does not exist on the first frame after navigation.
 */
function useScrollBehaviour() {
  const { pathname, hash, key } = useLocation();

  useEffect(() => {
    if (!hash) {
      window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
      return undefined;
    }

    const id = decodeURIComponent(hash.slice(1));
    let tries = 0;
    let frame = 0;

    const attempt = () => {
      const el = document.getElementById(id);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        return;
      }
      // ~1.5s of retries at 60fps, then give up quietly.
      if (tries < 90) {
        tries += 1;
        frame = requestAnimationFrame(attempt);
      }
    };

    frame = requestAnimationFrame(attempt);
    return () => cancelAnimationFrame(frame);
  }, [pathname, hash, key]);
}
