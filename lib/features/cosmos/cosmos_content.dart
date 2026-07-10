import '../panchang/panchang_names.dart' show NamePair;

/// All authored bilingual copy for the Rashifal (My Cosmos) feature. Kept as a
/// pure data file (like interpretations.dart / astrology_data.dart) so widgets
/// stay logic-free. Every entry is EN + HI — nothing English-only reaches the
/// UI. Read the right side with `pair.call(hi)`.

// ---- Section titles ----
const cTitleWeather = NamePair("Today's Cosmic Weather", 'आज का ग्रह-मौसम');
const cTitleDasha = NamePair('Your Dasha', 'आपकी दशा');
const cTitleGochar = NamePair('Moon Transit', 'चंद्र गोचर');
const cTitleHours = NamePair('Favourable & Tricky Hours', 'शुभ व अशुभ समय');
const cTitleAlert = NamePair('Transit Alert', 'गोचर सूचना');
const cTitleLucky = NamePair('Lucky Today', 'आज का शुभ');
const cLabelFav = NamePair('Favourable', 'शुभ');
const cLabelTricky = NamePair('Avoid', 'अशुभ');
const cLabelColour = NamePair('Colour', 'रंग');
const cLabelNumber = NamePair('Number', 'अंक');
const cLabelDirection = NamePair('Direction', 'दिशा');
const cLabelMantra = NamePair('Mantra', 'मंत्र');
const cChant = NamePair('Chant now', 'अभी जप करें');

// ---- The one-line day verdict (index by tier: 0 favourable,1 mixed,2 hard) ----
const cVerdictTiers = <NamePair>[
  NamePair('The stars are with you today — go ahead and do it with confidence.',
      'आज ग्रह आपके साथ हैं — भरोसे के साथ आगे बढ़ें।'),
  NamePair('A mixed day — take it slow and pick the right moment.',
      'आज दिन मिला-जुला है — धीरे चलें और सही मौका चुनें।'),
  NamePair('A tough day — step carefully and stay away from big risks.',
      'आज दिन थोड़ा कठिन है — संभलकर चलें और बड़े जोखिम से दूर रहें।'),
];
const cVerdictLabels = <NamePair>[
  NamePair('Favourable', 'अनुकूल'),
  NamePair('Mixed', 'मिश्रित'),
  NamePair('Challenging', 'चुनौतीपूर्ण'),
];

// ---- Chandra Gochar: Moon transiting the Nth house from the natal Moon.
// Index 0 = 1st house (Janma) … index 11 = 12th house. ----
const cGocharThemes = <NamePair>[
  NamePair('The Moon sits on your sign — your mind feels restless, so rest and take it easy.',
      'चंद्र आपकी राशि पर है — मन थोड़ा बेचैन रहेगा, इसलिए आराम करें और सहज रहें।'),
  NamePair('The Moon moves to your 2nd — family, food and money are on your mind today.',
      'चंद्र आपके दूसरे भाव में है — आज परिवार, खान-पान और पैसे पर ध्यान रहेगा।'),
  NamePair('The Moon moves to your 3rd — your courage and hard work pay off today.',
      'चंद्र आपके तीसरे भाव में है — आज आपकी हिम्मत और मेहनत रंग लाएगी।'),
  NamePair('The Moon moves to your 4th — home, comfort and your mother bring you warmth.',
      'चंद्र आपके चौथे भाव में है — घर, सुख-चैन और माँ का प्यार आपको सुकून देंगे।'),
  NamePair('The Moon moves to your 5th — creativity, love and children bring you joy.',
      'चंद्र आपके पाँचवें भाव में है — रचनात्मकता, प्रेम और संतान का सुख मिलेगा।'),
  NamePair('The Moon moves to your 6th — you get the better of rivals, but look after your health.',
      'चंद्र आपके छठे भाव में है — विरोधियों पर भारी रहेंगे, पर सेहत का ध्यान रखें।'),
  NamePair('The Moon moves to your 7th — partners, travel and people are all on your side.',
      'चंद्र आपके सातवें भाव में है — जीवनसाथी, यात्रा और लोग सब आपके साथ रहेंगे।'),
  NamePair('The Moon moves to your 8th — slow down, skip risks and give yourself time to think.',
      'चंद्र आपके आठवें भाव में है — रफ्तार धीमी रखें, जोखिम टालें और सोच-विचार करें।'),
  NamePair('The Moon moves to your 9th — luck, faith and learning are all with you.',
      'चंद्र आपके नौवें भाव में है — भाग्य, आस्था और ज्ञान सब आपका साथ देंगे।'),
  NamePair('The Moon moves to your 10th — a strong day for work and your good name.',
      'चंद्र आपके दसवें भाव में है — काम और मान-सम्मान के लिए मजबूत दिन है।'),
  NamePair('The Moon moves to your 11th — gains, friends and wishes coming true.',
      'चंद्र आपके ग्यारहवें भाव में है — लाभ, दोस्त और मनचाही बातें पूरी होंगी।'),
  NamePair('The Moon moves to your 12th — spending and quiet time; look within.',
      'चंद्र आपके बारहवें भाव में है — खर्च और एकांत का समय; अपने भीतर झाँकें।'),
];

