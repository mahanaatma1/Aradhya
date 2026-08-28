import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/source_chip.dart';
import '../related/related_rail.dart';
import 'festival_models.dart';
import 'festival_providers.dart';
import 'festival_reminder.dart';
import 'festivals_screen.dart' show ruleLabel;

const _accent = Color(0xFFE0762A);
const _accentDeep = Color(0xFFA7430F);

/// Festival slug -> `puja_vidhi.id` in the legacy `content.sqlite` corpus.
///
/// The two tables live in different databases with no foreign key between
/// them (`festivals` is in `gyan.sqlite`, built from JSONL; `puja_vidhi` is
/// in the older hand-written `content.sqlite`), so the link is made here by
/// matching each festival's slug to the `puja_vidhi` row actually verified
/// to describe that same occasion — checked by id against
/// `assets/db/content.sqlite` directly, not guessed from the title text.
const _pujaVidhiId = <String, int>{
  'chaitra-navratri': 5,
  'sharad-navratri': 5,
  'ram-navami': 13,
  'hanuman-jayanti': 20,
  'ganesh-chaturthi': 6,
  'janmashtami': 12,
  'karva-chauth': 15,
  'vat-savitri': 16,
  'dhanteras': 7,
  'diwali': 8,
  'govardhan-puja': 9,
  'bhai-dooj': 10,
  'chhath': 17,
  'makar-sankranti': 18,
  'vasant-panchami': 19,
  'holika-dahan': 14,
};

