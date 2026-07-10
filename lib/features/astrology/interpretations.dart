// Original interpretation library authored for DivyaVaani. Selected by the
// rule engine (yogas_doshas.dart, vimshottari.dart) from the computed chart.
// This is our own writing — edit freely.

/// Soul profile by Lagna (ascendant) sign, 0 = Aries .. 11 = Pisces.
const soulByLagna = <String>[
  'You take life head-on. There\'s a restless, go-first energy in you that makes you a natural starter — you\'re the one who kicks things off. Courage comes easily to you; patience is the thing you\'re here to learn.',
  'You\'re steady and down-to-earth. You build things slowly and then hold on firmly. Comfort, loyalty and real, solid things matter to you; change feels easier once it feels safe.',
  'You\'re curious and quick, and you come alive through words, ideas and connecting with people. Variety keeps you going; you find real depth when you let one thing finish before jumping to the next.',
  'You lead with your heart and your memories. Home, your roots and the people you look after shape everything you do; your quiet strength is how much you care.',
  'You\'re warm, proud and full of expression — you\'re here to shine and to give. Being appreciated matters to you; staying generous keeps your ego in the right place.',
  'You\'re careful and helpful, and you polish up what others leave half-done. Helping people and doing good work is how you show love; going a little easier on yourself is the thing to work on.',
  'You look for balance, beauty and fairness in everything. Your relationships act like a mirror for you; learning to make decisions is the muscle you need to build.',
  'You\'re intense and private. You feel everything deeply, and you grow by going right through it. Power, trust and truth are your big themes in life.',
  'At heart you\'re a seeker, always reaching for meaning, freedom and far-off horizons. Faith keeps you moving; a bit of focus turns that faith into real wisdom.',
  'You\'re disciplined and you last the distance, climbing step by step through responsibility and time. Your ambition is real — keeping some warmth is what makes the top worth reaching.',
  'You\'re independent and you look to the future, thinking in big systems and ideals. You belong to everyone, not just a few; getting close one-on-one is where you stretch yourself.',
  'You\'re sensitive and open, and the line between you and the world around you often melts away. Compassion and imagination are your gifts; staying grounded is the practice for you.',
];

/// Hindi — soul profile by Lagna (ascendant) sign, 0 = Aries .. 11 = Pisces.
const soulByLagnaHi = <String>[
  'आप ज़िंदगी का सामना सीधे और बेझिझक करते हैं। एक आगे बढ़ने वाली, बेचैन ऊर्जा आपको वो इंसान बना देती है जो हर काम शुरू करता है — पहल आप ही करते हैं। हिम्मत आपमें अपने-आप है; बस सब्र रखना — यही आपको सीखना है।',
  'आप शांत और ज़मीन से जुड़े हैं, धीरे-धीरे चीज़ें बनाते हैं और फिर मज़बूती से टिके रहते हैं। आराम, वफ़ादारी और ठोस, असली चीज़ें आपके लिए मायने रखती हैं; बदलाव तभी आसान लगता है जब वह सुरक्षित महसूस हो।',
  'आप जिज्ञासु और फुर्तीले हैं, और शब्दों, विचारों तथा लोगों से जुड़कर जी उठते हैं। तरह-तरह की चीज़ें आपको ऊर्जा देती हैं; गहराई तब आती है जब आप एक काम को पूरा होने देते हैं, फिर दूसरे पर जाते हैं।',
  'आप अपने दिल और अपनी यादों के सहारे आगे बढ़ते हैं। घर, अपनी जड़ें और वे लोग जिनका आप ख़याल रखते हैं — यही सब कुछ को आकार देते हैं; आपकी सबसे बड़ी ताकत है आपका ख़याल रखना और प्यार करना।',
  'आप गर्मजोश, स्वाभिमानी और खुलकर जताने वाले हैं — आप चमकने और देने के लिए बने हैं। सराहा जाना आपके लिए मायने रखता है; दरियादिली आपके अहं को उसकी सही जगह पर रखती है।',
  'आप बारीकी से देखने वाले और मददगार हैं, और जिसे दूसरे अधूरा छोड़ देते हैं उसे आप संवार देते हैं। दूसरों की मदद करना और अच्छा काम करना ही आपके प्यार जताने का तरीका है; अपने आप को कम कोसना — यही आपको सीखना है।',
  'आप हर चीज़ में संतुलन, सुंदरता और इंसाफ़ ढूँढ़ते हैं। आपके रिश्ते आपके लिए एक आईने की तरह हैं; फ़ैसले लेने की ताकत — यही आपको अपने अंदर बढ़ानी है।',
  'आप गहरे और अपने में सिमटे रहने वाले हैं। हर चीज़ को दिल से गहराई तक महसूस करते हैं, और उसी से गुज़रकर बदलते और बढ़ते हैं। ताकत, भरोसा और सच्चाई — यही आपकी ज़िंदगी के बड़े विषय हैं।',
  'मन से आप एक खोजी हैं, हमेशा मतलब, आज़ादी और दूर के क्षितिज की ओर बढ़ते रहते हैं। आपका विश्वास आपको आगे ले जाता है; थोड़ी एकाग्रता उस विश्वास को असली समझदारी में बदल देती है।',
  'आप अनुशासित हैं और लंबी दौड़ के इंसान हैं, जिम्मेदारी और समय के बल पर एक-एक कदम ऊपर चढ़ते हैं। आपकी महत्वाकांक्षा सच्ची है — थोड़ी गर्मजोशी बनाए रखना ही शिखर को पाने लायक बनाता है।',
  'आप स्वतंत्र हैं और भविष्य की ओर देखते हैं, बड़ी व्यवस्थाओं और आदर्शों के हिसाब से सोचते हैं। आप चंद लोगों के नहीं, सबके हैं; किसी एक के साथ गहरी नज़दीकी — वहीं आपको अपने आप को फैलाना है।',
  'आप संवेदनशील और खुले दिल के हैं, और अपने तथा दुनिया के बीच की लकीर अक्सर मिट जाती है। करुणा और कल्पना आपके तोहफ़े हैं; ज़मीन पर टिके रहना — यही आपके लिए अभ्यास है।',
];

/// Emotional nature by Moon sign, 0 = Aries .. 11 = Pisces.
const soulByMoon = <String>[
  'Deep down you need action and honesty. Your feelings come on fast and pass just as fast.',
  'You long for stability and comfort — a calm, loyal heart that settles in deeply once it commits to someone.',
  'Your mind and your mood move together; you work through your feelings by talking them out and understanding them.',
  'You\'re deeply caring and you take everything in. Home and a sense of belonging are where your heart truly rests.',
  'You have a warm, proud heart — you feel safest when you\'re seen, appreciated and openly loved.',
  'You calm yourself down by keeping order and being useful; you examine your feelings first before you trust them.',
  'Peace and harmony steady you, and conflict throws you off; you feel your best in fair, gentle company.',
  'You feel things with rare depth and intensity — guarded on the outside, but completely all-in underneath.',
  'You have a hopeful, freedom-loving heart; you need space, meaning, and something to believe in.',
  'You\'re self-contained and responsible with your emotions; you show love through being reliable more than through words.',
  'You feel through ideas and friendship — a cool surface over a warm, caring heart that wants to help everyone.',
  'You have a tender heart that soaks everything up, feeling other people\'s moods as if they were your own; quiet time alone and art bring you back to yourself.',
];

/// Hindi — emotional nature by Moon sign, 0 = Aries .. 11 = Pisces.
const soulByMoonHi = <String>[
  'दिल से आपको काम और सच्चाई चाहिए; भावनाएँ तेज़ी से आती हैं और तेज़ी से चली भी जाती हैं।',
  'आप ठहराव और सुकून चाहते हैं — एक शांत, वफ़ादार दिल जो किसी से जुड़ने के बाद गहराई से बस जाता है।',
  'आपका मन और आपका मूड साथ-साथ चलते हैं; आप अपनी भावनाओं को बातचीत और समझ के ज़रिए सुलझाते हैं।',
  'आप गहराई से ख़याल रखने वाले हैं और हर चीज़ को अपने अंदर उतार लेते हैं; घर और अपनापन वहीं हैं जहाँ आपका दिल सुकून पाता है।',
  'आपका दिल गर्मजोश और स्वाभिमानी है — आप तब सबसे महफ़ूज़ महसूस करते हैं जब आपको देखा, सराहा और खुलकर प्यार किया जाए।',
  'आप हर चीज़ को व्यवस्थित रखकर और काम आकर अपने आप को शांत करते हैं; भावनाओं पर भरोसा करने से पहले आप उन्हें परखते हैं।',
  'शांति और तालमेल आपको स्थिर रखते हैं और झगड़ा आपको विचलित कर देता है; आप न्यायप्रिय, कोमल संगति में सबसे अच्छा महसूस करते हैं।',
  'आप हर चीज़ को अनोखी गहराई और तीव्रता से महसूस करते हैं — ऊपर से संभले हुए, पर अंदर से पूरी तरह डूबे हुए।',
  'आपका दिल उम्मीद से भरा और आज़ादी पसंद है; आपको खुली जगह, मतलब और भरोसा करने के लिए कोई चीज़ चाहिए।',
  'आप अपनी भावनाओं में आत्मनिर्भर और जिम्मेदार हैं; आप शब्दों से ज़्यादा भरोसेमंद बनकर प्यार जताते हैं।',
  'आप विचारों और दोस्ती के ज़रिए महसूस करते हैं — एक शांत ऊपरी सतह के नीचे एक स्नेही दिल जो सबका भला चाहता है।',
  'आपका दिल कोमल है और सब कुछ सोख लेता है, दूसरों के मूड को अपना बना लेता है; अकेले में बिताया शांत समय और कला आपको फिर से ताज़ा कर देते हैं।',
];

/// Core identity / vitality by Sun sign, 0 = Aries .. 11 = Pisces.
const soulBySun = <String>[
  'At your very core you\'re a trailblazer — bold, self-starting, and happiest when you\'re carving out your own path.',
  'Deep down you\'re steady and down-to-earth; you shine by building things that last.',
  'You have a quick, all-rounder spirit — you come alive through ideas, words and plenty of variety.',
  'Who you are is rooted in caring and belonging; you lead with your heart and your memories.',
  'You have a natural glow and dignity about you; you\'re here to express yourself, create, and be seen.',
  'You define yourself through your skill and your service to others; getting the details just right is your signature.',
  'You grow into yourself through your relationships and a sense of fairness; you shine by creating harmony.',
  'You have an intense, private core with huge willpower; you\'re built for depth and for change.',
  'You have a seeker\'s soul — meaning, freedom and truth are the fuel that drives who you are.',
  'Deep down you\'re about purpose and mastery; you earn your light through taking responsibility.',
  'You define yourself by your ideals and by what makes you different — you\'re here to serve everyone, not just yourself.',
  'You have a gentle, imaginative core; your purpose flows through compassion and the things you can\'t quite see.',
];

/// Hindi — core identity / vitality by Sun sign, 0 = Aries .. 11 = Pisces.
const soulBySunHi = <String>[
  'आपके एकदम भीतर एक राह बनाने वाला बसा है — निडर, ख़ुद से शुरू करने वाला, और अपना रास्ता ख़ुद बनाने में सबसे खुश।',
  'दिल से आप शांत और ज़मीन से जुड़े हैं; आप ऐसी चीज़ें बनाकर चमकते हैं जो टिकाऊ हों।',
  'आपमें एक फुर्तीली, हर काम में माहिर रूह है — आप विचारों, शब्दों और तरह-तरह की चीज़ों से जी उठते हैं।',
  'आप जो हैं वह देखभाल और अपनेपन में बसा है; आप अपने दिल और अपनी यादों से आगे बढ़ते हैं।',
  'आपमें एक कुदरती चमक और वक़ार है; आप ख़ुद को जताने, कुछ रचने और देखे जाने के लिए बने हैं।',
  'आप अपने हुनर और दूसरों की सेवा से अपनी पहचान बनाते हैं; बारीकियों को ठीक-ठीक कर देना ही आपकी पहचान है।',
  'आप अपने रिश्तों और इंसाफ़ के भाव से ख़ुद में निखरते हैं; आप तालमेल बनाकर चमकते हैं।',
  'आपमें बहुत बड़ी इच्छाशक्ति वाला एक गहरा, अपने में सिमटा भीतरी रूप है; आप गहराई और बदलाव के लिए बने हैं।',
  'आपमें एक खोजी की रूह है — मतलब, आज़ादी और सच्चाई ही आपकी पहचान का ईंधन हैं।',
  'दिल से आप मक़सद और महारत के बारे में हैं; आप जिम्मेदारी उठाकर अपनी चमक अर्जित करते हैं।',
  'आप अपने आदर्शों और अपने अनोखेपन से ख़ुद को पहचानते हैं — आप सिर्फ़ अपने लिए नहीं, सबकी सेवा के लिए बने हैं।',
  'आपमें एक कोमल, कल्पनाशील भीतरी रूप है; आपका मक़सद करुणा और उन चीज़ों के ज़रिए बहता है जो नज़र नहीं आतीं।',
];

/// Maha Dasha reading by ruling planet.
const dashaByLord = <String, String>{
  'sun': 'Power, identity, recognition and willpower move right to the centre of your life. These years ask you to step fully into your own light — to lead, to be seen, and to build something that carries your name. All of this plays out through your sense of who you are, your health, and how you carry yourself, so big shifts in your identity are common. Pride is both the gift and the trap here: handle it wisely and it lifts you up; let it run wild and it leaves you alone.',
  'moon': 'Feelings, home, family and the public come to the front, and life turns more inward and more about your relationships. Your mind gets sensitive and takes everything in — caring for others and being cared for both matter a great deal now. Comfort, belonging and feeling emotionally safe quietly shape your choices, and your luck rises and falls like the tides. The work is to steady your mind so that passing moods don\'t drive lasting decisions.',
  'mars': 'Drive, courage, initiative and raw energy come surging up — this is a time to act, compete, build and defend. You feel bolder and more impatient, ready to push through obstacles that used to stop you. Handled well, this brings real achievement, leadership and strength; handled badly, it spills over into anger, haste, accidents and conflict. The skill is disciplined action — force, but with a cool head.',
  'mercury': 'Thinking, communication, learning and business all speed up, and the pace of life quickens. Opportunities come through words, ideas, deals, networking and skill, and being able to adapt becomes your biggest strength. It\'s a rich time for study, writing, business, and any work that connects minds and markets. The risk is spreading yourself too thin — too many threads, too much talk — so choose focus over just being clever.',
  'jupiter': 'Growth, wisdom, opportunity and grace open up your world. Teachers, mentors and well-wishers show up, doors open more easily, and faith carries you forward. It favours higher study, teaching, advising, finance, family and matters of dharma, and often brings prosperity and respect. The one thing to watch is overdoing it — too much optimism and stretching yourself too far can undo the blessing.',
  'venus': 'Love, beauty, comfort, art and relationships come to the front and sweeten your life. Romance, partnership, pleasure and the finer things flow more easily, and your sense of harmony grows deeper. It favours art, design, luxury, hospitality and everything to do with relationships, and material comforts tend to increase. The lesson is balance — enjoy without overdoing it, and don\'t mistake comfort or attraction for real commitment.',
  'saturn': 'Discipline, responsibility, endurance and playing the long game define this long, serious stretch. Saturn tests what\'s real and strips away what isn\'t, rewarding patience and honest effort while dissolving every shortcut. Progress feels slow and hard-won, but whatever you build now lasts. Carry the weight without letting your heart go hard, and this becomes the chapter of life that matures you the most.',
  'rahu': 'Ambition, hunger, newness and the unconventional pull hard, and life can move in sudden, dramatic leaps. Foreign lands, new fields, technology and offbeat paths open up, often bringing a fast rise — and just as sudden a fall. Your desires get magnified, so the same drive that lifts you can also lead you astray. Stay honest and grounded, and let your ambition serve something bigger than just your appetite.',
  'ketu': 'A turning inward — the material world loosens its grip and your spiritual insight deepens. You may feel detached from goals that once gripped you, drawn instead toward solitude, research, healing or the search for meaning. Endings that come now usually clear the way for freedom rather than causing harm. The invitation is to let go rather than hold on tight, and to look for the real essence behind how things appear.',
};

