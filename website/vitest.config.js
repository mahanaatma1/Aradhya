import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * Test config.
 *
 * Separate from vite.config.js rather than a `test` key inside it, because that
 * file is a function of the build mode and carries SSR branches and manual
 * chunking that mean nothing here. Vitest reads this file instead; the only
 * thing the two need to agree on is the React plugin, so JSX compiles the same
 * way in a test as it does in the bundle.
 *
 * The default environment is jsdom, which is what the components, hooks and
 * browser-facing services need. A file that runs in plain Node during the build
 * opts out with `// @vitest-environment node` at the top — booting jsdom for a
 * string module costs seconds and tests a world it never runs in.
 *
 * Note that `src/services/preload.js` stays on jsdom deliberately: it branches
 * on whether `document` exists, and the browser branch is the one that has to
 * work.
 */
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.js'],
    include: ['src/**/*.test.{js,jsx}', 'scripts/**/*.test.mjs'],
    restoreMocks: true,
  },
});
