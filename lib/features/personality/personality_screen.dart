import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/reference_art.dart';

/// One of the four classical paths of yoga — the archetype a user maps to.
class Archetype {
  final String key;
  final String nameEn;
  final String nameHi;
  final String pathEn; // e.g. "Bhakti Yoga"
  final String pathHi;
  final String descEn;
  final String descHi;
  final String deity; // affinity deity (drives the avatar art)
  final List<String> practicesEn;
  final List<String> practicesHi;
  final Color color;
  const Archetype(this.key, this.nameEn, this.nameHi, this.pathEn, this.pathHi,
      this.descEn, this.descHi, this.deity, this.practicesEn, this.practicesHi,
      this.color);
}

const _archetypes = <String, Archetype>{
  'bhakta': Archetype(
    'bhakta',
    'The Devotee',
    'भक्त',
    'Bhakti Yoga · the path of love',
    'भक्ति योग · प्रेम का मार्ग',
    'Your heart leads. You reach the divine through love, surrender and song — '
        'aartis, kirtan and a personal bond with your Ishta Devata move you most.',
    'आपका हृदय मार्गदर्शक है। आप प्रेम, समर्पण और भजन से ईश्वर तक पहुँचते हैं।',
    'Krishna',
    ['Daily aarti & kirtan', 'Japa of your Ishta mantra', 'Keep a home mandir'],
    ['नित्य आरती और कीर्तन', 'अपने इष्ट मंत्र का जप', 'घर में मंदिर रखें'],
    AppColors.terracotta,
  ),
  'jnani': Archetype(
    'jnani',
    'The Seeker',
    'ज्ञानी',
    'Jnana Yoga · the path of wisdom',
    'ज्ञान योग · विवेक का मार्ग',
    'Your mind leads. You reach truth through study, questioning and '
        'self-enquiry — scriptures, philosophy and "who am I?" light your way.',
    'आपका मन मार्गदर्शक है। आप अध्ययन, जिज्ञासा और आत्म-विचार से सत्य तक पहुँचते हैं।',
    'Saraswati',
    ['Read the Gita & Upanishads', 'Self-enquiry (atma-vichara)', 'Study daily'],
    ['गीता और उपनिषद् पढ़ें', 'आत्म-विचार (आत्म-जिज्ञासा)', 'नित्य स्वाध्याय'],
    AppColors.dharmaPurple,
  ),
  'karmayogi': Archetype(
    'karmayogi',
    'The Servant',
    'कर्मयोगी',
    'Karma Yoga · the path of action',
    'कर्म योग · कर्म का मार्ग',
    'Your hands lead. You reach the divine through selfless service and duty — '
        'seva, generosity and doing the right thing without attachment to reward.',
    'आपके कर्म मार्गदर्शक हैं। आप निःस्वार्थ सेवा और कर्तव्य से ईश्वर तक पहुँचते हैं।',
    'Hanuman',
    ['Daily seva / kindness', 'Act without attachment', 'Hanuman Chalisa'],
    ['नित्य सेवा / परोपकार', 'निष्काम भाव से कर्म करें', 'हनुमान चालीसा'],
    AppColors.sacredGreen,
  ),
  'yogi': Archetype(
    'yogi',
    'The Meditator',
    'योगी',
    'Raja Yoga · the path of stillness',
    'राज योग · स्थिरता का मार्ग',
    'Your breath leads. You reach the divine through discipline and inner '
        'silence — meditation, pranayama and steady practice are your temple.',
    'आपकी श्वास मार्गदर्शक है। आप अनुशासन और आंतरिक मौन से ईश्वर तक पहुँचते हैं।',
    'Shiva',
    ['Meditation (dhyana)', 'Pranayama daily', 'Steady, quiet discipline'],
    ['ध्यान (साधना)', 'नित्य प्राणायाम', 'स्थिर, शांत अनुशासन'],
    Color(0xFF3E7C8C),
  ),
};

/// A quiz question; each option scores one archetype.
class _Q {
  final String en;
  final String hi;
  final List<(String key, String en, String hi)> options;
  const _Q(this.en, this.hi, this.options);
}

