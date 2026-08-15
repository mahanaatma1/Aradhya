"""More Ramayana scenes.

The journey shipped with 21 scenes across seven kandas -- two for the whole of
Kishkindha and one for Uttara -- so the path had long empty stretches exactly
where the story is busiest.

Every scene here cites a canto whose label was read off the page itself. That
matters more than usual: in the first pass of this work every label was guessed
from the URL and all of them were wrong, so a citation that has not been
checked against the page is worth nothing.

sequence_no continues the existing Valmiki ordering. Recension stays 'valmiki'
throughout -- a Ramcharitmanas scene would be a different telling, not another
half of this one.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

D = "2026-08-15"
R = "griffith-ramayana"
rows = []


def scene(slug, seq, book_no, book_en, book_hi, en, hi, sd_en, sd_hi,
          ref, cast=(), lesson=None, place=None):
    o = {
        "slug": slug,
        "epic": "ramayana",
        "recension": "valmiki",
        "book_label": {"en": book_en, "hi": book_hi},
        "book_no": book_no,
        "sequence_no": seq,
        "title": {"en": en, "hi": hi},
        "short_description": {"en": sd_en, "hi": sd_hi},
        "tags": ["ramayana"],
        "cast": [{"entity_slug": c, "role": r} for c, r in cast],
        "sources": [{"source_slug": R, "source_chapter_or_section": ref,
                     "is_primary": True, "last_verified_at": D,
                     "verified_by": "TS"}],
        "verification": {"status_en": "verified", "status_hi": "verified",
                         "by": "TS", "at": D, "notes": ""},
    }
    if lesson:
        o["lesson"] = {"en": lesson[0], "hi": lesson[1]}
    if place:
        o["place_entity_slug"] = place
    rows.append(o)


BALA = ("Bala Kanda", "बाल कांड")
AYOD = ("Ayodhya Kanda", "अयोध्या कांड")
ARAN = ("Aranya Kanda", "अरण्य कांड")
KISH = ("Kishkindha Kanda", "किष्किंधा कांड")
SUND = ("Sundara Kanda", "सुंदर कांड")
YUDD = ("Yuddha Kanda", "युद्ध कांड")

scene("ram-dasharatha-sonless", 31, 1, *BALA,
      "A King Without a Son", "निःसंतान राजा",
      "Dasharatha rules well and has everything except an heir, and the whole "
      "epic begins from that single lack.",
      "दशरथ का शासन उत्तम है, पर उत्तराधिकारी नहीं — और समूचा महाकाव्य इसी एक "
      "अभाव से आरंभ होता है।",
      "BOOK I: Canto VI.: The King.",
      cast=[("dasharatha", "protagonist")],
      lesson=("The Ramayana opens not with a hero but with an absence.",
              "रामायण नायक से नहीं, एक अभाव से आरंभ होती है।"))

scene("ram-vishvamitra-spells", 32, 1, *BALA,
      "The Two Spells", "दो विद्याएँ",
      "Vishvamitra gives the boys Bala and Atibala, so that they will not "
      "hunger, thirst or tire on the road ahead.",
      "विश्वामित्र दोनों बालकों को बला और अतिबला देते हैं, जिससे मार्ग में "
      "भूख, प्यास और थकान उन्हें न रोके।",
      "BOOK I: Canto XXIV.: The Spells.",
      cast=[("vishvamitra", "protagonist"), ("rama", "protagonist")])

scene("ram-hermitage-burnt", 33, 1, *BALA,
      "The Hermitage Burnt", "आश्रम दहन",
      "Vishvamitra brings an army against Vasishtha's hermitage and learns "
      "that force cannot take what austerity has earned.",
      "विश्वामित्र सेना लेकर वसिष्ठ के आश्रम पर आते हैं और जानते हैं कि बल वह "
      "नहीं ले सकता जो तप से अर्जित है।",
      "BOOK I: Canto LV.: The Hermitage Burnt.",
      cast=[("vishvamitra", "antagonist"), ("vasishtha", "protagonist")],
      lesson=("The defeat is what turns a king into a sage.",
              "यही पराजय एक राजा को ऋषि बनाती है।"))

scene("ram-trisanku", 34, 1, *BALA,
      "Trisanku's Ascension", "त्रिशंकु की चढ़ाई",
      "Refused heaven in his own body, Trisanku is left hanging between worlds "
      "while Vishvamitra begins building him another one.",
      "सशरीर स्वर्ग से लौटाए गए त्रिशंकु दो लोकों के बीच लटके रह जाते हैं, और "
      "विश्वामित्र दूसरा स्वर्ग रचने लगते हैं।",
      "BOOK I: Canto LX.: Tris'anku's Ascension.",
      cast=[("vishvamitra", "protagonist")])

scene("ram-the-parle", 35, 1, *BALA,
      "The Parle", "परशुराम से भेंट",
      "On the road home from the wedding the party is stopped by Parashurama, "
      "and one bow is exchanged for another.",
      "विवाह से लौटते मार्ग में परशुराम रोकते हैं, और एक धनुष के बदले दूसरा "
      "दिया जाता है।",
      "BOOK I: Canto LXXV.: The Parle.",
      cast=[("rama", "protagonist"), ("parashurama", "antagonist")])

scene("ram-the-tamasa", 36, 2, *AYOD,
      "The Tamasa", "तमसा तट",
      "The citizens follow Rama out of Ayodhya and camp beside him. He waits "
      "for them to sleep and slips away, so they cannot ruin themselves for him.",
      "नगरवासी राम के पीछे चल पड़ते हैं और तमसा तट पर ठहरते हैं। वे उनके सो "
      "जाने की प्रतीक्षा कर चुपचाप निकल जाते हैं।",
      "Book II: Canto XLV.: The Tamasa.",
      cast=[("rama", "protagonist"), ("sita", "protagonist")],
      lesson=("Leaving quietly is the kinder act, and the harder one.",
              "चुपचाप जाना अधिक कठिन है, और अधिक दयालु भी।"))

scene("ram-way-prepared", 37, 2, *AYOD,
      "The Way Prepared", "मार्ग की तैयारी",
      "Bharata sets out for the forest with an army, an elephant train and the "
      "whole court -- not to fight his brother but to beg him to come back.",
      "भरत सेना, गजदल और समूची सभा लेकर वन की ओर चलते हैं — भाई से युद्ध को "
      "नहीं, उसे लौटाने की विनती को।",
      "Book II: Canto LXXX.: The Way Prepared.",
      cast=[("bharata", "protagonist")])

scene("ram-anasuya-gifts", 38, 2, *AYOD,
      "Anasuya's Gifts", "अनसूया का उपहार",
      "The sage's wife gives Sita ornaments and unguents that will not fade in "
      "the forest, and asks her how she came to choose exile.",
      "ऋषिपत्नी सीता को ऐसे आभूषण और अंगराग देती हैं जो वन में मलिन नहीं होते, "
      "और पूछती हैं कि उन्होंने वनवास क्यों चुना।",
      "Book II: Canto CXVIII.: Anasuya's Gifts.",
      cast=[("sita", "protagonist")])

scene("ram-ravan-flight", 39, 3, *ARAN,
      "Ravana's Flight", "रावण का पलायन",
      "Sita is carried off, and the Ramayana marks the moment not with a "
      "battle but with the sound of one voice calling and no one near enough "
      "to hear it.",
      "सीता का हरण होता है, और रामायण इस क्षण को युद्ध से नहीं, उस पुकार से "
      "अंकित करती है जिसे सुनने वाला कोई निकट नहीं।",
      "BOOK III: Canto LII.: Ravan's Flight.",
      cast=[("ravana", "antagonist"), ("sita", "protagonist")])

scene("ram-coronation-sugriva", 40, 4, *KISH,
      "The Coronation", "सुग्रीव का राज्याभिषेक",
      "Sugriva is restored to Kishkindha, and the alliance that will cross the "
      "sea is sealed with a throne rather than an oath.",
      "सुग्रीव को किष्किंधा वापस मिलती है, और समुद्र पार करने वाला मैत्री-बंधन "
      "शपथ से नहीं, सिंहासन से पक्का होता है।",
      "BOOK IV: Canto XXVI.: The Coronation.",
      cast=[("sugriva", "protagonist"), ("rama", "protagonist")])

scene("ram-hanuman-named", 41, 4, *KISH,
      "Hanuman Remembers", "हनुमान को स्मरण",
      "The Vanaras reach the shore and stop. Hanuman has to be reminded of his "
      "own strength before he will attempt the leap.",
      "वानर तट पर पहुँचकर रुक जाते हैं। छलांग से पूर्व हनुमान को उनका अपना बल "
      "स्मरण कराना पड़ता है।",
      "BOOK IV: Canto LXVI.: Hanuman.",
      cast=[("hanuman", "protagonist")],
      lesson=("The greatest capability in the epic is the one its owner forgot.",
              "महाकाव्य की सबसे बड़ी शक्ति वही है जिसे उसके धारक ने भुला दिया।"))

scene("ram-ravan-in-lanka", 42, 5, *SUND,
      "Ravana in His Own Hall", "अपनी सभा में रावण",
      "Hanuman, hidden, watches Ravana at rest and finds him magnificent -- "
      "which is exactly why the Ramayana lets him look.",
      "छिपे हुए हनुमान विश्राम करते रावण को देखते हैं और उसे तेजस्वी पाते हैं "
      "— रामायण उन्हें यही दिखाने देती है।",
      "BOOK V: Canto XVIII.: Ravan.",
      cast=[("hanuman", "protagonist"), ("ravana", "antagonist")])

scene("ram-rama-speech", 43, 6, *YUDD,
      "Rama's Speech", "राम का वचन",
      "With the sea in front of them and no way across, Rama thanks Hanuman "
      "for news of Sita and says plainly that he does not know what to do next.",
      "समुद्र सामने है और मार्ग नहीं। राम हनुमान को सीता का समाचार लाने के लिए "
      "धन्यवाद देते हैं और स्पष्ट कहते हैं कि आगे क्या करें, वे नहीं जानते।",
      "BOOK VI: Canto I.: Rama's Speech.",
      cast=[("rama", "protagonist"), ("hanuman", "protagonist")])

out = pathlib.Path(
    r'd:\Project\PlayStore\DivyaVaani\content\data\narrative\ramayana_more.jsonl')
with out.open('w', encoding='utf-8', newline='\n') as fh:
    for r in rows:
        fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
print(f"wrote {out.name}: {len(rows)} scenes")
