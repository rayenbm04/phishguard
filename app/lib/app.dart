import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'services/api_client.dart';
import 'services/app_settings.dart';
import 'services/connectivity_service.dart';
import 'services/history_repository.dart';
import 'services/screenshot_reader.dart';
import 'services/share_receiver.dart';
import 'ui/check_screen.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/theme.dart';

/// Everything the screens need, created once (and replaced by fakes in tests).
class AppServices {
  AppServices({
    ApiClient? api,
    this.connectivity = const ConnectivityService(),
    HistoryRepository? history,
    ShareReceiver? share,
    AppSettings? settings,
    this.screenshots = const ScreenshotReader(),
  })  : api = api ?? ApiClient(),
        history = history ?? HistoryRepository(),
        share = share ?? ShareReceiver(),
        settings = settings ?? AppSettings();

  final ApiClient api;
  final ConnectivityService connectivity;
  final HistoryRepository history;
  final ShareReceiver share;
  final AppSettings settings;
  final ScreenshotReader screenshots;
}

class PhishGuardApp extends StatefulWidget {
  const PhishGuardApp({super.key, this.services});

  final AppServices? services;

  @override
  State<PhishGuardApp> createState() => _PhishGuardAppState();
}

class _PhishGuardAppState extends State<PhishGuardApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final AppServices _services = widget.services ?? AppServices();
  StreamSubscription<SharedText>? _shareSub;
  SharedText? _pendingShare; // Shared before the first-time setup was finished.

  AppSettings get _settings => _services.settings;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _settings.load();
    _shareSub = _services.share.stream.listen(_openShared);
    _services.share.initial().then((shared) {
      if (shared != null) _openShared(shared);
    });
  }

  void _onSettingsChanged() {
    setState(() {});
    final pending = _pendingShare;
    if (_settings.setupDone && pending != null) {
      _pendingShare = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openShared(pending));
    }
  }

  void _openShared(SharedText shared) {
    final nav = _navigator.currentState;
    if (nav == null || !_settings.setupDone) {
      _pendingShare = shared; // Opened once the user has accepted the privacy terms.
      return;
    }
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute<void>(
      builder: (_) => CheckScreen(
        services: _services,
        initialText: shared.text,
        sourceApp: shared.sourceApp,
        fromShare: true,
      ),
    ));
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = _settings.language;
    return MaterialApp(
      title: 'PhishGuard',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      theme: Pg.theme(),
      // Before a language is chosen, the phone's language is used (French by default).
      locale: language == null ? null : Locale(language.code),
      supportedLocales: [for (final l in S.supported) Locale(l.code)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (device, supported) =>
          supported.firstWhere((l) => l.languageCode == device?.languageCode,
              orElse: () => const Locale('fr')),
      home: !_settings.loaded
          ? const Scaffold(body: SizedBox.shrink())
          : _settings.setupDone
              ? HomeScreen(services: _services)
              : OnboardingScreen(settings: _settings),
    );
  }
}
