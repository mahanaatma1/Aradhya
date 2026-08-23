"""Self-test for the narrative chapter fetcher (SC-04).

    py -m content.tools.selftest_narrative

`fetch_narrative.py` decides which page of a public-domain archive an event's
citation points at. Both halves of that decision fail quietly if they fail at
all: a misread heading files Adi Parva CIV as section 224, and a mis-parsed
citation sends a Drona Parva war day into Bhishma Parva. Either way the fetch
still "succeeds" and the wrong chapter lands on disk under a confident name,
which is exactly the failure the 34-wrong-labels-out-of-34 comment in
`fetch_pd.py` is a memorial to.

So the resolver is exercised here against a fabricated archive whose drift is
known, including the case the real one actually has: an offset that changes
partway through a book. Nothing here touches the network, content/data, or any
database.
"""

from __future__ import annotations

import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools import fetch_narrative as fn  # noqa: E402

CASES: list[tuple[str, object]] = []


def case(name):
    def wrap(fn_):
        CASES.append((name, fn_))
        return fn_
    return wrap


def eq(got, want, what=''):
    if got != want:
        raise AssertionError(f'{what or "value"}: got {got!r}, wanted {want!r}')


# ---------------------------------------------------------------------------
# Reading a page's own heading
# ---------------------------------------------------------------------------

CRUMB = 'Sacred Texts Hinduism Mahabharata Index Previous Next '


@case('a heading that names itself SECTION, in roman')
def _():
    eq(fn.heading_of(CRUMB + 'SECTION C (Sambhava Parva continued ) "Vaisampayana'),
       ('SECTION', 100, 100))


@case('a heading that is a bare number, as Shalya and Karna write it')
def _():
    # Books 8, 9, 11, 16 and 17 drop the word entirely. A parser that insisted
    # on "SECTION" left ten of the thirty-three chapters on disk unidentified.
    eq(fn.heading_of(CRUMB + '32 (Gada-yuddha Parva) "Dhritarashtra said'),
       ('SECTION', 32, 32))
    eq(fn.heading_of(CRUMB + '90 "Sanjaya said'), ('SECTION', 90, 90))


@case('a running title before the heading is not the heading')
def _():
    # The Shanti Parva alone repeats the work's name above the section: its first
    # page reads "THE MAHABHARATA SANTI PARVA SECTION I". A parser that only
    # looked at the first word it could not identify gave up on "THE" and left
    # the section the `mbh-shanti` event opens on unfetched.
    eq(fn.heading_of(CRUMB + 'THE MAHABHARATA SANTI PARVA SECTION I '
                             '"Janamejaya said'), ('SECTION', 1, 1))


@case('a print page marker is not the section number')
def _():
    # "p. 224 SECTION CIV" is Adi Parva 104 printed on page 224. Reading the
    # first number would file it as 224 and every later probe off that book
    # would then be corrected in the wrong direction.
    eq(fn.heading_of(CRUMB + 'p. 224 SECTION CIV (Sambhava Parva continued) "Bhishma'),
       ('SECTION', 104, 104))
    eq(fn.heading_of(CRUMB + 'p. 44 SECTION XXII "Vaisampayana said'),
       ('SECTION', 22, 22))


@case('a Griffith canto, with its title running on')
def _():
    eq(fn.heading_of('Sacred Texts Hinduism Index Previous Next '
                     "CANTO LV.: THE HERMITAGE BURNT. So o'er the field"),
       ('CANTO', 55, 55))


@case('a page that heads itself with a word is unidentified, not guessed')
def _():
    # Sub-parva title pages and volume front matter. Returning a number here
    # would be worse than returning nothing: the resolver would trust it.
    eq(fn.heading_of(CRUMB + 'Sambhava Parva Contents'), None)
    eq(fn.heading_of('Sacred Texts Hinduism Index Previous Next Buy this Book '
                     'at Amazon.com The Vishnu Purana , translated by Horace'), None)
    eq(fn.heading_of(''), None)


@case('roman numerals, including the subtractive ones')
def _():
    for text, want in [('IV', 4), ('IX', 9), ('XL', 40), ('XCIV', 94),
                       ('C', 100), ('CXCV', 195), ('CCXXIV', 224)]:
        eq(fn.from_roman(text), want, text)
    eq(fn.from_roman('SANJAYA'), None, 'a word is not a numeral')
    eq(fn.as_number('LV.:'), 55, 'trailing punctuation from a canto heading')


