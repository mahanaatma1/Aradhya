import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/brand.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/db/user_database.dart';
import 'core/notifications/panchang_reminders.dart';
import 'core/notifications/reminder_service.dart';
import 'core/providers/app_providers.dart';
import 'core/user/user_prefs.dart';
import 'features/astrology/sweph_ephemeris.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/language_fab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app's handcrafted-journal layout is designed for portrait only.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  final prefs = await SharedPreferences.getInstance();
  gOnboarded = prefs.getBool(PrefKeys.onboarded) ?? false;

  // Writable store for user-authored data (bookmarks, journal, sadhana
  // history). Opening it also runs the one-time SharedPreferences import.
  // A failure here must not block launch: every controller can still fall back
  // to prefs, so the app degrades rather than refusing to start.
  UserDatabase? userDb;
  try {
    userDb = await UserDatabase.open(prefs: prefs);
  } catch (e) {
    debugPrint('main: user database unavailable ($e)');
  }

  // Android drops scheduled alarms on reboot and on app update, so every
  // enabled reminder is re-armed at startup. Without this, reminders quietly
  // stop working after a phone restart.
  if (userDb != null) {
    final hindi = prefs.getString('locale') == 'hi';
    unawaited(ReminderService.instance.rescheduleAll(userDb, hindi: hindi));
    // Auto panchang reminders keep a rolling 60-day window of Ekadashi /
    // Purnima / Amavasya queued. Re-armed here so the window never runs dry
    // even if the user never opens the panchang screen. No-op when the
    // single toggle is off.
    unawaited(PanchangReminders.instance.rescheduleWindow(hindi: hindi));
  }

  // High-precision Swiss Ephemeris for the Kundli (falls back to the built-in
  // approximation if the native library can't load).
  await initSwephEphemeris();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        if (userDb != null) userDatabaseProvider.overrideWithValue(userDb),
      ],
      child: const DivyaVaaniApp(),
    ),
  );
}

/// Hosts the global floating language button and hides it on the splash and
/// onboarding routes. Route changes are applied in a post-frame callback so the
/// widget never marks itself dirty *during* a build (which would assert).
class _LangFabOverlay extends StatefulWidget {
  const _LangFabOverlay();

  @override
  State<_LangFabOverlay> createState() => _LangFabOverlayState();
}

class _LangFabOverlayState extends State<_LangFabOverlay> {
  static const _fab = 46.0;
  late String _path = _currentPath();

  /// Top-left offset the user has dragged the button to (null = default corner).
  Offset? _pos;

  String _currentPath() =>
      appRouter.routerDelegate.currentConfiguration.uri.path;

  void _onRouteChanged() {
    final next = _currentPath();
    if (next == _path) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && next != _path) setState(() => _path = next);
    });
  }

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hide = _path == '/splash' || _path.startsWith('/onboarding');
    if (hide) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final size = media.size;
    // Keep the button within the safe area.
    final minX = 8.0, maxX = size.width - _fab - 8;
    final minY = media.padding.top + 8;
    final maxY = size.height - _fab - media.padding.bottom - 8;
    // Default resting spot: bottom-right, above the nav bar.
    final def = Offset(maxX - 6, maxY - 88);
    final raw = _pos ?? def;
    final pos = Offset(raw.dx.clamp(minX, maxX), raw.dy.clamp(minY, maxY));

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          final cur = _pos ?? def;
          setState(() {
            _pos = Offset(
              (cur.dx + d.delta.dx).clamp(minX, maxX),
              (cur.dy + d.delta.dy).clamp(minY, maxY),
            );
          });
        },
        child: const LanguageFab(),
      ),
    );
  }
}

class DivyaVaaniApp extends ConsumerStatefulWidget {
  const DivyaVaaniApp({super.key});

  @override
  ConsumerState<DivyaVaaniApp> createState() => _DivyaVaaniAppState();
}

class _DivyaVaaniAppState extends ConsumerState<DivyaVaaniApp> {
  @override
  void initState() {
    super.initState();
    // A cold start from tapping a notification doesn't fire
    // `onDidReceiveNotificationResponse` (that's only for a warm/backgrounded
    // app) — the launch details carry the payload instead, and this is the
    // first point the router exists to act on it. Runs after the first
    // frame so it navigates on top of the already-resolved initial route
    // (onboarding vs. home) rather than racing it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReminderService.navigateTo(
          ReminderService.instance.takePendingLaunchPayload());
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: Brand.name,
      debugShowCheckedModeBanner: false,
      // The cream palette is the app's identity, so light is the default and
      // the system is not followed unless the user asks for it. The dark ramp
      // is a deliberate warm espresso, not an inverted paper.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.localizationsDelegates,
      routerConfig: appRouter,
      // A global floating language switch on top of every content screen —
      // every screen is bilingual. Hidden on the splash & onboarding (which
      // have their own language step).
      builder: (context, child) => Stack(
        children: [
          ?child,
          const _LangFabOverlay(),
        ],
      ),
    );
  }
}