/// Hindi — Maha Dasha reading by ruling planet.
const dashaByLordHi = <String, String>{
  'sun': 'ताकत, पहचान, सम्मान और इच्छाशक्ति आपकी ज़िंदगी के बिल्कुल बीचोंबीच आ जाते हैं। ये साल आपसे अपने भीतर की रोशनी में पूरी तरह उतरने को कहते हैं — आगे बढ़कर लीडरशिप करने, देखे जाने और ऐसा कुछ बनाने को जिससे आपका नाम जुड़े। यह सब आपके आत्मबोध, सेहत और आपके पेश आने के तरीके से ज़ाहिर होता है, इसलिए पहचान के स्तर पर बड़े बदलाव आम हैं। यहाँ अभिमान वरदान भी है और जाल भी: समझदारी से संभालें तो यह आपको ऊपर उठाता है, बेकाबू छोड़ दें तो अकेला कर देता है।',
  'moon': 'भावनाएँ, घर, परिवार और लोग सामने आ जाते हैं, और ज़िंदगी ज़्यादा भीतरी और रिश्तों वाली हो जाती है। मन संवेदनशील हो उठता है और हर चीज़ अपने अंदर उतार लेता है — दूसरों का ख़याल रखना और ख़ुद ख़याल पाना, दोनों अभी बहुत मायने रखते हैं। सुकून, अपनापन और भावनात्मक सुरक्षा चुपचाप आपके फ़ैसलों को आकार देते हैं, और किस्मत ज्वार-भाटे की तरह उठती-गिरती है। काम यह है कि मन को स्थिर रखें ताकि पल भर की मनोदशाएँ बड़े फ़ैसलों को न मोड़ दें।',
  'mars': 'हिम्मत, पहल, जोश और कच्ची ऊर्जा उमड़ पड़ती है — यह करने, मुक़ाबला करने, बनाने और बचाव करने का समय है। आप ज़्यादा निडर और बेसब्र महसूस करते हैं, उन रुकावटों को पार करने को तैयार जो कभी आपको रोकती थीं। ठीक से संभालें तो यह असली कामयाबी, लीडरशिप और ताकत लाता है; बिगड़ जाए तो गुस्से, हड़बड़ी, दुर्घटनाओं और झगड़े में बदल जाता है। हुनर है काबू में रखकर काम करना — ताकत, पर ठंडे दिमाग के साथ।',
  'mercury': 'सोच, बातचीत, पढ़ाई और व्यापार में तेज़ी आती है, और ज़िंदगी की रफ़्तार बढ़ जाती है। शब्दों, विचारों, सौदों, जान-पहचान और हुनर के ज़रिए मौके आते हैं, और हालात के हिसाब से ढल जाना आपकी सबसे बड़ी पूँजी बन जाता है। यह पढ़ाई, लेखन, व्यापार और मन तथा बाज़ार को जोड़ने वाले हर काम के लिए बढ़िया समय है। ख़तरा है ख़ुद को बिखेर देने का — बहुत सारे काम, बहुत सारी बातें — इसलिए सिर्फ़ चतुराई के बजाय एकाग्रता चुनें।',
  'jupiter': 'तरक़्क़ी, समझदारी, मौके और कृपा आपकी दुनिया को फैला देते हैं। गुरु, मार्गदर्शक और शुभचिंतक सामने आते हैं, दरवाज़े आसानी से खुलते हैं, और विश्वास आपको आगे ले जाता है। यह ऊँची पढ़ाई, पढ़ाने, सलाह देने, वित्त, परिवार और धर्म के मामलों के लिए अच्छा है, और अक्सर समृद्धि तथा सम्मान लाता है। बस एक बात का ध्यान रखें — हद से ज़्यादा उम्मीद और ख़ुद को बहुत ज़्यादा खींच लेना इस आशीर्वाद को बिगाड़ सकते हैं।',
  'venus': 'प्रेम, सुंदरता, सुकून, कला और रिश्ते सामने आ जाते हैं और ज़िंदगी में मिठास घुल जाती है। प्यार, साझेदारी, आनंद और सुंदर चीज़ें आसानी से आती हैं, और आपकी तालमेल की भावना गहरी होती है। यह कला, डिज़ाइन, ऐशो-आराम, आतिथ्य और रिश्तों वाले हर काम के लिए अच्छा है, और भौतिक सुख बढ़ने लगते हैं। सीख है संतुलन की — आनंद लें पर हद से न बढ़ें, और सुख या आकर्षण को सच्ची प्रतिबद्धता न समझ बैठें।',
  'saturn': 'अनुशासन, जिम्मेदारी, सहनशक्ति और लंबी दौड़ खेलना — यही इस लंबे, गंभीर दौर की पहचान हैं। शनि परखता है कि क्या असली है और जो नहीं है उसे हटा देता है, धैर्य और ईमानदार मेहनत को इनाम देता है जबकि हर शॉर्टकट को गला देता है। तरक़्क़ी धीमी और मेहनत से हासिल लगती है, पर जो आप अभी बनाते हैं वह टिकता है। दिल को पत्थर बनाए बिना यह बोझ उठाएँ, और यह आपकी ज़िंदगी का सबसे ज़्यादा परिपक्व करने वाला अध्याय बन जाएगा।',
  'rahu': 'महत्वाकांक्षा, भूख, नयापन और लीक से हटकर चीज़ों का ज़ोरदार खिंचाव रहता है, और ज़िंदगी अचानक, नाटकीय छलांगों में बढ़ सकती है। विदेश, नए क्षेत्र, तकनीक और अनोखे रास्ते खुलते हैं, जो अक्सर तेज़ उठान लाते हैं — और उतनी ही अचानक गिरावट भी। आपकी इच्छाएँ बड़ी हो जाती हैं, इसलिए जो जोश आपको ऊपर उठाता है वही भटका भी सकता है। ईमानदार और ज़मीन पर टिके रहें, और अपनी महत्वाकांक्षा को अपनी भूख से बड़े किसी मक़सद की सेवा में लगाएँ।',
  'ketu': 'एक भीतर की ओर मुड़ता मोड़ — भौतिक दुनिया की पकड़ ढीली होती है और आध्यात्मिक समझ गहरी होती है। जो लक्ष्य कभी आपको जकड़े रहते थे उनसे आप अलग-सा महसूस कर सकते हैं, इसके बजाय एकांत, शोध, उपचार या मतलब की खोज की ओर खिंचते हैं। इस समय आने वाले अंत अक्सर नुकसान के बजाय आज़ादी का रास्ता खोलते हैं। बुलावा यह है कि पकड़ने के बजाय छोड़ना सीखें, और चीज़ों के दिखावे के पीछे के असली सार को खोजें।',
};

/// A short italic flavour note for the running Maha Dasha.
const dashaFlavorByLord = <String, String>{
  'sun': 'A time to be seen and to lead; ambition and pride both surge — sudden openings appear, but so does the pull to bite off more than you can chew.',
  'moon': 'Emotions, home and the people around you come alive; comfort and connection matter, yet moods can pull you off course.',
  'mars': 'Energy and courage run high — a time to push forward and build. Watch out for haste, a short temper and burning out.',
  'mercury': 'The mind speeds up and doors open through words and deals; just keep the many threads from scattering into noise.',
  'jupiter': 'Growth, luck and grace open up your world; teachers and opportunity show up — but watch for getting complacent or overdoing it.',
  'venus': 'Love, beauty and pleasure blossom; relationships and comforts sweeten life — balance enjoyment with real commitment.',
  'saturn': 'A long, serious stretch of work and testing; slow but lasting rewards — patience beats shortcuts here.',
  'rahu': 'Ambition and offbeat paths pull hard; foreign, new or sudden roads open — stay honest even as the hunger grows.',
  'ketu': 'A turning inward; the material world loosens its grip and spiritual insight deepens — let go rather than hold on tight.',
};

/// Hindi — short flavour note for the running Maha Dasha.
const dashaFlavorByLordHi = <String, String>{
  'sun': 'देखे जाने और लीडरशिप करने का समय; महत्वाकांक्षा और अभिमान दोनों उमड़ते हैं — अचानक मौके खुलते हैं, पर हद से ज़्यादा कर बैठने का खिंचाव भी।',
  'moon': 'भावनाएँ, घर और आसपास के लोग जी उठते हैं; सुकून और जुड़ाव मायने रखते हैं, फिर भी मनोदशाएँ आपको राह से भटका सकती हैं।',
  'mars': 'ऊर्जा और हिम्मत चरम पर — आगे बढ़ने और बनाने का समय। हड़बड़ी, गुस्से और थककर चूर होने से सावधान रहें।',
  'mercury': 'मन तेज़ होता है और शब्दों तथा सौदों से दरवाज़े खुलते हैं; बस अनेक कामों को शोर में बिखरने न दें।',
  'jupiter': 'तरक़्क़ी, किस्मत और कृपा आपकी दुनिया को फैला देते हैं; गुरु और मौके आते हैं — पर आत्मसंतोष और अति से बचें।',
  'venus': 'प्रेम, सुंदरता और आनंद खिलते हैं; रिश्ते और सुख ज़िंदगी में मिठास घोलते हैं — आनंद को सच्ची प्रतिबद्धता से संतुलित करें।',
  'saturn': 'काम और परीक्षा का एक लंबा, गंभीर दौर; धीमे पर टिकाऊ फल — यहाँ धैर्य शॉर्टकट को मात देता है।',
  'rahu': 'महत्वाकांक्षा और लीक से हटकर चीज़ों का ज़ोरदार खिंचाव; विदेशी, नए या अचानक रास्ते खुलते हैं — भूख के बीच भी ईमानदार बने रहें।',
  'ketu': 'एक भीतर की ओर मुड़ता मोड़; भौतिक चीज़ों की पकड़ ढीली होती है और आध्यात्मिक समझ गहरी होती है — पकड़ने के बजाय छोड़ें।',
};

/// "What to do" during the running Maha Dasha.
const dashaDoByLord = <String, String>{
  'sun': 'Build legitimate authority through consistent work. Honour your elders and superiors. Show up where you genuinely matter.',
  'moon': 'Nurture your mind and close relationships. Keep a peaceful home base. Trust your intuition and protect your health.',
  'mars': 'Channel energy into disciplined action and exercise. Take initiative on bold goals. Defend what is right — calmly.',
  'mercury': 'Learn, network and communicate. Put ideas into writing and deals into order. Stay curious and organised.',
  'jupiter': 'Seek teachers, study and give generously. Say yes to genuine opportunity. Act on your values and faith.',
  'venus': 'Invest in relationships, beauty and art. Enjoy life\'s pleasures in balance. Cultivate harmony and refinement.',
  'saturn': 'Commit to steady, honest work. Take responsibility and be patient. Serve others and simplify your life.',
  'rahu': 'Pursue bold, unconventional goals with integrity. Embrace new fields and foreign links. Stay grounded and ethical.',
  'ketu': 'Turn inward through meditation and study. Release what no longer serves. Seek meaning over things.',
};

/// Hindi — "What to do" during the running Maha Dasha.
const dashaDoByLordHi = <String, String>{
  'sun': 'निरंतर कर्म से वैध अधिकार अर्जित करें। अपने बड़ों और वरिष्ठों का सम्मान करें। वहाँ उपस्थित रहें जहाँ आप वास्तव में मायने रखते हैं।',
  'moon': 'अपने मन और निकट संबंधों का पोषण करें। एक शांतिपूर्ण घर बनाए रखें। अपने अंतर्ज्ञान पर भरोसा करें और अपने स्वास्थ्य की रक्षा करें।',
  'mars': 'ऊर्जा को अनुशासित कर्म और व्यायाम में लगाएँ। साहसी लक्ष्यों पर पहल करें। जो सही है उसकी — शांति से — रक्षा करें।',
  'mercury': 'सीखें, संपर्क बनाएँ और संवाद करें। विचारों को लेखन में और सौदों को व्यवस्था में उतारें। जिज्ञासु और सुव्यवस्थित रहें।',
  'jupiter': 'गुरुओं और अध्ययन को खोजें और उदारता से दान दें। सच्चे अवसर को हाँ कहें। अपने मूल्यों और श्रद्धा पर कार्य करें।',
  'venus': 'संबंधों, सौंदर्य और कला में निवेश करें। जीवन के सुखों का संतुलित आनंद लें। सामंजस्य और परिष्कार विकसित करें।',
  'saturn': 'स्थिर, ईमानदार कर्म के प्रति प्रतिबद्ध रहें। जिम्मेदारी लें और धैर्य रखें। दूसरों की सेवा करें और अपने जीवन को सरल बनाएँ।',
  'rahu': 'साहसी, अपरंपरागत लक्ष्यों को सत्यनिष्ठा से पाएँ। नए क्षेत्रों और विदेशी संपर्कों को अपनाएँ। धरातल पर और नैतिक बने रहें।',
  'ketu': 'ध्यान और अध्ययन के माध्यम से अंतर्मुखी हों। जो अब उपयोगी नहीं उसे छोड़ें। वस्तुओं से अधिक अर्थ को खोजें।',
};

/// "What to avoid" during the running Maha Dasha.
const dashaAvoidByLord = <String, String>{
  'sun': 'Avoid ego clashes, face-saving in public, isolating yourself from advisors, and decisions made from wounded pride.',
  'moon': 'Avoid emotional over-reaction, clinging and neglecting rest. Don\'t let passing moods drive major decisions.',
  'mars': 'Avoid haste, anger, reckless risk and needless conflict. Don\'t burn bridges — or your own health.',
  'mercury': 'Avoid scattering your focus, over-talking and cutting corners. Don\'t trust cleverness over honesty.',
  'jupiter': 'Avoid over-optimism, excess and self-righteousness. Don\'t over-promise or overextend.',
  'venus': 'Avoid overindulgence, vanity and escapism. Don\'t mistake comfort or attraction for commitment.',
  'saturn': 'Avoid shortcuts, despair and rigidity. Don\'t resent the delays — they are teaching patience.',
  'rahu': 'Avoid greed, deception and obsession. Don\'t chase shortcuts or trade away your ethics for ambition.',
  'ketu': 'Avoid confusion, escapism and neglecting the practical. Don\'t detach so far that duties slip.',
};

/// Hindi — "What to avoid" during the running Maha Dasha.
const dashaAvoidByLordHi = <String, String>{
  'sun': 'अहंकार के टकराव, सार्वजनिक रूप से इज़्ज़त बचाने, सलाहकारों से दूरी बनाने और आहत अभिमान से लिए गए निर्णयों से बचें।',
  'moon': 'भावनात्मक अति-प्रतिक्रिया, चिपकाव और विश्राम की उपेक्षा से बचें। क्षणिक मनोदशाओं को बड़े निर्णय न चलाने दें।',
  'mars': 'हड़बड़ी, क्रोध, लापरवाह जोखिम और व्यर्थ टकराव से बचें। न रिश्ते जलाएँ — न अपना स्वास्थ्य।',
  'mercury': 'ध्यान बिखेरने, अधिक बोलने और शॉर्टकट अपनाने से बचें। ईमानदारी से ऊपर चतुराई पर भरोसा न करें।',
  'jupiter': 'अत्यधिक आशावाद, अति और आत्म-धार्मिकता से बचें। न अधिक वादे करें, न सीमा से आगे बढ़ें।',
  'venus': 'अति-भोग, दिखावे और पलायन से बचें। सुख या आकर्षण को प्रतिबद्धता न समझ बैठें।',
  'saturn': 'शॉर्टकट, निराशा और कठोरता से बचें। देरी से नाराज़ न हों — वे धैर्य सिखा रही हैं।',
  'rahu': 'लालच, छल और जुनून से बचें। शॉर्टकट के पीछे न भागें और महत्वाकांक्षा के लिए अपनी नैतिकता का सौदा न करें।',
  'ketu': 'भ्रम, पलायन और व्यावहारिकता की उपेक्षा से बचें। इतना विरक्त न हों कि कर्तव्य छूट जाएँ।',
};

