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

    # The collision the kind-bucketed duplicate-title check cannot see. Both
    # rows below are individually valid and their titles differ ("Bhadra" vs
    # "Bhadra-2"), so nothing else in the gate has anything to say about them --
    # which is exactly how twelve of these shipped.
    ("importer collision counter", "collision-suffix",
     [entity("bhadra"), entity("bhadra-2")], False),
    # And the case it must stay quiet about. The narrative files number their own
    # rows -- kuru-day-08, kuru-day-09 -- so a trailing counter is only
    # suspicious when the un-suffixed slug ALSO exists. A first draft of the
    # duplicate scan matched the bare shape instead and drowned in 1400 false
    # positives, of which twelve mattered.
    ("a numbered slug with no base slug is fine", "",
     [entity("kuru-day-08"), entity("kuru-day-09")], False),

    # The cited chapter must be re-readable on disk, not merely named. Both
    # sources below are registered and legitimate; the difference is that one
    # has been fetched to content/raw/ and the other has not, which is the
    # difference between a citation a later reader can check and one they
    # cannot. Uses the real registry, so if dutt-ramayana is ever fetched this
    # case starts failing and must be re-pointed -- the same self-invalidating
    # shape as the stale-exception check below.
    ("citing a source never fetched to raw/", "corpus-not-fetched",
     [entity("c1", sources=[{**GOOD_SOURCE, "source_slug": "dutt-ramayana",
                             "source_chapter_or_section": "Bala Kanda, Sarga 1"}])],
     False),
    ("citing an unfetched source blocks --strict", "corpus-not-fetched",
     [entity("c2", sources=[{**GOOD_SOURCE, "source_slug": "dutt-ramayana",
                             "source_chapter_or_section": "Bala Kanda, Sarga 1"}])],
     True),

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


def check_kg_degree() -> str:
    """report.kg_coverage must count relations the way the goal words it.

    This metric has been mis-measured by hand three times, each time in the
    direction that flattered the number: once with the threshold one below the
    goal, once counting `src_id or dst_id` (double, since build.py materialises
    every inverse), once counting rows rather than distinct partners (double for
    any pair attested by two chapters). It reported 91% against a 100% target
    when the real figure was 48%.

    So: a six-entity graph whose answer is countable by eye, shaped so that each
    wrong reading gives a DIFFERENT answer from the right one. `b` and `e` are
    the load-bearing rows -- each has one more citation than it has partners, so
    counting rows lets them over the bar and counting partners does not.
    """
    import sqlite3

    from content.tools import report

    db = sqlite3.connect(":memory:")
    db.executescript(
        "create table entities(id integer primary key, slug text, kind text,"
        " importance int);"
        "create table relations(src_id int, rel_type text, dst_id int);")
    db.executemany("insert into entities values (?,?,?,?)", [
        (1, "a", "deity", 1), (2, "b", "deity", 1), (3, "c", "human", 3),
        (4, "d", "human", 3), (5, "e", "human", 3), (6, "f", "human", 3),
    ])
    db.executemany("insert into relations values (?,?,?)", [
        # a: three distinct partners -> the only P0 that meets 3.
        (1, "r", 3), (1, "r", 4), (1, "r", 5),
        # b: TWO partners, one of them attested by two chapters. 3 rows, 2
        # relations. Counting rows would pass it; counting partners must not.
        (2, "r", 6), (2, "r", 6), (2, "r", 5),
        # c, d: two distinct partners each -> genuinely meet the P1 bar of 2.
        (3, "r", 1), (3, "r", 4), (4, "r", 1), (4, "r", 3),
        # e: ONE partner, two citations. Same trap as b, at the P1 bar.
        (5, "r", 1), (5, "r", 1),
        # f: nothing at all.
    ])

    got = {t["tier"]: (t["met"], t["total"]) for t in report.kg_coverage(db)}
    want = {"P0": (1, 2), "P1": (2, 4)}
    if got != want:
        return f"counted {got}, hand-count is {want}"
    return ""


def check_provenance_not_presence() -> str:
    """A raw/ directory holding the wrong book must not count as fetched.

    This is the failure that motivated validate.fetched_sources(). Two
    directories under content/raw/ existed, held one .txt each, and were the
    wrong works entirely -- a Gutenberg comedy filed as Müller's Upanishads and
    a Vermont historical novel filed as Vivekananda's Raja Yoga -- while 61
    rows cited them saying the primary text had been read. A check that asks
    "does the directory exist" passes both, and passing is the worse outcome:
    the next reader to grep for the quoted verse blames the citation.

    So the fixture is the two cases side by side, identical except for the
    manifest: `recorded/` has one and must count, `orphan/` has none and must
    not. Hermetic -- a temp RAW_DIR, so it keeps its teeth no matter what the
    real corpus does next.
    """
    import json as _json

    from content.tools import validate as v

    tmp = Path(tempfile.mkdtemp(prefix="aradhya-raw-"))
    try:
        (tmp / "recorded").mkdir()
        (tmp / "recorded" / "ch1.txt").write_text("text", encoding="utf-8")
        (tmp / "manifest.json").write_text(_json.dumps(
            [{"source_slug": "recorded", "file": "recorded/ch1.txt"}]),
            encoding="utf-8")

        # Same shape, no manifest anywhere. This is the wrong-book case.
        (tmp / "orphan").mkdir()
        (tmp / "orphan" / "full.txt").write_text("text", encoding="utf-8")

        # And the per-source manifest form the Gutenberg fetches write.
        (tmp / "gutenberg").mkdir()
        (tmp / "gutenberg" / "full.txt").write_text("text", encoding="utf-8")
        (tmp / "gutenberg" / "manifest.json").write_text(_json.dumps(
            {"source_slug": "gutenberg",
             "files": [{"path": "full.txt", "url": "https://x/y.txt"}]}),
            encoding="utf-8")

        original = v.RAW_DIR
        v.RAW_DIR = tmp
        try:
            got = v.fetched_sources()
        finally:
            v.RAW_DIR = original

        want = {"recorded": 1, "gutenberg": 1}
        if got != want:
            return f"counted {got}, should be {want} (orphan/ must be absent)"
        return ""
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    failures = 0

    drift = check_bounds_agree()
    if drift:
        failures += 1
    print(f"[{'FAIL' if drift else 'PASS'}] "
          f"{'applier and gate agree on word bounds':<34} "
          f"{'quick_summary':<32} {drift or validate.QUICK_SUMMARY_WORDS}")

    kg = check_kg_degree()
    if kg:
        failures += 1
    print(f"[{'FAIL' if kg else 'PASS'}] "
          f"{'KG degree counts distinct partners':<34} "
          f"{'kg_coverage':<32} {kg or 'P0 1/2, P1 2/4 by hand'}")

    prov = check_provenance_not_presence()
    if prov:
        failures += 1
    print(f"[{'FAIL' if prov else 'PASS'}] "
          f"{'raw/ needs provenance, not bytes':<34} "
          f"{'fetched_sources':<32} "
          f"{prov or 'unrecorded directory does not count'}")

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
    total = len(CASES) + 3
    print(f"selftest: {total - failures}/{total} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
