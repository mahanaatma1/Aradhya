"""Stage 1c -- fetch the PD chapter behind every mapped narrative event (SC-04).

`fetch_pd.py` keeps a hand-written list of chapters, chosen for the figures they
introduce. This one is driven by the events themselves: every row under
`content/data/narrative/` already states the chapter it is written from, and
this script resolves that citation to a page, fetches it, and records what the
page says it actually is.

Nothing here trusts a guess -- not the label on a page, and not the name of the
file either. Sacred-texts numbers its files sequentially across a whole work
while the text numbers its own sections, and the two drift: Adi Parva runs one
ahead of its files, Drona Parva four behind, and inside Griffith's Book I the
offset changes from two to zero partway through. Worse, the file *names* are not
computable: fifteen parvas are `m07/m07191.htm`, but the Shanti Parva is long
enough that the archive split it into three volumes, `m12a###`, `m12b###`,
`m12c###`. So each book's page list is read from the book's own index, a page is
a position in that list, every page's own `SECTION` / `CANTO` heading is read,
and a mismatch corrects the guess and tries again instead of being filed as
though it were right. The lesson is inherited: the first pass of this corpus
guessed 34 labels from URLs and was wrong 34 times.

Where a chapter is genuinely absent, the coverage file says so in words. Two
kinds of absence turned up on the first full run and they are not the same
problem: Griffith *abridges* the war and simply has no Canto LXXXVIII of Book VI,
which no amount of retrying will produce, while a 404 across a whole book means
the page list was wrong.

Outputs

  content/raw/<source>/<page>.txt        the stripped text, reusing whatever
                                         fetch_pd.py already put there
  content/raw/narrative_manifest.json    per file: the heading the page states,
                                         sha256, and which events cite it
  content/sources/narrative_coverage.json
                                         per event: what it cites, what is on
                                         disk, and why anything is missing

`content/raw/` is gitignored -- the texts are large and freely re-downloadable,
and the sha256 is what makes the corpus reproducible. The coverage file is
committed, because it is the worklist SC-05..08 read: an event may only be
written from chapters this file says are present.

This script reads the narrative JSONL and writes only to raw/ and to the
coverage file. It does not touch the schema, the shipped databases, or any
content row.
"""
import hashlib
import html
import json
import pathlib
import re
import sys
import time
import urllib.request

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

REPO = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
RAW = REPO / 'content' / 'raw'
NARR = REPO / 'content' / 'data' / 'narrative'
COVERAGE = REPO / 'content' / 'sources' / 'narrative_coverage.json'
MANIFEST = RAW / 'narrative_manifest.json'

BASE = "https://sacred-texts.com/hin/"
UA = ("Aradhya/1.0 (offline devotional app; public-domain text fetch; "
      "contact: sumerudigitalsm@gmail.com)")
PAUSE = 1.5          # be a polite guest on a free archive

# The eighteen books of the Mahabharata and the seven of the Ramayana, in the
# spellings the citations actually use. `book_no` in the data is authoritative;
# these exist to read a citation that names its book in words.
PARVAS = {
    'adi': 1, 'sabha': 2, 'vana': 3, 'virata': 4, 'udyoga': 5, 'bhishma': 6,
    'drona': 7, 'karna': 8, 'shalya': 9, 'sauptika': 10, 'stri': 11,
    'shanti': 12, 'anushasana': 13, 'ashvamedhika': 14, 'ashramavasika': 15,
    'mausala': 16, 'mahaprasthanika': 17, 'svargarohana': 18,
    # spellings sacred-texts and the older rows use
    'santi': 12, 'anusasana': 13, 'aswamedha': 14, 'asramavasika': 15,
    'mausala parva': 16, 'sauptika parva': 10, 'salya': 9, 'udyoga parva': 5,
}
KANDAS = {
    'bala': 1, 'ayodhya': 2, 'aranya': 3, 'kishkindha': 4, 'sundara': 5,
    'yuddha': 6, 'uttara': 7, 'lanka': 6, 'kiskindha': 4,
}

