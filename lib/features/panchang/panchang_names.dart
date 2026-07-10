// Traditional Vedic panchang name lists (public-domain Sanskrit terms).

class NamePair {
  final String en;
  final String hi;
  const NamePair(this.en, this.hi);
  String call(bool hindi) => hindi ? hi : en;
}

const tithiNames = <NamePair>[
  NamePair('Pratipada', 'प्रतिपदा'), NamePair('Dwitiya', 'द्वितीया'),
  NamePair('Tritiya', 'तृतीया'), NamePair('Chaturthi', 'चतुर्थी'),
  NamePair('Panchami', 'पंचमी'), NamePair('Shashthi', 'षष्ठी'),
  NamePair('Saptami', 'सप्तमी'), NamePair('Ashtami', 'अष्टमी'),
  NamePair('Navami', 'नवमी'), NamePair('Dashami', 'दशमी'),
  NamePair('Ekadashi', 'एकादशी'), NamePair('Dwadashi', 'द्वादशी'),
  NamePair('Trayodashi', 'त्रयोदशी'), NamePair('Chaturdashi', 'चतुर्दशी'),
  NamePair('Purnima', 'पूर्णिमा'),
  NamePair('Pratipada', 'प्रतिपदा'), NamePair('Dwitiya', 'द्वितीया'),
  NamePair('Tritiya', 'तृतीया'), NamePair('Chaturthi', 'चतुर्थी'),
  NamePair('Panchami', 'पंचमी'), NamePair('Shashthi', 'षष्ठी'),
  NamePair('Saptami', 'सप्तमी'), NamePair('Ashtami', 'अष्टमी'),
  NamePair('Navami', 'नवमी'), NamePair('Dashami', 'दशमी'),
  NamePair('Ekadashi', 'एकादशी'), NamePair('Dwadashi', 'द्वादशी'),
  NamePair('Trayodashi', 'त्रयोदशी'), NamePair('Chaturdashi', 'चतुर्दशी'),
  NamePair('Amavasya', 'अमावस्या'),
];

const nakshatraNames = <NamePair>[
  NamePair('Ashwini', 'अश्विनी'), NamePair('Bharani', 'भरणी'),
  NamePair('Krittika', 'कृत्तिका'), NamePair('Rohini', 'रोहिणी'),
  NamePair('Mrigashira', 'मृगशिरा'), NamePair('Ardra', 'आर्द्रा'),
  NamePair('Punarvasu', 'पुनर्वसु'), NamePair('Pushya', 'पुष्य'),
  NamePair('Ashlesha', 'आश्लेषा'), NamePair('Magha', 'मघा'),
  NamePair('Purva Phalguni', 'पूर्वा फाल्गुनी'), NamePair('Uttara Phalguni', 'उत्तरा फाल्गुनी'),
  NamePair('Hasta', 'हस्त'), NamePair('Chitra', 'चित्रा'),
  NamePair('Swati', 'स्वाति'), NamePair('Vishakha', 'विशाखा'),
  NamePair('Anuradha', 'अनुराधा'), NamePair('Jyeshtha', 'ज्येष्ठा'),
  NamePair('Mula', 'मूल'), NamePair('Purva Ashadha', 'पूर्वाषाढ़ा'),
  NamePair('Uttara Ashadha', 'उत्तराषाढ़ा'), NamePair('Shravana', 'श्रवण'),
  NamePair('Dhanishta', 'धनिष्ठा'), NamePair('Shatabhisha', 'शतभिषा'),
  NamePair('Purva Bhadrapada', 'पूर्वाभाद्रपद'), NamePair('Uttara Bhadrapada', 'उत्तराभाद्रपद'),
  NamePair('Revati', 'रेवती'),
];

const yogaNames = <NamePair>[
  NamePair('Vishkumbha', 'विष्कुम्भ'), NamePair('Priti', 'प्रीति'),
  NamePair('Ayushman', 'आयुष्मान'), NamePair('Saubhagya', 'सौभाग्य'),
  NamePair('Shobhana', 'शोभन'), NamePair('Atiganda', 'अतिगण्ड'),
  NamePair('Sukarma', 'सुकर्मा'), NamePair('Dhriti', 'धृति'),
  NamePair('Shula', 'शूल'), NamePair('Ganda', 'गण्ड'),
  NamePair('Vriddhi', 'वृद्धि'), NamePair('Dhruva', 'ध्रुव'),
  NamePair('Vyaghata', 'व्याघात'), NamePair('Harshana', 'हर्षण'),
  NamePair('Vajra', 'वज्र'), NamePair('Siddhi', 'सिद्धि'),
  NamePair('Vyatipata', 'व्यतीपात'), NamePair('Variyana', 'वरीयान'),
  NamePair('Parigha', 'परिघ'), NamePair('Shiva', 'शिव'),
  NamePair('Siddha', 'सिद्ध'), NamePair('Sadhya', 'साध्य'),
  NamePair('Shubha', 'शुभ'), NamePair('Shukla', 'शुक्ल'),
  NamePair('Brahma', 'ब्रह्म'), NamePair('Indra', 'इन्द्र'),
  NamePair('Vaidhriti', 'वैधृति'),
];

