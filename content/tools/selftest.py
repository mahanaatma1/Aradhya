"""Self-test for the validation gate.

    py -m content.tools.selftest

Feeds deliberately broken rows through validate.run() and asserts that each
check actually fires. An unverified validator is worse than no validator: it
gives false confidence that the content rules are being enforced.

Writes only to a temp directory; content/data is never touched.
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools import common, validate  # noqa: E402

GOOD_SOURCE = {
    "source_slug": "ganguli-mahabharata",
    "source_chapter_or_section": "Adi Parva 1",
    "is_primary": True,
    "last_verified_at": "2026-01-01",
    "verified_by": "TS",
}
VERIFIED = {"status_en": "verified", "status_hi": "verified", "by": "TS",
            "at": "2026-01-01", "notes": ""}


def entity(slug: str, **over) -> dict:
    row = {
        "slug": slug,
        "kind": "deity",
        "title": {"en": slug.title(), "hi": slug.title()},
        "short_description": {"en": f"{slug} summary.", "hi": f"{slug} सारांश।"},
        "aliases": [],
        "tags": [],
        "importance": 3,
        "sources": [dict(GOOD_SOURCE)],
        "verification": dict(VERIFIED),
    }
    row.update(over)
    return row


CASES: list[tuple[str, str, list[dict], bool]] = [
    # (label, expected finding code, rows, strict)
    ("clean row passes", "", [entity("hanuman")], False),
    ("unknown source_slug", "unknown-source",
     [entity("a1", sources=[{**GOOD_SOURCE, "source_slug": "not-a-real-source"}])], False),
    ("reference-only citation", "missing-primary-source",
     [entity("a2", sources=[{**GOOD_SOURCE, "source_slug": "wikipedia"}])], False),
    ("future verified date", "future-verified-date",
     [entity("a3", sources=[{**GOOD_SOURCE, "last_verified_at": "2099-01-01"}])], False),
    ("malformed verified date", "bad-verified-date",
     [entity("a4", sources=[{**GOOD_SOURCE, "last_verified_at": "01-01-2026"}])], False),
    ("dangling relation target", "dangling-ref",
     [entity("a5", related_items=[{"rel_type": "wields", "dst_slug": "nope",
                                   "confidence": "high"}])], False),
    ("unknown rel_type", "unknown-rel-type",
     [entity("a6"), entity("a7", related_items=[
         {"rel_type": "vibes_with", "dst_slug": "a6", "confidence": "high"}])], False),
    ("duplicate slug", "duplicate-slug", [entity("dup"), entity("dup")], False),
    ("duplicate title", "duplicate-title",
     [entity("t1", title={"en": "Same", "hi": "स"}),
      entity("t2", title={"en": "Same", "hi": "स"})], False),
    ("epithet claimed twice", "duplicate-alias",
     [entity("e1", aliases=[{"alias": "Devi", "script": "latn", "lang": "en",
                             "alias_kind": "epithet"}]),
      entity("e2", aliases=[{"alias": "Devi", "script": "latn", "lang": "en",
                             "alias_kind": "epithet"}])], False),
    ("missing Hindi is a warning in dev", "missing-hindi-title",
     [entity("h1", title={"en": "No Hindi"})], False),
    ("unverified blocked by --strict", "unverified",
     [entity("v1", verification={"status_en": "unverified",
                                 "status_hi": "unverified"})], True),
    ("schema rejects bad kind", "schema", [entity("k1", kind="wizard")], False),
    ("no sources at all", "schema", [entity("s1", sources=[])], False),
]


def run_case(rows: list[dict], strict: bool) -> validate.Report:
    tmp = Path(tempfile.mkdtemp(prefix="aradhya-selftest-"))
    try:
        (tmp / "entities").mkdir(parents=True)
        with (tmp / "entities" / "test.jsonl").open("w", encoding="utf-8") as fh:
            for r in rows:
                fh.write(json.dumps(r, ensure_ascii=False) + "\n")
        original = validate.DATA_DIR
        validate.DATA_DIR = tmp
        common.DATA_DIR = tmp
        try:
            return validate.run(strict=strict)
        finally:
            validate.DATA_DIR = original
            common.DATA_DIR = original
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    failures = 0
    for label, expected, rows, strict in CASES:
        rep = run_case(rows, strict)
        codes = {f.code for f in rep.findings}
        if expected:
            ok = expected in codes
        else:
            ok = not rep.errors
        status = "PASS" if ok else "FAIL"
        if not ok:
            failures += 1
        detail = f"expected '{expected}'" if expected else "expected no errors"
        print(f"[{status}] {label:<34} {detail:<32} got={sorted(codes) or '-'}")

    print()
    print(f"selftest: {len(CASES) - failures}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
