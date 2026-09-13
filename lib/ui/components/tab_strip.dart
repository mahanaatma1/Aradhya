import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'chips.dart';

/// Scrollable pill tabs (readers, detail scroll-spy, kundli sections).
class TabStrip extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.tint,
    this.padding = Insets.page,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ChipRow(
      padding: padding,
      children: [
        for (var i = 0; i < tabs.length; i++)
          ChoiceChipX(
            label: tabs[i],
            selected: i == index,
            tint: tint,
            onTap: () => onChanged(i),
          ),
      ],
    );
  }
}

/// Pins a [TabStrip] under the app bar while scrolling.
class PinnedTabStrip extends SliverPersistentHeaderDelegate {
  PinnedTabStrip({required this.child, this.height = 54});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.colors;
    return Material(
      color: c.canvas,
      elevation: overlaps ? 2 : 0,
      shadowColor: c.scrim,
      child: SizedBox(height: height, child: Center(child: child)),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(PinnedTabStrip old) => old.child != child;
}
