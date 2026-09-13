"""Promote the Wikidata pull into content/data/entities.

Two rules decide what ships.

BILINGUAL OR NOT AT ALL. Only entities that carry a real Hindi label from
Wikidata are promoted. Auto-transliterating the rest was tried and rejected:
ITRANS on an English spelling turns Dhritarashtra into ध्रितरश्त्र when the
correct form is धृतराष्ट्र. Wrong Devanagari in a devotional app is worse than
no entry, so the 240 without a Hindi label are left out rather than faked.

FACTS ONLY, AND CITED. Descriptions are assembled from the structured CC0 data
we actually pulled -- the kind, and the typed family edges -- never from
Wikipedia prose, which is CC BY-SA and would infect our licensing. Nothing is
invented: if we do not hold a fact, the sentence describing it is not written.

Everything lands as verification_status unverified. These are machine-assembled
from a reference source and have not been read by a human, which is exactly
what --strict refuses to ship. That is the intended gate, not an oversight.
"""
import json, pathlib, re, sqlite3, sys, unicodedata

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
from content.tools.common import fold_variants  # UTF-8 stdout too

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
STAGING = ROOT / 'content' / 'staging'
D = "2026-08-15"

ents = json.loads((STAGING / 'wd_entities.json').read_text(encoding='utf-8'))
edges = json.loads((STAGING / 'wd_edges.json').read_text(encoding='utf-8'))
aliases = json.loads((STAGING / 'wd_aliases.json').read_text(encoding='utf-8'))

# Only the fully bilingual ones.
keep = {q: v for q, v in ents.items() if v.get('hi')}


def slugify(s: str) -> str:
    """ASCII slug that FOLDS diacritics rather than deleting them.

    Deleting them turned Droṇa into 'dro-a' and Jaṭāyu into 'ja-yu'. NFKD
    splits the base letter from its mark, so the letter survives.
    """
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(c for c in s if not unicodedata.combining(c))
    s = s.lower().replace("'", "").replace('’', '')
    s = re.sub(r'[^a-z0-9]+', '-', s).strip('-')
    return s[:60]


def title_keys(s: str) -> set[str]:
    """Every spelling this title could be written as.

    Bhīṣma and Bhishma are the same person, and a plain
    strip-the-marks fold does not see that: it yields 'bhisma' against
    'bhishma'. fold_variants is the app's own transliteration map, so the
    merge key here matches how search already treats these names.
    """
    return set(fold_variants(s))


# Existing slugs and QIDs, so a re-run cannot duplicate the curated entities.
existing_slugs, existing_qids = set(), set()
# folded (kind, title) -> the slug we already curated for that figure
curated: dict[tuple[str, str], str] = {}
gyan = ROOT / 'assets' / 'db' / 'gyan.sqlite'
if gyan.exists():
    db = sqlite3.connect(f'file:{gyan}?mode=ro', uri=True)
    for slug, kind, title in db.execute(
            'select slug, kind, title_en from entities'):
        existing_slugs.add(slug)
        for k in title_keys(title or ''):
            curated[(kind, k)] = slug
    for (q,) in db.execute(
            'select wikidata_qid from entities where wikidata_qid is not null'):
        existing_qids.add(q)
    db.close()

slug_of: dict[str, str] = {}
# QIDs that resolve to an entity we already curated by hand. Their relations
# are still imported -- that is the whole point, the hand-written Draupadi
# gains her Wikidata lineage -- but no second entity row is emitted for them.
merged: set[str] = set()
seen_titles: set[tuple[str, str]] = set()
for q, v in sorted(keep.items()):
    s = slugify(v['en'])
    if not s or q in existing_qids:
        continue
    hit = next((curated[(v['kind'], k)] for k in title_keys(v['en'])
                if (v['kind'], k) in curated), None)
    if hit:
        slug_of[q] = hit
        merged.add(q)
        continue
    # Wikidata carries several items with the same English label in the same
    # class. Two entries a reader cannot tell apart are worse than one.
    keys = {(v['kind'], k) for k in title_keys(v['en'])}
    if keys & seen_titles:
        continue
    seen_titles |= keys
    base, n = s, 2
    while s in existing_slugs or s in slug_of.values():
        s, n = f'{base}-{n}', n + 1
    slug_of[q] = s

# --------------------------------------------------------------- relations
# Wikidata property -> our rel_type, and whether the edge points the other way.
# P22 says "X has father Y", which in our vocabulary is "Y father_of X".
REL = {
    'P22':   ('father_of', True),
    'P25':   ('mother_of', True),
    'P26':   ('spouse_of', False),
    'P40':   ('child_of', True),
    'P3373': ('sibling_of', False),
    'P1038': ('related_to', False),
}

rels = []
seen_rel = set()
for src, prop, dst in edges:
    if prop not in REL or src not in slug_of or dst not in slug_of:
        continue
    rel, flip = REL[prop]
    a, b = (dst, src) if flip else (src, dst)
    key = (slug_of[a], rel, slug_of[b])
    if key in seen_rel:
        continue
    seen_rel.add(key)
    rels.append({
        "src_slug": slug_of[a], "rel_type": rel, "dst_slug": slug_of[b],
        "confidence": "medium",
        "sources": [{"source_slug": "wikidata",
                     "source_chapter_or_section": src,
                     "is_primary": True, "last_verified_at": D,
                     "verified_by": "wikidata-pull"}],
    })