/// Life-area guidance for the running Maha Dasha, keyed by planet then area.
const lifeAreaLabels = ['Career', 'Relationships', 'Health', 'Wealth'];
const lifeAreaByLord = <String, List<String>>{
  'sun': [
    'A time of being seen, gaining power and moving up — leadership roles, promotions and public recognition come more easily. Work tied to government, well-established institutions or your own name suits you best. Let your results speak louder than your ego, and steer clear of clashes with those above you.',
    'Your confidence rises and you naturally take charge, but partners can feel overshadowed if you dominate the room. Your bond with father figures and people in authority comes into focus. Listen as much as you shine, and share the spotlight.',
    'Your energy is usually strong, but the Sun rules the heart, the eyes and your overall vitality — so keep an eye on blood pressure, your eyes, and exhaustion from stress. When it\'s well-placed you feel sturdy; if it\'s weak, take care ahead of time and don\'t run on pride alone.',
    'Your income tends to come through authority-linked roles, government or institutions, along with a pull to spend on things that show status. Your wealth grows fastest when you put money into lasting assets rather than into image.',
  ],
  'moon': [
    'Work that faces the public, involves caring for people, or keeps changing suits you — people, the public, food, hospitality or the home. Your fortunes rise and fall in cycles, so ride the tides instead of fighting them. Your reputation and the public mood matter more than usual.',
    'Emotional closeness, family and your mother come to the centre, and tenderness deepens your bonds. Moods can swing the relationship back and forth, so a sense of security and gentle reassurance keep it steady. Home is where the heart heals.',
    'Your mind, sleep, digestion and body fluids need care, and emotional stress shows up in your body quickly. Protect your rest and your inner balance, and good health follows.',
    'Your earnings are driven by comfort and can be a bit up and down. Your savings grow when you feel emotionally secure and shrink when anxiety pushes you into impulse spending — a calm mind is your best money asset.',
  ],
  'mars': [
    'Competitive, technical, physical or command-style fields reward your drive — engineering, the forces, sport, surgery or real estate. It\'s a strong time to take the initiative and lead from the front, but avoid rash moves and clashes at work.',
    'Passion runs hot — attraction is strong, and so is the chance of friction and impatience. Channel the fire into protecting and staying loyal rather than into arguments, give each other room, and pick your battles.',
    'Mars rules blood, muscles and heat — so watch for injuries, inflammation, fevers and accidents. Burn off the extra energy cleanly through exercise, or it turns into irritability and strain.',
    'Bold, decisive moves can pay off, and your earnings often come through effort, competition or property. But impulsive risks and anger-driven choices drain your wealth just as fast — act boldly, not rashly.',
  ],
  'mercury': [
    'Communication, trade, technology, analysis and writing flourish, and being a good all-rounder opens many doors. Networking, deals and skill-based work multiply your chances — just keep your many projects organised so your momentum isn\'t lost to scatter.',
    'Friendship, wit and good conversation are the glue of your bonds; you connect through shared ideas and humour. Keep your words kind and honest, since what you say can build people up or bruise them.',
    'Your nerves, skin, lungs and speech are sensitive, and an overactive mind brings restlessness or anxiety. Quiet the mental chatter through breathing, a steady routine and rest.',
    'Wealth comes through many small streams — skills, side-work, trade and networking rather than one big source. Being clever helps, but don\'t let it slide into cutting corners.',
  ],
  'jupiter': [
    'Teaching, advising, law, finance, medicine and growth-focused roles expand, often with recognition and mentorship. Your reputation and standing open doors — say yes to genuine opportunity, but don\'t stretch yourself too far on optimism alone.',
    'Generosity, shared values and mutual respect deepen your bonds, and relationships feel more meaningful. Elders, teachers and family blessings support you, and your patience makes you a steadying presence for everyone.',
    'Jupiter rules the liver, weight and metabolism — so watch for overindulging, putting on weight, and too much sugar. Keeping to moderation protects the naturally good health of this period.',
    'One of the best periods for wealth — your income grows on its own, and savings and investments tend to grow too. Give and invest wisely, and abundance tends to come back to you.',
  ],
  'venus': [
    'Art, design, beauty, luxury, hospitality and relationship-based work thrive, and your charm opens doors. Creative and people-facing roles are especially favoured, and your taste and diplomacy are real assets.',
    'Romance, harmony and pleasure blossom — love flows more easily and existing bonds sweeten, with marriage and partnership in the spotlight. Enjoy the closeness, but keep your devotion deeper than just attraction.',
    'Venus rules the reproductive system, the kidneys and the pull toward indulgence — so watch rich food, sugar and excess. Balance keeps you well and glowing.',
    'Comfort, beauty and luxury flow in, often through art, relationships or pleasant work. The temptation is to overspend on treats — enjoy yourself, but keep a cushion aside.',
  ],
  'saturn': [
    'Long, structured, service-oriented work suits you — you climb slowly but surely through discipline and endurance. Systems, hard work and administration reward you, and steady persistence beats raw brilliance in this chapter.',
    'Commitment matters more than romance now, and your bonds get tested by time, distance or duty. Loyalty, patience and simply showing up build lasting trust — whatever survives Saturn\'s testing is built to last.',
    'Saturn rules the bones, joints, teeth and long-running patterns — so expect slow-building issues that need steady care rather than quick fixes. Rest, routine and not overworking protect you.',
    'Wealth is slow, hard-earned and lasting — no windfalls, but steady security through discipline and saving. Avoid speculation; build patiently and it holds.',
  ],
  'rahu': [
    'Offbeat, foreign, technology-based or fast-rising fields open up, and sudden advancement is possible. Bold, boundary-pushing moves can leap you forward — keep your dealings clean, since shortcuts carry hidden costs.',
    'Attractions can be intense, unusual or unexpected, even across cultures or norms. Keep things clear and honest, since illusion and obsession are the shadow side — keep the intensity grounded in reality.',
    'Rahu brings anxiety, unusual or hard-to-diagnose complaints and nervous strain. Grounding habits — a routine, time in nature, breathing — steady your system more than medicine alone.',
    'Sudden gains and just as sudden losses mark this period, and your fortunes can swing sharply. Ambition can multiply your wealth or gamble it away — discipline and honesty are your safeguard.',
  ],
  'ketu': [
    'Research, spirituality, healing, investigation or behind-the-scenes work suits this inward time. Recognition matters less and depth matters more — you may quietly step back from the visible race.',
    'Detachment can create distance, and worldly bonds feel less gripping. Being present and putting in effort are the practice — stay engaged rather than drifting away, and spiritual company nourishes you most.',
    'Ketu brings subtle, mysterious or wrongly-diagnosed ailments and affects the nervous system. Deep rest, simplicity and spiritual practice restore you.',
    'Money feels like a side matter and can be unpredictable, coming and going without much attachment. Simplicity serves you well; clinging brings unease rather than security.',
  ],
};

/// Hindi — life-area guidance for the running Maha Dasha, keyed by planet.
const lifeAreaLabelsHi = ['करियर', 'संबंध', 'स्वास्थ्य', 'धन'];
const lifeAreaByLordHi = <String, List<String>>{
  'sun': [
    'देखे जाने, ताकत पाने और आगे बढ़ने का समय — लीडरशिप की भूमिकाएँ, तरक़्क़ी और लोगों में सम्मान आसानी से आते हैं। सरकार, जमे-जमाए संस्थानों या अपने ख़ुद के नाम से जुड़ा काम आपके लिए सबसे बढ़िया है। अपने अहं से ज़्यादा अपने नतीजों को बोलने दें, और अपने से ऊपर वालों से टकराव से बचें।',
    'आपका आत्मविश्वास बढ़ता है और आप अपने आप कमान संभाल लेते हैं, पर अगर आप हावी हो जाएँ तो साथी दबे हुए महसूस कर सकते हैं। पिता जैसे और अधिकार वाले लोगों से आपका रिश्ता सामने आता है। जितना चमकें उतना सुनें भी, और मंच साझा करें।',
    'आपकी ऊर्जा आम तौर पर मज़बूत रहती है, फिर भी सूर्य दिल, आँखों और आपकी कुल ताकत का कारक है — इसलिए रक्तचाप, आँखों और तनाव से आने वाली थकान पर ध्यान दें। अच्छी स्थिति में आप ताक़तवर महसूस करते हैं; कमज़ोर हो तो पहले से देखभाल करें और सिर्फ़ अभिमान के बल पर न चलें।',
    'आपकी आय अक्सर अधिकार से जुड़ी भूमिकाओं, सरकार या संस्थानों के ज़रिए आती है, और रुतबा दिखाने वाली चीज़ों पर खर्च करने का खिंचाव रहता है। धन तब सबसे तेज़ी से बढ़ता है जब आप दिखावे के बजाय टिकाऊ संपत्तियों में पैसा लगाते हैं।',
  ],
  'moon': [
    'लोगों के सामने आने वाला, देखभाल वाला या बदलता रहने वाला काम आपके लिए अच्छा है — लोग, जनता, भोजन, आतिथ्य या घर से जुड़ा। आपकी किस्मत चक्रों में उठती-गिरती है, इसलिए धारा से लड़ने के बजाय ज्वार के साथ बहें। आपकी साख और लोगों का मिज़ाज आम से ज़्यादा मायने रखते हैं।',
    'भावनात्मक नज़दीकी, परिवार और आपकी माँ केंद्र में आ जाते हैं, और कोमलता आपके रिश्तों को गहरा करती है। मनोदशाएँ रिश्ते को इधर-उधर झुला सकती हैं, इसलिए सुरक्षा का भाव और कोमल तसल्ली उसे स्थिर रखते हैं। घर वहीं है जहाँ दिल भरता है।',
    'आपके मन, नींद, पाचन और शरीर के तरल पदार्थों को देखभाल चाहिए, और भावनात्मक तनाव जल्दी ही शरीर में दिखने लगता है। अपने आराम और भीतरी संतुलन की रक्षा करें, अच्छी सेहत साथ चलेगी।',
    'आपकी कमाई सुकून से चलती है और थोड़ी ऊपर-नीचे होती रहती है। बचत तब बढ़ती है जब आप भावनात्मक रूप से महफ़ूज़ महसूस करते हैं और तब घटती है जब चिंता आपसे बिना सोचे खर्च करा देती है — शांत मन ही आपकी सबसे अच्छी आर्थिक पूँजी है।',
  ],
  'mars': [
    'मुक़ाबले वाले, तकनीकी, शारीरिक या कमान वाले क्षेत्र आपके जोश को इनाम देते हैं — इंजीनियरिंग, सेना, खेल, सर्जरी या रियल एस्टेट। यह पहल करने और आगे से लीडरशिप करने का मज़बूत समय है, पर उतावले कदमों और काम की जगह के झगड़ों से बचें।',
    'जुनून तेज़ रहता है — आकर्षण भी प्रबल है, और उतनी ही टकराव तथा बेसब्री की गुंजाइश भी। इस आग को बहस के बजाय एक-दूसरे को बचाने और वफ़ादारी में लगाएँ, एक-दूसरे को जगह दें, और अपनी लड़ाइयाँ सोच-समझकर चुनें।',
    'मंगल ख़ून, माँसपेशियों और गर्मी का स्वामी है — इसलिए चोट, सूजन, बुख़ार और दुर्घटनाओं पर ध्यान दें। फ़ालतू ऊर्जा को व्यायाम से साफ़-सुथरे तरीके से जला दें, वरना यह चिड़चिड़ाहट और तनाव में बदल जाती है।',
    'साहसी, पक्के फ़ैसले फल दे सकते हैं, और कमाई अक्सर मेहनत, मुक़ाबले या संपत्ति से आती है। पर बिना सोचे लिए जोखिम और गुस्से में लिए फ़ैसले धन को उतनी ही तेज़ी से बहा देते हैं — साहसी बनें, उतावले नहीं।',
  ],
  'mercury': [
    'बातचीत, व्यापार, तकनीक, विश्लेषण और लेखन फलते-फूलते हैं, और हर काम में माहिर होना कई दरवाज़े खोलता है। जान-पहचान, सौदे और हुनर वाला काम आपके मौके बढ़ाते हैं — बस अपने कई कामों को व्यवस्थित रखें ताकि रफ़्तार बिखराव में न खो जाए।',
    'दोस्ती, हँसी-मज़ाक और अच्छी बातचीत आपके रिश्तों का गोंद हैं; आप साझा विचारों और विनोद से जुड़ते हैं। अपने शब्दों को दयालु और सच्चा रखें, क्योंकि आपकी बात किसी को बना भी सकती है और चोट भी पहुँचा सकती है।',
    'आपके स्नायु, त्वचा, फेफड़े और वाणी संवेदनशील रहते हैं, और बहुत ज़्यादा दौड़ता मन बेचैनी या चिंता लाता है। श्वास, एक स्थिर दिनचर्या और आराम से मन के शोर को शांत करें।',
    'धन कई छोटी धाराओं से आता है — हुनर, अतिरिक्त काम, व्यापार और जान-पहचान, न कि किसी एक बड़े स्रोत से। चतुराई मददगार है, पर उसे शॉर्टकट में न फिसलने दें।',
  ],
  'jupiter': [
    'पढ़ाना, सलाह देना, विधि, वित्त, चिकित्सा और तरक़्क़ी वाली भूमिकाएँ फैलती हैं, अक्सर सम्मान और मार्गदर्शन के साथ। आपकी साख और रुतबा दरवाज़े खोलते हैं — सच्चे मौके को हाँ कहें, पर सिर्फ़ उम्मीद के भरोसे ख़ुद को बहुत ज़्यादा न खींचें।',
    'दरियादिली, साझा मूल्य और आपसी सम्मान आपके रिश्तों को गहरा करते हैं, और रिश्ते ज़्यादा सार्थक लगते हैं। बड़े-बुज़ुर्ग, गुरु और परिवार का आशीर्वाद आपका साथ देते हैं, और आपका धैर्य आपको सबके लिए एक स्थिर सहारा बना देता है।',
    'गुरु जिगर, वज़न और पाचन-क्रिया का स्वामी है — इसलिए ज़्यादा खाने, वज़न बढ़ने और शक्कर पर ध्यान दें। संयम रखना इस दौर की कुदरती अच्छी सेहत को बनाए रखता है।',
    'धन के लिए सबसे अच्छे दौरों में से एक — आपकी आय अपने आप बढ़ती है, और बचत तथा निवेश भी बढ़ते हैं। समझदारी से दें और निवेश करें, तो समृद्धि लौटकर आती है।',
  ],
  'venus': [
    'कला, डिज़ाइन, सुंदरता, ऐशो-आराम, आतिथ्य और रिश्तों वाला काम फलता-फूलता है, और आपका आकर्षण दरवाज़े खोलता है। रचनात्मक और लोगों के सामने वाली भूमिकाएँ ख़ास तौर पर अच्छी हैं, और आपकी रुचि तथा कूटनीति आपकी असली पूँजी हैं।',
    'प्रेम, तालमेल और आनंद खिलते हैं — प्यार ज़्यादा आसानी से बहता है और मौजूदा रिश्तों में मिठास घुलती है, विवाह और साझेदारी सुर्ख़ियों में रहते हैं। इस नज़दीकी का आनंद लें, पर अपने समर्पण को सिर्फ़ आकर्षण से गहरा रखें।',
    'शुक्र प्रजनन तंत्र, गुर्दों और भोग की ओर खिंचाव का स्वामी है — इसलिए गरिष्ठ भोजन, शक्कर और अति पर ध्यान दें। संतुलन आपको स्वस्थ और चमकदार बनाए रखता है।',
    'सुकून, सुंदरता और ऐशो-आराम भीतर आते हैं, अक्सर कला, रिश्तों या सुखद काम के ज़रिए। प्रलोभन है शौक़ पर ज़्यादा खर्च करने का — आनंद लें, पर एक बचत बचाकर रखें।',
  ],
  'saturn': [
    'लंबा, व्यवस्थित, सेवा वाला काम आपके लिए अच्छा है — आप अनुशासन और सहनशक्ति से धीरे पर पक्के तौर पर ऊपर चढ़ते हैं। व्यवस्था, मेहनत और प्रशासन आपको इनाम देते हैं, और इस अध्याय में लगातार लगे रहना कच्ची प्रतिभा को मात दे देता है।',
    'अभी रोमांस से ज़्यादा प्रतिबद्धता मायने रखती है, और आपके रिश्ते समय, दूरी या कर्तव्य से परखे जाते हैं। वफ़ादारी, धैर्य और बस साथ बने रहना स्थायी भरोसा बनाते हैं — जो शनि की परीक्षा से बच जाता है वही टिकने के लिए बना है।',
    'शनि हड्डियों, जोड़ों, दाँतों और लंबे समय से चली आ रही तकलीफ़ों का स्वामी है — इसलिए ऐसी धीरे-धीरे बढ़ने वाली समस्याओं की उम्मीद रखें जिन्हें जल्दी के उपाय के बजाय स्थिर देखभाल चाहिए। आराम, दिनचर्या और ज़रूरत से ज़्यादा काम न करना आपकी रक्षा करते हैं।',
    'धन धीमा, मेहनत से कमाया और टिकाऊ है — कोई अचानक लाभ नहीं, पर अनुशासन और बचत से स्थिर सुरक्षा। सट्टेबाज़ी से बचें; धैर्य से बनाएँ और यह टिका रहता है।',
  ],
  'rahu': [
    'लीक से हटकर, विदेशी, तकनीक वाले या तेज़ी से उभरते क्षेत्र खुलते हैं, और अचानक तरक़्क़ी मुमकिन है। साहसी, हदें लाँघने वाले कदम आपको आगे छलांग दिला सकते हैं — अपने लेन-देन साफ़ रखें, क्योंकि शॉर्टकट की एक छिपी क़ीमत होती है।',
    'आकर्षण तीव्र, अनोखे या अचानक हो सकते हैं, यहाँ तक कि अलग संस्कृतियों या रिवाज़ों के परे भी। चीज़ों को साफ़ और ईमानदार रखें, क्योंकि भ्रम और जुनून इसका छायापक्ष हैं — इस तीव्रता को हक़ीक़त में टिकाकर रखें।',
    'राहु चिंता, अनोखी या मुश्किल से पकड़ में आने वाली शिकायतें और स्नायविक तनाव लाता है। ज़मीन से जोड़ने वाली आदतें — दिनचर्या, प्रकृति में समय, श्वास — सिर्फ़ दवा से ज़्यादा आपके तंत्र को स्थिर करती हैं।',
    'अचानक लाभ और उतनी ही अचानक हानि इस दौर की पहचान हैं, और आपकी किस्मत तेज़ी से झूल सकती है। महत्वाकांक्षा आपके धन को कई गुना कर सकती है या जुए में गँवा सकती है — अनुशासन और ईमानदारी ही आपकी सुरक्षा हैं।',
  ],
  'ketu': [
    'शोध, आध्यात्म, उपचार, खोजबीन या पर्दे के पीछे का काम इस भीतरी समय के लिए अच्छा है। सम्मान कम और गहराई ज़्यादा मायने रखती है — आप चुपचाप इस दिखावटी दौड़ से पीछे हट सकते हैं।',
    'विरक्ति दूरी पैदा कर सकती है, और सांसारिक रिश्ते कम जकड़ने वाले लगते हैं। मौजूद रहना और मेहनत करना ही अभ्यास है — बहने के बजाय जुड़े रहें, और आध्यात्मिक संगति आपको सबसे ज़्यादा पोषण देती है।',
    'केतु सूक्ष्म, रहस्यमय या ग़लत पहचानी गई बीमारियाँ लाता है और स्नायुतंत्र को प्रभावित करता है। गहरा आराम, सादगी और आध्यात्मिक अभ्यास आपको फिर से तरोताज़ा कर देते हैं।',
    'धन एक साइड की बात लगती है और अप्रत्याशित हो सकती है, बिना ज़्यादा मोह के आती-जाती है। सादगी आपके काम आती है; पकड़कर रखना सुरक्षा के बजाय बेचैनी लाता है।',
  ],
};

