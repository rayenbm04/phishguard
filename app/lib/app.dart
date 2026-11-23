import 'dart:async';

import 'package:flutter/material.dart';

import 'services/api_client.dart';
import 'services/connectivity_service.dart';
import 'services/history_repository.dart';
import 'services/share_receiver.dart';
import 'ui/check_screen.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

/// Everything the screens need, created once (and replaced by fakes in tests).
class AppServices {
  AppServices({
    ApiClient? api,
    this.connectivity = const ConnectivityService(),
    HistoryRepository? history,
    ShareReceiver? share,
  })  : api = api ?? ApiClient(),
        history = history ?? HistoryRepository(),
        share = share ?? ShareReceiver();

  final ApiClient api;
  final ConnectivityService connectivity;
  final HistoryRepository history;
  final ShareReceiver share;
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

  @override
  void initState() {
    super.initState();
    _shareSub = _services.share.stream.listen(_openShared);
    _services.share.initial().then((shared) {
      if (shared != null) _openShared(shared);
    });
  }

  void _openShared(SharedText shared) {
    final nav = _navigator.currentState;
    if (nav == null) return;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishGuard',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      theme: Pg.theme(),
      home: HomeScreen(services: _services),
    );
  }
}
