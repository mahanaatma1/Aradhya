"""Stage 1 — acquire the entity SKELETON from Wikidata (CC0).

    py -m content.tools.wikidata --query deities --out entities/deities.jsonl
    py -m content.tools.wikidata --query lineage --relations

Why Wikidata and not Wikipedia: Wikidata is CC0 (public-domain dedication), so
structure — names, aliases, and typed family edges — can be used freely.
Wikipedia is CC BY-SA and its share-alike is viral: pasting its prose would
license our own descriptions under BY-SA. Wikipedia is therefore a *lead* to
the primary text, never a source of copy.

So this tool emits skeletons only:

    slug, wikidata_qid, titles (en/hi/sa), aliases, kind

Descriptions are deliberately left EMPTY. They get written from the
public-domain translations in extract.py, cited to those translations. A row
produced here cannot pass `validate.py` until a real citation is attached,
which is the intended forcing function — nothing reaches the app on the
strength of "Wikidata said so".
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import (  # noqa: E402
    CONTENT_DIR, REPO_ROOT, STAGING_DIR, has_devanagari, slugify, write_jsonl,
)

ENDPOINT = "https://query.wikidata.org/sparql"
QUERY_DIR = CONTENT_DIR / "queries" / "wikidata"

# A descriptive User-Agent is required by the WDQS policy; anonymous scraping
# gets blocked and would be rude besides.
USER_AGENT = ("AradhyaContentPipeline/1.0 "
              "(offline Hindu-spirituality app; contact: sumerudigitalsm@gmail.com)")

VERIFIED_STUB = {
    "status_en": "unverified",
    "status_hi": "unverified",
    "by": None,
    "at": None,
    "notes": "Skeleton from Wikidata. Descriptions and citations still required.",
}


def run_query(name: str, timeout: int = 90) -> list[dict]:
    path = QUERY_DIR / f"{name}.rq"
    if not path.exists():
        raise SystemExit(f"no such query: {path}")
    query = path.read_text(encoding="utf-8")
    url = f"{ENDPOINT}?format=json&query={urllib.parse.quote(query)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        payload = json.load(resp)
    return payload["results"]["bindings"]


def _v(row: dict, key: str) -> str | None:
    cell = row.get(key)
    if not cell:
        return None
    val = (cell.get("value") or "").strip()
    return val or None


def _qid(uri: str | None) -> str | None:
    if not uri:
        return None
    return uri.rsplit("/", 1)[-1] if uri.startswith("http") else uri


def entities_from(rows: list[dict], kind: str) -> list[dict]:
    """Skeleton rows, one per distinct Wikidata item."""
    out: dict[str, dict] = {}
    for r in rows:
        qid = _qid(_v(r, "item"))
        label = _v(r, "itemLabel")
        # Wikidata falls back to the bare Q-id when a label is missing; those
        # are useless as titles and are dropped rather than slugified.
        if not qid or not label or label.startswith("Q") and label[1:].isdigit():
            continue

        slug = slugify(label)
        if not slug or slug in out:
            continue

        hi = _v(r, "labelHi")
        sa = _v(r, "labelSa")

        aliases = []
        if hi and has_devanagari(hi):
            aliases.append({"alias": hi, "script": "deva", "lang": "hi",
                            "alias_kind": "primary"})
        if sa and has_devanagari(sa) and sa != hi:
            aliases.append({"alias": sa, "script": "deva", "lang": "sa",
                            "alias_kind": "primary"})

        out[slug] = {
            "slug": slug,
            "kind": kind,
            "wikidata_qid": qid,
            "title": {"en": label, "hi": hi, "sa": sa, "iast": None},
            # Left EMPTY on purpose: descriptions must come from a cited
            # public-domain source, not from Wikidata's one-line gloss.
            "short_description": {"en": "", "hi": None},
            "aliases": aliases,
            "tags": [kind],
            "importance": 3,
            "props": {},
            "sources": [],
            "verification": dict(VERIFIED_STUB),
            # Not part of the schema — a note for whoever writes the copy.
            "_wikidata_hint": _v(r, "desc"),
        }
    return list(out.values())


# Wikidata property -> our relation vocabulary.
PROP_MAP = {
    "P22": "father_of",     # subject's father  -> inverted below
    "P25": "mother_of",
    "P26": "spouse_of",
    "P40": "child_of",
    "P3373": "sibling_of",
}


def relations_from(rows: list[dict]) -> list[dict]:
    """Typed edges, with direction corrected.

    Wikidata's P22 means "X has father Y". Our vocabulary reads the other way
    (`father_of`), so those edges are emitted reversed. Getting this backwards
    would invert every family tree in the app, which is exactly the kind of
    error that looks plausible on screen.
    """
    seen: set[tuple] = set()
    out: list[dict] = []
    for r in rows:
        subj = _v(r, "itemLabel")
        obj = _v(r, "otherLabel")
        prop = _qid(_v(r, "prop"))
        if not subj or not obj or prop not in PROP_MAP:
            continue

        s_slug, o_slug = slugify(subj), slugify(obj)
        if not s_slug or not o_slug or s_slug == o_slug:
            continue

        rel = PROP_MAP[prop]
        if prop in ("P22", "P25"):
            # "X has father Y"  =>  Y father_of X
            src, dst = o_slug, s_slug
        elif prop == "P40":
            # "X has child Y"   =>  Y child_of X
            src, dst = o_slug, s_slug
        else:
            src, dst = s_slug, o_slug

        key = (src, rel, dst)
        if key in seen:
            continue
        seen.add(key)

        out.append({
            "src_slug": src,
            "rel_type": rel,
            "dst_slug": dst,
            "confidence": "medium",   # Wikidata alone is not a primary source
            "sources": [{
                "source_slug": "wikidata",
                "source_chapter_or_section": _qid(_v(r, "item")),
                "is_primary": False,
                "last_verified_at": time.strftime("%Y-%m-%d"),
                "verified_by": None,
            }],
        })
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Pull entity skeletons from Wikidata.")
    ap.add_argument("--query", required=True,
                    help="name of a .rq file in content/queries/wikidata")
    ap.add_argument("--kind", default="deity",
                    help="entity kind to stamp on the results")
    ap.add_argument("--out", help="output path relative to content/staging")
    ap.add_argument("--relations", action="store_true",
                    help="emit relation edges instead of entity skeletons")
    ap.add_argument("--dry-run", action="store_true",
                    help="print a sample instead of writing")
    args = ap.parse_args(argv)

    print(f"querying wikidata: {args.query}.rq …")
    rows = run_query(args.query)
    print(f"  {len(rows)} bindings")

    if args.relations:
        records = relations_from(rows)
        default_out = "relations/wikidata_lineage.jsonl"
    else:
        records = entities_from(rows, args.kind)
        default_out = f"entities/{args.query}.jsonl"

    if args.dry_run:
        for rec in records[:5]:
            print(json.dumps(rec, ensure_ascii=False, indent=2)[:600])
        print(f"\n{len(records)} record(s) — dry run, nothing written")
        return 0

    out = STAGING_DIR / (args.out or default_out)
    n = write_jsonl(out, records)
    print(f"wrote {out.relative_to(REPO_ROOT)}: {n} record(s)")
    print("Staged, not published: these rows have no descriptions and no "
          "citations yet. Run extract.py to write cited copy and promote them "
          "into content/data/, which is the only thing the build reads.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
