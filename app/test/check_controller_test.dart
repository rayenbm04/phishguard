import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishguard/controllers/check_controller.dart';
import 'package:phishguard/models/models.dart';
import 'package:phishguard/services/api_client.dart';
import 'package:phishguard/services/connectivity_service.dart';
import 'package:phishguard/services/history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConnectivity extends ConnectivityService {
  FakeConnectivity(this.online);
  bool online;

  @override
  Future<bool> isOnline() async => online;
}

String verdictJson() => File('../contracts/verdict.example.json').readAsStringSync();

void main() {
  late List<Map<String, dynamic>> sent;
  late HistoryRepository history;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent = [];
    history = HistoryRepository();
  });

  CheckController controller({required http.Client client, bool online = true}) =>
      CheckController(
        api: ApiClient(client: client, baseUrl: 'http://test', timeout: const Duration(milliseconds: 200)),
        connectivity: FakeConnectivity(online),
        history: history,
      );

  MockClient okServer() => MockClient((request) async {
        sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(verdictJson(), 200, headers: {'content-type': 'application/json'});
      });

  test('online: masks, sends, gets the verdict and saves it (SD1)', () async {
    final c = controller(client: okServer());
    await c.startCheck('Votre colis est bloqué, appelez le 98 123 456', sourceApp: 'com.whatsapp');

    expect(c.state.status, CheckStatus.done);
    expect(c.state.verdict!.level, VerdictLevel.fraudulent);

    final message = sent.single['message'] as Map<String, dynamic>;
    expect(message['text'], 'Votre colis est bloqué, appelez le [PHONE]');
    expect(message['maskedItems'], 1);
    expect(message['language'], 'fr');
    expect(sent.single['sourceApp'], 'com.whatsapp');

    final saved = await history.all();
    expect(saved.single.maskedText, contains('[PHONE]'));
    expect(saved.single.maskedText, isNot(contains('98 123 456')));
  });

  test('offline: fails without calling the server (SD5)', () async {
    final c = controller(client: okServer(), online: false);
    await c.startCheck('Hello');
    expect(c.state.status, CheckStatus.failed);
    expect(c.state.failure, CheckFailure.offline);
    expect(sent, isEmpty);
  });

  test('server error or timeout: FAILED (server unreachable)', () async {
    final error = controller(client: MockClient((_) async => http.Response('boom', 500)));
    await error.startCheck('Hello');
    expect(error.state.failure, CheckFailure.serverUnreachable);

    final slow = controller(
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await slow.startCheck('Hello');
    expect(slow.state.failure, CheckFailure.serverUnreachable);
    expect(await history.all(), isEmpty);
  });

  test('empty message is refused', () async {
    final c = controller(client: okServer());
    await c.startCheck('   ');
    expect(c.state.failure, CheckFailure.emptyMessage);
    expect(sent, isEmpty);
  });

  test('retry runs the last message again', () async {
    final c = controller(client: okServer(), online: false);
    await c.startCheck('Hello');
    (c.connectivity as FakeConnectivity).online = true;
    await c.retry();
    expect(c.state.status, CheckStatus.done);
  });
}
