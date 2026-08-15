"""Stage 4 — compile content/data/*.jsonl into assets/db/gyan.sqlite.

    py -m content.tools.build [--strict|--allow-unverified] [--modules a,b]

What it does, in order:
    1. run validate.py and refuse to build on any error
    2. create a fresh gyan.sqlite from content/schema/gyan.sql
    3. insert sources, then every content module, resolving slug -> integer id
    4. materialise inverse relations so every graph query is single-direction
    5. denormalize primary_source_* onto each content row (so a card can render
       a citation without a join, and it can never disagree with item_sources)
    6. build the search index (index.py) and related edges (relate.py) if present
    7. stamp meta, regenerate SOURCES.md, rewrite the Dart version const
    8. PRAGMA journal_mode=DELETE; VACUUM; integrity_check

Step 8 is not optional: a WAL-mode file cannot be opened read-only on device
without write access to its -shm sidecar, so the app would fail to open it.

content.sqlite is opened READ-ONLY and never modified.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools import validate  # noqa: E402
from content.tools.common import (  # noqa: E402
    ASSETS_DB_DIR, CONTENT_DIR, DATA_DIR, GYAN_DB, LEGACY_DB, REPO_ROOT,
    SCHEMA_DIR, SOURCES_DIR, bi, expand_devanagari_aliases, fold, fold_variants,
    read_jsonl, tokenize,
)

SEMVER = "1.0.0"
DART_DB_FILE = REPO_ROOT / "lib" / "core" / "db" / "content_database.dart"
BUILD_STAMP_RE = re.compile(
    r"(static const gyanAssetVersion\s*=\s*')[^']*('\s*;\s*//\s*BUILD_STAMP:gyan)")


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _git_sha() -> str:
    try:
        out = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                             cwd=REPO_ROOT, capture_output=True, text=True,
                             timeout=10)
        return out.stdout.strip() or "nogit"
    except Exception:
        return "nogit"


def _jstr(v: Any) -> str | None:
    """Serialise a list/dict column, or None when empty -- never '[]' noise."""
    if v is None or v == [] or v == {}:
        return None
    return json.dumps(v, ensure_ascii=False, sort_keys=True)


def _status(row: dict) -> str:
    """Collapse the per-language verification block into one column.

    Conservative on purpose: an entry verified in English but not Hindi is not
    'verified' for a bilingual app (§1.11).
    """
    v = row.get("verification") or {}
    en, hi = v.get("status_en"), v.get("status_hi")
    if "disputed" in (en, hi):
        return "disputed"
    if en == "verified" and hi == "verified":
        return "verified"
    return "unverified"


# ---------------------------------------------------------------------------
# builder
# ---------------------------------------------------------------------------

class Builder:
    def __init__(self, db: sqlite3.Connection, strict: bool,
                 modules: set[str] | None):
        self.db = db
        self.strict = strict
        self.modules = modules
        self.source_ids: dict[str, int] = {}
        self.entity_ids: dict[str, int] = {}
        self.narrative_ids: dict[str, int] = {}
        self.cosmology_ids: dict[str, int] = {}
        self.path_ids: dict[str, int] = {}
        # 'bhagavad-gita:2.47' -> scripture_sections.id, resolved
        # against the read-only legacy DB. Unresolvable refs are absent.
        self.section_ids: dict[str, int] = {}
        self.counts: dict[str, int] = {}
        self.skipped_unverified = 0

    # -- infrastructure ----------------------------------------------------

    def apply_schema(self) -> None:
        self.db.executescript((SCHEMA_DIR / "gyan.sql").read_text(encoding="utf-8"))

    def want(self, module: str) -> bool:
        return self.modules is None or module in self.modules

    def rows(self, module: str) -> list[dict]:
        """Load a module's rows, honouring --strict and --modules."""
        if not self.want(module):
            return []
        out: list[dict] = []
        d = DATA_DIR / module
        if not d.is_dir():
            return out
        for path in sorted(d.glob("*.jsonl")):
            for _line, obj in read_jsonl(path):
                if self.strict and _status(obj) != "verified":
                    self.skipped_unverified += 1
                    continue
                out.append(obj)
        self.counts[module] = len(out)
        return out

    # -- provenance --------------------------------------------------------

    def insert_sources(self) -> None:
        rows = [o for _l, o in read_jsonl(SOURCES_DIR / "registry.jsonl")]
        for o in rows:
            cur = self.db.execute(
                """insert into sources (slug, source_name, source_url, source_type,
                       source_language, edition, license_or_usage_note,
                       retrieved_at, checksum)
                   values (?,?,?,?,?,?,?,?,?)""",
                (o["slug"], o["source_name"], o.get("source_url"), o["source_type"],
                 o.get("source_language"), o.get("edition"),
                 o["license_or_usage_note"], o.get("retrieved_at"),
                 o.get("checksum")))
            self.source_ids[o["slug"]] = cur.lastrowid
        self.counts["sources"] = len(rows)

    def link_sources(self, table: str, item_id: int, row: dict) -> tuple[str | None, ...]:
        """Write item_sources rows and return the denormalized primary triple.

        The denormalized copy is DERIVED here rather than authored, which is
        why it can never drift from item_sources.
        """
        primary: dict | None = None
        last_verified: str | None = None

        for s in row.get("sources") or []:
            sid = self.source_ids.get(s["source_slug"])
            if sid is None:
                continue
            self.db.execute(
                """insert or ignore into item_sources
                   (item_table, item_id, source_id, source_chapter_or_section,
                    quote, last_verified_at, verified_by, is_primary)
                   values (?,?,?,?,?,?,?,?)""",
                (table, item_id, sid, s.get("source_chapter_or_section"),
                 s.get("quote"), s["last_verified_at"], s.get("verified_by"),
                 1 if s.get("is_primary") else 0))
            if primary is None or s.get("is_primary"):
                if primary is None or not primary.get("is_primary"):
                    primary = s
            lv = s.get("last_verified_at")
            if lv and (last_verified is None or lv > last_verified):
                last_verified = lv

        if not primary:
            return (None, None, None, last_verified)
        meta = next((o for _l, o in read_jsonl(SOURCES_DIR / "registry.jsonl")
                     if o["slug"] == primary["source_slug"]), None)
        name = meta["source_name"] if meta else primary["source_slug"]
        url = meta.get("source_url") if meta else None
        return (name, primary.get("source_chapter_or_section"), url, last_verified)

    # -- entities ----------------------------------------------------------

    def insert_entities(self) -> None:
        rows = self.rows("entities")
        for o in rows:
            t = o.get("title") or {}
            sd = o.get("short_description") or {}
            ld = o.get("long_description") or {}
            cur = self.db.execute(
                """insert into entities
                   (slug, kind, title_en, title_hi, title_sa, title_iast, category,
                    short_description_en, short_description_hi,
                    long_description_en, long_description_hi,
                    region, tradition, tags, props, image_asset, glyph,
                    importance, wikidata_qid, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], o["kind"], t.get("en"), t.get("hi"), t.get("sa"),
                 t.get("iast"), o.get("category"),
                 sd.get("en"), sd.get("hi"), ld.get("en"), ld.get("hi"),
                 o.get("region"), o.get("tradition"), _jstr(o.get("tags")),
                 _jstr(o.get("props")), o.get("image_asset"), o.get("glyph"),
                 o.get("importance", 3), o.get("wikidata_qid"), _status(o)))
            eid = cur.lastrowid
            self.entity_ids[o["slug"]] = eid

            name, ref, url, lv = self.link_sources("entities", eid, o)
            self.db.execute(
                """update entities set primary_source_name=?, primary_source_ref=?,
                   primary_source_url=?, last_verified_at=? where id=?""",
                (name, ref, url, lv, eid))

            self._insert_aliases(eid, o)

    def _insert_aliases(self, eid: int, o: dict) -> None:
        """Authored aliases + the titles themselves + derived transliterations.

        The titles must be aliases too, otherwise an entity is unfindable by its
        own name in the other script.
        """
        seen: set[tuple[str, str]] = set()

        def add(alias: str, script: str, lang: str, kind: str) -> None:
            alias = (alias or "").strip()
            if not alias:
                return
            f = fold(alias)
            if not f or (f, lang) in seen:
                return
            seen.add((f, lang))
            self.db.execute(
                """insert into entity_aliases
                   (entity_id, alias, alias_fold, script, lang, alias_kind)
                   values (?,?,?,?,?,?)""",
                (eid, alias, f, script, lang, kind))

        t = o.get("title") or {}
        add(t.get("en"), "latn", "en", "primary")
        add(t.get("hi"), "deva", "hi", "primary")
        add(t.get("sa"), "deva", "sa", "primary")
        add(t.get("iast"), "iast", "sa", "transliteration")

        for al in o.get("aliases") or []:
            add(al.get("alias"), al.get("script", "latn"),
                al.get("lang", "en"), al.get("alias_kind", "spelling"))

        # Derived: Devanagari -> IAST, so a Sanskrit name is Latin-searchable.
        for deva in (t.get("sa"), t.get("hi")):
            for iast in expand_devanagari_aliases(deva or ""):
                add(iast, "iast", "sa", "transliteration")

    # -- relations ---------------------------------------------------------

    def insert_relations(self) -> None:
        edges: list[tuple] = []

        def collect(src: str, rel: str, dst: str, ordinal, tradition,
                    note, confidence) -> None:
            a, b = self.entity_ids.get(src), self.entity_ids.get(dst)
            if a is None or b is None:
                return
            edges.append((a, rel, b, ordinal, tradition,
                          bi(note, "en"), bi(note, "hi"), confidence or "high"))

        # inline related_items on entities
        for module in ("entities",):
            d = DATA_DIR / module
            if not d.is_dir() or not self.want(module):
                continue
            for path in sorted(d.glob("*.jsonl")):
                for _l, o in read_jsonl(path):
                    if self.strict and _status(o) != "verified":
                        continue
                    for it in o.get("related_items") or []:
                        collect(o["slug"], it["rel_type"], it["dst_slug"],
                                it.get("ordinal"), it.get("tradition"),
                                it.get("note"), it.get("confidence"))

        # standalone relation files
        for o in self.rows("relations"):
            collect(o["src_slug"], o["rel_type"], o["dst_slug"], o.get("ordinal"),
                    o.get("tradition"), o.get("note"), o.get("confidence"))

        # materialise inverses so every query is single-direction
        materialised = list(edges)
        have = {(e[0], e[1], e[2]) for e in edges}
        for a, rel, b, ordinal, tradition, ne, nh, conf in edges:
            inv = validate.REL_INVERSE.get(rel)
            if not inv or (b, inv, a) in have:
                continue
            have.add((b, inv, a))
            materialised.append((b, inv, a, ordinal, tradition, ne, nh, conf))

        # Drop the generic `parent_of` where a specific father_of/mother_of
        # already says the same thing. Both are produced when an author states
        # the relationship from both ends -- Shiva father_of Ganesha, and
        # Ganesha child_of Shiva -- and the detail screen would then list the
        # same connection twice under different labels.
        specific = {(a, b) for a, rel, b, *_ in materialised
                    if rel in ("father_of", "mother_of")}
        before = len(materialised)
        materialised = [t for t in materialised
                        if not (t[1] == "parent_of" and (t[0], t[2]) in specific)]
        self.counts["relations_deduped"] = before - len(materialised)

        self.db.executemany(
            """insert into relations
               (src_id, rel_type, dst_id, ordinal, tradition, note_en, note_hi, confidence)
               values (?,?,?,?,?,?,?,?)""", materialised)
        self.counts["relations_total"] = len(materialised)
        self.counts["relations_inverse"] = len(materialised) - len(edges)

    # -- satellites --------------------------------------------------------

    def insert_cosmology(self) -> None:
        rows = self.rows("cosmology")
        for o in rows:
            t, sd, ld = o.get("title") or {}, o.get("short_description") or {}, \
                o.get("long_description") or {}
            cur = self.db.execute(
                """insert into cosmology_nodes
                   (slug, track, order_no, title_en, title_hi, title_sa,
                    short_description_en, short_description_hi,
                    long_description_en, long_description_hi,
                    duration_years, attributes, entity_id, tradition, tags, region,
                    verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], o["track"], o["order_no"], t.get("en"), t.get("hi"),
                 t.get("sa"), sd.get("en"), sd.get("hi"), ld.get("en"), ld.get("hi"),
                 o.get("duration_years"), _jstr(o.get("attributes")),
                 self.entity_ids.get(o.get("entity_slug") or ""),
                 o.get("tradition"), _jstr(o.get("tags")), o.get("region"),
                 _status(o)))
            self.cosmology_ids[o["slug"]] = cur.lastrowid
            self._stamp("cosmology_nodes", cur.lastrowid, o)
        # second pass for parent links (parents may appear after children)
        for o in rows:
            pid = self.cosmology_ids.get(o.get("parent_slug") or "")
            if pid:
                self.db.execute("update cosmology_nodes set parent_id=? where slug=?",
                                (pid, o["slug"]))

    def insert_narrative(self) -> None:
        for o in self.rows("narrative"):
            t, sd, ld = o.get("title") or {}, o.get("short_description") or {}, \
                o.get("long_description") or {}
            bl, lesson = o.get("book_label") or {}, o.get("lesson") or {}
            cur = self.db.execute(
                """insert into narrative_nodes
                   (slug, epic, recension, book_label_en, book_label_hi, book_no,
                    sequence_no, title_en, title_hi,
                    short_description_en, short_description_hi,
                    long_description_en, long_description_hi,
                    lesson_en, lesson_hi, place_entity_id, image_asset,
                    tags, region, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], o["epic"], o["recension"], bl.get("en"), bl.get("hi"),
                 o.get("book_no"), o["sequence_no"], t.get("en"), t.get("hi"),
                 sd.get("en"), sd.get("hi"), ld.get("en"), ld.get("hi"),
                 lesson.get("en"), lesson.get("hi"),
                 self.entity_ids.get(o.get("place_entity_slug") or ""),
                 o.get("image_asset"), _jstr(o.get("tags")), o.get("region"),
                 _status(o)))
            nid = cur.lastrowid
            self.narrative_ids[o["slug"]] = nid
            self._stamp("narrative_nodes", nid, o)
            for c in o.get("cast") or []:
                eid = self.entity_ids.get(c.get("entity_slug") or "")
                if eid:
                    self.db.execute(
                        "insert or ignore into narrative_cast (node_id, entity_id, role)"
                        " values (?,?,?)", (nid, eid, c.get("role")))

    def insert_dharma(self) -> None:
        for o in self.rows("dharma"):
            t, ctx = o.get("title") or {}, o.get("context") or {}
            refl, disc = o.get("reflection") or {}, o.get("disclaimer") or {}
            cur = self.db.execute(
                """insert into dharma_scenarios
                   (slug, title_en, title_hi, category, difficulty,
                    context_en, context_hi, reflection_en, reflection_hi,
                    based_on_node_id, disclaimer_en, disclaimer_hi,
                    tags, region, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], t.get("en"), t.get("hi"), o.get("category"),
                 o.get("difficulty", 2), ctx.get("en"), ctx.get("hi"),
                 refl.get("en"), refl.get("hi"),
                 self.narrative_ids.get(o.get("based_on_node_slug") or ""),
                 disc.get("en"), disc.get("hi"), _jstr(o.get("tags")),
                 o.get("region"), _status(o)))
            sid = cur.lastrowid
            self._stamp("dharma_scenarios", sid, o)
            for c in o.get("choices") or []:
                lb, cons = c.get("label") or {}, c.get("consequence") or {}
                self.db.execute(
                    """insert into dharma_choices
                       (scenario_id, choice_key, label_en, label_hi,
                        consequence_en, consequence_hi, guna, order_no)
                       values (?,?,?,?,?,?,?,?)""",
                    (sid, c["choice_key"], lb.get("en"), lb.get("hi"),
                     cons.get("en"), cons.get("hi"), c.get("guna"), c["order_no"]))

    def insert_vidya(self) -> None:
        for o in self.rows("vidya"):
            t, sd = o.get("title") or {}, o.get("short_description") or {}
            ld, pu = o.get("long_description") or {}, o.get("practical_use") or {}
            caution = o.get("caution") or {}
            cur = self.db.execute(
                """insert into vidya_topics
                   (slug, discipline, title_en, title_hi,
                    short_description_en, short_description_hi,
                    long_description_en, long_description_hi,
                    practical_use_en, practical_use_hi, caution_en, caution_hi,
                    modern_status, tags, region, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], o["discipline"], t.get("en"), t.get("hi"),
                 sd.get("en"), sd.get("hi"), ld.get("en"), ld.get("hi"),
                 pu.get("en"), pu.get("hi"), caution.get("en"), caution.get("hi"),
                 o["modern_status"], _jstr(o.get("tags")), o.get("region"),
                 _status(o)))
            self._stamp("vidya_topics", cur.lastrowid, o)

    def insert_festivals(self) -> None:
        for o in self.rows("festivals"):
            t, sd = o.get("title") or {}, o.get("short_description") or {}
            rit, fast = o.get("ritual_summary") or {}, o.get("fast_rules") or {}
            cur = self.db.execute(
                """insert into festivals
                   (slug, title_en, title_hi, title_sa, category, lunar_month,
                    paksha, tithi, solar_rule, region, tradition,
                    deity_entity_id, story_node_id,
                    short_description_en, short_description_hi,
                    ritual_summary_en, ritual_summary_hi,
                    fast_rules_en, fast_rules_hi, tags, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], t.get("en"), t.get("hi"), t.get("sa"), o.get("category"),
                 o.get("lunar_month"), o.get("paksha"), o.get("tithi"),
                 o.get("solar_rule"), o["region"], o.get("tradition"),
                 self.entity_ids.get(o.get("deity_entity_slug") or ""),
                 self.narrative_ids.get(o.get("story_node_slug") or ""),
                 sd.get("en"), sd.get("hi"), rit.get("en"), rit.get("hi"),
                 fast.get("en"), fast.get("hi"), _jstr(o.get("tags")), _status(o)))
            self._stamp("festivals", cur.lastrowid, o)

    def insert_qa(self) -> None:
        pairs = list(self.rows("ask"))
        self.section_ids = resolve_section_refs(
            {o["scripture_ref"] for o in pairs if o.get("scripture_ref")})
        unresolved = sum(
            1 for o in pairs
            if o.get("scripture_ref") and o["scripture_ref"] not in self.section_ids)
        if unresolved:
            print(f"  ask: {unresolved} scripture_ref(s) did not resolve to a "
                  f"unique verse -- those answers ship without a context link")
        for o in pairs:
            q, a = o.get("question") or {}, o.get("answer") or {}
            ex = o.get("explanation") or {}
            cur = self.db.execute(
                """insert into qa_pairs
                   (question_en, question_hi, question_fold, answer_en, answer_hi,
                    explanation_en, explanation_hi, passage_sa, passage_translit,
                    scripture_section_id, confidence, related_qa_ids, tags,
                    verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (q.get("en"), q.get("hi"), _qa_fold(q), a.get("en"),
                 a.get("hi"), ex.get("en"), ex.get("hi"), o.get("passage_sa"),
                 o.get("passage_translit"),
                 self.section_ids.get(o.get("scripture_ref") or ""),
                 o["confidence"],
                 _jstr(o.get("related_question_slugs")), _jstr(o.get("tags")),
                 _status(o)))
            self._stamp("qa_pairs", cur.lastrowid, o)

    def insert_journal(self) -> None:
        for o in self.rows("journal"):
            p = o.get("prompt") or {}
            cur = self.db.execute(
                """insert into journal_prompts
                   (slug, prompt_en, prompt_hi, theme, tags, verification_status)
                   values (?,?,?,?,?,?)""",
                (o["slug"], p.get("en"), p.get("hi"), o.get("theme"),
                 _jstr(o.get("tags")), _status(o)))
            self._stamp("journal_prompts", cur.lastrowid, o)

    def insert_paths(self) -> None:
        for o in self.rows("paths"):
            t, sd = o.get("title") or {}, o.get("short_description") or {}
            cur = self.db.execute(
                """insert into learning_paths
                   (slug, title_en, title_hi, level, short_description_en,
                    short_description_hi, est_minutes, cover_asset, order_no,
                    tags, verification_status)
                   values (?,?,?,?,?,?,?,?,?,?,?)""",
                (o["slug"], t.get("en"), t.get("hi"), o["level"], sd.get("en"),
                 sd.get("hi"), o.get("est_minutes"), o.get("cover_asset"),
                 o["order_no"], _jstr(o.get("tags")), _status(o)))
            pid = cur.lastrowid
            self.path_ids[o["slug"]] = pid
            self._stamp("learning_paths", pid, o)
            for s in o.get("steps") or []:
                st, bl = s.get("title") or {}, s.get("blurb") or {}
                self.db.execute(
                    """insert into path_steps
                       (path_id, step_no, title_en, title_hi, blurb_en, blurb_hi,
                        src, ref_table, ref_id, route, est_minutes, optional)
                       values (?,?,?,?,?,?,?,?,?,?,?,?)""",
                    (pid, s["step_no"], st.get("en"), st.get("hi"), bl.get("en"),
                     bl.get("hi"), s["src"], s["ref_table"], s["ref_id"],
                     s["route"], s.get("est_minutes"),
                     1 if s.get("optional") else 0))

    def _stamp(self, table: str, item_id: int, row: dict) -> None:
        name, ref, url, lv = self.link_sources(table, item_id, row)
        self.db.execute(
            f"""update {table} set primary_source_name=?, primary_source_ref=?,
                primary_source_url=?, last_verified_at=? where id=?""",
            (name, ref, url, lv, item_id))


# ---------------------------------------------------------------------------
# meta / SOURCES.md / dart stamp
# ---------------------------------------------------------------------------

def _qa_fold(q: dict) -> str:
    """Space-separated folded TOKENS of the question, in both languages.

    Two things this must get right, and the obvious implementation gets both
    wrong. Folding only the English question leaves every Hindi question
    permanently unmatchable while the table still looks fully populated -- a
    bilingual feature that is silently half dead. And fold() alone is the wrong
    tool: it strips whitespace, so a folded sentence collapses to one long
    run ('whatdoesthegitasayaboutfear') that no word-level match can touch.

    tokenize() is what the search index already uses, so a question folds here
    exactly as the same words fold there.
    """
    out: list[str] = []
    for lang in ("en", "hi"):
        for t in tokenize(q.get(lang) or ""):
            if t not in out:
                out.append(t)
    return " ".join(out)


def resolve_section_refs(refs: set[str]) -> dict[str, int]:
    """Map 'bhagavad-gita:2.47' to a scripture_sections id.

    Verse numbers are NOT unique on their own -- '2.47' matches ten rows across
    three scriptures, and twice within the Ramayana alone. A ref is therefore
    scoped by scripture slug, and anything that does not resolve to exactly one
    row is left unresolved rather than guessed at. A wrong "read in context"
    link is worse than none: it silently sends the reader to a different verse
    and tells them it is the source.
    """
    out: dict[str, int] = {}
    if not refs or not LEGACY_DB.exists():
        return out
    try:
        legacy = sqlite3.connect(f"file:{LEGACY_DB}?mode=ro", uri=True)
    except sqlite3.Error:
        return out
    try:
        for ref in refs:
            if ":" not in ref:
                continue
            slug, number = ref.split(":", 1)
            rows = legacy.execute(
                """select s.id from scripture_sections s
                   join scripture_books b on b.id = s.book_id
                   join scriptures sc on sc.id = b.scripture_id
                   where sc.slug = ? and s.number = ?""",
                (slug.strip(), number.strip())).fetchall()
            if len(rows) == 1:
                out[ref] = rows[0][0]
    finally:
        legacy.close()
    return out


def write_gzip(db_path) -> None:
    """Write the gzipped twin of the built database.

    pubspec bundles only the .gz, so this is not an optimisation step that can
    be skipped -- a build that does not run it ships a stale database to the
    app. Emitted here, next to the file it compresses, so the two cannot drift.
    """
    import gzip
    raw = db_path.read_bytes()
    out = db_path.with_suffix(db_path.suffix + ".gz")
    out.write_bytes(gzip.compress(raw, 9))
    print(f"  gzip {out.name}  ({len(raw)/1e6:.1f} MB -> "
          f"{out.stat().st_size/1e6:.1f} MB)")


def write_meta(db: sqlite3.Connection, version: str, strict: bool,
               counts: dict[str, int]) -> None:
    indexed = None
    if LEGACY_DB.exists():
        try:
            legacy = sqlite3.connect(f"file:{LEGACY_DB}?mode=ro", uri=True)
            indexed = dict(legacy.execute("select key,value from meta")).get(
                "content_version")
            legacy.close()
        except sqlite3.Error:
            pass

    meta = {
        "content_version": version,
        "schema_version": "1",
        "built_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "build_profile": "release" if strict else "dev",
        "indexed_content_version": indexed or "",
    }
    for table in ("sources", "entities", "entity_aliases", "relations",
                  "cosmology_nodes", "narrative_nodes", "dharma_scenarios",
                  "vidya_topics", "festivals", "qa_pairs", "journal_prompts",
                  "learning_paths", "path_steps", "search_docs",
                  "search_tokens", "related_edges"):
        n = db.execute(f"select count(*) from {table}").fetchone()[0]
        meta[f"{table}_count"] = str(n)
    meta["unverified_count"] = str(sum(
        db.execute(f"select count(*) from {t} where verification_status!='verified'"
                   ).fetchone()[0]
        for t in ("entities", "cosmology_nodes", "narrative_nodes",
                  "dharma_scenarios", "vidya_topics", "festivals", "qa_pairs",
                  "journal_prompts", "learning_paths")))

    db.executemany("insert or replace into meta (key,value) values (?,?)",
                   [(k, str(v)) for k, v in meta.items()])
    return meta


def write_sources_md(db: sqlite3.Connection, version: str) -> None:
    """Generated, never hand-edited -- so it cannot drift from the DB.
    Section 5 doubles as the in-app attribution block (Play compliance)."""
    rows = db.execute(
        """select s.slug, s.source_name, s.source_type, s.source_language,
                  s.edition, s.source_url, s.license_or_usage_note, s.retrieved_at,
                  count(i.item_id) as n
           from sources s left join item_sources i on i.source_id = s.id
           group by s.id order by s.source_type, s.source_name""").fetchall()

    cited = db.execute("select count(distinct item_table||':'||item_id) "
                       "from item_sources").fetchone()[0]

    out: list[str] = [
        "# Content Sources", "",
        "> Generated by `content/tools/build.py` — do not edit by hand.", "",
        f"Build `{version}` · {datetime.now(timezone.utc):%Y-%m-%d} · "
        f"{len(rows)} sources · {cited} cited items", "",
    ]
    titles = {"primary": "1. Primary sources", "secondary": "2. Secondary sources",
              "reference": "3. Reference sources", "ai_summary": "4. AI-assisted"}
    for stype, heading in titles.items():
        group = [r for r in rows if r[2] == stype]
        if not group:
            continue
        out += [f"## {heading}", ""]
        for slug, name, _t, lang, edition, url, lic, retrieved, n in group:
            out += [f"### {name}", ""]
            bits = [f"`{slug}`", f"type: {stype}"]
            if lang:
                bits.append(f"language: {lang}")
            if retrieved:
                bits.append(f"retrieved: {retrieved}")
            out.append("- " + " · ".join(bits))
            if edition:
                out.append(f"- Edition: {edition}")
            if url:
                out.append(f"- URL: {url}")
            out.append(f"- Licence: {lic}")
            out.append(f"- Cited by **{n}** item(s)")
            out.append("")

    out += ["## 5. Excluded sources", "",
            "| Source | Reason | Note |", "|---|---|---|"]
    for _l, o in read_jsonl(SOURCES_DIR / "excluded.jsonl"):
        note = (o.get("note") or "").replace("|", "\\|")
        out.append(f"| {o.get('name', o['domain'])} | {o.get('reason')} | {note} |")

    out += ["", "## 6. Attribution", "",
            "<!-- rendered verbatim in the app's About screen -->", ""]
    for slug, name, _t, _lang, edition, url, lic, _r, n in rows:
        if n:
            out.append(f"- **{name}**{f' ({edition})' if edition else ''} — {lic}")
    out.append("")

    (CONTENT_DIR / "SOURCES.md").write_text("\n".join(out), encoding="utf-8")


def stamp_dart(version: str) -> bool:
    if not DART_DB_FILE.exists():
        return False
    src = DART_DB_FILE.read_text(encoding="utf-8")
    new, n = BUILD_STAMP_RE.subn(rf"\g<1>{version}\g<2>", src)
    if n and new != src:
        DART_DB_FILE.write_text(new, encoding="utf-8")
    return bool(n)


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Build assets/db/gyan.sqlite")
    ap.add_argument("--strict", action="store_true",
                    help="release: refuse unverified content and placeholder assets")
    ap.add_argument("--allow-unverified", action="store_true",
                    help="dev (default): emit unverified rows, stamp build_profile=dev")
    ap.add_argument("--modules", default="",
                    help="comma-separated module ids for a partial rebuild")
    ap.add_argument("--skip-validate", action="store_true",
                    help="escape hatch; never use in a release build")
    args = ap.parse_args(argv)

    strict = args.strict
    modules = {m.strip() for m in args.modules.split(",") if m.strip()} or None

    if not args.skip_validate:
        # The stale-index check is skipped here on purpose: this run is what
        # regenerates the index it would be complaining about.
        rep = validate.run(strict=strict, skip_index_check=True)
        for f in rep.errors:
            print(f)
        if rep.errors:
            print(f"\nbuild ABORTED: {len(rep.errors)} validation error(s)")
            return 1

    ASSETS_DB_DIR.mkdir(parents=True, exist_ok=True)
    if GYAN_DB.exists():
        GYAN_DB.unlink()

    version = f"{SEMVER}+{datetime.now(timezone.utc):%Y%m%d}.{_git_sha()}"

    db = sqlite3.connect(GYAN_DB)
    try:
        db.execute("PRAGMA foreign_keys=ON")
        b = Builder(db, strict, modules)
        b.apply_schema()
        b.insert_sources()
        b.insert_entities()
        b.insert_relations()
        b.insert_cosmology()
        b.insert_narrative()
        b.insert_dharma()
        b.insert_vidya()
        b.insert_festivals()
        b.insert_qa()
        b.insert_journal()
        b.insert_paths()
        db.commit()

        # Optional stages -- these land in Phase 1 (P1-01 / P1-15).
        for stage in ("index", "relate"):
            try:
                mod = __import__(f"content.tools.{stage}", fromlist=["build_into"])
            except ImportError:
                print(f"note: content/tools/{stage}.py not present yet — skipped")
                continue
            mod.build_into(db)
            db.commit()

        meta = write_meta(db, version, strict, b.counts)
        db.commit()
        write_sources_md(db, version)

        db.execute("PRAGMA journal_mode=DELETE")
        db.commit()
        ok = db.execute("PRAGMA integrity_check").fetchone()[0]
        if ok != "ok":
            print(f"integrity_check FAILED: {ok}")
            return 1
        db.isolation_level = None
        db.execute("VACUUM")
    finally:
        db.close()

    stamped = stamp_dart(version)
    write_gzip(GYAN_DB)
    # The legacy fixture is not built here, but it IS shipped gzipped, and a
    # stale .gz would ship yesterday's content with today's index.
    if LEGACY_DB.exists():
        write_gzip(LEGACY_DB)

    size_mb = GYAN_DB.stat().st_size / (1024 * 1024)
    print(f"\nbuilt {GYAN_DB.relative_to(REPO_ROOT)}  "
          f"({size_mb:.2f} MB, profile={meta['build_profile']})")
    print(f"version {version}")
    if b.skipped_unverified:
        print(f"skipped {b.skipped_unverified} unverified row(s) (--strict)")
    for k in ("sources_count", "entities_count", "relations_count",
              "search_docs_count", "related_edges_count", "unverified_count"):
        print(f"  {k:<24} {meta.get(k, '0')}")
    print(f"  dart stamp               {'updated' if stamped else 'NOT FOUND'}")
    print(f"  SOURCES.md               regenerated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