const _questions = <_Q>[
  _Q('When you feel closest to the divine, it is while…', 'आप ईश्वर के सबसे निकट कब अनुभव करते हैं?', [
    ('bhakta', 'Singing or praying with an open heart', 'खुले हृदय से भजन या प्रार्थना करते हुए'),
    ('jnani', 'Understanding a deep truth', 'किसी गूढ़ सत्य को समझते हुए'),
    ('karmayogi', 'Helping someone in need', 'किसी ज़रूरतमंद की सहायता करते हुए'),
    ('yogi', 'Sitting in deep silence', 'गहरे मौन में बैठते हुए'),
  ]),
  _Q('Your ideal morning begins with…', 'आपकी आदर्श सुबह कैसे शुरू होती है?', [
    ('yogi', 'Meditation and breathwork', 'ध्यान और प्राणायाम'),
    ('bhakta', 'Aarti at your mandir', 'मंदिर में आरती'),
    ('jnani', 'Reading scripture', 'शास्त्र पाठ'),
    ('karmayogi', 'Planning acts of service', 'सेवा की योजना'),
  ]),
  _Q('A problem arises. You instinctively…', 'कोई समस्या आती है। आप सहज रूप से…', [
    ('jnani', 'Analyse it calmly and think it through', 'शांति से विश्लेषण करते हैं'),
    ('karmayogi', 'Roll up your sleeves and act', 'तुरंत कार्य में जुट जाते हैं'),
    ('bhakta', 'Pray and trust the divine', 'प्रार्थना कर ईश्वर पर भरोसा करते हैं'),
    ('yogi', 'Step back and centre yourself first', 'पहले स्वयं को स्थिर करते हैं'),
  ]),
  _Q('Which word resonates most?', 'कौन-सा शब्द सबसे अधिक भाता है?', [
    ('bhakta', 'Love', 'प्रेम'),
    ('jnani', 'Truth', 'सत्य'),
    ('karmayogi', 'Duty', 'कर्तव्य'),
    ('yogi', 'Peace', 'शांति'),
  ]),
  _Q('You admire people who are…', 'आप किन लोगों की प्रशंसा करते हैं?', [
    ('karmayogi', 'Selfless and hard-working', 'निःस्वार्थ और परिश्रमी'),
    ('jnani', 'Wise and clear-thinking', 'बुद्धिमान और स्पष्ट'),
    ('yogi', 'Calm and disciplined', 'शांत और अनुशासित'),
    ('bhakta', 'Warm and devoted', 'स्नेही और भक्त'),
  ]),
  _Q('Your favourite way to spend a festival is…', 'त्योहार बिताने का प्रिय तरीका?', [
    ('bhakta', 'Bhajans and celebration', 'भजन और उत्सव'),
    ('karmayogi', 'Serving food / helping out', 'भोजन सेवा / सहायता'),
    ('jnani', 'Learning its meaning', 'उसका अर्थ जानना'),
    ('yogi', 'Quiet fasting and prayer', 'शांत व्रत और प्रार्थना'),
  ]),
  _Q('Growth, for you, means…', 'आपके लिए उन्नति का अर्थ है…', [
    ('yogi', 'Mastering the mind', 'मन पर नियंत्रण'),
    ('jnani', 'Seeing reality clearly', 'सत्य को स्पष्ट देखना'),
    ('bhakta', 'A deeper bond with God', 'ईश्वर से गहरा नाता'),
    ('karmayogi', 'Doing more good in the world', 'संसार में अधिक भला करना'),
  ]),
  _Q('At the end of the day, you feel best when you…', 'दिन के अंत में आप कब सर्वोत्तम अनुभव करते हैं?', [
    ('karmayogi', 'Helped someone', 'किसी की मदद की'),
    ('bhakta', 'Prayed from the heart', 'हृदय से प्रार्थना की'),
    ('yogi', 'Meditated deeply', 'गहरा ध्यान किया'),
    ('jnani', 'Learned something true', 'कुछ सत्य सीखा'),
  ]),
];

/// The saved archetype result (key), or empty.
final personalityResultProvider = StateProvider<String>(
  (ref) => ref.read(sharedPrefsProvider).getString(PrefKeys.personalityResult) ?? '',
);

