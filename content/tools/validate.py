"""Stage 3 — the gate.

    py -m content.tools.validate [--strict]

Exits non-zero on any ERROR. `--strict` additionally promotes the bilingual
and verification warnings to errors, which is what a release build uses.

The division of labour matters:
    validate.py  says STOP      -- something is wrong and must be fixed
    report.py    says WHAT NEXT -- coverage gaps, ranked

Findings are returned as data (not printed inline) so report.py can reuse the
whole check suite without shelling out.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sqlite3
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import (  # noqa: E402
    ASSETS_DB_DIR, CONTENT_DIR, DATA_DIR, GYAN_DB, KINDS_DIR, LEGACY_DB,
    RAW_DIR, REPO_ROOT, SOURCES_DIR, excluded_domains, fold, read_jsonl,
    registry_slugs,
)

CURATION_DIR = CONTENT_DIR / "curation"

# ---------------------------------------------------------------------------
# Module map: data subdir -> (json schema id, gyan table)
# ---------------------------------------------------------------------------

MODULES: dict[str, tuple[str, str]] = {
    "entities":   ("entity",           "entities"),
    "relations":  ("relation",         "relations"),
    "cosmology":  ("cosmology_node",   "cosmology_nodes"),
    "narrative":  ("narrative_node",   "narrative_nodes"),
    "dharma":     ("dharma_scenario",  "dharma_scenarios"),
    "vidya":      ("vidya_topic",      "vidya_topics"),
    "festivals":  ("festival",         "festivals"),
    "ask":        ("qa_pair",          "qa_pairs"),
    "journal":    ("journal_prompt",   "journal_prompts"),
    "paths":      ("learning_path",    "learning_paths"),
}

# Legacy JSONL that predates this pipeline and feeds the OLD content build.
# Not validated against the gyan schemas -- deliberately skipped, not forgotten.
LEGACY_DATA_FILES = {"quiz.jsonl", "riddles.jsonl", "trivia.jsonl"}

# Relation vocabulary lives here (not a SQL CHECK) so it can grow without a
# schema migration. build.py materialises the inverse of each pair.
REL_INVERSE: dict[str, str] = {
    "father_of": "child_of", "mother_of": "child_of", "child_of": "parent_of",
    "spouse_of": "spouse_of", "sibling_of": "sibling_of",
    "guru_of": "disciple_of", "disciple_of": "guru_of",
    "wields": "wielded_by", "wielded_by": "wields",
    "killed_by": "killed", "killed": "killed_by",
    "incarnation_of": "has_incarnation", "has_incarnation": "incarnation_of",
    "mount_of": "has_mount", "has_mount": "mount_of",
    "consort_of": "consort_of",
    "authored": "authored_by", "authored_by": "authored",
    "appears_in": "features", "features": "appears_in",
    "mentioned_in": "mentions", "mentions": "mentioned_in",
    "located_in": "contains", "contains": "located_in",
    "ruled_by": "ruled", "ruled": "ruled_by",
    "worshipped_at": "worships", "worships": "worshipped_at",
    "related_to": "related_to", "symbol_of": "has_symbol",
    "has_symbol": "symbol_of", "associated_with": "associated_with",
    "part_of": "has_part", "has_part": "part_of",
    "member_of": "has_member", "has_member": "member_of",
}
LINEAGE_RELS = {"father_of", "mother_of", "spouse_of", "sibling_of", "child_of",
                "parent_of", "guru_of", "disciple_of"}

ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# The 30-second read, in words per language. apply_narrative.py gates one patch
# as it is written; this gates the finished set. The two bounds must be the same
# pair: a looser applier would write rows this gate then refuses, and no tool
# would be able to fix them. selftest_narrative.py asserts they still match.
QUICK_SUMMARY_WORDS = (30, 95)

# A quick summary is prose, and prose never carries its own citation -- the
# chapter lives in source_chapter_or_section, where the reader can see it.
CITES_INLINE = re.compile(r"\b(sarga|canto|section|parva\s+\d)\b", re.I)

# Events whose quick summary cannot be drafted from a cited public-domain
# chapter, and why. Recorded rather than skipped: every entry is reported on
# every run, and an entry that has stopped being needed is an error, not a
# leftover that quietly excuses a gap.
QUICK_SUMMARY_EXCEPTIONS: dict[str, str] = {
    "ram-indrajit": (
        "Griffith abridges the war -- his Book VI has no cantos 76-92, so "
        "sargas 88-91 are unreachable at any number. Needs a second recension "
        "(SC-06); must not silently borrow one."
    ),
}

# ---------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------


@dataclass
class Finding:
    severity: str          # 'error' | 'warning'
    code: str              # stable slug, e.g. 'missing-primary-source'
    message: str
    file: str | None = None
    line: int | None = None
    module: str | None = None

    def location(self) -> str:
        if self.file and self.line:
            return f"{self.file}:{self.line}"
        return self.file or "-"

    def __str__(self) -> str:
        return f"[{self.severity.upper():7}] {self.code:<28} {self.location():<44} {self.message}"


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)
    counts: dict[str, int] = field(default_factory=dict)

    def add(self, *a: Any, **kw: Any) -> None:
        self.findings.append(Finding(*a, **kw))

    @property
    def errors(self) -> list[Finding]:
        return [f for f in self.findings if f.severity == "error"]

    @property
    def warnings(self) -> list[Finding]:
        return [f for f in self.findings if f.severity == "warning"]


# ---------------------------------------------------------------------------
# JSON Schema plumbing
# ---------------------------------------------------------------------------

def _build_validator_map() -> dict[str, Any]:
    """Compile one validator per kind, with cross-file $ref resolution.

    Schemas reference each other by $id ('aradhya:_common#/$defs/slug'), so a
    referencing.Registry is required -- the default resolver would try to fetch
    over the network, which must never happen in a build.
    """
    try:
        from jsonschema import Draft202012Validator
        from referencing import Registry, Resource
    except ImportError as e:
        raise SystemExit(
            "missing dependency: py -m pip install -r content/requirements.txt"
        ) from e

    docs: dict[str, dict] = {}
    for path in sorted(KINDS_DIR.glob("*.schema.json")):
        doc = json.loads(path.read_text(encoding="utf-8"))
        docs[doc["$id"]] = doc

    registry = Registry().with_resources(
        [(uri, Resource.from_contents(doc)) for uri, doc in docs.items()]
    )

    out: dict[str, Any] = {}
    for uri, doc in docs.items():
        kind = uri.split(":", 1)[1]
        if kind == "_common":
            continue
        out[kind] = Draft202012Validator(doc, registry=registry)
    return out


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def _rel(path: Path) -> str:
    """Repo-relative when possible; absolute otherwise (selftest temp dirs)."""
    try:
        return str(path.relative_to(REPO_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


@dataclass
class Row:
    module: str
    kind: str
    path: Path
    line: int
    obj: dict[str, Any]

    @property
    def rel(self) -> str:
        return _rel(self.path)

    @property
    def slug(self) -> str:
        return self.obj.get("slug") or ""


def load_rows(rep: Report) -> list[Row]:
    rows: list[Row] = []
    for module, (kind, _table) in MODULES.items():
        d = DATA_DIR / module
        if not d.is_dir():
            continue
        for path in sorted(d.glob("*.jsonl")):
            try:
                for line_no, obj in read_jsonl(path):
                    rows.append(Row(module, kind, path, line_no, obj))
            except ValueError as e:
                rep.add("error", "malformed-jsonl", str(e),
                        file=_rel(path), module=module)
    return rows


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def check_schema(rows: list[Row], rep: Report) -> None:
    """1. JSON Schema conformance per kind."""
    validators = _build_validator_map()
    for r in rows:
        v = validators.get(r.kind)
        if v is None:
            rep.add("error", "unknown-kind", f"no schema for kind '{r.kind}'",
                    file=r.rel, line=r.line, module=r.module)
            continue
        for err in sorted(v.iter_errors(r.obj), key=lambda e: list(e.path)):
            loc = "/".join(str(p) for p in err.path) or "(root)"
            rep.add("error", "schema", f"{loc}: {err.message}",
                    file=r.rel, line=r.line, module=r.module)


def check_sources(rows: list[Row], rep: Report, known: set[str],
                  registry: dict[str, dict]) -> None:
    """2. source_slug known. 3. >=1 primary/secondary. 4. sane dates.
    8. licence non-empty + domain not excluded."""
    today = _dt.date.today()
    excluded = excluded_domains()

    for r in rows:
        srcs = r.obj.get("sources") or []
        if not srcs:
            rep.add("error", "no-sources",
                    "every entry needs at least one citation (reference doc §2)",
                    file=r.rel, line=r.line, module=r.module)
            continue

        has_strong = False
        for s in srcs:
            slug = s.get("source_slug")
            if slug not in known:
                rep.add("error", "unknown-source",
                        f"source_slug '{slug}' is not in content/sources/registry.jsonl",
                        file=r.rel, line=r.line, module=r.module)
                continue

            meta = registry[slug]
            if meta.get("source_type") in ("primary", "secondary"):
                has_strong = True

            if not (meta.get("license_or_usage_note") or "").strip():
                rep.add("error", "no-licence",
                        f"source '{slug}' has an empty license_or_usage_note",
                        file=r.rel, line=r.line, module=r.module)

            url = meta.get("source_url") or ""
            for domain, reason in excluded.items():
                bare = domain.lstrip("*.")
                if bare and bare in url:
                    rep.add("error", "excluded-source",
                            f"source '{slug}' points at excluded domain "
                            f"{domain} ({reason})",
                            file=r.rel, line=r.line, module=r.module)

            lv = s.get("last_verified_at")
            if not lv or not ISO_DATE.match(str(lv)):
                rep.add("error", "bad-verified-date",
                        f"last_verified_at '{lv}' is not ISO-8601 (YYYY-MM-DD)",
                        file=r.rel, line=r.line, module=r.module)
            else:
                try:
                    if _dt.date.fromisoformat(lv) > today:
                        rep.add("error", "future-verified-date",
                                f"last_verified_at '{lv}' is in the future",
                                file=r.rel, line=r.line, module=r.module)
                except ValueError:
                    rep.add("error", "bad-verified-date",
                            f"last_verified_at '{lv}' is not a real date",
                            file=r.rel, line=r.line, module=r.module)

        if not has_strong:
            # The rule guards VERIFIED content: nothing we assert as checked may
            # rest on a reference work alone (§2). An unverified skeleton is a
            # different thing -- a CC0 Wikidata import that cites Wikidata is
            # being honest about exactly what it is, and it is waiting for
            # substance from a public-domain text. --strict refuses unverified
            # rows outright, so a release build still cannot contain one.
            claims_verified = (r.obj.get("verification") or {}).get(
                "status_en") == "verified"
            rep.add(
                "error" if claims_verified else "warning",
                "missing-primary-source",
                "no source of type 'primary' or 'secondary' -- reference-only "
                "citations cannot be the base truth for sacred content (§2)"
                + ("" if claims_verified
                   else "; allowed here only because the entry is unverified"),
                file=r.rel, line=r.line, module=r.module)


def check_links(rows: list[Row], rep: Report) -> None:
    """5. Every slug reference resolves. No dangling edges."""
    entity_slugs = {r.slug for r in rows if r.module == "entities" and r.slug}
    narrative_slugs = {r.slug for r in rows if r.module == "narrative" and r.slug}
    cosmology_slugs = {r.slug for r in rows if r.module == "cosmology" and r.slug}

    def want(r: Row, value: Any, pool: set[str], label: str) -> None:
        if value and value not in pool:
            rep.add("error", "dangling-ref",
                    f"{label} '{value}' does not resolve",
                    file=r.rel, line=r.line, module=r.module)

    for r in rows:
        o = r.obj
        for item in o.get("related_items") or []:
            want(r, item.get("dst_slug"), entity_slugs, "related_items.dst_slug")
            rt = item.get("rel_type")
            if rt and rt not in REL_INVERSE:
                rep.add("error", "unknown-rel-type",
                        f"rel_type '{rt}' is not in the vocabulary (validate.REL_INVERSE)",
                        file=r.rel, line=r.line, module=r.module)

        if r.module == "relations":
            want(r, o.get("src_slug"), entity_slugs, "src_slug")
            want(r, o.get("dst_slug"), entity_slugs, "dst_slug")
            rt = o.get("rel_type")
            if rt and rt not in REL_INVERSE:
                rep.add("error", "unknown-rel-type",
                        f"rel_type '{rt}' is not in the vocabulary",
                        file=r.rel, line=r.line, module=r.module)

        want(r, o.get("entity_slug"), entity_slugs, "entity_slug")
        want(r, o.get("deity_entity_slug"), entity_slugs, "deity_entity_slug")
        want(r, o.get("place_entity_slug"), entity_slugs, "place_entity_slug")
        want(r, o.get("story_node_slug"), narrative_slugs, "story_node_slug")
        want(r, o.get("based_on_node_slug"), narrative_slugs, "based_on_node_slug")
        want(r, o.get("parent_slug"), cosmology_slugs, "parent_slug")
        for c in o.get("cast") or []:
            want(r, c.get("entity_slug"), entity_slugs, "cast.entity_slug")


def check_duplicates(rows: list[Row], rep: Report) -> None:
    """6. Exact title collision within a kind (error).
    7. Near-duplicate (warning). Duplicate alias across entities (warning) --
    a real search-quality bug: two entities answering to the same epithet."""
    by_kind: dict[str, dict[str, Row]] = {}
    slugs: dict[str, Row] = {}

    for r in rows:
        if r.slug:
            prev = slugs.get(r.slug)
            if prev:
                rep.add("error", "duplicate-slug",
                        f"slug '{r.slug}' already defined at {prev.rel}:{prev.line}",
                        file=r.rel, line=r.line, module=r.module)
            else:
                slugs[r.slug] = r

        title = (r.obj.get("title") or {}).get("en")
        if not title:
            continue
        key = f"{r.obj.get('kind', r.module)}"
        norm = fold(title)
        bucket = by_kind.setdefault(key, {})
        prev = bucket.get(norm)
        if prev:
            rep.add("error", "duplicate-title",
                    f"title '{title}' collides with {prev.rel}:{prev.line} in kind '{key}'",
                    file=r.rel, line=r.line, module=r.module)
        else:
            bucket[norm] = r

    # Near-duplicates (warning only -- legitimate near-names exist).
    try:
        from rapidfuzz import fuzz
    except ImportError:
        rep.add("warning", "rapidfuzz-missing",
                "rapidfuzz not installed -- near-duplicate detection skipped")
    else:
        for key, bucket in by_kind.items():
            items = list(bucket.items())
            for i in range(len(items)):
                for j in range(i + 1, len(items)):
                    a, ra = items[i]
                    b, rb = items[j]
                    if a and b and fuzz.token_set_ratio(a, b) > 90:
                        rep.add("warning", "near-duplicate",
                                f"'{a}' ~ '{b}' in kind '{key}' "
                                f"(also at {rb.rel}:{rb.line})",
                                file=ra.rel, line=ra.line, module=ra.module)

    # Duplicate aliases across DIFFERENT entities -- Risk 8 in the plan.
    alias_owner: dict[str, Row] = {}
    for r in rows:
        if r.module != "entities":
            continue
        for al in r.obj.get("aliases") or []:
            kind = al.get("alias_kind")
            if kind not in ("primary", "epithet"):
                continue  # only strong aliases feed related_edges matching
            f = fold(al.get("alias", ""))
            if not f:
                continue
            prev = alias_owner.get(f)
            if prev and prev.slug != r.slug:
                rep.add("warning", "duplicate-alias",
                        f"alias '{al['alias']}' is claimed by both '{prev.slug}' "
                        f"and '{r.slug}' -- will mis-wire related_edges (Risk 8)",
                        file=r.rel, line=r.line, module=r.module)
            else:
                alias_owner[f] = r


def check_module_rules(rows: list[Row], rep: Report) -> None:
    """9. vidya caution required. 10. festival region required.
    12. relation inverse materialisable (warning)."""
    for r in rows:
        o = r.obj
        if r.module == "vidya":
            if not (o.get("caution") or {}).get("en", "").strip():
                rep.add("error", "missing-caution",
                        "vidya_topics.caution_en is required -- the §4.15 "
                        "medical-advice rule is enforced, not reviewed",
                        file=r.rel, line=r.line, module=r.module)
        if r.module == "festivals":
            if not (o.get("region") or "").strip():
                rep.add("error", "missing-region",
                        "festivals.region is required -- §4.18: dates vary by region",
                        file=r.rel, line=r.line, module=r.module)
        for item in list(o.get("related_items") or []) + \
                ([o] if r.module == "relations" else []):
            rt = item.get("rel_type")
            if rt in LINEAGE_RELS and rt not in REL_INVERSE:
                rep.add("warning", "no-inverse",
                        f"lineage rel_type '{rt}' has no materialisable inverse",
                        file=r.rel, line=r.line, module=r.module)


def check_bilingual(rows: list[Row], rep: Report, strict: bool) -> None:
    """11. Hindi coverage. ERROR under --strict, warning in dev (§1.11)."""
    sev = "error" if strict else "warning"
    for r in rows:
        # Relation edges have no user-facing text of their own -- their titles
        # come from the entities they join, so a bilingual check here would be
        # 199 false positives.
        if r.module == "relations":
            continue
        o = r.obj
        title = o.get("title") or o.get("prompt") or o.get("question") or {}
        if isinstance(title, dict) and not (title.get("hi") or "").strip():
            rep.add(sev, "missing-hindi-title",
                    "title/prompt/question has no Hindi -- the app is bilingual (§1.11)",
                    file=r.rel, line=r.line, module=r.module)
        sd = o.get("short_description") or {}
        if isinstance(sd, dict) and sd.get("en") and not (sd.get("hi") or "").strip():
            rep.add(sev, "missing-hindi-summary",
                    "short_description has no Hindi",
                    file=r.rel, line=r.line, module=r.module)
        ld = o.get("long_description") or {}
        if isinstance(ld, dict) and ld.get("en") and not (ld.get("hi") or "").strip():
            rep.add("warning", "missing-hindi-body",
                    "long_description has no Hindi",
                    file=r.rel, line=r.line, module=r.module)


def check_quick_summary(rows: list[Row], rep: Report, strict: bool) -> None:
    """12. Every narrative event carries the 30-second read (SC-05).

    Absence is a warning while the epics are still being authored and an error
    under --strict, which is what ships. Everything else here is an error in
    both modes, because a summary that is the card blurb again, or that runs to
    two hundred words, is not unfinished work -- it is wrong work, and it got
    past the applier somehow.
    """
    lo, hi = QUICK_SUMMARY_WORDS
    sev = "error" if strict else "warning"
    seen: set[str] = set()

    for r in rows:
        if r.module != "narrative":
            continue
        seen.add(r.slug)
        o = r.obj
        qs = o.get("quick_summary") or {}
        sd = o.get("short_description") or {}
        excused = QUICK_SUMMARY_EXCEPTIONS.get(r.slug)
        sides = {lang: ((qs.get(lang) or "").strip()) for lang in ("en", "hi")}

        if not any(sides.values()):
            if excused:
                # Always emitted, in both modes. An excepted event is a gap the
                # reader will meet in the app, not a box that has been ticked.
                rep.add("warning", "quick-summary-excepted",
                        f"{r.slug}: no quick summary -- {excused}",
                        file=r.rel, line=r.line, module=r.module)
            else:
                rep.add(sev, "missing-quick-summary",
                        f"{r.slug}: no quick_summary -- every event needs the "
                        f"30-second read (SC-05)",
                        file=r.rel, line=r.line, module=r.module)
            continue

        if excused:
            rep.add("error", "stale-quick-summary-exception",
                    f"{r.slug} has a quick summary now, so its entry in "
                    f"QUICK_SUMMARY_EXCEPTIONS is obsolete -- delete it",
                    file=r.rel, line=r.line, module=r.module)

        for lang, text in sides.items():
            if not text:
                rep.add("error", "quick-summary-one-language",
                        f"{r.slug}: quick_summary.{lang} is empty -- both "
                        f"languages or neither",
                        file=r.rel, line=r.line, module=r.module)
                continue

            n = len(text.split())
            if not lo <= n <= hi:
                rep.add("error", "quick-summary-length",
                        f"{r.slug}: quick_summary.{lang} is {n} words, "
                        f"wanted {lo}-{hi}",
                        file=r.rel, line=r.line, module=r.module)

            m = CITES_INLINE.search(text)
            if m:
                rep.add("error", "quick-summary-cites-inline",
                        f"{r.slug}: quick_summary.{lang} says '{m.group(0)}' -- "
                        f"the chapter belongs in source_chapter_or_section, "
                        f"not in the prose",
                        file=r.rel, line=r.line, module=r.module)

            blurb = (sd.get(lang) or "").strip()
            if not blurb:
                continue
            if text == blurb:
                rep.add("error", "quick-summary-is-blurb",
                        f"{r.slug}: quick_summary.{lang} is short_description "
                        f"verbatim",
                        file=r.rel, line=r.line, module=r.module)
            elif blurb in text:
                rep.add("error", "quick-summary-repeats-blurb",
                        f"{r.slug}: quick_summary.{lang} contains "
                        f"short_description verbatim",
                        file=r.rel, line=r.line, module=r.module)
            elif n <= len(blurb.split()):
                rep.add("error", "quick-summary-not-longer",
                        f"{r.slug}: quick_summary.{lang} is {n} words against "
                        f"a {len(blurb.split())}-word blurb -- it expands the "
                        f"blurb or it has no reason to exist",
                        file=r.rel, line=r.line, module=r.module)

    # Only worth saying when there is a narrative set to compare against: on a
    # partial checkout, or a fabricated one in the selftest, every name here
    # would look unknown. And it is a hygiene notice, not a gate -- if the slug
    # is a typo then the real event still has no summary, and
    # missing-quick-summary catches it under the name it actually has.
    if seen:
        for slug, why in QUICK_SUMMARY_EXCEPTIONS.items():
            if slug not in seen:
                rep.add("warning", "unknown-quick-summary-exception",
                        f"QUICK_SUMMARY_EXCEPTIONS names '{slug}', which is not "
                        f"a narrative event -- renamed or removed? ({why})")


# Modules whose rows are prose we authored -- these must ALWAYS be verified
# under --strict, no skeleton tier. A Wikidata skeleton is a different thing
# from a paragraph a human wrote.
_AUTHORED_MODULES = {
    "narrative", "dharma", "vidya", "festivals", "ask", "journal", "paths",
    "cosmology",
}
# Source slugs that mark a row as a CC0 structured-data import rather than
# something read against a translation.
_SKELETON_SOURCES = {"wikidata"}


def _is_skeleton(obj: dict, importance_of: dict[str, int]) -> bool:
    """A P1/P2 row imported from CC0 structured data and honestly flagged as
    reference-tier. It ships with a 'Reference -- unverified' chip in-app
    (see reference_art / entity screen). P0 rows never qualify: importance <= 2
    is the app's spine and must be read against a primary text."""
    srcs = obj.get("sources") or []
    if not srcs or any(
        (s.get("source_slug") or "").lower() not in _SKELETON_SOURCES
        for s in srcs
    ):
        return False
    # Entity: its own importance. Relation: the more prominent endpoint.
    imp = obj.get("importance")
    if imp is None:
        imp = max(
            (importance_of.get(obj.get(k) or "", 99)
             for k in ("src_slug", "dst_slug")),
            default=99,
        )
    return imp is not None and imp >= 3