# Where each book's first section sits in the file numbering was hardcoded here
# from the chapters already on disk. It no longer is, and the deletion is the
# point: with 400-odd chapters already fetched, `prime_from_disk` learns the
# drift of fourteen of the fifteen cited parvas at no network cost, and Griffith's
# index states outright where each of his six books begins. A book with neither --
# the Shanti Parva was the one -- starts from zero and is corrected by the second
# read. A seed that has to be maintained by hand is a seed that goes stale.

# A content page of either work, as its own index links to it: `m07191.htm`,
# `m12a001.htm`, `ry399.htm`. `index.htm`, `errata.htm` and the navigation
# crumbs do not match, which is what keeps them out of the page list.
PAGE_FILE = re.compile(r'^(?:m\d\d[a-z]?\d+|ry\d+)\.htm$', re.I)
LINK = re.compile(r'href="([^"]+)"[^>]*>(.*?)</a>', re.I | re.S)
BOOK_LABEL = re.compile(r'^book\s+([ivxlcdm]+)\s*$', re.I)

ROMAN = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def from_roman(s: str) -> int | None:
    s = s.upper()
    if not s or any(ch not in ROMAN for ch in s):
        return None
    total = 0
    for i, ch in enumerate(s):
        v = ROMAN[ch]
        nxt = ROMAN.get(s[i + 1]) if i + 1 < len(s) else None
        total += -v if nxt and nxt > v else v
    return total


def as_number(token: str) -> int | None:
    token = token.strip().rstrip('.:').strip()
    if token.isdigit():
        return int(token)
    return from_roman(token)


def as_span(token: str) -> tuple[int, int] | None:
    """A heading's number, or the pair of them it covers.

    `m12a034.htm` heads itself "SECTION XXXIV-XXXV": Ganguli put two sections on
    one page. Exactly one page of the six hundred and thirty-nine here does
    that -- and both sections behind it are cited by a shipped event, so it is
    not a curiosity to round off. Reading it as one number loses a chapter and
    leaves every section after it in the volume off by one.
    """
    parts = re.split(r'[-–—]', token.strip().rstrip('.:').strip())
    nums = [as_number(p) for p in parts if p]
    if not nums or any(n is None for n in nums):
        return None
    return nums[0], nums[-1]


def stated(head: tuple[str, int, int] | None) -> str | None:
    """The heading as the manifest records it: what the page called itself."""
    if head is None:
        return None
    kind, first, last = head
    return f'{kind} {first}' if first == last else f'{kind} {first}-{last}'


def strip_html(raw: str) -> str:
    raw = re.sub(r'(?is)<(script|style|head).*?</\1>', ' ', raw)
    txt = re.sub(r'<[^>]+>', ' ', raw)
    txt = html.unescape(txt)
    return re.sub(r'\s+', ' ', txt).strip()


# The heading a page gives itself, which is the only identification trusted
# here -- and it is not written the same way twice. Adi Parva says "SECTION C
# (Sambhava Parva continued)". The Shanti Parva prints a running title first:
# "THE MAHABHARATA SANTI PARVA SECTION I". Griffith says "CANTO LV.: THE
# HERMITAGE BURNT." Shalya, Karna, Stri, Mausala and Mahaprasthanika drop the
# word entirely and open on a bare "32". So there are two passes: find the word
# and take the number after it wherever it sits, and failing that walk past the
# navigation crumbs and read the first token that is a number in either notation.
# A page with neither -- a sub-parva title page, front matter -- comes back
# unidentified, which is what it is.
CRUMBS = {'sacred', 'texts', 'hinduism', 'mahabharata', 'ramayana',
          'index', 'previous', 'next'}
NAMES = ('section', 'canto')


