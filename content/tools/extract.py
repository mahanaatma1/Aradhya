"""Stage 2 — turn staged skeletons into publishable content.

    py -m content.tools.extract --todo                 what still needs writing
    py -m content.tools.extract --promote              merge curation -> data/
    py -m content.tools.extract --audit                data-quality problems in staging

## The shape of the editorial step

`wikidata.py` produces skeletons: correct names, Devanagari, QIDs, aliases — and
**no descriptions, no citations**. Those skeletons sit in `content/staging/`,
which the build never reads.

The writing happens in `content/curation/*.jsonl`: one line per slug carrying
the prose and the citations. `--promote` merges

    staging skeleton  (names, aliases, qid)   [CC0, machine]
  + curation entry    (prose, sources)        [written by a person or an AI,
                                               cited to a public-domain text]
  = content/data/entities/*.jsonl             [what the build reads]

Splitting it this way means the machine-acquired half can be re-pulled and
refreshed at any time without touching a word of authored copy, and the
authored half is a small reviewable diff instead of being buried in 337 rows of
generated JSON.

## The rule that matters

A curation entry with no `sources` is refused here, in code — not left for
`validate.py` to catch later. Per the reference doc §2, AI text is permitted for
*phrasing* only; the claim itself must come from a cited source. Anything
without one never reaches `data/` at all.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import (  # noqa: E402
    CONTENT_DIR, DATA_DIR, REPO_ROOT, STAGING_DIR, has_devanagari, read_jsonl,
    write_jsonl,
)

CURATION_DIR = CONTENT_DIR / "curation"


def load_staged() -> dict[str, dict]:
    out: dict[str, dict] = {}
    d = STAGING_DIR / "entities"
    if not d.is_dir():
        return out
    for path in sorted(d.glob("*.jsonl")):
        for _line, obj in read_jsonl(path):
            slug = obj.get("slug")
            if slug:
                out[slug] = obj
    return out


def load_curation() -> dict[str, dict]:
    out: dict[str, dict] = {}
    if not CURATION_DIR.is_dir():
        return out
    for path in sorted(CURATION_DIR.glob("*.jsonl")):
        for _line, obj in read_jsonl(path):
            slug = obj.get("slug")
            if slug:
                out[slug] = obj
    return out


def load_published() -> set[str]:
    out: set[str] = set()
    d = DATA_DIR / "entities"
    if not d.is_dir():
        return out
    for path in sorted(d.glob("*.jsonl")):
        for _line, obj in read_jsonl(path):
            if obj.get("slug"):
                out.add(obj["slug"])
    return out


def merge(skeleton: dict | None, cur: dict) -> dict:
    """Curation wins on every field it specifies; the skeleton fills the rest.

    A hand-written title beats Wikidata's, because Wikidata's label is sometimes
    an odd disambiguation ("Saraswati देवी") and sometimes plain wrong.
    """
    sk = skeleton or {}
    sk_title = sk.get("title") or {}
    cu_title = cur.get("title") or {}

    title = {
        "en": cu_title.get("en") or sk_title.get("en"),
        "hi": cu_title.get("hi") or sk_title.get("hi"),
        "sa": cu_title.get("sa") or sk_title.get("sa"),
        "iast": cu_title.get("iast") or sk_title.get("iast"),
    }
    # Wikidata's `sa` labels are unreliable: some are Latin text mislabelled as
    # Sanskrit ("SURY"). Devanagari or nothing.
    if title["sa"] and not has_devanagari(title["sa"]):
        title["sa"] = None

    aliases = list(sk.get("aliases") or [])
    have = {(a.get("alias") or "").strip() for a in aliases}
    for a in cur.get("aliases") or []:
        if (a.get("alias") or "").strip() not in have:
            aliases.append(a)

    out = {
        "slug": cur["slug"],
        "kind": cur.get("kind") or sk.get("kind") or "deity",
        "title": {k: v for k, v in title.items() if v},
        "short_description": cur["short_description"],
        "aliases": aliases,
        "tags": cur.get("tags") or sk.get("tags") or [],
        "importance": cur.get("importance", sk.get("importance", 3)),
        "sources": cur["sources"],
        "verification": cur["verification"],
    }
    for key in ("wikidata_qid", "category", "region", "tradition", "glyph",
                "image_asset", "long_description", "props", "related_items"):
        val = cur.get(key, sk.get(key))
        if val not in (None, "", [], {}):
            out[key] = val
    return out


def cmd_todo(staged: dict, cur: dict, published: set[str]) -> int:
    pending = [s for s in staged if s not in cur and s not in published]
    print(f"staged {len(staged)} · curated {len(cur)} · published {len(published)}")
    print(f"{len(pending)} skeleton(s) still need cited copy\n")
    for slug in sorted(pending)[:40]:
        hint = staged[slug].get("_wikidata_hint") or ""
        print(f"  {slug:<28} {hint[:60]}")
    if len(pending) > 40:
        print(f"  … and {len(pending) - 40} more")
    return 0


def cmd_audit(staged: dict) -> int:
    """Data-quality problems worth knowing before anyone writes copy."""
    bad_sa, no_hi, suspicious = [], [], []
    for slug, o in staged.items():
        t = o.get("title") or {}
        sa, hi, en = t.get("sa"), t.get("hi"), t.get("en") or ""
        if sa and not has_devanagari(sa):
            bad_sa.append((slug, sa))
        if not hi:
            no_hi.append(slug)
        # A label that is mostly punctuation or very long is usually a
        # disambiguation string rather than a name.
        if len(en) > 40 or "(" in en:
            suspicious.append((slug, en))

    print(f"staged entities: {len(staged)}\n")
    print(f"Sanskrit label not in Devanagari ({len(bad_sa)}) — dropped on merge:")
    for slug, sa in bad_sa[:12]:
        print(f"  {slug:<28} {sa!r}")
    print(f"\nNo Hindi label ({len(no_hi)}) — needs writing by hand:")
    print("  " + ", ".join(sorted(no_hi)[:18]))
    print(f"\nSuspicious English label ({len(suspicious)}):")
    for slug, en in suspicious[:10]:
        print(f"  {slug:<28} {en[:56]}")
    return 0


def cmd_promote(staged: dict, cur: dict, out_name: str) -> int:
    records, refused = [], []
    for slug, entry in sorted(cur.items()):
        # Enforced here rather than downstream: an uncited claim must never
        # reach content/data at all.
        if not entry.get("sources"):
            refused.append((slug, "no sources"))
            continue
        if not (entry.get("short_description") or {}).get("en"):
            refused.append((slug, "no English description"))
            continue
        if not entry.get("verification"):
            refused.append((slug, "no verification block"))
            continue
        records.append(merge(staged.get(slug), entry))

    out = DATA_DIR / "entities" / out_name
    n = write_jsonl(out, records)
    print(f"promoted {n} entity/entities -> {out.relative_to(REPO_ROOT)}")

    matched = sum(1 for r in records if r.get("wikidata_qid"))
    print(f"  {matched} matched a Wikidata skeleton, "
          f"{len(records) - matched} authored from scratch")
    if refused:
        print(f"\nREFUSED {len(refused)} — uncited content does not ship:")
        for slug, why in refused:
            print(f"  {slug:<28} {why}")
    print("\nnext: py -m content.tools.validate")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Promote staged skeletons to data/.")
    ap.add_argument("--todo", action="store_true")
    ap.add_argument("--audit", action="store_true")
    ap.add_argument("--promote", action="store_true")
    ap.add_argument("--out", default="core.jsonl",
                    help="output filename under content/data/entities")
    args = ap.parse_args(argv)

    staged = load_staged()
    cur = load_curation()
    published = load_published()

    if args.audit:
        return cmd_audit(staged)
    if args.promote:
        return cmd_promote(staged, cur, args.out)
    return cmd_todo(staged, cur, published)


if __name__ == "__main__":
    raise SystemExit(main())
