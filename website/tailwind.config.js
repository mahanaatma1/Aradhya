/**
 * Aradhya web design tokens.
 *
 * These mirror the mobile app one-for-one — the palette comes from
 * `lib/app/theme/app_colors.dart` and `design/design-system.html`, the type
 * scale from `lib/app/theme/app_theme.dart`. Colours live as space-separated
 * RGB channels in CSS variables (see src/styles/tokens.css) so Tailwind's
 * `/opacity` modifiers keep working and a single `data-theme` swap flips the
 * whole site between the app's paper and espresso grounds.
 */
const withAlpha = (name) => `rgb(var(${name}) / <alpha-value>)`;

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        paper: withAlpha('--paper'),
        'paper-2': withAlpha('--paper-2'),
        'paper-3': withAlpha('--paper-3'),
        card: withAlpha('--card'),
        ink: withAlpha('--ink'),
        'ink-soft': withAlpha('--ink-soft'),
        'ink-faint': withAlpha('--ink-faint'),
        terra: withAlpha('--terra'),
        'terra-dark': withAlpha('--terra-dark'),
        gold: withAlpha('--gold'),
        'gold-bright': withAlpha('--gold-bright'),
        purple: withAlpha('--purple'),
        rose: withAlpha('--rose'),
        green: withAlpha('--green'),
      },
      fontFamily: {
        // Eczar / Inter / Noto Sans Devanagari are the app's bundled families.
        display: ['Eczar', 'Palatino Linotype', 'Book Antiqua', 'Georgia', 'serif'],
        body: ['Inter', 'Segoe UI', 'system-ui', '-apple-system', 'sans-serif'],
        deva: ['Noto Sans Devanagari', 'Nirmala UI', 'Mangal', 'serif'],
      },
      fontSize: {
        // Fluid display sizes — no media queries needed for the big headings.
        'display-xl': ['clamp(2.5rem, 6.2vw, 4.6rem)', { lineHeight: '1.04', letterSpacing: '-0.02em' }],
        'display-lg': ['clamp(2rem, 4.4vw, 3.25rem)', { lineHeight: '1.1', letterSpacing: '-0.015em' }],
        'display-md': ['clamp(1.6rem, 3vw, 2.35rem)', { lineHeight: '1.16', letterSpacing: '-0.01em' }],
        'display-sm': ['clamp(1.35rem, 2.1vw, 1.75rem)', { lineHeight: '1.24' }],
      },
      borderRadius: {
        sm: '10px',
        DEFAULT: '14px',
        md: '18px',
        lg: '24px',
        xl: '28px',
        '2xl': '34px',
      },
      boxShadow: {
        card: '0 10px 26px -14px rgb(var(--shadow-tint) / 0.45)',
        float: '0 26px 44px -20px rgb(var(--shadow-tint) / 0.5)',
        lift: '0 18px 34px -18px rgb(var(--shadow-tint) / 0.42)',
        inset: 'inset 0 1px 0 0 rgb(255 255 255 / 0.5)',
      },
      maxWidth: {
        shell: '1160px',
        prose: '68ch',
      },
      spacing: {
        section: 'clamp(4rem, 8vw, 7.5rem)',
      },
      transitionTimingFunction: {
        calm: 'cubic-bezier(0.22, 0.61, 0.36, 1)',
      },
      keyframes: {
        'fade-up': {
          from: { opacity: '0', transform: 'translateY(14px)' },
          to: { opacity: '1', transform: 'none' },
        },
        'fade-in': { from: { opacity: '0' }, to: { opacity: '1' } },
        'scale-in': {
          from: { opacity: '0', transform: 'scale(0.985) translateY(6px)' },
          to: { opacity: '1', transform: 'none' },
        },
        drift: {
          '0%,100%': { transform: 'translate3d(0,0,0)' },
          '50%': { transform: 'translate3d(0,-10px,0)' },
        },
        'spin-slow': { to: { transform: 'rotate(360deg)' } },
        shimmer: { '100%': { transform: 'translateX(100%)' } },
      },
      animation: {
        'fade-up': 'fade-up 0.6s cubic-bezier(0.22,0.61,0.36,1) both',
        'fade-in': 'fade-in 0.5s ease-out both',
        'scale-in': 'scale-in 0.18s cubic-bezier(0.22,0.61,0.36,1) both',
        drift: 'drift 11s ease-in-out infinite',
        'spin-slow': 'spin-slow 140s linear infinite',
        shimmer: 'shimmer 1.6s infinite',
      },
    },
  },
  plugins: [],
};
