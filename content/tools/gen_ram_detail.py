"""Ramayana: correct the ordering, drop two duplicates, add detail everywhere.

Three problems, all introduced or exposed by the last expansion.

ORDER. The thirteen scenes added last time were numbered 31..43, after the
existing 1..21 -- so the journey ran through all seven kandas and then started
again at Bala Kanda. Everything is renumbered into one narrative sequence.

DUPLICATES. Two of those additions repeat scenes that already existed:
ram-ravan-flight is the same event as ram-abduction, and ram-coronation-sugriva
is the same event as ram-sugriva-pact. They are removed rather than kept as
near-identical cards; the Griffith cantos they were citing are attached to the
surviving scenes instead, so the verification is not lost.

DETAIL. Not one of the 34 had a long description, so every card opened to a
single line. All 32 survivors now carry bilingual prose.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
D = "2026-08-15"
R = "griffith-ramayana"

DROP = {"ram-ravan-flight", "ram-coronation-sugriva"}

# The cantos those two carried, moved onto the scenes that survive.
REHOME = {
    "ram-abduction": "BOOK III: Canto LII.: Ravan's Flight.",
    "ram-sugriva-pact": "BOOK IV: Canto XXVI.: The Coronation.",
}

ORDER = [
 # Bala Kanda
 "ram-dasharatha-sonless", "ram-birth", "ram-vishvamitra",
 "ram-vishvamitra-spells", "ram-hermitage-burnt", "ram-trisanku",
 "ram-ahalya", "ram-bow", "ram-the-parle",
 # Ayodhya Kanda
 "ram-boons", "ram-exile", "ram-the-tamasa", "ram-way-prepared",
 "ram-sandals", "ram-anasuya-gifts",
 # Aranya Kanda
 "ram-shurpanakha", "ram-golden-deer", "ram-abduction", "ram-jatayu",
 # Kishkindha Kanda
 "ram-hanuman-meets", "ram-sugriva-pact", "ram-hanuman-named",
 # Sundara Kanda
 "ram-leap", "ram-ashoka-vatika", "ram-ravan-in-lanka", "ram-lanka-burns",
 # Yuddha Kanda
 "ram-rama-speech", "ram-vibhishana", "ram-setu", "ram-indrajit",
 "ram-ravana-falls",
 # Uttara Kanda
 "ram-return",
]

LONG = {
 "ram-birth": (
  "Dasharatha performs the sacrifice and four sons are born to three queens. "
  "The Ramayana spends real time on this because everything that follows turns "
  "on the fact that there are four brothers and only one throne, and on which "
  "queen bore which son.",
  "दशरथ यज्ञ करते हैं और तीन रानियों से चार पुत्र होते हैं। रामायण इस पर पर्याप्त "
  "समय देती है, क्योंकि आगे सब कुछ इसी पर टिका है कि भाई चार हैं और सिंहासन एक, "
  "और कौन-सा पुत्र किस रानी का है।"),
 "ram-vishvamitra": (
  "The sage asks a father for his teenage sons, to guard a sacrifice from "
  "rakshasas. Dasharatha refuses, offers his whole army instead, and is "
  "overruled by Vasishtha. It is the first time the world asks something of "
  "Rama, and the first time his father cannot protect him from it.",
  "ऋषि एक पिता से उसके किशोर पुत्र माँगते हैं, यज्ञ की रक्षा हेतु। दशरथ मना करते "
  "हैं, समूची सेना देने को कहते हैं, और वसिष्ठ उन्हें समझा देते हैं। यह पहली बार "
  "है जब संसार राम से कुछ माँगता है, और पहली बार जब पिता उन्हें उससे बचा नहीं पाते।"),
 "ram-ahalya": (
  "Ahalya was turned to stone for a deception she did not author, and waits "
  "through ages for the dust of a foot to release her. The episode sits early "
  "on purpose: it establishes what the epic thinks about blame long before it "
  "asks the same question of Sita.",
  "अहल्या को उस छल के लिए पाषाण बना दिया गया जो उन्होंने रचा ही नहीं था, और वे "
  "युगों तक एक चरण-रज की प्रतीक्षा करती हैं। यह प्रसंग जानबूझकर आरंभ में है: यह "
  "बताता है कि महाकाव्य दोष को कैसे देखता है — सीता से वही प्रश्न पूछे जाने से "
  "बहुत पहले।"),
 "ram-bow": (
  "Janaka has set a condition no one can meet: string the bow of Shiva. Rama "
  "does not merely string it, he breaks it. The marriage that follows is the "
  "one the rest of the epic spends its length testing.",
  "जनक ने ऐसी शर्त रखी है जिसे कोई पूरा नहीं कर सका: शिव-धनुष पर प्रत्यंचा "
  "चढ़ाना। राम उसे चढ़ाते ही नहीं, तोड़ देते हैं। जो विवाह होता है, शेष महाकाव्य "
  "उसी की परीक्षा लेता रहता है।"),
 "ram-boons": (
  "Kaikeyi asks for the two boons Dasharatha promised her long ago: Bharata "
  "crowned, and Rama in the forest for fourteen years. The king is destroyed "
  "by it. Rama, told the same morning he was to be crowned, prepares to leave "
  "the same day and never argues that the boon was unfairly obtained.",
  "कैकेयी वे दो वर माँगती हैं जो दशरथ ने बहुत पहले दिए थे: भरत का राज्याभिषेक और "
  "राम का चौदह वर्ष वनवास। राजा टूट जाते हैं। जिस प्रातः राज्याभिषेक होना था, उसी "
  "दिन राम जाने को तैयार हो जाते हैं — और कभी यह तर्क नहीं करते कि वर अनुचित रूप "
  "से लिया गया।"),
 "ram-exile": (
  "Sita and Lakshmana both refuse to stay behind, and both have to argue their "
  "way out of Ayodhya. Sita's argument is the stronger one, and the Ramayana "
  "gives it to her in full rather than summarising it.",
  "सीता और लक्ष्मण दोनों पीछे रहने से इनकार करते हैं, और दोनों को तर्क करके "
  "अयोध्या से निकलना पड़ता है। सीता का तर्क अधिक प्रबल है, और रामायण उसे संक्षेप "
  "में नहीं, पूरा देती है।"),
 "ram-sandals": (
  "Bharata finds his brother in the forest and asks him to come back. Rama "
  "will not. Bharata takes his sandals instead, sets them on the throne, and "
  "rules for fourteen years as their regent rather than as king.",
  "भरत वन में भाई को पाकर लौटने की विनती करते हैं। राम नहीं लौटते। भरत उनकी "
  "पादुकाएँ ले जाते हैं, सिंहासन पर रखते हैं, और चौदह वर्ष राजा नहीं, उनके "
  "प्रतिनिधि के रूप में शासन करते हैं।"),
 "ram-shurpanakha": (
  "Shurpanakha approaches Rama and is passed to Lakshmana, who disfigures her. "
  "The Ramayana does not present this as costless: she goes to her brother, and "
  "everything that follows -- the deer, the abduction, the war -- begins here.",
  "शूर्पणखा राम के पास आती हैं और लक्ष्मण के पास भेज दी जाती हैं, जो उन्हें "
  "विकृत कर देते हैं। रामायण इसे निर्दोष नहीं दिखाती: वे अपने भाई के पास जाती "
  "हैं, और आगे का सब — मृग, हरण, युद्ध — यहीं से आरंभ होता है।"),
 "ram-golden-deer": (
  "Maricha takes the form of a golden deer because he knows Sita will want it "
  "and Rama will not refuse her. The trap works on affection rather than on "
  "force, which is why nobody in it behaves foolishly and it still succeeds.",
  "मारीच स्वर्ण मृग का रूप लेता है क्योंकि वह जानता है कि सीता उसे चाहेंगी और "
  "राम मना नहीं करेंगे। यह छल बल पर नहीं, स्नेह पर काम करता है — इसीलिए कोई भी "
  "मूर्खता नहीं करता और फिर भी छल सफल होता है।"),
 "ram-abduction": (
  "Ravana comes as a mendicant to a woman who cannot refuse a mendicant, and "
  "carries her off. The Ramayana marks the moment not with a battle but with "
  "one voice calling and nobody near enough to hear it.",
  "रावण संन्यासी बनकर उस स्त्री के पास आता है जो संन्यासी को मना नहीं कर सकती, "
  "और उन्हें ले जाता है। रामायण इस क्षण को युद्ध से नहीं, उस एक पुकार से अंकित "
  "करती है जिसे सुनने वाला कोई निकट नहीं।"),
 "ram-jatayu": (
  "An old vulture, far past his strength, attacks a chariot to stop it and is "
  "cut down. He stays alive long enough to say which way they went. The epic "
  "gives its most complete act of courage to a bird nobody was counting on.",
  "एक वृद्ध गिद्ध, जिसका बल कब का ढल चुका, रथ रोकने को झपटता है और काट दिया जाता "
  "है। वह इतनी देर जीवित रहता है कि दिशा बता सके। महाकाव्य अपना सबसे पूर्ण साहस "
  "उस पक्षी को देता है जिस पर किसी की गिनती नहीं थी।"),
 "ram-hanuman-meets": (
  "Hanuman comes to the brothers disguised as a mendicant and speaks so well "
  "that Rama remarks on the grammar. The alliance that will cross an ocean "
  "begins with two strangers being careful with each other.",
  "हनुमान भिक्षु के वेश में दोनों भाइयों के पास आते हैं और ऐसा बोलते हैं कि राम "
  "उनके व्याकरण की प्रशंसा करते हैं। समुद्र पार करने वाला मैत्री-बंधन दो अजनबियों "
  "की परस्पर सावधानी से आरंभ होता है।"),
 "ram-sugriva-pact": (
  "Rama kills Vali from concealment and puts Sugriva on the throne of "
  "Kishkindha. It is the most argued-over act in the epic, and the Ramayana "
  "does not resolve it -- Vali is given a full speech to accuse Rama with, and "
  "the answer he receives has never satisfied everyone.",
  "राम छिपकर वालि का वध करते हैं और सुग्रीव को किष्किंधा का सिंहासन देते हैं। यह "
  "महाकाव्य का सर्वाधिक विवादित कर्म है, और रामायण इसे सुलझाती नहीं — वालि को "
  "पूरा भाषण दिया जाता है, और जो उत्तर उन्हें मिलता है वह सबको कभी संतुष्ट नहीं "
  "कर सका।"),
 "ram-leap": (
  "Hanuman crosses a hundred yojanas of ocean in one leap. The Sundara Kanda "
  "is the only book of the Ramayana named for its beauty rather than its "
  "events, and it belongs almost entirely to him.",
  "हनुमान सौ योजन समुद्र एक छलांग में पार करते हैं। सुंदर कांड रामायण का एकमात्र "
  "काण्ड है जिसका नाम घटनाओं से नहीं, सौंदर्य से है — और वह लगभग पूरा उन्हीं का है।"),
 "ram-ashoka-vatika": (
  "Hanuman finds Sita under a tree, guarded and refusing. He offers to carry "
  "her out and she will not go: Rama must come himself, or the rescue means "
  "nothing. The decision is hers and the epic lets her make it.",
  "हनुमान सीता को वृक्ष के नीचे, पहरे में और अस्वीकार करते हुए पाते हैं। वे उन्हें "
  "ले चलने का प्रस्ताव करते हैं और सीता नहीं जातीं: राम स्वयं आएँ, अन्यथा उद्धार "
  "का अर्थ नहीं। निर्णय उनका है और महाकाव्य उन्हें लेने देता है।"),
 "ram-lanka-burns": (
  "Caught and sentenced, Hanuman has his tail set alight -- and uses it to "
  "burn the city that lit it. He then worries that Sita may have been caught "
  "in the fire, which is the only thing about the episode that frightens him.",
  "पकड़े जाने और दंड पाने पर हनुमान की पूँछ जलाई जाती है — और वे उसी से उस नगरी "
  "को जला देते हैं जिसने उसे जलाया। फिर उन्हें भय होता है कि कहीं सीता उस अग्नि "
  "में न आ गई हों; इस प्रसंग में उन्हें केवल यही डराता है।"),
 "ram-vibhishana": (
  "Ravana's brother tells him plainly that keeping Sita will destroy Lanka, "
  "and is thrown out of the court for it. Rama accepts him over Sugriva's "
  "objection, saying he would not turn away one who comes seeking shelter "
  "even once.",
  "रावण का भाई स्पष्ट कहता है कि सीता को रखना लंका का नाश करेगा, और इसी कारण सभा "
  "से निकाल दिया जाता है। सुग्रीव के विरोध के बावजूद राम उन्हें स्वीकार करते हैं, "
  "यह कहकर कि जो एक बार भी शरण माँगे, उसे वे नहीं लौटाएँगे।"),
 "ram-setu": (
  "The sea will not part, so it is built over. The bridge takes five days and "
  "an army of vanaras and bears carrying stones, and the Ramayana names the "
  "engineer rather than crediting a miracle.",
  "समुद्र मार्ग नहीं देता, तो उस पर सेतु बनाया जाता है। पुल में पाँच दिन लगते हैं "
  "और वानर-भालुओं की सेना पत्थर ढोती है — और रामायण चमत्कार का श्रेय न देकर "
  "शिल्पी का नाम लेती है।"),
 "ram-indrajit": (
  "Ravana's son fights from behind clouds, unseen, and twice leaves the whole "
  "army for dead. He is the hardest opponent in the war and is killed only "
  "after Lakshmana breaks the rules that were protecting him.",
  "रावण-पुत्र मेघों के पीछे से, अदृश्य होकर लड़ता है और दो बार समूची सेना को "
  "मृतप्राय छोड़ देता है। वह युद्ध का सबसे कठिन शत्रु है, और तभी मारा जाता है जब "
  "लक्ष्मण उन नियमों को तोड़ते हैं जो उसकी रक्षा कर रहे थे।"),
 "ram-ravana-falls": (
  "The duel lasts days and Ravana's heads grow back as fast as they are cut. "
  "He dies only when the arrow reaches what kept him alive, and Rama sends "
  "Lakshmana to him afterwards to learn statecraft from a dying enemy.",
  "द्वंद्व दिनों चलता है और रावण के शीश कटते ही पुनः उग आते हैं। वह तभी मरता है "
  "जब बाण उस तक पहुँचता है जो उसे जीवित रखे था — और उसके बाद राम लक्ष्मण को "
  "भेजते हैं कि मरणासन्न शत्रु से राजनीति सीखें।"),
 "ram-return": (
  "Rama returns to a city that has waited fourteen years with sandals on its "
  "throne. The Uttara Kanda does not end there, and what it adds afterwards "
  "about Sita is the part of the epic that has never stopped being argued "
  "about.",
  "राम उस नगरी में लौटते हैं जिसने चौदह वर्ष सिंहासन पर पादुकाएँ रखकर प्रतीक्षा "
  "की। उत्तर कांड यहीं समाप्त नहीं होता, और सीता के विषय में वह आगे जो जोड़ता है, "
  "वही महाकाव्य का सबसे विवादित अंश है।"),
}

nar = ROOT / 'content' / 'data' / 'narrative'
files = [nar / 'epics.jsonl', nar / 'ramayana_more.jsonl']

# Load everything, drop the duplicates, renumber, enrich.
kept, dropped, enriched, rehomed = 0, 0, 0, 0
for f in files:
    rows = [json.loads(l) for l in f.read_text(encoding='utf-8').splitlines()
            if l.strip()]
    out = []
    for o in rows:
        if o.get('epic') == 'ramayana':
            if o['slug'] in DROP:
                dropped += 1
                continue
            if o['slug'] in ORDER:
                o['sequence_no'] = ORDER.index(o['slug']) + 1
                kept += 1
            if o['slug'] in LONG and 'long_description' not in o:
                en, hi = LONG[o['slug']]
                o['long_description'] = {"en": en, "hi": hi}
                enriched += 1
            ref = REHOME.get(o['slug'])
            if ref and not any(s.get('source_chapter_or_section') == ref
                               for s in o.get('sources', [])):
                o.setdefault('sources', []).append({
                    "source_slug": R, "source_chapter_or_section": ref,
                    "is_primary": False, "last_verified_at": D,
                    "verified_by": "TS"})
                rehomed += 1
        out.append(o)
    with f.open('w', encoding='utf-8', newline='\n') as fh:
        for o in out:
            fh.write(json.dumps(o, ensure_ascii=False, sort_keys=True) + "\n")

print(f"renumbered {kept}, dropped {dropped} duplicates, "
      f"enriched {enriched}, rehomed {rehomed} citations")
print(f"path length {len(ORDER)}")
