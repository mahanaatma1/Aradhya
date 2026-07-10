import 'ashtakoot.dart';

/// All human-readable text for Kundli Milan. Our own writing.

// ---- Cosmic-profile descriptors ----

const _milanMoonSignDescEn = [
  'bold and always first — jumps in early and feels things fast',
  'steady and warm — loves comfort and stays loyal',
  'curious and quick — a mind that likes to keep busy and play',
  'soft and caring — feels things deeply and truly',
  'warm and big-hearted — loves to shine and be seen',
  'careful and giving — shows love by doing things for you',
  'gentle and fair — wants everyone to get along',
  'deep and loyal — feelings that go all the way down',
  'free and hopeful — always looking for something more',
  'grounded and steady — builds a love that lasts',
  'independent and kind — loves openly and gives everyone space',
  'soft and dreamy — full of care for everyone',
];
const _milanMoonSignDescHi = [
  'हिम्मती और सबसे आगे — पहले कदम उठाता है, भावनाएँ तेज़ी से महसूस करता है',
  'शांत और गर्मजोश — आराम पसंद और रिश्ते में वफ़ादार',
  'जिज्ञासु और फुर्तीला — एक ऐसा मन जो हमेशा कुछ नया करना चाहता है',
  'नरम और ख्याल रखने वाला — भावनाएँ गहरी और सच्ची',
  'गर्मजोश और बड़े दिल वाला — चमकना और सराहा जाना पसंद',
  'ध्यान रखने वाला और देने वाला — काम करके प्यार जताता है',
  'सौम्य और इंसाफ़पसंद — सबसे ज़्यादा यही चाहता है कि सब मिल-जुलकर रहें',
  'गहरा और वफ़ादार — भावनाएँ मन की तह तक जाती हैं',
  'आज़ाद और उम्मीद से भरा — हमेशा कुछ और खोजता रहता है',
  'ज़मीन से जुड़ा और टिकाऊ — ऐसा प्यार जो लंबा चलता है',
  'अपने पैरों पर खड़ा और दयालु — खुलकर प्यार करता है और सबको जगह देता है',
  'नरम और सपने देखने वाला — सबके लिए दिल में करुणा',
];
String milanMoonSignDesc(int i, bool hi) =>
    (hi ? _milanMoonSignDescHi : _milanMoonSignDescEn)[i];

const _milanNakshatraDeityEn = [
  'Ashwini Kumaras', 'Yama', 'Agni', 'Brahma', 'Soma (Chandra)', 'Rudra',
  'Aditi', 'Brihaspati', 'Nagas (Serpents)', 'Pitrs (Ancestors)', 'Bhaga',
  'Aryaman', 'Savitr (Sun)', 'Vishvakarma', 'Vayu', 'Indra-Agni', 'Mitra',
  'Indra', 'Nirriti', 'Apas (Waters)', 'Vishvedevas', 'Vishnu', 'Vasus',
  'Varuna', 'Aja Ekapada', 'Ahir Budhnya', 'Pushan'
];
const _milanNakshatraDeityHi = [
  'अश्विनी कुमार', 'यम', 'अग्नि', 'ब्रह्मा', 'सोम (चंद्र)', 'रुद्र',
  'अदिति', 'बृहस्पति', 'नाग', 'पितर', 'भग',
  'अर्यमा', 'सवितृ (सूर्य)', 'विश्वकर्मा', 'वायु', 'इंद्र-अग्नि', 'मित्र',
  'इंद्र', 'निर्ऋति', 'आप (जल)', 'विश्वेदेव', 'विष्णु', 'वसु',
  'वरुण', 'अज एकपाद', 'अहिर्बुध्न्य', 'पूषा'
];
String milanNakshatraDeity(int i, bool hi) =>
    (hi ? _milanNakshatraDeityHi : _milanNakshatraDeityEn)[i];

const _milanYoniNameEn = [
  'Horse', 'Elephant', 'Sheep', 'Serpent', 'Dog', 'Cat', 'Rat', 'Cow',
  'Buffalo', 'Tiger', 'Deer', 'Monkey', 'Mongoose', 'Lion'
];
const _milanYoniNameHi = [
  'अश्व', 'गज', 'मेष', 'सर्प', 'श्वान', 'मार्जार', 'मूषक', 'गौ',
  'महिष', 'व्याघ्र', 'मृग', 'वानर', 'नकुल', 'सिंह'
];
String milanYoniName(int i, bool hi) =>
    (hi ? _milanYoniNameHi : _milanYoniNameEn)[i];

