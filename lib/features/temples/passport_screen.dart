import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'passport_book.dart';
import 'passport_providers.dart';
import 'passport_sections.dart';
import 'passport_stamp.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC97A3E); // brass foil, was gold-leaf

/// My Yatra — a pilgrimage passport, built to read like one.
///
/// The app had been recording every temple visit since Phase 0 with nowhere to
/// show them. A list would have discharged the requirement; a passport is what
/// the thing actually is. Cover, data page, stamps struck at their own angles,
/// and a card that can be shared without any of it leaving the device first.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final holder = ref.watch(userNameProvider);
    final visited = ref.watch(visitedTemplesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'मेरी यात्रा' : 'My Yatra'),
        actions: [
          if (visited.isNotEmpty)
            IconButton(
              tooltip: hi ? 'साझा करें' : 'Share',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _share(holder, visited, hi),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          PassportCover(
            holder: holder,
            visits: visited.length,
            hindi: hi,
            stats: PassportStats.of(visited),
          ),
          const SizedBox(height: 16),

          if (visited.isEmpty)
            _EmptyState(hindi: hi)
          else ...[
            const StatsBar(),
            const SizedBox(height: 18),

            // Recent stamps first: the passport is the stamps.
            SectionHead(
              hi ? 'हाल की मुद्रा' : 'RECENT STAMPS',
              actionLabel: visited.length > 6 ? (hi ? 'सब' : 'VIEW ALL') : null,
              onAction: () => context.push('/passport/journey'),
            ),
            const SizedBox(height: 10),
            StampPage(
              entries: visited.take(6).toList(),
              hindi: hi,
              pageNumber: 1,
            ),
            const SizedBox(height: 20),

            SectionHead(
              hi ? 'यात्रा वृत्तांत' : 'YATRA JOURNEY',
              actionLabel: visited.length > 3 ? (hi ? 'सब' : 'VIEW ALL') : null,
              onAction: () => context.push('/passport/journey'),
            ),
            const SizedBox(height: 10),
            JourneyTimeline(entries: visited.take(3).toList(), hindi: hi),
            const SizedBox(height: 20),
          ],

          const _NextStamp(),

          SectionHead(
            hi ? 'संग्रह' : 'COLLECTIONS',
            actionLabel: hi ? 'सब' : 'VIEW ALL',
            onAction: () => context.push('/passport/collections'),
          ),
          const SizedBox(height: 10),
          for (final c in kCollections.take(4))
            _CollectionCard(collection: c, hindi: hi),
          const SizedBox(height: 12),

          SectionHead(
            hi ? 'उपलब्धियाँ' : 'MILESTONES',
            actionLabel: hi ? 'सब' : 'VIEW ALL',
            onAction: () => context.push('/passport/milestones'),
          ),
          const SizedBox(height: 12),
          const MilestoneRail(preview: true),

          const SizedBox(height: 22),
          _PrivacyNote(hindi: hi),
        ],
      ),
    );
  }

  // ---- share ----------------------------------------------------------

  /// Renders the card off-screen and hands the file to the share sheet.
  ///
  /// The image is built from data already on the device and written to a temp
  /// file the user then chooses what to do with. Nothing is uploaded by the
  /// app itself.
  ///
  /// Two things here are load-bearing and were wrong the first time. The card
  /// is taller than the screen, and an overlay child is laid out against the
  /// screen's constraints -- so without the OverflowBox the Column overflowed
  /// and the capture came out clipped. And a fixed delay is not a guarantee
  /// that anything was painted; the boundary has to be waited on frame by
  /// frame until it actually has something in it.
  Future<Uint8List?> _capture(
      String holder, List<PassportEntry> visited, bool hi) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: 0,
        // The overlay already lays this out unconstrained, which is exactly
        // what a tall card needs. Forcing an OverflowBox here made the box
        // itself infinite, and an infinite size yields a non-finite transform
        // that toImage rejects outright.
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: key,
            child: PassportShareCard(
              holder: holder,
              visits: visited.length,
              recent: visited,
              hindi: hi,
              stats: PassportStats.of(visited),
              jyotirlinga: _setCount('jyotirlinga'),
              dham: _setCount('char_dham'),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      // Wait for real frames, not a guessed millisecond count.
      RenderRepaintBoundary? boundary;
      for (var i = 0; i < 12; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return null;
        final object = key.currentContext?.findRenderObject();
        if (object is RenderRepaintBoundary && !object.debugNeedsPaint) {
          boundary = object;
          break;
        }
      }
      if (boundary == null) {
        throw StateError('share card never painted');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  int _setCount(String tag) {
    final list = ref.read(collectionProvider(tag)).valueOrNull ?? const [];
    return list.where((e) => e.visited).length;
  }

  Future<void> _share(
      String holder, List<PassportEntry> visited, bool hi) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _capture(holder, visited, hi);
      if (bytes == null) return;
      const name = 'aradhya_yatra_passport.png';
      // The result is deliberately not inspected. ShareResultStatus.unavailable
      // means "shared, but the user's action could not be determined" -- it is
      // a success, and the web implementation returns it on every successful
      // share. Treating it as a failure reported an error after the share had
      // already worked.
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: 'image/png')],
        fileNameOverrides: const [name],
        text: hi
            ? '${visited.length} मंदिरों के दर्शन — ${Brand.name} यात्रा पासपोर्ट'
            : '${visited.length} temples visited — my ${Brand.name} Yatra Passport',
      ));
    } catch (e, st) {
      // The failure has to be visible somewhere. A silent catch is why this
      // looked like "share does nothing" rather than a fixable bug.
      debugPrint('passport share failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          '${hi ? 'साझा नहीं हो सका' : 'Could not share'}: $e',
          maxLines: 4,
        ),
      ));
    }
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;
  final bool hindi;
  const _CollectionCard({required this.collection, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(collectionProvider(collection.tag)).valueOrNull ?? const [];
    final held = entries.length;
    final done = entries.where((e) => e.visited).length;
    // Progress is measured against what the tradition names, not against how
    // many rows happen to carry the tag -- "5 of 4" is not a sentence.
    final canonical = collection.canonical;
    final complete = canonical > 0 && done >= canonical;
    final extra = held > canonical ? held - canonical : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StitchedCard(
        radius: 16,
        onTap: () => context.push('/passport/${collection.tag}'),
        background: complete ? _gold.withValues(alpha: 0.12) : kPaper,
        stitchColor: _gold.withValues(alpha: complete ? 0.8 : 0.45),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _ProgressRing(done: done, total: canonical == 0 ? 1 : canonical),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(collection.title(hindi),
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2A18))),
                  const SizedBox(height: 2),
                  Text(
                    hindi
                        ? '$done / $canonical दर्शन'
                        : '$done / $canonical visited',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A2A18).withValues(alpha: 0.75)),
                  ),
                  if (extra > 0)
                    Text(
                      hindi
                          ? '$canonical पारंपरिक + $extra अन्य'
                          : '$canonical traditional + $extra additional',
                      style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF3A2A18)
                              .withValues(alpha: 0.55)),
                    ),
                ],
              ),
            ),
            if (complete)
              const Icon(Icons.workspace_premium_rounded,
                  size: 20, color: _gold)
            else
              Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: const Color(0xFF3A2A18).withValues(alpha: 0.35)),
          ],
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
              // A set can be over-full (5 darshan against 4 traditional
              // Dhams), and a ring past 100% draws as a smear.
              value: total == 0 ? 0 : (done / total).clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: _gold.withValues(alpha: 0.18),
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

