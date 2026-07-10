import 'astro_chart.dart';
import 'astrology_data.dart';

/// Life-area (bhava) readings. Each area gives two readings: a sign-keyed
/// portrait of the house, and a personalised reading built from the house
/// ruler's placement and any planets sitting in the house. All text is our own.

class LifeAspect {
  final String label;
  final String body;
  const LifeAspect(this.label, this.body);
}

class LifeArea {
  final String title;
  final String subtitle; // e.g. "Cancer · 4th house"
  final List<LifeAspect> aspects;
  const LifeArea(this.title, this.subtitle, this.aspects);
}

// ---- Sign-keyed portraits (0 = Aries .. 11 = Pisces) ----

const _selfNature = [
  'You come across as bold, direct and quick to act, with a pioneering streak that dislikes waiting. A natural initiator, you meet life head-on and bounce back fast from setbacks.',
  'You present as calm, steady and grounded, valuing comfort, beauty and things that last. You move at your own unhurried pace and are very hard to shake once you settle.',
  'You seem curious, quick-witted and talkative, forever gathering ideas and making connections. Versatile and youthful, you adapt to anything but can scatter your focus.',
  'You give a gentle, caring and sensitive first impression, deeply tuned to mood and belonging. Protective of your own, you lead with feeling and forget nothing.',
  'You carry a warm, dignified and confident presence that naturally draws attention. Generous and proud, you shine when appreciated and lead from the heart.',
  'You appear thoughtful, precise and modest, noticing details others miss. Practical and helpful, you refine everything you touch but can be your own harshest critic.',
  'You come across as graceful, fair-minded and easy to like, forever seeking balance. Relationship-oriented, you weigh every side carefully before you decide.',
  'You project a quiet intensity and magnetic depth, revealing little at first. Determined and perceptive, you feel things powerfully and prize loyalty above all.',
  'You seem open, optimistic and freedom-loving, drawn to big ideas and far horizons. Honest to a fault, you inspire others but resist being fenced in.',
  'You present as serious, capable and self-controlled, with an air of quiet authority. Ambitious and patient, you build slowly and take responsibility to heart.',
  'You come across as independent, original and a little unconventional, marching to your own beat. Humane and future-minded, you connect widely yet stay inwardly detached.',
  'You give a soft, dreamy and compassionate impression, sensitive to everything around you. Imaginative and kind, you feel others\' pain as your own and seek meaning over material.',
];

const _selfNatureHi = [
  'आप साहसी, सीधे और तुरंत काम करने वाले लगते हैं, आगे बढ़ने की ऐसी चाह जो इंतज़ार पसंद नहीं करती। स्वभाव से शुरुआत करने वाले, आप जीवन का सामना डटकर करते हैं और मुश्किलों से जल्दी उबर जाते हैं।',
  'आप शांत, स्थिर और ज़मीन से जुड़े दिखते हैं, आराम, सुंदरता और टिकाऊ चीज़ों को महत्व देते हैं। आप अपनी सहज रफ़्तार से चलते हैं और एक बार टिक जाएं तो आपको हिलाना बहुत मुश्किल है।',
  'आप जिज्ञासु, तेज़ दिमाग़ और बातूनी लगते हैं, हमेशा नए विचार बटोरते और लोगों से जुड़ते रहते हैं। हर बात में ढल जाने वाले और जवान दिल के, पर आपका ध्यान कई जगह बंट सकता है।',
  'पहली नज़र में आप कोमल, ख़्याल रखने वाले और संवेदनशील लगते हैं, मन और अपनेपन को गहराई से भांप लेते हैं। अपनों की रक्षा करते हैं, दिल से चलते हैं और कुछ भी नहीं भूलते।',
  'आपमें एक गर्मजोशी, गरिमा और आत्मविश्वास है जो अपने आप ध्यान खींच लेता है। उदार और स्वाभिमानी, सराहना मिलने पर आप खिल उठते हैं और दिल से आगे बढ़कर राह दिखाते हैं।',
  'आप सोच-समझकर चलने वाले, बारीक़ और विनम्र लगते हैं, वो छोटी बातें भी देख लेते हैं जो दूसरे चूक जाते हैं। व्यावहारिक और मददगार, हर चीज़ को निखारते हैं, पर ख़ुद के सबसे कड़े आलोचक बन जाते हैं।',
  'आप सौम्य, न्यायप्रिय और सबको भाने वाले लगते हैं, हमेशा संतुलन ढूंढते रहते हैं। रिश्तों को अहमियत देते हैं और कोई फ़ैसला लेने से पहले हर पहलू को ध्यान से तौलते हैं।',
  'आपमें एक शांत गहराई और चुम्बकीय आकर्षण है, शुरू में आप बहुत कम खुलते हैं। दृढ़ और पैनी नज़र वाले, हर बात को गहराई से महसूस करते हैं और वफ़ादारी को सबसे ऊपर रखते हैं।',
  'आप खुले दिल, आशावादी और आज़ादी पसंद लगते हैं, बड़े विचारों और दूर की मंज़िलों की ओर खिंचते हैं। हद से ज़्यादा सच्चे, दूसरों को प्रेरित करते हैं, पर बंधना आपको पसंद नहीं।',
  'आप गंभीर, सक्षम और संयमी दिखते हैं, आपमें एक शांत रौब झलकता है। महत्वाकांक्षी और धैर्यवान, आप धीरे-धीरे बनाते हैं और ज़िम्मेदारी को दिल से निभाते हैं।',
  'आप स्वतंत्र, अलग सोच वाले और थोड़े अनोखे लगते हैं, अपनी ही धुन में चलते हैं। मानवीय और भविष्य की सोच रखने वाले, बहुतों से जुड़ते हैं फिर भी भीतर से थोड़े अलग रहते हैं।',
  'आप कोमल, स्वप्निल और करुणामय लगते हैं, आस-पास की हर चीज़ के प्रति संवेदनशील। कल्पनाशील और दयालु, दूसरों के दर्द को अपना समझते हैं और भौतिक से ज़्यादा गहरे अर्थ की तलाश करते हैं।',
];