@case('one page carrying two sections is read as both')
def _():
    # `m12a034.htm` heads itself "SECTION XXXIV-XXXV". One page in the six
    # hundred and thirty-nine does this, and `mbh-shanti` cites both numbers, so
    # reading it as section 34 alone loses a cited chapter and leaves every
    # section after it in the volume measured from the wrong place.
    eq(fn.heading_of(CRUMB + 'SECTION XXXIV-XXXV "Yudhishthira said'),
       ('SECTION', 34, 35))
    eq(fn.as_span('XXXIV-XXXV'), (34, 35))
    eq(fn.as_span('C'), (100, 100), 'the ordinary page is a span of one')
    eq(fn.as_span('PARVA'), None)
    eq(fn.stated(('SECTION', 34, 35)), 'SECTION 34-35', 'as the manifest says it')
    eq(fn.stated(('SECTION', 34, 34)), 'SECTION 34')


# ---------------------------------------------------------------------------
# Reading a citation
# ---------------------------------------------------------------------------

@case('every citation shape the shipped rows actually use')
def _():
    for text, want in [
        # a parva named in words, with an arabic range
        ('Adi Parva, Sections 100-104', (1, [100, 101, 102, 103, 104])),
        # the page's own title, carrying its book number and a roman section
        ('The Mahabharata, Book 1: Adi Parva: Section CXXXIX', (1, [139])),
        ('The Mahabharata, Book 9: Shalya Parva: Section 32', (9, [32])),
        # a kanda and a sarga range
        ('Bala Kanda, sargas 15-18', (1, [15, 16, 17, 18])),
        ('Yuddha Kanda, sargas 22', (6, [22])),
        # a Griffith page title
        ('BOOK I: Canto VI.: The King.', (1, [6])),
        ("Book II: Canto CXVIII.: Anasuya's Gifts.", (2, [118])),
    ]:
        book, sections, note = fn.parse_citation('ganguli-mahabharata', text)
        eq((book, sections), want, text)
        eq(note, '', f'{text} should parse cleanly')


@case('a citation naming a sub-parva instead of a section says so')
def _():
    # `mbh-pashupata` cites "Vana Parva, Kairata Parva". The Kairata Parva is a
    # span of Vana Parva, and which sections it covers is not in the citation.
    # The only honest outputs are a note and no sections.
    book, sections, note = fn.parse_citation('ganguli-mahabharata',
                                             'Vana Parva, Kairata Parva')
    eq(book, 3, 'the outer parva is still identifiable')
    eq(sections, [])
    assert note, 'an unresolvable citation must carry a reason'


@case('the kanda and parva tables agree with the epics they belong to')
def _():
    eq(fn.KANDAS['uttara'], 7)
    eq(fn.PARVAS['bhishma'], 6)
    eq(fn.PARVAS['drona'], 7)
    eq(fn.PARVAS['shalya'], 9)
    eq(fn.PARVAS['svargarohana'], 18)
    for name, no in [('bala', 1), ('yuddha', 6)]:
        book, _, _ = fn.parse_citation('dutt-ramayana', f'{name.title()} Kanda, sargas 1')
        eq(book, no, name)


# ---------------------------------------------------------------------------
# Resolving a section to a page, against a fabricated archive
# ---------------------------------------------------------------------------

