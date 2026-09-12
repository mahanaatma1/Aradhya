"""Fetch public-domain source chapters into content/raw/.

These are the texts our prose is written FROM. The pipeline rule is that
structure comes from Wikidata (CC0) and substance comes from public-domain
translations -- never from Wikipedia, whose CC BY-SA share-alike would infect
everything we write.

raw/ is gitignored. What makes the corpus reproducible is the sha256 recorded
per file, not the bytes being committed.

Whole works, not selected chapters. The selective version of this script fetched
the ~40 chapters that were cited at the time, and that turned out to be the
wrong unit: 165 rows cite Wilson across about 35 distinct chapters while 14 were
on disk, so most of those citations named a chapter no later reader could open,
even though `content/raw/wilson-vishnu-purana/` existed and the source counted
as fetched. Taking the whole work costs one long run of a job that never has to
happen again -- every author here died before 1930 -- and makes any citation
checkable, including the ones not written yet.

Every work here was published before 1929 and is public domain in the United
States, where the Internet Sacred Text Archive hosts them:

  Wilson, The Vishnu Purana (1840)
  Ganguli, The Mahabharata (1883-1896)
  Griffith, The Ramayan of Valmiki (1870-1874)
  Griffith, The Hymns of the Rigveda (1896)
  Telang, The Bhagavadgita (Sacred Books of the East vol. 8, 1882)
  Müller, The Upanishads (Sacred Books of the East vols. 1 and 15, 1879-1884)
"""
import hashlib, html, json, pathlib, re, sys, time, urllib.request

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

UA = ("Aradhya/1.0 (offline devotional app; public-domain text fetch; "
      "contact: sumerudigitalsm@gmail.com)")
RAW = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani\content\raw')
RAW.mkdir(parents=True, exist_ok=True)

# The ARCHIVE subdomain, not the bare one. sacred-texts.com has been rebuilt as
# a JavaScript application: hin/m01/m01001.htm still returns 200, but the body is
# 427,593 characters of sidebar, category tree and script tags with the chapter
# rendered client-side. strip_html() would have written that navigation chrome
# into content/raw/ as "the primary text", and every citation fetched afterwards
# would have pointed at it. archive.sacred-texts.com still serves the original
# flat pages -- 19,147 characters for the same chapter, text included. The files
# already on disk predate the rebuild, which is why nothing looked wrong: the
# fetcher skips what it has, so the breakage only shows on a new target.
BASE = "https://archive.sacred-texts.com/hin/"

# Griffith's Rigveda, all ten mandalas. Counts confirmed by probing each
# boundary rather than trusted: for every mandala the hymn below returns 200 and
# the next number 404. The whole text is taken instead of only the ~15 hymns
# cited today because the alternative is a fetch pass per citation on a corpus
# that will not change again -- Griffith died in 1906 -- and because RS-02 and
# RS-03 need to look up arbitrary suktas by rishi.
RIGVEDA_HYMNS = {1: 191, 2: 43, 3: 62, 4: 58, 5: 87, 6: 75,
                 7: 104, 8: 103, 9: 114, 10: 191}


def rigveda_targets() -> list[tuple[str, str]]:
    """(path, label) for every hymn. The real label comes from the page title."""
    return [(f"rigveda/rv{m:02d}{h:03d}.htm", f"Mandala {m}, Hymn {h}")
            for m, n in RIGVEDA_HYMNS.items() for h in range(1, n + 1)]