const _milanYoniDescEn = [
  'lively, full of energy, and loves to be free',
  'calm, strong, and stands its ground',
  'gentle, easy to work with, and mild',
  'deep, private, and quietly magnetic',
  'loyal, protective, and devoted',
  'independent, sensitive, and clever',
  'quick, smart, and good at finding a way',
  'calm, caring, and always giving',
  'tough, patient, and hardworking',
  'bold, ambitious, and likes to take charge',
  'graceful, gentle, and refined',
  'playful, restless, and full of ideas',
  'alert, brave, and sharp',
  'proud, commanding, and likes to lead',
];
const _milanYoniDescHi = [
  'जोशीला, ऊर्जा से भरा और आज़ादी पसंद',
  'शांत, मज़बूत और अपनी बात पर अटल',
  'सौम्य, साथ निभाने वाला और नरम',
  'गहरा, अपनी बात मन में रखने वाला और चुपचाप आकर्षक',
  'वफ़ादार, रक्षा करने वाला और समर्पित',
  'अपने पैरों पर खड़ा, संवेदनशील और होशियार',
  'फुर्तीला, समझदार और हर हाल में रास्ता निकालने वाला',
  'शांत, ख्याल रखने वाला और हमेशा देने वाला',
  'सख्त-जान, सब्र वाला और मेहनती',
  'दबंग, आगे बढ़ने वाला और कमान संभालने वाला',
  'सुंदर, कोमल और सलीकेदार',
  'खिलंदड़ा, बेचैन और नए-नए विचारों वाला',
  'चौकन्ना, बहादुर और तेज़',
  'स्वाभिमानी, रौबदार और आगे रहकर नेतृत्व करने वाला',
];
String milanYoniDesc(int i, bool hi) =>
    (hi ? _milanYoniDescHi : _milanYoniDescEn)[i];

// rank 1..4 → index 0..3
const _varnaNamesEn = ['Shudra', 'Vaishya', 'Kshatriya', 'Brahmin'];
const _varnaNamesHi = ['शूद्र', 'वैश्य', 'क्षत्रिय', 'ब्राह्मण'];
const _varnaDescsEn = [
  'likes to help and stays grounded — quietly gets things done with steady hands',
  'practical and good at business — cares about worth, resources, and keeping things running',
  'protective and always ready to act — born to lead and to stand guard',
  'thoughtful and stands by principles — drawn to wisdom and the inner life',
];
const _varnaDescsHi = [
  'मदद करने वाला और ज़मीन से जुड़ा — शांति से हर काम संभाल लेता है',
  'व्यावहारिक और कारोबार में तेज़ — मोल-भाव, साधन और व्यवस्था को अहमियत देने वाला',
  'रक्षा करने वाला और हमेशा तैयार — नेतृत्व करने और हिफ़ाज़त करने के लिए बना',
  'सोच-समझकर चलने वाला और उसूलों पर अडिग — ज्ञान और अंदर की दुनिया की ओर झुका हुआ',
];
String milanVarnaName(int rank, bool hi) =>
    (hi ? _varnaNamesHi : _varnaNamesEn)[rank - 1];
String milanVarnaDesc(int rank, bool hi) =>
    (hi ? _varnaDescsHi : _varnaDescsEn)[rank - 1];

const _milanGanaNameEn = ['Deva', 'Manushya', 'Rakshasa'];
const _milanGanaNameHi = ['देव', 'मनुष्य', 'राक्षस'];
const _milanGanaDescEn = [
  'a gentle, divine nature — soft, refined, and idealistic, most at home with kindness and the inner life',
  'a human nature — balanced and easy with people, a mix of high ideals and down-to-earth needs',
  'a strong, fiery nature — firm-willed, full of passion, and not afraid of a fight',
];
const _milanGanaDescHi = [
  'दैवी स्वभाव — सौम्य, सलीकेदार और आदर्शों वाला, दया और अंदर की दुनिया में सुकून पाता है',
  'मानवीय स्वभाव — संतुलित और लोगों से घुलने-मिलने वाला, ऊँचे आदर्शों और रोज़मर्रा की ज़रूरतों का मेल',
  'तीव्र स्वभाव — पक्के इरादों वाला, जज़्बे से भरा और टकराव से न डरने वाला',
];
String milanGanaName(int i, bool hi) =>
    (hi ? _milanGanaNameHi : _milanGanaNameEn)[i];
String milanGanaDesc(int i, bool hi) =>
    (hi ? _milanGanaDescHi : _milanGanaDescEn)[i];

const _milanNadiNameEn = ['Aadi (Vata)', 'Madhya (Pitta)', 'Antya (Kapha)'];
const _milanNadiNameHi = ['आदि (वात)', 'मध्य (पित्त)', 'अंत्य (कफ)'];
const _milanNadiDescEn = [
  'airy, always on the move, and quick — restless energy and a lively mind',
  'fiery, focused, and always pushing for change',
  'earthy, steady, and loves comfort',
];
const _milanNadiDescHi = [
  'हवा जैसा, चंचल और तेज़ — बेचैन ऊर्जा और चुस्त मन',
  'आग जैसा, एकाग्र और हर वक़्त बदलाव चाहने वाला',
  'ज़मीन जैसा स्थिर, सब्र वाला और आराम पसंद',
];
String milanNadiName(int i, bool hi) =>
    (hi ? _milanNadiNameHi : _milanNadiNameEn)[i];
String milanNadiDesc(int i, bool hi) =>
    (hi ? _milanNadiDescHi : _milanNadiDescEn)[i];

// ---- Koot display names ----

const _milanKootNameHi = {
  'varna': 'वर्ण',
  'vashya': 'वश्य',
  'tara': 'तारा',
  'yoni': 'योनि',
  'maitri': 'ग्रह मैत्री',
  'gana': 'गण',
  'bhakoot': 'भकूट',
  'nadi': 'नाड़ी',
};
String milanKootName(String key, String enName, bool hi) =>
    hi ? (_milanKootNameHi[key] ?? enName) : enName;

// ---- Per-koot one-liners (band: 0 none, 1 partial, 2 good, 3 full) ----

