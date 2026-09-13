"""Merge or disambiguate the importer's `<base>-N` collision slugs.

    py -m content.tools.merge_entities --dry-run
    py -m content.tools.merge_entities

The Wikidata pull appends a counter when a slug is taken instead of deciding
what the collision means, and stamps every row it imports `kind: human,
importance: 3`. Twelve of those shipped. `validate.check_collision_suffix` now
refuses them; this is the one-time repair of the ones already in the data.

Two outcomes, and which one applies is a research question, not a shape:

  MERGE       one figure split in two. The dup row is deleted and every
              reference to it is repointed at the base, which keeps its own
              authored prose, kind, importance and citation -- the dup's
              contribution is its EDGES, which is the whole reason the split
              mattered.

  DISAMBIGUATE  two figures that happen to share a name. Nothing is merged.
              The counter is replaced by a slug that says which figure it is,
              and the titles are qualified so a reader looking at a list of
              search results can tell them apart -- which, with two rows reading
              "Bhadra / भद्रा" and both carrying the importer's placeholder
              description, they could not.

Every decision below cites the Wikidata QID it was made from, because for four
of these twelve the QIDs are what settled it and a later reader will want to
re-check rather than take my word.
"""

from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "content" / "data"

# Keys whose value is an entity or narrative-node slug. `source_slug` is
# deliberately absent: it names a row in content/sources/registry.jsonl, not an
# entity, and rewriting it would corrupt citations.
REF_KEYS = {
    "dst_slug", "src_slug", "entity_slug", "place_entity_slug",
    "deity_entity_slug", "parent_slug", "vahana_slug", "ashram_place_slug",
    "story_node_slug", "based_on_node_slug",
}
REF_LIST_KEYS = {"ayudha_slugs", "consort_slugs", "entity_slugs"}

# ---------------------------------------------------------------- decisions

# One figure split in two. Verified pair by pair against the base row's authored
# description and the dup's QID; in every case the dup's edges are either new
# facts consistent with the base or literal restatements of edges the base
# already had (`atri spouse_of anasuya`, `kamsa child_of ugrasena`), which is
# itself confirmation that the two rows are about the same figure.
MERGE = {
    # Q757727 Atri. Base: Saptarishi, Rig Veda Mandala V, spouse Anasuya,
    # father of Chandra and Durvasa. Dup restates spouse+father and adds
    # appears_in.
    "atri-2": "atri",
    # Q3519846. Devanagari differs only as दधीच / दधीचि, and the alias list
    # carries "Dadhyancha" -- the sage who gives his bones for Indra's vajra,
    # which is the base row's authored description verbatim in substance.
    "dadhichi-2": "dadhichi",
    # Q2361344. Dup gives child_of Anasuya and sibling_of Chandra; the base
    # already holds `atri father_of durvasa`. Atri and Anasuya are the parents
    # and Chandra the brother -- consistent, and additive.
    "durvasa-2": "durvasa",
    # Q4180707 Gandiva -- Arjuna's bow, imported as `kind: human`. The base is
    # the same bow, cited to Gita 1.30 where Arjuna sets it down.
    "gandiva-2": "gandiva",
    # Q2092267. Base already holds child_of Ugrasena.
    "kamsa-2": "kamsa",
    # Q721272 Lanka -- Ravana's island, imported as `kind: human`.
    "lanka-2": "lanka",
    # Q249381 Mārkaṇḍeya. Same sage; the dup's title carries the honorific ऋषि.
    "markandeya-2": "markandeya",
    # Q825682. Dup gives child_of Renuka; the base holds `jamadagni father_of
    # parashurama`. Jamadagni and Renuka are his parents.
    "parashurama-2": "parashurama",
    # Q160213 Rama. The consequential one: the dup carried the entire genealogy
    # -- father Dasharatha, sons Lava and Kusha, siblings Lakshmana, Bharata,
    # Shatrughna and Shanta -- at importance 3, while the base carried the
    # teaching, dynasty and avatara edges at importance 1. The canonical Rama's
    # family tree therefore showed no family at all.
    "rama-2": "rama",
    # Q797498. Dup gives child_of Danu, which is what makes him a Danava; the
    # base is the serpent Indra strikes with the vajra.
    "vritra-2": "vritra",
}

