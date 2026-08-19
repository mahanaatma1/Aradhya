import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import 'passport_providers.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC08A2E);

/// My Yatra — the pilgrimage passport.
///
/// The app already recorded every temple visit and had nowhere to show them.
/// This is that page: what has been visited, what the traditional sets are,
/// and how far through each one you are.
///
/// Everything here stays on the device. There is no sharing, no upload and no
/// leaderboard, because a pilgrimage record is closer to a journal than to a
/// checklist and the app should not turn it into a score to compare.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final visited = ref.watch(visitedTemplesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'मेरी यात्रा' : 'My Yatra')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _Header(count: visited.length, hindi: hi),
          const SizedBox(height: 20),
          _SectionLabel(hi ? 'संग्रह' : 'COLLECTIONS'),
          const SizedBox(height: 10),
          for (final c in kCollections) _CollectionCard(collection: c, hindi: hi),
          const SizedBox(height: 22),
          _SectionLabel(hi ? 'आपकी यात्राएँ' : 'YOUR VISITS'),
          const SizedBox(height: 10),
          if (visited.isEmpty)
            _EmptyState(hindi: hi)
          else
            for (final e in visited) _VisitRow(entry: e, hindi: hi),
          const SizedBox(height: 20),
          _PrivacyNote(hindi: hi),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool hindi;
  const _Header({required this.count, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, Color(0xFF4A3220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.temple_hindu_rounded, size: 34, color: Color(0xFFF2DA86)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? (hindi ? 'अभी कोई यात्रा नहीं' : 'No visits yet')
                      : (hindi
                          ? '$count मंदिर दर्शन किए'
                          : '$count temples visited'),
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFF8EF)),
                ),
                const SizedBox(height: 3),
                Text(
                  hindi
                      ? 'यह अभिलेख केवल आपके उपकरण पर रहता है।'
                      : 'This record stays on your device.',
                  style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFFFF8EF).withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;
  final bool hindi;
  const _CollectionCard({required this.collection, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entries =
        ref.watch(collectionProvider(collection.tag)).valueOrNull ?? const [];
    final held = entries.length;
    final done = entries.where((e) => e.visited).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/passport/${collection.tag}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              _ProgressRing(done: done, total: held == 0 ? 1 : held),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection.title(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      // Held vs canonical, so an incomplete set reads as
                      // incomplete instead of passing for the whole tradition.
                      held == collection.canonical
                          ? (hindi
                              ? '$done / $held दर्शन'
                              : '$done of $held visited')
                          : (hindi
                              ? '$done / $held दर्शन · परंपरा में ${collection.canonical}'
                              : '$done of $held visited · ${collection.canonical} in the tradition'),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressRing({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : done / total,
              strokeWidth: 4,
              backgroundColor: _gold.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(_gold),
            ),
          ),
          Text('$done',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _accent)),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  final PassportEntry entry;
  final bool hindi;
  const _VisitRow({required this.entry, required this.hindi});

  static const _mon = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = entry.visitedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/temple?id=${entry.templeId}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The stamp: the mark that this one was actually reached.
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withValues(alpha: 0.55)),
                ),
                child: const Icon(Icons.check_rounded, size: 19, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name(hindi),
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
                    if (d != null)
                      Text(
                        '${d.day} ${_mon[d.month - 1]} ${d.year}'
                        '${entry.state != null ? " · ${entry.state}" : ""}',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    if ((entry.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(entry.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              fontStyle: FontStyle.italic,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.75))),
                    ],
                    if (entry.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              i <= entry.rating!
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: _gold,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hindi;
  const _EmptyState({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            hindi
                ? 'किसी मंदिर के पृष्ठ पर "दर्शन किया" चुनें — वह यहाँ दर्ज हो जाएगा।'
                : 'Mark a temple as visited on its page and it will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/temples'),
            icon: const Icon(Icons.explore_rounded, size: 17),
            label: Text(hindi ? 'मंदिर देखें' : 'Browse temples'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ));
}

class _PrivacyNote extends StatelessWidget {
  final bool hindi;
  const _PrivacyNote({required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 13, color: scheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            hindi
                ? 'आपकी यात्रा, टिप्पणियाँ और रेटिंग कहीं नहीं भेजी जातीं।'
                : 'Your visits, notes and ratings are never sent anywhere.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