const _wealthNature = [
  'You earn in bursts through initiative and bold moves, and money comes and goes quickly. Learning to save rather than spend on impulse is your wealth lesson.',
  'You have a powerful instinct for accumulating and holding wealth, and value security deeply. Money tends to grow steadily and stay once it reaches you.',
  'You earn through communication, trade and often more than one income stream at a time. Wealth flows through ideas and words, but scattered spending can leak it away.',
  'You build wealth cautiously and emotionally, saving for family and a sense of safety. Property and home-linked assets often feature strongly.',
  'You attract money through status, leadership and generosity, and enjoy spending on quality. Your wealth is closely tied to your reputation and self-expression.',
  'You manage money carefully, budgeting and tracking every rupee. Wealth grows through skill, service and prudent, methodical saving.',
  'You earn through partnerships and dealings, often work involving beauty or fairness. Money arrives with relationships, though comfort can tempt you to overspend.',
  'Your finances move through cycles of loss and recovery, often involving others\' money, inheritance or hidden sources. You guard your resources fiercely.',
  'You earn through knowledge, teaching, travel or ethical enterprise, and are generally fortunate with money. You are generous, and sometimes over-optimistic in spending.',
  'You build wealth slowly, patiently and through sheer discipline, respecting every rupee. Early scarcity often gives way to solid, lasting accumulation.',
  'You earn in unconventional ways, often through networks, technology or large groups. Money arrives irregularly and is spent as readily on causes as on yourself.',
  'Wealth flows intuitively and sometimes mysteriously, through creative, spiritual or charitable channels. You are generous and must keep your finances clear and honest.',
];

const _wealthNatureHi = [
  'आप पहल और साहसिक क़दमों से रुक-रुककर कमाते हैं, और पैसा जितनी जल्दी आता है उतनी जल्दी चला भी जाता है। मन के बहकावे में ख़र्च करने के बजाय बचत सीखना आपके धन का सबक़ है।',
  'आपमें धन जोड़ने और संभालकर रखने की गहरी समझ है, और सुरक्षा को आप बहुत महत्व देते हैं। पैसा धीरे-धीरे बढ़ता है और एक बार आ जाए तो टिका रहता है।',
  'आप बातचीत, व्यापार और अक्सर एक साथ कई ज़रियों से कमाते हैं। धन विचारों और शब्दों से बहता है, पर बिखरा हुआ ख़र्च उसे रिसा भी सकता है।',
  'आप सोच-समझकर और भावना से धन जोड़ते हैं, परिवार और सुरक्षा के लिए बचाते हैं। संपत्ति और घर से जुड़ी चीज़ें अक्सर आपके जीवन में ख़ास रहती हैं।',
  'आप रुतबे, नेतृत्व और उदारता से पैसा खींचते हैं, और अच्छी चीज़ों पर ख़र्च करना पसंद करते हैं। आपका धन आपकी साख और आपके अंदाज़ से गहराई से जुड़ा है।',
  'आप पैसा बहुत संभलकर संभालते हैं, बजट बनाते और एक-एक रुपये का हिसाब रखते हैं। धन हुनर, सेवा और सोच-समझकर की गई बचत से बढ़ता है।',
  'आप साझेदारी और लेन-देन से कमाते हैं, अक्सर ऐसे काम में जहां सुंदरता या न्याय हो। पैसा रिश्तों के साथ आता है, पर आराम की चाह में ज़्यादा ख़र्च का ख़तरा रहता है।',
  'आपका धन नुक़सान और उबरने के चक्रों से गुज़रता है, अक्सर दूसरों के पैसे, विरासत या छुपे ज़रियों से जुड़ा। आप अपने साधनों की जमकर रक्षा करते हैं।',
  'आप ज्ञान, शिक्षा, यात्रा या ईमानदार कारोबार से कमाते हैं, और पैसे के मामले में आम तौर पर भाग्यशाली रहते हैं। आप उदार हैं, और कभी-कभी ख़र्च में हद से ज़्यादा आशावादी।',
  'आप धन धीरे-धीरे, धैर्य और कड़ी मेहनत से जोड़ते हैं, हर रुपये की क़दर करते हैं। शुरू की तंगी अक्सर आगे चलकर ठोस और टिकाऊ जमा-पूंजी में बदल जाती है।',
  'आप हटकर तरीक़ों से कमाते हैं, अक्सर नेटवर्क, तकनीक या बड़े समूहों के ज़रिए। पैसा अनियमित रूप से आता है और जितनी आसानी से अपने ऊपर, उतनी ही किसी नेक काम पर ख़र्च होता है।',
  'धन सहज रूप से और कभी-कभी रहस्यमय ढंग से बहता है, रचनात्मक, आध्यात्मिक या दान से जुड़े ज़रियों से। आप उदार हैं और आपको अपना हिसाब साफ़ और ईमानदार रखना चाहिए।',
];

const _homeNature = [
  'Your home life is active and independent, sometimes restless, with a strong will running through the household. You may leave your birthplace early to build your own base.',
  'You crave a stable, comfortable and beautiful home, and you put down deep roots. Domestic peace, good food and property bring you genuine happiness.',
  'Your home is lively and full of talk, books and coming-and-going. You may keep two homes or move often, and you need mental stimulation in your surroundings.',
  'Home and mother are the centre of your emotional world, and you feel most yourself in familiar surroundings. You nurture your space and are deeply attached to it.',
  'You want a proud, warm and impressive home that reflects your standing. You are the heart of the household and take pride in hosting and protecting your family.',
  'You keep an orderly, clean and practical home and find peace in routine. You serve your family quietly and tend to worry over domestic details.',
  'You seek a harmonious, tasteful and welcoming home, and your peace depends on good relationships within it. Beauty and balance at home soothe you.',
  'Your domestic life carries emotional intensity and privacy, with deep undercurrents. Inner peace arrives only after you work through family complexity.',
  'Your home is open, philosophical and connected to travel or distant places. You value freedom under your own roof and may live far from where you were born.',
  'You take your home duties seriously and may carry heavy family responsibility early. Real comfort comes with age as you build a solid, respected household.',
  'Your home life is unconventional and independent, perhaps with an unusual family setup. You need mental freedom within the home and prize a wide circle over convention.',
  'Your home is a gentle, spiritual refuge, and you are deeply sensitive to its atmosphere. You seek emotional and spiritual peace within your four walls.',
];

