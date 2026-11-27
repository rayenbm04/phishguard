import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishguard/main.dart';
import 'package:phishguard/models/models.dart';
import 'package:phishguard/services/api_client.dart';
import 'package:phishguard/services/connectivity_service.dart';
import 'package:phishguard/services/screenshot_reader.dart';
import 'package:phishguard/ui/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineConnectivity extends ConnectivityService {
  const OnlineConnectivity();

  @override
  Future<bool> isOnline() async => true;
}

class FakeScreenshotReader extends ScreenshotReader {
  const FakeScreenshotReader(this.text);
  final String text;

  @override
  Future<String?> pickImage() async => '/fake/screenshot.png';

  @override
  Future<String> readText(String imagePath) async => text;
}

const setupDone = {'settings.privacyAccepted': true, 'settings.language': 'en'};

AppServices services({String screenshotText = ''}) => AppServices(
      api: ApiClient(
        baseUrl: 'http://test',
        client: MockClient((_) async => http.Response(
              File('../contracts/verdict.example.json').readAsStringSync(),
              200,
            )),
      ),
      connectivity: const OnlineConnectivity(),
      screenshots: FakeScreenshotReader(screenshotText),
    );

void main() {
  testWidgets('first launch: privacy consent, then language (SD4)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();

    // Continue stays disabled until the user agrees.
    final continueButton = find.byKey(const Key('continueButton'));
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.tap(find.byKey(const Key('agreeBox')));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Coller et analyser'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.privacyAccepted'), isTrue);
    expect(prefs.getString('settings.language'), 'fr');
  });

  testWidgets('home screen once the setup is done', (tester) async {
    SharedPreferences.setMockInitialValues(setupDone);
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();
    expect(find.text('PhishGuard'), findsOneWidget);
    expect(find.text('Paste and analyse'), findsOneWidget);
    expect(find.text('Check a screenshot'), findsOneWidget);
  });

  testWidgets('Arabic interface is right to left', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.privacyAccepted': true, 'settings.language': 'ar'});
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();
    expect(find.text('الصق وحلّل'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.text('الصق وحلّل')));
    expect(direction, TextDirection.rtl);
  });

  testWidgets('changing the language in the settings', (tester) async {
    SharedPreferences.setMockInitialValues(setupDone);
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-language-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsOneWidget);
  });

  testWidgets('type a message, check it, see the verdict (SD1)', (tester) async {
    SharedPreferences.setMockInitialValues(setupDone);
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Type a message or link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageField')),
        'Votre colis est bloqué: https://poste-tn.top/pay');
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('checkButton')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Scam'), findsOneWidget);
    expect(find.text('Why'), findsOneWidget);
  });

  testWidgets('screenshot text is shown for confirmation (SD3)', (tester) async {
    SharedPreferences.setMockInitialValues(setupDone);
    await tester.pumpWidget(
        PhishGuardApp(services: services(screenshotText: 'Your parcel is held, pay 2 DT')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screenshotButton')));
    await tester.pumpAndSettle();
    expect(find.text('Text read from the screenshot: check it, then start the check.'),
        findsOneWidget);
    expect(find.text('Your parcel is held, pay 2 DT'), findsOneWidget);
  });

  testWidgets('screenshot without text shows a message', (tester) async {
    SharedPreferences.setMockInitialValues(setupDone);
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screenshotButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No text found in this image'), findsOneWidget);
  });

  testWidgets('rate a verdict, then report it as a scam (SD6)', (tester) async {
    final sent = <Map<String, dynamic>>[];
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{"status": "received"}', 201);
      }),
    );
    final verdict = Verdict.fromJson(
        jsonDecode(File('../contracts/verdict.example.json').readAsStringSync())
            as Map<String, dynamic>);
    await tester.pumpWidget(MaterialApp(
      home: ResultScreen(verdict: verdict, maskedText: 'Payez ici [PHONE]', api: api),
    ));

    // The page scrolls; the comment field has its own scrollable, so name the page's one.
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byKey(const Key('reportScam')), 300, scrollable: page);
    await tester.tap(find.byKey(const Key('star-4')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('sendFeedback')), 100, scrollable: page);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('sendFeedback')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Thanks, your feedback was sent.'), findsOneWidget);
    expect(sent.single['rating'], 4);
    expect(sent.single['maskedText'], isNull); // The text is never sent with a simple rating.

    await tester.scrollUntilVisible(find.byKey(const Key('reportScam')), 100, scrollable: page);
    await tester.tap(find.byKey(const Key('reportScam')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirmReport')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Thanks, your report was sent.'), findsOneWidget);
    expect(sent.last['reportedAsScam'], isTrue);
    expect(sent.last['maskedText'], 'Payez ici [PHONE]');
  });
}
