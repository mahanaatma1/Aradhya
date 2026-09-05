"""Stage 5 — the content health dashboard.

    py -m content.tools.report [--open]

Writes content/build/report.html and prints a summary table.

Division of labour:
    validate.py  says STOP      -- something is wrong and must be fixed
    report.py    says WHAT NEXT -- coverage gaps, ranked, with line numbers

This is the artefact that keeps a growing corpus honest. Once there are
thousands of rows, "which entities still have no Hindi?" and "which aliases are
claimed by two different deities?" stop being answerable by reading files.
"""

from __future__ import annotations

import argparse
import html
import sqlite3
import sys
import webbrowser
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools import validate  # noqa: E402
from content.tools.common import BUILD_DIR, GYAN_DB, REPO_ROOT  # noqa: E402


# KG-03 and KG-04, as the plan states them: every P0 entity should carry at
# least 3 relations, and at least 80% of P1 entities at least 2.
#
# The tier is `importance` (1 major .. 5 minor), which is what P0/P1 mean
# everywhere else in the corpus: P0 is importance 1-2, P1 is importance 3.
#
# Degree is the row count in `relations` keyed on src_id, and that is the FULL
# degree rather than half of it: build.py materialises the inverse of every
# authored edge (build.py:289), so an entity that is only ever a destination in
# the source JSONL still has its own outbound row. Counting both src_id and
# dst_id here would double every relation.
#
# This lives in the report rather than in a notebook because it was previously
# computed by hand, and the hand-written query used the threshold one BELOW the
# one the goal states -- `>= 2` where the goal said 3, `>= 1` where it said 2.
# That reported KG-04 at 63% against an 80% target, i.e. nearly met, when the
# real figure for "2 or more" was 37%. A metric worth a target is worth a query
# that runs on every report.
KG_TIERS: tuple[tuple[str, tuple[int, ...], int, float], ...] = (
    ("P0", (1, 2), 3, 1.00),
    ("P1", (3,), 2, 0.80),
)


def kg_coverage(db: sqlite3.Connection) -> list[dict]:
    """Relation-count coverage per importance tier."""
    degree = dict(db.execute(
        "select src_id, count(*) from relations group by src_id"))

    out: list[dict] = []
    for name, importances, need, target in KG_TIERS:
        marks = ",".join("?" * len(importances))
        rows = list(db.execute(
            f"select id, slug, kind from entities where importance in ({marks})"
            " order by kind, slug", importances))
        total = len(rows)
        met = [r for r in rows if degree.get(r[0], 0) >= need]
        short = [r for r in rows if degree.get(r[0], 0) < need]

        by_kind: dict[str, int] = defaultdict(int)
        for _id, _slug, kind in short:
            by_kind[kind] += 1

        out.append({
            "tier": name,
            "need": need,
            "target": target,
            "total": total,
            "met": len(met),
            "pct": (len(met) / total) if total else 0.0,
            "zero": sum(1 for r in rows if degree.get(r[0], 0) == 0),
            "short_by_kind": dict(sorted(
                by_kind.items(), key=lambda kv: -kv[1])),
            # Named, so the gap is a work list rather than a number.
            "short": [(slug, kind, degree.get(i, 0))
                      for i, slug, kind in short],
        })
    return out


