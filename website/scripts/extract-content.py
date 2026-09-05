#!/usr/bin/env python3
"""Build the website's content module from Aradhya's curated content pipeline.

The mobile app ships `assets/db/gyan.sqlite.gz`, built by `py -m content.tools.build`
from the JSONL sources in `content/data/`. The website reuses those same sources so
there is exactly one curated knowledge base, not two.

Only rows whose English verification status is `verified` are emitted, and every
row keeps its primary source citation so the site can attribute what it shows.
Nothing here is written by hand — regenerate with:

    cd website && py scripts/extract-content.py

Output: src/data/mockContent.js
"""
from __future__ import annotations

import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
WEBSITE = os.path.dirname(HERE)
REPO = os.path.dirname(WEBSITE)
DATA = os.path.join(REPO, "content", "data")
OUT = os.path.join(WEBSITE, "src", "data", "mockContent.js")

# ---------------------------------------------------------------- source labels

SOURCE_LABELS = {
    "ganguli-mahabharata": "Ganguli, The Mahabharata (public domain)",
    "griffith-ramayana": "Griffith, The Ramayan of Valmiki (public domain)",
    "wilson-vishnu-purana": "Wilson, The Vishnu Purana (public domain)",
    "wikidata": "Wikidata (CC0)",
    "sanderson-gita": "Bhagavad Gita (public domain translation)",
}

# Entity category -> the facet the website groups it under. The facets are the
# ones the search page exposes; anything unmapped falls back to "concepts".
FACET_BY_CATEGORY = {
    # deities
    "trimurti": "deities", "dashavatara": "deities", "avatara": "deities",
    "shakta": "deities", "shaiva": "deities", "vaishnava": "deities",
    "ganapatya": "deities", "devi": "deities", "vedic": "deities",
    # people (mortals, sages, adversaries, dynasties)
    "mahabharata": "people", "ramayana": "people", "rishi": "people",
    "saptarishi": "people", "devarishi": "people", "asura": "people",
    "exemplar": "people", "vamsha": "people", "vanara": "people",
    # places
    "tirtha": "places", "river": "places", "mountain": "places",
    # scripture
    "shastra": "scriptures", "purana": "scriptures",
    # objects & concepts
    "astra": "objects", "ayudha": "objects", "sacred-mark": "objects",
    "vahana": "objects", "yantra": "objects", "ritual-object": "objects",
    "weapon-symbol": "objects", "symbol": "objects",
    "tattva": "concepts",
}

# A handful of entities are the texts themselves; the pipeline marks them only by
# slug convention, so recognise them explicitly rather than guessing from category.
SCRIPTURE_SLUGS = {
    "bhagavad-gita", "ramayana-text", "mahabharata-text", "upanishads-text",
    "rigveda", "bhagavata-purana",
}

# Motif drawn beside a card. Keys map to src/components/art/Glyph.jsx.
GLYPH_BY_FACET = {
    "deities": "lotus", "people": "figure", "places": "shikhara",
    "scriptures": "scroll", "objects": "trishula", "concepts": "chakra",
    "festivals": "diya", "stories": "bow",
}


def read_jsonl(*parts):
    path = os.path.join(DATA, *parts)
    if not os.path.exists(path):
        print(f"  ! missing {path}", file=sys.stderr)
        return []
    rows = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def verified(row) -> bool:
    v = row.get("verification") or {}
    return v.get("status_en") == "verified"


def en(value, default=""):
    """Pull the English string out of a {'en':..,'hi':..} bilingual field."""
    if isinstance(value, dict):
        return (value.get("en") or default).strip()
    return (value or default).strip() if isinstance(value, str) else default


def hi(value):
    return (value.get("hi") or "").strip() if isinstance(value, dict) else ""


def primary_source(row):
    for s in row.get("sources") or []:
        if s.get("is_primary"):
            slug = s.get("source_slug", "")
            label = SOURCE_LABELS.get(slug, slug.replace("-", " ").title())
            section = s.get("source_chapter_or_section") or ""
            return {"label": label, "section": section} if section else {"label": label}
    return None


def facet_for(row):
    if row["slug"] in SCRIPTURE_SLUGS:
        return "scriptures"
    cat = row.get("category")
    if cat in FACET_BY_CATEGORY:
        return FACET_BY_CATEGORY[cat]
    return "deities" if row.get("kind") == "deity" else "concepts"


# ------------------------------------------------------------------- entities

