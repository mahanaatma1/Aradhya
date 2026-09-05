import { Component } from 'react';
import { TriangleAlert } from 'lucide-react';
import Button from './Button.jsx';
import { appConfig } from '../../config/appConfig.js';
import { routes } from '../../config/routes.js';

/**
 * The last line of defence.
 *
 * Without this, one thrown render — a malformed content row, a chunk that fails
 * to load after a deploy replaces the assets — unmounts the whole tree and the
 * visitor gets a white page with no way out. This keeps the shell and offers the
 * two things that actually help: reload, or go home.
 *
 * It is deliberately a class: `componentDidCatch` has no hook equivalent.
 *
 * Scoped per route in Layout, not around the router, so recovering does not mean
 * losing the header and footer as well.
 */
export default class ErrorBoundary extends Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    // No reporting service, by design — the site collects nothing. The console
    // is where this goes, which is where a developer looking at a broken page
    // will already be.
    console.error('Unhandled error in', this.props.where ?? 'the page', error, info);
  }

  /** A route change should clear the error, so navigation is a way out. */
  componentDidUpdate(prevProps) {
    if (this.state.error && prevProps.resetKey !== this.props.resetKey) {
      this.setState({ error: null });
    }
  }

  render() {
    if (!this.state.error) return this.props.children;

    return (
      <div className="shell pb-section pt-36">
        <div className="surface stitch relative mx-auto max-w-xl px-6 py-14 text-center">
          <span
            className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full
                       bg-paper-2 text-ink-faint"
          >
            <TriangleAlert size={22} strokeWidth={1.6} aria-hidden="true" />
          </span>
          <h1 className="text-display-sm text-ink">Something broke on this page</h1>
          <p className="mx-auto mt-3 max-w-md text-[0.95rem] leading-relaxed text-ink-soft">
            Not your connection — this page failed while rendering. Reloading usually fixes it. If
            it does not, the rest of the site still works, and {appConfig.name} on your phone is
            unaffected.
          </p>

          <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
            <Button variant="secondary" size="sm" onClick={() => window.location.reload()}>
              Reload the page
            </Button>
            <Button variant="ghost" size="sm" to={routes.home} withArrow>
              Go to the home page
            </Button>
          </div>

          <p className="mt-8 text-[0.8rem] text-ink-faint">
            If you can tell us what you were looking at, it gets fixed faster —{' '}
            <a href={`mailto:${appConfig.contactEmail}`} className="link-quiet">
              {appConfig.contactEmail}
            </a>
          </p>
        </div>
      </div>
    );
  }
}