def check_verification(rows: list[Row], rep: Report, strict: bool) -> None:
    """--strict ships verified content, with one tier exception.

    Tiered gate (decided 2026-09-06): a P1/P2 entity or relation imported
    straight from CC0 Wikidata, and honestly flagged reference-tier, may ship
    with a visible 'Reference -- unverified' chip. Everything else -- every P0
    row (importance <= 2), and every row in an authored-prose module -- must be
    'verified' in BOTH languages. The un-tiered backlog is a post-launch
    quality track, not a launch blocker.
    """
    if not strict:
        return
    importance_of = {
        r.slug: r.obj.get("importance")
        for r in rows
        if r.module == "entities" and r.slug
        and r.obj.get("importance") is not None
    }
    for r in rows:
        v = r.obj.get("verification") or {}
        if v.get("status_en") == "verified" and v.get("status_hi") == "verified":
            continue
        if (r.module not in _AUTHORED_MODULES
                and _is_skeleton(r.obj, importance_of)):
            continue  # reference-tier skeleton -- ships flagged
        for lang in ("status_en", "status_hi"):
            if v.get(lang) != "verified":
                rep.add("error", "unverified",
                        f"verification.{lang} is '{v.get(lang)}' -- "
                        f"--strict ships verified content, or a reference-tier "
                        f"CC0 skeleton (this row is neither)",
                        file=r.rel, line=r.line, module=r.module)