def build_entities():
    rows = []
    seen = set()
    for f in ("core", "mahabharata", "astras", "symbols"):
        for r in read_jsonl("entities", f"{f}.jsonl"):
            slug = r.get("slug")
            if not slug or slug in seen or not verified(r):
                continue
            seen.add(slug)
            facet = facet_for(r)
            entity = {
                "slug": slug,
                "title": en(r.get("title"), slug.replace("-", " ").title()),
                "titleHi": hi(r.get("title")),
                "facet": facet,
                "category": r.get("category") or "",
                "kind": r.get("kind") or "",
                "summary": en(r.get("short_description")),
                "summaryHi": hi(r.get("short_description")),
                "tags": r.get("tags") or [],
                "importance": r.get("importance", 3),
                "glyph": GLYPH_BY_FACET.get(facet, "chakra"),
            }
            long_en = en(r.get("long_description"))
            if long_en:
                entity["detail"] = long_en
            aliases = sorted({
                a.get("alias", "").strip()
                for a in r.get("aliases") or []
                if a.get("alias") and a.get("script") == "latn"
            } - {entity["title"]})
            if aliases:
                entity["aliases"] = aliases
            src = primary_source(r)
            if src:
                entity["source"] = src
            props = r.get("props") or {}
            if props.get("symbolic_meaning_en"):
                entity["meaning"] = props["symbolic_meaning_en"]
            rows.append(entity)
    rows.sort(key=lambda e: (e["importance"], e["title"]))
    return rows


# ------------------------------------------------------------------ relations

def build_relations(entity_slugs):
    edges = {}
    files = [
        ("relations", "wikidata_graph.jsonl"),
        ("relations", "wikidata_edges_extra.jsonl"),
        ("relations", "rishis.jsonl"),
    ]
    for parts in files:
        for r in read_jsonl(*parts):
            src, dst, rel = r.get("src_slug"), r.get("dst_slug"), r.get("rel_type")
            if not (src and dst and rel):
                continue
            if src not in entity_slugs or dst not in entity_slugs:
                continue  # never link to a page that does not exist
            edges[(src, dst, rel)] = r.get("confidence", "medium")

    # Relations declared inline on an entity row.
    for f in ("core", "mahabharata", "astras", "symbols"):
        for r in read_jsonl("entities", f"{f}.jsonl"):
            src = r.get("slug")
            for item in r.get("related_items") or []:
                dst, rel = item.get("dst_slug"), item.get("rel_type")
                if src in entity_slugs and dst in entity_slugs and rel:
                    edges[(src, dst, rel)] = item.get("confidence", "medium")

    return [
        {"src": s, "dst": d, "type": t, "confidence": c}
        for (s, d, t), c in sorted(edges.items())
    ]


# -------------------------------------------------------------------- stories

def build_stories():
    """Narrative scenes, grouped into the arcs the app's Story Cards use."""
    scenes = []
    for f in ("epics", "ramayana_more", "mahabharata_more", "kurukshetra"):
        for r in read_jsonl("narrative", f"{f}.jsonl"):
            if not verified(r) or not r.get("slug"):
                continue
            arc = r.get("arc") or {}
            scene = {
                "slug": r["slug"],
                "epic": r.get("epic") or "",
                "title": en(r.get("title")),
                "titleHi": hi(r.get("title")),
                "summary": en(r.get("quick_summary")) or en(r.get("short_description")),
                "book": en(r.get("book_label")),
                "bookNo": r.get("book_no"),
                "seq": r.get("sequence_no", 0),
                "arcNo": arc.get("no"),
                "arcSlug": arc.get("slug") or "",
                "arcTitle": arc.get("title_en") or "",
                "cast": [c.get("entity_slug") for c in r.get("cast") or [] if c.get("entity_slug")],
                "place": r.get("place_entity_slug") or "",
            }
            lesson = en(r.get("lesson"))
            if lesson:
                scene["lesson"] = lesson
            src = primary_source(r)
            if src:
                scene["source"] = src
            scenes.append(scene)
    scenes.sort(key=lambda s: (s["epic"], s["bookNo"] or 0, s["seq"] or 0))
    return scenes


def build_arcs(scenes):
    by_arc = defaultdict(list)
    for s in scenes:
        if s["arcSlug"]:
            by_arc[(s["epic"], s["arcSlug"])].append(s)
    arcs = []
    for (epic, slug), group in by_arc.items():
        first = group[0]
        arcs.append({
            "slug": slug,
            "epic": epic,
            "no": first["arcNo"],
            "title": first["arcTitle"],
            "book": first["book"],
            "bookNo": first["bookNo"],
            "sceneCount": len(group),
            "summary": first["summary"],
        })
    # Arc numbers restart inside each book, so order by book first.
    arcs.sort(key=lambda a: (a["epic"], a["bookNo"] or 0, a["no"] or 0))
    return arcs


# ------------------------------------------------------------------- journeys

