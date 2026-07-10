import 'package:flutter/material.dart';

/// A placeholder block used to build skeleton loaders.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 10,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.09), scheme.surface);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps skeleton content and sweeps a soft highlight across it.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1250))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.09), scheme.surface);
    final highlight = Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.015), scheme.surface);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.15, 0.5, 0.85],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _Slide(_c.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Slide extends GradientTransform {
  final double t;
  const _Slide(this.t);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

// ---------------------------------------------------------------------------
// Presets — drop these straight into a screen's loading state.
// ---------------------------------------------------------------------------

/// A list of icon + two-line rows (hubs, directories, mantra/aarti lists).
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;
  const SkeletonList(
      {super.key, this.count = 7, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => Row(
          children: [
            const SkeletonBox(width: 46, height: 46, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 150, height: 14, radius: 7),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial temple cards (cover + facts strip + footer).
class SkeletonTempleCards extends StatelessWidget {
  final int count;
  const SkeletonTempleCards({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(height: 150, radius: 16),
            SizedBox(height: 12),
            SkeletonBox(width: 200, height: 13, radius: 7),
          ],
        ),
      ),
    );
  }
}

/// A reader placeholder — title then paragraph lines.
class SkeletonReader extends StatelessWidget {
  const SkeletonReader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SkeletonBox(width: 220, height: 22, radius: 8),
          const SizedBox(height: 20),
          const SkeletonBox(height: 120, radius: 16),
          const SizedBox(height: 20),
          for (var i = 0; i < 8; i++) ...[
            SkeletonBox(
                width: i.isEven ? double.infinity : 260, height: 13, radius: 7),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// A single card placeholder (e.g. the daily-verse card).
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Shimmer(child: SkeletonBox(height: height, radius: 18));
  }
}
