"""Load our own stories and puja procedures into gyan.sqlite.

RG-01, the last two prose tables. Same three gates as the kathas -- distinctness
against the fixture row each one replaces, bilingual coverage, and length -- for
the same reasons, plus one more that these tables specifically need:

  * CONTROLLED TAGS. The fixture's `stories.emotions` was one English-only
    free-text column carrying 57 distinct tags, 40 of them used exactly once
    ("absorption", "exchange", "validation"). Filter chips built on that are
    unusable and untranslatable. Rows here must draw from EMOTIONS below, so the
    chip set stays finite and every chip has a Hindi label.

    py -m content.tools.load_stories check
    py -m content.tools.load_stories load
"""

from __future__ import annotations

import json
import sqlite3
import sys
from difflib import SequenceMatcher
from pathlib import Path

from .legal_own import STOPWORDS, _longest_run, _words

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "assets" / "db" / "content.sqlite"
GYAN = ROOT / "assets" / "db" / "gyan.sqlite"
WORK = ROOT / "content" / "legal" / "work"

MAX_RATIO = 0.50
MAX_RUN = 5
MIN_HI_RATIO = 0.60

# The whole controlled vocabulary, English -> Hindi. Twelve tags instead of the
# fixture's 57: enough to filter usefully, few enough that every chip is worth
# tapping and every one is translated.
EMOTIONS = {
    "anger": "क्रोध", "fear": "भय", "faith": "श्रद्धा", "love": "प्रेम",
    "peace": "शांति", "joy": "आनंद", "grief": "शोक", "courage": "साहस",
    "devotion": "भक्ति", "wisdom": "विवेक", "sacrifice": "त्याग",
    "forgiveness": "क्षमा",
}

STORY_COLS = (
    "slug", "legacy_id", "title_en", "title_hi", "summary_en", "summary_hi",
    "body_en", "body_hi", "moral_en", "moral_hi", "reflection_en",
    "reflection_hi", "key_moments_en", "key_moments_hi", "emotions_en",
    "emotions_hi", "themes_en", "themes_hi", "characters_en", "characters_hi",
    "entity_slugs", "scripture_ref", "order_no", "primary_source_name",
    "primary_source_ref", "primary_source_url", "last_verified_at",
    "verification_status", "claim_type", "source_quality",
)
PUJA_COLS = (
    "slug", "legacy_id", "title_en", "title_hi", "deity_en", "deity_hi",
    "category_en", "category_hi", "when_en", "when_hi", "duration_en",
    "duration_hi", "preparation_en", "preparation_hi", "items_en", "items_hi",
    "vidhi_en", "vidhi_hi", "key_mantras", "benefits_en", "benefits_hi",
    "significance_en", "significance_hi", "common_mistakes_en",
    "common_mistakes_hi", "regional_variations_en", "regional_variations_hi",
    "festival_slug", "order_no", "primary_source_name", "primary_source_ref",
    "last_verified_at", "verification_status", "claim_type", "source_quality",
)
JSON_COLS = {
    "key_moments_en", "key_moments_hi", "emotions_en", "emotions_hi",
    "themes_en", "themes_hi", "characters_en", "characters_hi", "entity_slugs",
    "deity_en", "deity_hi", "items_en", "items_hi", "vidhi_en", "vidhi_hi",
    "key_mantras",
}


def _rows(name: str) -> list[dict]:
    out = []
    for path in sorted(WORK.glob(f"{name}*.json")):
        out += json.loads(path.read_text(encoding="utf-8"))["rows"]
    return out


def _score(mine: str, theirs: str) -> tuple[float, int]:
    a = [w for w in _words(mine) if w not in STOPWORDS]
    b = [w for w in _words(theirs) if w not in STOPWORDS]
    if not a or not b:
        return 0.0, 0
    return SequenceMatcher(None, a, b, autojunk=False).ratio(), _longest_run(a, b)


def _bilingual(row: dict, fields: tuple[str, ...]) -> list[str]:
    problems = []
    for field in fields:
        en, hi = row.get(f"{field}_en"), row.get(f"{field}_hi")
        if en and not hi:
            problems.append(f"{field}_en has no _hi")
        elif isinstance(en, str) and isinstance(hi, str) and en and hi:
            if len(hi) / len(en) < MIN_HI_RATIO:
                problems.append(f"{field} hi/en {len(hi)/len(en):.2f}")
    return problems


