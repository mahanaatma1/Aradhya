/**
 * Serve dist/ the way a static host does.
 *
 * `vite preview` rewrites every unmatched URL to dist/index.html before it looks
 * for a file, which means it serves the *home page* for /explore/arjuna and
 * hides everything scripts/prerender.mjs wrote. That makes it the wrong tool for
 * checking prerendered output: the pages look broken in a way the deployed site
 * would not be, and a real mismatch would be invisible underneath it.
 *
 * This resolves in the order Netlify, Cloudflare Pages, GitHub Pages and S3 all
 * use:
 *
 *   /path          → dist/path/index.html   (what the prerender writes)
 *   /path.ext      → dist/path.ext
 *   anything else  → dist/404.html, status 404
 *
 * Run it with `npm run serve`. It is a verification tool, not a deployment
 * target — no compression, no caching headers, no HTTP/2.
 */

import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const distDir = fileURLToPath(new URL('../dist', import.meta.url));
const port = Number(process.env.PORT ?? 5183);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2',
  '.xml': 'application/xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.ico': 'image/x-icon',
};

function resolve(pathname) {
  // normalize() collapses `..`, and the prefix check rejects anything that
  // still points outside dist/.
  const rel = normalize(decodeURIComponent(pathname)).replace(/^(\.\.[/\\])+/, '');
  const target = join(distDir, rel);
  if (!target.startsWith(distDir)) return null;

  if (existsSync(target) && statSync(target).isFile()) return target;

  const indexFile = join(target, 'index.html');
  if (existsSync(indexFile)) return indexFile;

  return null;
}

createServer((req, res) => {
  const { pathname } = new URL(req.url, 'http://localhost');
  const file = resolve(pathname);

  if (file) {
    res.writeHead(200, {
      'content-type': TYPES[extname(file)] ?? 'application/octet-stream',
      'cache-control': 'no-store',
    });
    createReadStream(file).pipe(res);
    return;
  }

  const notFound = join(distDir, '404.html');
  if (existsSync(notFound)) {
    res.writeHead(404, { 'content-type': TYPES['.html'], 'cache-control': 'no-store' });
    createReadStream(notFound).pipe(res);
    return;
  }

  res.writeHead(404, { 'content-type': TYPES['.txt'] });
  res.end('Not found');
}).listen(port, () => {
  console.log(`serving dist/ as a static host would → http://localhost:${port}`);
});
