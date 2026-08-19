"""Compare the database about to ship against the one that shipped last.

This exists because content has already vanished silently once. A promote run
done to add a single entity regenerated core.jsonl and wiped prose that had
been written into it -- 22 of 27 enriched entities lost their descriptions.
The build was green, validate was clean, and nothing anywhere said a word.

Counts alone are not enough: a build that adds 30 entities and drops 22
descriptions still looks like growth. So this tracks each measure separately
and fails on ANY unexplained decrease, not on the total.

Usage
    py -m content.tools.content_diff --snapshot     after a build you trust
    py -m content.tools.content_diff                compare current vs snapshot
    py -m content.tools.content_diff --allow-loss   record an intended removal

Exit codes
    0  no losses, or losses explicitly allowed
    1  something disappeared
"""
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import GYAN_DB, LEGACY_DB  # noqa: E402

SNAPSHOT = Path(__file__).resolve().parents[1] / "build" / "content_snapshot.json"

# Every measure worth guarding. Prose and Hindi coverage are listed separately
# from row counts on purpose: losing a description while gaining a row is the
# exact shape of the failure this tool was written for.
MEASURES: dict[str, str] = {
    "entities": "select count(*) from entities",
    "entities_verified":
        "select count(*) from entities where verification_status='verified'",
    "entities_with_prose":
        "select count(*) from entities where long_description_en is not null",
    "entities_hindi":
        "select count(*) from entities where title_hi is not null and title_hi<>''",
    "relations": "select count(*) from relations",
    "aliases": "select count(*) from entity_aliases",
    "narrative_nodes": "select count(*) from narrative_nodes",
    "narrative_with_prose":
        "select count(*) from narrative_nodes where long_description_en is not null",
    "cosmology_nodes": "select count(*) from cosmology_nodes",
    "cosmology_with_prose":
        "select count(*) from cosmology_nodes where long_description_en is not null",
    "festivals": "select count(*) from festivals",
    "dharma_scenarios": "select count(*) from dharma_scenarios",
    "dharma_choices": "select count(*) from dharma_choices",
    "vidya_topics": "select count(*) from vidya_topics",
    "qa_pairs": "select count(*) from qa_pairs",
    "learning_paths": "select count(*) from learning_paths",
    "path_steps": "select count(*) from path_steps",
    "journal_prompts": "select count(*) from journal_prompts",
    "sources": "select count(*) from sources",
    "item_sources": "select count(*) from item_sources",
    "search_docs": "select count(*) from search_docs",
    "related_edges": "select count(*) from related_edges",
}


def measure(db_path: Path) -> dict[str, int]:
    if not db_path.exists():
        return {}
    db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    out: dict[str, int] = {}
    try:
        for name, sql in MEASURES.items():
            try:
                out[name] = db.execute(sql).fetchone()[0]
            except sqlite3.Error:
                # A table that does not exist yet is not a loss.
                out[name] = 0
    finally:
        db.close()
    return out


def slug_sets(db_path: Path) -> dict[str, set[str]]:
    """Which slugs exist, so a diff can name what went missing.

    A count says "three fewer entities". This says which three -- the
    difference between a warning somebody ignores and one they act on.
    """
    if not db_path.exists():
        return {}
    db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    out: dict[str, set[str]] = {}
    try:
        for table in ("entities", "narrative_nodes", "cosmology_nodes",
                      "festivals", "vidya_topics", "dharma_scenarios",
                      "learning_paths"):
            try:
                out[table] = {r[0] for r in db.execute(f"select slug from {table}")}
            except sqlite3.Error:
                out[table] = set()
    finally:
        db.close()
    return out


def load_snapshot() -> dict | None:
    if not SNAPSHOT.exists():
        return None
    return json.loads(SNAPSHOT.read_text(encoding="utf-8"))


def save_snapshot(counts: dict[str, int], slugs: dict[str, set[str]]) -> None:
    SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    SNAPSHOT.write_text(
        json.dumps(
            {
                "counts": counts,
                "slugs": {k: sorted(v) for k, v in slugs.items()},
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--snapshot", action="store_true",
                    help="record the current build as the baseline")
    ap.add_argument("--allow-loss", action="store_true",
                    help="accept the losses and move the baseline forward")
    args = ap.parse_args(argv)

    counts = measure(GYAN_DB)
    slugs = slug_sets(GYAN_DB)
    if not counts:
        print(f"no database at {GYAN_DB}")
        return 1

    if args.snapshot:
        save_snapshot(counts, slugs)
        print(f"snapshot written: {sum(counts.values())} rows across "
              f"{len(counts)} measures")
        return 0

    prior = load_snapshot()
    if prior is None:
        save_snapshot(counts, slugs)
        print("no prior snapshot -- current build recorded as the baseline")
        return 0

    old_counts: dict[str, int] = prior.get("counts", {})
    old_slugs: dict[str, list] = prior.get("slugs", {})

    gains, losses = [], []
    for name, now in counts.items():
        was = old_counts.get(name, 0)
        if now > was:
            gains.append((name, was, now))
        elif now < was:
            losses.append((name, was, now))

    if gains:
        print("gained")
        for name, was, now in gains:
            print(f"  +{now - was:<5} {name:<24} {was} -> {now}")

    if not losses:
        print("\nnothing lost.")
        save_snapshot(counts, slugs)
        return 0

    print("\nLOST")
    for name, was, now in losses:
        print(f"  -{was - now:<5} {name:<24} {was} -> {now}")

    # Name the missing rows where we can. This is what turns the report from a
    # number into something actionable.
    for table, before in old_slugs.items():
        gone = sorted(set(before) - slugs.get(table, set()))
        if gone:
            shown = ", ".join(gone[:12])
            more = f" (+{len(gone) - 12} more)" if len(gone) > 12 else ""
            print(f"\n  {table}: {len(gone)} slug(s) gone")
            print(f"    {shown}{more}")

    if args.allow_loss:
        save_snapshot(counts, slugs)
        print("\n--allow-loss: baseline moved forward.")
        return 0

    print("\nBUILD SHOULD NOT SHIP.")
    print("Content disappeared without being removed on purpose. Either restore")
    print("it, or re-run with --allow-loss if the removal was intended.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