# Individual chapters, kept as a supplement to the whole-work lists discovered
# from the indexes below. What they carry that a generated list cannot is WHY a
# page matters -- each label here records the figure the page was located for,
# usually by probing the volume rather than guessing a canto number. They are
# also the only entries whose labels are already verified against the page.
TARGETS = {
    # Wilson, Vishnu Purana -- cosmology, Lakshmi, the dynasties
    "wilson-vishnu-purana": [
        ("vp/vp036.htm", "Book I, Chapter I"),
        ("vp/vp037.htm", "Book I, Chapter II"),
        ("vp/vp044.htm", "Book I, Chapter IX"),
        ("vp/vp049.htm", "Book I, Chapter XIV"),
        ("vp/vp062.htm", "Book II, Chapter I"),
        ("vp/vp063.htm", "the seven Patalas"),
        ("vp/vp065.htm", "the seven upper spheres"),
        ("vp/vp082.htm", "Book III, Chapter I"),
        ("vp/vp101.htm", "Book IV, Chapter I"),
        ("vp/vp102.htm", "Book IV, Chapter II"),
        ("vp/vp108.htm", "Book IV, Chapter VIII"),
        ("vp/vp120.htm", "Book IV, Chapter XX"),
        ("vp/vp127.htm", "Book V, Chapter I"),
        ("vp/vp131.htm", "Book V, Chapter V"),
    ],
    # Ganguli, Mahabharata -- Adi Parva introduces nearly every major figure
    "ganguli-mahabharata": [
        ("m01/m01063.htm", "Adi Parva, Section LXIII"),
        ("m01/m01067.htm", "Adi Parva, Section LXVII"),
        ("m01/m01095.htm", "Adi Parva, Section XCV"),
        ("m01/m01100.htm", "Adi Parva, Section C"),
        ("m01/m01123.htm", "Adi Parva, Section CXXIII"),
        ("m01/m01130.htm", "Adi Parva, Section CXXX"),
        # Rishi encyclopedia: Agastya, Markandeya, Narada, Chyavana.
        ("m03/m03096.htm", "Vana Parva, Agastya"),
        ("m03/m03097.htm", "Vana Parva, Agastya"),
        ("m03/m03122.htm", "Vana Parva, Chyavana"),
        ("m03/m03186.htm", "Vana Parva, Markandeya"),
        ("m03/m03187.htm", "Vana Parva, Markandeya"),
        # A "m12/m12124.htm" for Narada in the Santi Parva stood here and had
        # never once succeeded: Santi is split into lettered volumes, so its
        # pages are m12/m12a000.htm through m12/m12c063.htm and a bare m12124
        # 404'd on every run. The FAIL line scrolled past in a job printing
        # hundreds of successes, and because the fetcher skips what it has, a
        # path that never arrives looks exactly like a path already done. The
        # index-driven list below takes all 366 Santi pages, so nothing needs to
        # replace it by hand.
        ("m01/m01135.htm", "Adi Parva, Section CXXXV"),
        ("m01/m01187.htm", "Adi Parva, Section CLXXXVII"),
        # Located by probing for the figures themselves, then labelled from
        # the page. Guessed labels were wrong 34 times out of 34.
        ("m01/m01101.htm", "Ganga, Satyavati and the vow"),
        ("m01/m01104.htm", "Satyavati and Bhishma"),
        ("m01/m01113.htm", "Kunti"),
        # Located by probing each parva for the figures the scene is about,
        # then labelled from the page. The Mahabharata journey had twenty
        # events for eighteen parvas, so whole books had no scene at all.
        ("m01/m01140.htm", "the house of lac"),
        ("m01/m01148.htm", "Ekachakra"),
        ("m01/m01225.htm", "the Khandava forest"),
        ("m02/m02042.htm", "Shishupala at the Rajasuya"),
        ("m03/m03011.htm", "the forest years"),
        ("m04/m04014.htm", "Kichaka"),
        ("m04/m04023.htm", "the end of Kichaka"),
        ("m09/m09032.htm", "Duryodhana at the lake"),
        ("m09/m09058.htm", "the mace duel"),
        ("m11/m11016.htm", "Gandhari on the field"),
        ("m16/m16004.htm", "the end of the Yadavas"),
        ("m17/m17003.htm", "the final journey"),
        ("m08/m08090.htm", "Karna Parva -- the fall of Karna"),
        ("m02/m02051.htm", "Sabha Parva, Section LI"),
        ("m02/m02067.htm", "Sabha Parva, Section LXVII"),
        ("m06/m06025.htm", "Bhishma Parva, Section XXV"),
        ("m07/m07191.htm", "Drona Parva, Section CXCI"),
    ],
    # Griffith, Ramayana
    "griffith-ramayana": [
        ("rama/ry008.htm", "Book I, Canto I"),
        ("rama/ry026.htm", "Book I, Canto XIX"),
        ("rama/ry075.htm", "Book II, Canto XX"),
        ("rama/ry123.htm", "Book III, Canto XVII"),
        ("rama/ry158.htm", "Book IV, Canto III"),
        ("rama/ry196.htm", "Book V, Canto I"),
        # Located by probing the volume, not by guessing canto numbers: an
        # earlier guessed set contained none of these figures at all.
        ("rama/ry250.htm", "Book III, Canto LII"),
        ("rama/ry300.htm", "Book IV, Canto XXVI"),
        ("rama/ry360.htm", "Book V, Canto XVIII"),
        ("rama/ry400.htm", "Book VI, Canto I"),
        ("rama/ry341.htm", "Canto titled Hanuman"),
        ("rama/ry055.htm", "Vishvamitra and Vasishtha"),
        ("rama/ry060.htm", "Trisanku"),
        # For the Rishi encyclopedia: Valmiki's own opening, and the long
        # Vishvamitra arc that runs through the back half of Bala Kanda.
        ("rama/ry009.htm", "Book I, Canto II"),
        ("rama/ry010.htm", "Book I, Canto III"),
        ("rama/ry056.htm", "Vishvamitra arc"),
        ("rama/ry057.htm", "Vishvamitra arc"),
        ("rama/ry061.htm", "Vishvamitra arc"),
        ("rama/ry064.htm", "Vishvamitra arc"),
        ("rama/ry065.htm", "Vishvamitra arc"),
        ("rama/ry066.htm", "Vishvamitra arc"),
        ("rama/ry082.htm", "Book I, later cantos"),
    ],
    # Griffith, Rigveda -- all 1028 hymns, generated above.
    "griffith-rigveda": rigveda_targets(),
    # Telang, Bhagavadgita (SBE vol. 8). Every Gita citation in the corpus is
    # chapter.verse, so all eighteen chapters are needed and nothing less will
    # do: 56 rows cite this and none of them could be re-read before now. The
    # introduction is taken too, because one row cites it by name.
    #
    # Chapter -> file is off by two (Chapter I is sbe0803) and the index's own
    # labels contain two typos ("Chatper VI", "Chaper XVI"), so the mapping is
    # written out rather than computed, and the page title still overrides it.
    "telang-bhagavadgita": [
        ("sbe08/sbe0802.htm", "Introduction to Bhagavadgita"),
        *[(f"sbe08/sbe08{2 + c:02d}.htm", f"Bhagavadgita, Chapter {c}")
          for c in range(1, 19)],
    ],
    # Müller's Upanishads -- Sacred Books of the East volumes 1 and 15, which is
    # the registered edition. Taken per chapter rather than whole, because the
    # 50 rows citing this name a khanda ("Katha Upanishad 1.2.18") and only a
    # per-chapter fetch lets one of them be checked without reading a book.
    #
    # This replaces content/raw/muller-upanishads/full.txt, which was not the
    # Upanishads: it was a Project Gutenberg copy of "The convolvulus: a comedy
    # in three acts". See check_corpus_on_disk() in validate.py.
    #
    # SBE 1 pages 5-9 are transliteration plates -- tables of glyphs with no
    # prose. Fetching them would write empty files that look like chapters.
    "muller-upanishads": [
        *[(f"sbe01/sbe01{n:03d}.htm", f"SBE 1, page {n}")
          for n in range(0, 244) if not 5 <= n <= 9],
        *[(f"sbe15/sbe15{n:03d}.htm", f"SBE 15, page {n}")
          for n in range(0, 119)],
    ],
}