const _kootTextEn = <String, List<String>>{
  'varna': [
    'Your inner natures are a bit different; respecting how each of you is wired will help a lot.',
    'Your inner natures are a bit different; respecting how each of you is wired will help a lot.',
    'Your inner natures line up well — no tug-of-war deep down.',
    'Your inner natures line up well — no tug-of-war deep down.',
  ],
  'vashya': [
    'One of you tends to lead more — a little care keeps the say equal between you.',
    'One of you may pull a bit harder; staying aware keeps things balanced.',
    'An easy give-and-take, with one of you gently taking the lead now and then.',
    'You naturally draw toward each other — the pull between you is easy and mutual.',
  ],
  'tara': [
    'Your birth stars don\'t always help the flow — a little patience through the rough patches goes a long way.',
    'Your birth stars give mixed signals; the bond will have its ups and downs.',
    'Your birth stars give mixed signals; the bond will have its ups and downs.',
    'Your birth stars back each other up — luck seems to smile on this bond.',
  ],
  'yoni': [
    'Your gut instincts pull different ways — patience and respect for each other\'s rhythm matter here.',
    'Your instincts get along okay — it works with a little care.',
    'Your instincts get along okay — it works with a little care.',
    'Your instincts fit beautifully — physical closeness comes easily and naturally.',
  ],
  'maitri': [
    'Your minds run on different tracks; you may often read the same thing in different ways.',
    'Your minds meet well enough, with the odd mix-up along the way.',
    'Your minds mostly agree — talking things through comes easily.',
    'Your minds click like old friends — you get each other and back each other up.',
  ],
  'gana': [
    'Your temperaments pull sharply against each other — being clear and respecting the differences will matter.',
    'Your temperaments are different — being clear and respecting the differences will matter.',
    'Your natures get along, with just a few small differences to smooth over.',
    'Your temperaments match up well — your natures meet easily.',
  ],
  'bhakoot': [
    'Bhakoot Dosha is present — family harmony and shared money need some conscious care.',
    'Bhakoot Dosha is present — family harmony and shared money need some conscious care.',
    'No Bhakoot Dosha — family life and shared resources should flow smoothly.',
    'No Bhakoot Dosha — family life and shared resources should flow smoothly.',
  ],
  'nadi': [
    'Nadi Dosha is present — this is the heaviest check; health and children need attention and a remedy.',
    'Nadi Dosha is present — this is the heaviest check; health and children need attention and a remedy.',
    'No Nadi Dosha — the single most important check passes cleanly.',
    'No Nadi Dosha — the single most important check passes cleanly.',
  ],
};

const _kootTextHi = <String, List<String>>{
  'varna': [
    'आप दोनों का अंदरूनी स्वभाव थोड़ा अलग है; एक-दूसरे के मिज़ाज का आदर करेंगे तो बात बहुत आसान हो जाएगी।',
    'आप दोनों का अंदरूनी स्वभाव थोड़ा अलग है; एक-दूसरे के मिज़ाज का आदर करेंगे तो बात बहुत आसान हो जाएगी।',
    'आप दोनों का अंदरूनी स्वभाव अच्छे से मिलता है — मन के भीतर कोई खींचतान नहीं।',
    'आप दोनों का अंदरूनी स्वभाव अच्छे से मिलता है — मन के भीतर कोई खींचतान नहीं।',
  ],
  'vashya': [
    'आप में से एक थोड़ा ज़्यादा आगे रहता है — थोड़ा ध्यान रखेंगे तो दोनों की बराबर चलेगी।',
    'आप में से एक थोड़ा ज़्यादा हावी हो सकता है; ध्यान बनाए रखेंगे तो संतुलन बना रहेगा।',
    'आपस में सहज लेन-देन, जहाँ कभी-कभी एक जना प्यार से आगे रहता है।',
    'आप दोनों अपने-आप एक-दूसरे की ओर खिंचते हैं — यह खिंचाव सहज है और दोनों तरफ़ से है।',
  ],
  'tara': [
    'आपके जन्म नक्षत्र हमेशा साथ नहीं देते — मुश्किल दौर में थोड़ा सब्र बहुत काम आता है।',
    'आपके जन्म नक्षत्र मिले-जुले संकेत देते हैं; रिश्ते में उतार-चढ़ाव आते रहेंगे।',
    'आपके जन्म नक्षत्र मिले-जुले संकेत देते हैं; रिश्ते में उतार-चढ़ाव आते रहेंगे।',
    'आपके जन्म नक्षत्र एक-दूसरे का साथ देते हैं — किस्मत इस रिश्ते पर मेहरबान लगती है।',
  ],
  'yoni': [
    'आप दोनों की सहज पसंद अलग-अलग दिशा में जाती है — यहाँ सब्र और एक-दूसरे की लय का आदर ज़रूरी है।',
    'आपकी सहज पसंद ठीक-ठाक मिलती है — थोड़ी देखभाल से निभ जाती है।',
    'आपकी सहज पसंद ठीक-ठाक मिलती है — थोड़ी देखभाल से निभ जाती है।',
    'आपकी सहज पसंद बहुत अच्छे से मिलती है — शारीरिक नज़दीकी सहज और अपने-आप आती है।',
  ],
  'maitri': [
    'आप दोनों का मन अलग-अलग पटरी पर चलता है; एक ही बात को अक्सर आप अलग-अलग तरह से समझ सकते हैं।',
    'आपके मन ठीक-ठाक मिलते हैं, बीच-बीच में कोई ग़लतफ़हमी के साथ।',
    'आपके मन अधिकतर एक-से चलते हैं — बात करके सुलझाना आसान रहता है।',
    'आपके मन पुराने दोस्तों की तरह मिलते हैं — आप एक-दूसरे को समझते हैं और साथ देते हैं।',
  ],
  'gana': [
    'आप दोनों का स्वभाव आपस में काफ़ी टकराता है — साफ़ बात करना और मतभेदों का आदर करना अहम रहेगा।',
    'आप दोनों का स्वभाव अलग है — साफ़ बात करना और मतभेदों का आदर करना अहम रहेगा।',
    'आपके स्वभाव आपस में निभ जाते हैं, बस कुछ छोटे-मोटे फ़र्क़ सुलझाने होंगे।',
    'आपके स्वभाव अच्छे से मेल खाते हैं — आपकी प्रकृति सहजता से मिल जाती है।',
  ],
  'bhakoot': [
    'भकूट दोष मौजूद है — पारिवारिक सद्भाव और साझा पैसे पर थोड़ा सचेत ध्यान चाहिए।',
    'भकूट दोष मौजूद है — पारिवारिक सद्भाव और साझा पैसे पर थोड़ा सचेत ध्यान चाहिए।',
    'भकूट दोष नहीं — घर-परिवार का जीवन और साझा संसाधन सहजता से चलेंगे।',
    'भकूट दोष नहीं — घर-परिवार का जीवन और साझा संसाधन सहजता से चलेंगे।',
  ],
  'nadi': [
    'नाड़ी दोष मौजूद है — यह सबसे भारी परीक्षण है; स्वास्थ्य और संतान पर ध्यान और कोई उपाय ज़रूरी है।',
    'नाड़ी दोष मौजूद है — यह सबसे भारी परीक्षण है; स्वास्थ्य और संतान पर ध्यान और कोई उपाय ज़रूरी है।',
    'नाड़ी दोष नहीं — सबसे अहम परीक्षण साफ़-साफ़ पास हो जाता है।',
    'नाड़ी दोष नहीं — सबसे अहम परीक्षण साफ़-साफ़ पास हो जाता है।',
  ],
};

