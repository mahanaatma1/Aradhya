import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../tokens/tokens.dart';

/// Round back glyph used by every top bar.
class BackGlyph extends StatelessWidget {
  const BackGlyph({super.key, this.color, this.onDark = false});
  final Color? color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canPop = Navigator.of(context).canPop();
    if (!canPop) return const SizedBox(width: Space.x2);
    return Semantics(
      button: true,
      label: 'Back',
      child: PressScale(
        scale: 0.9,
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: Space.x2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onDark ? Colors.white.withValues(alpha: .12) : c.surfaceSunken,
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: 22, color: color ?? (onDark ? c.inkOnDeep : c.ink)),
        ),
      ),
    );
  }
}

/// Compact pinned top bar.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.transparent = false,
    this.pinned = true,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool transparent;
  final bool pinned;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return SliverAppBar(
      pinned: pinned,
      floating: !pinned,
      snap: !pinned,
      backgroundColor: transparent ? Colors.transparent : c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: leading ?? const BackGlyph(),
      titleSpacing: 0,
      centerTitle: centerTitle,
      title: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ScriptText(title,
              style: tt.titleLarge?.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            ScriptText(subtitle!,
                style: tt.bodySmall?.copyWith(color: c.inkFaint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: [...actions, const SizedBox(width: Space.x2)],
    );
  }
}

/// Collapsing hero header: art layers behind, title that fades in as it
/// collapses. [hero] is drawn full-bleed; [overlay] sits on top of it.
class SliverAppHeader extends StatelessWidget {
  const SliverAppHeader({
    super.key,
    required this.title,
    required this.hero,
    this.overlay,
    this.expandedHeight = 280,
    this.actions = const [],
    this.leading,
    this.onDark = true,
  });

  final String title;
  final Widget hero;
  final Widget? overlay;
  final double expandedHeight;
  final List<Widget> actions;
  final Widget? leading;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tt = Theme.of(context).textTheme;
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: onDark ? c.canvasDeep : c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: leading ?? BackGlyph(onDark: onDark),
      actions: [...actions, const SizedBox(width: Space.x2)],
      flexibleSpace: LayoutBuilder(builder: (context, box) {
        final collapsed = (box.maxHeight - kToolbarHeight - MediaQuery.paddingOf(context).top)
            .clamp(0, expandedHeight - kToolbarHeight);
        final t = 1 - (collapsed / (expandedHeight - kToolbarHeight));
        return Stack(
          fit: StackFit.expand,
          children: [
            hero,
            ?overlay,
            Positioned(
              left: 56,
              right: Space.x4,
              top: MediaQuery.paddingOf(context).top,
              height: kToolbarHeight,
              child: Opacity(
                opacity: Curves.easeIn.transform(t.clamp(0, 1).toDouble()),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ScriptText(title,
                      style: tt.titleLarge?.copyWith(color: onDark ? c.inkOnDeep : c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// The screen frame: a [CustomScrollView] with a shared controller (for
/// parallax), an optional bottom bar, and immersive/deep variants.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.slivers,
    this.controller,
    this.bottom,
    this.immersive = false,
    this.backgroundColor,
    this.floatingAction,
    this.bottomPadding = 96,
  });

  final List<Widget> slivers;
  final ScrollController? controller;
  final Widget? bottom;
  final bool immersive;
  final Color? backgroundColor;
  final Widget? floatingAction;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: backgroundColor ?? (immersive ? c.canvasDeep : c.canvas),
      extendBody: true,
      bottomNavigationBar: bottom,
      floatingActionButton: floatingAction,
      body: CustomScrollView(
        controller: controller,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          ...slivers,
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}

/// Convenience: a padded list of boxes as one sliver.
class SliverPage extends StatelessWidget {
  const SliverPage({super.key, required this.children, this.padding = Insets.page, this.gap = Space.x3});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
        separatorBuilder: (_, _) => SizedBox(height: gap),
      ),
    );
  }
}