const _homeNatureHi = [
  'आपका घर-जीवन सक्रिय और स्वतंत्र है, कभी-कभी बेचैन, और घर में एक मज़बूत इच्छाशक्ति चलती है। हो सकता है आप जल्दी अपनी जन्मभूमि छोड़कर अपना ठिकाना ख़ुद बनाएं।',
  'आप एक स्थिर, आरामदायक और सुंदर घर चाहते हैं, और गहरी जड़ें जमाते हैं। घर की शांति, अच्छा खाना और संपत्ति आपको सच्ची ख़ुशी देते हैं।',
  'आपका घर हलचल भरा है, बातों, किताबों और आने-जाने से भरा। हो सकता है आप दो घर रखें या बार-बार बदलें, और अपने माहौल में मानसिक ताज़गी चाहते हैं।',
  'घर और माँ आपकी भावनाओं का केंद्र हैं, और जाने-पहचाने माहौल में आप ख़ुद को सबसे ज़्यादा अपना महसूस करते हैं। आप अपने आशियाने को सींचते हैं और उससे गहराई से जुड़े हैं।',
  'आप एक शानदार, गर्मजोशी भरा और प्रभावशाली घर चाहते हैं जो आपके रुतबे को दर्शाए। आप घर की जान हैं और मेहमाननवाज़ी तथा परिवार की रक्षा पर गर्व करते हैं।',
  'आप एक व्यवस्थित, साफ़ और व्यावहारिक घर रखते हैं और नियम-क़ायदे में शांति पाते हैं। आप चुपचाप परिवार की सेवा करते हैं और घर की छोटी बातों की चिंता करते रहते हैं।',
  'आप एक सुरीला, सुरुचिपूर्ण और स्वागत करने वाला घर चाहते हैं, और आपकी शांति घर के अच्छे रिश्तों पर टिकी है। घर की सुंदरता और संतुलन आपको सुकून देते हैं।',
  'आपके घर-जीवन में भावनाओं की गहराई और निजता है, भीतर गहरी लहरें बहती हैं। सच्ची शांति तभी आती है जब आप परिवार की उलझनों को सुलझा लेते हैं।',
  'आपका घर खुला, विचारशील और यात्रा या दूर की जगहों से जुड़ा है। आप अपनी छत के नीचे आज़ादी चाहते हैं और हो सकता है जन्मभूमि से दूर रहें।',
  'आप घर की ज़िम्मेदारियों को गंभीरता से लेते हैं और शायद जल्दी ही परिवार का भारी बोझ उठा लें। असली सुख उम्र के साथ आता है जब आप एक ठोस, सम्मानित घर बनाते हैं।',
  'आपका घर-जीवन हटकर और स्वतंत्र है, शायद परिवार का ढांचा भी कुछ अलग हो। आपको घर में मानसिक आज़ादी चाहिए और आप रीति-रिवाज़ से ज़्यादा एक बड़े दायरे को महत्व देते हैं।',
  'आपका घर एक कोमल, आध्यात्मिक शरणस्थली है, और आप उसके माहौल के प्रति बहुत संवेदनशील हैं। आप अपनी चारदीवारी में भावनात्मक और आध्यात्मिक शांति ढूंढते हैं।',
];

// Health constitution keyed on the Lagna sign.
const _healthNature = [
  'You have a strong, energetic constitution and recover quickly, but you run hot — prone to fevers, headaches and stress from overexertion. Watch the head and blood pressure.',
  'You enjoy sturdy stamina and good resistance, but should mind the throat, neck and a tendency to gain weight from rich food and easy comfort.',
  'Your nervous energy runs high and your health is tied to the mind — care for the lungs, shoulders and hands, and guard against anxiety and restlessness.',
  'You are sensitive to emotion and diet, with the stomach, chest and digestion as weak points. Emotional stress shows up quickly in your body.',
  'You have vital, robust health and a strong heart, but should watch the heart, spine and a tendency to overstrain from pride or overwork.',
  'You are health-conscious and often the family caretaker, but prone to worry and digestive or intestinal sensitivity from an overactive mind.',
  'Your health depends on balance and calm; the kidneys, lower back and sugar levels need attention, and relationship stress affects you physically.',
  'You have deep reserves of strength and remarkable recovery power, but should watch the reproductive and eliminative systems and suppressed emotional strain.',
  'You are generally hearty and active, but the hips, thighs and liver need care, and excess in food, drink or activity is your main risk.',
  'You have endurance that improves with age, but a leaning toward the bones, knees, joints and teeth, and chronic rather than acute complaints.',
  'Your health is tied to circulation and the nervous system; watch the ankles, calves and irregular energy, and guard against nervous strain.',
  'You are sensitive and absorbent, with the feet, lymph and immune system as weak points. Emotional and environmental stress affects you strongly.',
];

const _healthNatureHi = [
  'आपकी सेहत मज़बूत और ऊर्जावान है और आप जल्दी उबर जाते हैं, पर आपका शरीर गर्म रहता है — बुख़ार, सिरदर्द और ज़्यादा मेहनत से तनाव की आशंका रहती है। सिर और रक्तचाप का ध्यान रखें।',
  'आपमें अच्छी सहनशक्ति और रोग से लड़ने की ताक़त है, पर गला, गर्दन और भारी खाने तथा आराम से वज़न बढ़ने की प्रवृत्ति का ध्यान रखें।',
  'आपकी स्नायु-ऊर्जा तेज़ रहती है और सेहत मन से जुड़ी है — फेफड़ों, कंधों और हाथों का ख़्याल रखें, और चिंता तथा बेचैनी से बचें।',
  'आप भावना और खान-पान के प्रति संवेदनशील हैं, और पेट, छाती तथा पाचन आपके कमज़ोर हिस्से हैं। भावनात्मक तनाव आपके शरीर पर जल्दी दिखता है।',
  'आपकी सेहत ओजस्वी और मज़बूत है और दिल दमदार है, पर हृदय, रीढ़ और अभिमान या ज़्यादा काम से खिंचाव का ध्यान रखें।',
  'आप सेहत के प्रति सजग रहते हैं और अक्सर परिवार की देखभाल करने वाले होते हैं, पर ज़्यादा सोचने से चिंता और पेट या आंतों की गड़बड़ी की आशंका रहती है।',
  'आपकी सेहत संतुलन और शांति पर टिकी है; गुर्दे, कमर के निचले हिस्से और शुगर पर ध्यान दें, और रिश्तों का तनाव आप पर शारीरिक असर डालता है।',
  'आपमें गहरी ताक़त और अद्भुत उबरने की शक्ति है, पर प्रजनन और मल-मूत्र तंत्र तथा दबे हुए भावनात्मक तनाव का ध्यान रखें।',
  'आप आम तौर पर हृष्ट-पुष्ट और सक्रिय हैं, पर कूल्हों, जांघों और जिगर का ख़्याल रखें, और खाने-पीने या काम में अति ही आपका सबसे बड़ा ख़तरा है।',
  'आपमें ऐसी सहनशक्ति है जो उम्र के साथ बढ़ती है, पर हड्डियों, घुटनों, जोड़ों और दांतों की ओर झुकाव रहता है, और शिकायतें अचानक नहीं, पुरानी होती हैं।',
  'आपकी सेहत रक्त-संचार और स्नायु तंत्र से जुड़ी है; टख़नों, पिंडलियों और उतार-चढ़ाव वाली ऊर्जा का ध्यान रखें, और स्नायु तनाव से बचें।',
  'आप संवेदनशील हैं और हर चीज़ को जल्दी सोख लेते हैं, पैर, लसीका तंत्र और रोग-प्रतिरोधक शक्ति आपके कमज़ोर हिस्से हैं। भावनात्मक और आस-पास के माहौल का तनाव आप पर गहरा असर करता है।',
];

