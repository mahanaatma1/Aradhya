import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/brand.dart';
import '../../core/notifications/panchang_reminders.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/interest_signals.dart';
import '../../core/user/streak.dart';
import '../../shared/currency_icons.dart';
import '../../shared/reference_art.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';
import '../scriptures/your_reading_section.dart';

/// "You" tab — progress, saved items, language, appearance, motion, and about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    final hi = ref.watch(isHindiProvider);
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final motion = ref.watch(motionLevelProvider);
    final streak = ref.watch(streakProvider);
    final bookmarkCount = ref.watch(bookmarksProvider).length;
    final name = ref.watch(userNameProvider);
    final deity = ref.watch(ishtaDeityProvider);

    return AppScaffold(
      slivers: [
        AppTopBar(title: hi ? 'आप' : 'You', leading: const SizedBox(width: Space.x4)),
        SliverPage(children: [
          // ---- Header ----
          Reveal(
            child: SurfaceCard(
              level: CardLevel.raised,
              child: Row(children: [
                DeityAvatar(
                  name: deity.isEmpty ? (name.isEmpty ? 'आ' : name) : deity,
                  asset: deity.isEmpty ? null : deityAvatar(deity),
                  size: 64,
                ),
                const SizedBox(width: Space.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScriptText(
                        name.isEmpty
                            ? (hi ? Brand.nameHi : Brand.name)
                            : (hi ? 'नमस्ते, $name' : 'Namaste, $name'),
                        style: tt.titleLarge?.copyWith(color: c.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ScriptText(
                        deity.isEmpty
                            ? (hi ? Brand.taglineHi : Brand.taglineEn)
                            : (hi ? 'इष्ट देव · $deity' : 'Ishta Devata · $deity'),
                        style: tt.bodySmall?.copyWith(color: c.inkFaint),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Reveal(
            index: 1,
            child: Row(children: [
              Expanded(
                child: StatTile(
                    label: hi ? 'श्रृंखला' : 'Streak',
                    value: streak.days,
                    unit: hi ? 'दिन' : 'days',
                    tint: c.flame),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: StatTile(
                    label: hi ? 'पुण्य' : 'Punya', value: streak.punya, tint: c.cosmos),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: StatTile(
                    label: hi ? 'कमल' : 'Kamal', value: streak.kamal, tint: c.gold),
              ),
            ]),
          ),
          Reveal(index: 2, child: _CurrencyGuide(hi: hi)),
          const YourReadingSection(),

          // ---- Your space ----
          SectionHeader(
              title: hi ? 'आपका स्थान' : 'Your space', padding: const EdgeInsets.only(top: Space.x2)),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              NavRow(
                title: hi ? 'साधना' : 'Sadhana',
                subtitle: hi ? 'जप, प्राणायाम, पाठ, आदतें — एक जगह' : 'Japa, pranayama, reading, habits — in one place',
                leading: Icon(Icons.self_improvement_rounded, color: c.tulsi),
                onTap: () => context.push('/sadhana'),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'मेरी यात्रा' : 'My Yatra',
                subtitle: hi ? 'दर्शन किए मंदिर, संग्रह और आपकी टिप्पणियाँ' : 'Temples visited, collections and your notes',
                leading: Icon(Icons.temple_hindu_rounded, color: c.accent),
                onTap: () => context.push('/passport'),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'ज्ञान यात्राएँ' : 'Knowledge Journeys',
                subtitle: hi ? 'निर्देशित पथ — सुझाया क्रम, कोई ताला नहीं' : 'Guided paths — a suggested order, nothing locked',
                leading: Icon(Icons.route_rounded, color: c.cosmos),
                onTap: () => context.push('/journey'),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'कर्म डायरी' : 'Karma Journal',
                subtitle: hi ? 'निजी चिंतन — केवल इसी उपकरण पर' : 'Private reflection — this device only',
                leading: Icon(Icons.edit_note_rounded, color: c.lotus),
                onTap: () => context.push('/journal'),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'सब कुछ खोजें' : 'Search everything',
                subtitle: hi ? 'श्लोक, मंदिर, मंत्र, कथा' : 'Verses, temples, mantras, kathas',
                leading: Icon(Icons.search_rounded, color: c.info),
                onTap: () => context.push('/search'),
              ),
              const StitchedDivider(indent: Space.x4),
              AppListTile(
                title: hi ? 'सहेजे गए' : 'Bookmarks',
                leading: Icon(Icons.bookmark_rounded, color: c.gold),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  CountBadge(bookmarkCount, color: c.gold),
                  const SizedBox(width: Space.x1),
                  Icon(Icons.chevron_right_rounded, color: c.inkFaint),
                ]),
                onTap: () => context.push('/bookmarks'),
              ),
            ]),
          ),

          // ---- Preferences ----
          SectionHeader(
              title: hi ? 'पसंद' : 'Preferences', padding: const EdgeInsets.only(top: Space.x2)),
          _PrefCard(
            label: hi ? 'भाषा' : 'Language',
            child: SegmentedControl<String>(
              values: const ['en', 'hi'],
              label: (v) => v == 'hi' ? 'हिन्दी' : 'English',
              selected: locale.languageCode,
              onChanged: (v) => ref.read(localeProvider.notifier).state = Locale(v),
            ),
          ),
          _PrefCard(
            label: hi ? 'रूप' : 'Appearance',
            child: SegmentedControl<ThemeMode>(
              values: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
              label: (v) => switch (v) {
                ThemeMode.light => hi ? 'उजाला' : 'Light',
                ThemeMode.dark => hi ? 'अँधेरा' : 'Dark',
                ThemeMode.system => hi ? 'फ़ोन' : 'System',
              },
              icon: (v) => switch (v) {
                ThemeMode.light => Icons.wb_sunny_rounded,
                ThemeMode.dark => Icons.nights_stay_rounded,
                ThemeMode.system => Icons.phone_android_rounded,
              },
              selected: mode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
            ),
          ),
          _PrefCard(
            label: hi ? 'गति और एनिमेशन' : 'Motion',
            body: switch (motion) {
              MotionLevel.full => hi
                  ? 'दीये, पंखुड़ियाँ, तारे और हर संक्रमण — पूरा उत्सव।'
                  : 'Diyas, petals, stars and every transition — the full festival.',
              MotionLevel.reduced => hi
                  ? 'संक्रमण रहते हैं; लगातार चलने वाले कण और पैरलैक्स बंद।'
                  : 'Transitions stay; ambient particles and parallax are off.',
              MotionLevel.off => hi
                  ? 'केवल हल्के फ़ेड। फ़ोन की “एनिमेशन कम करें” सेटिंग भी यही करती है।'
                  : 'Simple fades only. Your phone\'s "reduce motion" setting does this too.',
            },
            child: SegmentedControl<MotionLevel>(
              values: MotionLevel.values,
              label: (v) => switch (v) {
                MotionLevel.full => hi ? 'पूरा' : 'Full',
                MotionLevel.reduced => hi ? 'कम' : 'Reduced',
                MotionLevel.off => hi ? 'बंद' : 'Off',
              },
              selected: motion,
              onChanged: (v) => ref.read(motionLevelProvider.notifier).set(v),
            ),
          ),

          // ---- Reminders ----
          SectionHeader(
              title: hi ? 'स्मरण' : 'Reminders', padding: const EdgeInsets.only(top: Space.x2)),
          SurfaceCard(padding: EdgeInsets.zero, child: _PanchangReminderToggle(hi: hi)),

          // ---- Privacy ----
          SectionHeader(
              title: hi ? 'निजता' : 'Privacy', padding: const EdgeInsets.only(top: Space.x2)),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              NavRow(
                title: hi ? 'रुचि प्रोफ़ाइल हटाएँ' : 'Reset personalization',
                subtitle: hi
                    ? 'जो आप खोलते हैं उससे केवल क्रम बदलता है — कुछ छिपाया नहीं जाता, और यह इसी उपकरण पर रहता है'
                    : 'What you open changes only the order things appear in — nothing is hidden, and it stays on this device',
                leading: Icon(Icons.restart_alt_rounded, color: c.accent),
                onTap: () async {
                  final ok = await showConfirm(context,
                      title: hi ? 'रुचि प्रोफ़ाइल हटाएँ?' : 'Reset personalization?',
                      confirmLabel: hi ? 'हटाएँ' : 'Reset',
                      cancelLabel: hi ? 'रहने दें' : 'Keep');
                  if (!ok) return;
                  await ref.read(interestSignalsProvider.notifier).reset();
                  if (!context.mounted) return;
                  showAppSnack(context, hi ? 'रुचि प्रोफ़ाइल हटा दी गई।' : 'Personalization reset.',
                      kind: NoticeKind.success);
                },
              ),
              const StitchedDivider(indent: Space.x4),
              AppListTile(
                title: hi ? 'गोपनीयता नीति' : 'Privacy policy',
                subtitle: hi
                    ? 'आपकी डायरी, प्रगति और रुचियाँ इसी उपकरण पर रहती हैं'
                    : 'Your journal, progress and interests stay on this device',
                leading: Icon(Icons.privacy_tip_outlined, color: c.info),
                trailing: Icon(Icons.open_in_new_rounded, size: 18, color: c.inkFaint),
                onTap: () async {
                  final ok = await launchUrl(Uri.parse('https://aradhya.app/privacy'),
                      mode: LaunchMode.externalApplication);
                  if (!ok && context.mounted) {
                    showAppSnack(context, hi ? 'लिंक नहीं खुला।' : 'Could not open the link.',
                        kind: NoticeKind.warning);
                  }
                },
              ),
            ]),
          ),

          // ---- About ----
          SectionHeader(title: hi ? 'परिचय' : 'About', padding: const EdgeInsets.only(top: Space.x2)),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              AppListTile(
                title: Brand.name,
                subtitle: '${hi ? Brand.taglineHi : Brand.taglineEn} · v1.0.1',
                leading: Icon(Icons.info_outline_rounded, color: c.inkSoft),
              ),
              const StitchedDivider(indent: Space.x4),
              NavRow(
                title: hi ? 'स्रोत' : 'Sources',
                subtitle: hi
                    ? 'हर अनुवाद और डेटासेट का श्रेय, जिसमें OpenStreetMap भी शामिल है'
                    : 'Credit for every translation and dataset, including OpenStreetMap',
                leading: Icon(Icons.local_library_outlined, color: c.cosmos),
                onTap: () => context.push('/sources'),
              ),
              if (kDebugMode) ...[
                const StitchedDivider(indent: Space.x4),
                NavRow(
                  title: 'Kit gallery (debug)',
                  leading: Icon(Icons.palette_outlined, color: c.gold),
                  onTap: () => context.push('/debug/kit'),
                ),
                const StitchedDivider(indent: Space.x4),
                NavRow(
                  title: 'Notification test (debug)',
                  leading: Icon(Icons.bug_report_outlined, color: c.gold),
                  onTap: () => context.push('/debug/notifications'),
                ),
              ],
            ]),
          ),
        ]),
      ],
    );
  }
}

