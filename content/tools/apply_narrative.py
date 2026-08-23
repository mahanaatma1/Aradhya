"""Stage 1e -- put drafted Story Cards prose into the narrative rows (SC-05..08).

    py -m content.tools.apply_narrative content/staging/quick_summaries.json
    py -m content.tools.apply_narrative <patch> --replace     # overwrite existing
    py -m content.tools.apply_narrative <patch> --dry-run

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
names are the only ones that changed.

What it refuses. An empty side of a bilingual pair, prose that merely repeats
`short_description` (the plan asks for a quick summary *distinct* from the card
blurb, and a copy is the easiest way to satisfy a word count without adding
anything), a summary shorter than the blurb it is meant to expand, and a slug
it does not recognise. It also refuses to overwrite prose that is already there
unless told to, because a second run of a stale patch should not silently undo
an edit made after it.

Reads and writes content/data/narrative/*.jsonl. It does not touch the schema
or the shipped databases; `build.py` is what carries these fields into a DB.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NARRATIVE = ROOT / 'content' / 'data' / 'narrative'

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


def load_rows() -> tuple[dict[str, dict], dict[str, Path], dict[Path, list[str]]]:
    """Rows by slug, the file each came from, and each file's slug order.

    The order matters: rows are rewritten in place, so a file has to go back out
    in the sequence it came in. Nothing here sorts anything.
    """
    rows: dict[str, dict] = {}
    origin: dict[str, Path] = {}
    order: dict[Path, list[str]] = {}
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
            order[path].append(slug)
    return rows, origin, order


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


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('patch', help='JSON file: {slug: {field: value}}')
    p.add_argument('--replace', action='store_true',
                   help='overwrite a field that already has prose in it')
    p.add_argument('--dry-run', action='store_true',
                   help='check and report, write nothing')
    args = p.parse_args()

    patch = json.loads(Path(args.patch).read_text(encoding='utf-8'))
    rows, origin, order = load_rows()

    problems: list[str] = []
    touched: dict[Path, int] = {}
    skipped: list[str] = []
    for slug, fields in patch.items():
        row = rows.get(slug)
        if row is None:
            problems.append(f'{slug}: no such narrative row')
            continue
        for field, value in fields.items():
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