/// One festival: when it falls, what is done, and where that is recorded.
class FestivalDetailScreen extends ConsumerWidget {
  final int festivalId;
  const FestivalDetailScreen({super.key, required this.festivalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final festival = ref.watch(festivalByIdProvider(festivalId));

    return Scaffold(
      body: AsyncView(
        value: festival,
        isEmpty: (f) => f == null,
        emptyMessage: hi ? 'त्योहार नहीं मिला' : 'Festival not found',
        builder: (f) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 168,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(f!.title(hi),
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white)),
                background: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, _accentDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.desc(hi),
                        style: const TextStyle(fontSize: 15.5, height: 1.5)),
                    const SizedBox(height: 16),
                    _WhenCard(festival: f, hindi: hi),
                    if (!f.isPanIndia) _RegionNote(festival: f, hindi: hi),
                    if ((f.ritual(hi) ?? '').isNotEmpty)
                      _Section(
                        title: hi ? 'विधि' : 'Ritual',
                        body: f.ritual(hi)!,
                        icon: Icons.local_florist_rounded,
                      ),
                    if ((f.fast(hi) ?? '').isNotEmpty)
                      _Section(
                        title: hi ? 'व्रत नियम' : 'Fast rules',
                        body: f.fast(hi)!,
                        icon: Icons.no_food_rounded,
                      ),
                    _RemindMe(festival: f, hindi: hi),
                    if (f.deityEntityId != null)
                      _DeityLink(entityId: f.deityEntityId!, hindi: hi),
                    if (f.storyNodeId != null)
                      _StoryLink(sceneId: f.storyNodeId!, hindi: hi),
                    if (_pujaVidhiId[f.slug] != null)
                      _PujaLink(pujaId: _pujaVidhiId[f.slug]!, hindi: hi),
                    const SizedBox(height: 14),
                    SourceChip(
                      sourceName: f.sourceName,
                      sourceRef: f.sourceRef,
                      sourceUrl: f.sourceUrl,
                      lastVerifiedAt: f.lastVerifiedAt,
                      hindi: hi,
                    ),
                    RelatedRail(src: 'gyan', table: 'festivals', id: f.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The resolved dates, with the rule stated beneath them.
///
/// Both are shown deliberately: the date is this year's answer, the rule is
/// the durable fact, and a reader who knows the tithi can check our arithmetic.
class _WhenCard extends ConsumerWidget {
  final Festival festival;
  final bool hindi;
  const _WhenCard({required this.festival, required this.hindi});

  static const _mon = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dates = ref.watch(festivalDatesProvider(festival.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hindi ? 'कब' : 'When',
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: _accentDeep)),
          const SizedBox(height: 8),
          dates.when(
            loading: () => Text(hindi ? 'गणना हो रही है…' : 'Calculating…',
                style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            error: (e, st) => Text(
                hindi ? 'तिथि उपलब्ध नहीं' : 'Date unavailable',
                style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.5))),
            data: (list) {
              if (list.isEmpty) {
                // Never invent a date. Onam and the like need a nakshatra rule
                // the resolver does not implement, and saying so is correct.
                return Text(
                  hindi
                      ? 'इस पर्व की गणना पंचांग से अभी उपलब्ध नहीं है।'
                      : 'This festival is not yet resolvable from the panchang.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.6)),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in list.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${d.day} ${_mon[d.month - 1]} ${d.year}',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: d == list.first ? 20 : 14,
                          fontWeight: d == list.first
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: d == list.first
                              ? _accentDeep
                              : scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            ruleLabel(festival, hindi),
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.3,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            hindi
                ? 'तिथि आपके स्थान के सूर्योदय से गणना की गई है।'
                : 'Computed from the tithi at sunrise for your location.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

/// States plainly that a festival is not kept everywhere, and where it is.
/// Sets a one-off reminder for the evening before the next occurrence.
///
/// Disabled when the rule does not resolve — there is no date to remind about,
/// and offering the button anyway would promise something we cannot deliver.
class _RemindMe extends ConsumerWidget {
  final Festival festival;
  final bool hindi;
  const _RemindMe({required this.festival, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(festivalDatesProvider(festival.id)).valueOrNull;
    final set = ref.watch(festivalRemindersProvider).contains(festival.id);
    final next = (dates == null || dates.isEmpty) ? null : dates.first;
    final usable = next != null && next.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: FilledButton.tonalIcon(
        onPressed: !usable
            ? null
            : () async {
                final on = await ref
                    .read(festivalRemindersProvider.notifier)
                    .toggle(festival, next, hindi: hindi);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(on
                      ? (hindi
                          ? 'एक दिन पहले शाम को याद दिलाया जाएगा।'
                          : 'You will be reminded the evening before.')
                      : (hindi ? 'अनुस्मारक हटाया गया।' : 'Reminder removed.')),
                ));
              },
        icon: Icon(
            set ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
            size: 17),
        label: Text(set
            ? (hindi ? 'अनुस्मारक लगा है' : 'Reminder set')
            : (hindi ? 'याद दिलाएँ' : 'Remind me')),
        style: FilledButton.styleFrom(
          backgroundColor: _accent.withValues(alpha: set ? 0.28 : 0.14),
          foregroundColor: _accentDeep,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _RegionNote extends StatelessWidget {
  final Festival festival;
  final bool hindi;
  const _RegionNote({required this.festival, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.place_outlined,
              size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              (hindi ? 'मुख्यतः: ' : 'Chiefly kept in: ') +
                  festival.regions.map((r) => r.replaceAll('-', ' ')).join(', '),
              style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _Section(
      {required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _accentDeep),
              const SizedBox(width: 7),
              Text(title,
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.78))),
        ],
      ),
    );
  }
}

class _StoryLink extends StatelessWidget {
  final int sceneId;
  final bool hindi;
  const _StoryLink({required this.sceneId, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/gyan/scene/$sceneId'),
        icon: const Icon(Icons.auto_stories_rounded, size: 16),
        label: Text(hindi ? 'कथा पढ़ें' : 'Read the story'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentDeep,
          side: BorderSide(color: _accent.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _PujaLink extends StatelessWidget {
  final int pujaId;
  final bool hindi;
  const _PujaLink({required this.pujaId, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/puja-detail?id=$pujaId'),
        icon: const Icon(Icons.local_florist_rounded, size: 16),
        label: Text(hindi ? 'पूजा विधि देखें' : 'See puja vidhi'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentDeep,
          side: BorderSide(color: _accent.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _DeityLink extends StatelessWidget {
  final int entityId;
  final bool hindi;
  const _DeityLink({required this.entityId, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/gyan/entity/$entityId'),
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text(hindi ? 'देवता के बारे में' : 'About the deity'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentDeep,
          side: BorderSide(color: _accent.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