int _band(double got, double max) {
  final r = max == 0 ? 0 : got / max;
  if (r >= 0.99) return 3;
  if (r >= 0.5) return 2;
  if (r > 0) return 1;
  return 0;
}

String milanKootLine(String key, double got, double max, bool hi) =>
    (hi ? _kootTextHi : _kootTextEn)[key]![_band(got, max)];

// ---- Overall verdict ----

(String, String) milanVerdict(double total, bool hi) {
  if (total >= 30) {
    return hi
        ? ('एक शुभ संयोग',
            'यहाँ तारे बहुत मेहरबान हैं — एक ऐसा रिश्ता जो अपने-आप मेल खाता है और मज़बूत है।')
        : ('A Blessed Union',
            'The stars are really kind here — a bond that fits naturally and stands strong.');
  }
  if (total >= 26) {
    return hi
        ? ('एक सशक्त मिलान',
            'एक मज़बूत, अच्छे से मेल खाती जोड़ी, जिसमें लंबा साथ निभाने का सच्चा दम है।')
        : ('A Strong Match',
            'A strong, well-matched pair that has what it takes to go the distance.');
  }
  if (total >= 22) {
    return hi
        ? ('एक अच्छा मिलान',
            'कमज़ोरियों से ज़्यादा मज़बूतियाँ — एक उम्मीद भरा रिश्ता जो अच्छे से निभ सकता है।')
        : ('A Good Match',
            'More strengths than rough spots — a hopeful bond that can work well.');
  }
  if (total >= 18) {
    return hi
        ? ('प्रयास से निभने वाला',
            'यहाँ सच्ची संभावना है, पर इस रिश्ते को सोच-समझकर मेहनत और सब्र चाहिए। आपस में खुलकर बात करना और एक-दूसरे को समझना ही तय करेगा कि यह कैसे आगे बढ़ता है।')
        : ('Workable, with Effort',
            'There is real potential here, but this bond will need honest effort and patience. How openly you talk and how well you understand each other will decide where it goes.');
  }
  if (total >= 13) {
    return hi
        ? ('चुनौतीपूर्ण — देखभाल चाहिए',
            'कुंडली साफ़ बता रही है कि यहाँ असली टकराव है। समझदारी और सच्चाई से यह निभ सकता है, पर आँखें खुली रखकर आगे बढ़ें।')
        : ('Challenging — Needs Care',
            'The chart clearly points to real friction. With maturity and honesty it can still work, but go in with your eyes open.');
  }
  return hi
      ? ('कठिन — परामर्श लें',
          'शास्त्रों के हिसाब से अंक कम है। कृपया इसे ध्यान से तौलें और कोई फ़ैसला लेने से पहले किसी अनुभवी ज्योतिषी से सलाह ज़रूर लें।')
      : ('Difficult — Seek Counsel',
          'By the classical count the score is low. Please weigh this carefully and talk to an experienced astrologer before you decide.');
}

// ---- Four lived dimensions (regrouping the eight koots) ----

class MilanDimension {
  final String title;
  final String titleHi;
  final String subtitle;
  final String subtitleHi;
  final List<String> koots;
  const MilanDimension(
      this.title, this.titleHi, this.subtitle, this.subtitleHi, this.koots);
  String titleOf(bool hi) => hi ? titleHi : title;
  String subtitleOf(bool hi) => hi ? subtitleHi : subtitle;
}

