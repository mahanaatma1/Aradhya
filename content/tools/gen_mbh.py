"""Mahabharata: twelve more events, and detail on every one.

The journey carried twenty events for eighteen parvas, so whole books had no
scene at all -- Virata and Mausala were invisible, and the Adi Parva jumped
from Drona's teaching straight to the swayamvara. Worse, not one scene had a
long description, so every card opened to a single line.

Both are fixed here. The twelve additions are placed where they belong in the
narrative rather than appended, so the existing scenes are renumbered; they
stay inside 1..99 because the eighteen war days occupy 101..118 and a collision
there would put battle days in the middle of the main path.

Every citation is a chapter fetched into content/raw and labelled from the page
itself. In the first pass of this work every label was guessed from a URL and
all 34 were wrong, so nothing here is cited that has not been read.
"""
import json, pathlib, sys

sys.path.insert(0, r'd:\Project\PlayStore\DivyaVaani')
import content.tools.common  # noqa: F401

ROOT = pathlib.Path(r'd:\Project\PlayStore\DivyaVaani')
D = "2026-08-15"
G = "ganguli-mahabharata"

# ---------------------------------------------------------------- new scenes
# (slug, book_no, book_en, book_hi, title_en, title_hi, short_en, short_hi,
#  citation, cast)
NEW = [
 ("mbh-karna-tournament", 1, "Adi Parva", "आदि पर्व",
  "The Tournament", "रंगभूमि",
  "Karna outshoots the princes and is asked, in front of everyone, who his "
  "father is. A charioteer walks into the arena and claims him.",
  "कर्ण राजकुमारों से आगे निकल जाते हैं, और सबके सामने उनका कुल पूछा जाता है। "
  "तभी एक सूत रंगभूमि में आकर उन्हें अपना पुत्र कहता है।",
  "The Mahabharata, Book 1: Adi Parva: Section CXXXIX",
  [("karna", "protagonist"), ("duryodhana", "protagonist"),
   ("arjuna", "antagonist")],
  "Ganguli lets the humiliation land without softening it. Adhiratha comes "
  "forward trembling, leaning on a staff, and Karna -- who has just proved "
  "himself the equal of any man there -- bows his head to him in front of the "
  "whole assembly. Duryodhana makes him a king on the spot, and buys a loyalty "
  "that will outlast every argument anyone brings against it.",
  "गांगुली इस अपमान को बिना कोमल किए दर्ज करते हैं। अधिरथ काँपते हुए, लाठी के "
  "सहारे आगे आते हैं, और कर्ण — जो अभी-अभी सबके समान सिद्ध हुए हैं — समूची सभा "
  "के सामने उनके चरणों में सिर झुका देते हैं। दुर्योधन उसी क्षण उन्हें राजा बना "
  "देते हैं, और ऐसी निष्ठा खरीद लेते हैं जिसे कोई तर्क नहीं तोड़ पाएगा।"),

 ("mbh-lac-house", 1, "Adi Parva", "आदि पर्व",
  "The House of Lac", "लाक्षागृह",
  "A palace built of lac and resin is prepared for the Pandavas at Varanavata, "
  "and Vidura warns them in words only they can read.",
  "वारणावत में पांडवों के लिए लाख और राल का भवन बनाया जाता है, और विदुर उन्हें "
  "ऐसी भाषा में चेताते हैं जिसे केवल वे समझ सकें।",
  "The Mahabharata, Book 1: Adi Parva: Section CXLVII",
  [("yudhishthira", "protagonist"), ("vidura", "protagonist"),
   ("duryodhana", "antagonist")],
  "The Pandavas touch the feet of Bhishma and Dhritarashtra before they leave, "
  "in great sorrow, and go anyway. This is the first time the family tries to "
  "kill them, and the first time everyone senior enough to stop it decides not "
  "to. The pattern set here runs the length of the epic.",
  "जाने से पूर्व पांडव अत्यंत शोक के साथ भीष्म और धृतराष्ट्र के चरण स्पर्श करते "
  "हैं, और फिर भी चले जाते हैं। यह पहली बार है जब कुल उनकी हत्या का प्रयास करता "
  "है, और पहली बार जब रोकने में समर्थ हर वृद्ध चुप रह जाता है। यहीं बना यह "
  "क्रम समूचे महाकाव्य तक चलता है।"),

 ("mbh-khandava", 1, "Adi Parva", "आदि पर्व",
  "Indraprastha and the Khandava", "इंद्रप्रस्थ और खांडव",
  "Given half a kingdom, the Pandavas build Indraprastha -- and then burn the "
  "Khandava forest to clear the ground.",
  "आधा राज्य पाकर पांडव इंद्रप्रस्थ बसाते हैं — और भूमि के लिए खांडव वन जला "
  "देते हैं।",
  "The Mahabharata, Book 1: Adi Parva: Section CCXXIV",
  [("arjuna", "protagonist"), ("krishna", "protagonist"),
   ("yudhishthira", "protagonist")],
  "The text says the subjects lived most happily, depending upon Yudhishthira "
  "the just -- and in the same breath the forest and everything living in it "
  "is given to the fire. The Mahabharata does not present this as a wrong to "
  "be answered later. It simply records both, and leaves the reader holding "
  "them together.",
  "ग्रंथ कहता है कि प्रजा युधिष्ठिर के आश्रय में परम सुखी थी — और उसी साँस में "
  "वन तथा उसमें बसा सब कुछ अग्नि को सौंप दिया जाता है। महाभारत इसे बाद में "
  "चुकाए जाने वाले अपराध की तरह नहीं रखता। वह दोनों बातें दर्ज करता है और "
  "पाठक पर छोड़ देता है।"),

 ("mbh-shishupala", 2, "Sabha Parva", "सभा पर्व",
  "Shishupala Counts to a Hundred", "शिशुपाल के सौ अपराध",
  "At the Rajasuya, Shishupala objects to Krishna being honoured first and "
  "insults him until a promised count runs out.",
  "राजसूय में शिशुपाल कृष्ण के प्रथम पूजन का विरोध करते हैं और तब तक अपमान करते "
  "हैं जब तक दिया हुआ वचन समाप्त नहीं हो जाता।",
  "The Mahabharata, Book 2: Sabha Parva: Section XLII",
  [("krishna", "protagonist"), ("bhishma", "witness")],
  "Bhishma explains that Shishupala was born with three eyes and four arms and "
  "screamed like an ass, and that his mother was promised her son's offences "
  "would be forgiven a hundred times. The scene is built so that the killing, "
  "when it comes, is the discharge of a promise rather than an act of temper.",
  "भीष्म बताते हैं कि शिशुपाल तीन नेत्र और चार भुजाओं सहित उत्पन्न हुए और गधे "
  "के समान चीखे, और उनकी माता को वचन मिला था कि पुत्र के सौ अपराध क्षमा किए "
  "जाएँगे। दृश्य ऐसा रचा गया है कि वध क्रोध नहीं, वचन का पालन बने।"),

 ("mbh-kirmira", 3, "Vana Parva", "वन पर्व",
  "Kirmira in the Dark", "अंधकार में किर्मीर",
  "On the first night of exile the forest itself objects: a rakshasa blocks "
  "the road, and Bhima fights him in the dark.",
  "वनवास की प्रथम रात्रि में वन स्वयं रोकता है: एक राक्षस मार्ग रोक लेता है, "
  "और भीम अंधकार में उससे भिड़ते हैं।",
  "The Mahabharata, Book 3: Vana Parva: Section XI",
  [("bhima", "protagonist"), ("vidura", "witness")],
  "Vidura tells the story to a blind king who asked to hear it. That framing "
  "is the point of the chapter: Dhritarashtra keeps asking for news of the "
  "nephews he allowed to be driven out, and keeps being told exactly what his "
  "silence cost them.",
  "विदुर यह कथा उस अंधे राजा को सुनाते हैं जिसने स्वयं पूछा था। यही इस अध्याय "
  "का मर्म है: धृतराष्ट्र बार-बार उन भतीजों का समाचार माँगते हैं जिन्हें "
  "निकाले जाने पर वे मौन रहे, और बार-बार सुनते हैं कि उस मौन का मूल्य क्या रहा।"),

 ("mbh-virata", 4, "Virata Parva", "विराट पर्व",
  "A Year in Disguise", "अज्ञातवास",
  "The thirteenth year must be spent unrecognised. Five kings and a queen take "
  "service in Virata's household as cook, dancer, groom and maid.",
  "तेरहवाँ वर्ष अज्ञात बीतना है। पाँच राजा और एक रानी विराट के भवन में रसोइया, "
  "नर्तक, अश्वपाल और सैरंध्री बनकर रहते हैं।",
  "The Mahabharata, Book 4: Virata Parva: Section XIV",
  [("draupadi", "protagonist"), ("yudhishthira", "protagonist"),
   ("bhima", "protagonist")],
  "Ganguli notes that Draupadi, herself deserving to be waited upon, passed "
  "her days in extreme misery attending on another woman. The Virata Parva is "
  "the quietest book in the epic and the most humiliating, and the war that "
  "follows is easier to understand for having read it.",
  "गांगुली लिखते हैं कि द्रौपदी, जो स्वयं सेवा के योग्य थीं, दूसरी स्त्री की "
  "परिचर्या करते हुए अत्यंत कष्ट में दिन बिताती रहीं। विराट पर्व महाकाव्य का "
  "सबसे शांत और सबसे अपमानजनक भाग है — इसे पढ़ने के बाद आगे का युद्ध अधिक "
  "समझ आता है।"),

 ("mbh-kichaka", 4, "Virata Parva", "विराट पर्व",
  "Kichaka", "कीचक वध",
  "The queen's brother pursues Draupadi through the palace. She has no rank to "
  "appeal to and no husband who can act openly.",
  "रानी का भाई द्रौपदी का पीछा करता है। न उनके पास पद है जिससे न्याय माँगें, न "
  "कोई पति जो खुलकर कुछ कर सके।",
  "The Mahabharata, Book 4: Virata Parva: Section XXII",
  [("draupadi", "protagonist"), ("bhima", "protagonist"),
   ("kichaka", "antagonist")],
  "Kichaka's relatives find him mangled beyond recognition and wail around the "
  "body. The killing has to be done in the dark and disowned afterwards, "
  "because the year of concealment is not finished -- which is exactly what "
  "makes the episode unbearable rather than triumphant.",
  "कीचक के स्वजन उसे पहचान से परे विकृत पाकर शव के चारों ओर विलाप करते हैं। "
  "वध अंधकार में करना पड़ता है और बाद में अस्वीकार भी, क्योंकि अज्ञातवास शेष "
  "है — इसी से यह प्रसंग विजय नहीं, असह्य बनता है।"),

 ("mbh-lake", 9, "Shalya Parva", "शल्य पर्व",
  "Duryodhana at the Lake", "सरोवर में दुर्योधन",
  "With his army gone, Duryodhana hides in the water. The Pandavas find him "
  "and talk him out -- by telling him what staying in would make him.",
  "सेना नष्ट हो जाने पर दुर्योधन जल में छिप जाते हैं। पांडव उन्हें ढूँढ लेते "
  "हैं और बाहर बुला लेते हैं — यह कहकर कि भीतर रहना उन्हें क्या बना देगा।",
  "The Mahabharata, Book 9: Shalya Parva: Section 32",
  [("duryodhana", "protagonist"), ("yudhishthira", "antagonist")],
  "Dhritarashtra asks how his son, who had never in his life listened to "
  "admonition, behaved when taunted by his enemies. The answer is that he came "
  "out. Everything Duryodhana is -- the pride, the courage, the refusal to be "
  "thought less of -- is what finally gets him killed.",
  "धृतराष्ट्र पूछते हैं कि उनका पुत्र, जिसने जीवन में कभी उपदेश नहीं सुना, "
  "शत्रुओं के व्यंग्य पर कैसा आचरण करे। उत्तर यह है कि वे बाहर आ गए। दुर्योधन "
  "का समूचा स्वभाव — गर्व, साहस, हीन कहलाने से इनकार — अंततः उन्हीं का वध "
  "करता है।"),

 ("mbh-mausala", 16, "Mausala Parva", "मौसल पर्व",
  "The End of the Yadavas", "यादवों का अंत",
  "Thirty-six years after the war, Krishna's own people destroy each other in "
  "a drunken quarrel with reeds that turn to iron.",
  "युद्ध के छत्तीस वर्ष बाद कृष्ण के अपने ही कुल के लोग मद्य के कलह में उन "
  "सरकंडों से एक-दूसरे का नाश कर लेते हैं जो लोहा बन जाते हैं।",
  "The Mahabharata, Book 16: Mausala Parva: Section 4",
  [("krishna", "protagonist"), ("balarama", "protagonist")],
  "Daruka and Krishna go looking for Balarama and find him sitting alone "
  "against a tree. The Mahabharata gives its most powerful figure an ending "
  "with no battle in it at all -- his city drowned, his clan gone by its own "
  "hand, and a hunter's stray arrow waiting.",
  "दारुक और कृष्ण बलराम को खोजते हुए उन्हें एक वृक्ष के सहारे अकेले बैठा पाते "
  "हैं। महाभारत अपने सबसे समर्थ पात्र को ऐसा अंत देता है जिसमें युद्ध है ही "
  "नहीं — नगरी डूबी, कुल स्वयं अपने हाथों नष्ट, और प्रतीक्षा में एक व्याध का "
  "अनजाना बाण।"),
]