# ---------------------------------------------------------------------------
# archive.org whole-book fetches (festival sources).
#
# These are scanned/OCR'd books, not the hand-marked-up HTML sacred-texts.com
# serves, so they arrive as one flat _djvu.txt per book rather than a page per
# chapter -- fetching and splitting them is a different shape of problem from
# everything above, kept separate rather than forced through the same
# per-chapter TARGETS/INDEXES machinery.
#
# Both identifiers here were WRONG in the source registry when this was
# written (hindureligiousye00undeuoft and hinduholidaysce00guptgoog 404 --
# archive.org's metadata API returns {} for a dead identifier, not an error,
# which is easy to mistake for a transient outage). The real identifiers were
# found via the advancedsearch API by title+creator and confirmed against the
# registry's own recorded edition/publisher/year before use.
ARCHIVE_ORG_BOOKS = {
    # Underhill splits into 8 numbered chapters -- "CHAPTER    I" etc. appear
    # verbatim in the OCR and are unambiguous, so each chapter is fetched as
    # its own citable unit, matching how every other multi-chapter source in
    # this file is split.
    "underhill-hindu-year": {
        "identifier": "thehindureligiou00undeuoft",
        "split": "chapter",
    },
    # Gupte is an A-Z dictionary of festival/vrat entries, not chapters -- the
    # citable unit is the headword itself (already what festivals.jsonl's
    # source_chapter_or_section field holds for these rows), so the body is
    # kept as one whole file rather than force-split on a structure the OCR
    # does not mark. Front matter (title/preface/appendix) and the back INDEX
    # are excluded by line range so a citation never points at a page number
    # cross-reference instead of an actual entry.
    "gupte-hindu-holidays": {
        "identifier": "cu31924024133922",
        "split": "whole",
        "body_start_pattern": r"^Akshaya-Tritiya\s*—",
        "body_end_pattern": r"^INDEX AND GLOSSARY",
    },
}