// ---- 12-Rashi daily horoscope: aspect labels + tone-tiered predictions ----
// Each aspect is a `[tone][variant]` pool: outer index by day tone
// (0 = favourable, 1 = mixed, 2 = challenging), inner is a small set of variants
// picked deterministically per rashi + day via `dailyVariant` (daily_cosmos.dart)
// so neighbouring signs read differently and the text rotates day to day.
const cAspectGeneral = NamePair('General', 'सामान्य');
const cAspectLove = NamePair('Love', 'प्रेम');
const cAspectCareer = NamePair('Career', 'करियर');
const cAspectHealth = NamePair('Health', 'स्वास्थ्य');
const cAspectMoney = NamePair('Money', 'धन');
const cAspectFamily = NamePair('Family', 'परिवार');

const cLove = <List<NamePair>>[
  [
    NamePair('There is warmth in your relationships today — say how you feel, openly.',
        'आज रिश्तों में गर्मजोशी है — जो दिल में है, खुलकर कह दें।'),
    NamePair('Love feels easy today; a kind word brings you closer to someone special.',
        'आज प्रेम में सहजता है; एक मीठा बोल किसी ख़ास को और क़रीब ले आएगा।'),
    NamePair('A good day for the heart — plan something together and enjoy the closeness.',
        'दिल के लिए अच्छा दिन — साथ में कुछ योजना बनाएँ और अपनेपन का आनंद लें।'),
  ],
  [
    NamePair('Stay patient with the people you love; small misunderstandings will soon clear up.',
        'अपनों के साथ थोड़ा सब्र रखें; छोटी-मोटी ग़लतफ़हमियाँ जल्दी दूर हो जाएँगी।'),
    NamePair('Give your partner a little space today; things settle on their own by evening.',
        'आज जीवनसाथी को थोड़ी जगह दें; शाम तक बातें अपने आप संभल जाएँगी।'),
    NamePair('Speak gently in matters of the heart; a soft tone works better than being right.',
        'दिल के मामलों में नरमी से बात करें; सही होने से ज़्यादा मीठा लहज़ा काम आएगा।'),
  ],
  [
    NamePair('Skip arguments in love today; give some space and just listen.',
        'आज प्रेम में बहस से बचें; थोड़ी जगह दें और बस सुन लें।'),
    NamePair('Hold back sharp words with loved ones; let the mood pass before you talk.',
        'अपनों से कड़वे बोल रोक लें; मन शांत होने पर ही बात करें।'),
    NamePair('Feelings may be tender today — avoid big promises and simply stay caring.',
        'आज भावनाएँ नाज़ुक रहेंगी — बड़े वादों से बचें और बस प्यार बनाए रखें।'),
  ],
];
const cCareer = <List<NamePair>>[
  [
    NamePair('A strong day at work — your hard work gets noticed.',
        'काम में मजबूत दिन — आज आपकी मेहनत पर सबकी नज़र जाएगी।'),
    NamePair('Good chances at work today; step up and take the lead on a task.',
        'आज काम में अच्छे मौके हैं; आगे बढ़कर किसी काम की कमान संभालें।'),
    NamePair('Effort pays off now — a senior or client may appreciate your work.',
        'अब मेहनत रंग लाएगी — कोई वरिष्ठ या ग्राहक आपके काम की सराहना कर सकता है।'),
  ],
  [
    NamePair('Steady progress at work; take up one task at a time.',
        'काम में लगातार तरक्की; एक बार में एक ही काम पर ध्यान दें।'),
    NamePair('Keep your focus at work today; finish pending jobs before starting new ones.',
        'आज काम पर ध्यान बनाए रखें; नया शुरू करने से पहले रुके काम पूरे करें।'),
    NamePair('An average day at work — stay organised and results will follow.',
        'काम में सामान्य दिन — व्यवस्थित रहें, नतीजे अपने आप मिलेंगे।'),
  ],
  [
    NamePair('Work may get delayed; keep calm and avoid risky moves.',
        'काम में देरी हो सकती है; शांत रहें और जोखिम भरे कदमों से बचें।'),
    NamePair('Double-check your work today; small slips could cost time.',
        'आज अपना काम दोबारा जाँच लें; छोटी चूक भी समय बिगाड़ सकती है।'),
    NamePair('Avoid big decisions at work now; wait for a clearer day.',
        'अभी काम में बड़े फैसले टालें; किसी साफ़ दिन का इंतज़ार करें।'),
  ],
];
const cHealth = <List<NamePair>>[
  [
    NamePair('Good energy and freshness today — a great day to stay active.',
        'आज तन में अच्छी ऊर्जा और ताज़गी है — सक्रिय रहने के लिए बढ़िया दिन।'),
    NamePair('You feel light and fit today; a walk or some yoga will lift you further.',
        'आज शरीर हल्का और चुस्त लगेगा; टहलना या थोड़ा योग आपको और तरो-ताज़ा करेगा।'),
    NamePair('Health stays on your side — use the good mood to build a better routine.',
        'सेहत आपके साथ है — इस अच्छे मन का उपयोग बेहतर दिनचर्या बनाने में करें।'),
  ],
  [
    NamePair('Watch your daily routine; rest and light food will keep you well.',
        'अपनी दिनचर्या का ध्यान रखें; आराम और हल्का खाना आपको ठीक रखेगा।'),
    NamePair("Drink enough water and don't skip meals today; small care goes a long way.",
        'आज भरपूर पानी पिएँ और खाना न छोड़ें; छोटी सी देखभाल बहुत काम आएगी।'),
    NamePair('Mind your sleep today; a little rest will clear the tiredness.',
        'आज नींद का ध्यान रखें; थोड़ा आराम थकान दूर कर देगा।'),
  ],
  [
    NamePair('Take it easy — avoid overdoing it and get plenty of rest.',
        'आराम से चलें — खुद पर ज़्यादा ज़ोर न डालें और भरपूर आराम करें।'),
    NamePair('Go slow with your body today; skip heavy work and eat simple food.',
        'आज शरीर पर धीरे चलें; भारी काम टालें और सादा भोजन करें।'),
    NamePair("Don't ignore small signs of tiredness; rest before you push further.",
        'थकान के छोटे संकेतों को नज़रअंदाज़ न करें; आगे बढ़ने से पहले आराम करें।'),
  ],
];
const cMoney = <List<NamePair>>[
  [
    NamePair('Money is likely to come in; a good day to make decisions.',
        'आज पैसा आने के योग हैं; फैसले लेने के लिए अच्छा दिन है।'),
    NamePair('A gain or repayment may reach you today; put some aside as savings.',
        'आज कोई लाभ या उधारी वापसी मिल सकती है; कुछ हिस्सा बचत में रखें।'),
    NamePair('Good day for money matters — a planned purchase or deal can work out.',
        'धन के मामलों के लिए अच्छा दिन — सोची-समझी खरीदारी या सौदा बन सकता है।'),
  ],
  [
    NamePair('Spend carefully; put off big purchases for now.',
        'सोच-समझकर खर्च करें; बड़ी खरीदारी अभी के लिए टाल दें।'),
    NamePair('Keep an eye on your budget today; small savings will help later.',
        'आज अपने बजट पर नज़र रखें; छोटी बचत आगे काम आएगी।'),
    NamePair('Money comes and goes today; avoid lending and keep track of spending.',
        'आज पैसा आता-जाता रहेगा; उधार देने से बचें और खर्च का हिसाब रखें।'),
  ],
  [
    NamePair('Protect your money; stay away from loans and risky bets today.',
        'अपने पैसे को संभालें; आज कर्ज़ और जोखिम भरे दाँव से दूर रहें।'),
    NamePair('Hold off on investments today; an unplanned expense could pop up.',
        'आज निवेश से रुकें; कोई अनचाहा खर्च सामने आ सकता है।'),
    NamePair('Guard your wallet today; avoid big spending and money talk with others.',
        'आज अपनी जेब का ध्यान रखें; बड़े खर्च और पैसों की बातचीत से बचें।'),
  ],
];
const cFamily = <List<NamePair>>[
  [
    NamePair('Peace at home; spend some happy time with your family.',
        'घर में शांति रहेगी; परिवार के साथ कुछ खुशी के पल बिताएँ।'),
    NamePair('Warm moments at home today; a shared meal brings everyone closer.',
        'आज घर में गर्मजोशी रहेगी; साथ का भोजन सबको क़रीब लाएगा।'),
    NamePair('Family supports you today — a good time to sort out any small matter.',
        'आज परिवार आपका साथ देगा — किसी छोटी बात को सुलझाने का अच्छा समय।'),
  ],
  [
    NamePair('Give time to your family; small efforts will smooth everything over.',
        'परिवार को समय दें; छोटे-छोटे प्रयास सब कुछ सुलझा देंगे।'),
    NamePair('Listen to elders at home today; their advice settles a worry.',
        'आज घर के बड़ों की सुनें; उनकी सलाह किसी चिंता को शांत करेगी।'),
    NamePair("Keep small home matters simple today; don't let them grow bigger.",
        'आज घर की छोटी बातों को सरल रखें; उन्हें बड़ा न बनने दें।'),
  ],
  [
    NamePair('Staying patient with family will keep the peace today.',
        'परिवार के साथ सब्र रखेंगे तो आज घर में तनाव नहीं होगा।'),
    NamePair('Avoid touchy topics at home today; let calm return before you discuss.',
        'आज घर में संवेदनशील बातें टालें; शांति लौटने पर ही चर्चा करें।'),
    NamePair('A family member may need patience today; a soft word keeps the peace.',
        'आज किसी परिजन को धैर्य की ज़रूरत हो सकती है; नरम बोल शांति बनाए रखेगा।'),
  ],
];

