import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'text.dart';

/// Eyebrow + title + optional trailing action. The one section header.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.padding = Insets.section,
    this.accent,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!, color: accent ?? c.accent),
                  const SizedBox(height: Space.x1),
                ],
                ScriptText(
                  title,
                  style: tt.titleLarge?.copyWith(color: c.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Space.x3),
            trailing!,
          ],
        ],
      ),
    );
  }
}