const _spouseNature = [
  'Your partner is likely independent, energetic and strong-willed, and the relationship is passionate but needs room for two leaders. You are drawn to bold, decisive people.',
  'You seek a loyal, steady and sensual partner who values comfort and commitment. Marriage brings you stability, and you hold on faithfully once bonded.',
  'Your partner is likely clever, communicative and youthful, and you need conversation as much as affection. Variety and mental rapport keep the bond alive.',
  'You want a caring, emotionally present and home-loving partner, and marriage deepens your sense of belonging. You both give and need real tenderness.',
  'Your partner is likely warm, proud and impressive, and you want a relationship you can be proud of. Loyalty, admiration and generosity define the bond.',
  'You seek a capable, sincere and practical partner, and value being genuinely useful to each other. Take care that criticism never crowds out warmth.',
  'You are made for partnership and seek a refined, fair and charming spouse. Harmony, courtesy and true companionship matter enormously to you.',
  'Your bond runs deep, private and intense, and you seek a partner you can trust completely. Passion and loyalty are total, and betrayal is unforgivable.',
  'Your partner is likely honest, independent and philosophical, and you need freedom within the marriage. Shared beliefs and a little adventure keep it alive.',
  'You take marriage seriously and often commit later, seeking a mature, reliable and ambitious partner. The bond strengthens and warms steadily with time.',
  'Your partner is likely unconventional, independent and a friend first, and you need space within the bond. An equal, unpossessive partnership suits you best.',
  'You seek a gentle, devoted and spiritually attuned partner and can be deeply romantic. Guard against idealising a partner beyond who they really are.',
];

const _spouseNatureHi = [
  'आपका जीवनसाथी संभवतः स्वतंत्र, ऊर्जावान और दृढ़-इच्छाशक्ति वाला होगा, और रिश्ता जोशीला रहेगा पर दो अगुवाओं के लिए जगह चाहेगा। आप साहसी, निर्णय लेने वाले लोगों की ओर खिंचते हैं।',
  'आप एक वफ़ादार, स्थिर और प्रेमपूर्ण साथी चाहते हैं जो आराम और प्रतिबद्धता को महत्व दे। विवाह आपको स्थिरता देता है, और एक बार जुड़ जाएं तो आप निभाते हैं।',
  'आपका जीवनसाथी संभवतः चतुर, बातूनी और जवान दिल का होगा, और आपको स्नेह जितनी ही बातचीत भी चाहिए। नएपन और मन के मेल से रिश्ता जीवंत रहता है।',
  'आप एक ख़्याल रखने वाला, भावनाओं से जुड़ा और घर से प्यार करने वाला साथी चाहते हैं, और विवाह आपके अपनेपन को गहरा करता है। आप दोनों सच्ची कोमलता देते और चाहते हैं।',
  'आपका जीवनसाथी संभवतः गर्मजोशी भरा, स्वाभिमानी और प्रभावशाली होगा, और आप ऐसा रिश्ता चाहते हैं जिस पर गर्व हो। वफ़ादारी, सराहना और उदारता इस बंधन को परिभाषित करती हैं।',
  'आप एक सक्षम, सच्चे और व्यावहारिक साथी चाहते हैं, और एक-दूसरे के सचमुच काम आने को महत्व देते हैं। ध्यान रखें कि आलोचना कभी गर्मजोशी पर हावी न हो जाए।',
  'आप साझेदारी के लिए ही बने हैं और एक सुरुचिपूर्ण, न्यायप्रिय और आकर्षक जीवनसाथी चाहते हैं। मेल-मिलाप, शिष्टाचार और सच्चा साथ आपके लिए बहुत मायने रखते हैं।',
  'आपका बंधन गहरा, निजी और तीव्र होता है, और आप ऐसा साथी चाहते हैं जिस पर पूरा भरोसा कर सकें। प्रेम और वफ़ादारी पूर्ण होते हैं, और विश्वासघात अक्षम्य।',
  'आपका जीवनसाथी संभवतः सच्चा, स्वतंत्र और विचारशील होगा, और आपको विवाह में भी आज़ादी चाहिए। साझा विश्वास और थोड़ा रोमांच रिश्ते को जीवंत रखते हैं।',
  'आप विवाह को गंभीरता से लेते हैं और अक्सर देर से बंधते हैं, एक परिपक्व, भरोसेमंद और महत्वाकांक्षी साथी चाहते हैं। बंधन समय के साथ लगातार मज़बूत और गर्म होता जाता है।',
  'आपका जीवनसाथी संभवतः हटकर, स्वतंत्र और पहले एक दोस्त होगा, और आपको बंधन में भी अपनी जगह चाहिए। एक बराबरी वाली, बिना अधिकार जताए साझेदारी आपको सबसे भाती है।',
  'आप एक कोमल, समर्पित और आध्यात्मिक रूप से जुड़े साथी चाहते हैं और बहुत रोमांटिक हो सकते हैं। ध्यान रखें कि साथी को उसके असल रूप से ज़्यादा आदर्श न बना लें।',
];

const _fortuneNature = [
  'Fortune favours your courage and initiative — luck comes when you act first and lead. Your beliefs are direct and self-forged rather than inherited.',
  'Your good fortune builds steadily and is tied to values, comfort and the material blessings of life. You hold traditional, grounded beliefs.',
  'Luck comes through learning, communication and versatility, and you question everything before you believe it. Teachers and ideas shape your path.',
  'Your fortune is emotional and family-linked, and faith is felt rather than reasoned. Blessings often flow through the mother\'s side and your roots.',
  'You are fortunate through your own dignity, leadership and generosity, and you hold proud, heartfelt beliefs. Blessings arrive with recognition.',
  'Luck comes through service, skill and careful effort rather than windfalls. Your faith is practical and you prefer reason to blind belief.',
  'Fortune flows through relationships, fairness and partnerships, and you seek balanced, ethical philosophies. Justice is your guiding principle.',
  'Your fortune moves through deep transformations, and you are drawn to hidden and occult knowledge. Faith is tested and rebuilt through crisis.',
  'You are naturally lucky, principled and drawn to higher learning, philosophy and long journeys. This is fortune\'s own sign, and blessings arrive readily.',
  'Fortune is earned through discipline and patience rather than gifted, and you respect tradition and authority. Blessings ripen slowly but last.',
  'Your luck comes through unconventional paths, networks and humanitarian ideals. You question dogma and forge a progressive personal philosophy.',
  'You are blessed with intuition, compassion and spiritual grace, and fortune flows through faith and surrender. Pilgrimage and devotion uplift you.',
];

