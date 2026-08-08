"""Shared primitives for the Aradhya content pipeline.

The most important thing in this file is `fold_variants`.

    IT IS MIRRORED IN DART at lib/features/search/search_fold.dart.

    If you change the folding rules here you MUST change them there, and
    test/search_fold_test.dart (golden, driven by fold_fixtures.json) will fail
    until you do. That test exists because a silent divergence between the
    two implementations makes search quietly wrong rather than broken -- the
    index would contain tokens the app can never produce.

Design rule: the core fold is DEPENDENCY-FREE and uses only unicodedata +
a fixed character map, so it is trivially portable to Dart. Anything that
needs a real transliteration library (Devanagari -> IAST alias expansion)
lives in `expand_devanagari_aliases`, runs at build time only, and stores its
output as alias ROWS -- so Dart never has to transliterate anything.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any, Iterable, Iterator

# Windows consoles default to cp1252, which cannot encode Devanagari or IAST.
# Every tool imports this module, so forcing UTF-8 here fixes all of them at
# once -- otherwise the first print() of a Sanskrit name kills the build.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):  # already redirected / not a TTY
        pass

REPO_ROOT = Path(__file__).resolve().parents[2]
CONTENT_DIR = REPO_ROOT / "content"
SCHEMA_DIR = CONTENT_DIR / "schema"
KINDS_DIR = SCHEMA_DIR / "kinds"
SOURCES_DIR = CONTENT_DIR / "sources"
DATA_DIR = CONTENT_DIR / "data"

# Raw acquisition output (Wikidata skeletons) lands here, NOT in data/.
# Staged rows have no descriptions and no citations, so they would drown
# validate.py in thousands of expected errors and make the real signal
# unreadable. extract.py promotes a row into data/ only once it carries a
# cited description -- that promotion IS the editorial step.
STAGING_DIR = CONTENT_DIR / "staging"
RAW_DIR = CONTENT_DIR / "raw"
BUILD_DIR = CONTENT_DIR / "build"
ASSETS_DB_DIR = REPO_ROOT / "assets" / "db"

LEGACY_DB = ASSETS_DB_DIR / "content.sqlite"
GYAN_DB = ASSETS_DB_DIR / "gyan.sqlite"

# ---------------------------------------------------------------------------
# Folding
# ---------------------------------------------------------------------------

# IAST / ISO-15919 -> plain-ASCII spellings people actually type.
#
# Deliberately covers NON-ASCII characters only. Mapping 'c' -> 'ch' would be
# closer to popular transliteration but would also turn "concept" into
# "chonchept" -- the fold runs over English prose too, so it must be safe there.
_IAST_MAP = {
    "ā": "a",   # ā
    "ī": "i",   # ī
    "ū": "u",   # ū
    "ṛ": "ri",  # ṛ   kṛṣṇa -> krishna
    "ṝ": "ri",  # ṝ
    "ḷ": "li",  # ḷ
    "ḹ": "li",  # ḹ
    "ṃ": "m",   # ṃ
    "ṁ": "m",   # ṁ
    "ḥ": "h",   # ḥ
    "ñ": "n",   # ñ
    "ṅ": "n",   # ṅ
    "ṇ": "n",   # ṇ
    "ṭ": "t",   # ṭ
    "ḍ": "d",   # ḍ
    "ś": "sh",  # ś
    "ṣ": "sh",  # ṣ
    "é": "e", "è": "e", "ê": "e",
    "á": "a", "à": "a", "â": "a",
    "í": "i", "ì": "i",
    "ó": "o", "ò": "o", "ô": "o",
    "ú": "u", "ù": "u", "û": "u",
    "ç": "c",
}

_DEVANAGARI = re.compile(r"[ऀ-ॿ]")
_TOKEN_SPLIT = re.compile(r"[^0-9A-Za-z-ɏḀ-ỿऀ-ॿ]+")
_NON_TOKEN = re.compile(r"[^0-9a-zऀ-ॿ]+")


def _strip_marks(s: str) -> str:
    """NFKD-decompose and drop combining marks (Unicode category Mn).

    Devanagari matras ARE combining marks, so this is only applied to
    non-Devanagari text -- stripping them would destroy Hindi words.
    """
    return "".join(c for c in unicodedata.normalize("NFKD", s)
                   if not unicodedata.combining(c))


def has_devanagari(s: str) -> bool:
    return bool(_DEVANAGARI.search(s))


def fold_variants(s: str) -> list[str]:
    """Fold one token into the 1-2 forms that get indexed.

    Devanagari is preserved verbatim (only zero-width joiners removed) --
    a Hindi query must hit the Hindi token exactly.

    Latin yields up to two variants so that both common spellings hit:
        'kṛṣṇa' -> ['krishna', 'krsna']
        'Krishna' -> ['krishna']
    The first is the mapped form (ṛ -> ri, ṣ -> sh); the second is the naive
    mark-stripped form, for users who type the diacritic-free spelling.

    Returns [] for tokens that fold away to nothing.
    """
    if not s:
        return []

    s = unicodedata.normalize("NFC", s).strip()
    if not s:
        return []

    if has_devanagari(s):
        # ZWJ/ZWNJ vary by input method and must not create distinct tokens.
        cleaned = s.replace("‌", "").replace("‍", "")
        cleaned = _NON_TOKEN.sub("", cleaned.lower())
        return [cleaned] if cleaned else []

    lowered = s.lower()

    mapped = _NON_TOKEN.sub("", _strip_marks(
        "".join(_IAST_MAP.get(c, c) for c in lowered)))
    naive = _NON_TOKEN.sub("", _strip_marks(lowered))

    out: list[str] = []
    for v in (mapped, naive):
        if v and v not in out:
            out.append(v)
    return out


def fold(s: str) -> str:
    """The single primary folded form. Convenience for alias_fold columns."""
    v = fold_variants(s)
    return v[0] if v else ""


def tokenize(text: str) -> list[str]:
    """Split free text into folded tokens, preserving order, deduped per call."""
    if not text:
        return []
    out: list[str] = []
    seen: set[str] = set()
    for raw in _TOKEN_SPLIT.split(text):
        if not raw:
            continue
        for v in fold_variants(raw):
            if len(v) < 2 or v in seen:
                continue
            seen.add(v)
            out.append(v)
    return out


# ---------------------------------------------------------------------------
# Slugs
# ---------------------------------------------------------------------------

def slugify(s: str) -> str:
    """Stable, URL-safe id. Matches the `slug` pattern in _common.schema.json."""
    base = fold(s) if has_devanagari(s) else _strip_marks(
        "".join(_IAST_MAP.get(c, c) for c in unicodedata.normalize("NFC", s).lower()))
    base = re.sub(r"[^a-z0-9]+", "-", base).strip("-")
    return base[:80]


# ---------------------------------------------------------------------------
# Devanagari -> IAST alias expansion (BUILD TIME ONLY)
# ---------------------------------------------------------------------------

def expand_devanagari_aliases(deva: str) -> list[str]:
    """Transliterate Devanagari to IAST so a Sanskrit name is also searchable
    in Latin. Output is stored as alias ROWS, so the app never transliterates.

    Degrades to [] if indic-transliteration is unavailable -- a missing optional
    dependency must not fail the build, only reduce alias coverage (report.py
    surfaces the gap).
    """
    if not deva or not has_devanagari(deva):
        return []
    try:
        from indic_transliteration import sanscript
        from indic_transliteration.sanscript import transliterate
    except ImportError:
        return []
    try:
        iast = transliterate(deva, sanscript.DEVANAGARI, sanscript.IAST)
    except Exception:
        return []
    return [iast] if iast and iast != deva else []


# ---------------------------------------------------------------------------
# JSONL I/O
# ---------------------------------------------------------------------------

class JsonlError(ValueError):
    """A malformed line, carrying its file and line number for report.py."""

    def __init__(self, path: Path, line_no: int, message: str):
        super().__init__(f"{path}:{line_no}: {message}")
        self.path = path
        self.line_no = line_no


def read_jsonl(path: Path) -> Iterator[tuple[int, dict[str, Any]]]:
    """Yield (line_no, obj). Blank lines and #-comments are skipped."""
    if not path.exists():
        return
    with path.open(encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError as e:
                raise JsonlError(path, line_no, f"invalid JSON: {e.msg}") from e
            if not isinstance(obj, dict):
                raise JsonlError(path, line_no, "expected a JSON object")
            yield line_no, obj


def read_all_jsonl(paths: Iterable[Path]) -> list[tuple[Path, int, dict[str, Any]]]:
    rows: list[tuple[Path, int, dict[str, Any]]] = []
    for p in paths:
        for line_no, obj in read_jsonl(p):
            rows.append((p, line_no, obj))
    return rows


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    n = 0
    with path.open("w", encoding="utf-8", newline="\n") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False, sort_keys=True))
            fh.write("\n")
            n += 1
    return n


def data_files(subdir: str) -> list[Path]:
    d = DATA_DIR / subdir
    return sorted(d.glob("*.jsonl")) if d.is_dir() else []


# ---------------------------------------------------------------------------
# Bilingual helpers (§1.11)
# ---------------------------------------------------------------------------

def bi(obj: dict[str, Any] | None, lang: str) -> str | None:
    """Pull one language out of a {'en':..,'hi':..} block. Never falls back:
    a missing Hindi value must stay NULL so validate.py can catch it."""
    if not obj:
        return None
    v = obj.get(lang)
    return v if isinstance(v, str) and v.strip() else None


def registry_slugs() -> set[str]:
    return {obj["slug"] for _, obj in read_jsonl(SOURCES_DIR / "registry.jsonl")}


def excluded_domains() -> dict[str, str]:
    return {obj["domain"]: obj.get("reason", "")
            for _, obj in read_jsonl(SOURCES_DIR / "excluded.jsonl")}
