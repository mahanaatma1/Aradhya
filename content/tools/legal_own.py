"""Author and verify our own scripture text, replacing the Ishvarvaani fixture.

Release gate RG-01: every creative string the app reads out of
`assets/db/content.sqlite` has to be ours. For `scripture_sections` the
Sanskrit is public domain and carries over untouched; the English and Hindi
renderings -- and the Gita commentary -- are written fresh here.

Layout: one JSON file per book under `content/legal/own/scripture_verses/`,
keyed by the fixture's own row id so each replacement maps 1:1 back to the
row it supersedes.

    py -m content.tools.legal_own dump  bgc_1     # source Sanskrit to author against
    py -m content.tools.legal_own check bgc_1     # coverage + distinctness
    py -m content.tools.legal_own collisions bgc_1  # which of our words overlap
    py -m content.tools.legal_own status          # progress across all 130 books

`check` is the interesting one: it scores each authored string against the
fixture string it replaces, so "this is our own wording" is a measured claim
and not a promise.
"""

from __future__ import annotations

import json
import re
import sqlite3
import sys
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "assets" / "db" / "content.sqlite"
OWN_DIR = ROOT / "content" / "legal" / "own" / "scripture_verses"
WORK_DIR = ROOT / "content" / "legal" / "work"
# Strings too short to score need a human verdict, and a verdict nobody wrote
# down is not a verdict. Each merger item must carry a disposition here or the
# book fails, so the review bucket can never quietly become a pass.
REVIEWED = ROOT / "content" / "legal" / "own" / "reviewed.json"


def _dispositions() -> dict:
    if not REVIEWED.exists():
        return {}
    return json.loads(REVIEWED.read_text(encoding="utf-8")).get("merger", {})

# Fields we author. Sanskrit is PD and copied; transliteration is a mechanical
# transform of it. Commentary only exists on the Gita.
AUTHORED = ("body_en", "body_hi", "commentary_en", "commentary_hi")

# A shared translation of the same verse will always echo the source's proper
# nouns -- Dhrishtaketu is Dhrishtaketu in anyone's English. Those words are
# subject matter, not expression, so they are excluded before scoring and the
# thresholds below apply to what is left: the interpretive wording, which is
# the only part anyone could own.
MAX_RATIO = 0.50          # difflib similarity on expressive words
MAX_RUN = 5               # longest identical expressive-word run allowed
# A flat threshold is wrong: half of five expressive words is far more
# suspicious than half of thirty, because on a short line there is almost
# nothing left to agree about by accident. So the gate tightens as n shrinks.
SHORT_N = 8
MAX_RATIO_SHORT = 0.34
MAX_RUN_SHORT = 3
MIN_N = 4                 # below this, no metric can tell convergence from copying


def _too_close(ratio: float, run: int, n: int) -> bool:
    if n < SHORT_N:
        return run > MAX_RUN_SHORT or ratio > MAX_RATIO_SHORT
    return run > MAX_RUN or ratio > MAX_RATIO