const _fortuneNatureHi = [
  'भाग्य आपके साहस और पहल का साथ देता है — जब आप पहले क़दम बढ़ाते और अगुवाई करते हैं, तब क़िस्मत खुलती है। आपकी आस्था सीधी और अपने अनुभव से गढ़ी होती है, विरासत में मिली नहीं।',
  'आपका सौभाग्य धीरे-धीरे बनता है और मूल्यों, आराम तथा जीवन की भौतिक कृपा से जुड़ा है। आपकी आस्था पारंपरिक और ज़मीन से जुड़ी होती है।',
  'भाग्य सीखने, बातचीत और हर बात में ढलने से आता है, और मानने से पहले आप हर चीज़ पर सवाल करते हैं। गुरु और विचार आपकी राह गढ़ते हैं।',
  'आपका भाग्य भावनाओं और परिवार से जुड़ा है, और आस्था तर्क से नहीं, दिल से महसूस होती है। कृपा अक्सर माँ के पक्ष और आपकी जड़ों से बहती है।',
  'आप अपनी गरिमा, नेतृत्व और उदारता से भाग्यशाली होते हैं, और आपकी आस्था स्वाभिमानी तथा दिल से होती है। पहचान मिलने के साथ आशीर्वाद आते हैं।',
  'भाग्य सेवा, हुनर और सोच-समझकर की गई मेहनत से आता है, अचानक की कमाई से नहीं। आपकी आस्था व्यावहारिक है और आप अंधविश्वास से ज़्यादा तर्क को पसंद करते हैं।',
  'भाग्य रिश्तों, न्याय और साझेदारी से बहता है, और आप संतुलित, नैतिक विचारधारा ढूंढते हैं। न्याय आपका मार्गदर्शक सिद्धांत है।',
  'आपका भाग्य गहरे बदलावों से गुज़रता है, और आप छुपे तथा गूढ़ ज्ञान की ओर खिंचते हैं। आस्था संकट में परखी जाती है और फिर से गढ़ी जाती है।',
  'आप स्वभाव से भाग्यशाली, सिद्धांतवादी और उच्च शिक्षा, दर्शन तथा लंबी यात्राओं की ओर झुके होते हैं। यह भाग्य की अपनी राशि है, और आशीर्वाद सहज ही आते हैं।',
  'भाग्य अनुशासन और धैर्य से कमाया जाता है, उपहार में नहीं मिलता, और आप परंपरा तथा बड़ों का सम्मान करते हैं। आशीर्वाद धीरे पकते हैं पर टिकते हैं।',
  'आपका भाग्य हटकर राहों, नेटवर्क और मानवता के आदर्शों से आता है। आप रूढ़ियों पर सवाल करते हैं और एक प्रगतिशील निजी जीवन-दर्शन गढ़ते हैं।',
  'आप अंतर्ज्ञान, करुणा और आध्यात्मिक कृपा से धन्य हैं, और भाग्य आस्था तथा समर्पण से बहता है। तीर्थ और भक्ति आपको ऊपर उठाते हैं।',
];

const _careerNature = [
  'You thrive in careers demanding initiative, leadership and courage — defence, sport, engineering, surgery or your own venture. You need to be the one who acts.',
  'You suit stable, value-building fields — finance, real estate, food, art, luxury or agriculture. You build a solid reputation through sheer reliability.',
  'You excel in communication-driven work — writing, media, sales, teaching, trade or technology. Versatility and quick wit are your professional assets.',
  'You do well in nurturing or public-facing fields — hospitality, healthcare, food, property or work serving the masses. Emotional intelligence is your edge.',
  'You shine in leadership, government, management or entertainment — any role with visibility and authority. You need recognition and a stage.',
  'You excel in detail-oriented, analytical or service fields — health, accounting, editing, research or administration. Precision builds your name.',
  'You suit relational and aesthetic careers — law, diplomacy, design, counselling, luxury or partnership ventures. Fairness and charm carry you forward.',
  'You thrive in investigative or transformative fields — medicine, psychology, investigation, insurance or the occult. You handle what others avoid.',
  'You do well in teaching, law, publishing, travel, consulting or spiritual fields. Your reputation grows through wisdom and ethics.',
  'You are built for structured, ambitious careers — management, administration, engineering, government or long-haul enterprise. Authority comes with time.',
  'You suit innovative, technological or humanitarian fields — science, social work, networks or unconventional group ventures. You reform from within.',
  'You excel in creative, healing or spiritual work — art, film, medicine, charity or anything imaginative. Compassion quietly shapes your calling.',
];

const _careerNatureHi = [
  'आप ऐसे कामों में फलते-फूलते हैं जहां पहल, नेतृत्व और साहस चाहिए — रक्षा, खेल, इंजीनियरिंग, सर्जरी या अपना ख़ुद का उद्यम। आपको वही बनना है जो पहले क़दम बढ़ाए।',
  'आप स्थिर, मूल्य बनाने वाले क्षेत्रों के लिए उपयुक्त हैं — वित्त, संपत्ति, खान-पान, कला, विलासिता या खेती। आप अपनी भरोसेमंदी से एक ठोस साख बनाते हैं।',
  'आप बातचीत-आधारित कामों में उत्कृष्ट हैं — लेखन, मीडिया, बिक्री, शिक्षण, व्यापार या तकनीक। हर बात में ढलना और तेज़ बुद्धि आपकी पेशेवर ताक़त है।',
  'आप देखभाल या जनता से जुड़े क्षेत्रों में अच्छा करते हैं — आतिथ्य, स्वास्थ्य, खान-पान, संपत्ति या जन-सेवा का काम। भावनात्मक समझ आपकी ख़ासियत है।',
  'आप नेतृत्व, सरकार, प्रबंधन या मनोरंजन में चमकते हैं — कोई भी भूमिका जहां रुतबा और अधिकार हो। आपको पहचान और एक मंच चाहिए।',
  'आप बारीक़ी, विश्लेषण या सेवा वाले क्षेत्रों में उत्कृष्ट हैं — स्वास्थ्य, लेखा, संपादन, शोध या प्रशासन। सटीकता आपका नाम बनाती है।',
  'आप रिश्तों और सौंदर्य से जुड़े कामों के लिए उपयुक्त हैं — क़ानून, कूटनीति, डिज़ाइन, परामर्श, विलासिता या साझेदारी के उद्यम। न्याय और आकर्षण आपको आगे ले जाते हैं।',
  'आप जांच या गहरे बदलाव वाले क्षेत्रों में फलते हैं — चिकित्सा, मनोविज्ञान, जांच, बीमा या गूढ़ विद्या। जिससे दूसरे कतराते हैं, उसे आप संभाल लेते हैं।',
  'आप शिक्षण, क़ानून, प्रकाशन, यात्रा, परामर्श या आध्यात्मिक क्षेत्रों में अच्छा करते हैं। आपकी साख ज्ञान और नैतिकता से बढ़ती है।',
  'आप संगठित, महत्वाकांक्षी कामों के लिए बने हैं — प्रबंधन, प्रशासन, इंजीनियरिंग, सरकार या लंबे समय के उद्यम। अधिकार समय के साथ आता है।',
  'आप नए, तकनीकी या मानवीय क्षेत्रों के लिए उपयुक्त हैं — विज्ञान, समाजसेवा, नेटवर्क या हटकर सामूहिक उद्यम। आप भीतर से ही सुधार लाते हैं।',
  'आप रचनात्मक, उपचार या आध्यात्मिक कामों में उत्कृष्ट हैं — कला, फ़िल्म, चिकित्सा, दान या कोई भी कल्पनाशील काम। करुणा चुपचाप आपकी राह गढ़ती है।',
];

