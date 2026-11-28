import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/shell.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/analysis/presentation/analysis_screen.dart';
import 'package:phishguard/features/history/presentation/history_screen.dart';
import 'package:phishguard/features/home/presentation/home_screen.dart';
import 'package:phishguard/features/onboarding/presentation/intro_screen.dart';
import 'package:phishguard/features/onboarding/presentation/language_screen.dart';
import 'package:phishguard/features/onboarding/presentation/privacy_screen.dart';
import 'package:phishguard/features/onboarding/presentation/splash_screen.dart';
import 'package:phishguard/features/results/presentation/result_screen.dart';
import 'package:phishguard/features/screenshot/presentation/screenshot_screen.dart';
import 'package:phishguard/features/settings/presentation/about_screen.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';
import 'package:phishguard/features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const privacy = '/privacy';
  static const language = '/language';
  static const home = '/home';
  static const history = '/history';
  static const settings = '/settings';
  static const analysis = '/analysis';
  static const result = '/result';
  static const screenshot = '/screenshot';
  static const about = '/about';

  static const onboarding = {welcome, privacy, language};
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // The router is created once; a change of setup state only re-runs redirect.
  final setupDone = ValueNotifier<bool>(ref.read(settingsProvider).setupDone);
  ref.listen<bool>(settingsProvider.select((s) => s.setupDone), (_, next) => setupDone.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: setupDone,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.splash) return null;
      final onboarding = AppRoutes.onboarding.contains(location);
      if (!setupDone.value && !onboarding) return AppRoutes.welcome;
      if (setupDone.value && onboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const IntroScreen()),
      GoRoute(path: AppRoutes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.language, builder: (_, _) => const LanguageScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.history, builder: (_, _) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
          ]),
        ],
      ),
      // Full-screen routes, above the navigation bar.
      GoRoute(
        path: AppRoutes.analysis,
        redirect: (_, state) => state.extra is CheckRequest ? null : AppRoutes.home,
        builder: (_, state) => AnalysisScreen(request: state.extra! as CheckRequest),
      ),
      GoRoute(
        path: AppRoutes.result,
        redirect: (_, state) => state.extra is ResultArgs ? null : AppRoutes.home,
        builder: (_, state) => ResultScreen(args: state.extra! as ResultArgs),
      ),
      GoRoute(path: AppRoutes.screenshot, builder: (_, _) => const ScreenshotScreen()),
      GoRoute(path: AppRoutes.about, builder: (_, _) => const AboutScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    setupDone.dispose();
  });
  return router;
});
