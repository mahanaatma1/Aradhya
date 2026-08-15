"""Fetch public-domain source chapters into content/raw/.

These are the texts our prose is written FROM. The pipeline rule is that
structure comes from Wikidata (CC0) and substance comes from public-domain
translations -- never from Wikipedia, whose CC BY-SA share-alike would infect
everything we write.

raw/ is gitignored. What makes the corpus reproducible is the sha256 recorded
per file, not the bytes being committed.

Every work here was published before 1929 and is public domain in the United
States, where the Internet Sacred Text Archive hosts them:

  Wilson, The Vishnu Purana (1840)
  Ganguli, The Mahabharata (1883-1896)
  Griffith, The Ramayan of Valmiki (1870-1874)
"""
import hashlib, html, json, pathlib, re, sys, time, urllib.request

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

UA = ("Aradhya/1.0 (offline devotional app; public-domain text fetch; "
      "contact: sumerudigitalsm@gmail.com)")
RAW = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani\content\raw')
RAW.mkdir(parents=True, exist_ok=True)

BASE = "https://sacred-texts.com/hin/"

# Chapters chosen for who they describe, not for coverage. Each is a place the
# figures we ship are actually introduced or characterised.
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
        ("m01/m01135.htm", "Adi Parva, Section CXXXV"),
        ("m01/m01187.htm", "Adi Parva, Section CLXXXVII"),
        # Located by probing for the figures themselves, then labelled from
        # the page. Guessed labels were wrong 34 times out of 34.
        ("m01/m01101.htm", "Ganga, Satyavati and the vow"),
        ("m01/m01104.htm", "Satyavati and Bhishma"),
        ("m01/m01113.htm", "Kunti"),
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
    ],
}


def strip_html(raw: str) -> str:
    raw = re.sub(r'(?is)<(script|style|head).*?</\1>', ' ', raw)
    txt = re.sub(r'<[^>]+>', ' ', raw)
    txt = html.unescape(txt)
    return re.sub(r'\s+', ' ', txt).strip()


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
    for source, pages in TARGETS.items():
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
                        prior.setdefault(path, html.unescape(
                            re.sub(r'\s+', ' ', t.group(1))).split('|')[0].strip())
                    body = strip_html(raw)
                except Exception as e:                    # noqa: BLE001
                    print(f"  FAIL {path}: {type(e).__name__}")
                    continue
                dest.write_text(body, encoding='utf-8')
                time.sleep(1.5)          # be a polite guest on a free archive
            sha = hashlib.sha256(body.encode('utf-8')).hexdigest()
            verified = path in prior
            manifest.append({"source_slug": source, "path": path,
                             "label": prior.get(path, label),
                             "label_verified": verified,
                             "file": str(dest.relative_to(RAW)),
                             "chars": len(body), "sha256": sha})
            print(f"  {source:<22} {label:<32} {len(body):>7} chars")

    (RAW / 'manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1), encoding='utf-8')
    total = sum(m['chars'] for m in manifest)
    print(f"\n{len(manifest)} chapters, {total/1000:.0f}k chars")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
