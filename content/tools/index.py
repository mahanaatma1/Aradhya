"""Stage 4b — build the universal search index into gyan.sqlite.

Imported by build.py via `build_into(db)`; also runnable standalone for
measurement:

    py -m content.tools.index --dry-run

The important move: **content.sqlite is opened READ-ONLY and its rows are
indexed into gyan.sqlite**. That is what lets universal search span the 34k
rows of legacy content without modifying a database we have decided not to
touch. It also means the two files are coupled, which is why
`gyan.meta.indexed_content_version` exists and why validate.py fails the build
when they drift.

Not FTS5: sqflite uses the *system* SQLite, where FTS5 availability varies by
Android version and OEM. The expensive part — folding and alias expansion — has
to happen here for any backend, so the storage is a plain B-tree inverted index
that works everywhere. `SearchRepository` hides it; swapping to FTS5 later would
not touch the UI.
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import (  # noqa: E402
    CONTENT_DIR, LEGACY_DB, fold_variants, tokenize,
)

# Field weights, mirrored in SearchRepository.
F_TITLE, F_ALIAS, F_TAG, F_SUBTITLE, F_BODY = 0, 1, 2, 3, 4

# How many distinct body terms to index per document.
#
# Measured, not guessed: at 24 terms the 27,890 scripture verses produced
# 546,088 of the index's 572,405 postings -- 95% of the whole thing, for 0.6% of
# the searchable value. Verses get a tighter cap; everything else keeps the
# larger one because there are only a few thousand such rows in total.
#
# Stopwords are already dropped from bodies, so the first N terms of a verse are
# its content words, which is what people actually type.
MAX_BODY_TOKENS = 24
BODY_TOKEN_CAP = {"shloka": 10, "city": 0}


def body_cap(kind: str) -> int:
    return BODY_TOKEN_CAP.get(kind, MAX_BODY_TOKENS)

# Folded stopwords. Dropped from BODY only — a title like "The Ramayana" keeps
# its words, because a two-word title is mostly stopwords.
STOPWORDS = {
    "the", "and", "for", "with", "that", "this", "from", "you", "your", "who",
    "who", "was", "are", "his", "her", "its", "their", "them", "they", "has",
    "have", "had", "not", "but", "all", "one", "two", "who", "which", "when",
    "what", "into", "unto", "upon", "shall", "will", "may", "can", "own",
    "है", "हैं", "और", "का", "के", "की", "को", "में", "से", "पर", "यह", "वह",
    "एक", "भी", "तो", "ही", "कि", "जो", "था", "थे", "थी", "हो", "कर",
}


class Indexer:
    def __init__(self, db: sqlite3.Connection, routes: set[str]):
        self.db = db
        self.routes = routes
        self.doc_id = 0
        self.counts: dict[str, int] = {}
        self.skipped_routes: dict[str, int] = {}
        self.token_rows = 0
        # Term dictionary, built in memory and flushed once at the end. 21k
        # entries is nothing to hold, and it avoids a SELECT per token.
        self.terms: dict[str, int] = {}

    def term_id(self, token: str) -> int:
        tid = self.terms.get(token)
        if tid is None:
            tid = len(self.terms) + 1
            self.terms[token] = tid
        return tid

    def flush_terms(self) -> None:
        self.db.executemany(
            "insert into search_terms (id, token) values (?,?)",
            [(tid, tok) for tok, tid in self.terms.items()])

    # -- route gating ------------------------------------------------------

    def route_ok(self, route: str) -> bool:
        """A doc is only useful if tapping it goes somewhere.

        Modules whose screens have not landed yet (Phase 2+) are skipped rather
        than indexed with a dead link — a search result that opens GoRouter's
        error page is worse than no result at all.
        """
        path = route.split("?", 1)[0]
        parts = path.split("/")
        for pattern in self.routes:
            p = pattern.split("/")
            if len(p) != len(parts):
                continue
            if all(a.startswith(":") or a == b for a, b in zip(p, parts)):
                return True
        return False

    # -- writing -----------------------------------------------------------

    def add(self, *, src: str, kind: str, ref_table: str, ref_id: int,
            title_en: str, title_hi: str | None = None,
            subtitle_en: str | None = None, subtitle_hi: str | None = None,
            snippet_en: str | None = None, snippet_hi: str | None = None,
            route: str, boost: float = 1.0,
            aliases: list[str] | None = None,
            tags: list[str] | None = None,
            body: str | None = None) -> None:
        if not title_en or not title_en.strip():
            return
        if not self.route_ok(route):
            self.skipped_routes[kind] = self.skipped_routes.get(kind, 0) + 1
            return

        self.doc_id += 1
        did = self.doc_id
        self.db.execute(
            """insert into search_docs
               (doc_id, src, kind, ref_table, ref_id, title_en, title_hi,
                subtitle_en, subtitle_hi, snippet_en, snippet_hi, route, boost)
               values (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (did, src, kind, ref_table, ref_id, title_en.strip(), title_hi,
             subtitle_en, subtitle_hi, _snip(snippet_en), _snip(snippet_hi),
             route, boost))
        self.counts[kind] = self.counts.get(kind, 0) + 1

        seen: set[tuple[str, int]] = set()
        rows: list[tuple[int, int, int]] = []

        def emit(text: str | None, field: int, cap: int | None = None,
                 drop_stopwords: bool = False) -> None:
            if not text:
                return
            n = 0
            for tok in tokenize(text):
                if len(tok) < 2:
                    continue
                if drop_stopwords and tok in STOPWORDS:
                    continue
                key = (tok, field)
                if key in seen:
                    continue
                seen.add(key)
                rows.append((self.term_id(tok), did, field))
                n += 1
                if cap is not None and n >= cap:
                    return

        emit(title_en, F_TITLE)
        emit(title_hi, F_TITLE)
        for a in aliases or []:
            emit(a, F_ALIAS)
        for t in tags or []:
            emit(t, F_TAG)
        emit(subtitle_en, F_SUBTITLE)
        emit(subtitle_hi, F_SUBTITLE)
        emit(body, F_BODY, cap=body_cap(kind), drop_stopwords=True)

        self.db.executemany(
            "insert or ignore into search_tokens (term_id, doc_id, field) "
            "values (?,?,?)",
            rows)
        self.token_rows += len(rows)

    # -- gyan (new content) ------------------------------------------------

    def index_gyan(self) -> None:
        for row in self.db.execute(
                """select id, slug, kind, title_en, title_hi, category,
                          short_description_en, short_description_hi, importance,
                          tags
                   from entities"""):
            (eid, slug, kind, ten, thi, cat, sden, sdhi, importance,
             _tags) = row
            aliases = [r[0] for r in self.db.execute(
                "select alias from entity_aliases where entity_id=?", (eid,))]
            self.add(
                src="gyan", kind="entity", ref_table="entities", ref_id=eid,
                title_en=ten, title_hi=thi,
                subtitle_en=cat or kind, subtitle_hi=cat or kind,
                snippet_en=sden, snippet_hi=sdhi,
                route=f"/gyan/entity/{eid}",
                # importance 1 (major) -> 1.6, 5 (minor) -> 0.8, so Hanuman
                # outranks a minor gandharva for the query "han".
                boost=1.8 - 0.2 * (importance or 3),
                aliases=aliases,
                tags=[kind],
            )

        for row in self.db.execute(
                """select id, title_en, title_hi, region, short_description_en,
                          short_description_hi from festivals"""):
            fid, ten, thi, region, sden, sdhi = row
            self.add(src="gyan", kind="festival", ref_table="festivals",
                     ref_id=fid, title_en=ten, title_hi=thi,
                     subtitle_en=region, subtitle_hi=region,
                     snippet_en=sden, snippet_hi=sdhi,
                     route=f"/festivals/{fid}", boost=1.2)

        for row in self.db.execute(
                """select id, epic, title_en, title_hi, book_label_en,
                          short_description_en, short_description_hi
                   from narrative_nodes"""):
            nid, epic, ten, thi, book, sden, sdhi = row
            self.add(src="gyan", kind="scene", ref_table="narrative_nodes",
                     ref_id=nid, title_en=ten, title_hi=thi,
                     subtitle_en=book, subtitle_hi=book,
                     snippet_en=sden, snippet_hi=sdhi,
                     route=f"/gyan/scene/{nid}", tags=[epic])

    # -- legacy (content.sqlite, read-only) --------------------------------

    def index_legacy(self, legacy: sqlite3.Connection) -> None:
        tables = {r[0] for r in legacy.execute(
            "select name from sqlite_master where type='table'")}

        def has(t: str) -> bool:
            return t in tables

        if has("temples"):
            for (tid, ten, thi, den, dhi, state, sig) in legacy.execute(
                    """select id, name_en, name_hi, deity_en, deity_hi, state,
                              significance_en from temples"""):
                self.add(src="content", kind="temple", ref_table="temples",
                         ref_id=tid, title_en=ten, title_hi=thi,
                         subtitle_en=den, subtitle_hi=dhi,
                         snippet_en=sig, route=f"/temple?id={tid}",
                         boost=1.3, tags=[d for d in (den, state) if d])

        if has("mantras"):
            for (mid, ten, thi, deity, tr_en, tr_hi) in legacy.execute(
                    """select id, title_en, title_hi, deity, translation_en,
                              translation_hi from mantras"""):
                self.add(src="content", kind="mantra", ref_table="mantras",
                         ref_id=mid, title_en=ten, title_hi=thi,
                         subtitle_en=deity, subtitle_hi=deity,
                         snippet_en=tr_en, snippet_hi=tr_hi,
                         route=f"/read-mantra?id={mid}", boost=1.2,
                         tags=[deity] if deity else None)

        for table, kind in (("aartis", "aarti"), ("chalisas", "chalisa")):
            if not has(table):
                continue
            for (rid, ten, thi, deity, len_, lhi) in legacy.execute(
                    f"select id, title_en, title_hi, deity, lyrics_en, lyrics_hi "
                    f"from {table}"):
                self.add(src="content", kind=kind, ref_table=table, ref_id=rid,
                         title_en=ten, title_hi=thi,
                         subtitle_en=deity, subtitle_hi=deity,
                         snippet_en=len_, snippet_hi=lhi,
                         route=f"/read-lyrics?id={rid}&kind={table}",
                         boost=1.2, tags=[deity] if deity else None,
                         body=len_)

        if has("stories"):
            for (sid, ten, thi, emotions, ben, bhi) in legacy.execute(
                    "select id, title_en, title_hi, emotions, body_en, body_hi "
                    "from stories"):
                tags = [e.strip() for e in (emotions or "").split(",") if e.strip()]
                self.add(src="content", kind="story", ref_table="stories",
                         ref_id=sid, title_en=ten, title_hi=thi,
                         snippet_en=ben, snippet_hi=bhi,
                         route=f"/read-story?id={sid}", tags=tags, body=ben)

        if has("kathas"):
            for (kid, ten, thi, deity, ben, bhi) in legacy.execute(
                    "select id, title_en, title_hi, deity, body_en, body_hi "
                    "from kathas"):
                self.add(src="content", kind="katha", ref_table="kathas",
                         ref_id=kid, title_en=ten, title_hi=thi,
                         subtitle_en=deity, subtitle_hi=deity,
                         snippet_en=ben, snippet_hi=bhi,
                         # Ids are offset in Dart (Story.kathaIdOffset) so a
                         # katha and a story never collide in `extra`.
                         route=f"/read-story?id={500000 + kid}&kind=katha",
                         tags=[deity] if deity else None, body=ben)

        if has("puja_vidhi"):
            for (pid, ten, thi, deity, when_en) in legacy.execute(
                    "select id, title_en, title_hi, deity, when_en from puja_vidhi"):
                self.add(src="content", kind="puja", ref_table="puja_vidhi",
                         ref_id=pid, title_en=ten, title_hi=thi,
                         subtitle_en=deity, subtitle_hi=deity,
                         snippet_en=when_en, route=f"/puja-detail?id={pid}",
                         tags=[deity] if deity else None)

        if has("scripture_sections") and has("scripture_books"):
            books = {r[0]: (r[1], r[2]) for r in legacy.execute(
                "select id, title_en, title_hi from scripture_books")}
            for (sid, book_id, number, ben, bhi, sans) in legacy.execute(
                    """select id, book_id, number, body_en, body_hi, sanskrit
                       from scripture_sections"""):
                btitle_en, btitle_hi = books.get(book_id, (None, None))
                label_en = f"{btitle_en or 'Verse'} {number}".strip()
                label_hi = f"{btitle_hi or ''} {number}".strip() or None
                # 27,890 rows dominate the asset, so only a short English
                # snippet is stored. The Hindi body and the full text are one
                # join away in main.scripture_sections at render time -- both
                # databases are on the same connection, so duplicating the text
                # here would buy nothing but megabytes.
                self.add(src="content", kind="shloka",
                         ref_table="scripture_sections", ref_id=sid,
                         title_en=label_en, title_hi=label_hi,
                         snippet_en=_snip(ben, 90),
                         route=f"/scriptures/book/{book_id}?v={sid}",
                         boost=0.9, body=ben)

        if has("cities"):
            # Indexed so the birth-place picker can do substring/alias matching
            # instead of `name LIKE 'q%'`, which made "Navi Mumbai" unreachable
            # by typing "mumbai" (G6). Filtered out of general search by kind.
            for (cid, name, state, country) in legacy.execute(
                    "select id, name, state, country from cities"):
                # No snippet: the subtitle already carries state + country,
                # and these 4,276 rows exist for the birth-place picker rather
                # than for reading.
                self.add(src="content", kind="city", ref_table="cities",
                         ref_id=cid, title_en=name,
                         subtitle_en=", ".join(x for x in (state, country) if x),
                         route=f"/astrology?city={cid}", boost=0.5)


