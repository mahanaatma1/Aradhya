"""Give the Srishty nodes real descriptions.

Every cosmology node shipped with a single line and no long description, and
the seven Patalas shared one near-identical sentence -- which is why validate
kept warning that 'atala' looked like a duplicate of 'patala'. It was right.

Wilson distinguishes them plainly: each of the seven has its own soil. He also
lists them differently from the Bhagavata order this app uses -- his sequence
runs Atala, Vitala, Nitala, Gabhastimat, Mahatala, Sutala, Patala, where ours
has Talatala and Rasatala in the third and sixth places. That disagreement is
recorded rather than smoothed over: the two nodes with no counterpart in
Wilson say so, and the rest carry the soil he gives them.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
D = "2026-08-15"
W = "wilson-vishnu-purana"
TALA_REF = "The Vishnu Purana: Book II: Chapter V"
LOKA_REF = "The Vishnu Purana: Book II: Chapter VII"

# The Patalas are not a hell. Narada, returning, tells the gods that Patala is
# pleasanter than Indra's heaven -- which is the single most surprising fact
# about the lower worlds and was nowhere in the app.
PATALA_FRAME_EN = ("The Puranas are emphatic that the Patalas are not hells. "
                   "Narada returns from them and tells the gods that Patala is "
                   "pleasanter than Indra's heaven: sunlight that gives light "
                   "without heat, moonlight without cold, and inhabitants who "
                   "do not notice time passing. The hells are Naraka, and they "
                   "are lower still and quite separate.")
PATALA_FRAME_HI = ("पुराण स्पष्ट कहते हैं कि पाताल नरक नहीं हैं। नारद लौटकर "
                   "देवताओं से कहते हैं कि पाताल इंद्र के स्वर्ग से भी रमणीय है — "
                   "जहाँ सूर्य प्रकाश देता है, ताप नहीं; चंद्रमा शीत नहीं देता; "
                   "और निवासियों को काल का बीतना ज्ञात नहीं होता। नरक इनसे भी "
                   "नीचे हैं और पूर्णतः भिन्न हैं।")

SOIL = {
 "loka-atala":   ("white", "श्वेत"),
 "loka-vitala":  ("black", "कृष्ण"),
 "loka-mahatala": ("sandy", "बालुकामय"),
 "loka-sutala":  ("stony", "पाषाणमय"),
 "loka-patala":  ("gold", "स्वर्णिम"),
}

# The two our order carries that Wilson's does not.
NOT_IN_WILSON = {"loka-talatala", "loka-rasatala"}

UPPER = {
 "loka-bhur": (
  "The earth itself, and the only one of the seven spheres whose inhabitants "
  "are said to earn their next station rather than enjoy one already earned. "
  "Everything above is a result; this is where results are made.",
  "पृथ्वी स्वयं, और सात लोकों में एकमात्र वह जहाँ प्राणी अगली गति अर्जित करते "
  "हैं, भोगते नहीं। ऊपर सब फल है; यहीं कर्म होता है।"),
 "loka-bhuvar": (
  "The space between the earth and the sun, holding the siddhas and the "
  "wandering sages. The Purana measures it in yojanas rather than describing "
  "it, which is characteristic: the upper worlds are given as a geography.",
  "पृथ्वी और सूर्य के बीच का अंतरिक्ष, जहाँ सिद्ध और चारण मुनि विचरते हैं। "
  "पुराण इसका वर्णन नहीं, योजनों में माप देता है।"),
 "loka-svar": (
  "Indra's heaven, reached by merit and left when the merit runs out. The "
  "tradition is unusually blunt that this is a stay and not a destination.",
  "इंद्र का स्वर्ग, पुण्य से प्राप्त और पुण्य क्षीण होने पर छूट जाने वाला। "
  "परंपरा स्पष्ट है कि यह निवास है, गंतव्य नहीं।"),
 "loka-mahar": (
  "The sphere the great sages occupy between one cosmic day and the next. It "
  "is not destroyed when the lower three burn, but its residents leave it "
  "when the heat reaches them.",
  "वह लोक जहाँ महर्षि एक कल्प से दूसरे कल्प के बीच रहते हैं। निचले तीन लोकों "
  "के दहन पर यह नष्ट नहीं होता, पर ताप पहुँचने पर निवासी इसे छोड़ देते हैं।"),
 "loka-jana": (
  "The world of Brahma's mind-born sons -- those who were produced by thought "
  "rather than by birth, and who declined to continue the creation.",
  "ब्रह्मा के मानसपुत्रों का लोक — जो विचार से उत्पन्न हुए, जन्म से नहीं, और "
  "जिन्होंने सृष्टि आगे बढ़ाने से इनकार कर दिया।"),
 "loka-tapa": (
  "The world of those whose austerity carried them past the reach of the "
  "dissolution that ends a cosmic day.",
  "उनका लोक जिनकी तपस्या उन्हें कल्पांत के प्रलय की पहुँच से परे ले गई।"),
 "loka-satya": (
  "The highest of the seven, the abode of Brahma, from which there is said to "
  "be no return to birth. The Purana places the whole structure inside the "
  "shell of the world-egg, so even this has an outside.",
  "सातों में सर्वोच्च, ब्रह्मा का धाम, जहाँ से पुनर्जन्म नहीं कहा गया। पुराण "
  "इस समूची रचना को ब्रह्मांड के कोश के भीतर रखता है — अतः इसका भी बाहर है।"),
}

path = ROOT / 'content' / 'data' / 'cosmology' / 'vishnu_purana.jsonl'
rows = [json.loads(l) for l in path.read_text(encoding='utf-8').splitlines()
        if l.strip()]
touched = 0
for o in rows:
    slug = o['slug']
    long_en = long_hi = None
    ref = None

    if slug in SOIL:
        soil_en, soil_hi = SOIL[slug]
        long_en = (f"The Vishnu Purana gives each of the seven Patalas its own "
                   f"soil; this one is {soil_en}. " + PATALA_FRAME_EN)
        long_hi = (f"विष्णु पुराण सातों पातालों को अलग-अलग भूमि देता है; "
                   f"इसकी भूमि {soil_hi} है। " + PATALA_FRAME_HI)
        ref = TALA_REF
    elif slug in NOT_IN_WILSON:
        long_en = ("This world belongs to the Bhagavata ordering of the seven "
                   "Patalas. The Vishnu Purana lists a different pair here -- "
                   "Nitala and Gabhastimat -- so the two traditions do not "
                   "agree on the middle of the sequence. Both orders are held; "
                   "neither is a correction of the other. " + PATALA_FRAME_EN)
        long_hi = ("यह लोक भागवत के पाताल-क्रम का अंग है। विष्णु पुराण यहाँ "
                   "भिन्न नाम देता है — निताल और गभस्तिमत् — अतः दोनों परंपराएँ "
                   "मध्य क्रम पर एकमत नहीं हैं। दोनों क्रम मान्य हैं; कोई "
                   "दूसरे का संशोधन नहीं। " + PATALA_FRAME_HI)
        ref = TALA_REF
    elif slug in UPPER:
        long_en, long_hi = UPPER[slug]
        ref = LOKA_REF

    if long_en and 'long_description' not in o:
        o['long_description'] = {"en": long_en, "hi": long_hi}
        o.setdefault('sources', []).append({
            "source_slug": W, "source_chapter_or_section": ref,
            "is_primary": True, "last_verified_at": D, "verified_by": "TS"})
        touched += 1

with path.open('w', encoding='utf-8', newline='\n') as fh:
    for o in rows:
        fh.write(json.dumps(o, ensure_ascii=False, sort_keys=True) + "\n")
print(f"enriched {touched} cosmology nodes")
