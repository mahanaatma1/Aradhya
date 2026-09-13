import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';
import 'text.dart';
import 'utsav_decor.dart';

enum CardLevel { flat, rest, raised }

/// The base card: surface, 2 px border, radius 24, optional press.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.level = CardLevel.rest,
    this.padding = Insets.card,
    this.radius = Radii.lg,
    this.color,
    this.borderColor,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final CardLevel level;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = context.elevation;
    final box = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border, width: 2),
        boxShadow: switch (level) {
          CardLevel.flat => const [],
          CardLevel.rest => e.rest,
          CardLevel.raised => e.raised,
        },
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null && onLongPress == null) return box;
    return PressScale(onTap: onTap, onLongPress: onLongPress, child: box);
  }
}

/// A gradient card in a category colour, white text, bandhani texture.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.child,
    required this.style,
    this.onTap,
    this.padding = Insets.card,
    this.radius = Radii.lg,
    this.texture = true,
    this.minHeight,
  });

  final Widget child;
  final CategoryStyle style;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool texture;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      constraints:
          minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: style.linear,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: context.elevation.rest,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (texture) const Positioned.fill(child: BandhaniDots(opacity: .18)),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: context.colors.inkOnAccent),
              child: IconTheme.merge(
                data: IconThemeData(color: context.colors.inkOnAccent),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return box;
    return PressScale(onTap: onTap, haptic: HapticKind.light, child: box);
  }
}

/// Square-ish gradient tile with a motif and a bilingual label.
class TileCard extends StatelessWidget {
  const TileCard({
    super.key,
    required this.label,
    required this.style,
    this.motif,
    this.sublabel,
    this.onTap,
    this.minHeight = 96,
  });

  final String label;
  final String? sublabel;
  final CategoryStyle style;
  final Widget? motif;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final titleStyle =
        tt.titleMedium?.copyWith(fontFamily: AppFonts.display, color: Colors.white);
    final subStyle = tt.bodySmall?.copyWith(color: Colors.white70);
    return AccentCard(
      style: style,
      onTap: onTap,
      radius: Radii.md,
      minHeight: minHeight,
      padding: Insets.cardTight,
      child: LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final h = box.hasBoundedHeight ? box.maxHeight : double.infinity;
        // Fixed grid cells cannot grow, so the tile trades detail for fit:
        // stacked motif → motif beside a one-line title → title only.
        final roomy = h >= 96 * scale;
        final compact = !roomy && h >= 52 * scale;
        if (roomy) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (motif != null) SizedBox(height: 26, child: motif),
              const SizedBox(height: Space.x3),
              ScriptText(label, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (sublabel != null)
                ScriptText(sublabel!, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              if (motif != null) ...[
                SizedBox(height: 22, width: 22, child: FittedBox(child: motif)),
                const SizedBox(width: Space.x2),
              ],
              Expanded(
                child: ScriptText(label, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (compact && sublabel != null)
              ScriptText(sublabel!, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      }),
    );
  }
}

/// Raster art with a scrim and a title along the bottom edge.
class ArtCard extends StatelessWidget {
  const ArtCard({
    super.key,
    required this.asset,
    required this.title,
    this.subtitle,
    this.onTap,
    this.width,
    this.height = 140,
    this.radius = Radii.md,
    this.cacheWidth = 720,
  });

  final String asset;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double radius;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final box = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: context.colors.surfaceSunken,
        boxShadow: context.elevation.rest,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover, cacheWidth: cacheWidth),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            left: Space.x3,
            right: Space.x3,
            bottom: Space.x3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ScriptText(title,
                    style: tt.titleMedium?.copyWith(
                        fontFamily: AppFonts.display, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  ScriptText(subtitle!,
                      style: tt.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return box;
    return PressScale(onTap: onTap, haptic: HapticKind.light, child: box);
  }
}

/// Label + animated value + unit.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.tint,
    this.onTap,
  });

  final String label;
  final num value;
  final String? unit;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      onTap: onTap,
      padding: Insets.cardTight,
      radius: Radii.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Eyebrow(label),
          const SizedBox(height: Space.x1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedCount(value,
                      style: context.type.numeral
                          .copyWith(fontSize: 26, color: tint ?? c.ink)),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: Space.x1),
                Text(unit!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: c.inkFaint)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A verse with its translation, source and action row.
class VerseCard extends StatelessWidget {
  const VerseCard({
    super.key,
    required this.verse,
    this.translation,
    this.transliteration,
    this.source,
    this.eyebrow,
    this.actions = const [],
    this.onTap,
  });

  final String verse;
  final String? translation;
  final String? transliteration;
  final String? source;
  final String? eyebrow;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return SurfaceCard(
      onTap: onTap,
      level: CardLevel.raised,
      borderColor: c.gold.withValues(alpha: .55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null || source != null)
            Row(
              children: [
                if (eyebrow != null) Expanded(child: Eyebrow(eyebrow!)),
                if (source != null)
                  Text(source!,
                      style: tt.bodySmall?.copyWith(color: c.inkFaint)),
              ],
            ),
          const SizedBox(height: Space.x3),
          VerseText(verse),
          if (transliteration != null) ...[
            const SizedBox(height: Space.x2),
            ScriptText(transliteration!,
                style: tt.bodySmall?.copyWith(
                    color: c.inkFaint, fontStyle: FontStyle.italic)),
          ],
          if (translation != null) ...[
            const SizedBox(height: Space.x2),
            ScriptText(translation!,
                style: tt.bodyMedium?.copyWith(color: c.inkSoft)),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: Space.x3),
            Row(children: actions),
          ],
        ],
      ),
    );
  }
}