def db_stats() -> dict:
    """Per-table coverage, straight from the built database."""
    if not GYAN_DB.exists():
        return {}
    db = sqlite3.connect(f"file:{GYAN_DB}?mode=ro", uri=True)
    try:
        tables = [
            "entities", "relations", "entity_aliases", "cosmology_nodes",
            "narrative_nodes", "dharma_scenarios", "vidya_topics", "festivals",
            "qa_pairs", "journal_prompts", "learning_paths", "path_steps",
            "search_docs", "related_edges", "sources", "item_sources",
        ]
        have = {r[0] for r in db.execute(
            "select name from sqlite_master where type='table'")}

        out: dict = {"tables": {}, "meta": {}}
        for t in tables:
            if t not in have:
                continue
            row: dict = {"total": db.execute(f"select count(*) from {t}").fetchone()[0]}
            cols = {c[1] for c in db.execute(f"pragma table_info({t})")}

            if "verification_status" in cols:
                for status in ("verified", "unverified", "disputed"):
                    row[status] = db.execute(
                        f"select count(*) from {t} where verification_status=?",
                        (status,)).fetchone()[0]
            if "title_hi" in cols:
                row["missing_hi"] = db.execute(
                    f"select count(*) from {t} "
                    f"where title_hi is null or trim(title_hi)=''").fetchone()[0]
            if "short_description_hi" in cols:
                row["missing_hi_desc"] = db.execute(
                    f"select count(*) from {t} where short_description_hi is null "
                    f"or trim(short_description_hi)=''").fetchone()[0]
            if "long_description_en" in cols:
                row["missing_long"] = db.execute(
                    f"select count(*) from {t} where long_description_en is null "
                    f"or trim(long_description_en)=''").fetchone()[0]
            if "primary_source_name" in cols:
                row["no_citation"] = db.execute(
                    f"select count(*) from {t} "
                    f"where primary_source_name is null").fetchone()[0]
            if "image_asset" in cols:
                row["no_image"] = db.execute(
                    f"select count(*) from {t} where image_asset is null "
                    f"or trim(image_asset)=''").fetchone()[0]
            out["tables"][t] = row

        out["meta"] = dict(db.execute("select key, value from meta"))

        # Entities with no outbound related edges: usually a sign their aliases
        # are wrong, since almost every real figure links to something.
        out["orphan_entities"] = [
            r[0] for r in db.execute(
                """select e.slug from entities e
                   where not exists (
                     select 1 from related_edges r
                     where r.src_src='gyan' and r.src_table='entities'
                       and r.src_id=e.id)
                   order by e.importance limit 40""")]

        # An epithet claimed by two entities will mis-wire the related rail.
        out["dup_aliases"] = [
            (r[0], r[1]) for r in db.execute(
                """select a.alias_fold, group_concat(distinct e.slug)
                   from entity_aliases a join entities e on e.id=a.entity_id
                   where a.alias_kind in ('primary','epithet')
                   group by a.alias_fold
                   having count(distinct e.id) > 1
                   limit 40""")]

        out["kg_coverage"] = kg_coverage(db)

        out["search_by_kind"] = dict(db.execute(
            "select kind, count(*) from search_docs group by kind order by 2 desc"))
        out["edges_by_reason"] = dict(db.execute(
            """select substr(reason,1,instr(reason||':',':')-1), count(*)
               from related_edges group by 1 order by 2 desc limit 12"""))
        return out
    finally:
        db.close()