def _snip(text: str | None, n: int = 140) -> str | None:
    if not text:
        return None
    t = " ".join(text.split())
    return t if len(t) <= n else t[: n - 1] + "…"


def _load_routes() -> set[str]:
    f = CONTENT_DIR / "tools" / "routes.txt"
    if not f.exists():
        return set()
    return {ln.strip() for ln in f.read_text(encoding="utf-8").splitlines()
            if ln.strip() and not ln.startswith("#")}


def build_into(db: sqlite3.Connection) -> dict:
    """Called by build.py once content rows are in place."""
    routes = _load_routes()
    if not routes:
        print("  index: routes.txt missing — run the Dart route-export test; "
              "skipping index")
        return {}

    db.execute("delete from search_tokens")
    db.execute("delete from search_terms")
    db.execute("delete from search_docs")

    ix = Indexer(db, routes)
    ix.index_gyan()

    if LEGACY_DB.exists():
        legacy = sqlite3.connect(f"file:{LEGACY_DB}?mode=ro", uri=True)
        try:
            ix.index_legacy(legacy)
            version = dict(legacy.execute("select key,value from meta")).get(
                "content_version", "")
        finally:
            legacy.close()
        db.execute("insert or replace into meta (key,value) values (?,?)",
                   ("indexed_content_version", version))

    ix.flush_terms()
    total = sum(ix.counts.values())
    print(f"  index: {total} docs, {ix.token_rows} postings, "
          f"{len(ix.terms)} distinct terms")
    for kind, n in sorted(ix.counts.items(), key=lambda kv: -kv[1]):
        print(f"    {kind:<10} {n}")
    if ix.skipped_routes:
        print("    skipped (route not registered yet): "
              + ", ".join(f"{k}×{v}" for k, v in ix.skipped_routes.items()))
    return ix.counts


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Build the search index.")
    ap.add_argument("--dry-run", action="store_true",
                    help="index into an in-memory DB just to measure size")
    args = ap.parse_args(argv)

    from content.tools.common import GYAN_DB, SCHEMA_DIR
    if args.dry_run:
        db = sqlite3.connect(":memory:")
        db.executescript((SCHEMA_DIR / "gyan.sql").read_text(encoding="utf-8"))
    else:
        if not GYAN_DB.exists():
            print("error: gyan.sqlite not built yet — run content.tools.build")
            return 1
        db = sqlite3.connect(GYAN_DB)
    try:
        build_into(db)
        db.commit()
    finally:
        db.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