# Namesakes. Merging these would have been the worse error, so each is recorded
# with the evidence that separates them.
DISAMBIGUATE: dict[str, dict] = {
    # काली the Goddess (base `kali`, importance 1, Gopinatha Rao) against कलि,
    # Q1580107, whose own English description on Wikidata reads "satan demon in
    # Hindu mythology" and whose edges are consort of Alakshmi and sibling of
    # Durukti. Two different figures whose Latin transliterations collide; the
    # Devanagari never did, which is why only an English reader was misled.
    #
    # This pair is also why `kali` appeared in the plan's list of zero-degree P0
    # entities blamed on an unregistered source. Its eight edges were never
    # missing. They were on the other row.
    "kali-2": {
        "slug": "kali-asura",
        "kind": "asura",
        "title": {"en": "Kali (asura)", "hi": "कलि"},
        "short_description": {
            "en": "An asura of the Puranic tradition, distinct from the "
                  "goddess Kali (काली). Consort of Alakshmi and sibling of "
                  "Durukti.",
            "hi": "पुराण परंपरा का एक असुर, देवी काली से भिन्न। अलक्ष्मी का "
                  "जीवनसाथी और दुरुक्ति का भाई।",
        },
        "tags": ["asura"],
        # The importer's primary aliases were 'Kali' and 'कलि'. The bare Latin
        # 'Kali' is exactly the collision this row is being renamed to end:
        # `link_entities()` resolves mentions against aliases, so leaving it here
        # would wire every occurrence of "Kali" in the corpus to the asura rather
        # than to काली the Goddess, whose own title is 'Kali'. The Devanagari
        # कलि never collided -- काली is a different string -- so it is the one
        # form worth keeping.
        "aliases": [{"alias": "कलि", "alias_kind": "primary", "lang": "hi",
                     "script": "deva"}],
    },
    # Two of Bhadra's namesakes, and Wikidata holds them as two items:
    # Q14589610, labelled "Bhadra" and described "Krishna's wife" (spouse
    # Q42891, Krishna; the English article is titled "Bhadra (Krishna's
    # wife)"), and Q760003, labelled "Bhadra" and described "Hindu goddess"
    # (spouse Q223617, Kubera; our own edges give her as mother of Nalakuvara).
    #
    # Neither keeps the bare `bhadra`. Leaving it on one of them would re-create
    # the same trap for whichever row lost the coin toss, and there is no
    # priority to appeal to -- both are importer skeletons of equal standing.
    "bhadra": {
        "slug": "bhadra-krishna-consort",
        "title": {"en": "Bhadra (consort of Krishna)", "hi": "भद्रा (कृष्ण की पत्नी)"},
        "short_description": {
            "en": "One of Krishna's queens.",
            "hi": "कृष्ण की एक रानी।",
        },
        # Both rows carried 'Bhadra' and 'भद्रा' as primary aliases, and the gate
        # is right that keeping them "will mis-wire related_edges": a bare
        # "Bhadra" in the corpus resolves to whichever of the two the matcher
        # reaches first. Neither may claim it. An unresolvable name is better
        # left unclaimed than resolved by accident, and the qualified titles are
        # what a reader needs anyway.
        "aliases": [],
    },
    "bhadra-2": {
        "slug": "bhadra-kubera-consort",
        "kind": "deity",
        "title": {"en": "Bhadra (consort of Kubera)", "hi": "भद्रा (कुबेर की पत्नी)"},
        "short_description": {
            "en": "A goddess of the Hindu tradition. Child of Chandra, "
                  "consort of Kubera and mother of Nalakuvara.",
            "hi": "हिन्दू परंपरा की एक देवी। चंद्र की संतान, कुबेर की पत्नी "
                  "और नलकूवर की माता।",
        },
        "aliases": [],
    },
}


# ------------------------------------------------------------------ helpers

def fold(s: str) -> str:
    return " ".join((s or "").lower().split())


def files() -> list[Path]:
    return sorted(Path(p) for p in glob.glob(str(DATA / "**" / "*.jsonl"),
                                             recursive=True))


def read(path: Path) -> list[dict]:
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            out.append(json.loads(line))
    return out


def write(path: Path, rows: list[dict]) -> None:
    body = "".join(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n"
                   for r in rows)
    path.write_text(body, encoding="utf-8")


def repoint(obj, mapping: dict[str, str]) -> int:
    """Rewrite entity references in place. Returns how many it changed."""
    n = 0
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in REF_KEYS and isinstance(v, str) and v in mapping:
                obj[k] = mapping[v]
                n += 1
            elif k in REF_LIST_KEYS and isinstance(v, list):
                for i, item in enumerate(v):
                    if isinstance(item, str) and item in mapping:
                        v[i] = mapping[item]
                        n += 1
            else:
                n += repoint(v, mapping)
    elif isinstance(obj, list):
        for v in obj:
            n += repoint(v, mapping)
    return n