def render_html(rep: validate.Report, stats: dict) -> str:
    def esc(s) -> str:
        return html.escape(str(s))

    by_code: dict[str, list] = defaultdict(list)
    for f in rep.findings:
        by_code[f.code].append(f)

    parts: list[str] = []
    a = parts.append

    a("<!doctype html><meta charset='utf-8'>")
    a("<title>Aradhya — content health</title>")
    a("""<style>
      :root{--paper:#FDF8F5;--ink:#3A2214;--soft:#6F4C37;--terra:#A73015;
            --gold:#B48B3E;--green:#25533F;--amber:#FF9F43;--line:#E7D9CC}
      *{box-sizing:border-box}
      body{margin:0;padding:28px;background:var(--paper);color:var(--ink);
           font:15px/1.5 -apple-system,Segoe UI,Roboto,sans-serif}
      h1{font-size:26px;margin:0 0 4px}
      h2{font-size:17px;margin:30px 0 10px;color:var(--soft)}
      .sub{color:var(--soft);font-size:13px;margin-bottom:20px}
      table{border-collapse:collapse;width:100%;background:#fff;
            border:1px solid var(--line);border-radius:10px;overflow:hidden}
      th,td{padding:8px 11px;text-align:left;border-bottom:1px solid var(--line);
            font-size:13px}
      th{background:#F7ECDC;font-weight:700}
      tr:last-child td{border-bottom:none}
      td.n{text-align:right;font-variant-numeric:tabular-nums}
      .ok{color:var(--green);font-weight:700}
      .warn{color:#9A5B00;font-weight:700}
      .bad{color:var(--terra);font-weight:700}
      .pill{display:inline-block;padding:2px 9px;border-radius:99px;font-size:11px;
            font-weight:700}
      .pill.err{background:#fbe3de;color:var(--terra)}
      .pill.wrn{background:#fdf0dc;color:#9A5B00}
      code{background:#F1E7DC;padding:1px 5px;border-radius:4px;font-size:12px}
      .empty{color:var(--soft);font-style:italic;padding:10px 0}
      .bar{height:7px;background:#EFE2D6;border-radius:99px;overflow:hidden;
           min-width:90px}
      .bar>i{display:block;height:100%;background:var(--green)}
    </style>""")

    meta = stats.get("meta", {})
    a(f"<h1>Aradhya — content health</h1>")
    a(f"<div class='sub'>{esc(meta.get('content_version','(not built)'))} · "
      f"profile <b>{esc(meta.get('build_profile','?'))}</b> · "
      f"generated {datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC</div>")

    # ---- gate ----
    a("<h2>Validation</h2>")
    if not rep.findings:
        a("<div class='ok'>No errors, no warnings.</div>")
    else:
        a("<table><tr><th>Code</th><th>Severity</th><th class='n'>Count</th>"
          "<th>First occurrence</th></tr>")
        for code, items in sorted(by_code.items(),
                                  key=lambda kv: (kv[1][0].severity != "error",
                                                  -len(kv[1]))):
            sev = items[0].severity
            cls = "err" if sev == "error" else "wrn"
            a(f"<tr><td><code>{esc(code)}</code></td>"
              f"<td><span class='pill {cls}'>{esc(sev)}</span></td>"
              f"<td class='n'>{len(items)}</td>"
              f"<td>{esc(items[0].location())}<br>"
              f"<span style='color:#6F4C37;font-size:12px'>"
              f"{esc(items[0].message)}</span></td></tr>")
        a("</table>")

    # ---- coverage ----
    a("<h2>Coverage by table</h2>")
    tables = stats.get("tables", {})
    if not tables:
        a("<div class='empty'>gyan.sqlite not built yet.</div>")
    else:
        a("<table><tr><th>Table</th><th class='n'>Rows</th><th class='n'>Verified</th>"
          "<th>Progress</th><th class='n'>No Hindi</th><th class='n'>No citation</th>"
          "<th class='n'>No image</th></tr>")
        for name, row in tables.items():
            total = row["total"]
            verified = row.get("verified")
            pct = 0 if not total or verified is None else round(100 * verified / total)
            bar = (f"<div class='bar'><i style='width:{pct}%'></i></div>"
                   if verified is not None else "&mdash;")
            def cell(key):
                v = row.get(key)
                if v is None:
                    return "<td class='n'>&mdash;</td>"
                cls = "ok" if v == 0 else ("warn" if v < total else "bad")
                return f"<td class='n {cls}'>{v}</td>"
            a(f"<tr><td><code>{esc(name)}</code></td>"
              f"<td class='n'>{total}</td>"
              f"<td class='n'>{'&mdash;' if verified is None else verified}</td>"
              f"<td>{bar}</td>"
              f"{cell('missing_hi')}{cell('no_citation')}{cell('no_image')}</tr>")
        a("</table>")

    # ---- defects ----
    dups = stats.get("dup_aliases") or []
    a("<h2>Duplicate epithets "
      "<span style='font-weight:400;font-size:13px;color:#6F4C37'>"
      "(these mis-wire the related rail — Risk 8)</span></h2>")
    if not dups:
        a("<div class='ok'>None.</div>")
    else:
        a("<table><tr><th>Folded alias</th><th>Claimed by</th></tr>")
        for fold_val, slugs in dups:
            a(f"<tr><td><code>{esc(fold_val)}</code></td><td>{esc(slugs)}</td></tr>")
        a("</table>")

    orphans = stats.get("orphan_entities") or []
    a("<h2>Entities with no related edges</h2>")
    if not orphans:
        a("<div class='ok'>None.</div>")
    else:
        a("<div class='sub'>Usually means the aliases are wrong — almost every "
          "real figure links to something.</div>")
        a("<div>" + " ".join(f"<code>{esc(s)}</code>" for s in orphans) + "</div>")

    # ---- knowledge graph coverage ----
    kg = stats.get("kg_coverage") or []
    if kg:
        a("<h2>Relation coverage "
          "<span style='font-weight:400;font-size:13px;color:#6F4C37'>"
          "(KG-03, KG-04)</span></h2>")
        a("<table><tr><th>Tier</th><th>Goal</th><th class='n'>Met</th>"
          "<th class='n'>Of</th><th class='n'>Coverage</th>"
          "<th class='n'>No relations at all</th></tr>")
        for t in kg:
            hit = t["pct"] >= t["target"]
            cls = "ok" if hit else "bad"
            a(f"<tr><td>{esc(t['tier'])}</td>"
              f"<td>{t['need']} or more, on {t['target']:.0%}</td>"
              f"<td class='n'>{t['met']}</td>"
              f"<td class='n'>{t['total']}</td>"
              f"<td class='n {cls}'>{t['pct']:.0%}</td>"
              f"<td class='n'>{t['zero']}</td></tr>")
        a("</table>")
        for t in kg:
            if not t["short_by_kind"]:
                continue
            gaps = " · ".join(f"{esc(k)} {n}"
                              for k, n in t["short_by_kind"].items())
            a(f"<div class='sub'>{esc(t['tier'])} short of "
              f"{t['need']}: {gaps}</div>")

    # ---- derived ----
    a("<h2>Search index</h2>")
    kinds = stats.get("search_by_kind") or {}
    if kinds:
        a("<table><tr><th>Kind</th><th class='n'>Documents</th></tr>")
        for k, n in kinds.items():
            a(f"<tr><td>{esc(k)}</td><td class='n'>{n}</td></tr>")
        a("</table>")

    a("<h2>Related edges by rule</h2>")
    reasons = stats.get("edges_by_reason") or {}
    if reasons:
        a("<table><tr><th>Rule</th><th class='n'>Edges</th></tr>")
        for k, n in reasons.items():
            a(f"<tr><td>{esc(k or '(none)')}</td><td class='n'>{n}</td></tr>")
        a("</table>")

    return "\n".join(parts)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Content health dashboard.")
    ap.add_argument("--open", action="store_true",
                    help="open the report in a browser when done")
    ap.add_argument("--strict", action="store_true",
                    help="evaluate against release rules")
    args = ap.parse_args(argv)

    rep = validate.run(strict=args.strict)
    stats = db_stats()

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    out = BUILD_DIR / "report.html"
    out.write_text(render_html(rep, stats), encoding="utf-8")

    print(f"{'MODULE':<20}{'ROWS':>7}{'VERIFIED':>10}{'NO HINDI':>10}"
          f"{'NO CITATION':>13}")
    print("-" * 60)
    for name, row in (stats.get("tables") or {}).items():
        if row["total"] == 0:
            continue
        print(f"{name:<20}{row['total']:>7}"
              f"{row.get('verified', '-'):>10}"
              f"{row.get('missing_hi', '-'):>10}"
              f"{row.get('no_citation', '-'):>13}")

    dups = len(stats.get("dup_aliases") or [])
    orphans = len(stats.get("orphan_entities") or [])
    print("-" * 60)
    for t in stats.get("kg_coverage") or []:
        flag = "ok " if t["pct"] >= t["target"] else "GAP"
        print(f"{flag} {t['tier']}: {t['met']}/{t['total']} ({t['pct']:.0%}) "
              f"have {t['need']}+ relations · target {t['target']:.0%} · "
              f"{t['zero']} have none")
    print(f"errors {len(rep.errors)} · warnings {len(rep.warnings)} · "
          f"duplicate epithets {dups} · unlinked entities {orphans}")
    print(f"wrote {out.relative_to(REPO_ROOT)}")

    if args.open:
        webbrowser.open(out.as_uri())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