def check_routes(rows: list[Row], rep: Report) -> None:
    """13. Every emitted route matches a registered pattern.

    routes.txt is regenerated from appRouter by a Dart test, so a route rename
    cannot silently break every indexed deep link.
    """
    routes_file = CONTENT_DIR / "tools" / "routes.txt"
    if not routes_file.exists():
        rep.add("warning", "no-routes-file",
                "content/tools/routes.txt missing -- run the Dart route-export "
                "test; route validation skipped")
        return

    patterns: list[re.Pattern] = []
    for line in routes_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # Substitute :params BEFORE escaping. Python's re.escape has not
        # escaped ':' since 3.7, so matching on an escaped colon silently never
        # fired and EVERY parameterised route was reported as unknown.
        parts = [
            "[^/]+" if seg.startswith(":") else re.escape(seg)
            for seg in line.split("/")
        ]
        patterns.append(re.compile("^" + "/".join(parts) + "$"))

    def ok(route: str) -> bool:
        path = route.split("?", 1)[0]
        return any(p.match(path) for p in patterns)

    for r in rows:
        for step in r.obj.get("steps") or []:
            route = step.get("route")
            if route and not ok(route):
                rep.add("error", "unknown-route",
                        f"route '{route}' matches no pattern in routes.txt",
                        file=r.rel, line=r.line, module=r.module)