def alias_candidates(dup: dict, base: dict, taken: dict[str, str]) -> list[dict]:
    """The dup's aliases that are worth a later pass, and are not junk.

    Deliberately NOT merged into the base. The base rows here are hand-authored
    and `status: verified`; the dup rows are importer skeletons carrying
    `verified_by: wikidata-pull` and `status: unverified`. Copying an alias
    across that line silently relabels an unverified claim as a verified one, on
    a row whose whole value is that its claims were read against a primary text.

    The risk is not theoretical, and a first version of this that did merge them
    proved it twice. `kamsa-2` claimed **वाराणसी** -- Varanasi, a city -- as an
    alias of Kamsa. `rama-2` claimed **Narayan, नारायण and पुरुषोत्तम**, which
    are Vishnu's epithets; a search for them would have returned Rama. Neither
    was caught by checking the alias against names other entities already own,
    because no entity row happens to claim either -- which is the point: a rule
    that can only see conflicts cannot see a claim that is simply false.

    So they are parked, with the pair they came from, in
    content/staging/merged_aliases.json. 'Dadhyancha', 'Bhargava Rama' and
    'Jamadagnya Rama' are real and useful for search, and re-adding them wants
    one citation each, not a bulk copy.
    """
    out, base_titles = [], {fold(v) for v in (base.get("title") or {}).values()}
    have = {fold(a.get("alias") or "") for a in base.get("aliases") or []}
    for al in dup.get("aliases") or []:
        text = al.get("alias") or ""
        f = fold(text)
        # Already said, in the title or in an alias the base holds.
        if not f or f in base_titles or f in have:
            continue
        # A single alias holding a comma is two names the scraper ran together
        # ('वृत्र, Vṛtra'), not a name anyone uses.
        if "," in text:
            continue
        owner = taken.get(f)
        out.append({**al, "already_owned_by":
                    owner if owner not in (base.get("slug"),
                                           dup.get("slug")) else None})
    return out


def edge_rank(r: dict) -> tuple[int, int]:
    """Which copy of a duplicated edge to keep: better provenance wins.

    A row citing a real translation beats a Wikidata skeleton, and high
    confidence beats medium.
    """
    srcs = r.get("sources") or [{}]
    wd = all(s.get("source_slug") == "wikidata" for s in srcs)
    return (0 if wd else 1,
            {"high": 2, "medium": 1}.get(r.get("confidence"), 0))


def dedupe_globally(per_file: dict, mapping: dict[str, str]) -> tuple[int, int]:
    """Collapse edges the merge made identical, ACROSS files. In place.

    Deliberately not per-file, which a first version was and which left visible
    duplicates behind: `atri spouse_of anasuya` was authored in
    relations/rishis.jsonl and also imported, as `atri-2 spouse_of anasuya`, into
    relations/wikidata_graph.jsonl. Before the merge those were edges on two
    different entities and not duplicates at all; the merge is precisely what
    makes them the same edge, and it spans two files. Atri's page showed
    "Spouse Anasuya" twice, and Gandiva's showed "Wielded by Arjuna" twice.

    The distinct-partner degree metric was never affected -- that is what makes
    this a display defect rather than a miscount -- but the whole point of the
    merge was to stop showing the reader an artefact of the importer.
    """
    best: dict[tuple, tuple[list, int, dict]] = {}
    drop: list[tuple[list, int]] = []
    loops = 0
    for rows in per_file.values():
        for i, r in enumerate(rows):
            src, dst = r.get("src_slug"), r.get("dst_slug")
            if not (src and dst):
                continue
            if src == dst:
                # Only reachable if a base and its dup were linked to each
                # other, which would contradict them being one figure.
                drop.append((rows, i))
                loops += 1
                continue
            key = (src, r.get("rel_type"), dst)
            prev = best.get(key)
            if prev is None:
                best[key] = (rows, i, r)
            elif edge_rank(r) > edge_rank(prev[2]):
                drop.append((prev[0], prev[1]))
                best[key] = (rows, i, r)
            else:
                drop.append((rows, i))

    # Delete high-index-first so earlier indices stay valid.
    collapsed = len(drop) - loops
    for rows, i in sorted(drop, key=lambda t: -t[1]):
        rows[i] = None
    for rows in per_file.values():
        rows[:] = [r for r in rows if r is not None]
    return collapsed, loops


