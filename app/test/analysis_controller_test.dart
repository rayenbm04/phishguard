import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/analysis/presentation/analysis_controller.dart';
import 'package:phishguard/features/history/presentation/history_controller.dart';

import 'helpers.dart';

void main() {
  late FakeAdapter adapter;
  late FakeConnectivity connectivity;

  Future<ProviderContainer> container({
    FakeAdapter? api,
    bool online = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    adapter = api ?? FakeAdapter.ok();
    connectivity = FakeConnectivity(online);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      apiClientProvider.overrideWithValue(fakeApi(adapter, timeout: timeout)),
      connectivityProvider.overrideWithValue(connectivity),
    ]);
    addTearDown(c.dispose);
    c.listen(analysisProvider, (_, _) {}); // Keeps the auto-dispose provider alive.
    return c;
  }

  test('online: masks, sends, gets the verdict and saves it (SD1)', () async {
    final c = await container();
    await c.read(analysisProvider.notifier).start(
          const CheckRequest(text: 'Votre colis est bloqué, appelez le 98 123 456', sourceApp: 'com.whatsapp'),
          replyLanguage: Language.english,
        );

    final state = c.read(analysisProvider);
    expect(state.phase, AnalysisPhase.done);
    expect(state.verdict!.level, VerdictLevel.fraudulent);

    final body = adapter.bodies.single;
    final message = body['message'] as Map<String, dynamic>;
    expect(adapter.requests.single.path, '/analyse');
    expect(message['text'], 'Votre colis est bloqué, appelez le [PHONE]');
    expect(message['maskedItems'], 1);
    expect(message['language'], 'fr');
    expect(body['sourceApp'], 'com.whatsapp');
    expect(body['replyLanguage'], 'en');

    final saved = c.read(historyRepositoryProvider).all();
    expect(saved.single.maskedText, contains('[PHONE]'));
    expect(saved.single.maskedText, isNot(contains('98 123 456')));
    expect(saved.single.sourceApp, 'com.whatsapp');
  });

  test('offline: fails without calling the server', () async {
    final c = await container(online: false);
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    expect(c.read(analysisProvider).failure, AnalysisFailure.offline);
    expect(adapter.requests, isEmpty);
  });

  test('server error, unreachable server and timeout give distinct failures', () async {
    var c = await container(
      api: FakeAdapter((_) async => ResponseBody.fromString('boom', 500)),
    );
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    expect(c.read(analysisProvider).failure, AnalysisFailure.serverError);

    c = await container(
      api: FakeAdapter((o) async =>
          throw DioException(requestOptions: o, type: DioExceptionType.connectionError)),
    );
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    expect(c.read(analysisProvider).failure, AnalysisFailure.unreachable);

    c = await container(api: FakeAdapter(neverAnswers), timeout: const Duration(milliseconds: 200));
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    expect(c.read(analysisProvider).failure, AnalysisFailure.timeout);
    expect(c.read(historyRepositoryProvider).all(), isEmpty);
  });

  test('an answer that does not match the contract is a server error', () async {
    final c = await container(
      api: FakeAdapter((_) async => ResponseBody.fromString('{"level": "MAYBE"}', 200)),
    );
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    expect(c.read(analysisProvider).failure, AnalysisFailure.serverError);
  });

  test('empty message is refused', () async {
    final c = await container();
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: '   '));
    expect(c.read(analysisProvider).failure, AnalysisFailure.emptyMessage);
    expect(adapter.requests, isEmpty);
  });

  test('retry runs the last message again', () async {
    final c = await container(online: false);
    await c.read(analysisProvider.notifier).start(const CheckRequest(text: 'Hello'));
    connectivity.online = true;
    await c.read(analysisProvider.notifier).retry();
    expect(c.read(analysisProvider).phase, AnalysisPhase.done);
  });
}
