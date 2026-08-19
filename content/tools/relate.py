"""Stage 4c — precompute cross-module related content into gyan.sqlite.

Imported by build.py via `build_into(db)`.

Without this, every detail screen is a dead end. Open Hanuman and the app
already owns the Hanuman Chalisa, ~14 Hanuman temples, his mantras, his aarti
and his vrat kathas — none of it connected to anything.

Edges are PRECOMPUTED here rather than joined at runtime, for the same reason
the search index is: `related_edges` carries a denormalized title and route, so
a whole rail renders from one indexed query with no cross-database join and no
N+1 lookups.

Like index.py, this reads content.sqlite READ-ONLY and writes only into
gyan.sqlite, which is how the legacy corpus gets connected without touching it.

Rules are deterministic — no model, no randomness — so a rebuild produces
byte-identical edges and a bad recommendation is reproducible and fixable.
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import LEGACY_DB, fold, tokenize  # noqa: E402

# Per-source cap. Beyond a dozen the rail stops being a recommendation and
# becomes a second search results page.
MAX_EDGES_PER_SOURCE = 12
MIN_WEIGHT = 0.3

# Per-KIND cap within one rail.
#
# Without it the cap is spent by whichever kind simply has the most rows.
# Shiva's rail came out as twelve temples and nothing else -- no chalisa, no
# mantra, no Maha Shivratri -- because temples outnumber everything and every
# deity-name edge carries the same weight, so ordering within that weight was
# arbitrary. The rail is supposed to show that the app connects, and a wall of
# one kind shows the opposite on the most important entity we have.
MAX_EDGES_PER_KIND = 4

# Deity-name matching is the backbone of legacy linking, and Sanskrit epithets
# collide badly: "Devi", "Mata", "Bhagwan", "Ishwar" and friends are shared by
# dozens of figures. Matching on them would wire Durga's aarti onto a minor
# river goddess. They are refused outright rather than down-weighted -- a wrong
# recommendation is far more visible to a user than a missing one.
AMBIGUOUS_DEITY_TOKENS = {
    "devi", "mata", "maa", "ma", "bhagwan", "bhagavan", "ishwar", "ishvar",
    "prabhu", "swami", "sri", "shri", "shree", "lord", "goddess", "god",
    "dev", "deva", "bhagwati", "thakur", "baba", "ji",
}


class Relator:
    def __init__(self, db: sqlite3.Connection):
        self.db = db
        # (src, table, id) -> list of candidate edges
        self.edges: dict[tuple, list[tuple]] = defaultdict(list)
        self.reasons: dict[str, int] = defaultdict(int)

    # -- helpers -----------------------------------------------------------

    @staticmethod
    def deity_tokens(raw: str | None) -> set[str]:
        """Usable match tokens from a free-text deity field.

        The legacy `deity` columns are prose: "Lord Vishnu (Satyanarayan),
        Lord Shiva & Goddess Parvati". Split, fold, and drop the honorifics and
        generic epithets that would create false links.
        """
        if not raw:
            return set()
        out: set[str] = set()
        for part in raw.replace("&", ",").split(","):
            for word in part.split():
                f = fold(word.strip("()"))
                if len(f) >= 4 and f not in AMBIGUOUS_DEITY_TOKENS:
                    out.add(f)
        return out

    def add(self, src_key: tuple, dst_key: tuple, *, dst_kind: str,
            reason: str, weight: float, title_en: str, title_hi: str | None,
            subtitle_en: str | None, subtitle_hi: str | None,
            route: str) -> None:
        if weight < MIN_WEIGHT or src_key == dst_key or not title_en:
            return
        self.edges[src_key].append(
            (dst_key, dst_kind, reason, weight, title_en, title_hi,
             subtitle_en, subtitle_hi, route))
        self.reasons[reason] += 1

    # -- legacy <-> legacy, by deity --------------------------------------

    def link_legacy_by_deity(self, legacy: sqlite3.Connection) -> None:
        """Everything that names the same deity becomes mutually related.

        This is the single highest-value rule available today: it connects
        temples, aartis, chalisas, mantras, puja vidhi and vrat kathas that
        already ship, before a single new entity is authored.
        """
        tables = {r[0] for r in legacy.execute(
            "select name from sqlite_master where type='table'")}

        # (token) -> list of doc descriptors
        by_token: dict[str, list[dict]] = defaultdict(list)

        specs = [
            ("temples", "temple", "id, name_en, name_hi, deity_en, state",
             lambda r: f"/temple?id={r[0]}", 1.0),
            ("aartis", "aarti", "id, title_en, title_hi, deity, deity",
             lambda r: f"/read-lyrics?id={r[0]}&kind=aartis", 1.0),
            ("chalisas", "chalisa", "id, title_en, title_hi, deity, deity",
             lambda r: f"/read-lyrics?id={r[0]}&kind=chalisas", 1.0),
            ("mantras", "mantra", "id, title_en, title_hi, deity, deity",
             lambda r: f"/read-mantra?id={r[0]}", 1.0),
            ("puja_vidhi", "puja", "id, title_en, title_hi, deity, deity",
             lambda r: f"/puja-detail?id={r[0]}", 0.95),
            ("kathas", "katha", "id, title_en, title_hi, deity, deity",
             lambda r: f"/read-story?id={500000 + r[0]}&kind=katha", 0.95),
        ]

        for table, kind, cols, route_fn, base in specs:
            if table not in tables:
                continue
            for row in legacy.execute(f"select {cols} from {table}"):
                rid, ten, thi, deity, sub = row
                tokens = self.deity_tokens(deity)
                if not tokens:
                    continue
                doc = {
                    "key": ("content", table, rid),
                    "kind": kind,
                    "title_en": ten or "",
                    "title_hi": thi,
                    "subtitle_en": sub,
                    "subtitle_hi": sub,
                    "route": route_fn(row),
                    "base": base,
                    "tokens": tokens,
                }
                for t in tokens:
                    by_token[t].append(doc)

        for token, docs in by_token.items():
            # A token shared by hundreds of rows is not a useful signal -- it is
            # a generic word that slipped through the stoplist.
            if len(docs) > 60:
                continue
            for a in docs:
                for b in docs:
                    if a["key"] == b["key"]:
                        continue
                    # Same-kind links are less interesting than cross-kind ones:
                    # showing another temple under a temple is weaker than
                    # showing its aarti.
                    cross = 1.0 if a["kind"] != b["kind"] else 0.55
                    self.add(
                        a["key"], b["key"],
                        dst_kind=b["kind"],
                        reason=f"deity:{token}",
                        weight=0.9 * b["base"] * cross,
                        title_en=b["title_en"], title_hi=b["title_hi"],
                        subtitle_en=b["subtitle_en"], subtitle_hi=b["subtitle_hi"],
                        route=b["route"])

    # -- legacy stories by shared emotion ---------------------------------

    def link_stories_by_emotion(self, legacy: sqlite3.Connection) -> None:
        rows = list(legacy.execute(
            "select id, title_en, title_hi, emotions from stories"))
        by_emotion: dict[str, list[tuple]] = defaultdict(list)
        for rid, ten, thi, emotions in rows:
            for e in (emotions or "").split(","):
                e = e.strip().lower()
                if e:
                    by_emotion[e].append((rid, ten, thi, e))

        for emotion, group in by_emotion.items():
            if len(group) > 40:
                continue
            for rid, _ten, _thi, _e in group:
                for oid, oten, othi, _oe in group:
                    if oid == rid:
                        continue
                    self.add(
                        ("content", "stories", rid),
                        ("content", "stories", oid),
                        dst_kind="story", reason=f"emotion:{emotion}",
                        weight=0.45,
                        title_en=oten or "", title_hi=othi,
                        subtitle_en=emotion, subtitle_hi=emotion,
                        route=f"/read-story?id={oid}")

    # -- gyan entities -> everything --------------------------------------

    def link_festivals(self) -> None:
        """Entity to the festivals kept for it, both ways.

        Uses festivals.deity_entity_id, which is an explicit curated link --
        no name matching, so no epithet risk. §1.10 specified this rule and it
        was never implemented, which is why Hanuman had his temples and his
        chalisa on the rail but not Hanuman Jayanti.
        """
        rows = list(self.db.execute(
            """select f.id, f.title_en, f.title_hi, f.category,
                      e.id, e.title_en, e.title_hi, e.kind
               from festivals f join entities e on e.id = f.deity_entity_id"""))
        # Every deity link is equally true, so a flat weight leaves tie order
        # to chance -- which put a monthly vrat on Shiva's rail and left Maha
        # Shivratri off it. Category breaks the tie: the festival someone would
        # name first should be the one that survives the cap.
        by_category = {"major": 0.86, "jayanti": 0.83,
                       "vrat": 0.78, "regional": 0.76}
        for fid, ften, fthi, fcat, eid, eten, ethi, ekind in rows:
            w = by_category.get(fcat or "", 0.80)
            self.add(
                ("gyan", "entities", eid), ("gyan", "festivals", fid),
                dst_kind="festival", reason="festival_deity", weight=w,
                title_en=ften or "", title_hi=fthi,
                subtitle_en=fcat or "festival", subtitle_hi=fcat or "festival",
                route=f"/festivals/{fid}")
            self.add(
                ("gyan", "festivals", fid), ("gyan", "entities", eid),
                dst_kind="entity", reason="festival_deity", weight=w,
                title_en=eten or "", title_hi=ethi,
                subtitle_en=ekind, subtitle_hi=ekind,
                route=f"/gyan/entity/{eid}")

    def link_verses(self, legacy: sqlite3.Connection) -> None:
        """Verses to the figures named in them.

        The reader is the richest surface in the app and had no way out of
        itself: a verse knew nothing about the people in it. This is the rule
        that gives it one.

        It is also the noisiest rule in the file, so it is the most restricted:

        * Only entities of importance <= 2. A minor figure sharing a common
          name would otherwise attach itself to hundreds of verses.
        * Only `primary` aliases, never spellings or epithets. Epithets are
          exactly where Sanskrit names collide.
        * Word-boundary matching. Substring matching counted "Rama" inside
          "Parasurama" and "Chandramas" when this was first attempted by hand,
          and would do the same here.
        * At most 4 entities per verse, and a hard cap per entity, because a
          name like Krishna appears in hundreds of Gita verses and a rail
          showing 300 of them is a search results page, not a recommendation.

        Weight 0.5: a name appearing in a translation is real evidence, and
        weaker than a curated relation. The rail sorts by weight, so these sit
        below explicit links rather than displacing them.
        """
        tables = {r[0] for r in legacy.execute(
            "select name from sqlite_master where type='table'")}
        if "scripture_sections" not in tables:
            return

        # Only the figures worth surfacing, and only their primary name.
        majors: list[tuple[int, str, str, str | None]] = []
        for eid, ten, thi in self.db.execute(
                "select id, title_en, title_hi from entities "
                "where importance <= 2"):
            for (alias,) in self.db.execute(
                    "select alias from entity_aliases where entity_id=? "
                    "and alias_kind='primary' and lang='en'", (eid,)):
                f = fold(alias)
                if len(f) >= 4 and f not in AMBIGUOUS_DEITY_TOKENS:
                    majors.append((eid, f, ten or "", thi))

        if not majors:
            return

        per_entity: dict[int, int] = {}
        MAX_PER_ENTITY = 25

        rows = legacy.execute(
            "select s.id, s.book_id, s.body_en, b.title_en "
            "from scripture_sections s "
            "join scripture_books b on b.id = s.book_id "
            "where s.body_en is not null and length(s.body_en) > 40")

        for sid, book_id, body, book_title in rows:
            words = set(tokenize(body or ""))
            if not words:
                continue
            hits = 0
            for eid, f, ten, thi in majors:
                if f not in words:
                    continue
                if per_entity.get(eid, 0) >= MAX_PER_ENTITY:
                    continue
                hits += 1
                if hits > 4:
                    break
                per_entity[eid] = per_entity.get(eid, 0) + 1
                self.add(
                    ("content", "scripture_sections", sid),
                    ("gyan", "entities", eid),
                    dst_kind="entity", reason="named_in_verse", weight=0.50,
                    title_en=ten, title_hi=thi,
                    subtitle_en=book_title or "", subtitle_hi=book_title or "",
                    route=f"/gyan/entity/{eid}")

    def link_entities(self, legacy: sqlite3.Connection) -> None:
        """Entities to their own relations, and to legacy content by alias.

        Only `primary` and `epithet` aliases are used for legacy matching.
        A bare spelling variant is too weak a signal to justify wiring one
        deity's content onto another.
        """
        entities = list(self.db.execute(
            "select id, slug, kind, title_en, title_hi, category from entities"))
        if not entities:
            return

        # entity -> entity, via the typed relation graph
        for eid, _slug, _kind, _ten, _thi, _cat in entities:
            for (dst_id, rel, dten, dthi, dkind, dcat) in self.db.execute(
                    """select e2.id, r.rel_type, e2.title_en, e2.title_hi,
                              e2.kind, e2.category
                       from relations r join entities e2 on e2.id = r.dst_id
                       where r.src_id = ?""", (eid,)):
                self.add(
                    ("gyan", "entities", eid), ("gyan", "entities", dst_id),
                    dst_kind="entity", reason=f"relation:{rel}", weight=0.75,
                    title_en=dten or "", title_hi=dthi,
                    subtitle_en=dcat or dkind, subtitle_hi=dcat or dkind,
                    route=f"/gyan/entity/{dst_id}")

        # entity -> legacy content, by strong alias
        alias_map: dict[str, list[tuple[int, str, str | None]]] = defaultdict(list)
        for eid, _slug, _kind, ten, thi, _cat in entities:
            aliases = self.db.execute(
                "select alias, alias_kind from entity_aliases where entity_id=?",
                (eid,))
            for alias, akind in aliases:
                if akind not in ("primary", "epithet"):
                    continue
                f = fold(alias)
                if len(f) >= 4 and f not in AMBIGUOUS_DEITY_TOKENS:
                    alias_map[f].append((eid, ten or "", thi))

        tables = {r[0] for r in legacy.execute(
            "select name from sqlite_master where type='table'")}
        specs = [
            ("temples", "temple", "id, name_en, name_hi, deity_en",
             lambda r: f"/temple?id={r[0]}"),
            ("aartis", "aarti", "id, title_en, title_hi, deity",
             lambda r: f"/read-lyrics?id={r[0]}&kind=aartis"),
            ("chalisas", "chalisa", "id, title_en, title_hi, deity",
             lambda r: f"/read-lyrics?id={r[0]}&kind=chalisas"),
            ("mantras", "mantra", "id, title_en, title_hi, deity",
             lambda r: f"/read-mantra?id={r[0]}"),
        ]
        for table, kind, cols, route_fn in specs:
            if table not in tables:
                continue
            for row in legacy.execute(f"select {cols} from {table}"):
                rid, ten, thi, deity = row
                for token in self.deity_tokens(deity):
                    for eid, e_ten, e_thi in alias_map.get(token, []):
                        # entity -> content
                        self.add(
                            ("gyan", "entities", eid), ("content", table, rid),
                            dst_kind=kind, reason=f"alias:{token}", weight=0.9,
                            title_en=ten or "", title_hi=thi,
                            subtitle_en=deity, subtitle_hi=deity,
                            route=route_fn(row))
                        # content -> entity, so the rail works both ways
                        self.add(
                            ("content", table, rid), ("gyan", "entities", eid),
                            dst_kind="entity", reason=f"alias:{token}",
                            weight=0.85,
                            title_en=e_ten, title_hi=e_thi,
                            subtitle_en="Gyan", subtitle_hi="ज्ञान",
                            route=f"/gyan/entity/{eid}")

    # -- flush -------------------------------------------------------------

    def flush(self, routes: set[str]) -> int:
        def route_ok(route: str) -> bool:
            path = route.split("?", 1)[0]
            parts = path.split("/")
            for pattern in routes:
                p = pattern.split("/")
                if len(p) == len(parts) and all(
                        a.startswith(":") or a == b for a, b in zip(p, parts)):
                    return True
            return False

        rows = []
        skipped_route = 0
        for src_key, cands in self.edges.items():
            # Keep the strongest edge per destination, then the strongest N.
            best: dict[tuple, tuple] = {}
            for c in cands:
                dst_key = c[0]
                if dst_key not in best or c[3] > best[dst_key][3]:
                    best[dst_key] = c
            ordered = sorted(best.values(), key=lambda c: -c[3])

            kept = 0
            per_kind: dict[str, int] = {}
            for (dst_key, dst_kind, reason, weight, ten, thi, sen, shi,
                 route) in ordered:
                if kept >= MAX_EDGES_PER_SOURCE:
                    break
                if per_kind.get(dst_kind, 0) >= MAX_EDGES_PER_KIND:
                    continue
                if not route_ok(route):
                    skipped_route += 1
                    continue
                per_kind[dst_kind] = per_kind.get(dst_kind, 0) + 1
                rows.append((src_key[0], src_key[1], src_key[2],
                             dst_key[0], dst_key[1], dst_key[2],
                             dst_kind, reason, weight, ten, thi, sen, shi,
                             route))
                kept += 1

        self.db.executemany(
            """insert into related_edges
               (src_src, src_table, src_id, dst_src, dst_table, dst_id,
                dst_kind, reason, weight, title_en, title_hi,
                subtitle_en, subtitle_hi, route)
               values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)""", rows)
        if skipped_route:
            print(f"    skipped {skipped_route} edge(s): route not registered")
        return len(rows)


def _load_routes() -> set[str]:
    from content.tools.common import CONTENT_DIR
    f = CONTENT_DIR / "tools" / "routes.txt"
    if not f.exists():
        return set()
    return {ln.strip() for ln in f.read_text(encoding="utf-8").splitlines()
            if ln.strip() and not ln.startswith("#")}


def build_into(db: sqlite3.Connection) -> dict:
    routes = _load_routes()
    if not routes:
        print("  relate: routes.txt missing — skipped")
        return {}

    db.execute("delete from related_edges")

    r = Relator(db)
    if LEGACY_DB.exists():
        legacy = sqlite3.connect(f"file:{LEGACY_DB}?mode=ro", uri=True)
        try:
            r.link_legacy_by_deity(legacy)
            r.link_stories_by_emotion(legacy)
            r.link_entities(legacy)
            r.link_festivals()
            r.link_verses(legacy)
        finally:
            legacy.close()

    n = r.flush(routes)
    sources = db.execute(
        "select count(distinct src_src||src_table||src_id) from related_edges"
    ).fetchone()[0]
    print(f"  relate: {n} edges across {sources} source items")
    top = sorted(r.reasons.items(), key=lambda kv: -kv[1])[:5]
    for reason, cnt in top:
        print(f"    {reason:<24} {cnt}")
    return dict(r.reasons)


def main(argv: list[str] | None = None) -> int:
    from content.tools.common import GYAN_DB
    ap = argparse.ArgumentParser(description="Build related-content edges.")
    ap.add_argument("--show", metavar="TABLE:ID",
                    help="print the rail for one item, e.g. temples:12")
    args = ap.parse_args(argv)

    if not GYAN_DB.exists():
        print("error: gyan.sqlite not built — run content.tools.build")
        return 1
    db = sqlite3.connect(GYAN_DB)
    try:
        if args.show:
            table, _, rid = args.show.partition(":")
            for row in db.execute(
                    """select dst_kind, title_en, reason, round(weight,2), route
                       from related_edges
                       where src_table=? and src_id=?
                       order by weight desc""", (table, int(rid))):
                print("   ", row)
            return 0
        build_into(db)
        db.commit()
    finally:
        db.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