class PersonalityScreen extends ConsumerStatefulWidget {
  const PersonalityScreen({super.key});

  @override
  ConsumerState<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends ConsumerState<PersonalityScreen> {
  bool _started = false;
  int _q = 0;
  final Map<String, int> _scores = {};

  void _answer(String key) {
    _scores[key] = (_scores[key] ?? 0) + 1;
    if (_q < _questions.length - 1) {
      setState(() => _q++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    // Highest-scoring archetype wins; ties break by declaration order.
    var best = _archetypes.keys.first;
    var bestScore = -1;
    for (final k in _archetypes.keys) {
      final s = _scores[k] ?? 0;
      if (s > bestScore) {
        bestScore = s;
        best = k;
      }
    }
    await ref.read(sharedPrefsProvider).setString(PrefKeys.personalityResult, best);
    ref.read(personalityResultProvider.notifier).state = best;
    await ref.read(streakProvider.notifier).addPoints(5);
    if (mounted) setState(() {});
  }

  void _restart() {
    setState(() {
      _started = true;
      _q = 0;
      _scores.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final saved = ref.watch(personalityResultProvider);

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'व्यक्तित्व' : 'Soul Path')),
      body: SafeArea(
        child: !_started
            ? (saved.isNotEmpty
                ? _Result(
                    archetype: _archetypes[saved]!,
                    hi: hi,
                    onRetake: _restart)
                : _Intro(hi: hi, onStart: _restart))
            : _Question(
                q: _questions[_q],
                index: _q,
                total: _questions.length,
                hi: hi,
                onAnswer: _answer,
              ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final bool hi;
  final VoidCallback onStart;
  const _Intro({required this.hi, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology_rounded,
              size: 72, color: AppColors.dharmaPurple),
          const SizedBox(height: 20),
          Text(hi ? 'अपना आध्यात्मिक मार्ग जानें' : 'Discover Your Soul Path',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            hi
                ? '8 सरल प्रश्न — जानें कि योग के चार मार्गों में से कौन-सा आपका है।'
                : '8 quick questions reveal which of the four paths of yoga is yours.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(hi ? 'आरंभ करें' : 'Begin',
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Question extends StatelessWidget {
  final _Q q;
  final int index;
  final int total;
  final bool hi;
  final ValueChanged<String> onAnswer;
  const _Question(
      {required this.q,
      required this.index,
      required this.total,
      required this.hi,
      required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              minHeight: 7,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text('${index + 1} / $total',
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 20),
          Text(hi ? q.hi : q.en,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 23,
                  height: 1.25)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                for (final o in q.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      text: hi ? o.$3 : o.$2,
                      onTap: () => onAnswer(o.$1),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _OptionTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 16, height: 1.3)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final Archetype archetype;
  final bool hi;
  final VoidCallback onRetake;
  const _Result(
      {required this.archetype, required this.hi, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    final a = archetype;
    final avatar = deityAvatar(a.deity);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [a.color, Color.lerp(a.color, Colors.black, 0.3)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(hi ? 'आपका मार्ग' : 'YOUR PATH',
                  style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 12),
              if (avatar != null)
                Container(
                  width: 96,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Image.asset(avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.self_improvement_rounded,
                          size: 48,
                          color: Colors.white)),
                ),
              const SizedBox(height: 14),
              Text(hi ? a.nameHi : a.nameEn,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(hi ? a.pathHi : a.pathEn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(hi ? a.descHi : a.descEn,
            style: const TextStyle(fontSize: 16, height: 1.55)),
        const SizedBox(height: 22),
        Text(hi ? 'सुझाई गई साधना' : 'Suggested practices',
            style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: a.color)),
        const SizedBox(height: 10),
        for (final p in (hi ? a.practicesHi : a.practicesEn))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: a.color),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 15))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          hi
              ? 'आपकी देव-आत्मीयता: ${a.deity}'
              : 'Your deity affinity: ${a.deity}',
          style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(hi ? 'फिर से करें' : 'Retake the test'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    );
  }
}