// 7 movable karanas repeat; the fixed ones bracket the lunar month.
const karanaMovable = <NamePair>[
  NamePair('Bava', 'बव'), NamePair('Balava', 'बालव'),
  NamePair('Kaulava', 'कौलव'), NamePair('Taitila', 'तैतिल'),
  NamePair('Gara', 'गर'), NamePair('Vanija', 'वणिज'),
  NamePair('Vishti', 'विष्टि'),
];
const karanaKimstughna = NamePair('Kimstughna', 'किंस्तुघ्न');
const karanaFixedEnd = <NamePair>[
  NamePair('Shakuni', 'शकुनि'), NamePair('Chatushpada', 'चतुष्पाद'),
  NamePair('Naga', 'नाग'),
];

const varaNames = <NamePair>[
  NamePair('Ravivara', 'रविवार'), NamePair('Somavara', 'सोमवार'),
  NamePair('Mangalavara', 'मंगलवार'), NamePair('Budhavara', 'बुधवार'),
  NamePair('Guruvara', 'गुरुवार'), NamePair('Shukravara', 'शुक्रवार'),
  NamePair('Shanivara', 'शनिवार'),
];

const monthNames = <NamePair>[
  NamePair('Chaitra', 'चैत्र'), NamePair('Vaishakha', 'वैशाख'),
  NamePair('Jyeshtha', 'ज्येष्ठ'), NamePair('Ashadha', 'आषाढ़'),
  NamePair('Shravana', 'श्रावण'), NamePair('Bhadrapada', 'भाद्रपद'),
  NamePair('Ashwina', 'आश्विन'), NamePair('Kartika', 'कार्तिक'),
  NamePair('Margashirsha', 'मार्गशीर्ष'), NamePair('Pausha', 'पौष'),
  NamePair('Magha', 'माघ'), NamePair('Phalguna', 'फाल्गुन'),
];

const pakshaShukla = NamePair('Shukla Paksha', 'शुक्ल पक्ष');
const pakshaKrishna = NamePair('Krishna Paksha', 'कृष्ण पक्ष');

// The 24 named Ekadashis, indexed by amanta lunar month (0=Chaitra..11=Phalguna).
// Krishna-paksha (waning) Ekadashi of each month.
const ekadashiKrishna = <NamePair>[
  NamePair('Papamochani', 'पापमोचनी'), NamePair('Varuthini', 'वरुथिनी'),
  NamePair('Apara', 'अपरा'), NamePair('Yogini', 'योगिनी'),
  NamePair('Kamika', 'कामिका'), NamePair('Aja', 'अजा'),
  NamePair('Indira', 'इन्दिरा'), NamePair('Rama', 'रमा'),
  NamePair('Utpanna', 'उत्पन्ना'), NamePair('Saphala', 'सफला'),
  NamePair('Shattila', 'षटतिला'), NamePair('Vijaya', 'विजया'),
];
// Shukla-paksha (waxing) Ekadashi of each month.
const ekadashiShukla = <NamePair>[
  NamePair('Kamada', 'कामदा'), NamePair('Mohini', 'मोहिनी'),
  NamePair('Nirjala', 'निर्जला'), NamePair('Devshayani', 'देवशयनी'),
  NamePair('Shravana Putrada', 'श्रावण पुत्रदा'), NamePair('Parivartini', 'परिवर्तिनी'),
  NamePair('Papankusha', 'पापांकुशा'), NamePair('Prabodhini', 'प्रबोधिनी'),
  NamePair('Mokshada', 'मोक्षदा'), NamePair('Pausha Putrada', 'पौष पुत्रदा'),
  NamePair('Jaya', 'जया'), NamePair('Amalaki', 'आमलकी'),
];

// Muhurat (auspicious / inauspicious timings).
const mRahu = NamePair('Rahu Kaal', 'राहु काल');
const mYamaganda = NamePair('Yamaganda', 'यमगण्ड');
const mGulika = NamePair('Gulika Kaal', 'गुलिक काल');
const mAbhijit = NamePair('Abhijit Muhurat', 'अभिजित मुहूर्त');
const mBrahma = NamePair('Brahma Muhurat', 'ब्रह्म मुहूर्त');
