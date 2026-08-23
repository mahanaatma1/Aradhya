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


# A card blurb and a quick summary that legitimately expands it. The summary is
# spelled out rather than generated so the word count is a fact of the fixture
# and not of a loop -- these bounds are the thing under test.
BLURB = {"en": "Arjuna wins the contest at Panchala.",
         "hi": "अर्जुन पांचाल में प्रतियोगिता जीतते हैं।"}
GOOD_SUMMARY_EN = (
    "The five brothers travel to Panchala disguised as brahmins and take "
    "lodging in a potter's house. When every assembled king has failed to "
    "string the bow, Arjuna rises from among the brahmins, strings it and "
    "shoots the mark. Draupadi garlands him, and the kings who came for her "
    "hand cry out in grief as he leads her from the arena."
)
GOOD_SUMMARY_HI = (
    "पाँचों भाई ब्राह्मण वेश में पांचाल पहुँचते हैं और एक कुम्हार के घर "
    "ठहरते हैं। जब सभा में आए सभी राजा धनुष पर प्रत्यंचा चढ़ाने में विफल हो "
    "जाते हैं, तब अर्जुन ब्राह्मणों के बीच से उठकर धनुष चढ़ाते हैं और लक्ष्य "
    "भेदते हैं। द्रौपदी उन्हें वरमाला पहनाती हैं, और शेष राजा शोक करते हैं।"
)


def event(slug: str, **over) -> dict:
    row = {
        "slug": slug,
        "epic": "mahabharata",
        "recension": "critical_ed",
        "sequence_no": 1,
        "title": {"en": slug.title(), "hi": slug.title()},
        "short_description": dict(BLURB),
        "quick_summary": {"en": GOOD_SUMMARY_EN, "hi": GOOD_SUMMARY_HI},
        "sources": [dict(GOOD_SOURCE)],
        "verification": dict(VERIFIED),
    }
    row.update(over)
    # A case passing quick_summary=None means "this row has no summary at all".
    # Leaving a literal null in would trip the schema check instead, and the
    # case would pass for the wrong reason.
    return {k: v for k, v in row.items() if v is not None}


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

    # SC-05: the 30-second read. Absence is tolerated while the epics are being
    # authored and refused by the release build; the rest is wrong in any mode.
    ("event with a real quick summary passes", "", [event("n1")], False),
    ("missing quick summary is a warning in dev", "missing-quick-summary",
     [event("n2", quick_summary=None)], False),
    ("missing quick summary blocks --strict", "missing-quick-summary",
     [event("n3", quick_summary=None)], True),
    ("quick summary in one language only", "quick-summary-one-language",
     [event("n4", quick_summary={"en": GOOD_SUMMARY_EN, "hi": ""})], False),
    ("quick summary that is the blurb again", "quick-summary-is-blurb",
     [event("n5", quick_summary=dict(BLURB))], False),
    ("quick summary that swallows the blurb", "quick-summary-repeats-blurb",
     [event("n6", quick_summary={
         "en": BLURB["en"] + " " + GOOD_SUMMARY_EN,
         "hi": BLURB["hi"] + " " + GOOD_SUMMARY_HI})], False),
    ("quick summary too short to be worth the tap", "quick-summary-length",
     [event("n7", quick_summary={"en": "Arjuna wins her at the contest held "
                                       "in Panchala that day.",
                                 "hi": "अर्जुन उस दिन पांचाल में हुई "
                                       "प्रतियोगिता में उन्हें जीतते हैं।"})], False),
    ("quick summary that cites itself in the prose",
     "quick-summary-cites-inline",
     [event("n8", quick_summary={
         "en": GOOD_SUMMARY_EN + " This is told in section 190.",
         "hi": GOOD_SUMMARY_HI})], False),
    ("an exception that is no longer needed", "stale-quick-summary-exception",
     [event(next(iter(validate.QUICK_SUMMARY_EXCEPTIONS)))], False),
    ("an excepted event is reported, not skipped", "quick-summary-excepted",
     [event(next(iter(validate.QUICK_SUMMARY_EXCEPTIONS)), quick_summary=None)],
     True),
]


def module_of(row: dict) -> str:
    """Which data subdir this fixture belongs in.

    Inferred rather than declared so the case table stays four columns wide.
    `epic` is required by narrative_node and appears in no other kind, so it is
    a safe discriminator; anything else is an entity.
    """
    return "narrative" if "epic" in row else "entities"


def run_case(rows: list[dict], strict: bool) -> validate.Report:
    tmp = Path(tempfile.mkdtemp(prefix="aradhya-selftest-"))
    try:
        for row in rows:
            module = module_of(row)
            d = tmp / module
            d.mkdir(parents=True, exist_ok=True)
            with (d / "test.jsonl").open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(row, ensure_ascii=False) + "\n")
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


def check_bounds_agree() -> str:
    """The applier and the gate must hold prose to the same word bounds.

    apply_narrative.py checks one patch as it is written; validate.py checks the
    finished set. If the applier were the looser of the two it would happily
    write rows the gate then refuses, and there would be no tool left that could
    fix them -- the field would have to be hand-edited in the shipped JSONL.
    """
    from content.tools import apply_narrative

    theirs = apply_narrative.BILINGUAL["quick_summary"]
    ours = validate.QUICK_SUMMARY_WORDS
    if tuple(theirs) != tuple(ours):
        return (f"apply_narrative writes {theirs} but validate demands {ours} "
                f"-- they must be the same pair")
    return ""


def main() -> int:
    failures = 0

    drift = check_bounds_agree()
    if drift:
        failures += 1
    print(f"[{'FAIL' if drift else 'PASS'}] "
          f"{'applier and gate agree on word bounds':<34} "
          f"{'quick_summary':<32} {drift or validate.QUICK_SUMMARY_WORDS}")

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
    print(f"selftest: {len(CASES) + 1 - failures}/{len(CASES) + 1} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