def fetch_archive_org_books(prior: dict[str, str]) -> tuple[list[dict], list[tuple[str, str, str]]]:
    """Fetch each ARCHIVE_ORG_BOOKS entry's full text and split per its rule.

    Returns (manifest_entries, failures), same shape `main()` already uses for
    the sacred-texts.com fetch so both can be appended to one manifest/run.
    """
    manifest: list[dict] = []
    failed: list[tuple[str, str, str]] = []

    for source, cfg in ARCHIVE_ORG_BOOKS.items():
        outdir = RAW / source
        outdir.mkdir(parents=True, exist_ok=True)
        ident = cfg["identifier"]
        raw_cache = outdir / "_raw_djvu.txt"

        if raw_cache.exists():
            full = raw_cache.read_text(encoding='utf-8')
        else:
            url = f"https://archive.org/download/{ident}/{ident}_djvu.txt"
            try:
                req = urllib.request.Request(url, headers={'User-Agent': UA})
                with urllib.request.urlopen(req, timeout=90) as r:
                    full = r.read().decode('utf-8', 'replace')
            except Exception as e:                          # noqa: BLE001
                print(f"  FAIL {source} ({ident}): {type(e).__name__}")
                failed.append((source, ident, type(e).__name__))
                time.sleep(1.5)
                continue
            raw_cache.write_text(full, encoding='utf-8')
            time.sleep(1.5)

        if cfg["split"] == "chapter":
            # "CHAPTER    I" / "CHAPTER  VI" -- whitespace between the word and
            # the numeral is not fixed-width in the OCR, so it is matched
            # loosely rather than assumed.
            marks = list(re.finditer(r'^CHAPTER\s+([IVXLC]+)\s*$', full, re.M))
            if not marks:
                print(f"  FAIL {source}: no chapter markers found in OCR text")
                failed.append((source, ident, "NoChapterMarkers"))
                continue
            for i, m in enumerate(marks):
                start = m.start()
                end = marks[i + 1].start() if i + 1 < len(marks) else len(full)
                body = full[start:end].strip()
                label = f"Chapter {m.group(1)}"
                name = f"chapter_{m.group(1)}.txt"
                dest = outdir / name
                dest.write_text(body, encoding='utf-8')
                sha = hashlib.sha256(body.encode('utf-8')).hexdigest()
                path = f"{source}/{name}"
                manifest.append({
                    "source_slug": source, "path": path,
                    "label": prior.get(path, label),
                    "label_verified": path in prior,
                    "file": str(dest.relative_to(RAW)),
                    "chars": len(body), "sha256": sha,
                })
                print(f"  {source:<22} {label:<32} {len(body):>7} chars")
        else:  # "whole"
            start_m = re.search(cfg["body_start_pattern"], full, re.M)
            end_m = re.search(cfg["body_end_pattern"], full, re.M)
            if not start_m or not end_m or end_m.start() <= start_m.start():
                print(f"  FAIL {source}: body start/end markers not found")
                failed.append((source, ident, "NoBodyMarkers"))
                continue
            body = full[start_m.start():end_m.start()].strip()
            label = "Dictionary body (Akshaya-Tritiya .. end)"
            name = "body.txt"
            dest = outdir / name
            dest.write_text(body, encoding='utf-8')
            sha = hashlib.sha256(body.encode('utf-8')).hexdigest()
            path = f"{source}/{name}"
            manifest.append({
                "source_slug": source, "path": path,
                "label": prior.get(path, label),
                "label_verified": path in prior,
                "file": str(dest.relative_to(RAW)),
                "chars": len(body), "sha256": sha,
            })
            print(f"  {source:<22} {label:<32} {len(body):>7} chars")

    return manifest, failed


def strip_html(raw: str) -> str:
    raw = re.sub(r'(?is)<(script|style|head).*?</\1>', ' ', raw)
    txt = re.sub(r'<[^>]+>', ' ', raw)
    txt = html.unescape(txt)
    return re.sub(r'\s+', ' ', txt).strip()


def clean_label(text: str) -> str:
    """Unescape until stable.

    Several sacred-texts pages are double-encoded, so a single unescape leaves
    `Vis'v&aacute;mitra` in the label -- which would then render literally in a
    citation on the entity screen. Repeat until it stops changing.
    """
    prev = None
    out = re.sub(r'\s+', ' ', text)
    while out != prev:
        prev, out = out, html.unescape(out)
    return out.split('|')[0].strip()