// ---- Short Maha-Dasha theme by lord (distinct from the long dashaByLord) ----
const cDashaThemeByLord = <String, NamePair>{
  'sun': NamePair('A time for taking charge, standing tall and being seen.',
      'आगे बढ़कर कमान संभालने, पहचान बनाने और चमकने का समय।'),
  'moon': NamePair('A time for feelings, home and a sense of belonging.',
      'भावनाओं, घर और अपनेपन का समय।'),
  'mars': NamePair('A time for energy, courage and bold moves.',
      'जोश, हिम्मत और साहसी कदमों का समय।'),
  'mercury': NamePair('A time for smart thinking, good talk and business.',
      'तेज़ दिमाग, अच्छी बातचीत और कारोबार का समय।'),
  'jupiter': NamePair('A time for growth, good sense and blessings.',
      'तरक्की, समझदारी और आशीर्वाद का समय।'),
  'venus': NamePair('A time for love, beauty and comfort.',
      'प्यार, सुंदरता और सुख-चैन का समय।'),
  'saturn': NamePair('A time for discipline, patience and work that lasts.',
      'अनुशासन, धैर्य और टिकाऊ मेहनत का समय।'),
  'rahu': NamePair('A time for big dreams, new things and sudden turns.',
      'बड़े सपनों, नई चीज़ों और अचानक बदलावों का समय।'),
  'ketu': NamePair('A time for letting go and looking within.',
      'मोह छोड़ने और अपने भीतर झाँकने का समय।'),
};