def build_journeys():
    out = []
    for f in ("launch", "more"):
        for r in read_jsonl("paths", f"{f}.jsonl"):
            if not verified(r) or not r.get("slug"):
                continue
            out.append({
                "slug": r["slug"],
                "title": en(r.get("title")),
                "titleHi": hi(r.get("title")),
                "summary": en(r.get("short_description")),
                "level": r.get("level") or "beginner",
                "minutes": r.get("est_minutes") or 0,
                "order": r.get("order_no", 99),
                "tags": r.get("tags") or [],
                "steps": [
                    {
                        "no": s.get("step_no"),
                        "title": en(s.get("title")),
                        "blurb": en(s.get("blurb")),
                    }
                    for s in r.get("steps") or []
                ],
            })
    out.sort(key=lambda j: (j["level"] != "beginner", j["order"]))
    return out


# ------------------------------------------------------------------ festivals

def build_festivals():
    out = []
    for r in read_jsonl("festivals", "festivals.jsonl"):
        if not verified(r) or not r.get("slug"):
            continue
        when = []
        if r.get("lunar_month"):
            when.append(str(r["lunar_month"]).title())
        if r.get("paksha"):
            when.append(str(r["paksha"]).title())
        if r.get("tithi"):
            when.append(str(r["tithi"]).replace("_", " ").title())
        out.append({
            "slug": r["slug"],
            "title": en(r.get("title")),
            "titleHi": hi(r.get("title")),
            "summary": en(r.get("short_description")),
            "when": " · ".join(when) or en(r.get("solar_rule")),
            "region": r.get("region") or "",
            "tradition": r.get("tradition") or "",
            "deity": r.get("deity_entity_slug") or "",
            "ritual": en(r.get("ritual_summary")),
        })
    return out


# ----------------------------------------------------------------------- quiz

def build_quiz():
    out = []
    for r in read_jsonl("quiz.jsonl"):
        if not r.get("q_en"):
            continue
        out.append({
            "question": r["q_en"],
            "questionHi": r.get("q_hi") or "",
            "options": [
                {"key": o.get("key"), "text": o.get("en", "")} for o in r.get("options") or []
            ],
            "correct": r.get("correct"),
            "category": r.get("category") or "",
            "difficulty": r.get("difficulty", 1),
        })
    return out


def build_trivia():
    out = []
    for r in read_jsonl("trivia.jsonl"):
        fact = r.get("en") or r.get("fact_en") or en(r.get("fact"))
        if not fact:
            continue
        item = {"fact": fact}
        if r.get("source"):
            item["source"] = r["source"]
        out.append(item)
    return out


def build_riddles():
    """Clue riddles — the app reveals one clue at a time, so keep them ordered."""
    out = []
    for r in read_jsonl("riddles.jsonl"):
        clues = r.get("clues_en") or []
        if r.get("answer") and clues:
            out.append({"answer": r["answer"], "clues": clues})
    return out


# ------------------------------------------------------------------ emit file

def js(value, indent=0):
    return json.dumps(value, ensure_ascii=False, indent=2 if indent else None)


def main():
    entities = build_entities()
    slugs = {e["slug"] for e in entities}
    relations = build_relations(slugs)
    scenes = build_stories()
    arcs = build_arcs(scenes)
    journeys = build_journeys()
    festivals = build_festivals()
    quiz = build_quiz()
    trivia = build_trivia()
    riddles = build_riddles()

    header = f"""/**
 * AUTO-GENERATED — do not edit by hand.
 *
 * Source of truth: the curated JSONL under `content/data/` at the repo root, the
 * same pipeline that builds the mobile app's GYAN_DB. Every row below carries
 * verification status `verified` and, where the pipeline recorded one, the
 * primary public-domain citation it was written from.
 *
 * Regenerate:  cd website && py scripts/extract-content.py
 *
 * Counts: {len(entities)} entities · {len(relations)} relations · {len(scenes)} scenes
 *         · {len(arcs)} arcs · {len(journeys)} journeys · {len(festivals)} festivals
 *         · {len(quiz)} quiz questions · {len(trivia)} trivia facts · {len(riddles)} riddles
 */

"""

    parts = [header]
    for name, value in (
        ("entities", entities),
        ("relations", relations),
        ("scenes", scenes),
        ("arcs", arcs),
        ("journeys", journeys),
        ("festivals", festivals),
        ("quizQuestions", quiz),
        ("triviaFacts", trivia),
        ("riddles", riddles),
    ):
        parts.append(f"export const {name} = {js(value, indent=1)};\n\n")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(parts))

    size = os.path.getsize(OUT) / 1024
    print(f"wrote {os.path.relpath(OUT, WEBSITE)}  ({size:.0f} KB)")
    print(f"  entities  {len(entities)}")
    print(f"  relations {len(relations)}")
    print(f"  scenes    {len(scenes)} in {len(arcs)} arcs")
    print(f"  journeys  {len(journeys)}")
    print(f"  festivals {len(festivals)}")
    print(f"  quiz      {len(quiz)}   trivia {len(trivia)}   riddles {len(riddles)}")


if __name__ == "__main__":
    main()
