/**
 * The HTML-shaping half of the prerender, separated so it can be tested.
 *
 * scripts/prerender.mjs runs a build the moment it is imported — it reads
 * dist/, renders 254 pages and writes them. That makes it the wrong place for
 * the pure string functions below, which have all the fiddly cases (a `>` inside
 * a description, a `</script>` inside JSON-LD, a shell whose markers moved) and
 * none of the I/O. Here they are importable on their own.
 *
 * Everything in this module is a pure function of its arguments.
 */

import { join } from 'node:path';

/** Escape for an attribute value or text node. */
export function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Tokenise the head tags the prerender owns.
 *
 * Attribute regions allow quoted strings so a `>` inside a description does not
 * end the tag early. Only <meta>, <link> and the two element pairs we replace
 * are matched; everything else in the shell is left untouched.
 */
export const TAG_RE = new RegExp(
  [
    // <meta …> / <link …>
    '<(meta|link)\\b((?:[^>"\']|"[^"]*"|\'[^\']*\')*)>',
    // <title>…</title> / <script …>…</script>
    '<(title|script)\\b((?:[^>"\']|"[^"]*"|\'[^\']*\')*)>([\\s\\S]*?)</\\3\\s*>',
  ].join('|'),
  'gi',
);

/** True for a tag whose job the prerender has taken over. */
export function isOwnedTag(name, attrs) {
  if (name === 'title') return true;
  if (name === 'script') return /type\s*=\s*["']application\/ld\+json["']/i.test(attrs);
  if (name === 'link') return /rel\s*=\s*["']canonical["']/i.test(attrs);
  if (name === 'meta') {
    return (
      /name\s*=\s*["'](description|robots)["']/i.test(attrs) ||
      /property\s*=\s*["']og:/i.test(attrs) ||
      /name\s*=\s*["']twitter:/i.test(attrs)
    );
  }
  return false;
}

/**
 * Strip the owned tags out of the shell's <head>, and report how many went.
 *
 * The count is asserted by the caller: a shell that stopped containing a
 * <title> would otherwise silently produce pages with two of them.
 */
export function stripOwnedTags(html) {
  const headEnd = html.indexOf('</head>');
  if (headEnd === -1) throw new Error('dist/index.html has no </head> — is this a Vite build?');

  let removed = 0;
  const head = html.slice(0, headEnd).replace(TAG_RE, (match, tag, attrs, pair, pairAttrs) => {
    const name = (tag ?? pair).toLowerCase();
    if (!isOwnedTag(name, tag ? attrs : pairAttrs)) return match;
    removed += 1;
    return '';
  });

  // Collapse the blank lines the removals left behind.
  return { html: head.replace(/\r?\n[ \t]*(?=\r?\n)/g, '') + html.slice(headEnd), removed };
}

/**
 * Render one page's head tags as HTML, in a stable order.
 *
 * `canonical: false` omits the canonical link — for the 404 fallback, which is
 * served at whatever URL failed and so has no canonical URL to name.
 */
export function renderMeta(meta, jsonLd, { canonical = true } = {}) {
  const lines = [`<title>${esc(meta.title)}</title>`];
  for (const [name, content] of Object.entries(meta.names)) {
    lines.push(`<meta name="${name}" content="${esc(content)}" />`);
  }
  for (const [property, content] of Object.entries(meta.properties)) {
    lines.push(`<meta property="${property}" content="${esc(content)}" />`);
  }
  if (canonical) lines.push(`<link rel="canonical" href="${esc(meta.canonical)}" />`);
  if (jsonLd) {
    // The id is what useSeo replaces on hydration, so the page never ends up
    // holding two structured-data blocks.
    lines.push(
      '<script type="application/ld+json" id="aradhya-jsonld">' +
        // </script> cannot appear inside a script element, and JSON has no other
        // way out of it.
        JSON.stringify(jsonLd).replace(/</g, '\\u003c') +
        '</script>',
    );
  }
  return lines.map((line) => `    ${line}`).join('\n');
}

/** Where a route's file goes: '/' → dist/index.html, '/about' → dist/about/index.html. */
export function outputPathFor(distDir, pathname) {
  if (pathname === '/') return join(distDir, 'index.html');
  return join(distDir, ...pathname.replace(/^\/+|\/+$/g, '').split('/'), 'index.html');
}

/**
 * Cut the shell into the pieces every page is assembled from, and return the
 * function that puts a page back together.
 *
 * Each marker is asserted for the same reason the tag count is — a shell that
 * quietly stopped matching should stop the build, not produce 254 pages with the
 * body dropped on the floor.
 */
export function shellTemplate(stripped) {
  const headAt = stripped.indexOf('</head>');
  if (headAt === -1) throw new Error('dist/index.html has no </head> — is this a Vite build?');
  const beforeHead = stripped.slice(0, headAt).replace(/[ \t]+$/, '');

  const rootMatch = /<div id="root">\s*<\/div>/.exec(stripped);
  if (!rootMatch) {
    throw new Error('dist/index.html has no empty <div id="root"> — cannot place the rendered body.');
  }
  const bodyEndAt = stripped.indexOf('</body>', rootMatch.index);
  if (bodyEndAt === -1) throw new Error('dist/index.html has no </body>.');

  const headToRoot = stripped.slice(headAt, rootMatch.index);
  const rootToBodyEnd = stripped.slice(rootMatch.index + rootMatch[0].length, bodyEndAt);
  const tail = stripped.slice(bodyEndAt);

  /** One page's HTML: head tags, rendered body, and the data that body came from. */
  return function assemble(head, body, payload) {
    return (
      `${beforeHead}${head}\n  ${headToRoot}` +
      `<div id="root">${body}</div>` +
      `${rootToBodyEnd}${payload}${tail}`
    );
  };
}