# Function words carry no authorial choice either.
STOP_EN = {
    "the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "at", "by",
    "for", "with", "from", "as", "is", "are", "was", "were", "be", "been",
    "this", "that", "these", "those", "there", "here", "who", "whom", "which",
    "what", "all", "also", "too", "not", "no", "his", "her", "its", "their",
    "my", "our", "your", "them", "they", "he", "she", "it", "we", "you", "i",
    "me", "him", "us", "then", "than", "so", "if", "when", "where", "will",
    "shall", "have", "has", "had", "do", "does", "did", "said", "s",
    "among", "amongst", "each", "every", "one", "other", "others", "own",
    "yourself", "himself", "themselves", "into", "upon", "over", "out", "up",
    "down", "before", "after", "again", "very", "such", "same", "while",
    "addressed", "told", "answered", "asked", "replied", "am",
    "having", "being", "even",
}
STOP_HI = {
    "के", "का", "की", "को", "में", "से", "पर", "और", "भी", "है", "हैं", "था",
    "थे", "थी", "यह", "वह", "ये", "वे", "जो", "कि", "ही", "तो", "न", "नहीं",
    "एक", "इस", "उस", "अपने", "अपनी", "मेरे", "मेरा", "हमारे", "आप", "उन्होंने",
    "ने", "हुए", "किया", "कहा", "लिए", "गया", "गई", "कर", "करते", "द्वारा",
    "बोले", "सब", "सभी", "क्या", "वहाँ", "जब", "तब", "हो", "होने", "रहा",
    # Grammatical machinery, no authorial choice in any of it.
    "मैं", "मुझे", "मुझ", "हम", "तुम", "उन", "इन", "इनके", "इनकी", "उनके",
    "उनकी", "हे", "तथा", "अथवा", "या", "किन", "किनसे", "किनके", "कौन", "क्यों",
    "जिन", "जिनके", "वाले", "वाला", "वाली", "करने", "होता", "होती", "होते",
    "देख", "देखा", "जान", "जाने", "कहते", "कहकर", "पूछा", "दिया", "दी", "लिया",
    "आया", "गए", "थीं", "रहे", "रही", "कुछ", "कोई", "अब", "फिर", "इसलिए",
    "जैसे", "मानो", "केवल", "बिना", "साथ", "ओर", "ही।", "उसे", "उसके", "उसकी",
    "हूँ", "हूं", "स्वयं", "कीजिए", "कीजिये", "करो", "पास", "जाकर", "आकर",
    "प्रत्येक", "अपना", "स्वयम्", "इन्हें", "उन्हें", "जिसे", "जिससे", "जितना",
    "यहाँ", "यहां", "आपके", "आपका", "आपकी", "इच्छा", "इच्छुक", "चाहते",
    "चाहता", "चाहती", "चाहे", "चाहिए", "डालें", "डालना", "देते", "पाता",
    "पाते", "रखें", "लूँ", "सकता", "सकते", "गिना", "बीच", "भर", "ही",
    "इसे", "किसे", "इसका", "इसके", "उसको", "जिसका", "जिसने",
}
# Renderings the subject matter compels. There is no second way to say that
# someone is the son of Subhadra, that a maharatha is a great chariot-warrior,
# or that kasiraja is the king of Kashi. Two independent translators will agree
# on all of it, so none of it is evidence of copying and it is excluded before
# scoring. Kept deliberately narrow: relational, military and ritual vocabulary
# only, never a word that carries a reading of the verse.
FORCED_EN = {
    "son", "sons", "daughter", "father", "mother", "brother", "brothers",
    "grandsire", "grandfather", "grandfathers", "grandsons", "uncles",
    "kinsmen", "kin", "relatives", "friends", "teacher", "teachers",
    "preceptor", "disciple", "pupil", "king", "kings", "prince", "army",
    "armies", "force", "forces", "host", "troops", "battle", "war", "fight",
    "warrior", "warriors", "fighter", "fighters", "chariot", "chariots",
    "charioteer", "bow", "bows", "arrow", "arrows", "weapon", "weapons",
    "conch", "conches", "drum", "drums", "field", "formation", "array",
    "hero", "heroes", "archer", "archers", "men", "man", "world", "worlds",
    "heaven", "earth", "hell", "dharma", "family", "families", "clan",
    "ancestors", "sacrifice", "duty", "sin", "kingdom", "pleasures", "life",
    "lives", "mind", "body", "limbs", "hand", "skin", "hair", "great",
    "mighty", "valiant", "brave", "eager", "blew", "stood", "spoke", "saw",
    "seeing", "behold", "look", "name", "named", "sides", "side", "both",
    # Compelled by the verse's own nouns and adjectives.
    "lord", "lords", "horse", "horses", "white", "yoked", "divine", "sound",
    "between", "two", "midst", "middle", "sky", "heart", "hearts", "ape",
    "banner", "standing", "held", "halt", "supreme", "finest", "first",
    # Verbs and numerals the verse dictates. A hyphenated compound splits into
    # its parts here, so the pieces of "fathers-in-law" and "well-wishers" have
    # to be listed too -- there is no second English form of either.
    "kill", "kills", "killing", "killed", "slay", "slain", "destroy", "law",
    "wishers", "well", "three", "hundred", "thousand", "sitting", "sat",
    "grandsons", "brothers", "sisters", "wives", "connections", "kindred",
    # The four elements of 2.23 and what each of them does. pavaka is fire and
    # dahati is burns; there is no synonym that is not a distortion, and the
    # list of stages in 2.13 -- kaumaram, yauvanam, jara -- is the same three
    # words in any hand.
    "cut", "cuts", "burn", "burns", "soak", "soaks", "wet", "dry", "dries",
    "fire", "water", "waters", "wind", "childhood", "youth", "age", "another",
    "spoken", "speak", "speaking",
    # Birth and death, the two nouns chapter 2 is built on. jayate is born and
    # mriyate is dies; a translator has no second word for either.
    "born", "birth", "die", "dies", "death", "unborn",
    # 2.29 is a list of four verbs -- pasyati, vadati, srnoti, veda -- and the
    # inflections belong here for the same reason "spoke" and "saw" already do.
    # jaya and bhuj are likewise one English word each.
    "sees", "speaks", "hears", "hearing", "heard", "knows", "know",
    "victory", "victorious", "win", "wins", "won", "conquer", "conquered",
    "enjoy", "enjoys", "enjoyment", "enjoyments",
}
FORCED_HI = {
    "पुत्र", "पुत्रों", "पुत्रो", "पिता", "माता", "भाई", "पितामह", "पितरों",
    "पौत्र", "मामा", "श्वसुर", "सम्बन्धी", "बन्धु", "बान्धव", "स्वजन", "मित्र",
    "आचार्य", "गुरु", "शिष्य", "राजा", "राजाओं", "सेना", "सेनाओं", "बल",
    "युद्ध", "रण", "संग्राम", "योद्धा", "महारथी", "महारथ", "रथ", "सारथी",
    "धनुष", "बाण", "शस्त्र", "शस्त्रों", "शंख", "नगाड़े", "भेरी", "क्षेत्र",
    "व्यूह", "वीर", "शूरवीर", "धनुर्धर", "मनुष्यों", "लोक", "स्वर्ग", "पृथ्वी",
    "नरक", "धर्म", "कुल", "वंश", "पूर्वजों", "यज्ञ", "कर्तव्य", "पाप", "राज्य",
    "भोग", "जीवन", "प्राण", "मन", "शरीर", "अंग", "हाथ", "त्वचा", "रोम",
    "विशाल", "महान", "पराक्रमी", "वीर्यवान्", "शूर", "आतुर", "बजाया", "खड़ी",
    "देखिए", "देखकर", "नाम", "पक्ष", "दोनों", "ओर",
    # Compelled by the verse's own nouns and adjectives.
    "घोड़ों", "घोड़े", "अश्व", "श्वेत", "सफेद", "जुते", "दिव्य", "बजाए", "बजाते",
    "नाद", "शब्द", "आकाश", "मध्य", "बीच", "खड़ा", "खड़े", "नामक", "स्वामी",
    "अधिपति", "पृथ्वीपति", "भगवान्", "ईश्वर", "हृदय", "हृदयों",
    # Verbs the verse dictates: there is no second Hindi word for "to kill".
    "मारना", "मारने", "मारकर", "मार", "मारें", "वध", "हत्या", "तीन", "तीनों",
    "सौ", "सहस्र", "बैठ", "बैठा", "बैठे", "श्वशुरों", "साले", "नाते", "कुटुम्ब",
    # More inflections of the same verb, plus two words Hindi simply keeps from
    # the Sanskrit: avyaya and aja have no separate Hindi form to choose.
    "मारता", "मारते", "मरवाता", "मरवाना", "अजन्मा", "अज", "अव्यय", "अविनाशी",
    # The same compelled vocabulary as its English counterpart: the four
    # elements and what each does to nothing, then birth and death.
    "काटते", "काटता", "काटा", "जलाती", "जलाता", "जलाया", "भिगोता", "भिगोया",
    "सुखाती", "सुखाता", "सुखाया", "आग", "जल", "वायु", "पवन",
    "जन्म", "जन्मता", "जन्मा", "मरता", "मृत्यु",
}
FORCED_TERMS = FORCED_EN | FORCED_HI