class _EmptyState extends StatelessWidget {
  final bool hindi;
  const _EmptyState({required this.hindi});

  @override
  Widget build(BuildContext context) {
    return PassportPaper(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.approval_rounded,
              size: 34, color: kStampInk.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(
            hindi
                ? 'अभी कोई मुद्रा नहीं। किसी मंदिर के पृष्ठ पर "दर्शन किया" चुनें — वह यहाँ अंकित हो जाएगा।'
                : 'No stamps yet. Mark a temple as visited on its page and it will be struck here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF3A2A18).withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.go('/temples'),
            icon: const Icon(Icons.explore_rounded, size: 17),
            label: Text(hindi ? 'मंदिर देखें' : 'Browse temples'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _gold.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
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
                ? 'आपकी यात्रा, टिप्पणियाँ और रेटिंग कहीं नहीं भेजी जातीं। साझा करने पर केवल वही चित्र जाता है जो आप चुनते हैं।'
                : 'Your visits, notes and ratings are never sent anywhere. Sharing sends only the image you choose to send.',
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


/// The set closest to finishing, and what is still missing from it.
///
/// A passport that only records the past is a ledger. Naming the nearest
/// remaining stamp is what makes it a plan -- and it is drawn from the same
/// visit records, so it cannot claim progress that has not happened.
class _NextStamp extends ConsumerWidget {
  const _NextStamp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(isHindiProvider);

    Collection? best;
    List<PassportEntry> missing = const [];
    double bestShare = -1;

    for (final c in kCollections) {
      final list = ref.watch(collectionProvider(c.tag)).valueOrNull;
      if (list == null || list.isEmpty) continue;
      final done = list.where((e) => e.visited).length;
      if (done == 0 || done == list.length) continue;
      final share = done / list.length;
      if (share > bestShare) {
        bestShare = share;
        best = c;
        missing = list.where((e) => !e.visited).toList();
      }
    }

    final set = best;
    if (set == null || missing.isEmpty) return const SizedBox.shrink();
    final names = missing.take(3).map((e) => e.name(hi)).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StitchedCard(
        radius: 16,
        background: kPaper,
        stitchColor: _gold.withValues(alpha: 0.55),
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/passport/${set.tag}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.push_pin_rounded, size: 18, color: _gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hi ? 'अगली मुद्रा' : 'NEXT STAMP',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: _accent.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hi
                        ? '${set.title(true)} — ${missing.length} शेष'
                        : '${set.title(false)} — ${missing.length} to go',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A3220),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    names,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: _accent.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: _accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
