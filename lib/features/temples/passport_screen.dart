import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/brand.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/stitched_border.dart';
import 'passport_book.dart';
import 'passport_providers.dart';
import 'passport_stamp.dart';

const _accent = Color(0xFF8A6A4F);
const _gold = Color(0xFFC08A2E);

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
              holder: holder, visits: visited.length, hindi: hi),
          const SizedBox(height: 18),

          if (visited.isEmpty)
            _EmptyState(hindi: hi)
          else ...[
            _PageLabel(hi ? 'दर्शन मुद्रा' : 'STAMPS'),
            const SizedBox(height: 10),
            // Six to a page, the way a passport fills.
            for (var i = 0; i < visited.length; i += 6)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StampPage(
                  entries: visited.skip(i).take(6).toList(),
                  hindi: hi,
                  pageNumber: i ~/ 6 + 1,
                ),
              ),
          ],

          const SizedBox(height: 12),
          _PageLabel(hi ? 'संग्रह' : 'COLLECTIONS'),
          const SizedBox(height: 10),
          for (final c in kCollections)
            _CollectionCard(collection: c, hindi: hi),

          if (visited.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PageLabel(hi ? 'यात्रा विवरण' : 'VISIT LOG'),
            const SizedBox(height: 10),
            for (final e in visited) _VisitRow(entry: e, hindi: hi),
          ],

          const SizedBox(height: 20),
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
  Future<Uint8List?> _capture(
      String holder, List<PassportEntry> visited, bool hi) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -4000,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: key,
            child: PassportShareCard(
              holder: holder,
              visits: visited.length,
              recent: visited,
              hindi: hi,
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final ctx = key.currentContext;
      if (ctx == null || !mounted) return null;
      // ignore: use_build_context_synchronously
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  Future<void> _share(
      String holder, List<PassportEntry> visited, bool hi) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _capture(holder, visited, hi);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/aradhya_yatra_passport.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: hi
            ? '${visited.length} मंदिरों के दर्शन — ${Brand.name} यात्रा पासपोर्ट'
            : '${visited.length} temples visited — my ${Brand.name} Yatra Passport',
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(hi ? 'साझा नहीं हो सका' : 'Could not share'),
      ));
    }
  }
}

class _PageLabel extends StatelessWidget {
  final String text;
  const _PageLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(text,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w800,
                color: _accent.withValues(alpha: 0.75),
              )),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
                height: 1, color: _gold.withValues(alpha: 0.3)),
          ),
        ],
      );
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
    final complete = held > 0 && done == held;

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
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2A18))),
                  const SizedBox(height: 2),
                  Text(
                    // Held vs canonical, so an incomplete set reads as
                    // incomplete rather than passing for the whole tradition.
                    held == collection.canonical
                        ? (hindi
                            ? '$done / $held दर्शन'
                            : '$done of $held visited')
                        : (hindi
                            ? '$done / $held · परंपरा में ${collection.canonical}'
                            : '$done of $held · ${collection.canonical} in the tradition'),
                    style: TextStyle(
                        fontSize: 11.5,
                        color: const Color(0xFF3A2A18).withValues(alpha: 0.6)),
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
              value: total == 0 ? 0 : done / total,
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
    final d = entry.visitedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StitchedCard(
        radius: 14,
        background: kPaper,
        stitchColor: _gold.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(12),
        onTap: () => context.push('/temple?id=${entry.templeId}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PassportStamp(
              templeId: entry.templeId,
              place: entry.name(hindi),
              date: d,
              size: 62,
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
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2A18))),
                  if (d != null)
                    Text(
                      '${d.day} ${_mon[d.month - 1]} ${d.year}'
                      '${entry.state != null ? " · ${entry.state}" : ""}',
                      style: TextStyle(
                          fontSize: 11.5,
                          color:
                              const Color(0xFF3A2A18).withValues(alpha: 0.6)),
                    ),
                  if ((entry.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entry.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppFonts.accent,
                            fontSize: 13,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF5A4632))),
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
