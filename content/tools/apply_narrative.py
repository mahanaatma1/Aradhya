"""Stage 1e -- put drafted Story Cards prose into the narrative rows (SC-05..08).

    py -m content.tools.apply_narrative content/staging/quick_summaries.json
    py -m content.tools.apply_narrative <patch> --replace     # overwrite existing
    py -m content.tools.apply_narrative <patch> --dry-run
    py -m content.tools.apply_narrative <patch> --verified-by TS   # citations

The patch is `{"<slug>": {"quick_summary": {"en": ..., "hi": ...}}}`. Prose is
drafted from the digests, which are drafted from the fetched chapters; this is
the step that writes it down, and the only one that edits content/data.

Why a tool and not an editor. A narrative row is one JSON object on one line,
two kilobytes wide, and the field being added sorts into the middle of it.
Hand-editing seventy-eight of those is how a line ends up with a duplicated key
or a mangled Devanagari escape that nothing notices until a build. So the rows
are parsed, patched, and re-serialised with `sort_keys=True,
ensure_ascii=False`, which reproduces every untouched row byte for byte -- that
was checked against all seventy-nine before this tool was written, and it is
checked again on every run: a file is only rewritten if the rows this patch
names are the only lines that changed.

What it refuses. An empty side of a bilingual pair, prose that merely repeats
`short_description` (the plan asks for a quick summary *distinct* from the card
blurb, and a copy is the easiest way to satisfy a word count without adding
anything), a summary shorter than the blurb it is meant to expand, and a slug
it does not recognise. It also refuses to overwrite prose that is already there
unless told to, because a second run of a stale patch should not silently undo
an edit made after it.

Citations, `{"<slug>": {"citation": [{"source_slug": ..., "sections": [...],
"cited_as": ...}]}}`, are the one field here that is not prose, and they are
held to more than the prose is. SC-06 narrows citations that were too wide to
author from -- forty-two sections of Udyoga Parva down to the one that holds the
scene -- and a citation is the row's claim about where it got its story, so:

*A narrowing may not widen.* Every section named has to be inside what the row
already cites, per the coverage file. Tightening a citation weakens the claim,
which is safe; extending one asserts something no verifier saw.

*A narrowing may not change the source.* A `source_slug` the row does not
already cite is refused outright. Some events genuinely need a second recension
-- `ram-indrajit`'s sargas are absent from Griffith -- and the plan's rule is
that such a row must not silently borrow one.

*Every section has to be on disk.* A citation is only worth narrowing to text
that was fetched and can be read; the coverage file is the authority.

*Somebody's name goes on it.* `--verified-by` has no default. The row records a
person's initials against a date, and a tool cannot supply either on their
behalf, so a citation patch without a name is refused. The old range is kept in
`verification.notes` so the narrowing can be read back and undone.

Reads and writes content/data/narrative/*.jsonl, and reads
content/sources/narrative_coverage.json to check a citation. It does not touch
the schema or the shipped databases; `build.py` is what carries these fields
into a DB.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NARRATIVE = ROOT / 'content' / 'data' / 'narrative'
COVERAGE = ROOT / 'content' / 'sources' / 'narrative_coverage.json'

# Bilingual prose blocks this tool will write, with the word bounds each one is
# held to. The quick summary's ceiling is the point of it: "the 30-second read"
# stops being one at a hundred and twenty words, and the story block below it
# starts at a hundred. A block with no bounds is not policed on length.
BILINGUAL = {
    'quick_summary': (30, 95),
    'story': (90, 620),
    'reflection': (5, 60),
}
LIST_BLOCKS = {'key_moments': (3, 6)}      # beats per language, per the plan


def words(text: str) -> int:
    return len(text.split())


def load_rows() -> tuple[dict[str, dict], dict[str, Path],
                         dict[Path, list[str]], dict[str, str]]:
    """Rows by slug, the file each came from, each file's slug order, and the
    line each row arrived on.

    The order matters: rows are rewritten in place, so a file has to go back out
    in the sequence it came in. Nothing here sorts anything.

    The lines are kept so the write can prove it changed only what the patch
    named. Re-serialising a row this tool did not touch should reproduce the line
    it came from exactly, and if it ever stops doing that -- a json module that
    escapes differently, a row that arrived with keys out of order -- the whole
    file silently rewrites and the diff is unreadable.
    """
    rows: dict[str, dict] = {}
    origin: dict[str, Path] = {}
    order: dict[Path, list[str]] = {}
    source_line: dict[str, str] = {}
    for path in sorted(NARRATIVE.glob('*.jsonl')):
        order[path] = []
        for line in path.read_text(encoding='utf-8').splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            slug = row['slug']
            if slug in rows:
                raise SystemExit(f'duplicate slug across narrative files: {slug}')
            rows[slug], origin[slug] = row, path
            source_line[slug] = line
            order[path].append(slug)
    return rows, origin, order, source_line


def cited_sections() -> dict[tuple[str, str], set[int]]:
    """`(slug, source_slug) -> every section that row already cites`, and
    `(slug, source_slug, 'disk')` for the subset that was fetched.

    Taken from the coverage file rather than parsed out of
    `source_chapter_or_section`, because that field is prose -- "Sundara Kanda,
    sargas 14-38", "The Mahabharata, Book 1: Adi Parva: Section CCXXIV" -- and
    fetch_narrative already did the work of resolving it to numbers against the
    archive's own numbering. Parsing it a second time here is how the two would
    drift.
    """
    out: dict[tuple[str, str], set[int]] = {}
    if not COVERAGE.exists():
        return out
    coverage = json.loads(COVERAGE.read_text(encoding='utf-8'))
    for event in coverage['events']:
        for c in event['citations']:
            key = (event['slug'], c['read_from'])
            out.setdefault(key, set()).update(c['sections'])
        for ch in event['chapters']:
            key = (event['slug'], ch['source_slug'], 'disk')
            out.setdefault(key, set()).add(ch['section'])
    return out


def check(slug: str, field: str, value, row: dict) -> list[str]:
    """Everything wrong with one patched field, as sentences. Empty means fine."""
    bad: list[str] = []
    if field in LIST_BLOCKS:
        lo, hi = LIST_BLOCKS[field]
        for lang in ('en', 'hi'):
            items = (value or {}).get(lang)
            if not items:
                bad.append(f'{field}.{lang} is empty')
            elif not lo <= len(items) <= hi:
                bad.append(f'{field}.{lang} has {len(items)} beats, wanted {lo}-{hi}')
        return bad

    if field not in BILINGUAL and field != 'themes':
        return [f'{field} is not a block this tool writes']
    if field == 'themes':
        if not value:
            bad.append('themes is empty')
        return bad

    lo, hi = BILINGUAL[field]
    for lang in ('en', 'hi'):
        text = ((value or {}).get(lang) or '').strip()
        if not text:
            bad.append(f'{field}.{lang} is empty -- both languages or neither')
            continue
        n = words(text)
        if not lo <= n <= hi:
            bad.append(f'{field}.{lang} is {n} words, wanted {lo}-{hi}')
        blurb = ((row.get('short_description') or {}).get(lang) or '').strip()
        if blurb and field == 'quick_summary':
            if text == blurb:
                bad.append(f'{field}.{lang} is the card blurb verbatim')
            elif blurb and blurb in text:
                bad.append(f'{field}.{lang} contains the card blurb verbatim')
            elif words(text) <= words(blurb):
                bad.append(f'{field}.{lang} is no longer than the blurb it expands')
    return bad


def check_citation(slug: str, value, row: dict, cited: dict) -> list[str]:
    """Everything wrong with a citation patch, as sentences. Empty means fine.

    The four rules are in the module docstring; this is where they are enforced.
    Each one refuses rather than repairs, because the repair for a citation that
    names an unfetched chapter is to fetch it, and a tool that quietly dropped
    the section would leave the row claiming less than the person who wrote the
    patch believed it claimed.
    """
    bad: list[str] = []
    if not isinstance(value, list) or not value:
        return ['citation must be a non-empty list of {source_slug, sections,'
                ' cited_as}']
    have = {s.get('source_slug') for s in (row.get('sources') or [])}
    for i, entry in enumerate(value):
        where = f'citation[{i}]'
        source = entry.get('source_slug')
        sections = entry.get('sections')
        label = (entry.get('cited_as') or '').strip()
        if not source:
            bad.append(f'{where} has no source_slug')
            continue
        if source not in have:
            bad.append(f'{where} cites {source}, which this row does not already'
                       f' cite -- a narrowing cannot change the source')
            continue
        if not label:
            bad.append(f'{where} has no cited_as -- the row shows this to a reader')
        if not sections or not all(isinstance(s, int) for s in sections):
            bad.append(f'{where} has no sections, or a section that is not a number')
            continue
        was = cited.get((slug, source)) or set()
        if not was:
            bad.append(f'{where}: the coverage file has no {source} citation for'
                       f' this row -- re-run fetch_narrative before narrowing')
            continue
        wider = sorted(set(sections) - was)
        if wider:
            bad.append(f'{where} adds {", ".join(str(s) for s in wider)}, which the'
                       f' row does not already cite -- this widens, it does not narrow')
        on_disk = cited.get((slug, source, 'disk')) or set()
        absent = sorted(set(sections) - on_disk)
        if absent:
            bad.append(f'{where} names {", ".join(str(s) for s in absent)}, not'
                       f' fetched -- a citation has to point at text that was read')
    return bad


def apply_citation(row: dict, value: list, who: str, when: str) -> None:
    """Rewrite the row's `sources` to the narrowed sections, keeping the old
    range where it can be read back.

    Only the cited entries are touched. A row can carry sources this patch says
    nothing about -- a secondary reference, a second recension -- and those keep
    their own verifier and date, because nobody re-checked them today.
    """
    by_source = {e['source_slug']: e for e in value}
    notes = []
    for entry in row.get('sources') or []:
        new = by_source.get(entry.get('source_slug'))
        if new is None:
            continue
        was = entry.get('source_chapter_or_section') or '(none)'
        entry['source_chapter_or_section'] = new['cited_as']
        entry['last_verified_at'] = when
        entry['verified_by'] = who
        notes.append(f'{entry["source_slug"]}: {was} -> {new["cited_as"]}')
    v = row.setdefault('verification', {})
    old = (v.get('notes') or '').strip()
    line = f'{when} narrowed by {who}; was ' + '; '.join(notes)
    v['notes'] = f'{old} {line}'.strip() if old else line
    v['at'], v['by'] = when, who


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('patch', help='JSON file: {slug: {field: value}}')
    p.add_argument('--replace', action='store_true',
                   help='overwrite a field that already has prose in it')
    p.add_argument('--dry-run', action='store_true',
                   help='check and report, write nothing')
    p.add_argument('--verified-by', metavar='INITIALS',
                   help='who checked a citation patch against the text; required'
                        ' for citations, and there is no default')
    p.add_argument('--verified-at', metavar='YYYY-MM-DD',
                   help='the date to record; defaults to today')
    args = p.parse_args()

    patch = json.loads(Path(args.patch).read_text(encoding='utf-8'))
    rows, origin, order, source_line = load_rows()
    cited = cited_sections()
    when = args.verified_at or date.today().isoformat()

    problems: list[str] = []
    touched: dict[Path, int] = {}
    skipped: list[str] = []
    for slug, fields in patch.items():
        row = rows.get(slug)
        if row is None:
            problems.append(f'{slug}: no such narrative row')
            continue
        for field, value in fields.items():
            if field == 'citation':
                if not args.verified_by:
                    problems.append(f'{slug}: a citation patch needs --verified-by'
                                    ' -- somebody read the chapter, not this tool')
                    continue
                bad = check_citation(slug, value, row, cited)
                if bad:
                    problems += [f'{slug}: {b}' for b in bad]
                    continue
                apply_citation(row, value, args.verified_by, when)
                touched[origin[slug]] = touched.get(origin[slug], 0) + 1
                continue
            bad = check(slug, field, value, row)
            if bad:
                problems += [f'{slug}: {b}' for b in bad]
                continue
            if row.get(field) and not args.replace:
                # Silence here would make a re-run of an old patch look like a
                # success while it quietly reverted newer prose.
                skipped.append(f'{slug}.{field} already written -- --replace to overwrite')
                continue
            row[field] = value
            touched[origin[slug]] = touched.get(origin[slug], 0) + 1

    for line in problems:
        print(f'  ERROR  {line}')
    for line in skipped:
        print(f'  kept   {line}')
    if problems:
        print(f'{len(problems)} problem(s); nothing written')
        return 1
    if not touched:
        print('nothing to write')
        return 0

    # The claim in the docstring, checked rather than asserted: a row this patch
    # did not name has to re-serialise to the line it arrived on.
    named = set(patch)
    for path in touched:
        for slug in order[path]:
            if slug in named:
                continue
            again = json.dumps(rows[slug], ensure_ascii=False, sort_keys=True)
            if again != source_line[slug]:
                print(f'  ERROR  {slug} would change and this patch does not name'
                      f' it -- refusing to rewrite {path.name}')
                return 1

    if args.dry_run:
        for path, n in touched.items():
            print(f'  would write {n} field(s) in {path.name}')
        return 0

    for path, n in touched.items():
        out = '\n'.join(json.dumps(rows[s], ensure_ascii=False, sort_keys=True)
                        for s in order[path]) + '\n'
        path.write_text(out, encoding='utf-8', newline='\n')
        print(f'  wrote {n} field(s) in {path.name}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
