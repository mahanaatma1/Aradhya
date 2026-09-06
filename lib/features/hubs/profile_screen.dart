import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../core/notifications/panchang_reminders.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/interest_signals.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/streak.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/currency_icons.dart';
import '../../shared/widgets/app_logo.dart';
import '../scriptures/your_reading_section.dart';

/// "You" tab — progress, saved items, language, theme and about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = ref.watch(isHindiProvider);
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final streak = ref.watch(streakProvider);
    final bookmarkCount = ref.watch(bookmarksProvider).length;
    final name = ref.watch(userNameProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: 12),
                Text(
                    name.isEmpty
                        ? (hi ? Brand.nameHi : Brand.name)
                        : (hi ? 'नमस्ते, $name' : 'Namaste, $name'),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 24)),
                Text(hi ? Brand.taglineHi : Brand.taglineEn,
                    style: TextStyle(
                        fontFamily: hi ? AppFonts.devanagari : AppFonts.accent,
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${streak.days}',
                  label: hi ? 'दिन की श्रृंखला' : 'Day streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  leading: const PunyaIcon(size: 26),
                  value: '${streak.punya}',
                  label: hi ? 'पुण्य' : 'Punya',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  leading: const KamalIcon(size: 26),
                  value: '${streak.kamal}',
                  label: hi ? 'कमल' : 'Kamal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CurrencyGuide(hi: hi),
          const SizedBox(height: 16),

          const YourReadingSection(),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.self_improvement_rounded, color: scheme.primary),
              title: Text(hi ? 'साधना' : 'Sadhana'),
              subtitle: Text(hi
                  ? 'जप, प्राणायाम, पाठ, आदतें — एक जगह'
                  : 'Japa, pranayama, reading, habits — in one place'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/sadhana'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.temple_hindu_rounded, color: scheme.primary),
              title: Text(hi ? 'मेरी यात्रा' : 'My Yatra'),
              subtitle: Text(hi
                  ? 'दर्शन किए मंदिर, संग्रह और आपकी टिप्पणियाँ'
                  : 'Temples visited, collections, and your own notes'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/passport'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.route_rounded, color: scheme.primary),
              title: Text(hi ? 'ज्ञान यात्राएँ' : 'Knowledge Journeys'),
              subtitle: Text(hi
                  ? 'निर्देशित पथ — सुझाया क्रम, कोई ताला नहीं'
                  : 'Guided paths — a suggested order, nothing locked'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/journey'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.edit_note_rounded, color: scheme.primary),
              title: Text(hi ? 'कर्म डायरी' : 'Karma Journal'),
              subtitle: Text(hi
                  ? 'निजी चिंतन — केवल इसी उपकरण पर'
                  : 'Private reflection — this device only'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/journal'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.search_rounded, color: scheme.primary),
              title: Text(hi ? 'सब कुछ खोजें' : 'Search everything'),
              subtitle: Text(hi
                  ? 'श्लोक, मंदिर, मंत्र, कथा'
                  : 'Verses, temples, mantras, kathas'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/search'),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.bookmark_rounded, color: scheme.primary),
              title: Text(hi ? 'सहेजे गए' : 'Bookmarks'),
              subtitle: Text(hi ? '$bookmarkCount सहेजे गए' : '$bookmarkCount saved'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/bookmarks'),
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel(t.language),
          Card(
            child: Column(
              children: [
                _SelectTile(
                  label: 'English',
                  selected: locale.languageCode == 'en',
                  onTap: () => ref.read(localeProvider.notifier).state =
                      const Locale('en'),
                ),
                _SelectTile(
                  label: 'हिन्दी',
                  selected: locale.languageCode == 'hi',
                  onTap: () => ref.read(localeProvider.notifier).state =
                      const Locale('hi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel(hi ? 'रूप' : 'Appearance'),
          Card(
            child: Column(
              children: [
                _SelectTile(
                  label: hi ? 'उजाला' : 'Light',
                  selected: mode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .set(ThemeMode.light),
                ),
                _SelectTile(
                  label: hi ? 'अँधेरा' : 'Dark',
                  selected: mode == ThemeMode.dark,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(ThemeMode.dark),
                ),
                _SelectTile(
                  label: hi ? 'फ़ोन के अनुसार' : 'Follow system',
                  selected: mode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .set(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel(hi ? 'स्मरण' : 'Reminders'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _PanchangReminderToggle(hi: hi),
          ),
          const SizedBox(height: 16),

          _SectionLabel(hi ? 'निजता' : 'Privacy'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.restart_alt_rounded, color: scheme.primary),
              title: Text(hi ? 'रुचि प्रोफ़ाइल हटाएँ' : 'Reset personalization'),
              subtitle: Text(hi
                  ? 'जो आप खोलते हैं उससे केवल क्रम बदलता है — कुछ छिपाया नहीं जाता, और यह इसी उपकरण पर रहता है'
                  : 'What you open changes only the order things appear in — nothing is hidden, and it stays on this device'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await ref.read(interestSignalsProvider.notifier).reset();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(hi
                      ? 'रुचि प्रोफ़ाइल हटा दी गई।'
                      : 'Personalization reset.'),
                ));
              },
            ),
          ),
          // RG-08: the store listings link here, and a reader should be able
          // to reach the same page from inside the app without hunting for
          // it in a store description. Points at the live policy on
          // aradhya.app, which states plainly what stays on-device (journal,
          // bookmarks, streaks, japa counts) — see website/src/pages/
          // Privacy.jsx for the actual text this links to.
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading:
                  Icon(Icons.privacy_tip_outlined, color: scheme.primary),
              title: Text(hi ? 'गोपनीयता नीति' : 'Privacy Policy'),
              subtitle: Text(hi
                  ? 'आपकी डायरी, प्रगति और रुचियाँ इसी उपकरण पर रहती हैं'
                  : 'Your journal, progress and interests stay on this device'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(Uri.parse('https://aradhya.app/privacy'),
                  mode: LaunchMode.externalApplication),
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel('About'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text(Brand.name),
              subtitle: const Text('${Brand.taglineEn} · v1.0.0'),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.local_library_outlined, color: scheme.primary),
              title: Text(hi ? 'स्रोत' : 'Sources'),
              subtitle: Text(hi
                  ? 'हर अनुवाद और डेटासेट का श्रेय, जिसमें OpenStreetMap भी शामिल है'
                  : 'Credit for every translation and dataset, including OpenStreetMap'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/sources'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String value;
  final String label;
  const _MetricCard(
      {this.icon, this.leading, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
              height: 28,
              child: Center(
                  child: leading ?? Icon(icon, color: scheme.primary))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: scheme.primary)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Explains the two currencies — how you earn each and where Kamal is spent.
class _CurrencyGuide extends StatelessWidget {
  final bool hi;
  const _CurrencyGuide({required this.hi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget line(Widget icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 26, height: 26, child: Center(child: icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color:
                                scheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hi ? 'पुण्य और कमल कैसे काम करते हैं' : 'How Punya & Kamal work',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.secondary)),
          const SizedBox(height: 14),
          line(
            const PunyaIcon(size: 24),
            hi ? 'पुण्य — आपकी साधना का पुण्य' : 'Punya — your merit',
            hi
                ? 'हर अभ्यास से अर्जित होता है और कभी घटता नहीं। यह आपकी आजीवन साधना का अंक है।'
                : 'Earned from every practice and never spent — your lifetime score.',
          ),
          line(
            const KamalIcon(size: 24),
            hi ? 'कमल — आपकी मुद्रा' : 'Kamal — your currency',
            hi
                ? 'पुण्य के साथ अर्जित होता है। राशिफल में गहरी दैनिक भविष्यवाणी अनलॉक करने में व्यय करें।'
                : 'Earned alongside Punya. Spend it in Rashifal to unlock deeper daily readings.',
          ),
          line(
            Icon(Icons.add_circle_outline_rounded,
                size: 22, color: scheme.primary),
            hi ? 'कैसे कमाएँ' : 'How to earn',
            hi
                ? 'दैनिक भ्रमण +5 · एक माला जप +10 · आदत +2 · प्रश्नोत्तरी/व्यक्तित्व +5'
                : 'Daily visit +5 · a japa mala +10 · a habit +2 · quiz / personality +5',
          ),
        ],
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(label),
      onTap: onTap,
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : Icon(Icons.circle_outlined,
              color: scheme.onSurface.withValues(alpha: 0.3)),
    );
  }
}

/// One switch that turns on the automatic panchang reminders — a rolling
/// window of Ekadashi / Purnima / Amavasya nudges plus a daily verse, all
/// scheduled on-device. Separate from the per-festival toggles on each
/// festival's own page.
class _PanchangReminderToggle extends StatefulWidget {
  final bool hi;
  const _PanchangReminderToggle({required this.hi});

  @override
  State<_PanchangReminderToggle> createState() =>
      _PanchangReminderToggleState();
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
      // Reuse the same permission gate the other reminders use.
      final granted = await ReminderService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _busy = false;
            _on = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.hi
                ? 'सूचना की अनुमति नहीं मिली।'
                : 'Notification permission was not granted.'),
          ));
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
    final scheme = Theme.of(context).colorScheme;
    final hi = widget.hi;
    return Column(
      children: [
        SwitchListTile(
          value: _on ?? false,
          onChanged: (_on == null || _busy) ? null : _toggle,
          secondary: Icon(Icons.brightness_3_rounded, color: scheme.primary),
          title: Text(hi ? 'पंचांग स्मरण' : 'Panchang reminders'),
          subtitle: Text(
            hi
                ? 'हर एकादशी, पूर्णिमा और अमावस्या के दिन सुबह सूचना; प्रतिदिन साधना की याद और आज का श्लोक।'
                : 'A morning nudge on each Ekadashi, Purnima and Amavasya, an evening reminder to do your practice, and the verse of the day.',
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          isThreeLine: true,
        ),
        // Debug-only: opens the notification test panel (fire each kind on
        // demand, see the pending/tray counts, check where a tap lands).
        // Compiled out of release builds.
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: scheme.secondary),
            title: Text(
                hi ? 'सूचना परीक्षण (डिबग)' : 'Notification test (debug)'),
            subtitle: Text(
              hi
                  ? 'हर तरह की सूचना भेजें, गिनती और रीडायरेक्ट जाँचें।'
                  : 'Fire each kind, check counts and where a tap lands.',
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/debug/notifications'),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary)),
    );
  }
}
