import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * Two builds come out of this file.
 *
 * The default one is the site. The `--ssr` one (see `npm run build:ssr`) bundles
 * src/entry-server.jsx into dist-ssr/ so scripts/prerender.mjs can render pages
 * in plain Node — the only reason it exists is that Node cannot import JSX.
 */
export default defineConfig(({ isSsrBuild }) => ({
  plugins: [react()],
  // strictPort so the dev URL never moves — the preview tooling and .claude/launch.json
  // both assume this exact port.
  server: { port: 5180, strictPort: true, open: false },
  build: {
    target: 'es2020',
    cssCodeSplit: true,
    // The SSR bundle is a build artefact for one Node script: chunking it would
    // only get in the way, and manualChunks names packages that are externalised
    // there anyway.
    ...(isSsrBuild
      ? { ssr: true }
      : {
          rollupOptions: {
            output: {
              // Keep the router/runtime in one cacheable chunk; page code splits
              // itself through React.lazy in src/App.jsx.
              manualChunks: {
                react: ['react', 'react-dom', 'react-router-dom'],
              },
            },
          },
        }),
  },
}));
