import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { buildMeta } from '../config/seo.js';

/**
 * Per-route document head: title, description, canonical, Open Graph, Twitter.
 *
 * The tags themselves are computed by `buildMeta` in config/seo.js, which
 * scripts/prerender.mjs also uses to write them into static HTML at build time.
 * This hook only applies the result to the live document — so what a crawler
 * reads before JavaScript runs and what it reads after are the same tags.
 *
 * Nothing is restored on unmount, because the next route immediately sets its
 * own.
 */

function upsertMeta(selector, attrs) {
  let el = document.head.querySelector(selector);
  if (!el) {
    el = document.createElement('meta');
    document.head.appendChild(el);
  }
  for (const [key, value] of Object.entries(attrs)) el.setAttribute(key, value);
  return el;
}

function upsertLink(rel, href) {
  let el = document.head.querySelector(`link[rel="${rel}"]`);
  if (!el) {
    el = document.createElement('link');
    el.setAttribute('rel', rel);
    document.head.appendChild(el);
  }
  el.setAttribute('href', href);
}

/**
 * @param {{title?: string, description?: string, image?: string,
 *   type?: string, noindex?: boolean, jsonLd?: object|null}} options
 */
export default function useSeo({
  title,
  description,
  image,
  type = 'website',
  noindex = false,
  jsonLd = null,
} = {}) {
  const { pathname } = useLocation();

  useEffect(() => {
    const meta = buildMeta({ title, description, image, type, noindex, pathname });

    document.title = meta.title;

    for (const [name, content] of Object.entries(meta.names)) {
      upsertMeta(`meta[name="${name}"]`, { name, content });
    }
    for (const [property, content] of Object.entries(meta.properties)) {
      upsertMeta(`meta[property="${property}"]`, { property, content });
    }
    upsertLink('canonical', meta.canonical);
  }, [title, description, image, type, noindex, pathname]);

  // Structured data, kept in its own effect so a content-driven page can supply
  // it once the record has loaded without rewriting every other tag.
  useEffect(() => {
    const id = 'aradhya-jsonld';
    document.getElementById(id)?.remove();
    if (!jsonLd) return undefined;

    const script = document.createElement('script');
    script.id = id;
    script.type = 'application/ld+json';
    script.textContent = JSON.stringify(jsonLd);
    document.head.appendChild(script);

    return () => script.remove();
  }, [jsonLd]);
}
