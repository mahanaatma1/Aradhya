import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import 'stitched_border.dart';

/// A small floating square button framed by the signature stitched border that
/// switches the app language on tap. Mounted globally (see `main.dart`) so it
/// appears on every screen instead of a per-screen top-nav toggle. It shows the
/// language you'll switch **to** (हिं when in English, EN when in Hindi).
class LanguageFab extends ConsumerWidget {
  const LanguageFab({super.key});

  // Warm paper used for the stitch + label, matching the Verse-of-the-Day card.
  static const _cream = Color(0xFFF7EFE6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hi = ref.watch(localeProvider).languageCode == 'hi';
    final target = hi ? 'EN' : 'हिं';

    return Semantics(
      button: true,
      label: hi ? 'Switch to English' : 'हिंदी में बदलें',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ref.read(localeProvider.notifier).state =
              hi ? const Locale('en') : const Locale('hi'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              // Same terracotta gradient as the Verse-of-the-Day card.
              gradient: const LinearGradient(
                colors: [AppColors.terracotta, AppColors.terracottaDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: StitchedBorderPainter(
                color: _cream,
                inset: 5,
                radius: 8,
                strokeWidth: 1.3,
                dash: 4,
                gap: 3,
              ),
              child: Center(
                child: Text(
                  target,
                  style: TextStyle(
                    fontFamily: hi ? AppFonts.body : AppFonts.devanagari,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _cream,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
