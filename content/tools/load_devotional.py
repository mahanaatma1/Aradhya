"""Load our own mantras and devotional lyrics into gyan.sqlite.

RG-01, the devotional tables. Unlike the kathas, most of what ships here was
never Ishvarvaani's to own: the Hanuman Chalisa is Tulsidas c.1600 and the
Mahamrityunjaya is Rigveda. What the fixture owned was its *transcription* --
its romanisation, line breaks and repeat markers -- plus, on mantras, the
translation, summary and how-to-chant prose.

So the distinctness gate applies only to the authored prose. Running it against
`lyrics_hi` would be nonsense: ours and theirs are the same public-domain words,
and a high score there is proof the text is right, not proof of copying.

    py -m content.tools.load_devotional check
    py -m content.tools.load_devotional load
"""

from __future__ import annotations

import json
import sqlite3
import sys
from difflib import SequenceMatcher
from pathlib import Path

from .legal_own import STOPWORDS, _words

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "assets" / "db" / "content.sqlite"
GYAN = ROOT / "assets" / "db" / "gyan.sqlite"
WORK = ROOT / "content" / "legal" / "work"

MAX_RATIO = 0.50
# Below this many expressive words a ratio means nothing: "I bow to Krishna" and
# "Salutations to Lord Krishna" are the same three-word mantra faithfully
# rendered twice, and the only way to score lower is to translate it worse.
# legal_own.py draws the same line at MIN_N for the same reason.
MIN_N = 8
MIN_HI_RATIO = 0.60
# Proper names and one-word type labels cannot be padded to a length ratio --
# "गणेश" is simply shorter than "Ganesha" -- so the ratio rule applies to prose
# fields only.
PROSE_PAIRS = ("translation", "summary", "how_to_chant")

MANTRA_COLS = (
    "slug", "legacy_id", "title_en", "title_hi", "deity_en", "deity_hi",
    "type_en", "type_hi", "sanskrit", "iast", "translation_en", "translation_hi",
    "summary_en", "summary_hi", "how_to_chant_en", "how_to_chant_hi", "order_no",
    "primary_source_name", "primary_source_ref", "primary_source_url",
    "last_verified_at", "verification_status", "claim_type", "source_quality",
)
LYRIC_COLS = (
    "slug", "legacy_id", "kind", "title_en", "title_hi", "deity_en", "deity_hi",
    "lyrics_hi", "lyrics_en", "summary_en", "summary_hi", "order_no",
    "primary_source_name", "primary_source_ref", "last_verified_at",
    "verification_status", "claim_type", "source_quality",
)


def _score(mine: str, theirs: str) -> tuple[float, int]:
    a = [w for w in _words(mine) if w not in STOPWORDS]
    b = [w for w in _words(theirs) if w not in STOPWORDS]
    if not a or not b:
        return 0.0, 0
    return SequenceMatcher(None, a, b, autojunk=False).ratio(), len(a)


def _load(name: str) -> list[dict]:
    path = WORK / f"{name}.json"
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))["rows"]


def _gate() -> bool:
    fx = sqlite3.connect(FIXTURE)
    ok = True
    for row in _load("mantras"):
        problems = []
        old = fx.execute(
            "SELECT translation_en, summary_en, how_to_chant_en FROM mantras "
            "WHERE id = ?", (row.get("legacy_id"),)
        ).fetchone() if row.get("legacy_id") else None

        if old:
            for field, theirs in zip(PROSE_PAIRS, old):
                mine = row.get(f"{field}_en") or ""
                if not (mine and theirs):
                    continue
                ratio, n = _score(mine, theirs)
                # A short string cannot be scored; see MIN_N above.
                if ratio > MAX_RATIO and n >= MIN_N:
                    problems.append(f"{field}_en ratio {ratio:.2f} over {n} words")

        for field in PROSE_PAIRS:
            en, hi = row.get(f"{field}_en"), row.get(f"{field}_hi")
            if en and not hi:
                problems.append(f"{field}_en has no _hi")
            elif en and hi and len(hi) / len(en) < MIN_HI_RATIO:
                problems.append(f"{field} hi/en {len(hi)/len(en):.2f}")
        if not (row.get("sanskrit") or "").strip():
            problems.append("empty sanskrit")

        print(f"  {'FAIL' if problems else 'ok  '}  mantra {row['slug']}")
        for p in problems:
            print(f"          {p}")
        ok &= not problems

    for row in _load("devotional_lyrics"):
        problems = []
        # lyrics_* are deliberately NOT scored: the words are public domain and
        # identical by design. Only the summary is ours.
        for field in ("summary",):
            en, hi = row.get(f"{field}_en"), row.get(f"{field}_hi")
            if en and not hi:
                problems.append(f"{field}_en has no _hi")
        if not (row.get("lyrics_hi") or "").strip():
            problems.append("empty lyrics_hi")
        print(f"  {'FAIL' if problems else 'ok  '}  {row['kind']} {row['slug']}")
        for p in problems:
            print(f"          {p}")
        ok &= not problems
    return ok


def load() -> None:
    mantras, lyrics = _load("mantras"), _load("devotional_lyrics")
    print(f"{len(mantras)} mantra(s), {len(lyrics)} lyric(s) staged\n")
    if not _gate():
        sys.exit("\ngates failed -- nothing written")

    conn = sqlite3.connect(GYAN)
    for table, cols, rows in (("mantras", MANTRA_COLS, mantras),
                              ("devotional_lyrics", LYRIC_COLS, lyrics)):
        if not rows:
            continue
        sql = (f"INSERT OR REPLACE INTO {table} ({','.join(cols)}) "
               f"VALUES ({','.join('?' * len(cols))})")
        conn.executemany(sql, [[r.get(c) for c in cols] for r in rows])
    conn.commit()
    for table in ("mantras", "devotional_lyrics"):
        n = conn.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        print(f"{table}: {n} row(s)")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "load":
        load()
    else:
        m, l = _load("mantras"), _load("devotional_lyrics")
        print(f"{len(m)} mantra(s), {len(l)} lyric(s) staged\n")
        sys.exit(0 if _gate() else 1)
