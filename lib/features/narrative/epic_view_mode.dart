import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../core/user/user_prefs.dart';

/// How an epic is presented (SC-12).
///
/// Neither is the "real" one. Story mode is the kanda/parva books with their
/// arcs; Timeline keeps the vertical path that shipped first, which is still
/// the better way to see the whole sweep in one scroll. The choice is
/// remembered because it is a reading preference, not a mode you toggle
/// mid-thought.
enum EpicViewMode { story, timeline }

class EpicViewModeController extends StateNotifier<EpicViewMode> {
  EpicViewModeController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static EpicViewMode _read(SharedPreferences p) =>
      switch (p.getString(PrefKeys.epicViewMode)) {
        'timeline' => EpicViewMode.timeline,
        // Story is the default: the epics are books before they are diagrams,
        // and a first-time reader lands on the one that says so.
        _ => EpicViewMode.story,
      };

  Future<void> set(EpicViewMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(PrefKeys.epicViewMode, mode.name);
  }
}

final epicViewModeProvider =
    StateNotifierProvider<EpicViewModeController, EpicViewMode>(
        (ref) => EpicViewModeController(ref.watch(sharedPrefsProvider)));

/// The two-way switch shown at the top of both epics.
///
/// A segmented control rather than a tab bar: tabs would imply two sets of
/// content, and these are two views of one.
class EpicModeToggle extends ConsumerWidget {
  final bool hindi;
  const EpicModeToggle({super.key, required this.hindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(epicViewModeProvider);
    final scheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF8A6A4F);

    Widget half(EpicViewMode value, String label, IconData icon) {
      final on = mode == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () =>
                ref.read(epicViewModeProvider.notifier).set(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              // 40 high plus the Row's own padding keeps the tap target at the
              // 48 dp minimum even when the Hindi label wraps to one line.
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: on
                      ? accent.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 16,
                      color: on
                          ? accent
                          : scheme.onSurface.withValues(alpha: 0.55)),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12.5,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: on
                            ? accent
                            : scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.outline.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          half(EpicViewMode.story, hindi ? 'कथा' : 'Story',
              Icons.auto_stories_rounded),
          const SizedBox(width: 4),
          half(EpicViewMode.timeline, hindi ? 'क्रम' : 'Timeline',
              Icons.timeline_rounded),
        ],
      ),
    );
  }
}
