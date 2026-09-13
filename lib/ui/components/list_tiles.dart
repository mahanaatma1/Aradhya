import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';

/// Row with leading, title/subtitle and trailing; 56 px minimum.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    final row = Padding(
      padding: padding ??
          EdgeInsets.symmetric(
              horizontal: Space.x4, vertical: dense ? Space.x2 : Space.x3),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme.merge(
                data: IconThemeData(color: c.inkSoft), child: leading!),
            const SizedBox(width: Space.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ScriptText(title,
                    style: tt.titleMedium?.copyWith(color: c.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  ScriptText(subtitle!,
                      style: tt.bodySmall?.copyWith(color: c.inkFaint),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Space.x2),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return PressScale(onTap: onTap, scale: 0.985, child: row);
  }
}

/// Navigation row with a chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        onTap: onTap,
        trailing:
            Icon(Icons.chevron_right_rounded, color: context.colors.inkFaint),
      );
}

/// Label + switch.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => AppListTile(
        title: label,
        subtitle: subtitle,
        leading: leading,
        onTap: () => onChanged(!value),
        trailing: Switch.adaptive(value: value, onChanged: onChanged),
      );
}
