import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishguard/main.dart';
import 'package:phishguard/services/api_client.dart';
import 'package:phishguard/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineConnectivity extends ConnectivityService {
  const OnlineConnectivity();

  @override
  Future<bool> isOnline() async => true;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AppServices services() => AppServices(
        api: ApiClient(
          baseUrl: 'http://test',
          client: MockClient((_) async => http.Response(
                File('../contracts/verdict.example.json').readAsStringSync(),
                200,
              )),
        ),
        connectivity: const OnlineConnectivity(),
      );

  testWidgets('shows the PhishGuard home screen', (tester) async {
    await tester.pumpWidget(PhishGuardApp(services: services()));
    await tester.pumpAndSettle();
    expect(find.text('PhishGuard'), findsOneWidget);
    expect(find.text('Paste and analyse'), findsOneWidget);
    expect(find.text('Type a message or link'), findsOneWidget);
  });

  testWidgets('type a message, check it, see the verdict', (tester) async {
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
}
