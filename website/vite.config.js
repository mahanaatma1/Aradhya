import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // strictPort so the dev URL never moves — the preview tooling and .claude/launch.json
  // both assume this exact port.
  server: { port: 5180, strictPort: true, open: false },
  build: {
    target: 'es2020',
    cssCodeSplit: true,
    rollupOptions: {
      output: {
        // Keep the router/runtime in one cacheable chunk; page code splits itself
        // through React.lazy in src/App.jsx.
        manualChunks: {
          react: ['react', 'react-dom', 'react-router-dom'],
        },
      },
    },
  },
});
