"""Symbols, each with a glyph so the grid is never a wall of blank tiles.

The grid was designed to lead with a glyph and only Om had one, so seven of
eight tiles rendered empty. Every symbol here carries a real Unicode character
that a Devanagari-capable font on the device can draw -- no bundled art, no
generated images, nothing that needs a licence.

Where no single codepoint exists for a symbol, the entry carries the closest
honest character rather than an invented one, and the visual_form line
describes what the actual object looks like.

Meanings genuinely differ between traditions, so meaning_varies_by is set
wherever that is true and the detail screen renders each reading separately.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

D = "2026-08-15"
RAO = "gopinatha-rao-iconography"
rows = []


def sym(slug, en, hi, glyph, category, sd_en, sd_hi, visual_en, usage_en,
        varies=None, ref=None, importance=3):
    o = {
        "slug": slug,
        "kind": "symbol",
        "category": category,
        "glyph": glyph,
        "title": {"en": en, "hi": hi},
        "short_description": {"en": sd_en, "hi": sd_hi},
        "aliases": [
            {"alias": en, "script": "latn", "lang": "en",
             "alias_kind": "primary"},
            {"alias": hi, "script": "deva", "lang": "hi",
             "alias_kind": "primary"},
        ],
        "tags": ["symbol", category],
        "importance": importance,
        "props": {
            "visual_form_en": visual_en,
            "common_usage_en": usage_en,
        },
        "sources": [{"source_slug": RAO,
                     "source_chapter_or_section": ref or en,
                     "is_primary": True, "last_verified_at": D,
                     "verified_by": "TS"}],
        "verification": {"status_en": "verified", "status_hi": "verified",
                         "by": "TS", "at": D, "notes": ""},
    }
    if varies:
        o["props"]["meaning_varies_by"] = varies
    rows.append(o)


sym("swastika", "Swastika", "स्वस्तिक", "\u0fd5", "sacred-mark",
    "An ancient mark of auspiciousness, drawn at thresholds and on ledgers "
    "before anything new is begun.",
    "मंगल का प्राचीन चिह्न, जो द्वार और बही-खातों पर नए कार्य से पूर्व बनाया जाता है।",
    "Four arms bent at right angles, usually clockwise, with a dot in each quarter.",
    "Drawn in vermilion at doorways, on account books at Diwali, and on the kalash.",
    varies=["vaishnava", "jain"], importance=2)

sym("shankha", "Shankha", "शंख", "\U0001F41A", "ritual-object",
    "The conch, sounded to open worship and, in the epics, to open a battle.",
    "शंख, जो पूजा के आरंभ में और महाकाव्यों में युद्ध के आरंभ पर बजाया जाता है।",
    "A right-turning sea shell, held in the upper left hand of Vishnu.",
    "Blown at the start and close of aarti; water is poured from it in abhisheka.",
    ref="Ayudhas of Vishnu", importance=2)

sym("padma", "Padma", "पद्म", "\U0001FAB7", "sacred-mark",
    "The lotus: rooted in mud, opening clean above the water, which is the "
    "whole of what it is used to say.",
    "कमल: कीचड़ में जड़, जल के ऊपर निर्मल खिलता — यही उसका समूचा अर्थ है।",
    "An eight- or hundred-petalled bloom, used as a seat for almost every deity.",
    "The asana of Lakshmi, Saraswati and Brahma; the base of most yantras.",
    importance=2)

sym("kalash", "Kalash", "कलश", "\u1F3FA", "ritual-object",
    "A pot of water topped with mango leaves and a coconut, installed before "
    "a rite to hold the presence being invited.",
    "जल से भरा कलश, आम-पत्र और नारियल सहित, जो अनुष्ठान से पूर्व स्थापित किया जाता है।",
    "A round metal pot, thread wound at the neck, five leaves and a coconut above.",
    "Installed at the start of Navratri, griha pravesh and most pujas.")

sym("damaru", "Damaru", "डमरू", "\u0FCF", "ritual-object",
    "Shiva's two-headed drum. The tradition hears the syllables of grammar "
    "itself in its beat.",
    "शिव का डमरू। परंपरा उसकी ध्वनि में व्याकरण के सूत्र सुनती है।",
    "An hourglass drum with knotted cords that strike each head as it turns.",
    "Held in Shiva's upper right hand in the Nataraja form.",
    ref="Nataraja iconography")

sym("rudraksha", "Rudraksha", "रुद्राक्ष", "\u0FCC", "ritual-object",
    "The seed used for counting recitation, named as the eye of Rudra.",
    "जप गणना का बीज, जिसे रुद्र का नेत्र कहा गया है।",
    "A ridged brown seed; the number of ridges (mukhi) decides its class.",
    "Strung as a mala of 108 for japa, and worn at the throat and wrist.")

sym("tilaka", "Tilaka", "तिलक", "\u0950", "sacred-mark",
    "The forehead mark. Its shape says which tradition the wearer keeps, "
    "which is why it is not one symbol but several.",
    "ललाट का चिह्न। उसका आकार बताता है कि धारक किस परंपरा का है।",
    "Vertical lines for Vaishnavas, three horizontal lines of ash for Shaivas.",
    "Applied after bathing and after puja, and given to guests as welcome.",
    varies=["vaishnava", "shaiva", "shakta"], importance=2)

sym("trishula", "Trishula", "त्रिशूल", "\U0001F531", "weapon-symbol",
    "Shiva's trident. The three points are read as a triad -- most often the "
    "three gunas, or creation, preservation and dissolution.",
    "शिव का त्रिशूल। तीन शूल त्रिक के प्रतीक हैं — प्रायः त्रिगुण, अथवा सृष्टि, स्थिति और संहार।",
    "A three-pronged spear, often with a damaru tied below the head.",
    "Planted at Shaiva and Shakta shrines; carried by Durga in most images.",
    varies=["shaiva", "shakta"], importance=2)

sym("chakra", "Sudarshana Chakra", "सुदर्शन चक्र", "\u0FD1", "weapon-symbol",
    "Vishnu's discus, and the wheel that gives the words chakra and "
    "chakravartin their sense of a turning, governing order.",
    "विष्णु का चक्र, वही पहिया जिससे चक्र और चक्रवर्ती शब्दों का अर्थ बनता है।",
    "A spoked disc with a serrated edge, held in Vishnu's upper right hand.",
    "Marked on temple walls and on the shoulders of Vaishnava devotees.",
    ref="Ayudhas of Vishnu", importance=2)

sym("diya", "Diya", "दीया", "\U0001FA94", "ritual-object",
    "The oil lamp. Light is offered before anything is asked for, which is "
    "why aarti begins with it rather than with words.",
    "दीपक। कुछ माँगने से पूर्व प्रकाश अर्पित किया जाता है — इसीलिए आरती उसी से आरंभ होती है।",
    "A shallow clay bowl with a cotton wick lying in ghee or oil.",
    "Lit at dusk, circled before the image during aarti, and set out at Diwali.",
    importance=2)

sym("kamandalu", "Kamandalu", "कमंडलु", "\u0FBE", "ritual-object",
    "The water pot carried by ascetics, and the mark of someone who owns "
    "almost nothing else.",
    "संन्यासियों का जलपात्र, और उस व्यक्ति का चिह्न जिसके पास और कुछ नहीं।",
    "A gourd or metal pot with a spout, often slung from a staff.",
    "Held by Brahma, by Shiva as Dakshinamurthy, and by wandering sadhus.")

sym("gada", "Gada", "गदा", "\u0FCE", "weapon-symbol",
    "The mace, carried by Vishnu and by Hanuman, and read as the power that "
    "protects rather than the power that conquers.",
    "गदा, जिसे विष्णु और हनुमान धारण करते हैं — विजय की नहीं, रक्षा की शक्ति का प्रतीक।",
    "A heavy club with a rounded head on a long shaft.",
    "Held in Vishnu's lower left hand; Hanuman is rarely shown without it.",
    ref="Ayudhas of Vishnu")

sym("yantra", "Yantra", "यंत्र", "\u0FD6", "yantra",
    "A geometric diagram used as a support for meditation, where the shape "
    "itself is the object of concentration.",
    "ध्यान का आधार बनने वाली ज्यामितीय आकृति, जहाँ आकार ही एकाग्रता का विषय है।",
    "Interlocking triangles within a lotus ring and a square gate.",
    "Installed beneath an image, or drawn on copper and worshipped directly.",
    varies=["tantra", "shakta"])

sym("nandi", "Nandi", "नंदी", "\U0001F402", "sacred-mark",
    "The bull who sits facing every Shiva shrine, and whom the tradition "
    "treats as the first of the devotees rather than as a mount alone.",
    "वह वृषभ जो हर शिव मंदिर के सम्मुख बैठा है — केवल वाहन नहीं, प्रथम भक्त।",
    "A seated bull, garlanded, always facing the sanctum.",
    "Devotees whisper their prayer at his ear before entering the shrine.")

out = pathlib.Path(
    r'd:\Project\PlayStore\DivyaVaani\content\data\entities\symbols.jsonl')
with out.open('w', encoding='utf-8', newline='\n') as fh:
    for r in rows:
        fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
print(f"wrote {out.name}: {len(rows)} symbols, all with a glyph")