const milanDimensions = [
  MilanDimension(
      'Mental & Communication',
      'मानसिक तालमेल और संवाद',
      'How easily your minds meet, and how well luck carries your talks along.',
      'आपके मन कितनी आसानी से मिलते हैं, और किस्मत आपकी बातचीत को कितना साथ देती है।',
      ['tara', 'maitri']),
  MilanDimension(
      'Emotional & Family',
      'भावनात्मक और पारिवारिक',
      'How well your temperaments blend, and the flow of shared family life.',
      'आपके स्वभाव कितने अच्छे से घुलते हैं, और साथ में परिवार का जीवन कैसे चलता है।',
      ['gana', 'bhakoot']),
  MilanDimension(
      'Physical & Instinctive',
      'शारीरिक और स्वाभाविक',
      'Physical attraction, the pull between you, and how evenly the say is shared.',
      'शारीरिक आकर्षण, आपस का खिंचाव, और आप दोनों के बीच बराबरी का संतुलन।',
      ['vashya', 'yoni']),
  MilanDimension(
      'Spiritual & Wellbeing',
      'आध्यात्मिक और कल्याण',
      'How well your inner natures line up, and the base for health and family line.',
      'आपके अंदरूनी स्वभाव का मेल, और सेहत तथा आगे की पीढ़ी की नींव।',
      ['varna', 'nadi']),
];

const _dimBodyEn = <String, List<String>>{
  // [poor, mid, good]
  'Mental & Communication': [
    'You think on different tracks — the same words can mean different things to each of you. Patience and plain talk help.',
    'Mostly on the same page, with the odd mix-up that a little patience sorts out.',
    'You think on the same track — words land the way you mean them.',
  ],
  'Emotional & Family': [
    'Your natures and family habits pull in different directions; being honest and leaving room to disagree matters.',
    'Mostly in tune emotionally, with a few things — family ties, money habits — that need conscious sorting out.',
    'Your natures and family rhythms move together with ease.',
  ],
  'Physical & Instinctive': [
    'Some friction at the gut level; building trust slowly and respecting each other\'s pace matter most.',
    'A workable instinctive bond — your pace and likes differ, but care bridges the gap.',
    'Strong natural attraction and an easy, even give-and-take.',
  ],
  'Spiritual & Wellbeing': [
    'You are built differently inside; shared values have to be built on purpose, not just assumed.',
    'Broadly on the same page in values and make-up, with small differences to respect.',
    'In tune at the deepest level — your values, wellbeing, and where life is headed move together.',
  ],
};

const _dimBodyHi = <String, List<String>>{
  'Mental & Communication': [
    'आप दोनों अलग-अलग पटरी पर सोचते हैं — एक ही बात के अलग-अलग मतलब निकल सकते हैं। सब्र और साफ़ बातचीत मदद करती है।',
    'अधिकतर एक-सी सोच, बीच-बीच में कोई ग़लतफ़हमी जिसे थोड़ा सब्र सुलझा देता है।',
    'आप एक ही पटरी पर सोचते हैं — बात ठीक वैसे ही समझी जाती है जैसे कही जाती है।',
  ],
  'Emotional & Family': [
    'आपके स्वभाव और घर के तौर-तरीक़े अलग दिशा में खींचते हैं; सच्चाई और मतभेद की गुंजाइश रखना ज़रूरी है।',
    'दिल से अधिकतर तालमेल है, कुछ बातें — घर-परिवार के रिश्ते, पैसे की आदतें — जिन पर सोच-समझकर सुलझाना होगा।',
    'आपके स्वभाव और परिवार की लय आसानी से साथ चलते हैं।',
  ],
  'Physical & Instinctive': [
    'गहरे मन में थोड़ा टकराव; धीरे-धीरे भरोसा बनाना और एक-दूसरे की रफ़्तार का आदर सबसे अहम है।',
    'निभने वाला सहज बंधन — रफ़्तार और पसंद अलग हैं, पर ख्याल रखना इस फ़ासले को पाट देता है।',
    'मज़बूत सहज आकर्षण और लेन-देन का आसान, बराबरी वाला संतुलन।',
  ],
  'Spiritual & Wellbeing': [
    'आप अंदर से अलग बने हैं; साझा मूल्यों को यूँ ही मान लेने के बजाय जान-बूझकर बनाना होगा।',
    'मूल्यों और बनावट में मोटे तौर पर तालमेल, कुछ छोटे फ़र्क़ों का आदर करते हुए।',
    'सबसे गहरे स्तर पर तालमेल — आपके मूल्य, कल्याण और जीवन की दिशा एक साथ चलते हैं।',
  ],
};

String milanDimensionBody(MilanDimension d, double got, double max, bool hi) {
  final r = max == 0 ? 0.0 : got / max;
  final band = r >= 0.75 ? 2 : (r >= 0.4 ? 1 : 0);
  return '${d.subtitleOf(hi)} ${(hi ? _dimBodyHi : _dimBodyEn)[d.title]![band]}';
}

// ---- Shine / awareness blurbs, keyed by koot ----