def check_curation_gate(rep: Report) -> None:
    """CM-03: the curation folder gate must stay physical, not just a habit.

    `extract.py`'s `load_curation()` reads `curation/approved/` only, so a
    file left at the top level of `curation/` (outside any of the three
    subfolders) is silently invisible to `--promote` -- which reads as "my
    edit didn't take" rather than the actual cause, a file in the wrong
    place. Catching that here turns a confusing no-op into a named error.
    """
    if not CURATION_DIR.is_dir():
        return
    required = {"inbox", "approved", "rejected"}
    present = {p.name for p in CURATION_DIR.iterdir() if p.is_dir()}
    missing = required - present
    if missing:
        rep.add("error", "curation-gate-missing",
                f"content/curation/ is missing {sorted(missing)} -- "
                "the inbox/approved/rejected gate must exist for "
                "extract.py --promote to enforce it")
    stray = [p.name for p in CURATION_DIR.glob("*.jsonl") if p.is_file()]
    if stray:
        rep.add("error", "curation-gate-bypassed",
                f"content/curation/ has file(s) outside inbox/approved/"
                f"rejected: {stray} -- these are invisible to "
                "extract.py --promote (which reads approved/ only); move "
                "each into the right subfolder")


def fetched_sources() -> dict[str, int]:
    """slug -> number of files whose provenance is recorded, for content/raw/.

    Provenance, not presence. `content/raw/manifest.json` (written by
    fetch_pd.py) and `content/raw/<slug>/manifest.json` (written by the
    Gutenberg fetches) each record, per file, the URL it came from and the
    sha256 of what arrived. A directory with no such record is a directory
    nobody can account for, which is exactly how the wrong book got in.
    """
    counts: dict[str, int] = {}
    if not RAW_DIR.is_dir():
        return counts

    def note(slug: str, rel: str) -> None:
        if slug and rel and (RAW_DIR / slug / rel).exists():
            counts[slug] = counts.get(slug, 0) + 1

    top = RAW_DIR / "manifest.json"
    if top.exists():
        try:
            for m in json.loads(top.read_text(encoding="utf-8")):
                # `file` is recorded relative to raw/, so it carries the slug.
                f = str(m.get("file", ""))
                note(m.get("source_slug", ""), f.split("\\", 1)[-1].split("/", 1)[-1])
        except (OSError, ValueError, TypeError):
            pass

    for sub in sorted(p for p in RAW_DIR.iterdir() if p.is_dir()):
        mf = sub / "manifest.json"
        if not mf.exists():
            continue
        try:
            obj = json.loads(mf.read_text(encoding="utf-8"))
            for m in obj.get("files", []):
                note(obj.get("source_slug", sub.name), str(m.get("path", "")))
        except (OSError, ValueError, TypeError, AttributeError):
            pass
    return counts