# Whole works, discovered from the site's own index pages instead of guessed.
#
# Every hand-written target list in this file has been wrong somewhere. All 34
# labels in the first pass were wrong. The Vishnu Purana entries are off by one
# -- vp036.htm is labelled "Book I, Chapter I" here and the page itself says
# Chapter II -- which went unnoticed only because the fetcher overrides the
# guess with the page title. And the coverage was wrong in a way no label check
# could catch: 165 rows cite Wilson across about 35 distinct chapters while 14
# were on disk, so most of those citations could not be read even though the
# source counted as "fetched".
#
# So the lists come from the index. Each entry is (source, index page, page
# pattern); the index gives both the page set and the order, and the per-page
# title still supplies the final label.
INDEXES: list[tuple[str, str, str]] = [
    ("wilson-vishnu-purana", "vp/index.htm", r"vp\d+\.htm"),
    ("griffith-ramayana", "rama/index.htm", r"ry\d+\.htm"),
    # Santi (m12) and Anusasana (m13) are split into lettered volumes on the
    # site -- m12a/m12b/m12c, m13a/m13b -- so the pattern allows a letter.
    *[("ganguli-mahabharata", f"m{p:02d}/index.htm", rf"m{p:02d}[a-z]?\d+\.htm")
      for p in range(1, 19)],
]

# The Vishnu Purana index ends with a 24-page A-Z proper-name index, vp164 to
# vp187. Those are lookup tables, not chapters, and citing one would be citing
# Wilson's back matter. The bound is 164 and not 160: Book VI runs vp156-vp163,
# so a range written as `1[6-9]\d` would drop four real chapters -- including
# the dissolution of the world, which two cosmology rows cite.
SKIP = re.compile(r"vp(16[4-9]|1[78]\d)\.htm")

INDEX_CACHE = RAW / "_index"


def division_of(index_title: str) -> str:
    """The work division an index page says it covers, or "".

    The Mahabharata index pages name their own parva -- "The Mahabharata,
    Book 12: Santi Parva Index" -- and their per-section links do not: those
    read "Section 5", which is the same string in all eighteen books. Without
    the prefix a manifest entry says only "Section 5" and a citation of
    "Santi Parva 5" cannot be matched to it.

    Taken from the index's own title rather than from a table of parva names
    written here, so it cannot drift from the site. Wilson and Griffith return
    "" ("The Vishnu Purana Index" names no division) and need no prefix: their
    per-page titles carry the book already, as "Book VI: Chapter VII".
    """
    head, _, tail = index_title.rpartition(":")
    if not head:
        return ""
    return re.sub(r'\s*index\s*$', '', tail, flags=re.I).strip()


def discover() -> dict[str, list[tuple[str, str]]]:
    """(path, label) per source, read from each work's own index page.

    Cached under content/raw/_index/, so the index pages are fetched once and a
    re-run costs nothing. The cache is the record of what the site said the
    work contains at the time it was read.
    """
    INDEX_CACHE.mkdir(parents=True, exist_ok=True)
    out: dict[str, list[tuple[str, str]]] = {}
    for source, index_path, pattern in INDEXES:
        # v2: the cache format changed when division prefixes were added, and a
        # stale entry would silently keep serving bare "Section 5" labels.
        cache = INDEX_CACHE / (index_path.replace('/', '_') + '.v2.json')
        if cache.exists():
            pairs = [(p, lab) for p, lab in json.loads(
                cache.read_text(encoding='utf-8'))]
        else:
            url = BASE + index_path
            try:
                req = urllib.request.Request(url, headers={'User-Agent': UA})
                with urllib.request.urlopen(req, timeout=45) as r:
                    raw = r.read().decode('utf-8', 'replace')
            except Exception as e:                        # noqa: BLE001
                print(f"  INDEX FAIL {index_path}: {type(e).__name__}")
                continue
            time.sleep(1.5)
            t = re.search(r'<title>(.*?)</title>', raw, re.I | re.S)
            division = division_of(clean_label(t.group(1))) if t else ""
            folder = index_path.rsplit('/', 1)[0]
            seen: dict[str, str] = {}
            for m in re.finditer(
                    rf'href="({pattern})"[^>]*>(.*?)</a>', raw, re.I | re.S):
                page, label = m.group(1), clean_label(
                    re.sub(r'<[^>]+>', '', m.group(2)))
                if SKIP.fullmatch(page):
                    continue
                if division and division.lower() not in label.lower():
                    label = f"{division}, {label}"
                # An index links some pages twice ("Start Reading" and the real
                # entry). First occurrence wins unless it was the nav label.
                if page not in seen or seen[page].endswith('Start Reading'):
                    seen[page] = label
            pairs = [(f"{folder}/{p}", lab) for p, lab in seen.items()]
            cache.write_text(json.dumps(pairs, ensure_ascii=False, indent=1),
                             encoding='utf-8')
            print(f"  index {index_path:<18} {len(pairs):>5} pages"
                  f"{'  ' + division if division else ''}")
        out.setdefault(source, []).extend(pairs)
    return out


