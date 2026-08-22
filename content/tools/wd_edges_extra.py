"""The Wikidata edges the first promote pass threw away.

`wd_promote.py` mapped only the five kinship properties, so every other edge in
the pull was silently dropped -- 433 of 1362, of which 346 were P1441 "present
in work". That single property is what connects an epic character to its epic,
and its absence is most of why 285 of 511 entities had no relations at all.

This runs SEPARATELY from `wd_promote` and appends to its own file, because
`wd_promote` is not idempotent: re-running it after its output has been merged
into the curated entity files drops the entities it already merged, taking
their relations with them. Re-running THIS is safe -- it reads the shipped
entity files, resolves both ends of every edge against them, and writes only
what resolves.

Usage:  python -m content.tools.wd_edges_extra
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STAGING = ROOT / 'content' / 'staging' / 'wd_edges.json'
ENT_DIR = ROOT / 'content' / 'data' / 'entities'
OUT = ROOT / 'content' / 'data' / 'relations' / 'wikidata_edges_extra.jsonl'
REL_DIR = ROOT / 'content' / 'data' / 'relations'

D = '2026-08-22'

# Wikidata property -> our rel_type, and whether the edge points the other way.
REL = {
    'P1441': ('appears_in', False),   # X is present in work Y
    'P361':  ('part_of', False),      # X is part of Y
    'P527':  ('contains', False),     # X has part Y
}

# Works that edges point AT but that the class pull never returns, because they
# are texts rather than characters. The two epics were already curated in
# core.jsonl as `-text` slugs; the QIDs are stamped onto those rows rather than
# a second Mahabharata being created beside the first.
EXTRA_SLUGS = {
    'Q8276':   'mahabharata-text',
    'Q37293':  'ramayana-text',
    'Q682958': 'bhagavata-purana',
}


def load_slug_map() -> dict[str, str]:
    """qid -> slug, from every entity file we actually ship."""
    out: dict[str, str] = {}
    for f in sorted(ENT_DIR.glob('*.jsonl')):
        for line in f.open(encoding='utf-8'):
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            q = d.get('wikidata_qid')
            if q and d.get('slug'):
                out[q] = d['slug']
    for q, s in EXTRA_SLUGS.items():
        out.setdefault(q, s)
    return out


def existing_keys() -> set[tuple[str, str, str]]:
    """Everything already asserted, so a re-run adds nothing twice."""
    keys: set[tuple[str, str, str]] = set()
    for f in sorted(REL_DIR.glob('*.jsonl')):
        if f.name == OUT.name:
            continue
        for line in f.open(encoding='utf-8'):
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            keys.add((d['src_slug'], d['rel_type'], d['dst_slug']))
    return keys


def main() -> int:
    if not STAGING.exists():
        print(f'no staging edges at {STAGING}; run wd_pull first')
        return 1

    edges = json.load(STAGING.open(encoding='utf-8'))
    slug_of = load_slug_map()
    seen = existing_keys()

    rows = []
    unresolved: dict[str, int] = {}
    for src, prop, dst in edges:
        if prop not in REL:
            continue
        if src not in slug_of or dst not in slug_of:
            # Track what we are missing so the gap is measurable, not guessed.
            missing = dst if dst not in slug_of else src
            unresolved[missing] = unresolved.get(missing, 0) + 1
            continue
        rel, flip = REL[prop]
        a, b = (dst, src) if flip else (src, dst)
        key = (slug_of[a], rel, slug_of[b])
        if key in seen or slug_of[a] == slug_of[b]:
            continue
        seen.add(key)
        rows.append({
            'src_slug': slug_of[a],
            'rel_type': rel,
            'dst_slug': slug_of[b],
            # Wikidata is a reference, not a primary source. These edges say
            # "the tradition places this character in this text", which is a
            # claim the epic itself is the authority for -- so: medium.
            'confidence': 'medium',
            'sources': [{
                'source_slug': 'wikidata',
                'source_chapter_or_section': src,
                'is_primary': True,
                'last_verified_at': D,
                'verified_by': 'wikidata-pull',
            }],
        })

    rows.sort(key=lambda r: (r['rel_type'], r['src_slug'], r['dst_slug']))
    with OUT.open('w', encoding='utf-8', newline='\n') as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + '\n')

    by_type: dict[str, int] = {}
    for r in rows:
        by_type[r['rel_type']] = by_type.get(r['rel_type'], 0) + 1
    print(f'wrote {len(rows)} edges -> {OUT.name}')
    for k, v in sorted(by_type.items(), key=lambda x: -x[1]):
        print(f'  {k:12} {v}')
    top = sorted(unresolved.items(), key=lambda x: -x[1])[:6]
    if top:
        print('unresolved targets (not entities we hold):')
        for q, n in top:
            print(f'  {q:14} {n}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
