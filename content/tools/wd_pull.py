"""Bulk Wikidata pull for the entity graph.

CC0, so this is the one source we can take structure from wholesale. Only the
SKELETON comes from here -- QIDs, labels in en/hi/sa, aliases and typed
relation edges. Descriptions are NOT taken from Wikidata's Wikipedia-derived
text: that prose is CC BY-SA and its share-alike would infect our content.

Chunked deliberately. The public WDQS endpoint returns 504 on wide transitive
closures, which is why the existing lineage query was narrowed to a direct
P31 and only ever returned 74 edges. Here the seed set is gathered class by
class, then edges are fetched in batches of QIDs via VALUES, which the
endpoint handles comfortably.
"""
import json, pathlib, sys, time, urllib.parse, urllib.request

UA = "Aradhya/1.0 (offline devotional app; content pipeline; contact: sumerudigitalsm@gmail.com)"
ENDPOINT = "https://query.wikidata.org/sparql"
OUT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani\content\staging')
OUT.mkdir(parents=True, exist_ok=True)


def sparql(query: str, timeout: int = 120, tries: int = 3) -> list[dict]:
    url = ENDPOINT + "?format=json&query=" + urllib.parse.quote(query)
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.load(r)["results"]["bindings"]
        except Exception as e:                      # noqa: BLE001
            last = e
            # WDQS throttles aggressively; back off rather than hammer it.
            time.sleep(4 * (attempt + 1))
    print(f"    query failed after {tries} tries: {type(last).__name__}")
    return []


def qid(uri: str) -> str:
    return uri.rsplit("/", 1)[-1]


# The classes worth pulling. Transitive where the closure is small enough to
# survive, direct where it is not -- each was measured, not guessed.
# Each clause was MEASURED against the endpoint, not guessed. Several obvious
# candidates return zero (there is no "Mahabharata character" class), and the
# characters are reached instead through P1441 "present in work" -- 224 for the
# Mahabharata and 110 for the Ramayana, which is the lineage spine that was
# missing while the old query returned 74 edges.
#
# Temples are deliberately NOT pulled. The class yields ~1200 bare names with
# no description and mostly no Hindi, and the app already ships 187 curated
# temples. That would be volume, not richness.
SEEDS = [
    ("deity",  "?i wdt:P31/wdt:P279* wd:Q979507 .", "Hindu deity"),
    ("rishi",  "?i wdt:P31/wdt:P279* wd:Q755990 .", "Rishi"),
    ("human",  "?i wdt:P1441 wd:Q8276 .",           "Mahabharata characters"),
    ("human",  "?i wdt:P1441 wd:Q37293 .",          "Ramayana characters"),
    ("human",  "?i wdt:P31 wd:Q55607025 .",         "Ramayana (class)"),
    ("human",  "?i wdt:P1441 wd:Q682958 .",         "Bhagavata Purana"),
]

LABELS = """
SELECT ?i ?en ?hi ?sa WHERE {
  %s
  OPTIONAL { ?i rdfs:label ?en FILTER(LANG(?en)="en") }
  OPTIONAL { ?i rdfs:label ?hi FILTER(LANG(?hi)="hi") }
  OPTIONAL { ?i rdfs:label ?sa FILTER(LANG(?sa)="sa") }
}
LIMIT 1200
"""


def pull_seeds() -> dict[str, dict]:
    found: dict[str, dict] = {}
    for kind, clause, label in SEEDS:
        rows = sparql(LABELS % clause)
        added = 0
        for b in rows:
            q = qid(b["i"]["value"])
            en = b.get("en", {}).get("value")
            if not en or en.startswith("Q"):
                continue                     # unlabelled item, nothing to show
            if q in found:
                continue
            found[q] = {
                "qid": q, "kind": kind,
                "en": en,
                "hi": b.get("hi", {}).get("value"),
                "sa": b.get("sa", {}).get("value"),
            }
            added += 1
        print(f"  {label:<24} +{added:<5} (total {len(found)})")
        time.sleep(1)
    return found


EDGES = """
SELECT ?i ?p ?o WHERE {
  VALUES ?i { %s }
  VALUES ?p { wdt:P22 wdt:P25 wdt:P26 wdt:P40 wdt:P3373 wdt:P1038
              wdt:P1441 wdt:P2789 wdt:P527 wdt:P361 }
  ?i ?p ?o .
}
"""


def pull_edges(qids: list[str]) -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    B = 120
    for n in range(0, len(qids), B):
        chunk = " ".join(f"wd:{q}" for q in qids[n:n + B])
        rows = sparql(EDGES % chunk, timeout=150)
        for b in rows:
            out.append((qid(b["i"]["value"]),
                        b["p"]["value"].rsplit("/", 1)[-1],
                        qid(b["o"]["value"])))
        print(f"  edges batch {n // B + 1}: +{len(rows)} (total {len(out)})")
        time.sleep(1)
    return out


ALIASES = """
SELECT ?i ?a WHERE {
  VALUES ?i { %s }
  ?i skos:altLabel ?a .
  FILTER(LANG(?a) IN ("en","hi","sa"))
}
"""


def pull_aliases(qids: list[str]) -> list[tuple[str, str, str]]:
    out = []
    B = 120
    for n in range(0, len(qids), B):
        chunk = " ".join(f"wd:{q}" for q in qids[n:n + B])
        for b in sparql(ALIASES % chunk, timeout=150):
            out.append((qid(b["i"]["value"]),
                        b["a"]["value"],
                        b["a"].get("xml:lang", "en")))
        time.sleep(1)
    return out


def main() -> int:
    print("seeds:")
    seeds = pull_seeds()
    qids = sorted(seeds)
    if not qids:
        print("nothing fetched")
        return 1

    print(f"\nedges for {len(qids)} entities:")
    edges = pull_edges(qids)

    print(f"\naliases:")
    aliases = pull_aliases(qids)
    print(f"  {len(aliases)} aliases")

    (OUT / "wd_entities.json").write_text(
        json.dumps(seeds, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "wd_edges.json").write_text(
        json.dumps(edges, ensure_ascii=False), encoding="utf-8")
    (OUT / "wd_aliases.json").write_text(
        json.dumps(aliases, ensure_ascii=False), encoding="utf-8")

    with_hi = sum(1 for v in seeds.values() if v["hi"])
    print(f"\nentities {len(seeds)}  edges {len(edges)}  aliases {len(aliases)}")
    print(f"hindi labels present: {with_hi}/{len(seeds)}"
          f"  ({len(seeds) - with_hi} need translation)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