def all_targets() -> dict[str, list[tuple[str, str]]]:
    """TARGETS plus everything the indexes name, deduplicated by path."""
    merged: dict[str, list[tuple[str, str]]] = {}
    found = discover()
    for source in dict.fromkeys([*TARGETS, *found]):
        seen: set[str] = set()
        pages: list[tuple[str, str]] = []
        for path, label in [*TARGETS.get(source, []), *found.get(source, [])]:
            if path not in seen:
                seen.add(path)
                pages.append((path, label))
        merged[source] = pages
    return merged


def main() -> int:
    # Carry forward labels that were already verified against the page itself.
    # The manifest used to be rebuilt from scratch every run, which silently
    # discarded them and made each run re-derive all 43 -- enough requests in a
    # burst that the archive started resetting the connection.
    prior = {}
    mf = RAW / 'manifest.json'
    if mf.exists():
        for m in json.loads(mf.read_text(encoding='utf-8')):
            if m.get('label_verified'):
                prior[m['path']] = m['label']

    manifest = []
    failed: list[tuple[str, str, str]] = []
    for source, pages in all_targets().items():
        outdir = RAW / source
        outdir.mkdir(parents=True, exist_ok=True)
        for path, label in pages:
            name = path.replace('/', '_').replace('.htm', '.txt')
            dest = outdir / name
            if dest.exists():
                body = dest.read_text(encoding='utf-8')
            else:
                url = BASE + path
                try:
                    req = urllib.request.Request(url, headers={'User-Agent': UA})
                    with urllib.request.urlopen(req, timeout=45) as r:
                        raw = r.read().decode('utf-8', 'replace')
                    # The page names itself. Every label guessed from a URL in
                    # the first pass of this work was wrong -- all 34 of them --
                    # so the title is taken here and never inferred.
                    t = re.search(r'<title>(.*?)</title>', raw, re.I | re.S)
                    if t:
                        prior.setdefault(path, clean_label(t.group(1)))
                    body = strip_html(raw)
                except Exception as e:                    # noqa: BLE001
                    # Sleep on failure too. A run of 404s used to be the one
                    # case that hit the archive with no delay between requests.
                    print(f"  FAIL {path}: {type(e).__name__}")
                    failed.append((source, path, type(e).__name__))
                    time.sleep(1.5)
                    continue
                dest.write_text(body, encoding='utf-8')
                time.sleep(1.5)          # be a polite guest on a free archive
            sha = hashlib.sha256(body.encode('utf-8')).hexdigest()
            verified = path in prior
            manifest.append({"source_slug": source, "path": path,
                             "label": clean_label(prior.get(path, label)),
                             "label_verified": verified,
                             "file": str(dest.relative_to(RAW)),
                             "chars": len(body), "sha256": sha})
            print(f"  {source:<22} {label:<32} {len(body):>7} chars")

    archive_manifest, archive_failed = fetch_archive_org_books(prior)
    manifest.extend(archive_manifest)
    failed.extend(archive_failed)

    (RAW / 'manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1), encoding='utf-8')
    total = sum(m['chars'] for m in manifest)
    print(f"\n{len(manifest)} chapters, {total/1000:.0f}k chars")

    # A target that never arrives is invisible otherwise, and that is not
    # hypothetical: one hand-written Santi Parva path 404'd on every run for as
    # long as it existed, because its single FAIL line scrolled past in a log of
    # hundreds of successes and skip-if-exists makes a page that never arrived
    # indistinguishable from one already done. So the failures are collected and
    # reprinted at the end, where they are the last thing on screen.
    if failed:
        print(f"\n{len(failed)} target(s) did not arrive:")
        for source, path, err in failed:
            print(f"  {source:<22} {path:<24} {err}")
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
