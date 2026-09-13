import { useEffect, useState } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { Download, Menu, Search, X } from 'lucide-react';
import Wordmark from '../art/Wordmark.jsx';
import ThemeToggle from './ThemeToggle.jsx';
import Button from '../ui/Button.jsx';
import SearchBox from '../search/SearchBox.jsx';
import { primaryNav, routes } from '../../config/routes.js';
import { appConfig } from '../../config/appConfig.js';
import { useLockBodyScroll, useScrolled } from '../../hooks/index.js';

/**
 * Sticky header.
 *
 * Transparent over the hero, translucent once the page scrolls. The search icon
 * opens an inline bar under the header on desktop; on mobile the drawer leads
 * with search, because that is the reason most people arrive here.
 */
export default function Navbar() {
  const scrolled = useScrolled(10);
  const location = useLocation();

  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);

  useLockBodyScroll(menuOpen);

  // Any navigation closes both surfaces.
  useEffect(() => {
    setMenuOpen(false);
    setSearchOpen(false);
  }, [location.pathname, location.search]);

  useEffect(() => {
    if (!searchOpen && !menuOpen) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') {
        setSearchOpen(false);
        setMenuOpen(false);
      }
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [searchOpen, menuOpen]);

  const onSearchPage = location.pathname === routes.search;

  return (
    <>
      {/* Keyboard users get out of the header in one press. */}
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60]
                   focus:rounded-full focus:bg-terra focus:px-4 focus:py-2 focus:text-sm
                   focus:text-[#FFF4E9]"
      >
        Skip to content
      </a>

      <header
        className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 ease-calm
                    ${
                      scrolled || menuOpen || searchOpen
                        ? 'border-b border-ink/[0.08] bg-paper/85 backdrop-blur-xl'
                        : 'border-b border-transparent'
                    }`}
      >
        <div className="shell">
          <div
            className={`flex items-center justify-between transition-all duration-500 ease-calm
                        ${scrolled ? 'h-[4.75rem]' : 'h-[5.5rem]'}`}
          >
            <Link
              to={routes.home}
              aria-label={`${appConfig.name} — home`}
              className="shrink-0 rounded-md transition-opacity duration-200 hover:opacity-85"
            >
              {/* The share-card lockup (public/og-image.svg), and the lotus opens
                  on arrival the way the app's splash opens it. The header mounts
                  once per page load, so it plays on refresh and not on navigation. */}
              <Wordmark size={52} showTagline bloom />
            </Link>

            {/* Desktop nav */}
            <nav aria-label="Primary" className="hidden lg:block">
              <ul className="flex items-center gap-1">
                {primaryNav.map((item) => (
                  <li key={item.to}>
                    <NavLink
                      to={item.to}
                      className={({ isActive }) =>
                        `relative rounded-full px-3.5 py-2 text-[0.88rem] font-medium transition-colors
                         duration-200 ${
                           isActive ? 'text-terra' : 'text-ink-soft hover:bg-ink/[0.04] hover:text-ink'
                         }`
                      }
                    >
                      {({ isActive }) => (
                        <>
                          {item.label}
                          <span
                            aria-hidden="true"
                            className={`absolute inset-x-3.5 -bottom-0.5 h-[1.5px] rounded-full bg-terra
                                        transition-all duration-300 ease-calm
                                        ${isActive ? 'opacity-100' : 'scale-x-0 opacity-0'}`}
                          />
                        </>
                      )}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </nav>

            <div className="flex items-center gap-1.5">
              {!onSearchPage && (
                <button
                  type="button"
                  onClick={() => setSearchOpen((v) => !v)}
                  aria-label={searchOpen ? 'Close search' : 'Search'}
                  aria-expanded={searchOpen}
                  className="hidden h-10 w-10 items-center justify-center rounded-full text-ink-soft
                             transition-colors duration-200 hover:bg-ink/[0.05] hover:text-ink lg:flex"
                >
                  {searchOpen ? <X size={18} strokeWidth={1.9} /> : <Search size={18} strokeWidth={1.9} />}
                </button>
              )}

              <ThemeToggle
                className="hidden h-10 w-10 items-center justify-center rounded-full text-ink-soft
                           transition-colors duration-200 hover:bg-ink/[0.05] hover:text-ink sm:flex"
              />

              <Button href="#get-the-app" size="sm" icon={Download} className="hidden sm:inline-flex">
                Get the App
              </Button>

              <button
                type="button"
                onClick={() => setMenuOpen((v) => !v)}
                aria-label={menuOpen ? 'Close menu' : 'Open menu'}
                aria-expanded={menuOpen}
                className="flex h-10 w-10 items-center justify-center rounded-full text-ink
                           transition-colors duration-200 hover:bg-ink/[0.05] lg:hidden"
              >
                {menuOpen ? <X size={20} strokeWidth={1.9} /> : <Menu size={20} strokeWidth={1.9} />}
              </button>
            </div>
          </div>

          {/* Desktop inline search */}
          <div
            className={`overflow-hidden transition-all duration-300 ease-calm
                        ${searchOpen ? 'max-h-24 pb-4 opacity-100' : 'max-h-0 opacity-0'}`}
          >
            {searchOpen && (
              <SearchBox variant="compact" autoFocus onNavigate={() => setSearchOpen(false)} />
            )}
          </div>
        </div>
      </header>

      {/* Mobile drawer */}
      <div
        className={`fixed inset-0 z-40 lg:hidden ${menuOpen ? '' : 'pointer-events-none'}`}
        aria-hidden={!menuOpen}
      >
        <div
          onClick={() => setMenuOpen(false)}
          className={`absolute inset-0 bg-ink/25 backdrop-blur-sm transition-opacity duration-300
                      ${menuOpen ? 'opacity-100' : 'opacity-0'}`}
        />
        <nav
          aria-label="Menu"
          className={`absolute inset-x-0 top-0 max-h-[92dvh] overflow-y-auto rounded-b-2xl
                      border-b border-ink/[0.08] bg-paper pb-7 pt-[4.9rem] shadow-float
                      transition-transform duration-300 ease-calm
                      ${menuOpen ? 'translate-y-0' : '-translate-y-full'}`}
        >
          <div className="shell">
            {/* Search first — it is why most people are here. */}
            <SearchBox variant="hero" onNavigate={() => setMenuOpen(false)} />

            <ul className="mt-6 divide-y divide-ink/[0.07]">
              {primaryNav.map((item) => (
                <li key={item.to}>
                  <NavLink
                    to={item.to}
                    className={({ isActive }) =>
                      `flex items-center justify-between py-3.5 font-display text-[1.15rem]
                       font-medium transition-colors ${isActive ? 'text-terra' : 'text-ink'}`
                    }
                  >
                    {item.label}
                  </NavLink>
                </li>
              ))}
            </ul>

            <div className="mt-6 flex items-center gap-3">
              <Button href="#get-the-app" size="md" icon={Download} className="flex-1">
                Get the App
              </Button>
              <ThemeToggle
                size={18}
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full
                           border border-ink/15 text-ink-soft transition-colors hover:text-ink"
              />
            </div>
          </div>
        </nav>
      </div>
    </>
  );
}