const _gainsNature = [
  'Gains come through bold action, competition and self-driven ventures, and your friends are energetic go-getters. You fulfil desires by chasing them directly.',
  'Income accumulates steadily and your circle is loyal and well-established. You gain through patience and value long-standing connections.',
  'Gains flow through networks, ideas and multiple channels, and your friends are clever and varied. Communication turns contacts into profit.',
  'You gain through caring communities and emotional bonds, and your friends feel like family. Your income is closely tied to nurturing others.',
  'Gains come through leadership, status and influential friends. You attract powerful allies and fulfil ambitions through recognition.',
  'Income grows through skill, service and useful connections, and you help your circle practically. Your gains are quietly earned through diligence.',
  'You gain through partnerships and a wide, harmonious social circle. Cooperation and fairness turn relationships into real rewards.',
  'Gains arrive in intense cycles, often through shared or hidden resources, and your friendships are few but profound. You invest deeply in a chosen few.',
  'Income flows generously through knowledge, mentors and ethical ventures, and your friends are wise and worldly. Optimism attracts abundance.',
  'Gains are large but slow, earned through disciplined effort and senior, established connections. Your circle is small, serious and lasting.',
  'You gain through large networks, technology and unconventional means, and your friends span every walk of life. Group efforts fulfil your ideals.',
  'Income arrives intuitively through creative or charitable channels, and your circle is compassionate and artistic. You gain, quietly, by giving.',
];

const _gainsNatureHi = [
  'लाभ साहसिक क़दमों, मुक़ाबले और अपने दम पर किए उद्यमों से आता है, और आपके दोस्त ऊर्जावान, आगे बढ़ने वाले होते हैं। आप अपनी इच्छाओं को सीधे उनके पीछे भागकर पूरा करते हैं।',
  'आय धीरे-धीरे जमा होती है और आपका दायरा वफ़ादार तथा जमा-जमाया होता है। आप धैर्य से लाभ पाते हैं और पुराने रिश्तों को महत्व देते हैं।',
  'लाभ नेटवर्क, विचारों और कई ज़रियों से बहता है, और आपके दोस्त चतुर तथा भांति-भांति के होते हैं। बातचीत आपके संपर्कों को मुनाफ़े में बदल देती है।',
  'आप ख़्याल रखने वाले समुदायों और भावनात्मक रिश्तों से लाभ पाते हैं, और आपके दोस्त परिवार जैसे लगते हैं। आपकी आय दूसरों की देखभाल से गहराई से जुड़ी है।',
  'लाभ नेतृत्व, रुतबे और प्रभावशाली दोस्तों से आता है। आप ताक़तवर साथी खींचते हैं और पहचान के ज़रिए अपनी महत्वाकांक्षाएं पूरी करते हैं।',
  'आय हुनर, सेवा और काम के संपर्कों से बढ़ती है, और आप अपने दायरे की व्यावहारिक मदद करते हैं। आपका लाभ चुपचाप मेहनत से कमाया जाता है।',
  'आप साझेदारी और एक बड़े, सुरीले सामाजिक दायरे से लाभ पाते हैं। सहयोग और न्याय रिश्तों को सच्चे इनाम में बदल देते हैं।',
  'लाभ तीव्र चक्रों में आता है, अक्सर साझा या छुपे साधनों से, और आपकी दोस्तियां कम पर गहरी होती हैं। आप चुने हुए कुछ लोगों में गहराई से निवेश करते हैं।',
  'आय उदारता से ज्ञान, गुरुओं और नैतिक उद्यमों से बहती है, और आपके दोस्त बुद्धिमान तथा दुनियादार होते हैं। आशावाद समृद्धि खींचता है।',
  'लाभ बड़ा पर धीमा होता है, अनुशासित मेहनत और बड़े, जमे-जमाए संपर्कों से कमाया जाता है। आपका दायरा छोटा, गंभीर और टिकाऊ होता है।',
  'आप बड़े नेटवर्क, तकनीक और हटकर तरीक़ों से लाभ पाते हैं, और आपके दोस्त जीवन के हर क्षेत्र से होते हैं। सामूहिक प्रयास आपके आदर्शों को पूरा करते हैं।',
  'आय सहज रूप से रचनात्मक या दान के ज़रियों से आती है, और आपका दायरा करुणामय तथा कलात्मक होता है। आप चुपचाप, देकर, लाभ पाते हैं।',
];

const _spiritNature = [
  'Your spiritual path is active and self-driven — you find liberation through courage, action and conquering the ego head-on. Rest and surrender are your lessons.',
  'You reach the inner world through beauty, devotion and the senses stilled, finding peace in quiet retreat. Loosening attachment is your real work.',
  'Your spirituality is questioning and study-driven, and you free the mind through knowledge and mantra. Quieting the restless mind is the whole path.',
  'You touch the divine through feeling, devotion and surrender, and are deeply drawn to the mother aspect of God. Emotional release is your liberation.',
  'Your path is devotional and heartfelt, worshipping with warmth and dignity. Dissolving pride into humility opens the inner door.',
  'You approach spirituality through service, discipline and purification, finding the sacred in careful practice. Surrendering the need to control is your lesson.',
  'You find liberation through relationship, harmony and seeing the divine in others. Balance and letting go of judgment lead you inward.',
  'Your path runs through deep transformation, crisis and the occult, and you are a natural mystic. The death of the ego is your gateway to rebirth.',
  'You are drawn to philosophy, pilgrimage and higher wisdom, and seek liberation through faith and truth. Teachers and journeys light your way.',
  'Your path is disciplined and earned, through renunciation, patience and steady practice. You reach the heights by climbing slowly and releasing ambition.',
  'You seek liberation through detachment, universal love and unconventional practice. Serving humanity is how you dissolve the separate self.',
  'This is the sign of moksha itself — you are naturally intuitive, devotional and drawn to dissolution into the divine. Surrender and compassion are your whole path.',
];