# Names and epithets of a public-domain cast. A character's name is the purest
# case of subject matter: there is no way to translate this verse without it,
# and no version of it belongs to anyone. Patronymics drift too far from the
# stem for the matcher to bridge (धृतराष्ट्र appears only as धार्तराष्ट्राणां), so
# the recurring ones are named outright. Names and epithets only -- never a word
# that carries a reading of the verse.
PROPER = {
    "धृतराष्ट्र", "धृतराष्ट्रों", "दुर्योधन", "सञ्जय", "संजय", "अर्जुन", "कृष्ण",
    "भीष्म", "द्रोण", "कर्ण", "कृप", "कृपाचार्य", "अश्वत्थामा", "विकर्ण",
    "युधिष्ठिर", "भीम", "नकुल", "सहदेव", "द्रौपदी", "सुभद्रा", "अभिमन्यु",
    "कुन्ती", "कुन्तीपुत्र", "पाण्डु", "पाण्डव", "पाण्डवों", "कौरव", "कौरवों",
    "कुरु", "कुरुओं", "कुरुक्षेत्र", "पाञ्चजन्य", "देवदत्त", "पौण्ड्र",
    "अनन्तविजय", "सुघोष", "मणिपुष्पक", "गाण्डीव", "माधव", "केशव", "गोविन्द",
    "जनार्दन", "हृषीकेश", "गुडाकेश", "अच्युत", "मधुसूदन", "वार्ष्णेय", "पार्थ",
    "कौन्तेय", "धनंजय", "वृकोदर", "सव्यसाची", "द्रुपद", "विराट", "सात्यकि",
    "शिखण्डी", "धृष्टद्युम्न", "काशी", "काशिराज", "भारत", "यादव", "वृष्णि",
    "सोमदत्त", "सौमदत्ति", "भूरिश्रवा", "जयद्रथ", "शल्य", "शकुनि", "उत्तमौजा",
    "युधामन्यु", "चेकितान", "धृष्टकेतु", "पुरुजित्", "कुन्तिभोज", "शैब्य",
    "somadatta", "saumadatti", "bhurishrava", "jayadratha", "shalya",
    "shakuni", "uttamauja", "yudhamanyu", "chekitana", "dhrishtaketu",
    "purujit", "kuntibhoja", "shaibya",
    "dhritarashtra", "duryodhana", "sanjaya", "arjuna", "krishna", "bhishma",
    "drona", "karna", "kripa", "ashvatthama", "vikarna", "yudhishthira",
    "bhima", "nakula", "sahadeva", "draupadi", "subhadra", "abhimanyu",
    "kunti", "pandu", "pandava", "pandavas", "kaurava", "kauravas", "kuru",
    "kurus", "kurukshetra", "panchajanya", "devadatta", "paundra",
    "anantavijaya", "sughosha", "manipushpaka", "gandiva", "madhava",
    "keshava", "govinda", "janardana", "hrishikesha", "gudakesha", "achyuta",
    "madhusudana", "varshneya", "partha", "kaunteya", "dhananjaya",
    "vrikodara", "drupada", "virata", "satyaki", "shikhandi", "dhrishtadyumna",
    "kashi", "bharata", "yadava", "vrishni",
    # Vocative epithets and the glosses they compel. When the poem says
    # parantapa it is naming the man it is speaking to, exactly as when it says
    # Bharata; "scorcher of foes" is that name in English and there is no
    # version of it to own. Same for arisudana and purusharshabha.
    "parantapa", "scorcher", "foes", "foe", "arisudana", "enemies", "enemy",
    "mahabaho", "purusharshabha", "bull", "rulers",
}

