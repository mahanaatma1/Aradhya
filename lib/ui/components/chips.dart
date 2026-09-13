import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';

/// Selectable filter chip.
class ChoiceChipX extends StatelessWidget {
  const ChoiceChipX({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = tint ?? c.accent;
    final fg = selected ? c.inkOnAccent : c.inkSoft;
    return Semantics(
      selected: selected,
      button: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.standard,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          decoration: BoxDecoration(
            color: selected ? t : c.surfaceSunken,
            borderRadius: Radii.rPill,
            border: Border.all(
                color: selected ? t : c.border, width: selected ? 0 : 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: Space.x1),
              ],
              ScriptText(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling row of chips with page padding.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.padding = Insets.page});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.x2),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Static tinted tag (status, category, verification).
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.tint, this.icon, this.onTap});
  final String label;
  final Color? tint;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = tint ?? c.accent;
    final box = Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Space.x2 + 2),
      decoration: BoxDecoration(
        color: t.withValues(alpha: context.isDarkTheme ? .22 : .14),
        borderRadius: Radii.rPill,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: t),
            const SizedBox(width: 4),
          ],
          ScriptText(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: t, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    if (onTap == null) return box;
    return PressScale(onTap: onTap, child: box);
  }
}

/// Small count bubble.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color});
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color ?? c.accent,
        borderRadius: Radii.rPill,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: c.inkOnAccent,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