def check_corpus_on_disk(rows: list[Row], rep: Report, registry: dict[str, dict],
                         strict: bool) -> None:
    """The cited chapter must be re-readable, and be the work it claims to be.

    The pipeline rule this project holds itself to is: cited public-domain
    chapter -> fetched into content/raw/ -> read -> drafted -> verified -> DB.
    Every step but the first leaves no trace a later reader can check. What
    makes a citation auditable is that the text is ON DISK, so anyone can open
    the chapter and see whether it says what the row claims.

    Six registered sources were being cited by 300 rows whose verification
    notes read "confirmed in the primary text" while nothing of that text had
    ever been fetched -- dutt-ramayana (85 citations), underhill-hindu-year
    (58), telang-bhagavadgita (56), gopinatha-rao-iconography (29),
    griffith-rigveda (27), gupte-hindu-holidays (5). Those claims may well be
    true; the point is that no one could tell, which is the thing the pipeline
    rule exists to prevent.

    An earlier version of this check asked only whether content/raw/<slug>/
    existed, and that was not enough. Two directories existed and held the
    WRONG BOOK: muller-upanishads/full.txt was a Project Gutenberg copy of
    "The convolvulus: a comedy in three acts" and vivekananda-yoga-sutras/
    full.txt was "The Rangers; or, The Tory's Daughter" -- 61 citations resting
    on text with no relation to the works named. A directory-exists check
    passes both, and passing is worse than failing here: a later reader who
    greps the file for the quoted verse and does not find it will suspect the
    citation before suspecting the corpus.

    So the test is provenance, not presence: some manifest must record the URL
    a file came from and the hash of what arrived. That is decisive on the real
    corpus -- the four sources with recorded provenance are exactly the four
    holding the right text, and the two wrong-book directories have no
    manifest at all, which is how they went unnoticed. Content sniffing was
    tried first and rejected: probing for a distinctive word from the source's
    own title flags griffith-ramayana, whose pages never name the work.

    `source_type: reference` is exempt: wikidata is a queried API, not a
    chapter, and `wd_pull.py` records the QID that a later reader can re-query.
    A warning in dev (this is a fetch backlog, and it must not block authoring
    against the corpora that ARE present) and an error under --strict, because
    a release must not ship a claim its own audit trail cannot support.
    """
    fetched = fetched_sources()

    # slug -> (citation count, first location), for sources that need a text
    missing: dict[str, tuple[int, Row]] = {}
    for r in rows:
        for s in r.obj.get("sources") or []:
            slug = s.get("source_slug")
            meta = registry.get(slug or "")
            if not meta or meta.get("source_type") == "reference":
                continue
            if fetched.get(slug or ""):
                continue
            n, first = missing.get(slug, (0, r))
            missing[slug] = (n + 1, first)

    for slug, (n, first) in sorted(missing.items(), key=lambda kv: -kv[1][0]):
        where = RAW_DIR / slug
        why = ("holds no file with recorded provenance -- nothing says which URL "
               "produced it, so there is no way to tell it is the right book"
               if where.is_dir() else "does not exist")
        rep.add(
            "error" if strict else "warning", "corpus-not-fetched",
            f"{n} row(s) cite '{slug}' but content/raw/{slug}/ {why}. The "
            f"chapter cannot be audited. Fetch it (content/tools/fetch_pd.py) "
            f"or downgrade the rows that depend on it",
            file=first.rel, line=first.line, module=first.module)