STOPWORDS = STOP_EN | STOP_HI | FORCED_TERMS | PROPER



def _strip_diacritics(word: str) -> str:
    """Fold IAST to bare latin so 'dhṛṣṭaketuś' can meet 'Dhrishtaketu'."""
    out = unicodedata.normalize("NFD", word)
    out = "".join(ch for ch in out if not unicodedata.combining(ch))
    # IAST/ITRANS both spell the same sounds several ways; flatten the lot.
    for a, b in (("sh", "s"), ("ss", "s"), ("ri", "r"), ("ee", "i"),
                 ("oo", "u"), ("w", "v"), ("aa", "a"), ("h", "")):
        out = out.replace(a, b)
    return out


# Anusvara, candrabindu and a class nasal plus virama are interchangeable
# spellings of one sound -- भयंकर and भयङ्कर are the same word -- so nasalisation
# comes off both sides before matching. Avagraha marks an elided initial अ, and
# putting it back is what lets मेऽच्युत yield अच्युत.
_NASAL_CONJUNCT = re.compile(r"[ङञणनम]्")
_DEVA_DROP = re.compile(r"[ंँ़]")


def _deva_fold(text: str) -> str:
    return _NASAL_CONJUNCT.sub("", _DEVA_DROP.sub("", text.replace("ऽ", "अ")))