LONG = {
 "mbh-bhishma-vow": (
  "Shantanu wants to marry a fisherman's daughter whose father will not agree "
  "unless her sons inherit. Bhishma settles it by giving up both the throne "
  "and marriage, permanently. The vow is kept perfectly and for far longer "
  "than the situation that made sense of it, which is the tragedy the epic is "
  "really about.",
  "शांतनु एक धीवर-कन्या से विवाह चाहते हैं, पर उसके पिता की शर्त है कि सिंहासन "
  "उसी के पुत्रों को मिले। भीष्म सिंहासन और गृहस्थी दोनों का सदा के लिए त्याग "
  "कर यह सुलझा देते हैं। यह प्रतिज्ञा पूर्णतः निभाई जाती है — और उस परिस्थिति "
  "से कहीं आगे तक, जिसने उसे अर्थ दिया था।"),
 "mbh-births": (
  "Two sets of cousins grow up in one house: five sons of Pandu raised away "
  "from the court, and a hundred sons of the blind king who was passed over "
  "for the throne. Nothing in the war that follows is not already present in "
  "that arrangement.",
  "एक ही घर में दो कुल पलते हैं: पांडु के पाँच पुत्र, जो सभा से दूर पले, और "
  "उस अंधे राजा के सौ पुत्र जिसे सिंहासन नहीं मिला। आगे के युद्ध में ऐसा कुछ "
  "नहीं जो इस व्यवस्था में पहले से मौजूद न हो।"),
 "mbh-drona": (
  "Drona arrives poor and is made master of arms to a hundred princes. He is "
  "the finest teacher in the epic and openly partial, and the favouritism he "
  "never hides shapes almost every rivalry that follows.",
  "द्रोण निर्धन आते हैं और सौ राजकुमारों के शस्त्राचार्य बनाए जाते हैं। वे "
  "महाकाव्य के श्रेष्ठतम गुरु हैं और खुलकर पक्षपाती भी — यही पक्षपात आगे की "
  "लगभग हर प्रतिद्वंद्विता को आकार देता है।"),
 "mbh-draupadi-swayamvara": (
  "Arjuna wins Draupadi at the archery contest, and Kunti -- speaking before "
  "she looks -- tells her sons to share what they have brought. The five "
  "brothers hold to a word said by accident, and the marriage that follows "
  "binds them together for the rest of the story.",
  "अर्जुन धनुर्विद्या की परीक्षा में द्रौपदी को जीतते हैं, और कुंती — बिना देखे "
  "कह देती हैं कि जो लाए हो उसे बाँट लो। पाँचों भाई अनजाने में कहे उस वचन को "
  "निभाते हैं, और वह विवाह उन्हें शेष कथा भर एक सूत्र में बाँधे रखता है।"),
 "mbh-dice": (
  "Yudhishthira accepts a game he cannot win and stakes his brothers, himself "
  "and finally his wife. The epic gives its most truthful man the most "
  "ruinous weakness, and never once suggests the two are unrelated.",
  "युधिष्ठिर ऐसा द्यूत स्वीकार करते हैं जिसे वे जीत नहीं सकते, और भाइयों, "
  "स्वयं तथा अंत में पत्नी को दाँव पर लगा देते हैं। महाकाव्य अपने सबसे "
  "सत्यनिष्ठ पात्र को सबसे विनाशकारी दुर्बलता देता है।"),
 "mbh-draupadi-sabha": (
  "Draupadi asks whether a man who has already lost himself had anything left "
  "to wager. Bhishma calls the question of dharma subtle and declines to rule. "
  "The Mahabharata treats that unanswered question as the hinge of everything "
  "that follows.",
  "द्रौपदी पूछती हैं कि जो स्वयं को हार चुका हो, उसके पास दाँव पर लगाने को क्या "
  "शेष था। भीष्म धर्म को सूक्ष्म कहकर निर्णय टाल देते हैं। महाभारत उस अनुत्तरित "
  "प्रश्न को आगे की हर घटना की धुरी मानता है।"),
 "mbh-exile": (
  "Twelve years in the forest and a thirteenth unrecognised, on terms designed "
  "to be just survivable. The exile is where the Mahabharata does most of its "
  "thinking, and where the brothers meet the sages whose stories fill the "
  "longest book in the epic.",
  "बारह वर्ष वन में और तेरहवाँ अज्ञात — ऐसी शर्तों पर जो बस निभाई जा सकें। "
  "वनवास वही स्थान है जहाँ महाभारत सर्वाधिक चिंतन करता है, और जहाँ भाई उन "
  "ऋषियों से मिलते हैं जिनकी कथाएँ ग्रंथ के सबसे बड़े पर्व को भरती हैं।"),
 "mbh-pashupata": (
  "Arjuna goes alone into the mountains for weapons and fights a hunter who "
  "turns out to be Shiva. He is given the Pashupata, which the text is careful "
  "to say must never be used against an ordinary opponent.",
  "अर्जुन अस्त्रों के लिए अकेले पर्वत जाते हैं और एक किरात से युद्ध करते हैं, "
  "जो शिव निकलते हैं। उन्हें पाशुपत मिलता है — और ग्रंथ सावधानी से कहता है कि "
  "इसे साधारण शत्रु पर कभी न चलाया जाए।"),
 "mbh-yaksha": (
  "Four brothers drink from a forbidden lake and fall. Yudhishthira answers "
  "the yaksha's questions and is offered one brother back; he asks for Nakula, "
  "so that each of his father's wives keeps a living son.",
  "चार भाई निषिद्ध सरोवर का जल पीकर गिर पड़ते हैं। युधिष्ठिर यक्ष के प्रश्नों "
  "का उत्तर देकर एक भाई माँगने को कहे जाते हैं; वे नकुल को माँगते हैं, ताकि "
  "पिता की दोनों पत्नियों का एक-एक पुत्र जीवित रहे।"),
 "mbh-peace-fails": (
  "Krishna goes to Hastinapura to ask for five villages and is refused. The "
  "embassy is written so that everyone present can see the war coming and "
  "nobody with the standing to stop it does.",
  "कृष्ण पाँच गाँव माँगने हस्तिनापुर जाते हैं और अस्वीकार कर दिए जाते हैं। यह "
  "दूतकर्म ऐसे लिखा गया है कि उपस्थित सब युद्ध आता देख रहे हैं, और रोकने में "
  "समर्थ कोई उसे रोकता नहीं।"),
 "mbh-gita": (
  "Between the armies Arjuna sets down his bow. What follows is not a "
  "command to fight but an argument about acting without clinging to the "
  "fruit of the act -- and it ends by handing the choice back to him.",
  "दोनों सेनाओं के बीच अर्जुन धनुष रख देते हैं। आगे जो आता है वह युद्ध का आदेश "
  "नहीं, फल की आसक्ति छोड़कर कर्म करने का विवेचन है — और अंत में निर्णय उन्हीं "
  "को लौटा दिया जाता है।"),
 "mbh-bhishma-falls": (
  "With Shikhandi before him Bhishma sets down his bow and takes the arrows. "
  "He does not die: he waits on that bed for the sun to turn north, and spends "
  "the interval teaching.",
  "शिखंडी को सामने देखकर भीष्म धनुष रख देते हैं और बाण सह लेते हैं। वे मरते "
  "नहीं: शरशय्या पर सूर्य के उत्तरायण होने की प्रतीक्षा करते हैं, और उस बीच "
  "उपदेश देते हैं।"),
 "mbh-abhimanyu": (
  "Abhimanyu knows how to enter the wheel formation and not how to leave it. "
  "He is surrounded by men who each break the rules of engagement in turn, and "
  "the war stops pretending to have any after this.",
  "अभिमन्यु चक्रव्यूह में प्रवेश जानते हैं, निकलना नहीं। उन्हें घेरकर एक-एक "
  "करके सब युद्ध-नियम तोड़ते हैं, और इसके बाद युद्ध नियमों का दिखावा भी छोड़ "
  "देता है।"),
 "mbh-karna-falls": (
  "His chariot wheel sinks into the earth and the mantras he was taught desert "
  "him, exactly as he was warned they would. He asks for the pause the rules "
  "allow and does not get it.",
  "उनके रथ का पहिया धरती में धँस जाता है और सीखे हुए मंत्र विस्मृत हो जाते हैं "
  "— ठीक वैसे ही जैसे चेतावनी दी गई थी। वे नियमानुसार क्षण भर की छूट माँगते "
  "हैं और नहीं पाते।"),
 "mbh-duryodhana": (
  "The last duel is fought with maces and decided by a blow below the waist, "
  "which is against the rule both men were taught. Balarama walks out in "
  "disgust; Krishna does not deny what was done.",
  "अंतिम द्वंद्व गदा से होता है और कटि के नीचे प्रहार से तय होता है — जो नियम "
  "दोनों ने सीखा था, उसी के विरुद्ध। बलराम क्षुब्ध होकर चले जाते हैं; कृष्ण "
  "किए गए का खंडन नहीं करते।"),
 "mbh-night-raid": (
  "Ashwatthama enters the sleeping camp at night and kills what is left. It is "
  "the darkest passage in the epic, and the victory it completes is worth "
  "nothing to anyone by morning.",
  "अश्वत्थामा रात्रि में सोए शिविर में घुसकर शेष का संहार करते हैं। यह "
  "महाकाव्य का सबसे अंधकारमय प्रसंग है, और जिस विजय को यह पूरा करता है वह "
  "प्रातः तक किसी के काम की नहीं रहती।"),
 "mbh-gandhari": (
  "Gandhari walks the field and names her dead, one by one, to the man who "
  "won. The Stri Parva gives the whole war's cost to the women who were never "
  "asked about it.",
  "गांधारी रणभूमि में चलकर विजेता के सामने अपने मृतकों का एक-एक नाम लेती हैं। "
  "स्त्री पर्व समूचे युद्ध का मूल्य उन स्त्रियों को सौंप देता है जिनसे कभी "
  "पूछा ही नहीं गया।"),
 "mbh-shanti": (
  "From the bed of arrows Bhishma answers questions about kingship, duty and "
  "release for as long as it takes. The longest teaching in the epic is "
  "delivered by a dying man to the nephew who defeated him.",
  "शरशय्या से भीष्म राजधर्म, कर्तव्य और मोक्ष के प्रश्नों का उत्तर तब तक देते "
  "हैं जब तक आवश्यक हो। महाकाव्य का सबसे लंबा उपदेश एक मरणासन्न पुरुष उस भतीजे "
  "को देता है जिसने उसे हराया।"),
 "mbh-final-journey": (
  "The brothers walk north to die, and fall one by one along the road. Only "
  "Yudhishthira and a dog reach the end, and he refuses heaven rather than "
  "abandon the dog.",
  "भाई उत्तर की ओर मृत्यु के लिए चलते हैं और मार्ग में एक-एक कर गिरते जाते "
  "हैं। अंत तक केवल युधिष्ठिर और एक कुत्ता पहुँचते हैं, और वे कुत्ते को छोड़ने "
  "के बजाय स्वर्ग ठुकरा देते हैं।"),
 "mbh-svargarohana": (
  "Yudhishthira is shown his cousins in heaven and his brothers in torment, "
  "and refuses to stay. The epic ends by testing its most righteous character "
  "one final time, on whether he will choose comfort over company.",
  "युधिष्ठिर को स्वर्ग में भाई-बंधु और नरक में अपने भाई दिखाए जाते हैं, और वे "
  "रुकने से इनकार कर देते हैं। महाकाव्य अपने सर्वाधिक धर्मनिष्ठ पात्र की "
  "अंतिम परीक्षा इसी पर लेता है कि वह सुख चुनेगा या साथ।"),
}