const _shineBlurbEn = <String, (String, String)>{
  'varna': ('Your inner natures line up',
      'You both come at life from a similar place inside — neither of you will quietly hold the other\'s priorities against them over the years.'),
  'vashya': ('You naturally pull toward each other',
      'The influence between you is even — you move toward one another without one taking over.'),
  'tara': ('Luck walks with you',
      'Your birth stars back each other up, cushioning the bond through life\'s turns.'),
  'yoni': ('Instincts in tune',
      'Your physical and gut natures blend easily — closeness comes without having to push.'),
  'maitri': ('Minds that meet like friends',
      'You get each other almost without trying — talking things through and supporting each other comes naturally.'),
  'gana': ('Temperaments that fit',
      'Your basic natures sit well together — fewer clashes of mood and manner.'),
  'bhakoot': ('Family life flows easily',
      'With no Bhakoot friction, sharing a home, money, and family life tends to settle into an easy rhythm instead of turning into a battleground.'),
  'nadi': ('Health & family line on solid ground',
      'No Nadi Dosha — the heaviest check passes cleanly. Your basic make-ups complement each other.'),
};
const _shineBlurbHi = <String, (String, String)>{
  'varna': ('आपके अंदरूनी स्वभाव मिलते हैं',
      'आप दोनों जीवन को अंदर से एक-सी नज़र से देखते हैं — सालों तक कोई एक-दूसरे की प्राथमिकताओं से मन-ही-मन नाराज़ नहीं रहेगा।'),
  'vashya': ('एक-दूसरे की ओर सहज खिंचाव',
      'आपके बीच का असर बराबर है — आप एक-दूसरे की ओर बढ़ते हैं, कोई हावी नहीं होता।'),
  'tara': ('किस्मत आपके साथ चलती है',
      'आपके जन्म नक्षत्र एक-दूसरे को ताक़त देते हैं और ज़िंदगी के मोड़ों पर रिश्ते को सहारा देते हैं।'),
  'yoni': ('स्वभाव में तालमेल',
      'आपकी शारीरिक और सहज प्रकृति आसानी से घुल-मिल जाती है — नज़दीकियाँ बिना ज़ोर लगाए आती हैं।'),
  'maitri': ('दोस्तों जैसे मिलते मन',
      'आप एक-दूसरे को बिना कोशिश किए ही समझ लेते हैं — बातचीत और एक-दूसरे का सहारा सहज आता है।'),
  'gana': ('मेल खाते स्वभाव',
      'आपकी मूल प्रकृति अच्छी तरह साथ बैठती है — मिज़ाज और व्यवहार के टकराव कम रहते हैं।'),
  'bhakoot': ('पारिवारिक जीवन आसानी से चलता है',
      'भकूट का टकराव न होने से साझा गृहस्थी, पैसा और पारिवारिक रिश्ते लड़ाई के मैदान बनने के बजाय एक आसान लय में ढल जाते हैं।'),
  'nadi': ('सेहत और वंश की मज़बूत नींव',
      'नाड़ी दोष नहीं — सबसे भारी परीक्षण साफ़-साफ़ पास होता है। आप दोनों की बनावट एक-दूसरे की पूरक है।'),
};

const _awareBlurbEn = <String, (String, String)>{
  'varna': ('You care about different things deep down',
      'At the core, you value life in different ways. Say out loud what each of you holds dear, so neither feels overlooked.'),
  'vashya': ('One of you may pull harder',
      'The say between you tips to one side. Keep checking in: whose choice are we going with? Equal say keeps love free of quiet resentment.'),
  'tara': ('Some rough patches ahead',
      'The stars won\'t always soften this bond. Expect harder stretches, and face them as a team, not as rivals.'),
  'yoni': ('Your instincts differ',
      'Your physical and gut rhythms don\'t match on their own. Slow down, ask, and respect each other\'s pace.'),
  'maitri': ('Your minds work differently',
      'You can look at the same thing and read it two different ways. The fix isn\'t agreeing — it\'s asking "how are you seeing this?" before you react.'),
  'gana': ('Very different temperaments',
      'One of you may be soft and idealistic while the other is intense and down-to-earth. Respect the difference; don\'t try to "fix" the other person.'),
  'bhakoot': ('Family & money need care',
      'Bhakoot friction can strain shared money and family life. Agree on the big things early, and come back to them often.'),
  'nadi': ('Go carefully on health',
      'A same-Nadi match is the heaviest flag — tradition ties it to health and children. Talk to an astrologer and put your wellbeing first, together.'),
};
const _awareBlurbHi = <String, (String, String)>{
  'varna': ('गहरे में आपकी अलग-अलग प्राथमिकताएँ',
      'मन की गहराई में आप जीवन को अलग तरह से अहमियत देते हैं। जो हर एक को प्यारा है उसे खुलकर कह दें, ताकि किसी को अनदेखा न लगे।'),
  'vashya': ('आप में से एक ज़्यादा हावी हो सकता है',
      'आपके बीच बात एक ओर झुकी है। बार-बार पूछते रहें: हम किसकी पसंद पर चल रहे हैं? बराबर की चलेगी तो प्यार में मन-ही-मन नाराज़गी नहीं आएगी।'),
  'tara': ('आगे कुछ मुश्किल दौर',
      'तारे इस रिश्ते को हमेशा नरम नहीं करते। मुश्किल दौर आने के लिए तैयार रहें, और उनका सामना प्रतिद्वंद्वी बनकर नहीं, एक टीम बनकर करें।'),
  'yoni': ('आपकी सहज पसंद अलग है',
      'आपकी शारीरिक और सहज लय अपने-आप मेल नहीं खाती। धीरे चलें, पूछें, और एक-दूसरे की रफ़्तार का आदर करें।'),
  'maitri': ('आपका मन अलग तरह से चलता है',
      'एक ही बात को आप दो अलग-अलग तरह से समझ सकते हैं। हल यह नहीं कि सहमत हो जाएँ — बल्कि प्रतिक्रिया देने से पहले पूछें, "तुम इसे कैसे देख रहे हो?"'),
  'gana': ('बहुत अलग स्वभाव',
      'आप में से एक नरम और आदर्शों वाला हो सकता है तो दूसरा तीव्र और ज़मीन से जुड़ा। इस फ़र्क़ का आदर करें; दूसरे को "सुधारने" की कोशिश न करें।'),
  'bhakoot': ('परिवार और पैसे पर ध्यान चाहिए',
      'भकूट का टकराव साझा पैसे और पारिवारिक जीवन पर दबाव डाल सकता है। बड़ी बातों पर पहले ही सहमति बना लें, और समय-समय पर उन्हें दोहराते रहें।'),
  'nadi': ('सेहत के मामले में सावधानी',
      'एक ही नाड़ी का मिलान सबसे भारी संकेत है — परंपरा में इसे सेहत और संतान से जोड़ा जाता है। किसी ज्योतिषी से सलाह लें और मिलकर अपने कल्याण को पहले रखें।'),
};