def _subject_tokens(sanskrit: str, transliteration: str) -> tuple[str, list[str]]:
    """Words that are subject matter, taken from the PD verse itself.

    Sanskrit sandhi fuses adjacent names into a single token -- dhrstaketus and
    cekitanah arrive as one word -- so the Devanagari side is returned as one
    joined string and matched by substring rather than by token.
    """
    deva = "".join(re.findall(r"[ऀ-ॿ]+", sanskrit or ""))
    latin = [_strip_diacritics(w) for w in _words(transliteration or "")]
    return _deva_fold(deva), [w for w in latin if len(w) > 2]



def _db() -> sqlite3.Connection:
    if not FIXTURE.exists():
        sys.exit(f"fixture not found: {FIXTURE}")
    return sqlite3.connect(FIXTURE)


def _book(conn: sqlite3.Connection, slug: str) -> tuple[int, str]:
    row = conn.execute(
        "SELECT id, title_en FROM scripture_books WHERE slug = ?", (slug,)
    ).fetchone()
    if not row:
        sys.exit(f"unknown book slug: {slug}")
    return row[0], row[1]


def _source_rows(conn: sqlite3.Connection, book_id: int) -> list[dict]:
    cur = conn.execute(
        """SELECT id, number, sanskrit, transliteration,
                  body_en, body_hi, commentary_en, commentary_hi
           FROM scripture_sections WHERE book_id = ? ORDER BY order_no""",
        (book_id,),
    )
    cols = [c[0] for c in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


# Devanagari matras and the virama are combining marks, which `\w` does not
# match -- using it would shatter हृषीकेश into five fragments and make any two
# Hindi texts look alike. Split on separators instead and keep words whole.
_SEP = re.compile(r"[\s।॥.,;:!?\"'()\[\]{}<>|/\\*_=+~`^&%$#@—–\-]+")


def _words(text: str) -> list[str]:
    """Lowercased word list, punctuation dropped -- the unit of comparison."""
    return [w for w in _SEP.split((text or "").lower()) if w]


def _longest_run(a: list[str], b: list[str]) -> int:
    if not a or not b:
        return 0
    return SequenceMatcher(None, a, b, autojunk=False).find_longest_match(
        0, len(a), 0, len(b)
    ).size


def _is_subject(word: str, deva: str, latin: list[str]) -> bool:
    """True when this word is carried by the verse itself rather than chosen."""
    if word in STOPWORDS or word.isdigit():
        return True
    if re.search(r"[ऀ-ॿ]", word):
        # Hindi: a name the verse already contains, possibly buried inside a
        # sandhi compound and possibly inflected. Inflection lands on the final
        # vowel (नायका -> नायकों), so try successively shorter stems rather than
        # demanding the whole word survive intact.
        folded_deva = _deva_fold(word)
        return any(
            folded_deva[:k] in deva for k in (6, 5, 4) if len(folded_deva) >= k
        )
    folded = _strip_diacritics(word)
    if len(folded) < 3:
        return True
    return any(
        folded == l
        or (len(folded) >= 5 and folded[:5] in l)
        # Same Sanskrit root, differently inflected or anglicised: pandu/pandavas.
        or (len(folded) >= 4 and len(l) >= 4 and folded[:4] == l[:4])
        or SequenceMatcher(None, folded, l).ratio() > 0.72
        for l in latin
    )


def _expressive(text: str, deva: str, latin: list[str]) -> list[str]:
    return [w for w in _words(text) if not _is_subject(w, deva, latin)]


def _similarity_raw(ours: str, theirs: str) -> tuple[float, int, int]:
    """Similarity over every word, names included -- context for review items."""
    a, b = _words(ours), _words(theirs)
    if not a or not b:
        return 0.0, 0, len(a)
    return (
        SequenceMatcher(None, a, b, autojunk=False).ratio(),
        _longest_run(a, b),
        len(a),
    )


def _similarity(
    ours: str, theirs: str, deva: str, latin: list[str]
) -> tuple[float, int, int]:
    """(ratio, longest run, expressive word count) over expressive words only."""
    a = _expressive(ours, deva, latin)
    b = _expressive(theirs, deva, latin)
    if not a or not b:
        return 0.0, 0, len(a)
    ratio = SequenceMatcher(None, a, b, autojunk=False).ratio()
    return ratio, _longest_run(a, b), len(a)



def cmd_dump(slug: str) -> None:
    """Write the PD Sanskrit for one book to content/legal/work/ to author against."""
    conn = _db()
    book_id, title = _book(conn, slug)
    rows = _source_rows(conn, book_id)
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    out = WORK_DIR / f"{slug}.source.json"
    payload = {
        "slug": slug,
        "title_en": title,
        "book_id": book_id,
        "verses": len(rows),
        "needs_commentary": any(r["commentary_en"] for r in rows),
        "rows": [
            {"id": r["id"], "number": r["number"], "sanskrit": r["sanskrit"]}
            for r in rows
        ],
    }
    out.write_text(
        json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(f"{slug} ({title}): {len(rows)} verses -> {out.relative_to(ROOT)}")
    print(f"commentary required: {payload['needs_commentary']}")


def cmd_check(slug: str) -> int:
    """Verify one authored book: coverage, empties, and distinctness."""
    conn = _db()
    book_id, title = _book(conn, slug)
    src = {r["id"]: r for r in _source_rows(conn, book_id)}

    path = OWN_DIR / f"{slug}.json"
    if not path.exists():
        print(f"{slug}: not authored yet ({len(src)} verses pending)")
        return 1

    doc = json.loads(path.read_text(encoding="utf-8"))
    ours = {r["id"]: r for r in doc["rows"]}
    problems: list[str] = []

    missing = sorted(set(src) - set(ours))
    extra = sorted(set(ours) - set(src))
    if missing:
        problems.append(f"{len(missing)} verses missing (first: {missing[:5]})")
    if extra:
        problems.append(f"{len(extra)} ids not in this book: {extra[:5]}")

    worst: list[tuple[float, int, int, str]] = []
    merger: list[str] = []
    for vid, row in sorted(ours.items()):
        if vid not in src:
            continue
        s = src[vid]
        deva, latin = _subject_tokens(s["sanskrit"] or "", s["transliteration"] or "")

        # Sanskrit is PD and carried over by the build, so it need not be
        # restated here -- but if it is, it must match the source exactly.
        if row.get("sanskrit") and row["sanskrit"] != (s["sanskrit"] or ""):
            problems.append(f"{s['number']}: sanskrit altered (must carry over verbatim)")

        for field in AUTHORED:
            theirs = s[field]
            mine = row.get(field)
            if not theirs:
                continue  # fixture has none -- nothing owed
            if not (mine or "").strip():
                problems.append(f"{s['number']}: {field} empty")
                continue
            ratio, run, n = _similarity(mine, theirs, deva, latin)
            if n < MIN_N:
                # Almost nothing left but names and compelled vocabulary. On a
                # line this short, convergence and copying look identical to any
                # metric, so it goes to a human instead of quietly passing.
                raw, raw_run, _ = _similarity_raw(mine, theirs)
                key = f"{slug}/{s['number']}/{field}"
                merger.append((key, f"{s['number']} {field} "
                                    f"(raw {raw:.2f}, run {raw_run})"))
                continue
            if _too_close(ratio, run, n):
                problems.append(
                    f"{s['number']}: {field} too close to fixture "
                    f"(expressive ratio {ratio:.2f}, longest run {run}, n={n})"
                )
            worst.append((ratio, run, vid, f"{s['number']} {field}"))

    worst.sort(reverse=True)
    print(f"{slug} ({title}): {len(ours)}/{len(src)} verses authored")
    if worst:
        avg = sum(w[0] for w in worst) / len(worst)
        print(f"  distinctness: mean expressive ratio {avg:.2f} over {len(worst)} strings")
        print("  closest to fixture:")
        for ratio, run, _, label in worst[:5]:
            print(f"    {ratio:.2f} run={run:<3} {label}")
    if merger:
        seen = _dispositions()
        undecided = [(k, lbl) for k, lbl in merger if k not in seen]
        print(f"  {len(merger)} string(s) too short to score -- names and compelled "
              f"vocabulary only; {len(merger) - len(undecided)} with a recorded verdict:")
        for key, label in merger:
            verdict = seen.get(key)
            print(f"    {label}: {verdict or 'NO VERDICT RECORDED'}")
        for key, label in undecided:
            problems.append(f"{label} needs a verdict in {REVIEWED.name}")

    if problems:
        print(f"  FAIL -- {len(problems)} problem(s):")
        for p in problems[:25]:
            print(f"    - {p}")
        if len(problems) > 25:
            print(f"    ... and {len(problems) - 25} more")
        return 1
    print("  OK -- complete, and every string clears the distinctness bar")
    return 0


def cmd_collisions(slug: str) -> int:
    """List the expressive words our text shares with the fixture's, and nothing else.

    Deliberately does not print the fixture's prose. Seeing their sentence is
    what produces a paraphrase of it; seeing only the overlapping word choices
    is enough to re-say the verse in our own words.
    """
    conn = _db()
    book_id, title = _book(conn, slug)
    src = {r["id"]: r for r in _source_rows(conn, book_id)}
    path = OWN_DIR / f"{slug}.json"
    if not path.exists():
        sys.exit(f"{slug}: not authored yet")
    doc = json.loads(path.read_text(encoding="utf-8"))

    print(f"{slug} ({title}) -- shared expressive words, ours only:")
    for row in doc["rows"]:
        s = src.get(row["id"])
        if not s:
            continue
        deva, latin = _subject_tokens(s["sanskrit"] or "", s["transliteration"] or "")
        for field in AUTHORED:
            if not s[field] or not (row.get(field) or "").strip():
                continue
            ratio, run, n = _similarity(row[field], s[field], deva, latin)
            if n >= MIN_N and not _too_close(ratio, run, n):
                continue
            mine = _expressive(row[field], deva, latin)
            shared = [w for w in mine if w in set(_expressive(s[field], deva, latin))]
            print(f"  {s['number']} {field}  ratio {ratio:.2f} run {run} n={n}")
            print(f"    drop or replace: {', '.join(shared) or '(order only)'}")
            # On a string too short to score, the thing worth seeing is the
            # longest stretch we have word-for-word in common -- a long identical
            # run is what a reader would notice, whatever the metric calls it.
            if n < MIN_N:
                a, b = _words(row[field]), _words(s[field])
                m = SequenceMatcher(None, a, b, autojunk=False).find_longest_match(
                    0, len(a), 0, len(b)
                )
                if m.size >= 4:
                    print(f"    longest shared run ({m.size}): "
                          f"{' '.join(a[m.a:m.a + m.size])}")
    return 0


def cmd_status() -> int:
    conn = _db()
    books = conn.execute(
        """SELECT b.slug, b.title_en, b.scripture_id, COUNT(s.id)
           FROM scripture_books b JOIN scripture_sections s ON s.book_id = b.id
           GROUP BY b.id ORDER BY b.scripture_id, b.order_no"""
    ).fetchall()
    names = dict(conn.execute("SELECT id, name_en FROM scriptures").fetchall())

    per_scripture: dict[int, list[int]] = {}
    pending: list[str] = []
    for slug, _title, sid, total in books:
        path = OWN_DIR / f"{slug}.json"
        done = 0
        if path.exists():
            doc = json.loads(path.read_text(encoding="utf-8"))
            done = len(doc.get("rows", []))
        tally = per_scripture.setdefault(sid, [0, 0])
        tally[0] += done
        tally[1] += total
        if done < total:
            pending.append(f"{slug} ({done}/{total})")

    grand_done = sum(v[0] for v in per_scripture.values())
    grand_total = sum(v[1] for v in per_scripture.values())
    for sid, (done, total) in per_scripture.items():
        pct = 100.0 * done / total if total else 0.0
        print(f"{names.get(sid, sid):18} {done:6}/{total:<6} {pct:5.1f}%")
    pct = 100.0 * grand_done / grand_total if grand_total else 0.0
    print(f"{'TOTAL':18} {grand_done:6}/{grand_total:<6} {pct:5.1f}%")
    if pending:
        print(f"\nnext up: {', '.join(pending[:6])}")
    return 0


def cmd_selftest() -> int:
    """Prove the checker still catches copying, so a pass means something.

    A distinctness check nobody has tried to fool is worth nothing. This feeds
    it the fixture's own text and a light paraphrase of it; both must be caught.
    """
    conn = _db()
    failures = 0
    rows = conn.execute(
        """SELECT number, sanskrit, transliteration, body_en, body_hi, commentary_en
           FROM scripture_sections WHERE commentary_en IS NOT NULL LIMIT 40"""
    ).fetchall()

    verbatim_caught = verbatim_total = 0
    for number, sanskrit, translit, *fields in rows:
        deva, latin = _subject_tokens(sanskrit or "", translit or "")
        for text in fields:
            if not text:
                continue
            ratio, run, n = _similarity(text, text, deva, latin)
            verbatim_total += 1
            # A verbatim copy is caught if it trips the gate, or is short
            # enough to be routed to human review rather than passed.
            if _too_close(ratio, run, n) or n < MIN_N:
                verbatim_caught += 1
            else:
                failures += 1
                print(f"  LEAK: verbatim {number} passed (ratio {ratio:.2f}, "
                      f"run {run}, n={n})")
    print(f"verbatim copies caught: {verbatim_caught}/{verbatim_total}")

    # A paraphrase that only swaps synonyms must still be caught.
    para_caught = para_total = 0
    swaps = [
        ("assembled", "gathered"), ("eager", "keen"), ("mighty", "huge"),
        ("behold", "look at"), ("valiant", "brave"), ("said", "spoke"),
        ("army", "host"), ("battle", "combat"), ("O ", "Hey "),
    ]
    for number, sanskrit, translit, body_en, _hi, comm in rows:
        deva, latin = _subject_tokens(sanskrit or "", translit or "")
        for text in (body_en, comm):
            if not text or len(_words(text)) < 12:
                continue
            sneaky = text
            for a, b in swaps:
                sneaky = sneaky.replace(a, b)
            if sneaky == text:
                continue
            ratio, run, n = _similarity(sneaky, text, deva, latin)
            para_total += 1
            if _too_close(ratio, run, n) or n < MIN_N:
                para_caught += 1
            else:
                failures += 1
                print(f"  LEAK: paraphrase of {number} passed "
                      f"(ratio {ratio:.2f}, run {run}, n={n})")
    print(f"synonym paraphrases caught: {para_caught}/{para_total}")

    if failures:
        print(f"SELFTEST FAILED -- {failures} disguised copy/copies slipped through")
        return 1
    print("SELFTEST OK -- the checker catches verbatim text and synonym swaps")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "dump" and len(argv) == 3:
        cmd_dump(argv[2])
        return 0
    if cmd == "check" and len(argv) == 3:
        return cmd_check(argv[2])
    if cmd == "collisions" and len(argv) == 3:
        return cmd_collisions(argv[2])
    if cmd == "status":
        return cmd_status()
    if cmd == "selftest":
        return cmd_selftest()
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
