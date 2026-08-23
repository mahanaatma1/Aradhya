"""Stage 1d -- put the fetched chapters in front of the author (SC-05..08).

    py -m content.tools.digest_narrative [--chars 700] [--tail 300] [--chapters 8]
    py -m content.tools.digest_narrative --only ram-birth,mbh-shanti

SC-04 put 629 public-domain chapters on disk. The content rule says the prose
that ships is drafted from those chapters and from nothing else, which means the
chapters have to be readable one event at a time -- a `raw/` directory of six
hundred files sorted by archive filename is a corpus, not a source you can write
from. This turns it into one digest per event: the citation, what the row
already claims, and the chapters themselves in the order the story happens.

Two things here are deliberately awkward, because both are the difference
between an honest draft and a plausible one.

First, every digest states what it *left out*. Chapters are excerpted, and an
event citing twenty-five sections gets a spread of them rather than all: so the
digest names the sections it showed, names the ones it skipped, and prints the
extract size, in the file the draft is written from. An author who cannot see
that a summary rests on 8 of 25 chapters will write as though it rests on 25.

Second, absence is copied through from the coverage file with its reason
attached. `ram-indrajit` has no chapters at all -- Griffith's index runs Canto
LXXV then XCIII, so the sargas it cites are not in this translation at any
number -- and a digest that quietly showed nothing would read exactly like a
digest for an event with nothing interesting in it. It says so instead, at the
top, in words.

Reads: content/sources/narrative_coverage.json, content/data/narrative/*.jsonl,
content/raw/**. Writes: content/staging/narrative_digests/ only. It does not
touch the schema, the shipped databases, or any content row.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COVERAGE = ROOT / 'content' / 'sources' / 'narrative_coverage.json'
NARRATIVE = ROOT / 'content' / 'data' / 'narrative'
RAW = ROOT / 'content' / 'raw'
OUT = ROOT / 'content' / 'staging' / 'narrative_digests'

# The archive wraps every chapter in navigation. Left in, it is the most
# repeated text in the corpus and the least informative, and at 700 characters
# an extract it would be most of the extract.
CRUMB_HEAD = re.compile(r'^\s*Sacred Texts.*?(?=(?:SECTION|CANTO|THE MAHABHARATA)\b)',
                        re.I | re.S)
CRUMB_TAIL = re.compile(r'\s*Next:.*$|\s*Sacred Texts \|.*$', re.I | re.S)
PRINT_PAGE = re.compile(r'\bp\.\s*\d+\s*')


def rows() -> dict[str, dict]:
    """Every narrative row, by slug. The digest quotes what the row already
    claims so the new prose can be written to be *different* from it: the plan
    asks for a quick summary distinct from `short_description`, and the only way
    to honour that is to have the blurb in view while writing."""
    out = {}
    for path in sorted(NARRATIVE.glob('*.jsonl')):
        for line in path.read_text(encoding='utf-8').splitlines():
            if line.strip():
                row = json.loads(line)
                out[row['slug']] = row
    return out


def spread(items: list, keep: int) -> list:
    """`keep` of `items`, evenly spaced, first and last always included.

    An event citing a wide span is summarised from a sample, and where the
    sample falls decides what the summary can see. Evenly is the only defensible
    choice: the first N chapters would summarise the opening of the span and
    call it the event.
    """
    if keep <= 0 or len(items) <= keep:
        return items
    if keep == 1:
        return [items[0]]
    step = (len(items) - 1) / (keep - 1)
    picked = {round(i * step) for i in range(keep)}
    return [items[i] for i in sorted(picked)]


def body_of(file: str) -> str | None:
    path = RAW / file.replace('\\', '/')
    if not path.exists():
        return None
    text = path.read_text(encoding='utf-8', errors='replace')
    text = CRUMB_HEAD.sub('', text)
    text = CRUMB_TAIL.sub('', text)
    return PRINT_PAGE.sub('', text).strip()


def extract(body: str, chars: int, tail: int) -> str:
    """The head of a chapter, and its end. Ganguli and Griffith both open a
    chapter with who is speaking and close it with what changed, and the middle
    is elaboration -- so for a summary the two ends carry the event and the
    omission is marked where it happened rather than being trimmed silently."""
    body = ' '.join(body.split())
    if len(body) <= chars + tail:
        return body
    head, end = body[:chars].rstrip(), body[len(body) - tail:].lstrip()
    dropped = len(body) - chars - tail
    return f'{head}\n\n    [... {dropped:,} characters not shown ...]\n\n{end}'


# Ganguli and Griffith transliterate a century before the spellings the slugs
# use: Santanu for Shantanu, Rávan for Ravana, Drupada's daughter is Krishná.
# Folding both sides to a common skeleton -- lose the diacritics, let s and sh
# meet, drop the vowel a chapter might spell differently -- turns a name that
# would never match into one that usually does. It is a heuristic and it is
# allowed to be: a missed passage costs an extract, not a wrong claim.
FOLD = str.maketrans('áàâäãéèêíìîóòôöõúùûüñçš', 'aaaaaeeeiiiooooouuuuncs')
STOP = {'the', 'a', 'of', 'and', 'in', 'to', 'at', 'his', 'her', 'is', 'on',
        'for', 'with', 'from', 'who', 'that', 'day', 'own'}


def skeleton(word: str) -> str:
    w = word.lower().translate(FOLD)
    w = re.sub(r'[^a-z]', '', w)
    return re.sub(r'sh', 's', w)


def focus_terms(row: dict) -> list[str]:
    """What this event is about, as words to look for in the chapter.

    The title carries more than it looks like it does. "The Vow of Bhishma" puts
    *vow* in the search, and the vow is the one paragraph of Adi Parva 100 that
    a head-and-tail extract of a nineteen-thousand-character chapter will always
    miss -- which is how an event can be digested from its own source and still
    not show the thing it is named after.
    """
    words_: list[str] = []
    for text in (row.get('title') or {}).get('en', ''), \
            (row.get('short_description') or {}).get('en', ''):
        words_ += re.findall(r"[A-Za-z']+", text)
    for c in row.get('cast') or []:
        words_ += (c.get('entity_slug') or '').split('-')
    words_ += (row.get('place_entity_slug') or '').split('-')
    terms, seen = [], set()
    for w in words_:
        s = skeleton(w)
        if len(s) >= 4 and w.lower() not in STOP and s not in seen:
            seen.add(s)
            terms.append(s)
    return terms


def passages(body: str, terms: list[str], head: int, tail: int,
             width: int = 420, keep: int = 2) -> list[str]:
    """The stretches of the unshown middle that mention what the event is about.

    Scored by how many *distinct* terms a window carries, not by how often one
    of them repeats: a paragraph saying "Bhishma" nine times is the chapter's
    ordinary weather, while one saying "Bhishma" and "vow" and "Satyavati"
    together is the scene.
    """
    middle = body[head:len(body) - tail]
    if not middle or not terms:
        return []
    step = width // 2
    scored: list[tuple[int, int]] = []
    for start in range(0, max(len(middle) - width, 1), step):
        window = skeleton(middle[start:start + width])
        hits = sum(1 for t in terms if t in window)
        if hits:
            scored.append((hits, start))
    scored.sort(key=lambda p: (-p[0], p[1]))
    picked: list[int] = []
    for _, start in scored:
        if all(abs(start - p) >= width for p in picked):
            picked.append(start)
        if len(picked) == keep:
            break
    out = []
    for start in sorted(picked):
        text = middle[start:start + width]
        out.append(f'    ... {text.strip()} ...')
    return out


def bilingual(field: dict | None, lang: str) -> str:
    return ((field or {}).get(lang) or '').strip() or '(none)'


def digest(event: dict, row: dict, args) -> str:
    out: list[str] = []
    w = out.append
    w(f"event      {event['slug']}")
    w(f"epic       {event['epic']}   book {event['book_no']} "
      f"{bilingual(row.get('book_label'), 'en')}"
      f"{'   (war day)' if event.get('war_day') else ''}")
    arc = row.get('arc') or {}
    w(f"arc        {arc.get('no')}. {arc.get('slug')} — {arc.get('title_en')}")
    w(f"title      {bilingual(row.get('title'), 'en')}  /  "
      f"{bilingual(row.get('title'), 'hi')}")
    w(f"recension  {row.get('recension')}")
    w(f"sequence   {event['sequence_no']}")
    w('')
    w('cited as')
    for c in event['citations']:
        line = f"  {c['cited_as']}  [{c['cited_source']}]"
        if c['read_from'] != c['cited_source']:
            # The substitution is stated wherever the text is read, not only in
            # the coverage file: an author drafting from Griffith while the row
            # cites Dutt needs to know that the two number their chapters
            # differently before they write "sarga 88" into anything.
            line += f"  -- read from {c['read_from']}, which is what this archive has"
        if c.get('note'):
            line += f"  -- {c['note']}"
        w(line)
    w('')
    w('the row already says')
    w(f"  short_description.en  {bilingual(row.get('short_description'), 'en')}")
    w(f"  short_description.hi  {bilingual(row.get('short_description'), 'hi')}")
    w(f"  long_description.en   {bilingual(row.get('long_description'), 'en')}")
    if row.get('lesson'):
        w(f"  lesson.en (deprecated) {bilingual(row.get('lesson'), 'en')}")
    w('')

    if event['missing'] or event['blocked']:
        w('NOT AVAILABLE — do not write around this, write within what is below')
        for b in event['blocked']:
            w(f'  {b}')
        for m in event['missing']:
            w(f"  book {m['book_no']} section {m['section']}: {m['reason']}")
        w('')

    chapters = event['chapters']
    shown = spread(chapters, args.chapters)
    if not chapters:
        w('NO CHAPTERS ON DISK. Nothing here is a source. This event cannot be')
        w('drafted until its citation resolves to text that exists.')
        return '\n'.join(out) + '\n'

    skipped = [c['section'] for c in chapters if c not in shown]
    w(f"chapters   {len(shown)} of {len(chapters)} shown"
      f"   (first {args.chars} chars + last {args.tail} of each)")
    w(f"  shown    {', '.join(str(c['section']) for c in shown)}")
    if skipped:
        # Stated in the digest, not just in the run log, because the digest is
        # what the draft is written from and the log is not.
        w(f"  skipped  {', '.join(str(s) for s in skipped)}"
          f"   -- on disk, not excerpted here")
    w('')
    terms = focus_terms(row)
    w(f"looking for  {', '.join(terms)}")
    w('')
    for c in shown:
        body = body_of(c['file'])
        w('=' * 74)
        w(f"[{c['source_slug']}] book {c['book_no']} section {c['section']}"
          f"   {c['path']}")
        w('=' * 74)
        if not body:
            w(f"  MISSING FROM DISK: {c['file']}")
            w('')
            continue
        flat = ' '.join(body.split())
        w(extract(flat, args.chars, args.tail))
        found = passages(flat, terms, args.chars, args.tail)
        if found:
            w('')
            w('  from the part not shown above:')
            w('\n'.join(found))
        w('')
    return '\n'.join(out) + '\n'


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--chars', type=int, default=700,
                   help='characters from the start of each chapter shown')
    p.add_argument('--tail', type=int, default=300,
                   help='characters from the end of each chapter shown')
    p.add_argument('--chapters', type=int, default=8,
                   help='chapters excerpted per event, spread across the span')
    p.add_argument('--only', default='',
                   help='comma-separated slugs, for redoing one event deeper')
    args = p.parse_args()

    if not COVERAGE.exists():
        print(f'no coverage file at {COVERAGE}. Run fetch_narrative first.')
        return 1
    events = json.loads(COVERAGE.read_text(encoding='utf-8'))['events']
    by_slug = rows()
    wanted = {s.strip() for s in args.only.split(',') if s.strip()}

    OUT.mkdir(parents=True, exist_ok=True)
    written = chars = 0
    nothing: list[str] = []
    for event in events:
        if wanted and event['slug'] not in wanted:
            continue
        row = by_slug.get(event['slug'])
        if row is None:
            print(f"  {event['slug']}: in coverage but not in narrative/*.jsonl")
            continue
        text = digest(event, row, args)
        (OUT / f"{event['slug']}.txt").write_text(text, encoding='utf-8')
        written, chars = written + 1, chars + len(text)
        if not event['chapters']:
            nothing.append(event['slug'])

    print(f'{written} digests, {chars // 1024}k chars -> '
          f'{OUT.relative_to(ROOT).as_posix()}')
    if nothing:
        print('  no source text at all, so not draftable yet: '
              + ', '.join(nothing))
    return 0


if __name__ == '__main__':
    sys.exit(main())