/// Atmakaraka (soul significator) — the planet holding the soul's deepest
/// desire, its chief lesson, and its unfinished karma. Detailed by planet.
const atmakarakaByPlanet = <String, String>{
  'sun':
      'Your soul\'s main journey is about your own self, authority, and the courage to be seen. Your deepest wish is to realise your own light — to lead, to matter, to stand up for your truth. The lesson is to hold that power without pride, turning ego into genuine self-respect. In terms of karma, it touches your bond with your father and your sense of your own worth; the spiritual path here is knowing your own Self behind the personality (atma-jnana).',
  'moon':
      'Your soul is looking for emotional wholeness, belonging, and the ability to nurture. There\'s a deep pull toward your mother, your home and caring for others, and an equally deep need to feel safe. The lesson is emotional maturity — to feel things fully without being ruled by your moods, and to care for others without losing yourself. The path is bhakti and surrender to the divine feminine, where feeling turns into devotion.',
  'mars':
      'Your soul\'s path runs through courage, disciplined energy, and standing up for what is right. The wish is to assert yourself, to act, to protect and to win. The lesson is mastering your anger and impatience — putting your force into righteous, well-thought-out action rather than knee-jerk reaction. In terms of karma it involves conflict, competition and inner strength; the path is tapasya, the fearless discipline that turns raw power into real character.',
  'mercury':
      'Your soul learns through knowledge, communication and a fine eye for detail. The wish is to understand, to connect ideas, and to put the truth into clear words. The lesson is to move from being clever to being truly wise, and to steady a mind that loves to wander. In terms of karma it touches speech, learning and being adaptable; the path is study, mantra, and the quiet clarity that sees things exactly as they are.',
  'jupiter':
      'Your soul is looking for wisdom, meaning and dharma — the bigger why behind life. The wish is to grow, to teach, to bless and to lift others up. The lesson is to actually live your principles rather than just preach them, and to avoid the overdoing and self-righteousness that comfort can bring. The path is the grace of a guru and the study of scripture, where knowledge ripens into real wisdom.',
  'venus':
      'Your soul\'s journey is through love, relationship, beauty and devotion. Your deepest wish is union — harmony, refinement, and the sweetness of a real connection. The lesson is to love without needing to possess, and to find the sacred inside pleasure and relationships rather than being tied down by them. In terms of karma it involves partnership, desire and art; the path is bhakti, where love itself becomes the doorway to liberation.',
  'saturn':
      'Your soul\'s work is discipline, endurance, service and letting go. The wish is to build something lasting and to become free of depending on anyone or anything. The lesson is patience and acceptance — carrying responsibility and the delays of time without letting your heart go hard. In terms of karma, this is the very marker of karma itself; the path is renunciation and service — letting go of the fruits of your actions and finding freedom in doing your duty.',
};

/// Hindi — Atmakaraka (soul significator) by planet.
const atmakarakaByPlanetHi = <String, String>{
  'sun':
      'आपकी आत्मा की मुख्य यात्रा आपके अपने आप, अधिकार और देखे जाने के साहस से जुड़ी है। सबसे गहरी चाह है अपने भीतर की रोशनी को साकार करना — लीडरशिप करना, महत्व रखना, अपने सच पर टिके रहना। सीख यह है कि उस ताकत को अभिमान के बिना संभालें, अहं को सच्चे आत्म-सम्मान में बदलें। कर्म के लिहाज़ से यह पिता से आपके रिश्ते और आपके अपने मोल के भाव को छूती है; यहाँ आध्यात्मिक रास्ता है अपने व्यक्तित्व के पीछे के असली आत्म को जानना (आत्म-ज्ञान)।',
  'moon':
      'आपकी आत्मा भावनात्मक पूर्णता, अपनापन और दूसरों का ख़याल रखने की क्षमता ढूँढ़ती है। माँ, घर और दूसरों की देखभाल की ओर एक गहरा खिंचाव है, और उतनी ही गहरी ज़रूरत है महफ़ूज़ महसूस करने की। सीख है भावनात्मक परिपक्वता — हर चीज़ को पूरी तरह महसूस करना पर मूड के काबू में आए बिना, और ख़ुद को खोए बिना दूसरों का ख़याल रखना। रास्ता है भक्ति और दिव्य नारीशक्ति के आगे समर्पण, जहाँ भावना भक्ति बन जाती है।',
  'mars':
      'आपकी आत्मा का रास्ता हिम्मत, काबू में रखी ऊर्जा और सही की रक्षा से होकर गुज़रता है। चाह है अपने को जमाना, काम करना, रक्षा करना और जीतना। सीख है गुस्से और बेसब्री पर काबू पाना — अपनी ताकत को झट से की गई प्रतिक्रिया के बजाय धर्म वाले, सोचे-समझे काम में मोड़ना। कर्म के लिहाज़ से इसमें टकराव, मुक़ाबला और भीतरी बल शामिल हैं; रास्ता है तपस्या, वह निडर अनुशासन जो कच्ची शक्ति को असली चरित्र में बदल देता है।',
  'mercury':
      'आपकी आत्मा ज्ञान, बातचीत और बारीक परख के ज़रिए सीखती है। चाह है समझना, विचारों को जोड़ना और सच को साफ़ शब्दों में कहना। सीख है सिर्फ़ चतुर होने से आगे बढ़कर सच में समझदार बनना, और उस मन को स्थिर करना जो भटकना पसंद करता है। कर्म के लिहाज़ से यह वाणी, पढ़ाई और हालात के हिसाब से ढलने को छूती है; रास्ता है अध्ययन, मंत्र और वह शांत स्पष्टता जो चीज़ों को ठीक वैसा देखती है जैसी वे हैं।',
  'jupiter':
      'आपकी आत्मा समझदारी, मतलब और धर्म ढूँढ़ती है — ज़िंदगी के पीछे का बड़ा "क्यों"। चाह है बढ़ना, सिखाना, आशीर्वाद देना और दूसरों को ऊपर उठाना। सीख है अपने सिद्धांतों का सिर्फ़ उपदेश देने के बजाय उन्हें सचमुच जीना, और आराम से आने वाली अति तथा ख़ुद को सही मानने की आदत से बचना। रास्ता है गुरु की कृपा और शास्त्रों का अध्ययन, जहाँ ज्ञान पककर असली समझदारी बन जाता है।',
  'venus':
      'आपकी आत्मा की यात्रा प्रेम, रिश्ते, सुंदरता और भक्ति से होकर गुज़रती है। सबसे गहरी चाह है मिलन — तालमेल, परिष्कार और जुड़ाव की मिठास। सीख है बिना अधिकार जताए प्रेम करना, और भोग तथा रिश्तों में बँधने के बजाय उनके भीतर की पवित्रता को ढूँढ़ना। कर्म के लिहाज़ से इसमें साझेदारी, इच्छा और कला शामिल हैं; रास्ता है भक्ति, जहाँ प्रेम ख़ुद मुक्ति का दरवाज़ा बन जाता है।',
  'saturn':
      'आपकी आत्मा का काम है अनुशासन, सहनशक्ति, सेवा और छोड़ना सीखना। चाह है कुछ स्थायी बनाना और किसी भी इंसान या चीज़ पर निर्भरता से मुक्त होना। सीख है धैर्य और स्वीकार करना — जिम्मेदारी और समय की देरियों को दिल कठोर किए बिना उठाना। कर्म के लिहाज़ से यह ख़ुद कर्म का ही कारक है; रास्ता है त्याग और सेवा — अपने कर्मों के फल को छोड़ देना और कर्तव्य निभाने में ही आज़ादी पाना।',
};

/// How the Atmakaraka's desire is coloured by the sign it occupies (0=Aries).
const atmakarakaBySign = <String>[
  'With this in Aries, you chase your soul\'s deepest wish head-on, with courage and a rush to go first — you\'re here to learn to make your own path.',
  'In Taurus, it looks for stability, beauty and solid, real things; your soul grows up by staying steady and valuing what truly lasts.',
  'In Gemini, it moves through curiosity, words and being an all-rounder; your soul grows by choosing depth over endless variety.',
  'In Cancer, it flows through feeling, memory and care; your soul ripens by looking after others without drowning in emotion.',
  'In Leo, it shines through creativity, dignity and the wish to be seen; your soul learns a generosity that rises above pride.',
  'In Virgo, it works through service, precision and making things better; your soul softens as you swap self-criticism for humility.',
  'In Libra, it looks for balance, relationships and fairness; your soul matures through harmony and clear, kind decisions.',
  'In Scorpio, it burns through intensity, secrecy and deep change; your soul is remade as you honestly face your own depths.',
  'In Sagittarius, it reaches for meaning, freedom and truth; your soul grows by turning restless searching into real wisdom.',
  'In Capricorn, it climbs through responsibility, patience and mastery; your soul is set free by carrying duty without going hard.',
  'In Aquarius, it serves ideals, the wider community and the unconventional; your soul stretches by balancing detachment with real closeness.',
  'In Pisces, it dissolves through compassion, imagination and surrender; your soul wakes up as you keep its boundless feeling grounded.',
];

/// Hindi — how the Atmakaraka's desire is coloured by the sign (0=Aries).
const atmakarakaBySignHi = <String>[
  'मेष में होने पर आप अपनी आत्मा की सबसे गहरी चाह को सीधे, हिम्मत और पहले करने की जल्दी के साथ पूरा करते हैं — आपको अपना रास्ता ख़ुद बनाना सीखना है।',
  'वृषभ में यह ठहराव, सुंदरता और ठोस, असली चीज़ों को ढूँढ़ती है; आपकी आत्मा टिके रहकर और सच्चे टिकाऊ को महत्व देकर बड़ी होती है।',
  'मिथुन में यह जिज्ञासा, शब्दों और हर काम में माहिर होने से चलती है; आपकी आत्मा अनगिनत तरह-तरह की चीज़ों के बजाय गहराई चुनकर बढ़ती है।',
  'कर्क में यह भावना, यादों और देखभाल से बहती है; आपकी आत्मा भावना में डूबे बिना दूसरों का ख़याल रखकर परिपक्व होती है।',
  'सिंह में यह सृजनशीलता, वक़ार और देखे जाने की चाह से चमकती है; आपकी आत्मा वह दरियादिली सीखती है जो अभिमान से ऊपर उठ जाती है।',
  'कन्या में यह सेवा, बारीकी और चीज़ों को बेहतर बनाने से काम करती है; आपकी आत्मा आत्म-आलोचना को विनम्रता से बदलकर कोमल होती है।',
  'तुला में यह संतुलन, रिश्ते और इंसाफ़ ढूँढ़ती है; आपकी आत्मा तालमेल और साफ़, दयालु फ़ैसलों से परिपक्व होती है।',
  'वृश्चिक में यह तीव्रता, गोपनीयता और गहरे बदलाव से धधकती है; आपकी आत्मा अपनी गहराइयों का ईमानदारी से सामना करके नए सिरे से गढ़ी जाती है।',
  'धनु में यह मतलब, आज़ादी और सच्चाई की ओर बढ़ती है; आपकी आत्मा बेचैन खोज को असली समझदारी में बदलकर बढ़ती है।',
  'मकर में यह जिम्मेदारी, धैर्य और महारत से ऊपर चढ़ती है; आपकी आत्मा दिल कठोर किए बिना कर्तव्य निभाकर मुक्त होती है।',
  'कुम्भ में यह आदर्शों, बड़े समाज और लीक से हटकर चीज़ों की सेवा करती है; आपकी आत्मा वैराग्य को सच्ची नज़दीकी से संतुलित करके फैलती है।',
  'मीन में यह करुणा, कल्पना और समर्पण से घुल जाती है; आपकी आत्मा अपनी असीम भावना को ज़मीन पर टिकाकर जाग उठती है।',
];