# --------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    all_rows = {p: read(p) for p in files()}

    # Every title and alias currently claimed, so an alias can be checked
    # against the corpus rather than against a list written here.
    taken: dict[str, str] = {}
    for path, rows in all_rows.items():
        if "entities" not in str(path):
            continue
        for r in rows:
            for v in (r.get("title") or {}).values():
                taken.setdefault(fold(v), r.get("slug"))
            for al in r.get("aliases") or []:
                taken.setdefault(fold(al.get("alias") or ""), r.get("slug"))

    ents = {r["slug"]: r for rows in all_rows.values() for r in rows
            if r.get("slug")}

    missing = [s for s in (*MERGE, *MERGE.values(), *DISAMBIGUATE)
               if s not in ents]
    if missing:
        print(f"decision table names slugs that do not exist: {missing}")
        return 1

    # A merge that would fold an edge onto itself means the two rows are linked
    # to each other, which contradicts them being the same figure.
    mapping = dict(MERGE)
    for old, spec in DISAMBIGUATE.items():
        mapping[old] = spec["slug"]

    print(f"{len(MERGE)} merge(s), {len(DISAMBIGUATE)} row(s) renamed\n")

    # --- aliases are parked, not merged; see alias_candidates()
    parked: dict[str, list[dict]] = {}
    for dup, base in MERGE.items():
        cands = alias_candidates(ents[dup], ents[base], taken)
        if cands:
            parked[f"{dup} -> {base}"] = cands
        print(f"  {dup:<16} -> {base:<14} "
              f"{len(cands)} alias(es) parked for a cited pass"
              + (f": {[c['alias'] for c in cands]}" if cands else ""))

    print()
    for old, spec in DISAMBIGUATE.items():
        print(f"  {old:<16} => {spec['slug']}   {spec['title']['en']}")

    if args.dry_run:
        print("\n--dry-run: nothing written")
        return 0

    park = ROOT / "content" / "staging" / "merged_aliases.json"
    park.parent.mkdir(parents=True, exist_ok=True)
    park.write_text(json.dumps(parked, ensure_ascii=False, indent=1),
                    encoding="utf-8")
    print(f"\nparked aliases -> {park.relative_to(ROOT)}")

    # --- apply
    deleted = repointed = collapsed = loops = 0
    for path, rows in all_rows.items():
        out = []
        # `repoint` mutates the row dicts in place, so the original list holds
        # the SAME objects and `out != rows` is False for a file where only
        # references changed. That silently skipped every relations file on the
        # first run: the counter said 49 references repointed, none of them
        # reached disk, and the gate then reported 49 dangling refs. So track the
        # change explicitly instead of inferring it from a comparison.
        touched = False
        for r in rows:
            slug = r.get("slug")
            if slug in MERGE and "entities" in str(path):
                deleted += 1
                touched = True
                continue                       # the dup entity row itself
            if slug in DISAMBIGUATE and "entities" in str(path):
                spec = DISAMBIGUATE[slug]
                r["slug"] = spec["slug"]
                for k, v in spec.items():
                    if k != "slug":
                        r[k] = v
                touched = True
            n = repoint(r, mapping)
            repointed += n
            touched = touched or n > 0
            out.append(r)
        out, c, l = dedupe_edges(out)
        collapsed += c
        loops += l
        if touched or c or l:
            write(path, out)
    print(f"\ndeleted {deleted} duplicate entity row(s)")
    print(f"repointed {repointed} reference(s)")
    print(f"collapsed {collapsed} edge(s) the merge made identical")
    print(f"dropped {loops} self-loop(s)")

    # Re-read from disk and confirm no old slug survives anywhere. Counting what
    # was repointed in memory is not the same claim as it having been written,
    # which is exactly how the first run reported success on 49 references it
    # never saved.
    stale: dict[str, list[str]] = {}
    for path in files():
        for i, row in enumerate(read(path), 1):
            blob = json.dumps(row, ensure_ascii=False)
            for old in mapping:
                if f'"{old}"' in blob:
                    stale.setdefault(old, []).append(
                        f"{path.relative_to(ROOT)}:{i}")
    if stale:
        print("\nSTALE REFERENCES SURVIVED -- the write did not land:")
        for old, hits in stale.items():
            print(f"  {old:<16} {len(hits)}  {hits[:4]}")
        return 1
    print(f"verified: no reference to any of the {len(mapping)} old slugs "
          f"remains on disk")
    return 0


if __name__ == "__main__":
    sys.exit(main())
