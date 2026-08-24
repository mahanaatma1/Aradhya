"""Stage 1e -- which chapters of a wide citation actually hold the event (SC-06).

    py -m content.tools.narrow_citations
    py -m content.tools.narrow_citations mbh-khandava kuru-day-16
    py -m content.tools.narrow_citations --all --json

Fourteen events cite a range too wide to author from -- `mbh-peace-fails` cites
forty-two sections of Udyoga Parva, `kuru-day-14` seventy-five of Drona -- and
SC-04 flagged them `too_broad_to_author_from` rather than fetching around the
problem. The plan's answer is to narrow the citation before writing the story,
and this is the reading that proposes the narrowing: for each event it scores
every fetched section of that book against what the row says the event is, and
reports the narrowest span that carries the score.

It is read-only on purpose. A citation is provenance, so it changes through the
row's own `sources` field with a verifier's name against it, never as a side
effect of a search. What this prints is a worklist for a person.

Three decisions are what make the score worth reading.

*Terms are weighted by how rare they are, and by how hard the chapter leans on
them.* "Bhima" appears in most sections of the Mahabharata and locates nothing;
"samsaptaka" appears in a handful and locates a day of the war. Each term is
weighted by inverse document frequency taken twice -- across the translation and
across the book being searched, the smaller kept -- so that a word has to be
unusual in both to be worth anything, and then grown by how many times the
chapter uses it, because a chapter that merely lists a name says it once. This
gets there without a hand-kept list of names too ordinary to search for, which
would need extending for every new epic.

*The search covers the whole book on disk, not the cited range.* A row whose
title names a beat sitting outside its own citation can only be caught by
looking past it: `kuru-day-16` is titled for Karna taking command and cites the
sections after it. Narrowing and correcting are different acts -- one tightens a
true citation, the other says it points at the wrong place -- so a proposal
landing outside the cited range is reported loudly rather than folded in, and has
to beat the best cited section by half again before it is proposed at all.

*What was never fetched is named as unfetched.* SC-04 fetched cited chapters
only, so a book is on disk in patches. A span scored against half a book, with
the other half silently absent, would read like a search that found the best
place when it found the best of what it could see.

Reads: content/sources/narrative_coverage.json, content/data/narrative/*.jsonl,
content/raw/**. Writes: nothing, unless --json is passed, and then only
content/staging/citation_proposals.json.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from content.tools import digest_narrative as dg  # noqa: E402  (needs ROOT first)

MANIFEST = dg.RAW / 'narrative_manifest.json'
OUT_JSON = ROOT / 'content' / 'staging' / 'citation_proposals.json'

# The width SC-04 calls too broad to author from. A proposal is allowed to be
# narrower and is not allowed to be wider: at thirteen sections it has not
# solved the problem it was run to solve.
SPAN_MAX = 12

# A section stays in the span while it scores at least this much of the peak.
# Half is loose enough to keep the second half of a scene that continues into
# the next chapter, and tight enough that the ordinary weather of the book --
# every section mentions the war, the brothers, the king -- does not join in.
KEEP_FRACTION = 0.5

# A section has to use at least this many of the row's discriminating words
# before its score counts. One rare word is a mention; several together are the
# scene. Without the gate, Drona Parva 98 -- which says "chakravyuha" once, in
# passing, on a later day -- outscored the five sections that actually narrate
# Abhimanyu entering the formation, because one word at weight 4.6 is worth more
# squared than four words at 1.5. Lowered for a row whose own text yields fewer
# terms than this, so a thin row is not gated out of existence.
MIN_TERMS = 3

# How much a term's weight can grow by being *used* rather than merely present.
# Bhishma Parva section 25 is the Gita's roll-call: it names every warrior on
# both sides once each, and it says "Kurukshetra", which Ganguli says almost
# nowhere else. Scored on presence alone it beat the chapters that narrate the
# fighting for seven of the eighteen days of the war -- an index outscoring
# everything it indexes. The chapter that narrates a day says its warrior's name
# dozens of times, so the count is the difference, and log keeps it a tilt rather
# than a takeover: a section cannot win on repetition alone, only on repeating
# what already discriminates.
USE_CAP = 3.0

# How far a section outside the cited range has to beat the best section inside
# it before the tool proposes moving the citation rather than tightening it.
# See `propose`: half again as good, or the citation stands.
OVERRIDE = 1.5

ROMAN = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
WORD = re.compile(r"[A-Za-z']+")

# The diacritics have to come out of the text *before* it is cut into words.
# [A-Za-z]+ does not match á, so splitting first turns Griffith's "Rávan" into
# "R" and "van" and a search for ravana never finds him: in Sundara Kanda, where
# he is on nearly every page, he registered in two sections of thirty-three, drew
# the weight of a rare word for it, and sent the search for Sita in the Asoka
# grove to Canto I. digest_narrative folds the same letters but folds a whole
# window at once, which is why it never had this problem to have.
FOLD_TEXT = dict(dg.FOLD)
FOLD_TEXT.update({ord(chr(k).upper()): ord(chr(v).upper())
                  for k, v in dg.FOLD.items()})


def number_in(title: str) -> int | None:
    """The number in "Section 87", "Section CCCLIII", or "Canto LXXV.: The
    Night Attack".

    Used only as a fallback: the manifest carries the heading the page itself
    prints, and that is the authority for what a section is numbered. The order
    files are consulted for the pages the manifest has no entry for -- the ones
    never fetched -- and there the table of contents is all there is.

    Both numerals have to be read, because the archive uses both: Ganguli's
    contents pages count in arabic and the pages themselves in roman. And the
    roman has to be matched as a whole word. Stripping the non-numeral letters
    out of a title instead -- which is what this did first -- turns "Section 87"
    into CI, and Karna Parva grew a section 101 that scored higher than any real
    one.
    """
    head = title.split(':')[0]
    digits = re.search(r'\b(\d+)\b', head)
    if digits:
        return int(digits.group(1))
    letters = re.search(r'\b([IVXLCDM]+)\b', head.upper())
    if not letters:
        return None
    total = prev = 0
    for ch in reversed(letters.group(1)):
        v = ROMAN[ch]
        total += -v if v < prev else v
        prev = max(prev, v)
    return total or None


def order_pages() -> dict[tuple[str, int], list[tuple[str, str]]]:
    """(source, book) -> [(page file name, table-of-contents title)], in order.

    This is the archive's own list of what a book contains, which is the only
    way to say how much of a book is *not* on disk. Ganguli is split one order
    file per book, so the book number is in the file name. Griffith is one list
    for all seven, with a bare "Book IV" standing where a book begins.
    """
    out: dict[tuple[str, int], list[tuple[str, str]]] = {}
    for path in sorted((dg.RAW / 'ganguli-mahabharata').glob('_order_m*.json')):
        book = int(re.search(r'_order_m(\d+)', path.name).group(1))
        pages = json.loads(path.read_text(encoding='utf-8'))
        out[('ganguli-mahabharata', book)] = [(p[0], p[1]) for p in pages]
    rama = dg.RAW / 'griffith-ramayana' / '_order_rama.json'
    if rama.exists():
        book = 0
        for htm, title in json.loads(rama.read_text(encoding='utf-8')):
            mark = re.fullmatch(r'Book\s+([IVXLCDM]+)', title.strip())
            if mark:
                book = number_in(mark.group(1)) or 0
                continue
            if book:
                out.setdefault(('griffith-ramayana', book), []).append((htm, title))
    return out


def build_index(coverage: dict) -> tuple[dict, dict, list[str]]:
    """Two maps and a list of complaints.

    `on_disk[(source, book)][section] = (file, title)` for every fetched page,
    and `book_pages[(source, book)] = {section: title}` for every page the
    archive lists whether fetched or not.

    The coverage file is layered over the index afterwards and wins where the
    two disagree, because coverage is what the fetch actually resolved and this
    function is inference. Disagreements are returned rather than swallowed: if
    my reading of the archive's numbering has drifted from the fetcher's, every
    score below is scored against the wrong chapter and the run should say so.
    """
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    by_page: dict[tuple[str, str], dict] = {
        (m['source_slug'], Path(m['path'].replace('\\', '/')).name): m
        for m in manifest
    }
    pages = order_pages()

    on_disk: dict[tuple[str, int], dict[int, tuple[str, str]]] = {}
    book_pages: dict[tuple[str, int], dict[int, str]] = {}
    for key, listed in pages.items():
        source, _book = key
        for htm, title in listed:
            entry = by_page.get((source, htm))
            heading = (entry or {}).get('heading') or ''
            # "SECTION 34-35" is one page carrying two sections. Both numbers
            # point at it, so a citation to either resolves.
            nums = [int(n) for n in re.findall(r'\d+', heading)] if heading else []
            if not nums:
                n = number_in(title)
                nums = [n] if n else []
            for n in nums:
                book_pages.setdefault(key, {}).setdefault(n, title)
                if entry:
                    on_disk.setdefault(key, {})[n] = (entry['file'], title)

    problems: list[str] = []
    for event in coverage['events']:
        for ch in event['chapters']:
            key = (ch['source_slug'], ch['book_no'])
            mine = (on_disk.get(key) or {}).get(ch['section'])
            if mine is None:
                on_disk.setdefault(key, {})[ch['section']] = (ch['file'], '')
                book_pages.setdefault(key, {}).setdefault(ch['section'], '')
                problems.append(f"{event['slug']}: coverage has "
                                f"{ch['source_slug']} book {ch['book_no']} "
                                f"section {ch['section']}, the order files do not")
            elif mine[0] != ch['file']:
                on_disk[key][ch['section']] = (ch['file'], mine[1])
                problems.append(f"{event['slug']}: section {ch['section']} of book "
                                f"{ch['book_no']} is {ch['file']} in coverage and "
                                f"{mine[0]} here -- trusting coverage")
    return on_disk, book_pages, problems


class Corpus:
    """Every fetched page of one translation, as word sets, read once.

    Kept per source rather than per book for two reasons. Several events share a
    book, and reading Drona Parva's 130 fetched chapters once per event would be
    four times the work for the same answer. And frequency has to be counted
    across the whole translation -- see `weights` -- which means the whole
    translation has to be in hand before any one book can be scored.
    """

    def __init__(self, source: str, on_disk: dict):
        self.source = source
        self.words: dict[tuple[int, int], Counter[str]] = {}
        self.buckets: dict[tuple[int, int], dict[str, set[str]]] = {}
        self.titles: dict[tuple[int, int], set[str]] = {}
        self.books: dict[int, list[int]] = {}
        for (src, book), sections in sorted(on_disk.items()):
            if src != source:
                continue
            for section, (file, title) in sorted(sections.items()):
                body = dg.body_of(file)
                if not body:
                    continue
                got = Counter(w for w in (dg.skeleton(x) for x
                                          in WORD.findall(body.translate(FOLD_TEXT)))
                              if len(w) >= 4)
                key = (book, section)
                self.words[key] = got
                bucket: dict[str, set[str]] = {}
                for w in got:
                    bucket.setdefault(w[:4], set()).add(w)
                self.buckets[key] = bucket
                # Griffith's contents name every canto -- "The Asoka Grove",
                # "Rávan's Lament" -- and a word in a chapter's own title says
                # the chapter is *about* it, where a word in the body only says
                # it came up. Ganguli's contents say "Section 62", which
                # contributes nothing and costs nothing.
                self.titles[key] = {
                    w for w in (dg.skeleton(x) for x
                                in WORD.findall(title.translate(FOLD_TEXT)))
                    if len(w) >= 4}
                self.books.setdefault(book, []).append(section)

    def hit(self, key: tuple[int, int], term: str) -> bool:
        """Whether this section uses this term, allowing for a century of
        transliteration drift. Ganguli's Rávan and the slug's ravana share four
        folded letters and differ by one in length, which is most of the rule:
        agree on a prefix, and do not differ in length by more than three.

        The prefix is four letters for a short term and five for a long one.
        Four throughout is what a name needs -- ravan/ravana, sanjay/sanjaya --
        and it is too loose for the ordinary English a title also contributes:
        "outshoots" folds to outsoots, which shares outs with "outside" and is
        within one of its length, so the tournament matched every section that
        mentioned being outside. Five letters costs the names nothing, since the
        drift is in the tail.
        """
        return self._among(self.words.get(key), self.buckets.get(key), term)

    def in_title(self, key: tuple[int, int], term: str) -> bool:
        words = self.titles.get(key)
        return bool(words) and self._among(words, None, term)

    @staticmethod
    def _among(words: set[str] | None, buckets: dict | None, term: str) -> bool:
        if not words:
            return False
        if term in words:
            return True
        cut = 4 if len(term) <= 5 else 5
        pool = buckets.get(term[:4], ()) if buckets is not None else words
        return any(abs(len(w) - len(term)) <= 3 and w[:cut] == term[:cut]
                   for w in pool)

    def uses(self, key: tuple[int, int], term: str) -> int:
        """How many times this section uses this term, under the same tolerant
        match as `hit`. A name drifts across spellings inside one chapter --
        Ganguli writes both Rávan and Ravana -- so the count has to be over
        everything the match accepts, not over the exact word.
        """
        words = self.words.get(key)
        if not words:
            return 0
        cut = 4 if len(term) <= 5 else 5
        pool = self.buckets.get(key, {}).get(term[:4], ())
        return sum(words[w] for w in pool
                   if abs(len(w) - len(term)) <= 3 and w[:cut] == term[:cut])

    def weights(self, terms: list[str], book: int
                ) -> tuple[dict[str, float], dict[str, int]]:
        """Inverse document frequency, taken twice, and the smaller kept: once
        over every fetched section of the translation, once over the fetched
        sections of the book being searched.

        Neither count works alone, and both failures were seen before this rule
        was written.

        Over the book alone: SC-04 fetched cited chapters only, so a book is on
        disk in patches -- 39 of Adi Parva's 236 sections -- and inside a patch
        an ordinary word can be freakishly rare. "half" appeared in one of those
        39 and so drew the highest weight the measure can give, which put a
        genealogy chapter above section 224 for an event about the Khandava.

        Over the translation alone: a name can be rare in the whole Ramayana and
        still be in every chapter of the book you are searching. "Sita" and
        "Ravana" weighed 2.6 and 3.3 across Griffith, and they are on nearly
        every page of Sundara Kanda -- so the search for Sita in the Asoka grove
        landed on Canto I, Hanuman's Leap, which mentions all of them and none
        of what makes the grove the grove.

        Keeping the smaller says a word has to be unusual in both to be worth
        anything: unusual in the translation, or it is filler; unusual in this
        book, or it cannot tell one chapter of it from another.

        Terms the translation never uses weigh nothing, and so do terms it uses
        everywhere; both are returned with their document frequency so the report
        can tell them apart. They fail for opposite reasons, and only the first
        suggests the citation is pointing at the wrong book.
        """
        here = [(book, s) for s in self.books.get(book) or []]
        n_all, n_here = len(self.words) or 1, len(here) or 1
        weight, freq = {}, {}
        for t in terms:
            df_all = sum(1 for key in self.words if self.hit(key, t))
            df_here = sum(1 for key in here if self.hit(key, t))
            freq[t] = df_all
            weight[t] = min(math.log(n_all / df_all),
                            math.log(n_here / df_here)) if df_all and df_here else 0.0
        return weight, freq

    def score(self, key: tuple[int, int], weights: dict[str, float]) -> float:
        """Weights squared, grown by how often the section uses the term, doubled
        for a word in the chapter's own title, and zero unless enough distinct
        words fire at all.

        Squaring is what stops width beating precision. Unsquared, a section
        firing six ordinary words at weight 1 outscores one firing "khandava"
        and "indraprastha" at weight 3, and the ordinary section wins on the
        strength of being ordinary in six ways -- which is how the first run of
        this tool proposed Bhagavad Gita Chapter I for Karna taking command.

        The MIN_TERMS gate is the other half of that trade. Squaring makes one
        very rare word enough on its own, and one word is how a chapter mentions
        something rather than how it narrates it.

        The use factor answers the same objection at chapter scale, since a list
        of names satisfies any gate written in terms of distinct words -- see
        USE_CAP for the roll-call that made it necessary.
        """
        fired = [t for t, w in weights.items() if w > 0 and self.hit(key, t)]
        need = min(MIN_TERMS, sum(1 for w in weights.values() if w > 0))
        if len(fired) < need:
            return 0.0
        total = 0.0
        for t in fired:
            w = weights[t]
            use = 1.0 + min(math.log(max(self.uses(key, t), 1)), USE_CAP)
            total += w * w * use * (2 if self.in_title(key, t) else 1)
        return total


def propose(scores: dict[int, float], cited: set[int]
            ) -> tuple[list[int], tuple[int, float] | None]:
    """The scene around the best-scoring section: grow outward while the
    neighbour still carries half the peak, and stop at SPAN_MAX wide. Returns
    the span, and the outside rival that was set aside for want of margin.

    Grown from the peak rather than chosen as the highest-scoring span, because
    the highest-scoring span is not the same question. Summed over a window,
    five mediocre sections beat one excellent one -- the first run of this
    proposed Adi Parva 119-123 for the Khandava over section 224, which scored
    half again as much on its own, because 224's neighbours were never fetched
    and so contributed nothing to its window.

    Width is counted in section numbers, not in fetched sections. With 39 of Adi
    Parva's 203 sections on disk, twelve *consecutive fetched* sections reach
    from 143 to 224, which is not a narrowing of anything. Holes inside the span
    are allowed -- this translation runs Drona 37 then 39 -- they cost width like
    any other section.

    A peak outside the cited range has to clear the best cited section by
    OVERRIDE before it is allowed to anchor the span. The citation is evidence,
    entered by a person who read something; word overlap is weaker evidence than
    that, and it should take a decisive win to overturn a citation rather than a
    narrow one. Days 1 and 9 of the war are the case: rows so thin that their own
    words are "fights", "fiercely", "chariot" -- the weather of every chapter of
    the book -- and on a near-tie the citation is the better guide. The rival is
    still returned, so a close call is reported rather than buried.
    """
    live = {s: v for s, v in scores.items() if v > 0}
    if not live:
        return [], None
    peak_section = max(live, key=lambda s: (live[s], -s))
    rival = None
    inside = {s: v for s, v in live.items() if s in cited}
    if peak_section not in cited and inside:
        best_cited = max(inside, key=lambda s: (inside[s], -s))
        if live[peak_section] < inside[best_cited] * OVERRIDE:
            rival = (peak_section, live[peak_section])
            peak_section = best_cited
    floor = live[peak_section] * KEEP_FRACTION
    order = sorted(live)
    lo = hi = order.index(peak_section)
    while True:
        left = order[lo - 1] if lo > 0 else None
        right = order[hi + 1] if hi + 1 < len(order) else None
        options = []
        for i, section in ((lo - 1, left), (hi + 1, right)):
            if section is None or live[section] < floor:
                continue
            span = (order[hi] - section + 1) if i < lo else (section - order[lo] + 1)
            if span <= SPAN_MAX:
                options.append((live[section], i))
        if not options:
            return order[lo:hi + 1], rival
        _, i = max(options)
        lo, hi = min(lo, i), max(hi, i)


def as_range(span: list[int]) -> str:
    """A span as a citation would write it, with holes shown.

    "42-46" and "42, 46" are different claims about the archive: the first says
    five chapters carry the scene, the second says two do and the ones between
    them were never fetched. A proposal is read by someone deciding what to cite,
    so it has to say which one it means.
    """
    if not span:
        return '(none)'
    if len(span) == 1:
        return str(span[0])
    if span[-1] - span[0] + 1 == len(span):
        return f'{span[0]}-{span[-1]}'
    return ', '.join(str(s) for s in span)


def neighbours(cited: set[int], listed: dict[int, str], fetched: set[int],
               reach: int = 6) -> list[int]:
    """Sections just outside the citation that the archive lists and the fetch
    never took. These are the blind spot: the tool cannot score them, and for a
    row whose beat is missing from its own range they are the first place to
    look. Named, not guessed at."""
    if not cited:
        return []
    want = set(range(min(cited) - reach, min(cited))) | \
        set(range(max(cited) + 1, max(cited) + 1 + reach))
    return sorted(n for n in want if n in listed and n not in fetched and n > 0)


def report(event: dict, row: dict, get_corpus, book_pages: dict) -> list[dict]:
    """One block per book the event cites, printed, and the same as data.

    Per *citation's* book, not the row's own `book_no`. The row's book is where
    the event sits in the epic; the citation's is where the text is, and for the
    war days those are different -- `kuru-day-16` is a Bhishma Parva row citing
    Karna Parva. Scored against the row's book, the first run of this tool
    matched Karna taking command to a chapter of the Bhagavad Gita.
    """
    print('=' * 78)
    print(f"{event['slug']}   {row.get('title', {}).get('en', '')}")
    terms = dg.focus_terms(row)

    # Several citations can name the same book; they are one search.
    grouped: dict[tuple[str, int], dict] = {}
    for c in event['citations']:
        key = (c['read_from'], c['book_no'])
        g = grouped.setdefault(key, {'sections': set(), 'labels': []})
        g['sections'].update(c['sections'])
        g['labels'].append(c['cited_as'])

    out = []
    for (source, book_no), g in sorted(grouped.items()):
        cited = g['sections']
        label = '; '.join(dict.fromkeys(g['labels']))
        print(f"  cited as   {label}   [{source} book {book_no}]")

        corpus = get_corpus(source)
        listed = book_pages.get((source, book_no)) or {}
        fetched = sorted(corpus.books.get(book_no) or [])
        if not fetched:
            print('  no section of that book is on disk -- nothing to score')
            out.append({'slug': event['slug'], 'source': source,
                        'book_no': book_no, 'cited_as': label,
                        'cited_sections': sorted(cited), 'propose': [],
                        'outside_citation': [], 'scores': {},
                        'unfetched_neighbours': [], 'fetched_in_book': 0,
                        'listed_in_book': len(listed)})
            continue

        weights, freq = corpus.weights(terms, book_no)
        scores = {s: corpus.score((book_no, s), weights) for s in fetched}
        span, rival = propose(scores, cited)
        outside = sorted(s for s in span if s not in cited)
        top = sorted(scores.items(), key=lambda kv: -kv[1])[:5]

        print(f"  book {book_no}: {len(fetched)} sections fetched of "
              f"{len(listed)} the archive lists; citation covers {len(cited)}")
        useful = sorted((w, t) for t, w in weights.items() if w > 0)[::-1][:6]
        print('  discriminating  ' + (', '.join(f'{t} {w:.1f}' for w, t in useful)
                                      or '(none -- nothing in the row locates it)'))
        absent = [t for t in terms if freq.get(t) == 0]
        if absent:
            # The one failure narrowing cannot fix. If the translation never says
            # the word the row is named for, no span of it is the event.
            print(f"  never used      {', '.join(absent)}")

        if span:
            where = 'inside the citation' if not outside else \
                f'OUTSIDE at {", ".join(str(s) for s in outside)}' \
                '  -- a correction, not a narrowing'
            print(f"  PROPOSE    sections {as_range(span)}  "
                  f"({len(span)} of the {len(cited)} cited)   {where}")
        else:
            print('  PROPOSE    nothing -- no fetched section of this book scores')

        if rival:
            print(f"  close call: {rival[0]} scores {rival[1]:.1f} outside the "
                  f"citation, under the {OVERRIDE:g}x it would take to move it")

        for section, value in top:
            fired = [t for t in terms
                     if weights.get(t, 0) > 0 and corpus.hit((book_no, section), t)]
            mark = '*' if section in span else ('.' if section in cited else ' ')
            title = listed.get(section) or ''
            title = f'   {title}' if title and not re.fullmatch(
                r'(Section|Canto)\s+([IVXLCDM]+|\d+)\.?', title.strip()) else ''
            print(f"    {mark} {section:>4}  {value:5.1f}  "
                  f"{', '.join(fired[:7])}{title}")

        gap = neighbours(cited, listed, set(fetched))
        if gap:
            print(f"  not fetched, so not scored: {', '.join(str(g_) for g_ in gap)}"
                  f"   (adjacent to the citation)")
        here = [m for m in event['missing'] if m['book_no'] == book_no]
        if here:
            print('  missing from this translation: ' + ', '.join(
                f"section {m['section']}" for m in here))

        out.append({
            'slug': event['slug'],
            'source': source,
            'book_no': book_no,
            'cited_as': label,
            'cited_sections': sorted(cited),
            'fetched_in_book': len(fetched),
            'listed_in_book': len(listed),
            'propose': span,
            'outside_citation': outside,
            'close_call': {'section': rival[0], 'score': round(rival[1], 3)}
                          if rival else None,
            'scores': {str(s): round(v, 3) for s, v in top},
            'unfetched_neighbours': gap,
        })
    return out


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('slugs', nargs='*',
                   help='events to read; default is every one SC-04 flagged')
    p.add_argument('--all', action='store_true',
                   help='every event with a citation, not only the flagged ones')
    p.add_argument('--json', action='store_true',
                   help=f'also write {OUT_JSON.name} for the next tool to read')
    args = p.parse_args()

    if not dg.COVERAGE.exists():
        print(f'no coverage file at {dg.COVERAGE}. Run fetch_narrative first.')
        return 1
    coverage = json.loads(dg.COVERAGE.read_text(encoding='utf-8'))
    by_slug = dg.rows()
    on_disk, book_pages, problems = build_index(coverage)
    if problems:
        print('the archive index and the coverage file disagree:')
        for line in problems[:12]:
            print(f'  {line}')
        if len(problems) > 12:
            print(f'  ... and {len(problems) - 12} more')
        print()

    if args.slugs:
        chosen = [e for e in coverage['events'] if e['slug'] in set(args.slugs)]
        unknown = set(args.slugs) - {e['slug'] for e in chosen}
        for slug in sorted(unknown):
            print(f'  {slug}: not in the coverage file')
    elif args.all:
        chosen = [e for e in coverage['events'] if e['citations']]
    else:
        chosen = [e for e in coverage['events'] if e.get('too_broad_to_author_from')]

    corpora: dict[str, Corpus] = {}

    def get_corpus(source: str) -> Corpus:
        if source not in corpora:
            corpora[source] = Corpus(source, on_disk)
            c = corpora[source]
            print(f'read {len(c.words)} fetched sections of {source}, '
                  f'{len(c.books)} books')
        return corpora[source]

    out = []
    for event in sorted(chosen, key=lambda e: -e['wanted']):
        row = by_slug.get(event['slug'])
        if row is None or not event['citations']:
            continue
        out += report(event, row, get_corpus, book_pages)

    print('=' * 78)
    inside = [r for r in out if r['propose'] and not r['outside_citation']]
    moved = [r for r in out if r['outside_citation']]
    empty = [r for r in out if not r['propose']]
    print(f'{len(out)} citations read: {len(inside)} narrow inside themselves, '
          f'{len(moved)} point outside, {len(empty)} score nothing')
    for r in sorted(inside, key=lambda r: -len(r['cited_sections'])):
        print(f"  {r['slug']:<20} {len(r['cited_sections']):>3} cited  ->  "
              f"{as_range(r['propose']):<14} ({len(r['propose'])})")
    for r in moved:
        print(f"  {r['slug']:<20} {len(r['cited_sections']):>3} cited  ->  "
              f"look at {', '.join(str(s) for s in r['outside_citation'])}")
    for r in empty:
        print(f"  {r['slug']:<20} {len(r['cited_sections']):>3} cited  ->  "
              f"nothing scores in {r['source']} book {r['book_no']}")
    print('\nNothing was written. A citation changes in the row, through '
          'apply_narrative, with a verifier named.')

    if args.json:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(
            {'generated_by': 'content/tools/narrow_citations.py',
             'task': 'SC-06 groundwork: proposed narrower citations, unapplied',
             'span_max': SPAN_MAX, 'keep_fraction': KEEP_FRACTION,
             'proposals': out}, ensure_ascii=False, indent=1), encoding='utf-8')
        print(f'wrote {OUT_JSON.relative_to(ROOT).as_posix()}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