def heading_of(body: str) -> tuple[str, int, int] | None:
    """What a page says it is: the kind, and the first and last section on it.

    Almost always the two numbers are the same. The one page that carries a span
    is why the shape has room for two.
    """
    tokens = body[:400].split()

    for i, token in enumerate(tokens[:-1]):
        word = token.strip('.:,;').lower()
        if word in NAMES:
            # The number must follow immediately. "SECTION" with prose after it
            # is a word in a sentence, not a heading.
            span = as_span(tokens[i + 1])
            if span:
                return word.upper(), *span

    after_page_marker = False
    for token in tokens:
        word = token.strip('.:,;').lower()
        if word in CRUMBS:
            continue
        if word == 'p':
            # A print page marker, "p. 224". It sits before the heading on some
            # pages and not others, and mistaking it for the section number
            # would file Adi Parva CIV as section 224.
            after_page_marker = True
            continue
        if after_page_marker:
            after_page_marker = False
            if word.isdigit():
                continue
        span = as_span(token)
        return ('SECTION', *span) if span else None
    return None


class Archive:
    """Sacred-texts, with the file-to-section drift learned as it goes."""

    def __init__(self, source: str):
        self.source = source
        self.offsets: dict[int, int] = {}
        self.fetched = 0
        self.requests = 0
        # page path -> (body, heading) for everything seen this run or already
        # on disk, so a section wanted by four events costs one request.
        self.pages: dict[str, tuple[str, tuple[str, int] | None]] = {}
        self.by_section: dict[tuple[int, int], str] = {}
        # The book's own page list, and the position of each page in it. A
        # "position" is this tool's only notion of where a chapter lives; the
        # digits in a filename are the archive's business, not ours.
        self.order: dict[int, list[str]] = {}
        self.where: dict[str, int] = {}
        self.bounds: dict[int, tuple[int, int]] = {}
        self.seeded = False

    # -- page naming ------------------------------------------------------
    def dir_for(self, book: int) -> str:
        return 'rama' if self.source == 'griffith-ramayana' else f'm{book:02d}'

    def index_for(self, book: int) -> str:
        # Griffith is one volume with six books inside it and one index for the
        # lot; each parva is its own volume with its own.
        return f'{self.dir_for(book)}/index.htm'

    def pages_in(self, book: int) -> list[str]:
        """The pages this book actually has, in the order its index gives them.

        This exists because the naming is not computable. Building
        `m12/m12001.htm` from the book number returned 404 for all fifty-six
        chapters the Shanti Parva event cites, because the archive calls them
        `m12/m12a001.htm`. Reading the list costs one request per book and
        removes the guess rather than patching it.

        The list is cached beside the chapters, so a re-run costs nothing.
        """
        if book in self.order:
            return self.order[book]
        cache = RAW / self.source / f'_order_{self.dir_for(book)}.json'
        listed: list[list[str]] | None = None
        if cache.exists():
            listed = json.loads(cache.read_text(encoding='utf-8'))
        else:
            raw = self.fetch_raw(self.index_for(book))
            if raw is not None:
                listed, seen = [], set()
                for href, label in LINK.findall(raw):
                    if PAGE_FILE.match(href) and href not in seen:
                        seen.add(href)
                        listed.append([href, strip_html(label)])
                cache.parent.mkdir(parents=True, exist_ok=True)
                cache.write_text(json.dumps(listed, ensure_ascii=False),
                                 encoding='utf-8')
        if not listed:
            self.order[book] = []
            return []
        d = self.dir_for(book)
        self.order[book] = [f'{d}/{href}' for href, _ in listed]
        for i, path in enumerate(self.order[book], 1):
            self.where[path] = i
        self.seed_from_index(book, [label for _, label in listed])
        return self.order[book]

    def seed_from_index(self, book: int, labels: list[str]) -> None:
        """Take Griffith's six book divisions from the index that states them.

        His pages are numbered across the whole work, so nothing on disk can be
        filed under a book without guessing -- but the index names the page each
        book opens on, in the archive's own words. That is a fact to read, not a
        number to maintain. It seeds the first probe; the heading still decides.

        It also *fences* each book, which matters more than the seed does. His
        canto numbers restart at every book -- Book III and Book VI both have a
        Canto LIV -- so a search that may roam the whole volume is searching a
        sequence that is not monotonic, and will happily walk out of Book VI into
        Book III and conclude the canto does not exist. The fence is what makes
        the sequence monotonic again.
        """
        if self.source != 'griffith-ramayana' or self.seeded:
            return
        self.seeded = True
        starts: list[tuple[int, int]] = []
        for i, label in enumerate(labels, 1):
            m = BOOK_LABEL.match(label.strip())
            n = from_roman(m.group(1)) if m else None
            if n:
                starts.append((n, i))
        for j, (n, first) in enumerate(starts):
            # Up to the page the next book opens on, or the end of the volume for
            # the last -- whose tail is an index and an errata, both of which are
            # headless and get stepped over.
            last = starts[j + 1][1] - 1 if j + 1 < len(starts) else len(labels)
            self.bounds[n] = (first, last)
            self.offsets[n] = first - 1

    def window(self, book: int) -> tuple[int, int]:
        """The stretch of the page list this book's sections can be in."""
        return self.bounds.get(book, (1, len(self.pages_in(book))))

    def path_for(self, book: int, pos: int) -> str | None:
        order = self.pages_in(book)
        return order[pos - 1] if 1 <= pos <= len(order) else None

    def local(self, path: str) -> pathlib.Path:
        source_dir = RAW / self.source
        name = path.replace('/', '_').replace('.htm', '.txt')
        # fetch_pd.py wrote rama_ry008.txt; keep the same names so its 55
        # chapters are reused rather than downloaded a second time.
        return source_dir / name

    # -- one page ---------------------------------------------------------
    def fetch_raw(self, path: str) -> str | None:
        """The page as sent. Only the index needs this -- stripping an index of
        its tags would take the hrefs with it."""
        try:
            req = urllib.request.Request(BASE + path, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=45) as r:
                raw = r.read().decode('utf-8', 'replace')
        except Exception as e:                            # noqa: BLE001
            print(f'    FAIL {path}: {type(e).__name__}')
            return None
        self.requests += 1
        time.sleep(PAUSE)
        return raw

    def read(self, path: str) -> tuple[str, tuple[str, int] | None] | None:
        if path in self.pages:
            return self.pages[path]
        dest = self.local(path)
        if dest.exists():
            body = dest.read_text(encoding='utf-8')
        else:
            raw = self.fetch_raw(path)
            if raw is None:
                self.pages[path] = None
                return None
            body = strip_html(raw)
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(body, encoding='utf-8')
            self.fetched += 1
        got = (body, heading_of(body))
        self.pages[path] = got
        return got

    def prime_from_disk(self, book: int) -> None:
        """Learn the drift for free from chapters already fetched.

        Between fetch_pd.py and the first run of this script there are four
        hundred chapters here. Each Mahabharata file names its book in its own
        filename and its section in its first line, so the drift for that book is
        knowable without a single request -- which is the only reason a
        six-hundred-chapter run is a polite one.

        Griffith is deliberately not primed this way. A canto heading says
        "CANTO LV" without saying which book, so a file on disk cannot be filed
        under a book without guessing -- and guessing here would poison the
        offset for a book the file does not belong to. His divisions come from
        `seed_from_index` instead, where the archive states them. Those pages are
        still reused; they are just recognised when a resolve asks for them,
        where the book is known.
        """
        if self.source == 'griffith-ramayana':
            return
        for path in self.pages_in(book):
            if not self.local(path).exists():
                continue
            got = self.read(path)
            if got and got[1]:
                self.remember(book, self.where[path], *got[1][1:])

    def remember(self, book: int, pos: int, first: int, last: int) -> None:
        path = self.path_for(book, pos)
        if path is not None:
            # A page heading itself "SECTION XXXIV-XXXV" is the page for both, so
            # both are filed against it. The offset is measured from the first
            # section on the page, because that is where the page begins.
            for section in range(first, last + 1):
                self.by_section[(book, section)] = path
        self.offsets[book] = pos - first

    # -- resolution -------------------------------------------------------
    def resolve(self, book: int, section: int,
                tries: int = 12) -> tuple[str | None, str]:
        """Find the page carrying (book, section), correcting as it goes.

        The search is a window that only ever shrinks. It opens on the stretch of
        the page list the book occupies, and every heading read closes one side of
        it: a page saying XL when XLV was wanted rules out itself and everything
        before it. While only one side is known the next probe is a straight delta
        -- a page saying XL when XLV was wanted is five short of the mark, and
        that lands on the answer in one more read, which is what makes a
        six-hundred-chapter run cheap. Once both sides are known the delta has
        been proved untrustworthy, so the probe bisects instead.

        The window is why this cannot give up early. It ends when it is empty,
        and an empty window is a proof: no unread page is left that could carry
        the section, and the two pages that closed it name the gap exactly.
        "Griffith runs 75 then 93" tells SC-06 which sargas this translation
        drops; "somewhere between 71 and 105" would not.

        Returns the page and an empty string, or nothing and the reason. The
        reason is not decoration -- it is the difference between a chapter this
        translation omits and a page list that is wrong, and the first full run
        turned up one of each.
        """
        if (book, section) in self.by_section:
            return self.by_section[(book, section)], ''
        order = self.pages_in(book)
        if not order:
            return None, f'book {book} has no page list in this archive'
        left, right = self.window(book)
        # There is deliberately no "section N > page count, so it cannot exist"
        # shortcut here. It was written, and it was wrong: Griffith's Book VI runs
        # 106 pages and numbers its cantos to 130, because he omits chapters and
        # keeps the original numbering. A page count bounds how many sections are
        # *present*, never how high they are *numbered*. Absence gets proved from
        # a heading or not at all.

        lo = hi = None      # nearest headings below and above the target
        seen: set[int] = set()
        pos = min(max(section + self.offsets.get(book, 0), left), right)

        for _ in range(tries):
            if left > right:
                break
            if pos in seen or not left <= pos <= right:
                pos = next((p for p in self.sweep(left, right) if p not in seen),
                           0)
                if not pos:
                    break
            seen.add(pos)
            path = order[pos - 1]
            got = self.read(path)
            if got is None:
                return None, f'{path} could not be fetched'
            head = got[1]
            if head is None:
                # A title page, an index, an errata. It rules out nothing, so the
                # window does not move; only this page is struck off.
                pos += 1
                continue
            self.remember(book, pos, *head[1:])
            first, last = head[1], head[2]
            if first <= section <= last:
                return path, ''
            if last < section:
                lo, left = (pos, last), pos + 1
                edge = last
            else:
                hi, right = (pos, first), pos - 1
                edge = first
            pos = ((left + right) // 2 if lo and hi
                   else min(max(pos + section - edge, left), right))

        if left > right:
            # The window closed. Whatever shut each side is the evidence.
            if lo and hi:
                return None, ('absent from this translation, which runs '
                              f'{lo[1]} then {hi[1]}')
            if lo:
                return None, (f'this translation runs only to {lo[1]}, so it '
                              f'has no section {section}')
            if hi:
                return None, (f'this translation opens at {hi[1]}, so it has '
                              f'no section {section}')
        if lo and hi:
            # Out of probes with the window still open. Say that, rather than
            # name two sections as though they were neighbours.
            return None, (f'not found between the pages carrying {lo[1]} and '
                          f'{hi[1]}, after {len(seen)} probes')
        return None, f'no page carrying section {section} in {len(seen)} probes'

    @staticmethod
    def sweep(left: int, right: int):
        """Positions to fall back on when the delta lands somewhere already read.
        The midpoint first, because halving the window beats stepping through it.
        """
        yield (left + right) // 2
        yield from range(left, right + 1)