class FakeArchive(fn.Archive):
    """An archive whose drift is known, so the resolver can be held to it.

    `pages` maps a position in the book's page list to the section the page there
    carries, or to None for a page with no heading -- a sub-parva title page,
    which the real archive has and which the resolver has to step past rather
    than give up on. A pair means the page carries a span of sections, which one
    page of the real corpus does.

    `names` is the book's page list. Left out, it is the ordinary
    `m04/m04031.htm` shape, so a position and a filename number coincide and the
    assertions below can be read at a glance. Passed in, it is whatever the
    archive actually calls its pages -- which for the Shanti Parva is not the
    ordinary shape at all.
    """

    def __init__(self, source: str, pages: dict[int, int | tuple[int, int] | None],
                 offsets: dict[int, int] | None = None,
                 names: list[str] | None = None):
        super().__init__(source)
        self.offsets = dict(offsets or {})
        self.numbers = pages
        self.names = names
        self.reads: list[int] = []

    def pages_in(self, book: int) -> list[str]:
        if book not in self.order:
            if self.names is not None:
                listed = self.names
            elif self.source == 'griffith-ramayana':
                listed = [f'rama/ry{n:03d}.htm'
                          for n in range(1, self.last_position() + 1)]
            else:
                listed = [f'm{book:02d}/m{book:02d}{n:03d}.htm'
                          for n in range(1, self.last_position() + 1)]
            self.order[book] = listed
            for i, path in enumerate(listed, 1):
                self.where[path] = i
        return self.order[book]

    def last_position(self) -> int:
        return max(self.numbers)

    def read(self, path: str):
        pos = self.where[path]
        self.reads.append(pos)
        if pos not in self.numbers:
            return None
        section = self.numbers[pos]
        if section is None:
            head = None
        elif isinstance(section, tuple):
            head = ('SECTION', *section)
        else:
            head = ('SECTION', section, section)
        return (f'body of page {pos}', head)


def carries(a: FakeArchive, pos: int) -> tuple[int, int] | None:
    """The sections the fake archive's page at `pos` holds, as a span."""
    got = a.numbers.get(pos)
    if got is None:
        return None
    return got if isinstance(got, tuple) else (got, got)


def found(a: FakeArchive, book: int, section: int) -> str | None:
    """The page, dropping the reason. Cases that care about the reason ask for
    it directly."""
    return a.resolve(book, section)[0]


@case('the page list comes from the archive, never from the book number')
def _():
    # The Shanti Parva. Fifteen parvas are m07/m07191.htm; this one was split
    # into three volumes and is m12/m12a001.htm, and computing the name from the
    # book number 404'd on all fifty-six chapters the Shanti event cites. The
    # resolver must be able to land on a page it could not have named.
    names = ['m12/m12a000.htm'] + [f'm12/m12a{n:03d}.htm' for n in range(1, 60)]
    pages: dict[int, int | None] = {1: None}          # the volume title page
    pages.update({p: p - 1 for p in range(2, 61)})
    a = FakeArchive('ganguli-mahabharata', pages, {}, names)
    eq(found(a, 12, 1), 'm12/m12a001.htm',
       'section 1 sits behind the volume title page')
    eq(found(a, 12, 56), 'm12/m12a056.htm')


@case('a book with no page list is reported, not probed')
def _():
    a = FakeArchive('ganguli-mahabharata', {1: 1}, {}, [])
    path, why = a.resolve(13, 4)
    eq(path, None)
    assert 'page list' in why, why
    eq(a.reads, [], 'nothing to probe means no requests')


@case('a book whose files run one ahead of its sections')
def _():
    # Adi Parva: file 101 carries section 100.
    a = FakeArchive('ganguli-mahabharata',
                    {p: p - 1 for p in range(2, 240)}, {1: 1})
    eq(found(a, 1, 100), 'm01/m01101.htm')
    eq(len(a.reads), 1, 'a correct seed costs one read')
    eq(found(a, 1, 139), 'm01/m01140.htm')


@case('a book whose files run behind its sections')
def _():
    # Drona Parva near the end: file 191 carries section 195.
    a = FakeArchive('ganguli-mahabharata',
                    {p: p + 4 for p in range(1, 200)}, {7: -4})
    eq(found(a, 7, 195), 'm07/m07191.htm')


@case('a wrong seed is corrected, not recorded')
def _():
    # The seed says the offset is zero; the archive says it is five. One wrong
    # read, one delta, then right -- and nothing filed under the wrong page.
    a = FakeArchive('ganguli-mahabharata',
                    {p: p - 5 for p in range(6, 100)}, {3: 0})
    eq(found(a, 3, 40), 'm03/m03045.htm')
    eq(a.reads, [40, 45], 'guess, then correct by the delta')
    eq(a.by_section[(3, 40)], 'm03/m03045.htm')


@case('an offset that changes partway through a book')
def _():
    # Griffith's Book I, which is the reason the offset is re-learned from every
    # page instead of being trusted once: canto 6 is file 8, canto 55 is file
    # 55. A single learned offset for the book would miss one of the two.
    pages: dict[int, int | None] = {p: p - 2 for p in range(3, 50)}
    pages.update({p: p for p in range(50, 80)})
    a = FakeArchive('griffith-ramayana', pages, {1: 2})
    eq(found(a, 1, 6), 'rama/ry008.htm')
    eq(found(a, 1, 55), 'rama/ry055.htm')
    eq(found(a, 1, 24), 'rama/ry026.htm')