const _spiritNatureHi = [
  'आपकी आध्यात्मिक राह सक्रिय और अपने दम पर चलने वाली है — आप साहस, कर्म और अहंकार को सीधे जीतकर मुक्ति पाते हैं। विश्राम और समर्पण आपके सबक़ हैं।',
  'आप सुंदरता, भक्ति और शांत इंद्रियों से भीतरी संसार तक पहुंचते हैं, एकांत में शांति पाते हैं। मोह को ढीला करना ही आपका असली काम है।',
  'आपकी आध्यात्मिकता सवाल करने और अध्ययन से भरी है, और आप ज्ञान तथा मंत्र से मन को मुक्त करते हैं। बेचैन मन को शांत करना ही पूरी राह है।',
  'आप भावना, भक्ति और समर्पण से ईश्वर को छूते हैं, और ईश्वर के मातृ-रूप की ओर गहराई से खिंचते हैं। भावनाओं का बह जाना ही आपकी मुक्ति है।',
  'आपकी राह भक्ति और दिल से भरी है, आप गर्मजोशी और गरिमा से पूजा करते हैं। अभिमान को विनम्रता में घोलना भीतरी द्वार खोल देता है।',
  'आप सेवा, अनुशासन और शुद्धि से आध्यात्मिकता तक पहुंचते हैं, सावधान साधना में पवित्रता पाते हैं। नियंत्रण की चाह को छोड़ना ही आपका सबक़ है।',
  'आप रिश्तों, मेल-मिलाप और दूसरों में ईश्वर देखकर मुक्ति पाते हैं। संतुलन और निर्णय छोड़ना आपको भीतर की ओर ले जाता है।',
  'आपकी राह गहरे बदलाव, संकट और गूढ़ विद्या से गुज़रती है, और आप स्वभाव से एक रहस्यदर्शी हैं। अहंकार का मिटना ही आपके पुनर्जन्म का द्वार है।',
  'आप दर्शन, तीर्थ और उच्च ज्ञान की ओर खिंचते हैं, और आस्था तथा सत्य से मुक्ति ढूंढते हैं। गुरु और यात्राएं आपकी राह रोशन करती हैं।',
  'आपकी राह अनुशासित और कमाई हुई है, त्याग, धैर्य और निरंतर साधना से। आप धीरे-धीरे चढ़कर और महत्वाकांक्षा को छोड़कर ऊंचाइयों तक पहुंचते हैं।',
  'आप वैराग्य, विश्व-प्रेम और हटकर साधना से मुक्ति ढूंढते हैं। मानवता की सेवा ही वह तरीक़ा है जिससे आप अपने अलगाव को घोल देते हैं।',
  'यह मोक्ष की अपनी राशि है — आप स्वभाव से अंतर्ज्ञानी, भक्त और ईश्वर में विलीन होने की ओर खिंचे हुए हैं। समर्पण और करुणा ही आपकी पूरी राह है।',
];

// What each house (1..12) connects the ruler to.
const _houseArea = [
  'your identity and vitality',
  'wealth, speech and family',
  'courage, effort and communication',
  'home, mother and inner peace',
  'creativity, romance and children',
  'health, work and daily challenges',
  'marriage and partnerships',
  'transformation, secrets and shared resources',
  'fortune, dharma and higher learning',
  'career and public standing',
  'gains, friendships and ambitions',
  'spirituality, expenses and foreign lands',
];

const _houseAreaHi = [
  'आपकी पहचान और जीवनशक्ति',
  'धन, वाणी और परिवार',
  'साहस, मेहनत और संवाद',
  'घर, माँ और भीतरी शांति',
  'रचनात्मकता, प्रेम और संतान',
  'सेहत, काम और रोज़मर्रा की चुनौतियां',
  'विवाह और साझेदारी',
  'बदलाव, राज़ और साझा साधन',
  'भाग्य, धर्म और उच्च ज्ञान',
  'करियर और सामाजिक प्रतिष्ठा',
  'लाभ, दोस्ती और महत्वाकांक्षाएं',
  'आध्यात्मिकता, ख़र्च और विदेश',
];

// Own signs and exaltation sign of each planet (for a dignity note).
const _own = {
  'sun': {4},
  'moon': {3},
  'mars': {0, 7},
  'mercury': {2, 5},
  'jupiter': {8, 11},
  'venus': {1, 6},
  'saturn': {9, 10},
};
const _exalt = {
  'sun': 0, 'moon': 1, 'mars': 9, 'mercury': 5,
  'jupiter': 3, 'venus': 11, 'saturn': 6,
};
const _signLord = [
  'mars', 'venus', 'mercury', 'moon', 'sun', 'mercury',
  'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter',
];
const _planetInfluence = {
  'sun': 'authority, confidence and visibility',
  'moon': 'emotional depth and a caring, changeable tone',
  'mars': 'drive, energy and the odd spark of friction',
  'mercury': 'intellect, skill and communication',
  'jupiter': 'growth, wisdom, protection and good fortune',
  'venus': 'grace, comfort, beauty and pleasure',
  'saturn': 'discipline, delay and slow but lasting rewards',
  'rahu': 'ambition, intensity and unconventional turns',
  'ketu': 'detachment, mystery and a spiritual undercurrent',
};

const _planetInfluenceHi = {
  'sun': 'अधिकार, आत्मविश्वास और चमक',
  'moon': 'भावनाओं की गहराई और एक कोमल, बदलता स्वभाव',
  'mars': 'जोश, ऊर्जा और कभी-कभी थोड़ी टकराहट',
  'mercury': 'बुद्धि, हुनर और संवाद',
  'jupiter': 'वृद्धि, ज्ञान, रक्षा और सौभाग्य',
  'venus': 'सौम्यता, आराम, सुंदरता और सुख',
  'saturn': 'अनुशासन, देरी और धीमे पर टिकाऊ फल',
  'rahu': 'महत्वाकांक्षा, तीव्रता और हटकर मोड़',
  'ketu': 'वैराग्य, रहस्य और एक आध्यात्मिक धारा',
};

// (title, house, areaWord, primaryLabel, primaryBank, primarySignHouse, secondaryLabel)
const _areaDefs = <(String, int, String, String, List<String>, int, String)>[
  ('Personality & Self', 1, 'sense of self', 'Core Nature', _selfNature, 1, 'What Shapes It'),
  ('Wealth & Finances', 2, 'wealth', 'Money & Savings', _wealthNature, 2, 'How It Flows'),
  ('Home & Happiness', 4, 'domestic peace', 'Home & Heart', _homeNature, 4, 'Your Foundations'),
  ('Health & Vitality', 6, 'health', 'Constitution', _healthNature, 1, 'Effort & Immunity'),
  ('Marriage & Partnership', 7, 'married life', 'Your Partner', _spouseNature, 7, 'The Bond'),
  ('Fortune & Dharma', 9, 'fortune', 'Luck & Faith', _fortuneNature, 9, 'Blessings & Teachers'),
  ('Career & Reputation', 10, 'career', 'Your Calling', _careerNature, 10, 'Reputation & Status'),
  ('Gains & Aspirations', 11, 'gains', 'Gains & Friends', _gainsNature, 11, 'Fulfilment of Desires'),
  ('Spirituality & Liberation', 12, 'inner path', 'Inner Path', _spiritNature, 12, 'Letting Go'),
];