# ---------------------------------------------------------------------------
# Citations
# ---------------------------------------------------------------------------

def parse_citation(source: str, text: str) -> tuple[int | None, list[int], str]:
    """Read a citation into (book_no, sections, note).

    Four shapes appear in the shipped rows:
      "Adi Parva, Sections 100-104"                       book by name, a range
      "The Mahabharata, Book 1: Adi Parva: Section CXXXIX"  the page's own title
      "Bala Kanda, sargas 15-18"                          a kanda, a sarga range
      "BOOK I: Canto VI.: The King."                      a Griffith page title
    `note` is non-empty when the citation cannot be turned into section numbers,
    and it is carried into the coverage file rather than being smoothed over.
    """
    low = text.lower()

    book = None
    m = re.search(r'\bbook\s+(\d+)\b', low)
    if m:
        book = int(m.group(1))
    if book is None:
        m = re.search(r'\bbook\s+([ivxlcdm]+)\b', low)
        if m:
            book = from_roman(m.group(1))
    if book is None:
        table = KANDAS if 'kanda' in low or 'canto' in low or source.endswith('ramayana') else PARVAS
        for name, no in table.items():
            if re.search(rf'\b{re.escape(name)}\b', low):
                book = no
                break

    # A range, in either script's word for a chapter.
    m = re.search(r'\b(?:sections?|sargas?|cantos?)\s+([ivxlcdm\d]+)\s*[-\u2013]\s*([ivxlcdm\d]+)',
                  low)
    if m:
        a, b = as_number(m.group(1)), as_number(m.group(2))
        if a and b and b >= a:
            return book, list(range(a, b + 1)), ''
    m = re.search(r'\b(?:sections?|sargas?|cantos?)\s+([ivxlcdm\d]+)', low)
    if m:
        n = as_number(m.group(1))
        if n:
            return book, [n], ''

    return book, [], 'citation names no section, sarga or canto'