@case('a chapter the translation omits is called absent, not unresolved')
def _():
    # The live case, and the one the first full run found the hard way: Griffith
    # abridges the war, and Book VI has no cantos 76-92 at all. `ram-indrajit`
    # cites sargas 88-91, every one of them inside that hole. Retrying cannot
    # produce them, so the answer has to say why and name what it did see --
    # otherwise SC-06 spends its time re-fetching a page that does not exist.
    pages: dict[int, int | None] = {p: p for p in range(1, 76)}
    pages.update({p: p + 17 for p in range(76, 114)})
    a = FakeArchive('griffith-ramayana', pages, {6: 0})
    path, why = a.resolve(6, 88)
    eq(path, None)
    assert 'absent from this translation' in why, why
    assert '75' in why and '93' in why, f'name both sides of the hole: {why}'


@case('a title page between sections is stepped past')
def _():
    # A sub-parva title page carries no number and *displaces* what follows it:
    # if file 30 is the title page, section 30 is file 31 and every section after
    # it is one file further on than it was. Stepping past has to leave that
    # widened drift behind it, or the next resolve in the book pays for it again.
    pages: dict[int, int | None] = {p: p for p in range(1, 30)}
    pages[30] = None
    pages.update({p: p - 1 for p in range(31, 60)})
    a = FakeArchive('ganguli-mahabharata', pages, {4: 0})
    eq(found(a, 4, 30), 'm04/m04031.htm',
       'section 30 sits one file later than the arithmetic says')
    eq(a.reads, [30, 31], 'a title page costs one wasted read, not a failure')
    eq(found(a, 4, 45), 'm04/m04046.htm',
       'and the drift it caused is carried forward')


@case('a title page with no section behind it gives up rather than looping')
def _():
    # The step-past is a guess in one direction, and it can be wrong: here the
    # page after the title page is already past the section wanted, so the delta
    # sends the probe back where it began. The section is simply not in this
    # archive, and that has to be reported in a bounded number of reads.
    pages: dict[int, int | None] = {p: p for p in range(1, 60)}
    pages[30] = None
    a = FakeArchive('ganguli-mahabharata', pages, {4: 0})
    path, why = a.resolve(4, 30)
    eq(path, None)
    assert why, 'a failure must carry a reason'
    assert len(a.reads) <= 6, f'{len(a.reads)} reads before giving up'


@case('a section past the end is proved from a heading, not from a page count')
def _():
    # The obvious shortcut -- "the book has 39 pages, so it has no section 500"
    # -- was written here and was wrong. Griffith's Book VI runs 106 pages and
    # numbers its cantos to 130, because he omits chapters and keeps the original
    # numbering; the shortcut declared six chapters absent that were on disk. A
    # page count bounds how many sections are present, never how high they are
    # numbered, so the last page has to be read and its heading believed.
    a = FakeArchive('ganguli-mahabharata', {p: p for p in range(1, 40)}, {5: 0})
    path, why = a.resolve(5, 500)
    eq(path, None)
    assert 'runs only to 39' in why, why
    eq(a.reads, [39], 'one read at the end of the window, and it settles it')


@case('a numbering that skips is followed, not out-guessed')
def _():
    # Griffith's Book VI again, in miniature: 30 pages carrying cantos numbered
    # to 44. Every one of those cantos is present and must be found, however far
    # the number runs past the count of pages.
    pages: dict[int, int | None] = {p: p for p in range(1, 16)}
    pages.update({p: p + 14 for p in range(16, 31)})   # cantos 30-44
    a = FakeArchive('griffith-ramayana', pages, {6: 0})
    a.bounds[6] = (1, 30)
    eq(found(a, 6, 44), 'rama/ry030.htm')
    eq(found(a, 6, 15), 'rama/ry015.htm')


@case('a section already known costs no read at all')
def _():
    a = FakeArchive('ganguli-mahabharata', {p: p for p in range(1, 40)}, {6: 0})
    eq(found(a, 6, 25), 'm06/m06025.htm')
    before = len(a.reads)
    eq(found(a, 6, 25), 'm06/m06025.htm')
    eq(len(a.reads), before, 'the second ask is free')