def check_index_version(rep: Report) -> None:
    """14. gyan.indexed_content_version must match content.sqlite (Risk 2)."""
    if not GYAN_DB.exists():
        return  # nothing built yet
    if not LEGACY_DB.exists():
        rep.add("error", "missing-legacy-db",
                f"{LEGACY_DB} not found -- the search index cannot be verified")
        return
    try:
        legacy = sqlite3.connect(f"file:{LEGACY_DB}?mode=ro", uri=True)
        gyan = sqlite3.connect(f"file:{GYAN_DB}?mode=ro", uri=True)
        lv = dict(legacy.execute("select key,value from meta")).get("content_version")
        gv = dict(gyan.execute("select key,value from meta")).get("indexed_content_version")
        legacy.close()
        gyan.close()
    except sqlite3.Error as e:
        rep.add("warning", "version-check-failed", f"could not compare versions: {e}")
        return
    if gv and lv and gv != lv:
        rep.add("error", "stale-index",
                f"gyan.sqlite was indexed against content.sqlite '{gv}' but the "
                f"shipped one is '{lv}' -- every legacy deep link may be wrong "
                f"(Risk 2). Rebuild gyan.sqlite.")


def check_assets(rows: list[Row], rep: Report, strict: bool) -> None:
    """Asset manifest integrity (P0-34). --strict blocks placeholder art."""
    manifest_path = REPO_ROOT / "assets" / "manifest.json"
    if not manifest_path.exists():
        rep.add("warning", "no-asset-manifest",
                "assets/manifest.json missing -- asset checks skipped")
        return
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        rep.add("error", "bad-asset-manifest", f"assets/manifest.json: {e}")
        return

    entries = manifest.get("assets", manifest if isinstance(manifest, list) else [])
    by_path = {a["path"]: a for a in entries}
    known = set(by_path)

    for a in entries:
        if not (a.get("license") or "").strip():
            rep.add("error", "asset-no-licence",
                    f"asset '{a.get('path')}' has no license",
                    file="assets/manifest.json")
        if strict and a.get("replace_before_ship"):
            rep.add("error", "placeholder-asset",
                    f"asset '{a.get('path')}' is still flagged "
                    f"replace_before_ship -- release blocked (RG-03)",
                    file="assets/manifest.json")
        p = REPO_ROOT / a.get("path", "")
        if not p.exists():
            rep.add("error", "asset-missing-file",
                    f"manifest lists '{a.get('path')}' but the file does not exist",
                    file="assets/manifest.json")

    for r in rows:
        for key in ("image_asset", "cover_asset"):
            v = r.obj.get(key)
            if v and v not in known:
                rep.add("error", "asset-not-in-manifest",
                        f"{key} '{v}' is not in assets/manifest.json",
                        file=r.rel, line=r.line, module=r.module)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run(strict: bool = False, skip_index_check: bool = False) -> Report:
    """Run every check.

    `skip_index_check` is set by build.py: the staleness guard compares the
    EXISTING gyan.sqlite against content.sqlite, which is meaningless when we
    are about to overwrite gyan.sqlite. Without it, bumping content.sqlite
    deadlocks -- the build refuses because the index is stale, and the only way
    to refresh the index is to build.
    """
    rep = Report()

    if not (SOURCES_DIR / "registry.jsonl").exists():
        rep.add("error", "no-registry", "content/sources/registry.jsonl is missing")
        return rep

    registry = {o["slug"]: o for _, o in read_jsonl(SOURCES_DIR / "registry.jsonl")}
    known = set(registry)

    rows = load_rows(rep)
    rep.counts = {m: sum(1 for r in rows if r.module == m) for m in MODULES}
    rep.counts["_total"] = len(rows)

    if rows:
        check_schema(rows, rep)
        check_sources(rows, rep, known, registry)
        check_links(rows, rep)
        check_duplicates(rows, rep)
        check_module_rules(rows, rep)
        check_bilingual(rows, rep, strict)
        check_quick_summary(rows, rep, strict)
        check_verification(rows, rep, strict)
        check_routes(rows, rep)
        check_assets(rows, rep, strict)
        check_corpus_on_disk(rows, rep, registry, strict)

    check_curation_gate(rep)

    if not skip_index_check:
        check_index_version(rep)
    return rep


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Validate Aradhya content JSONL.")
    ap.add_argument("--strict", action="store_true",
                    help="release mode: unverified + missing-Hindi become errors")
    ap.add_argument("--quiet", action="store_true", help="only print the summary")
    args = ap.parse_args(argv)

    rep = run(strict=args.strict)

    if not args.quiet:
        for f in rep.findings:
            print(f)

    total = rep.counts.get("_total", 0)
    mode = "strict" if args.strict else "dev"
    print()
    print(f"validate ({mode}): {total} rows, "
          f"{len(rep.errors)} error(s), {len(rep.warnings)} warning(s)")

    if total == 0:
        print("note: no content authored yet -- schema and registry checks only.")

    return 1 if rep.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
