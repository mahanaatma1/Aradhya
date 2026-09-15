"""Load our own kathas into `gyan.kathas`, replacing the Ishvarvaani fixture.

Release gate RG-01: every creative string the app reads has to be ours. The
fixture's 57 kathas live in `main.kathas` (content.sqlite); ours live here, and
`legacy_id` records which fixture row each one retires so the swap is auditable
and reversible.

    py -m content.tools.load_kathas check    # gates only, writes nothing
    py -m content.tools.load_kathas load     # gates, then write to gyan.sqlite
    py -m content.tools.load_kathas status   # coverage against the fixture

`check` runs the same three gates `load` does, so a batch can be validated
before it is anywhere near the database:

  * DISTINCTNESS -- each body is scored against the fixture row it replaces,
    reusing legal_own.py's scorer. Ours are written from public-domain sources
    without opening the fixture, so these come back near zero; a high score
    means the writer drifted toward the fixture and the row needs looking at.
  * BILINGUAL -- every populated `_en` needs a populated `_hi`, and the Hindi
    has to be at least 60% of the English length. That ratio is what catches a
    stub translation of a full English paragraph (RG-01 bilingual rule).
  * LENGTH -- ours must be longer than the row it replaces. The fixture bodies
    are plot summaries; a replacement that is not substantially longer has not
    been enriched, whatever else it got right.
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

MAX_RATIO = 0.50          # same gate legal_own.py applies to scripture
MAX_RUN = 5
MIN_HI_RATIO = 0.60       # Hindi must be a full rendering, not a stub

# Columns written straight through. JSON-encoded list fields are handled
# separately below, since they arrive as Python lists.
SCALAR = (
    "slug", "legacy_id", "title_en", "title_hi", "festival_slug",
    "when_en", "when_hi", "summary_en", "summary_hi", "body_en", "body_hi",
    "vrat_vidhi_en", "vrat_vidhi_hi", "phala_en", "phala_hi",
    "moral_en", "moral_hi", "reflection_en", "reflection_hi", "order_no",
    "primary_source_name", "primary_source_ref", "primary_source_url",
    "last_verified_at", "verification_status", "claim_type", "source_quality",
)
LISTS = ("deity_en", "deity_hi", "entity_slugs",
         "key_moments_en", "key_moments_hi", "themes_en", "themes_hi")


def _batches() -> list[dict]:
    rows = []
    for path in sorted(WORK.glob("kathas_*.json")):
        rows += json.loads(path.read_text(encoding="utf-8"))["rows"]
    sample = WORK / "SAMPLE_katha_41_vat_savitri.json"
    if sample.exists():
        row = json.loads(sample.read_text(encoding="utf-8"))
        row.setdefault("legacy_id", 41)
        # The sample predates the batch shape and uses the older key names.
        row.setdefault("themes_en", row.get("themes"))
        row.setdefault("order_no", 50)
        row.setdefault("verification_status", "verified")
        rows.append(row)
    return rows


def _score(mine: str, theirs: str) -> tuple[float, int]:
    a = [w for w in _words(mine) if w not in STOPWORDS]
    b = [w for w in _words(theirs) if w not in STOPWORDS]
    if not a or not b:
        return 0.0, 0
    return SequenceMatcher(None, a, b, autojunk=False).ratio(), _longest_run(a, b)


def _gate(rows: list[dict]) -> bool:
    fx = sqlite3.connect(FIXTURE)
    ok = True
    for r in rows:
        problems = []
        old = fx.execute(
            "SELECT body_en, body_hi FROM kathas WHERE id = ?", (r["legacy_id"],)
        ).fetchone() if r.get("legacy_id") else None

        if old:
            for lang, mine, theirs in (("en", r["body_en"], old[0]),
                                       ("hi", r["body_hi"], old[1])):
                ratio, run = _score(mine, theirs)
                if ratio > MAX_RATIO:
                    problems.append(f"{lang} ratio {ratio:.3f} > {MAX_RATIO}")
                if run > MAX_RUN:
                    problems.append(f"{lang} run {run} > {MAX_RUN}")
            if len(r["body_en"]) <= len(old[0]):
                problems.append(
                    f"body_en {len(r['body_en'])} not longer than fixture {len(old[0])}")

        for k, v in r.items():
            if k.endswith("_en") and v and not r.get(k[:-3] + "_hi"):
                problems.append(f"{k} has no _hi")
        hi_ratio = len(r["body_hi"]) / len(r["body_en"])
        if hi_ratio < MIN_HI_RATIO:
            problems.append(f"hi/en {hi_ratio:.2f} < {MIN_HI_RATIO}")

        print(f"  {'FAIL' if problems else 'ok  '}  {r['slug']}")
        for p in problems:
            print(f"          {p}")
        ok &= not problems
    return ok


def load() -> None:
    rows = _batches()
    print(f"{len(rows)} katha(s) staged\n")
    if not _gate(rows):
        sys.exit("\ngates failed -- nothing written")

    conn = sqlite3.connect(GYAN)
    have = {r[0] for r in conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='kathas'")}
    if not have:
        sys.exit("gyan.sqlite has no kathas table -- rebuild it from "
                 "content/schema/gyan.sql first")

    cols = SCALAR + LISTS
    sql = (f"INSERT OR REPLACE INTO kathas ({','.join(cols)}) "
           f"VALUES ({','.join('?' * len(cols))})")
    for r in rows:
        vals = [r.get(c) for c in SCALAR]
        vals += [json.dumps(r.get(c) or [], ensure_ascii=False) for c in LISTS]
        conn.execute(sql, vals)
    conn.commit()
    n = conn.execute("SELECT count(*) FROM kathas").fetchone()[0]
    print(f"\nwrote {len(rows)} row(s); gyan.kathas now holds {n}")


def status() -> None:
    fx = sqlite3.connect(FIXTURE)
    total = fx.execute("SELECT count(*) FROM kathas").fetchone()[0]
    done = {r.get("legacy_id") for r in _batches()} - {None}
    ek = {r[0] for r in fx.execute(
        "SELECT id FROM kathas WHERE title_en LIKE '%Ekadashi%'")}
    writable = total - len(ek)
    print(f"fixture kathas      {total}")
    print(f"  replaced          {len(done)}")
    print(f"  Ekadashi, blocked {len(ek)}  (no public-domain source; see "
          f"content/legal/HANDOFF-RG01-NONSCRIPTURE.md)")
    print(f"  writable, to do   {writable - len(done & (set(range(1, total + 1)) - ek))}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "load":
        load()
    elif cmd == "status":
        status()
    else:
        rows = _batches()
        print(f"{len(rows)} katha(s) staged\n")
        sys.exit(0 if _gate(rows) else 1)