/// How the Darakaraka (partner) is coloured by the sign it occupies (0=Aries).
const darakarakaBySign = <String>[
  'In Aries, your partner is bold, direct and independent — quick to act and full of initiative.',
  'In Taurus, your partner is steady, sensual and loyal, and values comfort, patience and the good things in life.',
  'In Gemini, your partner is talkative, clever and young at heart, keeping the bond lively and mentally interesting.',
  'In Cancer, your partner is caring, emotional and family-centred, giving you warmth and a strong sense of home.',
  'In Leo, your partner is warm, proud and expressive — generous, a bit dramatic, and likes to be admired.',
  'In Virgo, your partner is practical, helpful and sharp-eyed, showing love through care and attention to little details.',
  'In Libra, your partner is charming, fair-minded and focused on the relationship, drawn to harmony, beauty and true partnership.',
  'In Scorpio, your partner is intense, private and deeply loyal, with powerful feelings and rock-solid commitment.',
  'In Sagittarius, your partner is free-spirited, honest and hopeful, loving travel, meaning and plenty of open space.',
  'In Capricorn, your partner is mature, ambitious and dependable — grounded, serious and built to last.',
  'In Aquarius, your partner is independent, original and friendly, valuing freedom, ideals and a good mind.',
  'In Pisces, your partner is gentle, compassionate and imaginative — tender-hearted and drawn to the spiritual side of life.',
];

/// Hindi — how the Darakaraka (partner) is coloured by the sign (0=Aries).
const darakarakaBySignHi = <String>[
  'मेष में आपका जीवनसाथी निडर, सीधा और स्वतंत्र होता है — फटाफट काम करने वाला और पहल से भरपूर।',
  'वृषभ में आपका जीवनसाथी शांत, इंद्रियप्रिय और वफ़ादार होता है, जो सुकून, धैर्य और ज़िंदगी की अच्छी चीज़ों को महत्व देता है।',
  'मिथुन में आपका जीवनसाथी बातूनी, चतुर और दिल से जवान होता है, जो रिश्ते को जीवंत और दिमाग़ी तौर पर दिलचस्प बनाए रखता है।',
  'कर्क में आपका जीवनसाथी स्नेही, भावुक और परिवार पर केंद्रित होता है, जो आपको गर्माहट और घर का मज़बूत एहसास देता है।',
  'सिंह में आपका जीवनसाथी गर्मजोश, स्वाभिमानी और खुलकर जताने वाला होता है — दरियादिल, थोड़ा नाटकीय, और सराहे जाने की चाह रखने वाला।',
  'कन्या में आपका जीवनसाथी व्यावहारिक, मददगार और पैनी नज़र वाला होता है, जो देखभाल और छोटी-छोटी बारीकियों पर ध्यान देकर प्यार जताता है।',
  'तुला में आपका जीवनसाथी आकर्षक, इंसाफ़पसंद और रिश्ते पर केंद्रित होता है, जो तालमेल, सुंदरता और सच्ची साझेदारी की ओर खिंचता है।',
  'वृश्चिक में आपका जीवनसाथी तीव्र, अपने में सिमटा और गहराई से वफ़ादार होता है, जिसमें प्रबल भावनाएँ और अटूट प्रतिबद्धता होती है।',
  'धनु में आपका जीवनसाथी स्वच्छंद, ईमानदार और उम्मीद से भरा होता है, जिसे यात्रा, मतलब और खुली जगह प्रिय है।',
  'मकर में आपका जीवनसाथी परिपक्व, महत्वाकांक्षी और भरोसेमंद होता है — ज़मीन से जुड़ा, गंभीर और टिकाऊ।',
  'कुम्भ में आपका जीवनसाथी स्वतंत्र, मौलिक और मिलनसार होता है, जो आज़ादी, आदर्शों और अच्छी सोच को महत्व देता है।',
  'मीन में आपका जीवनसाथी कोमल, करुणामय और कल्पनाशील होता है — सरल दिल का और ज़िंदगी के आध्यात्मिक पहलू की ओर झुका हुआ।',
];

/// Darakaraka (spouse significator) — the nature of the partner, how the bond
/// is met, and what it teaches. Detailed by planet.
const darakarakaByPlanet = <String, String>{
  'sun':
      'Your partner carries dignity, confidence and a strong sense of who they are — warm, principled, and used to being respected. In life they lean toward authority: government, administration, management, or any field where they lead and are seen. Expect a proud, self-respecting person with a status-aware, comfortable lifestyle, who sometimes resembles or reminds you of a father figure. The bond shines when you both stand tall without competing, and you\'re likely to meet them through work, status, or a respected setting.',
  'moon':
      'Your partner is caring, sensitive and nurturing — emotionally tuned-in, family-minded, and devoted to comfort and home. Their world tends to centre on people: caregiving, hospitality, food, or public-facing work, and their moods and fortunes rise and fall like the tides. Expect a homely, emotionally rich lifestyle where family and belonging come first. You usually meet them through family, familiar places, or a natural emotional closeness.',
  'mars':
      'Your partner is strong, energetic and protective, with drive, courage and a competitive streak. They\'re drawn to active, physical or technical fields — the forces, sport, engineering, surgery, machinery or real estate — and live at a fast, go-getting pace. Expect a bold, hard-working, independent person who plays as hard as they work, and can be a little short-tempered at times. You may meet them through action, sport, siblings, or lively, adventurous circumstances.',
  'mercury':
      'Your partner is witty, intelligent and young at heart — good with words, adaptable, and mentally quick. Their life often revolves around words, ideas and exchange: business, writing, teaching, media, IT or trade, with a busy, all-rounder routine and a youthful manner. Expect a lively, social, mentally stimulating home. You usually meet them through study, work, writing, or a younger, playful connection.',
  'jupiter':
      'Your partner is wise, generous and principled — cultured, hopeful, and morally grounded, often from a good or traditional family. They\'re suited to teaching, law, finance, counselling, medicine or spiritual life, and tend to live comfortably, generously, and by their values. Expect a respected, well-meaning companion who lifts up your life and your outlook. You often meet them through teachers, family blessings, travel, or a spiritual setting.',
  'venus':
      'Your partner is loving, charming and refined — artistic, sociable, and drawn to beauty, comfort and pleasure. Their world often involves the arts, design, fashion, luxury, entertainment or hospitality, and they enjoy a graceful, comfortable, beautiful lifestyle. Expect a romantic, warm companion who values harmony and the finer things. You\'re likely to meet them through art, social gatherings, or an easy, mutual attraction.',
  'saturn':
      'Your partner is mature, responsible and steady — grounded, loyal and dutiful, often older, more serious, or from a simpler or different background than yours. They suit disciplined, service-oriented or long-haul work: labour, administration, law, engineering, or anything that needs patience and endurance, and they live modestly and reliably. Expect a bond that builds slowly and lasts, where love shows up as duty and being there more than romance. You often meet them through work, responsibility, or after a period of waiting.',
};

/// Hindi — Darakaraka (spouse significator) by planet.
const darakarakaByPlanetHi = <String, String>{
  'sun':
      'आपका जीवनसाथी वक़ार, आत्मविश्वास और अपने होने का मज़बूत भाव रखता है — गर्मजोश, उसूलों वाला, और सम्मान पाने का आदी। ज़िंदगी में वे अधिकार की ओर झुकते हैं: सरकार, प्रशासन, प्रबंधन, या कोई भी ऐसा क्षेत्र जहाँ वे लीड करें और देखे जाएँ। ऐसे स्वाभिमानी, आत्म-सम्मानी इंसान की उम्मीद रखें जिसकी जीवनशैली रुतबे के प्रति सचेत और सुखी हो, जो कभी-कभी किसी पिता जैसे व्यक्ति की याद दिलाता हो। यह रिश्ता तब चमकता है जब आप दोनों बिना मुक़ाबला किए तने खड़े रहें, और आप उनसे अक्सर काम, रुतबे या किसी सम्मानित माहौल के ज़रिए मिलते हैं।',
  'moon':
      'आपका जीवनसाथी स्नेही, संवेदनशील और ख़याल रखने वाला होता है — भावनाओं को पढ़ने वाला, परिवार-प्रिय, और सुकून तथा घर के प्रति समर्पित। उनकी दुनिया अक्सर लोगों के इर्द-गिर्द रहती है: देखभाल, आतिथ्य, भोजन, या लोगों के सामने वाला काम, और उनकी मनोदशाएँ तथा किस्मत ज्वार-भाटे की तरह उठती-गिरती हैं। ऐसी घरेलू, भावनात्मक रूप से समृद्ध जीवनशैली की उम्मीद रखें जहाँ परिवार और अपनापन सबसे पहले आते हैं। आप अक्सर उनसे परिवार, जानी-पहचानी जगहों, या एक कुदरती भावनात्मक नज़दीकी के ज़रिए मिलते हैं।',
  'mars':
      'आपका जीवनसाथी बलवान, ऊर्जावान और रक्षा करने वाला होता है, जिसमें जोश, हिम्मत और मुक़ाबले की धार होती है। वे सक्रिय, शारीरिक या तकनीकी क्षेत्रों की ओर खिंचते हैं — सेना, खेल, इंजीनियरिंग, सर्जरी, मशीनरी या रियल एस्टेट — और तेज़, आगे बढ़ने वाली रफ़्तार से जीते हैं। ऐसे निडर, मेहनती, स्वतंत्र इंसान की उम्मीद रखें जो जितनी मेहनत करता है उतने ही जोश से जीता भी है, और कभी-कभी ज़रा जल्दी गुस्सा हो जाता है। आप उनसे किसी काम-काज, खेल, भाई-बहनों, या जोशीली, साहसिक परिस्थितियों के ज़रिए मिल सकते हैं।',
  'mercury':
      'आपका जीवनसाथी विनोदी, समझदार और दिल से जवान होता है — शब्दों में माहिर, हालात के हिसाब से ढलने वाला, और दिमाग़ी तौर पर तेज़। उनकी ज़िंदगी अक्सर शब्दों, विचारों और लेन-देन के इर्द-गिर्द घूमती है: व्यवसाय, लेखन, पढ़ाना, मीडिया, आईटी या व्यापार, एक व्यस्त, हर काम में माहिर दिनचर्या और जवान-सा अंदाज़ के साथ। ऐसे जीवंत, मिलनसार, दिमाग़ी तौर पर दिलचस्प घर की उम्मीद रखें। आप अक्सर उनसे पढ़ाई, काम, लेखन, या किसी छोटे, खिलंदड़े जुड़ाव के ज़रिए मिलते हैं।',
  'jupiter':
      'आपका जीवनसाथी समझदार, दरियादिल और उसूलों वाला होता है — सुसंस्कृत, उम्मीद से भरा और नैतिक रूप से दृढ़, अक्सर किसी अच्छे या पारंपरिक परिवार से। वे पढ़ाने, विधि, वित्त, परामर्श, चिकित्सा या आध्यात्मिक जीवन के लिए उपयुक्त हैं, और सुखपूर्वक, दरियादिली से तथा अपने मूल्यों के अनुसार जीते हैं। ऐसे सम्मानित, नेकदिल साथी की उम्मीद रखें जो आपकी ज़िंदगी और आपके नज़रिये को ऊपर उठाता है। आप अक्सर उनसे गुरुओं, परिवार के आशीर्वाद, यात्रा, या किसी आध्यात्मिक माहौल के ज़रिए मिलते हैं।',
  'venus':
      'आपका जीवनसाथी प्रेमपूर्ण, आकर्षक और परिष्कृत होता है — कलाप्रिय, मिलनसार, और सुंदरता, सुकून तथा आनंद की ओर खिंचा हुआ। उनकी दुनिया अक्सर कला, डिज़ाइन, फ़ैशन, ऐशो-आराम, मनोरंजन या आतिथ्य से जुड़ी रहती है, और वे एक सुंदर, सुखी, ख़ूबसूरत जीवनशैली का आनंद लेते हैं। ऐसे रोमांटिक, गर्मजोश साथी की उम्मीद रखें जो तालमेल और सुंदर चीज़ों को महत्व देता है। आप उनसे अक्सर कला, सामाजिक समारोहों, या एक सहज, आपसी आकर्षण के ज़रिए मिलते हैं।',
  'saturn':
      'आपका जीवनसाथी परिपक्व, जिम्मेदार और स्थिर होता है — ज़मीन से जुड़ा, वफ़ादार और कर्तव्यनिष्ठ, अक्सर आपसे बड़ा, ज़्यादा गंभीर, या किसी सादी या अलग पृष्ठभूमि से। वे अनुशासित, सेवा वाले या लंबे चलने वाले काम के लिए उपयुक्त हैं: श्रम, प्रशासन, विधि, इंजीनियरिंग, या धैर्य और सहनशक्ति माँगने वाला कोई भी काम, और वे सादगी और भरोसे के साथ जीते हैं। ऐसे रिश्ते की उम्मीद रखें जो धीरे बनता है और टिकता है, जहाँ प्यार रोमांस से ज़्यादा कर्तव्य और साथ मौजूद रहने के रूप में दिखता है। आप अक्सर उनसे काम, जिम्मेदारी, या किसी इंतज़ार के दौर के बाद मिलते हैं।',
};

/// Mulank (psychic number) meaning, 1..9.
const mulankByNumber = <int, String>{
  1: 'Your ruling planet is the Sun — you\'re a born leader: independent, ambitious and one of a kind.',
  2: 'Your ruling planet is the Moon — you\'re sensitive, easy to work with, intuitive and gentle.',
  3: 'Your ruling planet is Jupiter — you\'re wise, hopeful, good at expressing yourself, and disciplined.',
  4: 'Your ruling planet is Rahu — you\'re unconventional, practical, hard-working and a reformer at heart.',
  5: 'Your ruling planet is Mercury — you\'re quick, a good all-rounder, a natural communicator, and adaptable.',
  6: 'Your ruling planet is Venus — you\'re loving, artistic, harmonious and fond of life\'s pleasures.',
  7: 'Your ruling planet is Ketu — you\'re mystical, reflective, spiritual and independent.',
  8: 'Your ruling planet is Saturn — you\'re disciplined and you last the distance; your rewards come slowly but surely.',
  9: 'Your ruling planet is Mars — you\'re energetic, courageous, determined and protective.',
};

/// Hindi — Mulank (psychic number) meaning, 1..9.
const mulankByNumberHi = <int, String>{
  1: 'आपका स्वामी ग्रह है सूर्य — आप जन्मजात नेता हैं: स्वतंत्र, महत्वाकांक्षी और अपने ढंग के अकेले।',
  2: 'आपका स्वामी ग्रह है चंद्र — आप संवेदनशील, मिलकर काम करने वाले, अंतर्ज्ञानी और कोमल हैं।',
  3: 'आपका स्वामी ग्रह है गुरु — आप समझदार, उम्मीद से भरे, अपनी बात कहने में माहिर और अनुशासित हैं।',
  4: 'आपका स्वामी ग्रह है राहु — आप लीक से हटकर, व्यावहारिक, मेहनती और दिल से सुधारवादी हैं।',
  5: 'आपका स्वामी ग्रह है बुध — आप तेज़, हर काम में माहिर, बातचीत में कुशल और हालात के हिसाब से ढलने वाले हैं।',
  6: 'आपका स्वामी ग्रह है शुक्र — आप प्रेमपूर्ण, कलाप्रिय, तालमेल वाले और ज़िंदगी के सुखों के शौक़ीन हैं।',
  7: 'आपका स्वामी ग्रह है केतु — आप रहस्यमय, आत्ममंथन करने वाले, आध्यात्मिक और स्वतंत्र हैं।',
  8: 'आपका स्वामी ग्रह है शनि — आप अनुशासित हैं और लंबी दौड़ के इंसान हैं; आपके फल धीरे पर पक्के तौर पर आते हैं।',
  9: 'आपका स्वामी ग्रह है मंगल — आप ऊर्जावान, साहसी, दृढ़ और रक्षा करने वाले हैं।',
};

