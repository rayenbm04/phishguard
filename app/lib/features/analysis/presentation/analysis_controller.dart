import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/services/api_client.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/history/data/history_repository.dart';
import 'package:phishguard/features/history/presentation/history_controller.dart';

final analysisProvider =
    NotifierProvider.autoDispose<AnalysisController, AnalysisState>(AnalysisController.new);

/// Runs one check: online? -> mask on the phone -> POST /analyse -> save to history.
class AnalysisController extends Notifier<AnalysisState> {
  CheckRequest? _last;
  Language? _lastReplyLanguage;

  @override
  AnalysisState build() => const AnalysisState();

  /// [replyLanguage]: language of the interface, used for the explanation.
  Future<void> start(CheckRequest request, {Language? replyLanguage}) async {
    if (state.isRunning) return;
    _last = request;
    _lastReplyLanguage = replyLanguage;

    final text = request.text.trim();
    if (text.isEmpty) {
      state = const AnalysisState(phase: AnalysisPhase.failed, failure: AnalysisFailure.emptyMessage);
      return;
    }

    // Step 1 happens on the phone: personal numbers are hidden before anything leaves it.
    final masked = ref.read(maskerProvider).mask(text);
    state = AnalysisState(phase: AnalysisPhase.preparing, masked: masked);

    if (!await ref.read(connectivityProvider).isOnline()) {
      if (!ref.mounted) return;
      state = AnalysisState(
          phase: AnalysisPhase.failed, masked: masked, failure: AnalysisFailure.offline);
      return;
    }
    if (!ref.mounted) return;
    state = AnalysisState(phase: AnalysisPhase.waiting, masked: masked);

    try {
      final verdict = await ref
          .read(apiClientProvider)
          .analyse(masked, sourceApp: request.sourceApp, replyLanguage: replyLanguage);
      try {
        await ref.read(historyRepositoryProvider).save(
              HistoryEntry(maskedText: masked.text, verdict: verdict, sourceApp: request.sourceApp),
            );
        ref.invalidate(historyProvider);
      } catch (e) {
        debugPrint('History not saved: $e'); // The verdict matters more.
      }
      if (!ref.mounted) return;
      state = AnalysisState(phase: AnalysisPhase.done, masked: masked, verdict: verdict);
    } on ApiException catch (e) {
      debugPrint('Check failed: $e');
      if (!ref.mounted) return;
      state = AnalysisState(
        phase: AnalysisPhase.failed,
        masked: masked,
        failure: switch (e.failure) {
          ApiFailure.timeout => AnalysisFailure.timeout,
          ApiFailure.unreachable => AnalysisFailure.unreachable,
          ApiFailure.serverError || ApiFailure.badResponse => AnalysisFailure.serverError,
        },
      );
    } catch (e) {
      debugPrint('Check failed: $e');
      if (!ref.mounted) return;
      state = AnalysisState(
          phase: AnalysisPhase.failed, masked: masked, failure: AnalysisFailure.serverError);
    }
  }

  Future<void> retry() async {
    final last = _last;
    if (last != null) await start(last, replyLanguage: _lastReplyLanguage);
  }
}