# Family edges by slug, for building the description sentences.
parents: dict[str, list[str]] = {}
spouses: dict[str, list[str]] = {}
for r in rels:
    if r['rel_type'] in ('father_of', 'mother_of'):
        parents.setdefault(r['dst_slug'], []).append(r['src_slug'])
    elif r['rel_type'] == 'child_of':
        parents.setdefault(r['src_slug'], []).append(r['dst_slug'])
    elif r['rel_type'] == 'spouse_of':
        spouses.setdefault(r['src_slug'], []).append(r['dst_slug'])
        spouses.setdefault(r['dst_slug'], []).append(r['src_slug'])

title_of = {slug_of[q]: (v['en'], v['hi']) for q, v in keep.items()
            if q in slug_of}

KIND_LINE = {
    'deity': ("A deity of the Hindu tradition.",
              "\u0939\u093f\u0928\u094d\u0926\u0942 \u092a\u0930\u0902\u092a\u0930\u093e \u0915\u0947 \u090f\u0915 \u0926\u0947\u0935\u0924\u093e\u0964"),
    'rishi': ("A sage of the Vedic tradition.",
              "\u0935\u0948\u0926\u093f\u0915 \u092a\u0930\u0902\u092a\u0930\u093e \u0915\u0947 \u090f\u0915 \u090b\u0937\u093f\u0964"),
    'human': ("A figure of the epic and Puranic tradition.",
              "\u092e\u0939\u093e\u0915\u093e\u0935\u094d\u092f \u0914\u0930 \u092a\u0941\u0930\u093e\u0923 \u092a\u0930\u0902\u092a\u0930\u093e \u0915\u093e \u090f\u0915 \u092a\u093e\u0924\u094d\u0930\u0964"),
}


def describe(slug: str, kind: str) -> tuple[str, str]:
    """One bilingual sentence per fact we actually hold. Never more."""
    en_parts, hi_parts = [], []
    base = KIND_LINE.get(kind, KIND_LINE['human'])
    en_parts.append(base[0])
    hi_parts.append(base[1])

    # `dict.fromkeys` is load-bearing, not tidiness. `parents[slug]` is fed by
    # two branches above -- P22/P25 inverted (`dasharatha father_of rama`) and
    # P40 direct (`rama child_of dasharatha`) -- and Wikidata states both
    # directions, so a single father arrives twice and read "Child of Dasharatha
    # and Dasharatha." That was in 41 shipped descriptions. The spouse path
    # below already deduplicated; this one did not, which is why only the parent
    # sentence doubled.
    ps = [title_of[p] for p in dict.fromkeys(parents.get(slug, []))
          if p in title_of][:2]
    if ps:
        en_parts.append("Child of " + " and ".join(p[0] for p in ps) + ".")
        hi_parts.append(" \u0914\u0930 ".join(p[1] for p in ps)
                        + " \u0915\u0940 \u0938\u0902\u0924\u093e\u0928\u0964")

    ss = [title_of[p] for p in dict.fromkeys(spouses.get(slug, []))
          if p in title_of][:2]
    if ss:
        en_parts.append("Consort of " + " and ".join(p[0] for p in ss) + ".")
        hi_parts.append(" \u0914\u0930 ".join(p[1] for p in ss)
                        + " \u0915\u0947 \u091c\u0940\u0935\u0928\u0938\u093e\u0925\u0940\u0964")

    en, hi = " ".join(en_parts), " ".join(hi_parts)
    return en[:200], hi[:200]


# ----------------------------------------------------------------- aliases
alias_by_q: dict[str, list[tuple[str, str]]] = {}
for q, text, lang in aliases:
    if q not in slug_of or not text.strip():
        continue
    alias_by_q.setdefault(q, []).append((text.strip(), lang))

rows = []
for q, v in sorted(keep.items()):
    slug = slug_of.get(q)
    if not slug or q in merged:
        continue
    en, hi = describe(slug, v['kind'])
    al = [{"alias": v['en'], "script": "latn", "lang": "en",
           "alias_kind": "primary"},
          {"alias": v['hi'], "script": "deva", "lang": "hi",
           "alias_kind": "primary"}]
    for text, lang in alias_by_q.get(q, [])[:6]:
        al.append({"alias": text,
                   "script": "deva" if lang in ("hi", "sa") else "latn",
                   "lang": lang, "alias_kind": "spelling"})
    o = {
        "slug": slug,
        "kind": v['kind'],
        "wikidata_qid": q,
        "title": {"en": v['en'], "hi": v['hi']},
        "short_description": {"en": en, "hi": hi},
        "aliases": al,
        "tags": [v['kind']],
        "importance": 3,
        "sources": [{"source_slug": "wikidata",
                     "source_chapter_or_section": q,
                     "is_primary": True, "last_verified_at": D,
                     "verified_by": "wikidata-pull"}],
        "verification": {"status_en": "unverified", "status_hi": "unverified",
                         "by": "wikidata-pull", "at": D,
                         "notes": "Skeleton imported from Wikidata (CC0); descriptions assembled from its structured facts only."},
    }
    if v.get('sa'):
        o['title']['sa'] = v['sa']
    rows.append(o)

out_e = ROOT / 'content' / 'data' / 'entities' / 'wikidata_graph.jsonl'
out_r = ROOT / 'content' / 'data' / 'relations' / 'wikidata_graph.jsonl'
out_r.parent.mkdir(parents=True, exist_ok=True)
for path, data in ((out_e, rows), (out_r, rels)):
    with path.open('w', encoding='utf-8', newline='\n') as fh:
        for r in data:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")

print(f"entities  {len(rows)}  -> {out_e.name}")
print(f"relations {len(rels)} -> {out_r.name}")
print(f"merged    {len(merged)} onto entities we had already curated")
print(f"skipped   {len(ents) - len(keep)} without a Hindi label")
