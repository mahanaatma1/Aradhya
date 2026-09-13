import 'package:flutter/material.dart';

import '../../shared/widgets/stitched_border.dart';
import '../tokens/tokens.dart';
import 'buttons.dart';

enum NoticeKind { info, success, warning, danger, offline }

/// Inline notice strip (stale index, offline hints, offering windows).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.kind = NoticeKind.info,
    this.action,
    this.onDismiss,
  });

  final String text;
  final NoticeKind kind;
  final Widget? action;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (tint, icon) = switch (kind) {
      NoticeKind.info => (c.info, Icons.info_outline_rounded),
      NoticeKind.success => (c.success, Icons.check_circle_outline_rounded),
      NoticeKind.warning => (c.warning, Icons.warning_amber_rounded),
      NoticeKind.danger => (c.danger, Icons.error_outline_rounded),
      NoticeKind.offline => (c.cosmos, Icons.cloud_off_rounded),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.x3, Space.x3, Space.x2, Space.x3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: context.isDarkTheme ? .2 : .1),
        borderRadius: Radii.rMd,
        border: Border.all(color: tint.withValues(alpha: .35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: Space.x2),
          Expanded(
            child: ScriptText(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.ink)),
          ),
          if (action != null) ...[const SizedBox(width: Space.x2), action!],
          if (onDismiss != null)
            IconCircleButton(
                icon: Icons.close_rounded,
                tooltip: 'Dismiss',
                size: 32,
                onPressed: onDismiss),
        ],
      ),
    );
  }
}

/// Dashed divider (the stitched line survives as a divider only).
class StitchedDivider extends StatelessWidget {
  const StitchedDivider({super.key, this.color, this.indent = 0});
  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent),
      child: CustomPaint(
        size: const Size(double.infinity, 1.5),
        painter: _DashPainter(color ?? context.colors.borderStrong),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 4, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Ornament divider: a small rangoli diamond between two hairlines.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = color ?? context.colors.gold;
    return Row(
      children: [
        Expanded(child: Divider(color: t.withValues(alpha: .5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x3),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 8, height: 8, color: t),
          ),
        ),
        Expanded(child: Divider(color: t.withValues(alpha: .5))),
      ],
    );
  }
}

/// Search input in a pill.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      readOnly: readOnly,
      onTap: onTap,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.inkFaint),
        prefixIcon: Icon(Icons.search_rounded, color: c.inkSoft),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3),
        border: OutlineInputBorder(
            borderRadius: Radii.rPill, borderSide: BorderSide(color: c.border, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: Radii.rPill, borderSide: BorderSide(color: c.border, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: Radii.rPill, borderSide: BorderSide(color: c.accent, width: 2)),
      ),
    );
  }
}

/// Page indicator dots.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index, this.color});
  final int count;
  final int index;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.base,
            curve: Motion.standard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? (color ?? c.accent) : c.border,
              borderRadius: Radii.rPill,
            ),
          ),
      ],
    );
  }
}

/// Avatar for a deity: bundled art with a monogram fallback.
class DeityAvatar extends StatelessWidget {
  const DeityAvatar({super.key, required this.name, this.asset, this.size = 48});
  final String name;
  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: c.goldGradient),
        border: Border.all(color: c.gold, width: 2),
      ),
      child: asset != null
          ? Image.asset(asset!, fit: BoxFit.cover, cacheWidth: (size * 3).round())
          : Center(
              child: Text(name.isEmpty ? '' : name.characters.first,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: size * 0.42,
                      color: Palette.plum900))),
    );
  }
}

/// Floating snackbar in the kit style.
void showAppSnack(BuildContext context, String text,
    {NoticeKind kind = NoticeKind.info, SnackBarAction? action}) {
  final c = context.colors;
  final tint = switch (kind) {
    NoticeKind.success => c.success,
    NoticeKind.warning => c.warning,
    NoticeKind.danger => c.danger,
    _ => c.gold,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: tint, borderRadius: Radii.rPill)),
        const SizedBox(width: Space.x3),
        Expanded(child: ScriptText(text)),
      ]),
      action: action,
    ));
}

/// Keeps the logo's stitched frame available to the kit without importing
/// the shared widget everywhere.
typedef StitchedFrame = StitchedBorderPainter;
