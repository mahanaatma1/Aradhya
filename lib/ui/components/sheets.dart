import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'buttons.dart';

/// The one bottom-sheet style: drag handle, title row, safe area, scrollable.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool scrollable = false,
  bool isDismissible = true,
  double? maxHeightFraction,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * (maxHeightFraction ?? 0.9),
    ),
    shape: const RoundedRectangleBorder(borderRadius: Radii.rSheet),
    builder: (ctx) {
      final body = Padding(
        padding: EdgeInsets.fromLTRB(
            Space.x4, 0, Space.x4, Space.x4 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: builder(ctx),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) AppSheetHeader(title: title),
          if (scrollable) Flexible(child: SingleChildScrollView(child: body)) else body,
        ],
      );
    },
  );
}

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x2, Space.x3),
      child: Row(
        children: [
          Expanded(
            child: ScriptText(title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          trailing ??
              IconCircleButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                size: 40,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        ],
      ),
    );
  }
}

/// Yes/no confirmation. Returns true when confirmed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? body,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: ScriptText(title),
      content: body == null ? null : ScriptText(body),
      actionsPadding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x4),
      actions: [
        GhostButton(label: cancelLabel, onPressed: () => Navigator.pop(ctx, false)),
        PrimaryButton(
          label: confirmLabel,
          size: ButtonSize.sm,
          gradient: !destructive,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
      backgroundColor: c.surface,
    ),
  );
  return result ?? false;
}
