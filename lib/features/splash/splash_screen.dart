import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/app_logo.dart';

/// The launch splash — the lotus opens from a bud into full bloom on the warm
/// paper ground, then the wordmark rises in and we route on to onboarding
/// (first run) or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Bloom + Pop at 0.6× speed → a slow, deliberate ~2.6s bloom.
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2580))
      ..forward();
    // Hold on the open bloom, then move on.
    Future.delayed(const Duration(milliseconds: 3300), () {
      if (mounted) context.go(gOnboarded ? '/' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            // Logo fades + lifts in quickly, then blooms across the whole run.
            final logoFade = Curves.easeOut.transform((v / 0.25).clamp(0.0, 1.0));
            // The pop lives in the petals; the tile just scales up smoothly.
            final tileScale = 0.9 + 0.1 * Curves.easeOutCubic.transform(v);
            // Text rises in over the second half.
            final textT = ((v - 0.5) / 0.45).clamp(0.0, 1.0);
            final textFade = Curves.easeOut.transform(textT);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: logoFade,
                  child: Transform.scale(
                    scale: tileScale,
                    child: AppLogo(size: 124, bloom: v),
                  ),
                ),
                const SizedBox(height: 30),
                Opacity(
                  opacity: textFade,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - textFade)),
                    child: Column(
                      children: [
                        Text(
                          hi ? Brand.nameHi : Brand.name,
                          style: TextStyle(
                            fontFamily: hi
                                ? AppFonts.devanagari
                                : AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 40,
                            color: AppColors.inkLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hi ? Brand.taglineHi : Brand.taglineEn,
                          style: TextStyle(
                            fontFamily:
                                hi ? AppFonts.devanagari : AppFonts.accent,
                            fontSize: 16,
                            color: AppColors.inkSoftLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
