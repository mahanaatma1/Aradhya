import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/router/app_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/reference_art.dart';
import '../../shared/widgets/app_logo.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';
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

/// First-run setup: language · name · Ishta Devata, as three cards that
/// slide under a festival sky.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  int _step = 0;
  int? _deityIdx;

  @override
  void dispose() {
    _page.dispose();
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

  void _go(int step) {
    final reduce = MotionScope.of(context).reduce;
    setState(() => _step = step);
    if (reduce) {
      _page.jumpToPage(step);
    } else {
      _page.animateToPage(step, duration: Motion.slow, curve: Motion.emphasized);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      _go(_step + 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hi = ref.watch(isHindiProvider);
    final sky = ColorTokens.dark.skyGradient;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          // Sky band with the logo; shrinks a little on the deity step.
          AnimatedContainer(
            duration: Motion.slow,
            curve: Motion.emphasized,
            height: _step == 2 ? 150 : 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.xl)),
              child: ShaderSurface(
                id: ShaderId.utsavSky,
                colors: sky,
                params: const [0.3],
                fallback: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky),
                  ),
                ),
                child: ParticleField(
                  emitters: [Emitters.petals(rate: 2, color: ColorTokens.dark.gold)],
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x2, 0),
                      child: Column(
                        children: [
                          Row(children: [
                            PageDots(count: 3, index: _step, color: ColorTokens.dark.gold),
                            const Spacer(),
                            GhostButton(
                              label: hi ? 'छोड़ें' : 'Skip',
                              color: ColorTokens.dark.inkOnDeep,
                              onPressed: _finish,
                            ),
                          ]),
                          const Spacer(),
                          AnimatedScale(
                            duration: Motion.slow,
                            scale: _step == 2 ? 0.6 : 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: ElevationTokens.dark.glow,
                              ),
                              child: const AppLogo(size: 84),
                            ),
                          ),
                          const SizedBox(height: Space.x4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _LanguageStep(hi: hi),
                _NameStep(controller: _name, hi: hi, onSubmit: _next),
                _DeityStep(
                  hi: hi,
                  selected: _deityIdx,
                  onSelect: (i) => setState(() => _deityIdx = i),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.x6, Space.x2, Space.x6, Space.x4),
              child: Row(children: [
                if (_step > 0) ...[
                  IconCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: hi ? 'पीछे' : 'Back',
                    size: 48,
                    onPressed: () => _go(_step - 1),
                  ),
                  const SizedBox(width: Space.x3),
                ],
                Expanded(
                  child: PrimaryButton(
                    size: ButtonSize.lg,
                    expand: true,
                    label: _step == 2
                        ? (hi ? 'आरंभ करें' : 'Get started')
                        : (hi ? 'आगे' : 'Continue'),
                    icon: _step == 2 ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScriptText(title, style: tt.headlineMedium?.copyWith(color: c.ink)),
        const SizedBox(height: Space.x1),
        ScriptText(body, style: tt.bodyMedium?.copyWith(color: c.inkSoft)),
      ],
    );
  }
}

/// Step 1 — welcome + language.
class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({required this.hi});
  final bool hi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;

    Widget option(String label, String sub, bool active, Locale locale) {
      return SurfaceCard(
        onTap: () => ref.read(localeProvider.notifier).state = locale,
        borderColor: active ? c.accent : c.border,
        color: active ? c.accentSoft : c.surface,
        padding: const EdgeInsets.symmetric(horizontal: Space.x5, vertical: Space.x4),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScriptText(label, style: tt.titleLarge?.copyWith(color: c.ink)),
                Text(sub, style: tt.bodySmall?.copyWith(color: c.inkFaint)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: Motion.base,
            child: active
                ? Icon(Icons.check_circle_rounded, key: const ValueKey(true), color: c.accent)
                : Icon(Icons.circle_outlined, key: const ValueKey(false), color: c.inkFaint),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.x6, Space.x6, Space.x6, Space.x4),
      child: RevealList(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScriptText(hi ? Brand.nameHi : Brand.name,
                style: tt.displayMedium?.copyWith(color: c.ink)),
            ScriptText(hi ? Brand.taglineHi : Brand.taglineEn,
                style: tt.bodyLarge?.copyWith(color: c.inkSoft)),
          ],
        ),
        const SizedBox(height: Space.x6),
        Eyebrow(hi ? 'अपनी भाषा चुनें' : 'Choose your language'),
        const SizedBox(height: Space.x3),
        option('English', 'English', !hi, const Locale('en')),
        const SizedBox(height: Space.x3),
        option('हिन्दी', 'Hindi', hi, const Locale('hi')),
      ]),
    );
  }
}

/// Step 2 — name.
class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.hi, required this.onSubmit});
  final TextEditingController controller;
  final bool hi;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.x6, Space.x6, Space.x6, Space.x4),
      child: RevealList(children: [
        _StepTitle(
          title: hi ? 'हम आपको क्या कहें?' : 'What should we call you?',
          body: hi ? 'ताकि आपकी साधना आपकी अपनी लगे।' : 'So your practice feels like your own.',
        ),
        const SizedBox(height: Space.x6),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: hi ? 'आपका नाम' : 'Your name',
            hintStyle: TextStyle(color: c.inkFaint),
            filled: true,
            fillColor: c.surface,
            prefixIcon: Icon(Icons.person_rounded, color: c.inkSoft),
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.x5, vertical: Space.x4),
            border: OutlineInputBorder(borderRadius: Radii.rLg, borderSide: BorderSide(color: c.border, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: Radii.rLg, borderSide: BorderSide(color: c.border, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: Radii.rLg, borderSide: BorderSide(color: c.accent, width: 2)),
          ),
        ),
      ]),
    );
  }
}

/// Step 3 — Ishta Devata picker.
class _DeityStep extends StatelessWidget {
  const _DeityStep({required this.hi, required this.selected, required this.onSelect});
  final bool hi;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.x6, Space.x5, Space.x6, Space.x3),
          child: _StepTitle(
            title: hi ? 'अपने इष्ट देव चुनें' : 'Choose your Ishta Devata',
            body: hi
                ? 'आपकी व्यक्तिगत आराधना के लिए। बाद में बदल सकते हैं।'
                : 'For your personal worship. You can change this later.',
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x2),
            crossAxisCount: 3,
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x3,
            childAspectRatio: 0.9 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4),
            children: [
              for (var i = 0; i < _deities.length; i++)
                Reveal(
                  index: i,
                  kind: RevealKind.pop,
                  child: _DeityCard(
                    en: _deities[i].$1,
                    hi: _deities[i].$2,
                    showHi: hi,
                    selected: selected == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeityCard extends StatelessWidget {
  const _DeityCard({
    required this.en,
    required this.hi,
    required this.showHi,
    required this.selected,
    required this.onTap,
  });
  final String en;
  final String hi;
  final bool showHi;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = DeityAccent.of(en);
    return Semantics(
      selected: selected,
      button: true,
      label: en,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.light,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.standard,
          decoration: BoxDecoration(
            color: selected ? accent.color.withValues(alpha: .18) : c.surface,
            borderRadius: Radii.rMd,
            border: Border.all(color: selected ? c.gold : c.border, width: 2),
            boxShadow: selected ? context.elevation.glow : context.elevation.rest,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DeityAvatar(name: en, asset: deityAvatar(en), size: 56),
              const SizedBox(height: Space.x2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x1),
                child: ScriptText(
                  showHi ? hi : en,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? c.ink : c.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