String yogaTitle(String type, [bool hi = false]) => hi
    ? switch (type) {
        'ruchaka' => 'रुचक योग',
        'bhadra' => 'भद्र योग',
        'hamsa' => 'हंस योग',
        'malavya' => 'मालव्य योग',
        'shasha' => 'शश योग',
        'gajakesari' => 'गजकेसरी योग',
        'budhaditya' => 'बुध-आदित्य योग',
        'chandramangal' => 'चंद्र-मंगल योग',
        'raja' => 'राज योग',
        'dhana' => 'धन योग',
        'neechabhanga' => 'नीचभंग राज योग',
        'vipreet' => 'विपरीत राज योग',
        _ => 'योग',
      }
    : switch (type) {
        'ruchaka' => 'Ruchaka Yoga',
        'bhadra' => 'Bhadra Yoga',
        'hamsa' => 'Hamsa Yoga',
        'malavya' => 'Malavya Yoga',
        'shasha' => 'Shasha Yoga',
        'gajakesari' => 'Gaja Kesari Yoga',
        'budhaditya' => 'Budha-Aditya Yoga',
        'chandramangal' => 'Chandra-Mangal Yoga',
        'raja' => 'Raja Yoga',
        'dhana' => 'Dhana Yoga',
        'neechabhanga' => 'Neecha Bhanga Raja Yoga',
        'vipreet' => 'Vipreet Raja Yoga',
        _ => 'Yoga',
      };

String yogaReading(String type, [bool hi = false]) =>
    hi ? _yogaReadingHi(type) : switch (type) {
      'ruchaka' =>
        'Mars sits powerfully in an angle (kendra) of your chart, forming Ruchaka Yoga — one of the five great "great person" (Mahapurusha) yogas. It gives you courage, leadership, physical strength, and a commanding, disciplined nature: you take on challenges head-on and others naturally fall in behind you. People with this yoga often do really well in the forces, sport, engineering, surgery, law enforcement, or anywhere that rewards boldness and stamina, and they tend to have a strong, athletic build. The gift here is a true fighter\'s spirit; your lifelong work is to master your anger and impulses, so that this strength builds you up rather than burns you out.',
      'bhadra' =>
        'Mercury stands strong in an angle (kendra), forming Bhadra Yoga — the "great person" yoga of the mind. It gives you a quick, sharp mind, a way with words, wit, and a natural head for business and analysis. Such people flourish in writing, teaching, trade, commerce, law, media, and any work built on communication and clever thinking, and they often stay youthful, curious and adaptable all through life. The blessing is a brilliant, flexible mind; the thing to watch is turning cleverness into real depth and keeping that restless mind focused.',
      'hamsa' =>
        'Jupiter sits strong in an angle (kendra), forming Hamsa Yoga — the "great person" yoga of wisdom. It gives you learning, good character, hope, faith, and the respect of others, along with a graceful, upright and dignified nature. People with this yoga often become teachers, advisors, judges, priests or trusted guides, drawn naturally to knowledge, dharma and a higher purpose. The gift is a wise, kind presence that others lean on; the thing to watch is to actually live your principles rather than just preach them.',
      'malavya' =>
        'Venus stands strong in an angle (kendra), forming Malavya Yoga — the "great person" yoga of beauty and refinement. It brings charm, good looks, artistic talent, comfort, luxury and harmonious relationships, usually with a magnetic, pleasing presence. Such people enjoy the finer things and do well in art, design, entertainment, fashion, hospitality, and anything that joins beauty with skill, often surrounded by ease and plenty. The gift is grace and a life full of pleasure; the thing to watch is keeping your devotion and character deeper than mere indulgence.',
      'shasha' =>
        'Saturn sits strong in an angle (kendra), forming Shasha Yoga — the "great person" yoga of discipline and endurance. It gives you authority, patience, a gift for organising, and success that\'s slow to arrive but solid and lasting; you rise through sheer perseverance rather than luck. People with this yoga often reach positions of power in government, administration, industry, institutions, or any field where steady, long effort pays off. The gift is lasting authority, honestly earned; the thing to watch is softening any rigidity, so the long climb doesn\'t turn your heart to stone.',
      'gajakesari' =>
        'Jupiter stands in a strong angle from your Moon, forming the famous Gaja Kesari Yoga — which literally means "the elephant and the lion". It blesses you with intelligence, wisdom, a calm and generous mind, good judgement, and a lasting good name, with an influence that grows steadily as you get older. Such people are respected, well-liked and often prosperous, and they carry themselves with a quiet dignity. The gift is a wise, magnetic character that quietly earns trust and honour across a whole lifetime.',
      'budhaditya' =>
        'The Sun and Mercury sit together, forming Budha-Aditya Yoga — the coming together of soul and mind. It sharpens the mind, clears your thinking, and strengthens your communication and confidence, giving you a bright, well-spoken and capable nature. People with this yoga shine in academics, administration, government, writing, analysis, and any role that rewards clear thinking and expression. The gift is a bright, articulate intelligence; the only thing to watch is that the Sun\'s brightness doesn\'t overpower Mercury\'s subtlety and patience.',
      'chandramangal' =>
        'The Moon joins Mars, forming Chandra-Mangal Yoga — where feeling meets drive. It gives you energy, the knack of making do with what you have, emotional toughness, and a strong instinct for turning effort into real money, making natural entrepreneurs and earners. Such people are practical, ambitious and good with money, often building wealth through their own initiative and enterprise. The gift is drive paired with gut instinct; the thing to watch is not letting emotion and aggression cloud your money decisions.',
      'raja' =>
        'The lord of an angle (kendra) and the lord of a trine (trikona) join forces in your chart — a classic Raja Yoga, the mark of rising fortune. It brings status, capability, recognition and success, lifting the areas of life this yoga touches into prominence and power. People with such combinations tend to rise above where they started, gaining authority, influence or prosperity, sometimes out of nowhere. The gift is real worldly rise, and it flowers most fully during the planetary periods (dashas) of the planets that form it.',
      'dhana' =>
        'The lords of wealth — the houses of income and savings — are linked together in your chart, forming a Dhana Yoga. It gives you a natural ability to earn, gather and hold on to resources, with money that grows steadily across your lifetime rather than in one dramatic stroke. Such people rarely fall short of money, and wealth tends to build up through their own competence and instincts. The gift is durable prosperity, and it grows even stronger during the periods of the wealth-giving planets.',
      'neechabhanga' =>
        'A planet in your chart landed in its sign of weakness (debilitation), but another supporting placement cancels out that weakness — forming Neecha Bhanga Raja Yoga. This "cancellation" turns what looks like a handicap into an unusual strength: a hard or humble early start tends to flip dramatically into rise, respect and achievement later in life. People with this yoga often surprise everyone, turning their biggest limitation into their biggest asset. The gift is a rise from the ashes, which usually unfolds as the cancelled planet matures through its dasha.',
      'vipreet' =>
        'The lords of the tough houses (the 6th, 8th and 12th) sit in each other\'s places, forming Vipreet Raja Yoga — the "reversal" royal yoga. It works by a hidden logic: hardships, rivals, losses and crises end up turning to your advantage, so your setbacks become comebacks. People with this yoga often thrive precisely through hardship and competition, in situations that would defeat others. The gift is a resilience that turns trouble into triumph, and it switches on most strongly during the periods of the planets involved.',
      _ => '',
    };

String _yogaReadingHi(String type) => switch (type) {
      'ruchaka' =>
        'मंगल आपकी कुंडली के केंद्र में बहुत मज़बूत होकर रुचक योग बना रहा है — पाँच खास "महापुरुष" योगों में से एक। यह आपको सच्ची हिम्मत, कुदरती लीडरशिप, शारीरिक ताकत और काम करने का एक पक्का, अनुशासित तरीका देता है: आप मुश्किलों का सीधे सामना करते हैं और लोग अपने-आप आप पर भरोसा करके आपके पीछे चलते हैं। ऐसे लोग अक्सर सेना, खेल, इंजीनियरिंग, सर्जरी, पुलिस या किसी भी ऐसी जगह बहुत अच्छा करते हैं जहाँ हिम्मत और दमखम की क़द्र हो, और इनका शरीर आम तौर पर मज़बूत और चुस्त होता है। इसका सबसे बड़ा तोहफ़ा है एक सच्चे योद्धा जैसा जज़्बा; बस ज़िंदगी भर एक बात पर ध्यान देना है — अपने गुस्से और बेसब्री को काबू में रखना, ताकि यही ताकत आपको बनाए, जलाए नहीं।',
      'bhadra' =>
        'बुध केंद्र में मज़बूत होकर भद्र योग बना रहा है — दिमाग़ का "महापुरुष" योग। यह आपको एक तेज़, कुशाग्र दिमाग़, शब्दों पर पकड़, हाज़िरजवाबी और व्यापार व विश्लेषण की कुदरती समझ देता है। ऐसे लोग लेखन, पढ़ाने, व्यापार, वाणिज्य, विधि, मीडिया और बातचीत व चतुर सोच पर टिके हर काम में फलते-फूलते हैं, और ज़िंदगी भर जवान, जिज्ञासु और हर हाल में ढल जाने वाले बने रहते हैं। तोहफ़ा है एक प्रखर, लचीला दिमाग़; ध्यान इस बात का रखें कि चतुराई को असली गहराई में बदलें और उस बेचैन दिमाग़ को एक जगह टिकाकर रखें।',
      'hamsa' =>
        'गुरु केंद्र में मज़बूत होकर हंस योग बना रहा है — समझदारी का "महापुरुष" योग। यह आपको विद्या, अच्छा चरित्र, उम्मीद, श्रद्धा और दूसरों का सम्मान देता है, और एक शालीन, धर्म वाला और वक़ार भरा स्वभाव देता है। ऐसे लोग अक्सर शिक्षक, सलाहकार, न्यायाधीश, पुरोहित या भरोसेमंद मार्गदर्शक बनते हैं, और अपने-आप ज्ञान, धर्म और एक ऊँचे मक़सद की ओर झुके होते हैं। तोहफ़ा है एक समझदार, नेकदिल मौजूदगी जिस पर लोग टिके रहते हैं; ध्यान इस बात का रखें कि अपने उसूलों का सिर्फ़ उपदेश न दें, बल्कि उन्हें सचमुच जिएँ।',
      'malavya' =>
        'शुक्र केंद्र में मज़बूत होकर मालव्य योग बना रहा है — सुंदरता और परिष्कार का "महापुरुष" योग। यह आकर्षण, अच्छा रूप-रंग, कलात्मक हुनर, सुकून, ऐशो-आराम और मधुर रिश्ते देता है, अक्सर एक चुम्बकीय, मनभावन मौजूदगी के साथ। ऐसे लोग ज़िंदगी की सुंदर चीज़ों का आनंद लेते हैं और कला, डिज़ाइन, मनोरंजन, फ़ैशन, आतिथ्य तथा सुंदरता व हुनर को जोड़ने वाले हर क्षेत्र में सफल होते हैं, अक्सर सुख-समृद्धि के बीच। तोहफ़ा है शालीनता और आनंद से भरी ज़िंदगी; ध्यान इस बात का रखें कि आपकी भक्ति और चरित्र सिर्फ़ भोग से गहरे बने रहें।',
      'shasha' =>
        'शनि केंद्र में मज़बूत होकर शश योग बना रहा है — अनुशासन और सहनशक्ति का "महापुरुष" योग। यह आपको अधिकार, धैर्य, चीज़ों को व्यवस्थित करने का हुनर और ऐसी सफलता देता है जो धीरे आती है पर ठोस और टिकाऊ होती है; आप किस्मत से नहीं, बल्कि अटूट मेहनत से ऊपर उठते हैं। ऐसे लोग अक्सर सरकार, प्रशासन, उद्योग, संस्थाओं या ऐसी किसी भी जगह ताकत के पदों तक पहुँचते हैं जहाँ लगातार, लंबी मेहनत रंग लाती है। तोहफ़ा है ईमानदारी से कमाया गया टिकाऊ अधिकार; ध्यान इस बात का रखें कि अपनी कठोरता को नरम करें, ताकि यह लंबी चढ़ाई आपके दिल को पत्थर न बना दे।',
      'gajakesari' =>
        'गुरु आपके चंद्र से एक मज़बूत केंद्र में बैठकर मशहूर गजकेसरी योग बना रहा है — जिसका शाब्दिक मतलब है "हाथी और शेर"। यह आपको बुद्धि, समझदारी, एक शांत व दरियादिल मन, अच्छी परख और एक टिकाऊ सुनाम देता है, और ऐसा प्रभाव देता है जो उम्र के साथ लगातार बढ़ता जाता है। ऐसे लोग सम्मानित, सबके प्रिय और अक्सर समृद्ध होते हैं, और एक शांत वक़ार के साथ चलते हैं। तोहफ़ा है एक समझदार, चुम्बकीय व्यक्तित्व जो पूरी ज़िंदगी चुपचाप भरोसा और सम्मान कमाता रहता है।',
      'budhaditya' =>
        'सूर्य और बुध साथ बैठकर बुध-आदित्य योग बना रहे हैं — आत्मा और दिमाग़ का मेल। यह दिमाग़ को तेज़ करता है, सोच को साफ़ करता है और बातचीत व आत्मविश्वास को बढ़ाता है, जिससे एक तेजस्वी, बात करने में माहिर और सक्षम स्वभाव बनता है। ऐसे लोग पढ़ाई, प्रशासन, सरकार, लेखन, विश्लेषण और साफ़ सोच व अभिव्यक्ति वाली हर भूमिका में चमकते हैं। तोहफ़ा है एक चमकदार, सुवक्ता बुद्धि; बस एक बात का ध्यान रखें कि सूर्य का तेज बुध की बारीकी और धैर्य पर हावी न हो जाए।',
      'chandramangal' =>
        'चंद्र मंगल से मिलकर चंद्र-मंगल योग बना रहा है — जहाँ भावना और उद्यम मिलते हैं। यह ऊर्जा, कम में काम चला लेने की सूझ, भावनात्मक मज़बूती और मेहनत को असली पैसे में बदलने की प्रबल प्रवृत्ति देता है, जिससे कुदरती उद्यमी और कमाने वाले बनते हैं। ऐसे लोग व्यावहारिक, महत्वाकांक्षी और पैसे के मामले में कुशल होते हैं, अक्सर अपनी पहल और उद्यम से दौलत बनाते हैं। तोहफ़ा है अंतर्ज्ञान के साथ जुड़ा उद्यम; ध्यान इस बात का रखें कि भावना और आक्रामकता आपके पैसे के फ़ैसलों को धुँधला न कर दें।',
      'raja' =>
        'आपकी कुंडली में किसी केंद्र (कोण) का स्वामी और किसी त्रिकोण का स्वामी मिलकर काम कर रहे हैं — एक बढ़िया राज योग, बढ़ती किस्मत की पहचान। यह रुतबा, सामर्थ्य, मान्यता और सफलता देता है, और ज़िंदगी के जिन हिस्सों को यह योग छूता है उन्हें प्रमुखता व ताकत तक उठा देता है। ऐसे संयोग वाले लोग अक्सर जहाँ से शुरू हुए थे उससे ऊपर उठते हैं और अधिकार, प्रभाव या समृद्धि पाते हैं, कभी-कभी अचानक ही। तोहफ़ा है असली सांसारिक उन्नति, और यह उन ग्रहों की दशा-अंतर्दशा में सबसे ज़्यादा फलती है जो इसे बनाते हैं।',
      'dhana' =>
        'आपकी कुंडली में धन के स्वामी — आय और बचत के भाव — आपस में जुड़े हुए हैं, जिससे धन योग बनता है। यह कमाने, जमा करने और संसाधनों को थामे रखने की कुदरती क्षमता देता है, और पैसा एक ही झटके में नहीं, बल्कि पूरी ज़िंदगी में धीरे-धीरे बढ़ता है। ऐसे लोगों को अक्सर पैसे की कमी नहीं रहती, और दौलत उनकी अपनी योग्यता और सूझबूझ से जुड़ती जाती है। तोहफ़ा है टिकाऊ समृद्धि, और यह धन देने वाले ग्रहों की दशा में और भी मज़बूत हो जाती है।',
      'neechabhanga' =>
        'आपकी कुंडली में कोई ग्रह अपनी नीच राशि में जा गिरा था, पर एक और सहारा देने वाली स्थिति उस कमज़ोरी को रद्द कर देती है — इससे नीचभंग राज योग बनता है। यह "रद्द होना" एक दिखने वाली कमज़ोरी को एक अनोखी ताकत में बदल देता है: एक कठिन या मामूली शुरुआत ज़िंदगी में आगे चलकर नाटकीय ढंग से उन्नति, सम्मान और उपलब्धि में पलट जाती है। ऐसे लोग अक्सर सबको चौंका देते हैं, अपनी सबसे बड़ी कमज़ोरी को अपनी सबसे बड़ी ताकत बना लेते हैं। तोहफ़ा है राख से फिर उठ खड़ा होना, जो अक्सर तब खिलता है जब वह रद्द हुआ ग्रह अपनी दशा में परिपक्व होता है।',
      'vipreet' =>
        'मुश्किल भावों (6ठे, 8वें और 12वें) के स्वामी एक-दूसरे की जगह पर बैठ जाते हैं, जिससे विपरीत राज योग बनता है — "उलटफेर" वाला राज योग। यह एक छिपे तर्क से काम करता है: मुश्किलें, दुश्मन, नुकसान और संकट आख़िर में आपके ही फ़ायदे में बदल जाते हैं, इसलिए आपकी नाकामियाँ वापसी बन जाती हैं। ऐसे लोग अक्सर ठीक मुसीबत और मुक़ाबले के बीच ही फलते-फूलते हैं, उन हालात में जो दूसरों को हरा देते। तोहफ़ा है वह दृढ़ता जो मुसीबत को जीत में बदल देती है, और यह संबंधित ग्रहों की दशा में सबसे मज़बूती से चालू होती है।',
      _ => '',
    };

