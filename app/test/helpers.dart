import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/app/app.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/services/api_client.dart';
import 'package:phishguard/core/services/connectivity_service.dart';
import 'package:phishguard/core/services/screenshot_reader.dart';
import 'package:phishguard/core/services/share_receiver.dart';

/// The shared example of ../contracts (flutter test runs from app/).
String verdictJson() => File('../contracts/verdict.example.json').readAsStringSync();

Verdict exampleVerdict() => Verdict.fromJson(jsonDecode(verdictJson()) as Map<String, dynamic>);

/// A Dio adapter that answers without network and records what was sent.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  /// Answers 200 with the example verdict to /analyse and 201 to /feedback.
  factory FakeAdapter.ok() => FakeAdapter((options) async => options.path.endsWith('/feedback')
      ? ResponseBody.fromString('{"status": "received"}', 201, headers: _json)
      : ResponseBody.fromString(verdictJson(), 200, headers: _json));

  static final _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  /// JSON bodies sent, in order.
  List<Map<String, dynamic>> get bodies =>
      [for (final r in requests) Map<String, dynamic>.from(r.data as Map)];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient fakeApi(FakeAdapter adapter, {Duration timeout = const Duration(seconds: 8)}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test', responseType: ResponseType.plain))
    ..httpClientAdapter = adapter;
  return ApiClient(dio: dio, timeout: timeout);
}

class FakeConnectivity extends ConnectivityService {
  FakeConnectivity(this.online);
  bool online;

  @override
  Future<bool> isOnline() async => online;
}

class FakeScreenshotReader extends ScreenshotReader {
  const FakeScreenshotReader(this.text);
  final String text;

  @override
  Future<String?> pickImage() async => '/fake/screenshot.png';

  @override
  Future<String> readText(String imagePath) async => text;
}

class FakeClipboard extends ClipboardReader {
  const FakeClipboard(this.text);
  final String? text;

  @override
  Future<String?> read() async => text;
}

/// A share receiver whose "app opened from the share menu" text is [first].
class FakeShareReceiver extends ShareReceiver {
  FakeShareReceiver([this.first]) : super(channel: const MethodChannel('test/share'));
  final SharedText? first;

  @override
  Future<SharedText?> initial() async => first;
}

const setupDone = {'settings.privacyAccepted': true, 'settings.language': 'en'};

/// Starts the whole app with fakes. Animations are turned off (as with the
/// phone's "Remove animations" setting), so pumpAndSettle always ends.
Future<FakeAdapter> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = setupDone,
  FakeAdapter? adapter,
  bool online = true,
  String screenshotText = '',
  String? clipboard,
  SharedText? shared,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final api = adapter ?? FakeAdapter.ok();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      apiClientProvider.overrideWithValue(fakeApi(api)),
      connectivityProvider.overrideWithValue(FakeConnectivity(online)),
      screenshotReaderProvider.overrideWithValue(FakeScreenshotReader(screenshotText)),
      clipboardProvider.overrideWithValue(FakeClipboard(clipboard)),
      shareReceiverProvider.overrideWithValue(FakeShareReceiver(shared)),
    ],
    child: const PhishGuardApp(),
  ));
  // The splash waits on a timer: pumpAndSettle alone would not move the clock.
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle(); // Then home or onboarding.
  return api;
}

/// Lets the fake network calls complete, then the screens settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Completes never: a server that does not answer.
Future<ResponseBody> neverAnswers(RequestOptions _) => Completer<ResponseBody>().future;
