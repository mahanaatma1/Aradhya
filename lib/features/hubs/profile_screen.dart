import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/bookmarks.dart';
import '../../core/user/streak.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/currency_icons.dart';
import '../../shared/widgets/app_logo.dart';

/// "You" tab — progress, saved items, language, theme and about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final hi = ref.watch(isHindiProvider);
    final locale = ref.watch(localeProvider);
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

          _SectionLabel('About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text(Brand.name),
              subtitle: Text('${Brand.taglineEn} · v1.0.0'),
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
