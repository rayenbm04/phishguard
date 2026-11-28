import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/services/share_receiver.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/home/presentation/draft_controller.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

/// The interface language: the user's choice, else the phone's language if
/// PhishGuard speaks it, else French.
final effectiveLanguageProvider = Provider<Language>((ref) {
  final chosen = ref.watch(settingsProvider.select((s) => s.language));
  if (chosen != null) return chosen;
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return switch (device) {
    'ar' => Language.arabic,
    'en' => Language.english,
    _ => Language.french,
  };
});

class PhishGuardApp extends ConsumerStatefulWidget {
  const PhishGuardApp({super.key});

  @override
  ConsumerState<PhishGuardApp> createState() => _PhishGuardAppState();
}

class _PhishGuardAppState extends ConsumerState<PhishGuardApp> {
  StreamSubscription<SharedText>? _shareSub;
  late final GoRouter _router;

  /// Shared before the setup was finished, or during the splash screen.
  SharedText? _pendingShare;

  @override
  void initState() {
    super.initState();
    final receiver = ref.read(shareReceiverProvider);
    _shareSub = receiver.stream.listen(_onShared);
    receiver.initial().then((shared) {
      if (shared != null) _onShared(shared);
    });
    _router = ref.read(routerProvider);
    _router.routerDelegate.addListener(_scheduleDelivery);
  }

  void _onShared(SharedText shared) {
    _pendingShare = shared;
    _scheduleDelivery();
  }

  void _scheduleDelivery() {
    if (_pendingShare == null) return;
    // Not inside the router's own notification: right after it.
    scheduleMicrotask(_deliverShare);
  }

  /// A shared text goes into the home screen's field. It is checked only when
  /// the user taps Check.
  void _deliverShare() {
    final shared = _pendingShare;
    if (shared == null || !mounted) return;
    if (!ref.read(settingsProvider).setupDone) return;
    if (_router.routerDelegate.currentConfiguration.uri.path == AppRoutes.splash) return;
    _pendingShare = null;
    ref.read(draftProvider.notifier).replace(shared.text, sourceApp: shared.sourceApp, shared: true);
    _router.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _router.routerDelegate.removeListener(_scheduleDelivery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final language = ref.watch(effectiveLanguageProvider);
    final arabic = language == Language.arabic;

    return MaterialApp.router(
      title: 'PhishGuard',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(arabic: arabic, easyRead: settings.easyRead),
      darkTheme: AppTheme.dark(arabic: arabic, easyRead: settings.easyRead),
      themeMode: settings.themeMode,
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final system = media.textScaler.scale(16) / 16;
        final scale = (system * settings.effectiveTextScale).clamp(0.85, 2.2).toDouble();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: AppMotion(
            reduced: settings.easyRead || media.disableAnimations,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
