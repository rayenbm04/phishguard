import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/services/share_receiver.dart';
import 'package:phishguard/features/history/data/history_repository.dart';
import 'package:phishguard/features/results/presentation/result_screen.dart';
import 'package:phishguard/l10n/app_localizations.dart';

import 'helpers.dart';

void main() {
  testWidgets('first launch: intro, privacy consent, then language (SD4)', (tester) async {
    await pumpApp(tester, prefs: {});

    await tester.tap(find.byKey(const Key('introContinue')));
    await tester.pumpAndSettle();

    // Continue stays disabled until the user agrees.
    final continueButton = find.byKey(const Key('continueButton'));
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.tap(find.byKey(const Key('agreeBox')));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // Choosing French previews the screen in French before confirming.
    await tester.tap(find.byKey(const Key('language-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez votre langue'), findsOneWidget);
    await tester.tap(find.byKey(const Key('startButton')));
    await tester.pumpAndSettle();
    expect(find.text('Vérifier ce message'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.privacyAccepted'), isTrue);
    expect(prefs.getString('settings.language'), 'fr');
  });

  testWidgets('home screen once the setup is done', (tester) async {
    await pumpApp(tester);
    expect(find.text('Got a strange message?'), findsOneWidget);
    expect(find.byKey(const Key('pasteButton')), findsOneWidget);
    expect(find.byKey(const Key('screenshotButton')), findsOneWidget);
    // Nothing to check yet: the button waits for a message.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('checkButton'))).onPressed, isNull);
  });

  testWidgets('Arabic interface is right to left', (tester) async {
    await pumpApp(tester, prefs: {'settings.privacyAccepted': true, 'settings.language': 'ar'});
    final button = find.text('افحص هذه الرسالة');
    expect(button, findsOneWidget);
    expect(Directionality.of(tester.element(button)), TextDirection.rtl);
  });

  testWidgets('changing the language in the settings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-language-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsWidgets);
  });

  testWidgets('dark theme from the settings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Settings').first)).brightness, Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.themeMode'), 'dark');
  });

  testWidgets('type a message, check it, see the verdict (SD1)', (tester) async {
    final api = await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('messageField')),
        'Votre colis est bloqué, appelez le 98 123 456: https://poste-tn.top/pay');
    await tester.pump();
    expect(find.textContaining('1 personal number will be hidden'), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkButton')));
    await settle(tester);

    expect(find.byKey(const Key('verdict-FRAUDULENT')), findsOneWidget);
    expect(find.text('Scam'), findsWidgets);
    final message = api.bodies.single['message'] as Map<String, dynamic>;
    expect(message['text'], contains('[PHONE]'));
    expect(message['text'], isNot(contains('98 123 456')));
    expect(api.bodies.single['replyLanguage'], 'en');

    final page = find.descendant(of: find.byKey(const Key('resultList')), matching: find.byType(Scrollable)).first;
    // Scroll to the reason itself: the "Why" heading can be visible while the card is not built yet.
    await tester.scrollUntilVisible(find.text('The link is listed as phishing.'), 200, scrollable: page);
    expect(find.text('Why'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('reason-1')));
    await tester.pumpAndSettle();

    // The evidence opens on tap.
    await tester.tap(find.byKey(const Key('reason-1')));
    await tester.pumpAndSettle();
    expect(find.text('amende-tn.info is flagged as social engineering'), findsOneWidget);
  });

  testWidgets('offline: no request, a clear message and a retry button', (tester) async {
    final api = await pumpApp(tester, online: false);
    await tester.enterText(find.byKey(const Key('messageField')), 'Hello');
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkButton')));
    await settle(tester);
    expect(find.byKey(const Key('failure-offline')), findsOneWidget);
    expect(find.byKey(const Key('retryButton')), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('paste fills the field, nothing is checked yet', (tester) async {
    final api = await pumpApp(tester, clipboard: 'Félicitations, vous avez gagné !');
    await tester.tap(find.byKey(const Key('pasteButton')));
    await tester.pumpAndSettle();
    expect(find.text('Félicitations, vous avez gagné !'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a shared text waits in the field for the user to tap Check', (tester) async {
    final api = await pumpApp(
      tester,
      shared: const SharedText(text: 'Votre carte est bloquée', sourceApp: 'com.whatsapp'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Votre carte est bloquée'), findsOneWidget);
    expect(find.text('Shared from WhatsApp'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('screenshot text is shown for confirmation (SD3)', (tester) async {
    await pumpApp(tester, screenshotText: 'Your parcel is held, pay 2 DT');
    await tester.tap(find.byKey(const Key('screenshotButton')));
    await tester.pumpAndSettle();
    expect(find.text('Text read from the screenshot: check it, then start the check.'), findsOneWidget);
    expect(find.text('Your parcel is held, pay 2 DT'), findsOneWidget);
    expect(find.byKey(const Key('checkScreenshotText')), findsOneWidget);
  });

  testWidgets('screenshot without text shows a message', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('screenshotButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No text found in this image'), findsOneWidget);
  });

  testWidgets('history: search, filter, clear with confirmation', (tester) async {
    final verdict = exampleVerdict();
    final entries = [
      HistoryEntry(maskedText: 'Paiement amende [PHONE]', verdict: verdict),
      HistoryEntry(maskedText: 'Votre colis attend', verdict: verdict, sourceApp: 'com.whatsapp'),
    ];
    await pumpApp(tester, prefs: {
      ...setupDone,
      'history.v1': [for (final e in entries) jsonEncode(e.toJson())],
    });
    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Votre colis attend'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('historySearch')), 'amende');
    await tester.pumpAndSettle();
    expect(find.text('Votre colis attend'), findsNothing);
    expect(find.textContaining('Paiement amende'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearHistory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmClear')));
    await tester.pumpAndSettle();
    expect(find.text('No checks yet'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('history.v1'), isNull);
  });

  testWidgets('rate a verdict, then report it as a scam (SD6)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(setupDone);
    final prefs = await SharedPreferences.getInstance();
    final api = FakeAdapter.ok();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(fakeApi(api)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ResultScreen(
          args: ResultArgs(verdict: exampleVerdict(), maskedText: 'Payez ici [PHONE]'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The page scrolls; the comment field has its own scrollable, so name the page's one.
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.byKey(const Key('reportScam')), 300, scrollable: page);
    await tester.tap(find.byKey(const Key('star-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('sendFeedback')), 100, scrollable: page);
    await tester.tap(find.byKey(const Key('sendFeedback')));
    await settle(tester);
    expect(find.text('Thanks, your feedback was sent.'), findsOneWidget);
    expect(api.requests.single.path, '/feedback');
    expect(api.bodies.single['rating'], 4);
    expect(api.bodies.single['maskedText'], isNull); // Never sent with a simple rating.

    await tester.scrollUntilVisible(find.byKey(const Key('reportScam')), 100, scrollable: page);
    await tester.tap(find.byKey(const Key('reportScam')));
    await tester.pumpAndSettle();
    // The dialog shows what will be sent.
    expect(find.text('What will be sent'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmReport')));
    await settle(tester);
    expect(find.text('Thanks, your report was sent.'), findsOneWidget);
    expect(api.bodies.last['reportedAsScam'], isTrue);
    expect(api.bodies.last['maskedText'], 'Payez ici [PHONE]');
  });
}
