import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../components/components.dart';
import '../motion/motion.dart';
import '../tokens/tokens.dart';

/// Debug gallery of every kit component and motion primitive, in the live
/// theme and language. Route: `/debug/kit` (debug builds only).
class KitGalleryScreen extends ConsumerStatefulWidget {
  const KitGalleryScreen({super.key});

  @override
  ConsumerState<KitGalleryScreen> createState() => _KitGalleryScreenState();
}

class _KitGalleryScreenState extends ConsumerState<KitGalleryScreen> {
  int _seg = 0;
  int _tab = 0;
  bool _toggle = true;
  double _progress = 0.62;
  int _burst = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cats = context.categories;
    final hi = ref.watch(isHindiProvider);
    final motion = ref.watch(motionLevelProvider);
    final tier = ref.watch(perfTierProvider);

    return AppScaffold(
      slivers: [
        AppTopBar(
          title: hi ? 'किट गैलरी' : 'Kit gallery',
          subtitle: 'tier ${tier.name} · motion ${motion.name}',
          actions: [
            IconCircleButton(
              icon: Icons.brightness_6_rounded,
              tooltip: 'Toggle theme',
              onPressed: () => ref.read(themeModeProvider.notifier).set(
                  context.isDarkTheme ? ThemeMode.light : ThemeMode.dark),
            ),
            const SizedBox(width: Space.x2),
            IconCircleButton(
              icon: Icons.translate_rounded,
              tooltip: 'Toggle language',
              onPressed: () => ref.read(localeProvider.notifier).state =
                  hi ? const Locale('en') : const Locale('hi'),
            ),
          ],
        ),
        SliverPage(children: [
          SegmentedControl<MotionLevel>(
            values: MotionLevel.values,
            label: (v) => v.name,
            selected: motion,
            onChanged: (v) => ref.read(motionLevelProvider.notifier).set(v),
          ),
          const SectionHeader(
              title: 'Buttons', eyebrow: 'Controls', padding: EdgeInsets.zero),
          Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
            PrimaryButton(
                label: hi ? 'आज का दीया जलाएँ' : 'Light today\'s diya',
                icon: Icons.local_fire_department_rounded,
                onPressed: () => showAppSnack(context, hi ? 'दीया जला' : 'Diya lit',
                    kind: NoticeKind.success)),
            SecondaryButton(label: hi ? 'बाद में' : 'Later', onPressed: () {}),
            GhostButton(label: hi ? 'और जानें' : 'Learn more', onPressed: () {}),
            PillButton(label: hi ? 'सुनें' : 'Listen', icon: Icons.volume_up_rounded, onPressed: () {}),
            IconCircleButton(icon: Icons.bookmark_rounded, tooltip: 'Bookmark', onPressed: () {}),
            IconCircleButton(icon: Icons.share_rounded, tooltip: 'Share', filled: true, onPressed: () {}),
            const PrimaryButton(label: 'Disabled'),
            const PrimaryButton(label: 'Loading', loading: true),
          ]),
          const SectionHeader(title: 'Chips & tabs', padding: EdgeInsets.zero),
          TabStrip(
            tabs: hi ? const ['सभी', 'त्योहार', 'तिथि व्रत', 'विशेष'] : const ['All', 'Festivals', 'Tithi vrat', 'Special'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
            padding: EdgeInsets.zero,
          ),
          Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
            TagPill(label: hi ? 'सत्यापित' : 'Verified', tint: c.success, icon: Icons.verified_rounded),
            TagPill(label: hi ? 'चार धाम' : 'Char Dham', tint: c.cosmos),
            TagPill(label: 'Gita 2·47', tint: c.gold),
            const CountBadge(12),
            StreakFlame(7),
          ]),
          SegmentedControl<int>(
            values: const [0, 1, 2],
            label: (v) => hi ? ['हल्का', 'गहरा', 'सिस्टम'][v] : ['Light', 'Dark', 'System'][v],
            selected: _seg,
            onChanged: (v) => setState(() => _seg = v),
          ),
          const SectionHeader(title: 'Cards', padding: EdgeInsets.zero),
          VerseCard(
            eyebrow: hi ? 'आज का श्लोक' : 'Verse of the day',
            source: 'Gita 2·47',
            verse: 'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।',
            transliteration: 'karmaṇy-evādhikāras te mā phaleṣu kadācana',
            translation: hi
                ? 'तुम्हारा अधिकार केवल कर्म पर है, उसके फलों पर कभी नहीं।'
                : 'You have a right to your actions alone, never to their fruits.',
            actions: [
              PillButton(label: hi ? 'सुनें' : 'Listen', icon: Icons.volume_up_rounded, onPressed: () {}),
              const Spacer(),
              IconCircleButton(icon: Icons.bookmark_border_rounded, tooltip: 'Save', size: 36, onPressed: () {}),
              const SizedBox(width: Space.x1),
              IconCircleButton(icon: Icons.share_rounded, tooltip: 'Share', size: 36, onPressed: () {}),
            ],
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x3,
            childAspectRatio: 1.5 / MediaQuery.textScalerOf(context).scale(1),
            children: [
              TileCard(label: hi ? 'मंदिर' : 'Mandir', sublabel: hi ? 'संध्या अर्पण' : 'offer at dusk', style: cats.scriptures, motif: const Icon(Icons.local_fire_department_rounded), onTap: () {}),
              TileCard(label: hi ? 'जप' : 'Japa', sublabel: '108', style: cats.mantras, motif: const Icon(Icons.radio_button_checked_rounded), onTap: () {}),
              TileCard(label: hi ? 'प्राणायाम' : 'Breathe', sublabel: '5 min', style: cats.quiz, motif: const Icon(Icons.air_rounded), onTap: () {}),
              TileCard(label: hi ? 'कर्म पत्रिका' : 'Journal', sublabel: '1 prompt', style: cats.astrology, motif: const Icon(Icons.edit_rounded), onTap: () {}),
            ],
          ),
          Row(children: [
            Expanded(child: StatTile(label: hi ? 'श्रृंखला' : 'Streak', value: 12, unit: hi ? 'दिन' : 'days', tint: c.flame)),
            const SizedBox(width: Space.x3),
            Expanded(child: StatTile(label: hi ? 'कमल' : 'Kamal', value: 240, tint: c.gold)),
          ]),
          AccentCard(
            style: cats.personality,
            onTap: () {},
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(hi ? 'व्यक्तित्व · 2 मिनट' : 'Personality · 2 min', color: Colors.white70),
              const SizedBox(height: Space.x2),
              Text(hi ? 'अपना आत्म-पथ खोजें' : 'Discover your Soul Path',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            ]),
          ),
          const SectionHeader(title: 'Progress & lists', padding: EdgeInsets.zero),
          Row(children: [
            ProgressRing(value: _progress, child: Text('${(_progress * 100).round()}', style: Theme.of(context).textTheme.labelLarge)),
            const SizedBox(width: Space.x4),
            Expanded(child: ProgressBar(value: _progress)),
            const SizedBox(width: Space.x3),
            PillButton(label: '+', onPressed: () => setState(() => _progress = (_progress + .15) % 1)),
          ]),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              NavRow(title: hi ? 'बुकमार्क' : 'Bookmarks', subtitle: hi ? '14 सहेजे गए' : '14 saved', leading: const Icon(Icons.bookmark_rounded), onTap: () {}),
              const StitchedDivider(indent: Space.x4),
              ToggleRow(label: hi ? 'दैनिक अनुस्मारक' : 'Daily reminder', subtitle: '6:00 AM', leading: const Icon(Icons.alarm_rounded), value: _toggle, onChanged: (v) => setState(() => _toggle = v)),
            ]),
          ),
          NoticeBanner(
            kind: NoticeKind.offline,
            text: hi ? 'हिंदी आवाज़ ऑफ़लाइन उपलब्ध नहीं है।' : 'The Hindi voice is not available offline.',
            action: GhostButton(label: hi ? 'इंस्टॉल करें' : 'Install', onPressed: () {}),
          ),
          AppSearchField(hint: hi ? 'शास्त्र, मंदिर, देवता खोजें…' : 'Search scriptures, temples, deities…'),
          const OrnamentDivider(),
          const FestivalStripe(),
          Center(child: PageDots(count: 4, index: _tab % 4)),
          Row(children: [
            const DeityAvatar(name: 'Ganesha'),
            const SizedBox(width: Space.x3),
            Expanded(child: EmptyState(title: hi ? 'अभी यहाँ कुछ नहीं' : 'Nothing here yet', body: hi ? 'पहला श्लोक सहेजें' : 'Save your first verse')),
          ]),
          SecondaryButton(
            label: hi ? 'शीट खोलें' : 'Open sheet',
            onPressed: () => showAppSheet(
              context,
              title: hi ? 'आवाज़ चुनें' : 'Choose a voice',
              builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                NavRow(title: 'Hindi (offline)', onTap: () => Navigator.pop(context)),
                NavRow(title: 'English (offline)', onTap: () => Navigator.pop(context)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Particles & shaders', padding: EdgeInsets.zero),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: Radii.rLg,
              child: ShaderSurface(
                id: ShaderId.utsavSky,
                colors: c.skyGradient,
                params: const [0.4],
                fallback: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: c.skyGradient,
                    ),
                  ),
                ),
                child: ParticleField(
                  key: ValueKey(_burst),
                  emitters: [
                    Emitters.stars(color: c.inkOnDeep),
                    Emitters.petals(color: c.gold),
                    if (_burst > 0) Emitters.sparkleBurst(color: c.gold),
                  ],
                  child: Center(
                    child: PrimaryButton(
                      label: hi ? 'चमक' : 'Sparkle',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: () => setState(() => _burst++),
                    ),
                  ),
                ),
              ),
            ),
          ),
          RevealList(children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.x2),
                child: SurfaceCard(child: Text('Reveal ${i + 1}')),
              ),
          ]),
        ]),
      ],
    );
  }
}