// ---- Sade Sati phase note + remedy (concise, bilingual) ----
const cSadeSatiPhase = <String, NamePair>{
  'rising': NamePair(
      'Your Shani Sade Sati is just starting — new responsibilities and a slower pace begin now.',
      'आपकी शनि साढ़े साती अभी शुरू हो रही है — अब नई जिम्मेदारियाँ आएँगी और रफ्तार धीमी रहेगी।'),
  'peak': NamePair(
      'Your Shani Sade Sati is at its peak — patience and honest hard work are what protect you.',
      'आपकी शनि साढ़े साती अपने चरम पर है — धैर्य और सच्ची मेहनत ही आपकी ढाल है।'),
  'setting': NamePair(
      'Your Shani Sade Sati is winding down — the hardest part is now passing.',
      'आपकी शनि साढ़े साती अब उतार पर है — सबसे कठिन दौर बीत रहा है।'),
};
const cSadeSatiRemedy = NamePair(
    'Read the Hanuman Chalisa on Saturdays, and help elders and working people.',
    'शनिवार को हनुमान चालीसा पढ़ें, और बुज़ुर्गों व मेहनतकश लोगों की मदद करें।');

// ---- Lucky colour + direction by the chart's ruling planet ----
const cLuckyColourByPlanet = <String, NamePair>{
  'sun': NamePair('Saffron & Gold', 'केसरी व स्वर्ण'),
  'moon': NamePair('White & Silver', 'श्वेत व रजत'),
  'mars': NamePair('Red & Coral', 'लाल व मूँगा'),
  'mercury': NamePair('Green', 'हरा'),
  'jupiter': NamePair('Yellow & Gold', 'पीला व स्वर्ण'),
  'venus': NamePair('White & Pink', 'श्वेत व गुलाबी'),
  'saturn': NamePair('Blue & Black', 'नीला व काला'),
  'rahu': NamePair('Smoky Grey', 'धूम्र'),
  'ketu': NamePair('Brown & Grey', 'भूरा व धूसर'),
};
const cLuckyDirectionByPlanet = <String, NamePair>{
  'sun': NamePair('East', 'पूर्व'),
  'moon': NamePair('North-West', 'वायव्य'),
  'mars': NamePair('South', 'दक्षिण'),
  'mercury': NamePair('North', 'उत्तर'),
  'jupiter': NamePair('North-East', 'ईशान'),
  'venus': NamePair('South-East', 'आग्नेय'),
  'saturn': NamePair('West', 'पश्चिम'),
  'rahu': NamePair('South-West', 'नैऋत्य'),
  'ketu': NamePair('Centre', 'केंद्र'),
};

// ---- Empty state (no birth chart yet) ----
const cEmptyHeading =
    NamePair('See your day through your own stars', 'अपने सितारों से अपना दिन देखें');
const cEmptyBody = NamePair(
    'Add your birth details to unlock a reading made just for you — your dasha, moon transit, lucky signs and the day ahead.',
    'सिर्फ़ आपके लिए बना राशिफल पाने के लिए अपनी जन्म जानकारी जोड़ें — आपकी दशा, चंद्र गोचर, शुभ संकेत और आने वाला दिन।');
const cEmptyCta = NamePair('Create your chart', 'अपनी कुंडली बनाएं');

// ---- Kamal-gated "deeper reading" teaser ----
const cDeeperTitle =
    NamePair('Find out your next lucky day', 'जानें आपका अगला शुभ दिन कौन-सा है');
const cDeeperLocked =
    NamePair('Unlock with Kamal', 'कमल से अनलॉक करें');
const cDeeperInsufficient =
    NamePair('Not enough Kamal yet', 'पर्याप्त कमल नहीं');
