import { defineConfig } from 'vite';
import base from './vite.config.js';

/**
 * The site, built so React explains itself.
 *
 * `npm run build:debug` — reach for it when a prerendered page misbehaves in the
 * browser and the console only offers "Minified React error #418".
 *
 * Vite pins `process.env.NODE_ENV` to "production" for every build, and that is
 * what selects React's minified error codes; `--mode development` does not
 * change it, and neither does `--minify false` (that only stops the *bundler*
 * minifying, which is why an unminified prod build still prints codes). Defining
 * it here is what actually swaps in the development React — about 1 MB of it,
 * with full messages and the component stack that names the offending element.
 *
 * Build with this, serve with `npm run serve`, and a hydration mismatch prints
 * the server's value, the client's value, and where it is.
 *
 * Never deploy the output: it is several times the size and much slower.
 */
export default defineConfig(async (env) => {
  const config = typeof base === 'function' ? await base(env) : base;
  return {
    ...config,
    define: { ...config.define, 'process.env.NODE_ENV': '"development"' },
    build: { ...config.build, minify: false },
  };
});
