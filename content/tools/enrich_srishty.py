"""Srishty: prose on every node, and a traditions-differ layer.

The Creation track is the first tab a reader opens and had eight nodes of one
line each with no long description at all. Time and the Yugas were the same.
Only the Lokas had been written. That is why the screen felt thin: the default
view was the emptiest part of it.

Sources are already fetched and were checked before writing:
  Vishnu Purana Book I, Chapter II   -- the whole cosmogony, Pradhana through
                                        Mahat, Ahankara, Tanmatras, elements
                                        and the mundane egg
  Vishnu Purana Book I, Chapter III  -- the measure of time, kashtha through
                                        yuga, manvantara and the life of Brahma

TRADITIONS. Where accounts genuinely differ, both are given and neither is
called a correction of the other. This is the same treatment the Patala
ordering already gets. Only differences I can state accurately are included --
a vague "some say otherwise" is worse than silence.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
D = "2026-08-15"
W = "wilson-vishnu-purana"
CREATION_REF = "The Vishnu Purana: Book I: Chapter II"
TIME_REF = "The Vishnu Purana: Book I: Chapter III"

# slug -> (long_en, long_hi, ref, tradition_note or None)
NODES = {
 # ------------------------------------------------------------- creation
 "srishti-avyakta": (
  "Before anything there is Pradhana, the unmanifest -- described not as empty "
  "but as undifferentiated, holding everything that will unfold without yet "
  "being any of it. The Purana is careful that this is a state, not a "
  "beginning in time, because time itself has not been produced.",
  "सबसे पूर्व प्रधान है, अव्यक्त — जिसे शून्य नहीं, अभेद कहा गया है: जो सब कुछ "
  "अपने भीतर धारण किए है पर अभी कुछ भी नहीं बना। पुराण सावधान है कि यह अवस्था "
  "है, काल का आरंभ नहीं — क्योंकि काल स्वयं अभी उत्पन्न नहीं हुआ।",
  CREATION_REF,
  ("The sequence is Samkhya's. But classical Samkhya holds Purusha and "
   "Prakriti to be two independent principles, while the Vishnu Purana "
   "subordinates both to Vishnu. The steps are shared; what they rest on "
   "is not.",
   "यह क्रम सांख्य का है। किंतु शास्त्रीय सांख्य पुरुष और प्रकृति को दो स्वतंत्र "
   "तत्त्व मानता है, जबकि विष्णु पुराण दोनों को विष्णु के अधीन रखता है। चरण "
   "समान हैं; आधार भिन्न।")),

 "srishti-purusha-prakriti": (
  "The first division: Purusha, which is aware and does nothing, and Prakriti, "
  "which acts and is not aware. Every later distinction in the sequence rests "
  "on this one, and the Purana introduces time here as the third thing that "
  "lets the two meet.",
  "प्रथम विभाजन: पुरुष, जो चेतन है पर करता कुछ नहीं, और प्रकृति, जो करती है पर "
  "चेतन नहीं। आगे का हर भेद इसी पर टिका है, और पुराण यहीं काल को तीसरे तत्त्व "
  "के रूप में लाता है जो दोनों का संयोग संभव करता है।",
  CREATION_REF, None),

 "srishti-mahat": (
  "Mahat, the great principle -- intelligence arriving before matter. The "
  "order is deliberate and is the most counter-intuitive claim in the "
  "sequence: the capacity to know is produced first, and the things to be "
  "known come after it.",
  "महत्, महान तत्त्व — पदार्थ से पूर्व बुद्धि का आना। यह क्रम जानबूझकर है और "
  "इस शृंखला का सबसे अप्रत्याशित कथन है: जानने की क्षमता पहले उत्पन्न होती है, "
  "और जानने योग्य वस्तुएँ उसके बाद।",
  CREATION_REF, None),

 "srishti-ahamkara": (
  "Ahamkara, the sense of being a separate I. The Purana divides it three "
  "ways, and from those divisions come both the senses that perceive and the "
  "elements that are perceived -- so the perceiver and the perceived have a "
  "common root.",
  "अहंकार, पृथक् 'मैं' का भाव। पुराण इसे तीन भागों में बाँटता है, और उन्हीं से "
  "जानने वाली इंद्रियाँ तथा जाने जाने वाले भूत — दोनों उत्पन्न होते हैं। अतः "
  "द्रष्टा और दृश्य का मूल एक है।",
  CREATION_REF, None),

 "srishti-tanmatra": (
  "The tanmatras: sound, touch, form, taste and smell as bare qualities, "
  "before anything possesses them. They are the subtle side of what the five "
  "elements will be on the gross side.",
  "तन्मात्राएँ: शब्द, स्पर्श, रूप, रस और गंध — शुद्ध गुण के रूप में, इससे पूर्व "
  "कि कोई वस्तु उन्हें धारण करे। जो पंचभूत स्थूल रूप में होंगे, ये उसका सूक्ष्म "
  "पक्ष हैं।",
  CREATION_REF, None),

 "srishti-mahabhuta": (
  "Ether, air, fire, water and earth -- the point where the account finally "
  "reaches things that can be touched. Each element carries the qualities of "
  "the ones before it, which is why earth alone has all five.",
  "आकाश, वायु, अग्नि, जल और पृथ्वी — यहीं वर्णन उन वस्तुओं तक पहुँचता है जिन्हें "
  "छुआ जा सके। हर भूत अपने से पूर्व के गुण धारण करता है, इसीलिए पृथ्वी में "
  "पाँचों गुण हैं।",
  CREATION_REF, None),

 "srishti-brahmanda": (
  "The elements combine into a single egg, floating on the waters, and "
  "everything that exists is inside it. The shell is described as vast beyond "
  "counting -- which means the whole structure of worlds above and below has "
  "an outside.",
  "भूत मिलकर एक अंड बनाते हैं, जो जल पर तैरता है, और जो कुछ है वह उसी के भीतर "
  "है। उसका कोश अगणनीय विस्तार का कहा गया है — अर्थात् ऊपर-नीचे के समस्त लोकों "
  "की समूची रचना का भी एक बाहर है।",
  CREATION_REF,
  ("Accounts differ on where the egg belongs in the order. The Vishnu Purana "
   "places it after the elements have formed; other Puranic accounts open "
   "with it and derive the elements inside it.",
   "अंड का स्थान क्रम में कहाँ है, इस पर मत भिन्न हैं। विष्णु पुराण इसे भूतों "
   "के बनने के बाद रखता है; अन्य पुराण इसी से आरंभ करते हैं और भूतों को इसके "
   "भीतर उत्पन्न मानते हैं।")),

 "srishti-beings": (
  "Within the egg the worlds are arranged and beings ordered into their kinds. "
  "The Purana calls this the secondary creation, distinguishing the one-time "
  "unfolding of the elements from the ordering that repeats each cosmic day.",
  "अंड के भीतर लोक व्यवस्थित होते हैं और प्राणी अपनी-अपनी योनियों में स्थापित "
  "किए जाते हैं। पुराण इसे प्रतिसर्ग कहता है — भूतों के एक बार के प्रकटन को उस "
  "व्यवस्था से अलग करते हुए जो प्रत्येक कल्प में दोहराई जाती है।",
  CREATION_REF,
  ("Sarga and pratisarga are counted differently between Puranas. Some treat "
   "the ordering of beings as part of the first creation; the Vishnu Purana "
   "keeps them separate.",
   "सर्ग और प्रतिसर्ग की गणना पुराणों में भिन्न है। कुछ प्राणि-व्यवस्था को "
   "प्रथम सर्ग का ही अंग मानते हैं; विष्णु पुराण इन्हें पृथक् रखता है।")),
}

# Time-cycle and yuga nodes are matched by title where slugs are unknown.
BY_TITLE = {
 "Yuga": (
  "The base unit of the traditional reckoning. Four unequal yugas make one "
  "mahayuga, and their lengths stand in the ratio 4:3:2:1 -- so the first age "
  "is four times the last.",
  "पारंपरिक कालगणना की मूल इकाई। चार असमान युग मिलकर एक महायुग बनाते हैं, और "
  "उनकी अवधि 4:3:2:1 के अनुपात में है — प्रथम युग अंतिम से चार गुना।",
  TIME_REF, None),
 "Mahayuga": (
  "Four yugas together, 4,320,000 years. The Purana builds every larger "
  "measure by multiplying this one rather than by naming a new quantity.",
  "चारों युग मिलाकर 43,20,000 वर्ष। पुराण हर बड़ी इकाई इसी के गुणन से बनाता है, "
  "नई संख्या गढ़कर नहीं।",
  TIME_REF, None),
 "Manvantara": (
  "Seventy-one mahayugas, the reign of one Manu. Fourteen Manus in succession "
  "make a day of Brahma, and the Purana names each of them.",
  "इकहत्तर महायुग, एक मनु का शासनकाल। क्रमशः चौदह मनु मिलकर ब्रह्मा का एक दिन "
  "बनाते हैं, और पुराण प्रत्येक का नाम देता है।",
  TIME_REF, None),
 "Kalpa": (
  "A day of Brahma: fourteen manvantaras, after which the lower worlds are "
  "dissolved and remade. His night is as long, and his life is counted in "
  "years of such days -- the largest number the tradition uses.",
  "ब्रह्मा का एक दिन: चौदह मन्वंतर, जिसके बाद निचले लोक विलीन होकर पुनः रचे "
  "जाते हैं। उनकी रात्रि भी उतनी ही है, और उनका जीवन ऐसे दिनों के वर्षों में "
  "गिना जाता है — परंपरा की सबसे बड़ी संख्या।",
  TIME_REF, None),
}

path = ROOT / 'content' / 'data' / 'cosmology' / 'vishnu_purana.jsonl'
rows = [json.loads(l) for l in path.read_text(encoding='utf-8').splitlines()
        if l.strip()]

prose = notes = 0
for o in rows:
    hit = NODES.get(o['slug'])
    if hit is None:
        hit = BY_TITLE.get((o.get('title') or {}).get('en', ''))
    if hit is None:
        continue
    en, hi, ref, tradition = hit

    if 'long_description' not in o:
        o['long_description'] = {"en": en, "hi": hi}
        o.setdefault('sources', []).append({
            "source_slug": W, "source_chapter_or_section": ref,
            "is_primary": True, "last_verified_at": D, "verified_by": "TS"})
        prose += 1

    if tradition:
        attrs = o.setdefault('attributes', {})
        if 'traditions_differ' not in attrs:
            attrs['traditions_differ'] = {"en": tradition[0], "hi": tradition[1]}
            notes += 1

with path.open('w', encoding='utf-8', newline='\n') as fh:
    for o in rows:
        fh.write(json.dumps(o, ensure_ascii=False, sort_keys=True) + "\n")

print(f"prose added to {prose} nodes")
print(f"traditions-differ notes added to {notes} nodes")