# Narrative order. New scenes sit where they belong rather than at the end, so
# everything is renumbered. Kept inside 1..99: the eighteen war days occupy
# 101..118 and a collision would drop battle days into the main path.
ORDER = [
 "mbh-bhishma-vow", "mbh-births", "mbh-drona", "mbh-karna-tournament",
 "mbh-lac-house", "mbh-draupadi-swayamvara", "mbh-khandava",
 "mbh-shishupala", "mbh-dice", "mbh-draupadi-sabha",
 "mbh-exile", "mbh-kirmira", "mbh-pashupata", "mbh-yaksha",
 "mbh-virata", "mbh-kichaka",
 "mbh-peace-fails", "mbh-gita", "mbh-bhishma-falls", "mbh-abhimanyu",
 "mbh-karna-falls", "mbh-lake", "mbh-duryodhana", "mbh-night-raid",
 "mbh-gandhari", "mbh-shanti", "mbh-mausala",
 "mbh-final-journey", "mbh-svargarohana",
]

new_rows = []
for (slug, bno, ben, bhi, ten, thi, sden, sdhi, ref, cast, len_, lhi) in NEW:
    new_rows.append({
        "slug": slug, "epic": "mahabharata", "recension": "critical_ed",
        "book_label": {"en": ben, "hi": bhi}, "book_no": bno,
        "sequence_no": ORDER.index(slug) + 1,
        "title": {"en": ten, "hi": thi},
        "short_description": {"en": sden, "hi": sdhi},
        "long_description": {"en": len_, "hi": lhi},
        "tags": ["mahabharata"],
        "cast": [{"entity_slug": c, "role": r} for c, r in cast],
        "sources": [{"source_slug": G, "source_chapter_or_section": ref,
                     "is_primary": True, "last_verified_at": D,
                     "verified_by": "TS"}],
        "verification": {"status_en": "verified", "status_hi": "verified",
                         "by": "TS", "at": D, "notes": ""},
    })

# Renumber and enrich the existing scenes in place.
src = ROOT / 'content' / 'data' / 'narrative' / 'epics.jsonl'
rows = [json.loads(l) for l in src.read_text(encoding='utf-8').splitlines()
        if l.strip()]
enriched = renumbered = 0
for o in rows:
    if o.get('epic') != 'mahabharata':
        continue
    slug = o['slug']
    if slug in ORDER:
        want = ORDER.index(slug) + 1
        if o.get('sequence_no') != want:
            o['sequence_no'] = want
            renumbered += 1
    if slug in LONG and 'long_description' not in o:
        en, hi = LONG[slug]
        o['long_description'] = {"en": en, "hi": hi}
        enriched += 1

with src.open('w', encoding='utf-8', newline='\n') as fh:
    for o in rows:
        fh.write(json.dumps(o, ensure_ascii=False, sort_keys=True) + "\n")

out = ROOT / 'content' / 'data' / 'narrative' / 'mahabharata_more.jsonl'
with out.open('w', encoding='utf-8', newline='\n') as fh:
    for r in new_rows:
        fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")

print(f"new scenes      {len(new_rows)}")
print(f"renumbered      {renumbered}")
print(f"gained detail   {enriched}")
print(f"total main path {len(ORDER)}")