/// Localized severity badge for a dosha ('low'/'medium'/'high' or the Sade
/// Sati phases 'rising'/'peak'/'setting').
String severityLabel(String s, [bool hi = false]) => hi
    ? switch (s) {
        'low' => 'हल्का',
        'medium' => 'मध्यम',
        'high' => 'प्रबल',
        'rising' => 'आरोही',
        'peak' => 'शिखर',
        'setting' => 'अवरोही',
        _ => s,
      }
    : s.toUpperCase();

String doshaTitle(String type, [bool hi = false]) => hi
    ? switch (type) {
        'mangal' => 'मंगल दोष (मांगलिक)',
        'kaalsarp' => 'काल सर्प दोष',
        'sadesati' => 'शनि साढ़े साती',
        'kemadruma' => 'केमद्रुम दोष',
        'guruchandal' => 'गुरु चांडाल दोष',
        'shakata' => 'शकट दोष',
        'pitra' => 'पितृ दोष',
        'nadi' => 'नाड़ी दोष',
        _ => 'दोष',
      }
    : switch (type) {
        'mangal' => 'Mangal Dosha (Manglik)',
        'kaalsarp' => 'Kaal Sarp Dosha',
        'sadesati' => 'Shani Sade Sati',
        'kemadruma' => 'Kemadruma Dosha',
        'guruchandal' => 'Guru Chandal Dosha',
        'shakata' => 'Shakata Dosha',
        'pitra' => 'Pitra Dosha',
        'nadi' => 'Nadi Dosha',
        _ => 'Dosha',
      };

String doshaReading(String type, String severity, [bool hi = false]) =>
    hi ? _doshaReadingHi(type, severity) : switch (type) {
      'mangal' => mangalReading(severity),
      'kaalsarp' =>
        'Every one of your seven planets falls on just one side of the Rahu–Ketu line, boxed in between the two nodes — the pattern known as Kaal Sarp Dosha. Life with this yoga can feel unusually fated and intense, coming in sudden surges and abrupt delays rather than smooth, steady progress, with a sense that unseen forces are shaping events. But it\'s far from only difficult: it gives you deep focus, resilience and drive, and a great many people with it become unusually successful in the second half of life, especially after about age 30 once its early struggles have done their work. The key is to keep going — this dosha rewards those who push on through the delays.',
      'sadesati' => _sadeSati(severity),
      'kemadruma' =>
        'Your Moon stands with no planet to support it in the houses right beside it (the 2nd and 12th from the Moon) and with no close company — the pattern called Kemadruma Dosha. It can leave your mind feeling unsupported, alone, or shut up in itself, and life may seem to have no easy safety net, especially in the early years. Yet this very aloneness forges remarkable emotional independence: people with it learn to stand on their own and often grow into deeply self-reliant, capable adults. Nourishing relationships, a steady routine and some inner practice greatly ease the loneliness, and many classical exceptions can reduce it or cancel it outright.',
      'guruchandal' =>
        'Jupiter — the planet of wisdom, faith and sound judgement — sits together with a lunar node (Rahu or Ketu), forming Guru Chandal Dosha. This meeting of the teacher with the shadow can shake up your beliefs, blur the line between right and wrong, and create tension with teachers, tradition, or your own conscience. But it has a bright side: it makes an original, independent, unconventional thinker who questions the rules they\'ve inherited and is willing to break old moulds to reach their own truth. Strengthening Jupiter through study, devotion and wise company steers this pattern toward genuine wisdom that you\'ve earned yourself.',
      'shakata' =>
        'Your Moon and Jupiter sit in the harsh 6th–8th angle from each other, forming Shakata Dosha — named after a cart that jolts unevenly along the road. It tends to make your fortune come in waves rather than a steady climb: stretches of rising are followed by dips, and stability can feel hard to hold on to, especially in your mind and your material life. It\'s far from ruinous, and its effect drops a lot whenever Jupiter or the Moon is strong or well-placed. Staying consistent, thinking long-term, and not getting discouraged by the natural ups and downs are the way through.',
      'pitra' =>
        'The Sun or the 9th house of your chart — the seats of the father and the family line — is under strain from Saturn or the nodes, pointing to Pitra Dosha, the karmic debt of the forefathers. Traditionally it can bring repeated obstacles in family harmony, career, marriage, or the wellbeing of children, as though some ancestral matter is still unsettled. It isn\'t a punishment but an invitation to heal the family line through remembrance and service. Honouring the ancestors with Shraddha, Tarpan and charity — especially during Pitru Paksha — is the classical remedy, and it brings a noticeable sense of peace.',
      _ => '',
    };

String mangalReading(String severity) {
  const base =
      'Mars sits in one of the houses (the 1st, 2nd, 4th, 7th, 8th or 12th, counted from your Lagna or Moon) that traditionally stir up friction in marriage and close partnership — the pattern called Mangal Dosha, or being "Manglik". It gives you a fiery, independent, strong-willed nature with a lot of drive, sharp opinions, and real intensity in close bonds, which in marriage can show up as clashes over freedom, a mismatched pace, or a slower, bumpier road to settling down. The effect is real, but usually milder than popular belief makes out, and many classical rules soften it.';
  final tail = switch (severity) {
    'low' =>
      ' In your chart the effect is mild and largely eased — softened because it gets cancelled out. Classical tradition says it settles down further once Mars reaches its "maturity age" of about 28 (backed up by Saturn\'s first return near 29), and that marrying another Manglik partner cancels it almost completely.',
    'medium' =>
      ' Here the effect is moderate; it eases off noticeably as you grow older, and it naturally pairs well with another Manglik partner whose chart carries the same heat.',
    _ =>
      ' The effect is strong, coming from both your Lagna and your Moon; patience in relationships and matching with another Manglik chart help the most, and any softening factors further ease whatever is left.',
  };
  return base + tail;
}

String _sadeSati(String phase) {
  const base =
      'Saturn is passing through the sign just before, over, or just after your birth Moon — the roughly seven-and-a-half-year stretch known as Sade Sati, Saturn\'s most famous test. It\'s a demanding, maturing chapter that slowly strips away everything unnecessary — illusions, shortcuts and false supports — and rebuilds your life on honest, solid foundations, rewarding patience, discipline and integrity. You feel it most in your mind, your emotions, your responsibilities, and the direction of your life, and though it can feel heavy while it runs, most people come out of it wiser, stronger and more grounded.';
  final tail = switch (phase) {
    'rising' =>
      ' You\'re in the first (rising) phase, with Saturn in the 12th from your Moon — a time of endings, extra expenses and quiet inner preparation, as old chapters gently close.',
    'peak' =>
      ' You\'re in the peak phase, with Saturn passing right over your Moon itself — the most testing stretch, reshaping your mind, your self-image and your life\'s direction from the ground up.',
    _ =>
      ' You\'re in the final (setting) phase, with Saturn in the 2nd from your Moon — the pressures on family, speech and finances slowly ease as this long lesson finishes and stability returns.',
  };
  return base + tail;
}

String _doshaReadingHi(String type, String severity) => switch (type) {
      'mangal' => _mangalReadingHi(severity),
      'kaalsarp' =>
        'आपके सातों ग्रह राहु-केतु की रेखा के एक ही तरफ़ पड़ते हैं, दोनों नोड्स के बीच घिरे हुए — यह पैटर्न काल सर्प दोष कहलाता है। इस योग के साथ ज़िंदगी असामान्य रूप से किस्मत से चलने वाली और तीव्र लग सकती है, जो सहज, स्थिर प्रगति के बजाय अचानक उभार और अचानक रुकावटों में आती है, मानो कोई अनदेखी शक्तियाँ घटनाओं को आकार दे रही हों। फिर भी यह सिर्फ़ मुश्किल नहीं है: यह आपको गहरी एकाग्रता, दृढ़ता और उद्यम देता है, और बहुत-से लोग इसके साथ ज़िंदगी के दूसरे हिस्से में — ख़ासकर लगभग 30 साल की उम्र के बाद, जब इसके शुरुआती संघर्ष अपना काम कर चुके होते हैं — असामान्य रूप से सफल होते हैं। कुंजी है चलते रहना — यह दोष उन्हें इनाम देता है जो रुकावटों के बीच भी आगे बढ़ते रहते हैं।',
      'sadesati' => _sadeSatiHi(severity),
      'kemadruma' =>
        'आपका चंद्र अपने ठीक बगल के भावों (चंद्र से दूसरे और बारहवें) में किसी ग्रह के सहारे बिना और किसी पास की संगति के बिना खड़ा है — यह पैटर्न केमद्रुम दोष कहलाता है। यह मन को असहाय, अकेला या भावनात्मक रूप से अपने में बंद महसूस करा सकता है, और ज़िंदगी में — ख़ासकर शुरुआती सालों में — कोई आसान सुरक्षा-जाल न होने-सा लग सकता है। फिर भी यही अकेलापन ग़ज़ब की भावनात्मक स्वतंत्रता गढ़ता है: ऐसे लोग अपने पैरों पर खड़ा होना सीखते हैं और अक्सर गहरे आत्मनिर्भर, सक्षम इंसान बनते हैं। पोषण देने वाले रिश्ते, एक स्थिर दिनचर्या और थोड़ी भीतरी साधना इस अकेलेपन को बहुत घटा देते हैं, और कई शास्त्रीय अपवाद इसे कम या पूरी तरह रद्द कर सकते हैं।',
      'guruchandal' =>
        'गुरु — समझदारी, श्रद्धा और अच्छी परख का ग्रह — किसी चंद्र-नोड (राहु या केतु) के साथ बैठकर गुरु चांडाल दोष बना रहा है। गुरु का छाया-ग्रह के साथ यह मिलन आपके विश्वास को हिला सकता है, सही-गलत की लकीर को धुँधला कर सकता है, और गुरुजनों, परंपरा या आपकी अपनी अंतरात्मा से तनाव पैदा कर सकता है। पर इसका एक उजला पक्ष भी है: यह एक मौलिक, स्वतंत्र, लीक से हटकर सोचने वाला इंसान बनाता है जो विरासत में मिले नियमों पर सवाल करता है और अपने सच तक पहुँचने के लिए पुराने साँचे तोड़ने को तैयार रहता है। अध्ययन, भक्ति और अच्छे लोगों की संगति से गुरु को मज़बूत करना इस पैटर्न को सच्ची, ख़ुद कमाई हुई समझदारी की ओर मोड़ देता है।',
      'shakata' =>
        'आपका चंद्र और गुरु एक-दूसरे से कठोर 6-8 अक्ष में बैठे हैं, जिससे शकट दोष बनता है — उस गाड़ी के नाम पर जो अपनी राह पर असमान रूप से हिचकोले खाती है। यह किस्मत को स्थिर चढ़ाई के बजाय लहरों में लाता है: उठान के दौर के बाद गिरावट आती है, और स्थिरता थामे रखना मुश्किल लग सकता है, ख़ासकर आपके मन और भौतिक जीवन में। यह विनाशकारी से कोसों दूर है, और जब भी गुरु या चंद्र मज़बूत या अच्छी जगह पर हो, इसका असर बहुत घट जाता है। लगातार लगे रहना, लंबी सोच रखना और स्वाभाविक उतार-चढ़ाव से निराश न होना ही इसका रास्ता है।',
      'pitra' =>
        'आपकी कुंडली में सूर्य या नवम भाव — पिता और पितृ-वंश के स्थान — शनि या नोड्स के दबाव में हैं, जो पितृ दोष का संकेत है, पूर्वजों का कर्म-ऋण। परंपरा के अनुसार यह परिवार के तालमेल, करियर, विवाह या संतान के सुख में बार-बार रुकावटें ला सकता है, मानो कोई पितृ-संबंधी मामला अभी अनसुलझा रह गया हो। यह कोई सज़ा नहीं, बल्कि स्मरण और सेवा से वंश को ठीक करने का निमंत्रण है। श्राद्ध, तर्पण और दान से — ख़ासकर पितृ पक्ष में — पूर्वजों का सम्मान इसका शास्त्रीय उपाय है, और यह साफ़ महसूस होने वाली शांति लाता है।',
      _ => '',
    };