// Hindi parallel of _areaDefs (same order; house/signHouse taken from _areaDefs).
const _areaDefsHi = <(String, String, String, List<String>, String)>[
  ('व्यक्तित्व और स्वयं', 'अपनेपन का भाव', 'मूल स्वभाव', _selfNatureHi, 'इसे क्या गढ़ता है'),
  ('धन और आर्थिक स्थिति', 'धन', 'पैसा और बचत', _wealthNatureHi, 'यह कैसे बहता है'),
  ('घर और सुख', 'घरेलू शांति', 'घर और दिल', _homeNatureHi, 'आपकी नींव'),
  ('सेहत और जीवनशक्ति', 'सेहत', 'शारीरिक गठन', _healthNatureHi, 'मेहनत और रोग-प्रतिरोध'),
  ('विवाह और साझेदारी', 'वैवाहिक जीवन', 'आपका जीवनसाथी', _spouseNatureHi, 'यह बंधन'),
  ('भाग्य और धर्म', 'भाग्य', 'क़िस्मत और आस्था', _fortuneNatureHi, 'आशीर्वाद और गुरु'),
  ('करियर और प्रतिष्ठा', 'करियर', 'आपका बुलावा', _careerNatureHi, 'साख और रुतबा'),
  ('लाभ और आकांक्षाएं', 'लाभ', 'लाभ और दोस्त', _gainsNatureHi, 'इच्छाओं की पूर्ति'),
  ('आध्यात्मिकता और मुक्ति', 'भीतरी राह', 'भीतरी राह', _spiritNatureHi, 'छोड़ देना'),
];

String _ordinal(int h) => switch (h) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '${h}th',
    };

// Hindi ordinal for houses ("पहले", "दूसरे" … "बारहवें" भाव).
const _hindiOrdinals = [
  'पहले', 'दूसरे', 'तीसरे', 'चौथे', 'पांचवें', 'छठे',
  'सातवें', 'आठवें', 'नौवें', 'दसवें', 'ग्यारहवें', 'बारहवें',
];
String _hindiOrdinal(int h) =>
    (h >= 1 && h <= 12) ? _hindiOrdinals[h - 1] : '$hवें';

String _joinHi(List<String> items) {
  if (items.length == 1) return items.first;
  if (items.length == 2) return '${items[0]} और ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')} और ${items.last}';
}

List<LifeArea> computeLifeAreas(BirthChart chart, [bool hi = false]) {
  final out = <LifeArea>[];
  for (var i = 0; i < _areaDefs.length; i++) {
    final (title, house, areaWord, primaryLabel, bank, signHouse, secondaryLabel) =
        _areaDefs[i];
    final (titleHi, areaWordHi, primaryLabelHi, bankHi, secondaryLabelHi) =
        _areaDefsHi[i];

    final primarySign = (chart.lagnaRashi + signHouse - 1) % 12;
    final houseSign = (chart.lagnaRashi + house - 1) % 12;

    // Primary: sign portrait.
    final primary = LifeAspect(
      hi ? primaryLabelHi : primaryLabel,
      hi
          ? 'इस क्षेत्र पर ${signNames[primarySign](true)} का असर है। ${bankHi[primarySign]}'
          : '${signNames[primarySign].en} shapes this area of your life. ${bank[primarySign]}',
    );

    // Secondary: house-ruler placement + planets here.
    final lord = _signLord[houseSign];
    final lordName = planetInfo[lord]!.name(hi);
    final lordPlaced = chart.byKey(lord);
    final lordHouse = lordPlaced.house;
    final lordSign = lordPlaced.graha.rashi;

    final strong =
        (_own[lord]?.contains(lordSign) ?? false) || _exalt[lord] == lordSign;
    final dusthana = lordHouse == 6 || lordHouse == 8 || lordHouse == 12;
    final good = [1, 4, 5, 7, 9, 10].contains(lordHouse);

    final sb = StringBuffer();
    if (hi) {
      sb.write('इस क्षेत्र का स्वामी, $lordName, आपके ${_hindiOrdinal(lordHouse)} '
          'भाव में बैठा है — आपके $areaWordHi को ${_houseAreaHi[lordHouse - 1]} से जोड़ता है।');
      if (strong) {
        sb.write(' यह अपनी या उच्च राशि में विराजमान है, जो यहां सच्ची ताक़त का स्रोत है।');
      } else if (dusthana) {
        sb.write(
            ' एक चुनौतीपूर्ण भाव में बैठा होने से, यह क्षेत्र टिकने से पहले शुरू में परखा जा सकता है।');
      } else if (good) {
        sb.write(' एक सहायक भाव में अच्छी तरह बैठा, यह इस क्षेत्र को टिकाऊ मज़बूती देता है।');
      }
    } else {
      sb.write(
          'The ruler of this area, $lordName, sits in your ${_ordinal(lordHouse)} '
          'house — connecting your $areaWord to ${_houseArea[lordHouse - 1]}.');
      if (strong) {
        sb.write(
            ' It rests in its own or exaltation sign, a real source of strength here.');
      } else if (dusthana) {
        sb.write(
            ' Placed in a challenging house, this area may be tested early before it settles.');
      } else if (good) {
        sb.write(' Well placed in a supportive house, it lends this area lasting strength.');
      }
    }

    final planets = chart.grahas
        .where((p) => p.house == house)
        .map((p) => p.graha.key)
        .toList();
    if (planets.isNotEmpty) {
      if (hi) {
        final names = planets.map((k) => planetInfo[k]!.name(true)).toList();
        final infl = planets.map((k) => _planetInfluenceHi[k]).join('; ');
        final verb = planets.length == 1 ? 'बैठा है' : 'बैठे हैं';
        sb.write(' ${_joinHi(names)} सीधे इसी भाव में $verb, जो $infl जोड़ते हैं।');
      } else {
        final names = planets.map((k) => planetInfo[k]!.name.en).toList();
        final infl = planets.map((k) => _planetInfluence[k]).join('; ');
        final verb = planets.length == 1 ? 'sits' : 'sit';
        sb.write(
            ' ${_join(names)} $verb directly in this house, adding $infl.');
      }
    }

    out.add(LifeArea(
      hi ? titleHi : title,
      hi
          ? '${signNames[houseSign](true)} · ${_hindiOrdinal(house)} भाव'
          : '${signNames[houseSign].en} · ${_ordinal(house)} house',
      [
        primary,
        LifeAspect(hi ? secondaryLabelHi : secondaryLabel, sb.toString())
      ],
    ));
  }
  return out;
}

String _join(List<String> items) {
  if (items.length == 1) return items.first;
  if (items.length == 2) return '${items[0]} and ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