def load_events() -> list[dict]:
    rows = []
    for f in sorted(NARR.glob('*.jsonl')):
        for line in f.read_text(encoding='utf-8').splitlines():
            if line.strip():
                r = json.loads(line)
                r['_file'] = f.name
                rows.append(r)
    rows.sort(key=lambda r: (r['epic'], r['sequence_no']))
    return rows


def main() -> int:
    events = load_events()
    archives = {
        'ganguli-mahabharata': Archive('ganguli-mahabharata'),
        'griffith-ramayana': Archive('griffith-ramayana'),
    }

    # Everything already on disk, read once, so the drift is known before the
    # first request of the run.
    print('reading what is already here...')
    for book in range(1, 19):
        archives['ganguli-mahabharata'].prime_from_disk(book)
    for a in archives.values():
        print(f'  {a.source:<22} {len(a.pages):>3} chapters on disk, '
              f'{len(a.by_section):>3} identified')

    cites: dict[str, set[str]] = {}
    coverage = []
    for ev in events:
        want = []
        for s in ev['sources']:
            slug = s['source_slug']
            text = s['source_chapter_or_section']
            book, sections, note = parse_citation(slug, text)
            # A Dutt sarga citation is a citation to the Valmiki recension. The
            # text fetched for it is Griffith of the same sarga -- the other
            # English translation of the same recension, and the one this
            # corpus already holds. That substitution is recorded per entry,
            # never folded into the citation: SC-06 must either re-cite to what
            # was read or fetch Dutt itself.
            read_from = 'griffith-ramayana' if slug == 'dutt-ramayana' else slug
            want.append({
                'cited_source': slug,
                'cited_as': text,
                'read_from': read_from,
                # The citation's own book wins over the row's `book_no`, and the
                # eight rows where they disagree are all war days: days 11-15
                # cite Drona, 16-17 Karna, 18 Shalya, while every day is filed
                # under Bhishma so the eighteen stay one sub-view instead of
                # scattering across four parvas (SC-12). `book_no` is where the
                # day is *shown*; the citation is where it is *written from*.
                'book_no': book if book is not None else ev['book_no'],
                'sections': sections,
                'note': note,
            })

        entry = {
            'slug': ev['slug'],
            'epic': ev['epic'],
            'book_no': ev['book_no'],
            'sequence_no': ev['sequence_no'],
            'title_en': ev['title']['en'],
            'war_day': 'war-day' in ev.get('tags', []),
            'citations': want,
            'chapters': [],
            'missing': [],
            'blocked': [],
        }

        for w in want:
            arc = archives.get(w['read_from'])
            if arc is None:
                entry['blocked'].append(
                    f"{w['cited_source']} is not fetchable from this archive")
                continue
            if w['note']:
                entry['blocked'].append(f"{w['cited_as']}: {w['note']}")
                continue
            book = w['book_no']
            print(f"  {ev['slug']:<24} {w['read_from'][:8]} bk{book:<2} "
                  f"{len(w['sections']):>3} sections")
            for sec in w['sections']:
                path, why = arc.resolve(book, sec)
                if path is None:
                    entry['missing'].append({'book_no': book, 'section': sec,
                                             'reason': why})
                    continue
                entry['chapters'].append({
                    'source_slug': w['read_from'],
                    'book_no': book,
                    'section': sec,
                    'path': path,
                    'file': str(arc.local(path).relative_to(RAW)),
                })
                cites.setdefault(path, set()).add(ev['slug'])

        wanted = sum(len(w['sections']) for w in want)
        entry['wanted'] = wanted
        entry['present'] = len(entry['chapters'])
        # Stated, not implied. A range this wide is a pointer at a span of the
        # book rather than at an incident, and prose cannot honestly be written
        # from it until SC-06 narrows it.
        entry['too_broad_to_author_from'] = wanted > 12
        coverage.append(entry)

    manifest = []
    for source, arc in archives.items():
        for path, got in sorted(arc.pages.items()):
            if got is None:
                continue
            body, head = got
            dest = arc.local(path)
            manifest.append({
                'source_slug': source,
                'path': path,
                'heading': stated(head),
                'heading_verified': head is not None,
                'file': str(dest.relative_to(RAW)),
                'chars': len(body),
                'sha256': hashlib.sha256(body.encode('utf-8')).hexdigest(),
                'cited_by': sorted(cites.get(path, ())),
            })
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1),
                        encoding='utf-8')

    COVERAGE.parent.mkdir(parents=True, exist_ok=True)
    COVERAGE.write_text(json.dumps({
        'generated_by': 'content/tools/fetch_narrative.py',
        'task': 'SC-04',
        'events': coverage,
    }, ensure_ascii=False, indent=1), encoding='utf-8')

    full = [e for e in coverage if e['wanted'] and e['present'] == e['wanted']]
    part = [e for e in coverage if e['present'] and e['present'] < e['wanted']]
    none = [e for e in coverage if not e['present']]
    broad = [e for e in coverage if e['too_broad_to_author_from']]
    print(f"\n{len(manifest)} chapters on disk, "
          f"{sum(m['chars'] for m in manifest) / 1000:.0f}k chars")
    print(f"  {sum(a.fetched for a in archives.values())} fetched this run")
    print(f"\nevents: {len(coverage)}")
    print(f"  every cited chapter present : {len(full)}")
    print(f"  some chapters present       : {len(part)}")
    print(f"  nothing present             : {len(none)}")
    print(f"  citation too broad to author from: {len(broad)}")
    # Every shortfall says why, in the archive's own terms. "Unresolved" is not a
    # finding; "Griffith runs 75 then 93" is, and it is the difference between a
    # chapter to re-fetch and a chapter that does not exist in this translation.
    for e in part + none:
        for line in e['blocked']:
            print(f"    {e['slug']:<24} {line}")
        for why, secs in sorted(reasons(e['missing']).items()):
            print(f"    {e['slug']:<24} {compress(secs)}: {why}")
    return 0


def reasons(missing: list[dict]) -> dict[str, list[int]]:
    """Group a shortfall by its cause, because fifty-six identical lines hide the
    one line that matters."""
    out: dict[str, list[int]] = {}
    for m in missing:
        out.setdefault(m.get('reason') or 'no reason recorded', []).append(
            m['section'])
    return out


def compress(sections: list[int]) -> str:
    """1,2,3,7 -> "1-3, 7". A run of consecutive sections is one citation."""
    runs: list[list[int]] = []
    for s in sorted(sections):
        if runs and s == runs[-1][-1] + 1:
            runs[-1].append(s)
        else:
            runs.append([s])
    return ', '.join(str(r[0]) if len(r) == 1 else f'{r[0]}-{r[-1]}' for r in runs)


if __name__ == '__main__':
    raise SystemExit(main())
