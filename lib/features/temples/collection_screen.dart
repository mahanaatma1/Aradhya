import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/async_view.dart';
import 'passport_providers.dart';
import 'passport_stamp.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC97A3E);

/// One collection: the temples of a traditional set, visited or not.
class CollectionScreen extends ConsumerWidget {
  final String tag;
  const CollectionScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);
    final collection = kCollections.firstWhere(
      (c) => c.tag == tag,
      orElse: () => Collection(tag, tag, tag, 0),
    );
    final entries = ref.watch(collectionProvider(tag));

    return Scaffold(
      appBar: AppBar(title: Text(collection.title(hi))),
      body: AsyncView(
        value: entries,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: hi ? 'कोई मंदिर नहीं मिला' : 'No temples found',
        builder: (list) {
          final done = list.where((e) => e.visited).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _Progress(done: done, total: list.length,
                  canonical: collection.canonical, hindi: hi),
              const SizedBox(height: 16),

              // The stamps earned in this set, on their own page. Seeing the
              // gaps is the point -- an empty slot is what a collection is for.
              if (list.isNotEmpty) ...[
                _StampSheet(entries: list, hindi: hi),
                const SizedBox(height: 18),
              ],

              for (final e in list) _Row(entry: e, hindi: hi),
            ],
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int done;
  final int total;
  final int canonical;
  final bool hindi;
  const _Progress({
    required this.done,
    required this.total,
    required this.canonical,
    required this.hindi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$done / $total',
            style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _accent)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 6,
            backgroundColor: _gold.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(_gold),
          ),
        ),
        if (canonical > 0 && total != canonical) ...[
          const SizedBox(height: 8),
          Text(
            // Say it plainly rather than letting a full bar imply a complete
            // set. The app holds what it holds.
            hindi
                ? 'परंपरा में $canonical हैं; इस ऐप में अभी $total दर्ज हैं।'
                : 'The tradition counts $canonical; the app currently holds $total.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final PassportEntry entry;
  final bool hindi;
  const _Row({required this.entry, required this.hindi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            border: Border.all(
                color: entry.visited
                    ? _gold.withValues(alpha: 0.5)
                    : scheme.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: entry.visited
                      ? _gold.withValues(alpha: 0.16)
                      : scheme.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: entry.visited
                          ? _gold.withValues(alpha: 0.6)
                          : scheme.outline.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  entry.visited
                      ? Icons.check_rounded
                      : Icons.circle_outlined,
                  size: 16,
                  color: entry.visited
                      ? _accent
                      : scheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name(hindi),
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 15,
                            fontWeight: entry.visited
                                ? FontWeight.w700
                                : FontWeight.w600)),
                    if (entry.state != null)
                      Text(entry.state!,
                          style: TextStyle(
                              fontSize: 11.5,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}


/// The collected stamps of one set, with an empty ring where one is missing.
class _StampSheet extends StatelessWidget {
  final List<PassportEntry> entries;
  final bool hindi;
  const _StampSheet({required this.entries, required this.hindi});

  @override
  Widget build(BuildContext context) {
    return PassportPaper(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hindi ? 'एकत्रित मुद्रा' : 'STAMPS COLLECTED',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
              color: kStampInk.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final e in entries)
                if (e.visited)
                  PassportStamp(
                    templeId: e.templeId,
                    place: e.name(hindi),
                    date: e.visitedAt,
                    state: e.state,
                    size: 92,
                  )
                else
                  _EmptySlot(label: e.name(hindi)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A stamp that has not been earned: the outline, waiting.
class _EmptySlot extends StatelessWidget {
  final String label;
  const _EmptySlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kStampInk.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: kStampInk.withValues(alpha: 0.34),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
