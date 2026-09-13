// @vitest-environment node
// This module is strings in, strings out, and runs in plain Node during the
// build. Booting jsdom for it would cost seconds and test a world it never sees.

import { describe, expect, it } from 'vitest';

import {
  esc,
  isOwnedTag,
  outputPathFor,
  renderMeta,
  shellTemplate,
  stripOwnedTags,
} from './head.mjs';

/** A shell shaped like the one Vite emits, with the tags the prerender owns. */
const SHELL = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Aradhya — Explore. Understand. Practice.</title>
    <meta name="description" content="Search India's spiritual heritage." />
    <meta name="robots" content="index, follow" />
    <meta property="og:title" content="Aradhya" />
    <meta name="twitter:card" content="summary_large_image" />
    <link rel="canonical" href="https://aradhya.app/" />
    <link rel="icon" href="/favicon.svg" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <script type="application/ld+json">{"@type":"WebSite"}</script>
    <script type="module" crossorigin src="/assets/index-abc.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <noscript>Enable JavaScript.</noscript>
  </body>
</html>
`;

describe('esc', () => {
  it('escapes the characters that would break out of an attribute', () => {
    expect(esc('Rama & Sita')).toBe('Rama &amp; Sita');
    expect(esc('a "quoted" word')).toBe('a &quot;quoted&quot; word');
    expect(esc('<script>')).toBe('&lt;script&gt;');
  });

  it('escapes the ampersand first, so an escape is not double-escaped', () => {
    expect(esc('&quot;')).toBe('&amp;quot;');
  });

  it('leaves the non-ASCII text most of this content is made of alone', () => {
    expect(esc('आराध्य — Kṛṣṇa’s')).toBe('आराध्य — Kṛṣṇa’s');
  });
});

describe('isOwnedTag', () => {
  it('claims the tags the prerender rewrites', () => {
    expect(isOwnedTag('title', '')).toBe(true);
    expect(isOwnedTag('meta', 'name="description"')).toBe(true);
    expect(isOwnedTag('meta', 'name="robots"')).toBe(true);
    expect(isOwnedTag('meta', 'property="og:image"')).toBe(true);
    expect(isOwnedTag('meta', 'name="twitter:card"')).toBe(true);
    expect(isOwnedTag('link', 'rel="canonical"')).toBe(true);
    expect(isOwnedTag('script', 'type="application/ld+json"')).toBe(true);
  });

  /**
   * The inverse matters more than the positive case: claiming the module
   * script would delete the application from every page.
   */
  it('leaves everything else in the shell alone', () => {
    expect(isOwnedTag('meta', 'charset="UTF-8"')).toBe(false);
    expect(isOwnedTag('meta', 'name="viewport" content="width=device-width"')).toBe(false);
    expect(isOwnedTag('meta', 'name="theme-color" content="#0b0b0f"')).toBe(false);
    expect(isOwnedTag('link', 'rel="icon" href="/favicon.svg"')).toBe(false);
    expect(isOwnedTag('link', 'rel="preconnect" href="https://fonts.gstatic.com"')).toBe(false);
    expect(isOwnedTag('link', 'rel="stylesheet" href="/assets/index.css"')).toBe(false);
    expect(isOwnedTag('script', 'type="module" src="/assets/index.js"')).toBe(false);
  });

  it('matches attributes however they are quoted or spaced', () => {
    expect(isOwnedTag('link', "rel='canonical'")).toBe(true);
    expect(isOwnedTag('link', 'rel = "canonical"')).toBe(true);
    expect(isOwnedTag('meta', 'NAME="DESCRIPTION"')).toBe(true);
  });

  /**
   * `rel="canonical-ish"` is not a canonical link. The pattern has no anchor
   * after the value, so this documents that the closing quote does the work.
   */
  it('does not claim a tag whose attribute merely starts the same way', () => {
    expect(isOwnedTag('link', 'rel="canonicalise"')).toBe(false);
    expect(isOwnedTag('meta', 'name="descriptions"')).toBe(false);
  });
});

describe('stripOwnedTags', () => {
  const { html, removed } = stripOwnedTags(SHELL);

  it('removes exactly the owned tags', () => {
    // title, description, robots, og:title, twitter:card, canonical, ld+json.
    expect(removed).toBe(7);
  });

  it('leaves the shell able to boot', () => {
    expect(html).toContain('<meta charset="UTF-8" />');
    expect(html).toContain('name="viewport"');
    expect(html).toContain('rel="icon"');
    expect(html).toContain('rel="preconnect"');
    expect(html).toContain('src="/assets/index-abc.js"');
    expect(html).toContain('<div id="root"></div>');
  });

  it('takes the owned tags out', () => {
    expect(html).not.toContain('<title>');
    expect(html).not.toContain('name="description"');
    expect(html).not.toContain('rel="canonical"');
    expect(html).not.toContain('application/ld+json');
  });

  it('reports zero for a shell it does not recognise, rather than passing silently', () => {
    // The build asserts on this count — it is the signal that index.html changed
    // shape, which would otherwise ship pages with two <title>s.
    const { removed: none } = stripOwnedTags('<html><head></head><body></body></html>');
    expect(none).toBe(0);
  });

  it('refuses a document with no head', () => {
    expect(() => stripOwnedTags('<html><body>hi</body></html>')).toThrow(/no <\/head>/);
  });

  /**
   * The regex allows quoted regions precisely so this case works: a `>` inside
   * a description must not be read as the end of the tag, or everything after
   * it on that line survives into the output as loose text.
   */
  it('handles a > inside an attribute value', () => {
    const shell = `<html><head>
    <meta name="description" content="Krishna -> Arjuna, and back" />
    <meta name="keep" content="yes" />
    </head><body></body></html>`;
    const out = stripOwnedTags(shell);
    expect(out.removed).toBe(1);
    expect(out.html).not.toContain('Arjuna, and back');
    expect(out.html).toContain('name="keep"');
  });

  it('does not touch the body, even when it contains an owned tag name', () => {
    const shell = '<html><head><title>a</title></head><body><p>&lt;title&gt;</p></body></html>';
    expect(stripOwnedTags(shell).html).toContain('<p>&lt;title&gt;</p>');
  });
});

describe('renderMeta', () => {
  const meta = {
    title: 'Hanuman — Aradhya',
    canonical: 'https://aradhya.app/explore/hanuman',
    names: { description: 'A devotee & a hero', robots: 'index, follow' },
    properties: { 'og:title': 'Hanuman — Aradhya' },
  };

  it('writes one tag per line, in a stable order', () => {
    const lines = renderMeta(meta, null).split('\n').map((l) => l.trim());
    expect(lines).toEqual([
      '<title>Hanuman — Aradhya</title>',
      '<meta name="description" content="A devotee &amp; a hero" />',
      '<meta name="robots" content="index, follow" />',
      '<meta property="og:title" content="Hanuman — Aradhya" />',
      '<link rel="canonical" href="https://aradhya.app/explore/hanuman" />',
    ]);
  });

  it('omits the canonical when asked — the 404 is served at any URL', () => {
    expect(renderMeta(meta, null, { canonical: false })).not.toContain('rel="canonical"');
  });

  it('gives the JSON-LD the id useSeo replaces, so a page never holds two', () => {
    const html = renderMeta(meta, { '@type': 'DefinedTerm' });
    expect(html).toContain('<script type="application/ld+json" id="aradhya-jsonld">');
  });

  /**
   * `</script>` inside a script element ends it, wherever it appears — including
   * inside a JSON string. JSON has no escape for it, so the `<` is escaped
   * instead. Without this, a summary quoting HTML would end the block early and
   * spill the rest of the record into the page as text.
   */
  it('cannot be escaped out of by content containing </script>', () => {
    const html = renderMeta(meta, { description: 'closes with </script> here' });
    expect(html).not.toContain('</script> here');
    expect(html).toContain('\\u003c/script>');
    // Still valid JSON, and still says the same thing.
    const json = html.slice(html.indexOf('>', html.indexOf('<script')) + 1, html.lastIndexOf('</script>'));
    expect(JSON.parse(json).description).toBe('closes with </script> here');
  });
});

describe('outputPathFor', () => {
  it('maps the root to the shell itself', () => {
    expect(outputPathFor('dist', '/')).toMatch(/^dist[\\/]index\.html$/);
  });

  it('gives every other route a directory with an index.html', () => {
    expect(outputPathFor('dist', '/about')).toMatch(/^dist[\\/]about[\\/]index\.html$/);
    expect(outputPathFor('dist', '/explore/hanuman'))
      .toMatch(/^dist[\\/]explore[\\/]hanuman[\\/]index\.html$/);
  });

  it('ignores surrounding slashes rather than producing an empty segment', () => {
    expect(outputPathFor('dist', '/about/')).toBe(outputPathFor('dist', '/about'));
  });
});

describe('shellTemplate', () => {
  const { html: stripped } = stripOwnedTags(SHELL);
  const assemble = shellTemplate(stripped);

  it('puts the head tags before </head> and the body inside #root', () => {
    const page = assemble('    <title>X</title>', '<h1>Hanuman</h1>', '');
    expect(page.indexOf('<title>X</title>')).toBeLessThan(page.indexOf('</head>'));
    expect(page).toContain('<div id="root"><h1>Hanuman</h1></div>');
  });

  it('keeps the rest of the shell byte-for-byte', () => {
    const page = assemble('', '', '');
    expect(page).toContain('<meta charset="UTF-8" />');
    expect(page).toContain('src="/assets/index-abc.js"');
    expect(page).toContain('<noscript>Enable JavaScript.</noscript>');
    expect(page.endsWith('</html>\n')).toBe(true);
  });

  it('puts the payload after the body and before </body>', () => {
    const page = assemble('', '<p>x</p>', '<script id="aradhya-preload">{}</script>');
    expect(page.indexOf('<p>x</p>')).toBeLessThan(page.indexOf('aradhya-preload'));
    expect(page.indexOf('aradhya-preload')).toBeLessThan(page.indexOf('</body>'));
  });

  it('emits an empty #root when there is no body, which is what /404 wants', () => {
    expect(assemble('', '', '')).toContain('<div id="root"></div>');
  });

  it('refuses a shell whose mount point is missing', () => {
    expect(() => shellTemplate('<html><head></head><body></body></html>'))
      .toThrow(/no empty <div id="root">/);
  });

  it('refuses a shell whose #root is already full — that build was not clean', () => {
    expect(() => shellTemplate('<html><head></head><body><div id="root"><p>x</p></div></body></html>'))
      .toThrow(/no empty <div id="root">/);
  });
});
