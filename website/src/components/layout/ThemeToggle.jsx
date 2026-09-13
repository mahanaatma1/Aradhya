import { Moon, Sun } from 'lucide-react';
import { useTheme } from '../../hooks/index.js';

/**
 * Light/dark switch.
 *
 * Both icons are always in the DOM and CSS shows one, keyed on
 * `html[data-theme]` (see index.css). That is not a styling preference — it is
 * what lets a prerendered page hydrate: the correct icon is already showing
 * before React mounts, and the markup React produces on its first render is the
 * same regardless of theme, so it matches the HTML the build wrote. Branching in
 * JSX instead would emit the light icon on the server and possibly the dark one
 * in the browser.
 *
 * The label stays fixed for the same reason. It names the control rather than
 * the next state, which also spares a screen-reader user a label that changes
 * under them on every press.
 */
export default function ThemeToggle({ className = '', size = 17 }) {
  const { toggle } = useTheme();

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label="Switch between light and dark reading"
      title="Switch between light and dark reading"
      className={className}
    >
      <Moon size={size} strokeWidth={1.9} className="theme-light-only" aria-hidden="true" />
      <Sun size={size} strokeWidth={1.9} className="theme-dark-only" aria-hidden="true" />
    </button>
  );
}