// Koot order for consistent display.
const _kootOrder = ['varna', 'vashya', 'tara', 'yoni', 'maitri', 'gana', 'bhakoot', 'nadi'];

List<(String, String)> milanShineItems(MilanResult r, bool hi) {
  final map = hi ? _shineBlurbHi : _shineBlurbEn;
  final out = <(String, String)>[];
  for (final key in _kootOrder) {
    final k = r.koot(key);
    if (k.max > 0 && k.got / k.max >= 0.85) out.add(map[key]!);
  }
  return out;
}

List<(String, String)> milanAwareItems(MilanResult r, bool hi) {
  final map = hi ? _awareBlurbHi : _awareBlurbEn;
  final out = <(String, String)>[];
  for (final key in _kootOrder) {
    final k = r.koot(key);
    if (k.max > 0 && k.got / k.max <= 0.34) out.add(map[key]!);
  }
  return out;
}

// ---- What this looks like day to day ----

String _pick(double r, String poor, String mid, String good) =>
    r >= 0.75 ? good : (r >= 0.4 ? mid : poor);

List<(String, String)> milanDailyLife(MilanResult r, bool hi) {
  double frac(String k) {
    final ks = r.koot(k);
    return ks.max == 0 ? 0 : ks.got / ks.max;
  }

  final comm = frac('maitri');
  final live = (frac('bhakoot') + frac('gana')) / 2;
  final intim = (frac('yoni') + frac('vashya')) / 2;
  final well = frac('nadi');

  if (hi) {
    return [
      (
        'रोज़मर्रा की बातचीत',
        _pick(
            comm,
            'बार-बार समझाना पड़ेगा। जब कोई बात अहम हो, उसे दो बार कहें — एक बार अपने शब्दों में, एक बार उनके शब्दों में।',
            'बातचीत अधिकतर दिन ठीक चलती है; जब बात अहम हो, ज़रा रुककर पक्का कर लें कि दोनों का मतलब एक ही है।',
            'बातचीत आसान है — आप मुश्किल बातें भी कह सकते हैं और फिर भी सुने जाते हैं।'),
      ),
      (
        'साथ रहना',
        _pick(
            live,
            'एक ही घर में रहना सच्चा तालमेल माँगता है — दिनचर्या पर पहले सहमति बना लें और हँसी-मज़ाक साथ रखें।',
            'दिनचर्या और परिवार की उम्मीदों पर थोड़ी बातचीत, पर कुछ भी ऐसा नहीं जिसे प्यार और हँसी न सुलझा सके।',
            'रोज़मर्रा का जीवन एक आसान लय में ढल जाता है — दिनचर्या और परिवार बिना ज़्यादा टकराव के मेल खाते हैं।'),
      ),
      (
        'नज़दीकी और अपनापन',
        _pick(
            intim,
            'नज़दीकी को सब्र चाहिए — अलग रफ़्तार का मतलब है धीरे चलना और पूछना, यूँ ही मान न लेना।',
            'निभने वाला अपनेपन का बंधन — रफ़्तार और पसंद अलग हो सकती है, पर एक-दूसरे का ख्याल इसे जोड़ देता है।',
            'नज़दीकी अपने-आप आती है — आकर्षण और प्यार दोनों तरफ़ से बहते हैं।'),
      ),
      (
        'लंबे समय की सेहत',
        _pick(
            well,
            'आप दोनों की बनावट अलग है — सेहत और दिनचर्या पर साथ मिलकर ध्यान देना वक़्त के साथ रिश्ते को मज़बूत रखता है।',
            'सेहत और रहन-सहन पर साथ मिलकर ध्यान रखना रिश्ते को सालों तक मज़बूत बनाए रखता है।',
            'बनावट का कोई बड़ा टकराव नहीं। सेहत और रहन-सहन की आम देखभाल से रिश्ता दशकों तक आराम से चलता है।'),
      ),
    ];
  }

  return [
    (
      'Everyday talk',
      _pick(
          comm,
          'You\'ll need to spell things out often. When something matters, say it twice — once in your words, once in theirs.',
          'Talking works well most days; when it really matters, slow down and check you both mean the same thing.',
          'Talking is easy — you can say hard things and still be heard.'),
    ),
    (
      'Living together',
      _pick(
          live,
          'Sharing a home takes real give-and-take — agree on the routines early and keep the humour close.',
          'A bit of working-out around routines and family expectations, but nothing that goodwill and a laugh can\'t smooth over.',
          'Daily life settles into an easy rhythm — routines and family fit together without much friction.'),
    ),
    (
      'Closeness & intimacy',
      _pick(
          intim,
          'Closeness needs patience — different rhythms mean going slow and asking, not assuming.',
          'A workable close bond — your pace and likes may differ, but caring for each other bridges the gap.',
          'Closeness comes easily — attraction and affection flow both ways.'),
    ),
    (
      'Long-term wellbeing',
      _pick(
          well,
          'You\'re built differently — looking after health and routine together keeps the bond strong over time.',
          'Looking after health and lifestyle together keeps the bond going strong across the years.',
          'No big clash in how you\'re built. With basic care of health and lifestyle, the bond carries easily across decades.'),
    ),
  ];
}