class _PrefCard extends StatelessWidget {
  const _PrefCard({required this.label, required this.child, this.body});
  final String label;
  final String? body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: Space.x3),
          child,
          if (body != null) ...[
            const SizedBox(height: Space.x2),
            ScriptText(body!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkFaint)),
          ],
        ],
      ),
    );
  }
}

/// Explains the two currencies — how you earn each and where Kamal is spent.
class _CurrencyGuide extends StatelessWidget {
  const _CurrencyGuide({required this.hi});
  final bool hi;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    Widget line(Widget icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: Space.x3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 26, height: 26, child: Center(child: icon)),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScriptText(title, style: tt.titleMedium?.copyWith(color: c.ink)),
                    ScriptText(body, style: tt.bodySmall?.copyWith(color: c.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(hi ? 'पुण्य और कमल कैसे काम करते हैं' : 'How Punya & Kamal work'),
          const SizedBox(height: Space.x3),
          line(const PunyaIcon(size: 24), hi ? 'पुण्य — आपकी साधना का पुण्य' : 'Punya — your merit',
              hi ? 'हर अभ्यास से अर्जित होता है और कभी घटता नहीं। यह आपकी आजीवन साधना का अंक है।' : 'Earned from every practice and never spent — your lifetime score.'),
          line(const KamalIcon(size: 24), hi ? 'कमल — आपकी मुद्रा' : 'Kamal — your currency',
              hi ? 'पुण्य के साथ अर्जित होता है। मंदिर में भोग और दीये पर व्यय करें।' : 'Earned alongside Punya. Spend it in the Mandir on bhog and diyas.'),
          line(Icon(Icons.add_circle_outline_rounded, size: 22, color: c.accent), hi ? 'कैसे कमाएँ' : 'How to earn',
              hi ? 'दैनिक भ्रमण +5 · एक माला जप +10 · आदत +2 · प्रश्नोत्तरी/व्यक्तित्व +5' : 'Daily visit +5 · a japa mala +10 · a habit +2 · quiz / personality +5'),
        ],
      ),
    );
  }
}

