import { beforeEach, describe, expect, it, vi } from 'vitest';

import { PRELOAD_ID } from './preload.js';

/**
 * A fresh copy of the module.
 *
 * `store` and `collecting` are module-level, and `store` is deliberately cached
 * after its first read — that is what stops every `useAsync` call re-parsing
 * the blob. So a test that wants to observe the *first* read has to start from
 * a module that has never done one.
 */
async function freshPreload() {
  vi.resetModules();
  return import('./preload.js');
}

function inlineData(json) {
  const el = document.createElement('script');
  el.type = 'application/json';
  el.id = PRELOAD_ID;
  el.textContent = json;
  document.body.append(el);
}

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('preloaded', () => {
  it('reads the value the build inlined for this page', async () => {
    inlineData(JSON.stringify({ 'record:hanuman': { title: 'Hanuman' } }));
    const { preloaded } = await freshPreload();
    expect(preloaded('record:hanuman')).toEqual({ title: 'Hanuman' });
  });

  /**
   * `undefined` is the only miss signal — `useAsync` falls through to the async
   * path on it — so a real `null` value has to survive the round trip.
   */
  it('distinguishes an inlined null from a missing key', async () => {
    inlineData(JSON.stringify({ 'record:nobody': null }));
    const { preloaded } = await freshPreload();
    expect(preloaded('record:nobody')).toBeNull();
    expect(preloaded('record:absent')).toBeUndefined();
  });

  it('returns undefined for a page with no inlined data', async () => {
    const { preloaded } = await freshPreload();
    expect(preloaded('stats')).toBeUndefined();
  });

  it('returns undefined for an empty key rather than looking it up', async () => {
    inlineData(JSON.stringify({ '': 'x' }));
    const { preloaded } = await freshPreload();
    expect(preloaded('')).toBeUndefined();
    expect(preloaded(null)).toBeUndefined();
  });

  /**
   * A blob truncated in transit must cost a skeleton, not the page. This is the
   * difference between "the content arrives a tick later" and a white screen.
   */
  it('survives a truncated blob by behaving as though there were none', async () => {
    inlineData('{"record:hanuman": {"title": "Hanu');
    const { preloaded } = await freshPreload();
    expect(() => preloaded('record:hanuman')).not.toThrow();
    expect(preloaded('record:hanuman')).toBeUndefined();
  });

  it('survives an empty script element', async () => {
    inlineData('');
    const { preloaded } = await freshPreload();
    expect(preloaded('stats')).toBeUndefined();
  });

  it('parses the document once, not per lookup', async () => {
    inlineData(JSON.stringify({ a: 1, b: 2 }));
    const { preloaded } = await freshPreload();
    expect(preloaded('a')).toBe(1);

    // Removing the element after the first read changes nothing: the data is
    // already in memory, which is what lets React's first render be synchronous.
    document.getElementById(PRELOAD_ID).remove();
    expect(preloaded('b')).toBe(2);
  });
});

describe('the build-time collector', () => {
  it('is off by default, so the browser never probes a loader during render', async () => {
    const { isCollecting } = await freshPreload();
    expect(isCollecting()).toBe(false);
  });

  it('records what a render offered, and stops when told', async () => {
    const { startCollecting, offer, stopCollecting, isCollecting } = await freshPreload();

    startCollecting();
    expect(isCollecting()).toBe(true);
    offer('stats', { entities: 174 });
    offer('graph', ['a']);
    const collected = stopCollecting();

    expect(isCollecting()).toBe(false);
    expect(Object.fromEntries(collected)).toEqual({ stats: { entities: 174 }, graph: ['a'] });
  });

  it('ignores offers made outside a collection', async () => {
    const { offer, startCollecting, stopCollecting } = await freshPreload();
    offer('stats', { entities: 174 });
    startCollecting();
    expect(stopCollecting().size).toBe(0);
  });

  it('ignores an undefined value — a miss is not data', async () => {
    const { startCollecting, offer, stopCollecting } = await freshPreload();
    startCollecting();
    offer('missing', undefined);
    offer('present', null);
    const collected = stopCollecting();
    expect(collected.has('missing')).toBe(false);
    expect(collected.get('present')).toBeNull();
  });

  it('returns an empty map when stopped without being started', async () => {
    const { stopCollecting } = await freshPreload();
    expect(stopCollecting()).toEqual(new Map());
  });

  it('starts each page from nothing rather than inheriting the last one', async () => {
    const { startCollecting, offer, stopCollecting } = await freshPreload();
    startCollecting();
    offer('record:rama', { title: 'Rama' });
    stopCollecting();

    startCollecting();
    offer('record:sita', { title: 'Sita' });
    const second = stopCollecting();
    expect([...second.keys()]).toEqual(['record:sita']);
  });
});

describe('setPreload / clearPreload', () => {
  it('installs a page’s data ahead of rendering it', async () => {
    const { setPreload, preloaded } = await freshPreload();
    setPreload({ stats: { entities: 174 } });
    expect(preloaded('stats')).toEqual({ entities: 174 });
  });

  it('accepts the Map the collector hands back, not just an object', async () => {
    const { setPreload, preloaded } = await freshPreload();
    setPreload(new Map([['stats', { entities: 174 }]]));
    expect(preloaded('stats')).toEqual({ entities: 174 });
  });

  it('copies what it is given, so later writes to the source do not leak in', async () => {
    const { setPreload, preloaded } = await freshPreload();
    const source = new Map([['a', 1]]);
    setPreload(source);
    source.set('b', 2);
    expect(preloaded('b')).toBeUndefined();
  });

  it('replaces the previous page rather than merging with it', async () => {
    const { setPreload, preloaded } = await freshPreload();
    setPreload({ 'record:rama': { title: 'Rama' } });
    setPreload({ 'record:sita': { title: 'Sita' } });
    expect(preloaded('record:rama')).toBeUndefined();
    expect(preloaded('record:sita')).toEqual({ title: 'Sita' });
  });

  /**
   * Between pages the build clears the store. Without this the next page would
   * render with the previous page's data still reachable — and, because the
   * verification pass renders from the store, would appear to verify.
   */
  it('clears back to reading the document', async () => {
    inlineData(JSON.stringify({ fromDocument: true }));
    const { setPreload, clearPreload, preloaded } = await freshPreload();

    setPreload({ installed: true });
    expect(preloaded('fromDocument')).toBeUndefined();

    clearPreload();
    expect(preloaded('installed')).toBeUndefined();
    expect(preloaded('fromDocument')).toBe(true);
  });

  it('treats null as an empty store rather than throwing', async () => {
    const { setPreload, preloaded } = await freshPreload();
    setPreload(null);
    expect(preloaded('anything')).toBeUndefined();
  });
});