def _gate() -> bool:
    fx = sqlite3.connect(FIXTURE)
    ok = True

    for row in _rows("stories"):
        problems = []
        if row.get("legacy_id"):
            old = fx.execute(
                "SELECT body_en, body_hi FROM stories WHERE id = ?",
                (row["legacy_id"],)).fetchone()
            if old:
                for lang, mine, theirs in (("en", row["body_en"], old[0]),
                                           ("hi", row["body_hi"], old[1])):
                    ratio, run = _score(mine, theirs)
                    if ratio > MAX_RATIO:
                        problems.append(f"{lang} ratio {ratio:.3f}")
                    if run > MAX_RUN:
                        problems.append(f"{lang} run {run}")
                if len(row["body_en"]) <= len(old[0]):
                    problems.append(
                        f"body_en {len(row['body_en'])} not longer than "
                        f"fixture {len(old[0])}")
        problems += _bilingual(row, ("title", "summary", "body", "moral",
                                     "reflection"))
        # Controlled vocabulary: an unknown tag means an untranslatable chip.
        tags = row.get("emotions_en") or []
        unknown = [t for t in tags if t not in EMOTIONS]
        if unknown:
            problems.append(f"emotions not in vocabulary: {unknown}")
        if not tags:
            problems.append("no emotions")
        hi_tags = row.get("emotions_hi") or []
        if len(hi_tags) != len(tags):
            problems.append("emotions_hi length differs from emotions_en")

        print(f"  {'FAIL' if problems else 'ok  '}  story {row['slug']}")
        for p in problems:
            print(f"          {p}")
        ok &= not problems

    for row in _rows("puja"):
        problems = []
        if row.get("legacy_id"):
            old = fx.execute(
                "SELECT vidhi_en FROM puja_vidhi WHERE id = ?",
                (row["legacy_id"],)).fetchone()
            if old and old[0]:
                mine = " ".join(row.get("vidhi_en") or [])
                ratio, run = _score(mine, old[0])
                if ratio > MAX_RATIO:
                    problems.append(f"vidhi ratio {ratio:.3f}")
        problems += _bilingual(row, ("title", "when", "benefits",
                                     "significance"))
        for field in ("items", "vidhi"):
            en, hi = row.get(f"{field}_en") or [], row.get(f"{field}_hi") or []
            if len(en) != len(hi):
                problems.append(f"{field}: {len(en)} en vs {len(hi)} hi")
        if not row.get("vidhi_en"):
            problems.append("no vidhi steps")

        print(f"  {'FAIL' if problems else 'ok  '}  puja {row['slug']}")
        for p in problems:
            print(f"          {p}")
        ok &= not problems
    return ok


def load() -> None:
    stories, pujas = _rows("stories"), _rows("puja")
    print(f"{len(stories)} story/ies, {len(pujas)} puja(s) staged\n")
    if not _gate():
        sys.exit("\ngates failed -- nothing written")

    conn = sqlite3.connect(GYAN)
    for table, cols, rows in (("stories", STORY_COLS, stories),
                              ("puja_vidhi", PUJA_COLS, pujas)):
        if not rows:
            continue
        sql = (f"INSERT OR REPLACE INTO {table} ({','.join(cols)}) "
               f"VALUES ({','.join('?' * len(cols))})")
        payload = []
        for r in rows:
            vals = []
            for c in cols:
                v = r.get(c)
                if c in JSON_COLS and v is not None and not isinstance(v, str):
                    v = json.dumps(v, ensure_ascii=False)
                vals.append(v)
            payload.append(vals)
        conn.executemany(sql, payload)
    conn.commit()
    for table in ("stories", "puja_vidhi"):
        n = conn.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        print(f"{table}: {n} row(s)")


QUOTE_COLS = (
    "legacy_id", "kind", "text_en", "text_hi", "sanskrit", "iast", "source_title_en",
    "source_title_hi", "verse_ref", "source_slug", "scripture_verse_number",
    "themes_en", "themes_hi", "order_no", "primary_source_name",
    "primary_source_ref", "last_verified_at", "verification_status",
    "claim_type", "source_quality",
)


def load_quotes() -> None:
    """Load `quotes`, which has no distinctness gate and does not need one.

    These are not rewrites of the fixture's English. Every row is either our own
    already-authored rendering of a verse, a line from a story we wrote, or a
    traditional saying -- so the text is ours or public domain by construction.
    What is worth checking is that each row is bilingual and carries an
    attribution, and that a row claiming to be a numbered verse actually has the
    number.
    """
    rows = _rows("quotes")
    print(f"{len(rows)} quote(s) staged")
    problems = 0
    for r in rows:
        bad = []
        if not (r.get("text_hi") or "").strip():
            bad.append("no text_hi")
        if not (r.get("text_en") or "").strip():
            bad.append("no text_en")
        # A proverb has no chapter and verse; only a 'verse' row must have one.
        if r.get("kind", "verse") == "verse" and not (r.get("verse_ref") or "").strip():
            bad.append("kind=verse but no verse_ref")
        if not (r.get("source_title_en") or "").strip():
            bad.append("no source_title_en")
        if bad:
            problems += 1
            print(f"  FAIL  {r.get('verse_ref')}: {bad}")
    if problems:
        sys.exit(f"{problems} quote(s) failed -- nothing written")

    conn = sqlite3.connect(GYAN)
    sql = (f"INSERT INTO quotes ({','.join(QUOTE_COLS)}) "
           f"VALUES ({','.join('?' * len(QUOTE_COLS))})")
    payload = []
    for r in rows:
        vals = []
        for col in QUOTE_COLS:
            v = r.get(col)
            if col in ("themes_en", "themes_hi") and v is not None and not isinstance(v, str):
                v = json.dumps(v, ensure_ascii=False)
            if col == "kind":
                v = v or "verse"
            vals.append(v)
        payload.append(vals)
    conn.executemany(sql, payload)
    conn.commit()
    n = conn.execute("SELECT count(*) FROM quotes").fetchone()[0]
    print(f"quotes: {n} row(s)")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "quotes":
        load_quotes()
    elif len(sys.argv) > 1 and sys.argv[1] == "load":
        load()
    else:
        s, p = _rows("stories"), _rows("puja")
        print(f"{len(s)} story/ies, {len(p)} puja(s) staged\n")
        sys.exit(0 if _gate() else 1)