/// One switch for the automatic panchang reminders (Ekadashi / Purnima /
/// Amavasya nudges plus the daily verse), all scheduled on-device.
class _PanchangReminderToggle extends StatefulWidget {
  const _PanchangReminderToggle({required this.hi});
  final bool hi;

  @override
  State<_PanchangReminderToggle> createState() => _PanchangReminderToggleState();
}

class _PanchangReminderToggleState extends State<_PanchangReminderToggle> {
  bool? _on;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PanchangReminders.instance.isEnabled().then((v) {
      if (mounted) setState(() => _on = v);
    });
  }

  Future<void> _toggle(bool want) async {
    setState(() => _busy = true);
    if (want) {
      final granted = await ReminderService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _busy = false;
            _on = false;
          });
          showAppSnack(context,
              widget.hi ? 'सूचना की अनुमति नहीं मिली।' : 'Notification permission was not granted.',
              kind: NoticeKind.warning);
        }
        return;
      }
    }
    await PanchangReminders.instance.setEnabled(want, hindi: widget.hi);
    if (mounted) {
      setState(() {
        _on = want;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = widget.hi;
    return ToggleRow(
      label: hi ? 'पंचांग स्मरण' : 'Panchang reminders',
      subtitle: hi
          ? 'हर एकादशी, पूर्णिमा और अमावस्या के दिन सुबह सूचना; प्रतिदिन साधना की याद और आज का श्लोक।'
          : 'A morning nudge on each Ekadashi, Purnima and Amavasya, an evening reminder to practise, and the verse of the day.',
      leading: Icon(Icons.brightness_3_rounded, color: context.colors.cosmos),
      value: _on ?? false,
      onChanged: (_on == null || _busy) ? (_) {} : _toggle,
    );
  }
}
