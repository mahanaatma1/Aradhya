import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/tr.dart';
import '../../ui/components/components.dart';
import '../../ui/motion/motion.dart';
import '../../ui/tokens/tokens.dart';

/// The persistent 5-tab shell (Home · Gyan · Jyotish · Yatra · You): a
/// floating festival pill above the content with a vermilion indicator that
/// springs between tabs. The body extends behind it.
class NavScaffold extends StatelessWidget {
  final StatefulNavigationShell navShell;
  const NavScaffold({super.key, required this.navShell});

  // Hindi labels stay short on purpose: five tabs share ~360 px and
  // Devanagari runs taller and wider than Latin at the same size.
  static const tabs = <NavTab>[
    NavTab(Icons.home_rounded, Icons.home_outlined, Bilingual('Home', 'होम')),
    NavTab(Icons.hub_rounded, Icons.hub_outlined, Bilingual('Gyan', 'ज्ञान')),
    NavTab(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined,
        Bilingual('Jyotish', 'ज्योतिष')),
    NavTab(Icons.place_rounded, Icons.place_outlined, Bilingual('Yatra', 'यात्रा')),
    NavTab(Icons.person_rounded, Icons.person_outline_rounded,
        Bilingual('You', 'आप')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.canvas,
      body: navShell,
      bottomNavigationBar: UtsavNavBar(
        index: navShell.currentIndex,
        tabs: tabs,
        onTap: (i) => navShell.goBranch(i, initialLocation: i == navShell.currentIndex),
      ),
    );
  }
}

class NavTab {
  final IconData filled;
  final IconData outline;
  final Bilingual label;
  const NavTab(this.filled, this.outline, this.label);
}

/// Height the bar occupies above the safe area, for screens that pad their
/// scroll views so the last card clears it.
const double kNavBarClearance = 92;

class UtsavNavBar extends StatelessWidget {
  const UtsavNavBar({
    super.key,
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  final int index;
  final List<NavTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hi = context.isHindi;
    final reduce = MotionScope.of(context).reduce;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Space.x2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x3, 0, Space.x3, Space.x1),
        child: LayoutBuilder(builder: (context, box) {
          const pad = 5.0;
          final w = (box.maxWidth - pad * 2) / tabs.length;
          return Container(
            height: 68,
            padding: const EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: Radii.rXl,
              border: Border.all(color: c.gold, width: 2),
              boxShadow: context.elevation.float,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: reduce ? Duration.zero : Motion.slow,
                  curve: Motion.emphasized,
                  left: index * w,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: c.accentGradient),
                      borderRadius: Radii.rXl,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(
                        child: _NavItem(
                          tab: tabs[i],
                          selected: i == index,
                          hi: hi,
                          onTap: () {
                            if (i != index) PressScale.haptics(HapticKind.selection);
                            onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.hi,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final bool hi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.inkOnAccent : c.inkFaint;
    final label = tab.label.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.enter,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                selected ? tab.filled : tab.outline,
                key: ValueKey(selected),
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.forScript(
                TextStyle(
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: AppFonts.body,
                  fontFamilyFallback: AppFonts.fallback,
                ),
                devanagari: hi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container for the shell's branch navigators: only the current branch is
/// on stage and ticking; the previous one stays mounted (state preserved)
/// but offstage, and the newly selected branch fades in briefly.
class ShellBranches extends StatefulWidget {
  const ShellBranches({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<ShellBranches> createState() => _ShellBranchesState();
}

class _ShellBranchesState extends State<ShellBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    value: 1,
  );

  @override
  void didUpdateWidget(ShellBranches old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MotionScope.of(context).reduce) {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: i == widget.index
                  ? FadeTransition(opacity: _fade, child: widget.children[i])
                  : widget.children[i],
            ),
          ),
      ],
    );
  }
}
