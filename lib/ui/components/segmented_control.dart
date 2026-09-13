import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../tokens/tokens.dart';

/// Pill segmented control with a sliding thumb.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.values,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  final List<T> values;
  final String Function(T) label;
  final IconData? Function(T)? icon;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MotionScope.of(context).reduce;
    final idx = values.indexOf(selected).clamp(0, values.length - 1);
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 8) / values.length;
      return Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: Radii.rPill,
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: reduce ? Duration.zero : Motion.slow,
              curve: Motion.emphasized,
              left: idx * w,
              top: 0,
              bottom: 0,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: Radii.rPill,
                  boxShadow: context.elevation.rest,
                ),
              ),
            ),
            Row(
              children: [
                for (final v in values)
                  Expanded(
                    child: Semantics(
                      selected: v == selected,
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (v != selected) {
                            PressScale.haptics(HapticKind.selection);
                            onChanged(v);
                          }
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.base,
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                  color: v == selected ? c.inkOnAccent : c.inkSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon?.call(v) != null) ...[
                                  Icon(icon!(v),
                                      size: 16,
                                      color: v == selected ? c.inkOnAccent : c.inkSoft),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: ScriptText(label(v),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
