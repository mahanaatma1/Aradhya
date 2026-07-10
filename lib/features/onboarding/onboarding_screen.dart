import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/reference_art.dart';
import '../../shared/widgets/app_logo.dart';
import '../devotional/deity_accent.dart';

/// The deities offered in the Ishta Devata picker (matches the Mandir roster).
const _deities = <(String, String)>[
  ('Ganesha', 'गणेश'),
  ('Krishna', 'कृष्ण'),
  ('Shiva', 'शिव'),
  ('Durga', 'दुर्गा'),
  ('Hanuman', 'हनुमान'),
  ('Lakshmi', 'लक्ष्मी'),
  ('Rama', 'राम'),
  ('Saraswati', 'सरस्वती'),
];

/// First-run setup: pick a language, tell us your name, and choose your Ishta
/// Devata. Mirrors Ishvarvaani's onboarding (language · name · deity).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();
  int? _deityIdx;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final p = ref.read(sharedPrefsProvider);
    final name = _name.text.trim();
    await p.setString(PrefKeys.userName, name);
    ref.read(userNameProvider.notifier).state = name;
    if (_deityIdx != null) {
      final deity = _deities[_deityIdx!].$1;
      await p.setString(PrefKeys.ishtaDeity, deity);
      ref.read(ishtaDeityProvider.notifier).state = deity;
    }
    await p.setBool(PrefKeys.onboarded, true);
    gOnboarded = true;
    if (mounted) context.go('/');
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots + skip.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _step ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(hi ? 'छोड़ें' : 'Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_step) {
                  0 => _LanguageStep(key: const ValueKey(0)),
                  1 => _NameStep(key: const ValueKey(1), controller: _name),
                  _ => _DeityStep(
                      key: const ValueKey(2),
                      hi: hi,
                      selected: _deityIdx,
                      onSelect: (i) => setState(() => _deityIdx = i),
                    ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(
                    _step == 2
                        ? (hi ? 'आरंभ करें' : 'Get Started')
                        : (hi ? 'आगे' : 'Continue'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 1 — welcome + language pick.
class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final hi = locale.languageCode == 'hi';

    Widget option(String label, String sub, bool active, VoidCallback onTap) {
      final scheme = Theme.of(context).colorScheme;
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: active
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: scheme.primary
                    .withValues(alpha: active ? 0.6 : 0.18),
                width: active ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              if (active)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 96),
          const SizedBox(height: 20),
          Text(hi ? Brand.nameHi : Brand.name,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 30)),
          Text(hi ? Brand.taglineHi : Brand.taglineEn,
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          const SizedBox(height: 36),
          Text(hi ? 'अपनी भाषा चुनें' : 'Choose your language',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 14),
          option('English', 'English', !hi,
              () => ref.read(localeProvider.notifier).state = const Locale('en')),
          const SizedBox(height: 12),
          option('हिन्दी', 'Hindi', hi,
              () => ref.read(localeProvider.notifier).state = const Locale('hi')),
        ],
      ),
    );
  }
}

/// Step 2 — name capture.
class _NameStep extends ConsumerWidget {
  final TextEditingController controller;
  const _NameStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_emotions_rounded,
              size: 64, color: AppColors.terracotta),
          const SizedBox(height: 24),
          Text(hi ? 'हम आपको क्या कहें?' : 'What should we call you?',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 26)),
          const SizedBox(height: 8),
          Text(
              hi
                  ? 'ताकि आपकी साधना आपकी अपनी लगे।'
                  : 'So your practice feels like your own.',
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: hi ? 'आपका नाम' : 'Your name',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 3 — Ishta Devata (personal deity) picker.
class _DeityStep extends StatelessWidget {
  final bool hi;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _DeityStep(
      {super.key,
      required this.hi,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'अपने इष्ट देव चुनें' : 'Choose your Ishta Devata',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 24)),
          const SizedBox(height: 4),
          Text(
              hi
                  ? 'आपकी व्यक्तिगत आराधना के लिए। बाद में बदल सकते हैं।'
                  : 'For your personal worship. You can change this later.',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                for (var i = 0; i < _deities.length; i++)
                  _DeityCard(
                    en: _deities[i].$1,
                    hi: _deities[i].$2,
                    showHi: hi,
                    selected: selected == i,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeityCard extends StatelessWidget {
  final String en;
  final String hi;
  final bool showHi;
  final bool selected;
  final VoidCallback onTap;
  const _DeityCard(
      {required this.en,
      required this.hi,
      required this.showHi,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = DeityAccent.of(en);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: accent.color.withValues(alpha: selected ? 0.22 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: accent.color.withValues(alpha: selected ? 0.75 : 0.22),
              width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (_) {
              final img = deityAvatar(en);
              return Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.color.withValues(alpha: 0.14),
                ),
                child: img != null
                    ? Image.asset(img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(accent.icon,
                            color: accent.color, size: 32))
                    : Icon(accent.icon, color: accent.color, size: 32),
              );
            }),
            const SizedBox(height: 8),
            Text(showHi ? hi : en,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
