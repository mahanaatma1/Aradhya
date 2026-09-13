import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';

enum ButtonSize { sm, md, lg }

double _height(ButtonSize s) => switch (s) {
      ButtonSize.sm => 40,
      ButtonSize.md => 48,
      ButtonSize.lg => 56,
    };

Widget _label(BuildContext context, String label, IconData? icon, bool loading,
    Color color, ButtonSize size) {
  final tt = Theme.of(context).textTheme;
  final style = (size == ButtonSize.lg ? tt.titleMedium : tt.labelLarge)
      ?.copyWith(color: color, fontWeight: FontWeight.w600);
  if (loading) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
    );
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: Space.x2),
      ],
      Flexible(
        child: ScriptText(label,
            style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

/// Filled vermilion pill — the one primary action on a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.md,
    this.loading = false,
    this.expand = false,
    this.gradient = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool loading;
  final bool expand;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !loading;
    final box = Container(
      height: _height(size),
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: Space.x5),
      decoration: BoxDecoration(
        gradient: gradient && enabled
            ? LinearGradient(colors: c.accentGradient)
            : null,
        color: enabled ? (gradient ? null : c.accent) : c.surfaceSunken,
        borderRadius: Radii.rPill,
        boxShadow: enabled ? context.elevation.rest : const [],
      ),
      alignment: Alignment.center,
      child: _label(context, label, icon, loading,
          enabled ? c.inkOnAccent : c.inkFaint, size),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressScale(
        enabled: enabled,
        onTap: onPressed,
        haptic: HapticKind.light,
        child: box,
      ),
    );
  }
}

/// Outlined pill for the secondary action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.md,
    this.expand = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final tint = color ?? c.accent;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressScale(
        enabled: enabled,
        onTap: onPressed,
        child: Container(
          height: _height(size),
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: Space.x5),
          decoration: BoxDecoration(
            borderRadius: Radii.rPill,
            border: Border.all(
                color: enabled ? tint.withValues(alpha: .6) : c.border,
                width: 2),
            color: c.surface,
          ),
          alignment: Alignment.center,
          child: _label(
              context, label, icon, false, enabled ? tint : c.inkFaint, size),
        ),
      ),
    );
  }
}

/// Text-only action.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      enabled: onPressed != null,
      onTap: onPressed,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: Space.x3),
        alignment: Alignment.center,
        child: _label(context, label, icon, false,
            onPressed == null ? c.inkFaint : (color ?? c.accent), ButtonSize.md),
      ),
    );
  }
}

/// Round icon button, 44 px hit target.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 44,
    this.color,
    this.background,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? background;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: PressScale(
          enabled: onPressed != null,
          onTap: onPressed,
          scale: 0.9,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background ?? (filled ? c.accent : c.surfaceSunken),
              border: filled ? null : Border.all(color: c.border, width: 1.5),
            ),
            child: Icon(icon,
                size: size * 0.5,
                color: color ?? (filled ? c.inkOnAccent : c.inkSoft)),
          ),
        ),
      ),
    );
  }
}

/// Small pill with icon + label, used inside cards.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.background,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      enabled: onPressed != null,
      onTap: onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: Space.x3),
        decoration: BoxDecoration(
          color: background ?? c.surfaceSunken,
          borderRadius: Radii.rPill,
        ),
        alignment: Alignment.center,
        child:
            _label(context, label, icon, false, color ?? c.inkSoft, ButtonSize.sm),
      ),
    );
  }
}
