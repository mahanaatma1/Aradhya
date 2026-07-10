import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/stitched_border.dart';

/// The persistent 5-tab bottom navigation shell
/// (Home · Rashifal · Astrology · Yatra · You).
///
/// Custom bar (not Material's NavigationBar): no pill indicator — the selected
/// tab is shown by tinting its icon + label and framing the icon with the
/// signature dashed "stitched" border (same motif as the app logo).
class NavScaffold extends StatelessWidget {
  final StatefulNavigationShell navShell;
  const NavScaffold({super.key, required this.navShell});

  static const _tabs = <_Tab>[
    _Tab(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _Tab(Icons.nightlight_round, Icons.nightlight_outlined, 'Rashifal'),
    _Tab(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Astrology'),
    _Tab(Icons.place_rounded, Icons.place_outlined, 'Yatra'),
    _Tab(Icons.person_rounded, Icons.person_outline_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navShell,
      bottomNavigationBar: Material(
        color: scheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: _tabs[i],
                        selected: navShell.currentIndex == i,
                        color: scheme.primary,
                        muted: scheme.onSurface.withValues(alpha: 0.5),
                        onTap: () => navShell.goBranch(
                          i,
                          initialLocation: i == navShell.currentIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final Color color;
  final Color muted;
  final VoidCallback onTap;
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.color,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? color : muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The icon is framed by the stitched border when selected (same
          // dashed motif as the app logo).
          SizedBox(
            width: 38,
            height: 34,
            child: CustomPaint(
              foregroundPainter: selected
                  ? StitchedBorderPainter(
                      color: color,
                      inset: 2,
                      radius: 8,
                      strokeWidth: 1.2,
                      dash: 3.5,
                      gap: 3,
                    )
                  : null,
              child: Center(
                child: Icon(selected ? tab.filled : tab.outline,
                    size: 22, color: c),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  final IconData filled;
  final IconData outline;
  final String label;
  const _Tab(this.filled, this.outline, this.label);
}