String _mangalReadingHi(String severity) {
  const base =
      'मंगल उन भावों में से एक में बैठा है (लग्न या चंद्र से 1, 2, 4, 7, 8 या 12वें) जो परंपरा से विवाह और निकट संबंध में टकराव जगाते हैं — यह पैटर्न मंगल दोष, या मांगलिक होना कहलाता है। यह आपको एक तेजस्वी, स्वतंत्र, दृढ़-इच्छाशक्ति वाला स्वभाव देता है, ख़ूब जोश, तीखे विचार और करीबी रिश्तों में एक तीव्रता के साथ, जो विवाह में आज़ादी को लेकर टकराव, बेमेल रफ़्तार, या घर बसाने की धीमी, ऊबड़-खाबड़ राह के रूप में दिख सकता है। असर सच्चा है पर आम तौर पर लोक-मान्यता से हल्का होता है, और कई शास्त्रीय नियम इसे नरम कर देते हैं।';
  final tail = switch (severity) {
    'low' =>
      ' आपकी कुंडली में इसका असर हल्का और काफ़ी हद तक कम है — इसलिए क्योंकि यह रद्द हो जाता है। शास्त्रीय परंपरा मानती है कि यह मंगल के लगभग 28 साल की परिपक्वता-उम्र पर पहुँचने के बाद और भी शांत हो जाता है (शनि की पहली वापसी लगभग 29 साल पर इसे और पक्का करती है), और किसी दूसरे मांगलिक साथी से विवाह इसे लगभग पूरी तरह ख़त्म कर देता है।',
    'medium' =>
      ' यहाँ असर मध्यम है; यह उम्र बढ़ने के साथ साफ़ तौर पर घटता है, और किसी दूसरे मांगलिक साथी से — जिसकी कुंडली में वही गर्मी हो — अपने-आप अच्छा मेल बैठता है।',
    _ =>
      ' असर प्रबल है, जो आपके लग्न और चंद्र दोनों से उठता है; रिश्तों में धैर्य और किसी दूसरी मांगलिक कुंडली से मेल सबसे ज़्यादा मददगार है, और कोई भी नरम करने वाला कारक बाकी बचे असर को और घटा देता है।',
  };
  return base + tail;
}

String _sadeSatiHi(String phase) {
  const base =
      'शनि आपके जन्म-चंद्र से ठीक पहले, ऊपर या ठीक बाद की राशि से गोचर कर रहा है — लगभग साढ़े सात साल का वह दौर जो साढ़े साती कहलाता है, शनि की सबसे मशहूर परीक्षा। यह एक कठिन, परिपक्व करने वाला अध्याय है जो धीरे-धीरे हर ग़ैर-ज़रूरी चीज़ को हटा देता है — भ्रम, शॉर्टकट और झूठे सहारे — और आपकी ज़िंदगी को ईमानदार, टिकाऊ नींव पर फिर से खड़ा करता है, धैर्य, अनुशासन और सच्चाई को इनाम देता है। यह सबसे ज़्यादा आपके मन, भावनाओं, अपनी जिम्मेदारियों और ज़िंदगी की दिशा में महसूस होता है, और भले ही चलते समय यह भारी लगे, ज़्यादातर लोग इससे ज़्यादा समझदार, मज़बूत और स्थिर होकर निकलते हैं।';
  final tail = switch (phase) {
    'rising' =>
      ' आप पहले (आरोही) चरण में हैं, शनि आपके चंद्र से 12वें में — अंत, बढ़े हुए खर्च और चुपचाप भीतरी तैयारी का समय, जब पुराने अध्याय हौले से बंद होते हैं।',
    'peak' =>
      ' आप शिखर चरण में हैं, शनि आपके चंद्र के ठीक ऊपर से गुज़रता हुआ — सबसे कठिन दौर, जो आपके मन, आपकी अपनी छवि और आपकी ज़िंदगी की दिशा को जड़ से नया आकार देता है।',
    _ =>
      ' आप आख़िरी (अवरोही) चरण में हैं, शनि आपके चंद्र से दूसरे में — परिवार, वाणी और पैसे पर दबाव धीरे-धीरे घटते हैं, ज्यों-ज्यों यह लंबा सबक़ पूरा होता है और स्थिरता लौटती है।',
  };
  return base + tail;
}

String doshaRemedy(String type, [bool hi = false]) => hi
    ? switch (type) {
        'mangal' =>
          'मंगलवार को हनुमान चालीसा पढ़ें — हनुमान जी मंगल के देवता हैं और उसकी गर्मी को संतुलन में रखते हैं। हर हफ़्ते हनुमान जी को लाल फूल चढ़ाएँ और सरसों के तेल का दीया जलाएँ, और मंगलवार को लाल मसूर या लाल कपड़ा दान करें। सबसे बढ़कर, मंगल को दबाने के बजाय व्यायाम, खेल या सेवा के ज़रिए उसे एक अच्छी दिशा दें।',
        'kaalsarp' =>
          'भगवान शिव की उपासना करें और महामृत्युंजय मंत्र का जप करें। नाग पंचमी पर नागों को अर्पण करें, और चाहें तो किसी तीर्थ-स्थल पर काल सर्प शांति करवाएँ। सबसे बढ़कर, धैर्य के साथ चलते रहें — यह पैटर्न डटे रहने वालों को इनाम देता है।',
        'sadesati' =>
          'हनुमान जी और शनि देव की उपासना करें; शनिवार को हनुमान चालीसा और शनि मंत्र पढ़ें। बुज़ुर्गों, ग़रीबों और मेहनतकश लोगों की सेवा करें, शनि को सरसों का तेल चढ़ाएँ, और एक ईमानदार, अनुशासित दिनचर्या रखें। शॉर्टकट से बचें — लगातार की गई मेहनत ही सच्चा उपाय है।',
        'kemadruma' =>
          'चंद्र को मज़बूत करें: भगवान शिव की उपासना करें, सोमवार को जल और सफ़ेद फूल चढ़ाएँ, और अच्छी, पोषण देने वाली संगति रखें। एक शांत दिनचर्या, ध्यान और पानी के पास बिताया समय मन को स्थिर करते हैं।',
        'guruchandal' =>
          'गुरु को मज़बूत करें: भगवान विष्णु या अपने गुरु की उपासना करें, पीला कपड़ा पहनें, और गुरुवार को गुरु मंत्र का जप करें। शास्त्रों को पढ़ें और समझदार, नेक लोगों की संगति रखें।',
        'shakata' =>
          'सोमवार और गुरुवार को भक्ति और दान से चंद्र तथा गुरु का सम्मान करें। ठहराव और लंबी सोच अपने अंदर बढ़ाएँ, और स्वाभाविक उतार-चढ़ाव से निराश न हों।',
        'pitra' =>
          'अपने पूर्वजों का सम्मान करें: श्राद्ध और तर्पण करें, ज़रूरतमंदों, कौओं और गायों को भोजन दें, और पितृ पक्ष में उनके नाम पर दान करें। पूर्वजों और भगवान विष्णु की प्रार्थना शांति लाती है।',
        _ => '',
      }
    : switch (type) {
      'mangal' =>
        'Recite the Hanuman Chalisa on Tuesdays — Hanuman is the deity of Mars and calms its heat. Offer red flowers and light a mustard-oil lamp before Hanuman every week, and donate red lentils or red cloth on Tuesdays. Most importantly, give Mars a good direction — through exercise, sport or seva — instead of bottling it up.',
      'kaalsarp' =>
        'Worship Lord Shiva and chant the Maha Mrityunjaya mantra. Make offerings to the Nagas on Nag Panchami, and perform a Kaal Sarp shanti at a sacred site if you wish. Above all, keep going with patience — this pattern rewards those who stick with it.',
      'sadesati' =>
        'Worship Hanuman and Shani Dev; recite the Hanuman Chalisa and a Shani mantra on Saturdays. Serve the elderly, the poor and working people, offer mustard oil to Shani, and keep an honest, disciplined routine. Avoid shortcuts — steady effort is the real remedy.',
      'kemadruma' =>
        'Strengthen the Moon: worship Lord Shiva, offer water and white flowers on Mondays, and keep good, nourishing company. A calm routine, meditation, and time near water steady the mind.',
      'guruchandal' =>
        'Strengthen Jupiter: worship Lord Vishnu or your guru, wear yellow, and chant the Guru mantra on Thursdays. Study scripture and keep the company of wise, ethical people.',
      'shakata' =>
        'Honour the Moon and Jupiter through devotion and charity on Mondays and Thursdays. Build steadiness and long-term thinking, and don\'t get discouraged by the natural ups and downs.',
      'pitra' =>
        'Honour your ancestors: perform Shraddha and Tarpan, offer food to the needy, to crows and to cows, and give in their name during Pitru Paksha. Prayers to the ancestors and to Lord Vishnu bring peace.',
      _ => '',
    };

/// Reference list for the "Learn More" view — (title, description).
const learnMoreYogas = <(String, String)>[
  ('Ruchaka Yoga',
      'Brings courage, leadership and physical strength. Bold doers who do well in defence, sport, or any field that needs a fighter\'s spirit.'),
  ('Bhadra Yoga',
      'Brings a sharp mind, a way with words and a strong business sense. Quick thinkers who succeed in writing, teaching, trade and analysis.'),
  ('Hamsa Yoga',
      'Brings wisdom, good character and respect. People become teachers, advisors or spiritual figures — others come to them for guidance.'),
  ('Malavya Yoga',
      'Brings beauty, charm, comfort and refined taste. Draws in luxury, artistic talent and graceful relationships, often with a striking presence.'),
  ('Shasha Yoga',
      'Brings discipline, authority and slowly-built success. People rise through patience and hard work into respected positions.'),
  ('Gaja Kesari Yoga',
      'Brings fame, prosperity and intelligence. Recognition in your field, with wisdom and influence that grow as you get older.'),
  ('Budha-Aditya Yoga',
      'Brings a sharp mind, clear thinking and strong communication. People shine in academics, government and roles that need mental skill.'),
  ('Chandra-Mangal Yoga',
      'Brings drive, an entrepreneurial spark and the ability to earn through your own efforts, often building a business.'),
  ('Raja Yoga',
      'A general "royal yoga" formed when the lords of lucky houses join forces — bringing power, prestige or unusual success.'),
  ('Dhana Yoga',
      'A "wealth yoga" formed by links between the houses of money — steady build-up of wealth over a lifetime.'),
  ('Neecha Bhanga Raja Yoga',
      'A "cancellation" yoga where a weak planet is restored to full power. A hard start turns dramatically into strength.'),
  ('Vipreet Raja Yoga',
      'An "unexpected" royal yoga where difficulties turn into triumph — your hardest experiences become your biggest wins.'),
];

const learnMoreDoshas = <(String, String)>[
  ('Mangal Dosha (Manglik)',
      'Mars in certain houses creates friction in marriage; how strong it is varies, and many traditional rules can cancel it out.'),
  ('Kaal Sarp Dosha',
      'All the planets sit between Rahu and Ketu. Life feels intense and fated in bursts; the effects often ease after age 30.'),
  ('Shani Sade Sati',
      'A roughly 7½-year cycle as Saturn passes through the signs around the Moon. Testing, but deeply life-changing.'),
  ('Pitra Dosha',
      'Linked to unsettled ancestral karma; may bring obstacles in family, marriage or with children. Remedies involve prayers and offerings.'),
  ('Guru Chandal Dosha',
      'Jupiter with Rahu or Ketu can shake up your faith and judgement, but also makes an original, rule-breaking thinker.'),
  ('Kemadruma Dosha',
      'The Moon sits alone with no support; the mind can feel isolated but grows deeply self-reliant.'),
  ('Shakata Dosha',
      'The Moon and Jupiter in difficult angles; fortunes rise and fall in waves rather than climbing steadily.'),
  ('Nadi Dosha',
      'Mainly a marriage-matching factor — when bride and groom share the same nadi, tradition advises a remedy or some caution.'),
];

const learnMoreYogasHi = <(String, String)>[
  ('रुचक योग',
      'हिम्मत, लीडरशिप और शारीरिक ताकत देता है। निडर, कर्मठ लोग जो रक्षा, खेल या योद्धा जैसा जज़्बा माँगने वाले हर क्षेत्र में सफल होते हैं।'),
  ('भद्र योग',
      'तेज़ दिमाग़, शब्दों पर पकड़ और मज़बूत व्यापार-समझ देता है। तेज़ सोचने वाले जो लेखन, पढ़ाने, व्यापार और विश्लेषण में सफल होते हैं।'),
  ('हंस योग',
      'समझदारी, अच्छा चरित्र और सम्मान देता है। लोग शिक्षक, सलाहकार या आध्यात्मिक व्यक्ति बनते हैं — दूसरे उनसे मार्गदर्शन के लिए आते हैं।'),
  ('मालव्य योग',
      'सुंदरता, आकर्षण, सुकून और परिष्कृत रुचि देता है। ऐशो-आराम, कलात्मक हुनर और मधुर रिश्ते खींचता है, अक्सर एक प्रभावशाली मौजूदगी के साथ।'),
  ('शश योग',
      'अनुशासन, अधिकार और धीरे-धीरे बनी सफलता देता है। लोग धैर्य और मेहनत से सम्मानित पदों तक उठते हैं।'),
  ('गजकेसरी योग',
      'यश, समृद्धि और बुद्धि देता है। अपने क्षेत्र में मान्यता, और उम्र के साथ बढ़ती समझदारी तथा प्रभाव।'),
  ('बुध-आदित्य योग',
      'तेज़ दिमाग़, साफ़ सोच और मज़बूत बातचीत देता है। लोग पढ़ाई, सरकार और दिमाग़ी हुनर माँगने वाली भूमिकाओं में चमकते हैं।'),
  ('चंद्र-मंगल योग',
      'उद्यम, व्यावसायिक ऊर्जा और अपनी मेहनत से कमाने की क्षमता देता है, अक्सर अपना व्यवसाय खड़ा करते हुए।'),
  ('राज योग',
      'शुभ भावों के स्वामी मिलकर बनाते हैं — ताकत, रुतबा या असाधारण सफलता लाता एक आम राजसी योग।'),
  ('धन योग',
      'धन के भावों के आपसी जुड़ाव से बना धन-योग — पूरी ज़िंदगी में स्थिर रूप से जुड़ती दौलत।'),
  ('नीचभंग राज योग',
      'एक भंग योग जहाँ कमज़ोर ग्रह फिर से मज़बूत हो जाता है। कठिन शुरुआत नाटकीय ढंग से ताकत में बदल जाती है।'),
  ('विपरीत राज योग',
      'एक अप्रत्याशित राजसी योग जहाँ मुश्किलें जीत में बदल जाती हैं — सबसे कठिन अनुभव सबसे बड़ी जीत बन जाते हैं।'),
];

const learnMoreDoshasHi = <(String, String)>[
  ('मंगल दोष (मांगलिक)',
      'कुछ भावों में मंगल विवाह में टकराव पैदा करता है; यह कितना प्रबल है यह बदलता रहता है, और कई पारंपरिक नियम इसे रद्द कर सकते हैं।'),
  ('काल सर्प दोष',
      'सारे ग्रह राहु और केतु के बीच। ज़िंदगी झटकों में तीव्र और किस्मत से चलने वाली लगती है; असर अक्सर 30 साल के बाद घटता है।'),
  ('शनि साढ़े साती',
      'लगभग साढ़े 7 साल का चक्र जब शनि चंद्र के आसपास की राशियों से गोचर करता है। कठिन, पर गहराई से ज़िंदगी बदल देने वाला।'),
  ('पितृ दोष',
      'अनसुलझे पितृ-कर्म से जुड़ा; परिवार, विवाह या संतान में रुकावटें ला सकता है। उपाय में प्रार्थना और अर्पण शामिल हैं।'),
  ('गुरु चांडाल दोष',
      'गुरु का राहु या केतु के साथ होना विश्वास और परख को हिला सकता है, पर एक मौलिक, नियम तोड़ने वाला विचारक भी बनाता है।'),
  ('केमद्रुम दोष',
      'चंद्र बिना सहारे अकेला बैठा है; मन अकेला लग सकता है पर गहराई से आत्मनिर्भर बनता है।'),
  ('शकट दोष',
      'चंद्र और गुरु कठिन कोणों में; किस्मत स्थिर चढ़ाई के बजाय लहरों में उठती-गिरती है।'),
  ('नाड़ी दोष',
      'मुख्यतः विवाह-मिलान का कारक — जब वर और वधू की नाड़ी एक जैसी हो, तो परंपरा उपाय या सावधानी की सलाह देती है।'),
];