// ---- Closing word & disclaimer ----

String milanClosingWord(double total, bool hi) {
  if (total >= 26) {
    return hi
        ? 'यह वह रिश्ता है जिसकी ओर तारे झुके हुए हैं। जिस सच्चाई ने आपको यहाँ तक पहुँचाया, उसी से इसे सँभालें, और यह आपको बहुत दूर तक ले जाएगा।'
        : 'This is a bond the stars lean toward. Look after it with the same honesty that brought you here, and it will carry you far.';
  }
  if (total >= 18) {
    return hi
        ? 'यहाँ कुछ सच्चा है, पर इसके लिए समझदारी से मेहनत करनी होगी। यह अंक आपका भविष्य नहीं है — यह बस एक नक्शा है कि आसान और मुश्किल दौर कहाँ-कहाँ हैं। जो जोड़े अपने मुश्किल दौर को पहले से जान लेते हैं, वे अक्सर उन जोड़ों से बेहतर निभाते हैं जिन्होंने मान लिया था कि सब आसान ही रहेगा।'
        : 'There is something real here, but it asks for grown-up effort. The score is not your future — it is just a map of where the easy and hard stretches lie. Couples who know their hard stretches ahead of time often do better than couples who assumed it would all be easy.';
  }
  return hi
      ? 'शास्त्रों के हिसाब से अंक सावधान करता है। यह सिर्फ़ जानकारी है, कोई आख़िरी फ़ैसला नहीं। अगर आपके मन तय हैं, तो आँखें खुली रखकर आगे बढ़ें, मेहनत करें और किसी समझदार से सलाह लें।'
      : 'By the classical count the score urges caution. That\'s information, not a verdict. If your hearts are set, walk in with your eyes open, put in the work, and seek wise advice.';
}

String milanDisclaimer(bool hi) => hi
    ? 'यह अष्टकूट गुण मिलान शास्त्रों की पुरानी परंपरा पर आधारित मार्गदर्शन देता है — यह किसी अनुभवी ज्योतिषी की सलाह की जगह नहीं ले सकता। शादी जैसे बड़े फ़ैसलों के लिए कृपया किसी जानकार से ज़रूर सलाह लें। अपने दिल पर भरोसा रखें, अपने रिश्ते का मान रखें, और प्यार से चुनाव करें।'
    : 'This Ashtakoot Guna Milan gives guidance rooted in old classical tradition — it can\'t take the place of an experienced astrologer\'s advice. For big decisions like marriage, please talk to an expert. Trust your heart, honour your bond, and choose with love.';

(String, String) milanManglikNote(MilanResult r, bool hi) {
  if (r.a.manglik && r.b.manglik) {
    return hi
        ? ('मंगल दोष — दोनों में',
            'दोनों की कुंडली में मंगल दोष है। परंपरा मानती है कि जोड़े में दोनों तरफ़ होने पर यह आपस में कट जाता है, इसलिए यहाँ चिंता की कोई बात नहीं।')
        : ('Mangal Dosha — matched',
            'Both charts have Mangal Dosha. Tradition says that when both have it, it cancels out between the pair, so there\'s nothing to worry about here.');
  }
  if (!r.a.manglik && !r.b.manglik) {
    return hi
        ? ('मंगल दोष — नहीं',
            'किसी की भी कुंडली में मंगल दोष नहीं है। इस बारे में सुलझाने को कुछ है ही नहीं।')
        : ('Mangal Dosha — clear',
            'Neither chart has Mangal Dosha. There\'s nothing to sort out on this front.');
  }
  final who = r.a.manglik ? r.a.name : r.b.name;
  return hi
      ? ('मंगल दोष — एक तरफ़',
          '$who की कुंडली में मंगल दोष है जबकि दूसरे की में नहीं। परंपरा यहाँ सावधानी की सलाह देती है; अक्सर कोई उपाय या किसी ज्योतिषी से जाँच करवाने को कहा जाता है। एक बात याद रखें — अगर मंगल अपनी राशि या उच्च राशि में बैठा हो, तो यह दोष काफ़ी हद तक कट जाता है।')
      : ('Mangal Dosha — on one side',
          '$who has Mangal Dosha while the other does not. Tradition says to be careful here; a remedy or a check with an astrologer is often suggested. One thing to keep in mind — if Mangal sits in its own or exalted sign, the dosha is considered largely cancelled.');
}