@case('the resolver never returns a page whose heading disagrees')
def _():
    # An archive that is not monotonic, so the delta correction cannot converge.
    # Giving up is correct; returning the last page probed would not be.
    a = FakeArchive('ganguli-mahabharata',
                    {1: 9, 2: 3, 3: 7, 4: 1, 5: 5}, {2: 0})
    got = found(a, 2, 4)
    assert got is None or carries(a, a.where[got]) == (4, 4), \
        f'resolved to {got}, which does not carry section 4'


@case('both sections of a combined page resolve to it, and so does the next')
def _():
    # The Shanti Parva's page 34 heads itself "SECTION XXXIV-XXXV". Sections 34
    # and 35 are one page, so the page must answer for both -- and after it the
    # file numbering runs one behind the sections for the rest of the volume,
    # which the offset has to pick up rather than fight.
    pages: dict[int, int | tuple[int, int] | None] = {p: p for p in range(1, 34)}
    pages[34] = (34, 35)
    pages.update({p: p + 1 for p in range(35, 60)})
    a = FakeArchive('ganguli-mahabharata', pages, {12: 0},
                    [f'm12/m12a{n:03d}.htm' for n in range(1, 60)])
    eq(found(a, 12, 34), 'm12/m12a034.htm')
    eq(found(a, 12, 35), 'm12/m12a034.htm', 'the same page carries both')
    eq(found(a, 12, 40), 'm12/m12a039.htm',
       'and the drift the combined page causes is carried forward')


@case("Griffith's six books are seeded from the index that states them")
def _():
    # His pages are numbered across the whole work, so nothing on disk can be
    # filed under a book without guessing. The index names the page each book
    # opens on; that is a fact to read. The old hardcoded seed had Book IV at
    # file 274 when the index says 275 -- which is exactly the drift a
    # hand-maintained table acquires.
    a = FakeArchive('griffith-ramayana', {1: 1})
    a.seed_from_index(1, ['Title Page', 'Invocation', 'Book I',
                          'Canto I.: Nárad.', 'Canto II.: Brahmá’s Visit.'])
    eq(a.offsets[1], 2, 'Book I opens at the third page listed')
    eq(a.window(1), (3, 5), 'and runs to the end of what the index lists')
    assert a.seeded, 'the index is read once, not once per book'


@case('a canto number that repeats in another book stays inside its own')
def _():
    # Griffith's Book III and Book VI both have a Canto LIV, so the page list is
    # monotonic only *within* a book. Unfenced, a search for Book VI canto 108
    # overshot the end of the volume, fell back to the midpoint of all 505 pages,
    # landed in Book III, read a canto number far below 108 and concluded from it
    # that 108 was missing. Six of Griffith's chapters were reported absent that
    # way, and every one of them was on disk already.
    labels = (['Title Page', 'Book I'] + [f'Canto {i}' for i in range(1, 21)]
              + ['Book II'] + [f'Canto {i}' for i in range(1, 21)])
    names = [f'rama/ry{i:03d}.htm' for i in range(len(labels))]
    pages: dict[int, int | None] = {1: None, 2: None, 23: None}
    pages.update({p: p - 2 for p in range(3, 23)})      # Book I, cantos 1-20
    pages.update({p: p - 23 for p in range(24, 44)})    # Book II, cantos 1-20
    a = FakeArchive('griffith-ramayana', pages, {}, names)
    a.pages_in(1)
    a.seed_from_index(1, labels)
    eq(a.window(1), (2, 22))
    eq(a.window(2), (23, 43))
    eq(found(a, 2, 15), 'rama/ry037.htm',
       "Book II's canto 15, not the identically numbered one in Book I")
    assert all(p >= 23 for p in a.reads), \
        f'the search wandered out of Book II: {a.reads}'


def main() -> int:
    failures = 0
    for name, test in CASES:
        try:
            test()
        except Exception as e:                            # noqa: BLE001
            failures += 1
            print(f'  FAIL  {name}\n          {type(e).__name__}: {e}')
        else:
            print(f'  ok    {name}')
    print(f'selftest_narrative: {len(CASES) - failures}/{len(CASES)} passed')
    return 1 if failures else 0


if __name__ == '__main__':
    raise SystemExit(main())
