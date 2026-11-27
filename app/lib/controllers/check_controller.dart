import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/history_repository.dart';
import '../services/personal_data_masker.dart';

/// Steps of one check (SD1 / SD5).
enum CheckStatus { idle, analysing, done, failed }

/// Why a check failed, to show the right message.
enum CheckFailure { emptyMessage, offline, serverUnreachable }

@immutable
class CheckState {
  const CheckState({
    this.status = CheckStatus.idle,
    this.verdict,
    this.failure,
  });

  final CheckStatus status;
  final Verdict? verdict;
  final CheckFailure? failure;
}

/// Runs a check: online? -> mask -> POST /analyse -> save to history.
class CheckController extends ChangeNotifier {
  CheckController({
    required this.api,
    required this.connectivity,
    required this.history,
    this.masker = const PersonalDataMasker(),
  });

  final ApiClient api;
  final ConnectivityService connectivity;
  final HistoryRepository history;
  final PersonalDataMasker masker;

  CheckState _state = const CheckState();
  CheckState get state => _state;

  String? _lastMessage;
  String? _lastSourceApp;
  Language? _lastReplyLanguage;

  /// [replyLanguage]: language of the app, used for the explanation.
  Future<void> startCheck(String message, {String? sourceApp, Language? replyLanguage}) async {
    if (_state.status == CheckStatus.analysing) return;
    _lastMessage = message;
    _lastSourceApp = sourceApp;
    _lastReplyLanguage = replyLanguage;

    if (message.trim().isEmpty) {
      _set(const CheckState(status: CheckStatus.failed, failure: CheckFailure.emptyMessage));
      return;
    }
    if (!await connectivity.isOnline()) {
      _set(const CheckState(status: CheckStatus.failed, failure: CheckFailure.offline));
      return;
    }

    _set(const CheckState(status: CheckStatus.analysing));
    final masked = masker.mask(message.trim());
    try {
      final verdict =
          await api.analyse(masked, sourceApp: sourceApp, replyLanguage: replyLanguage);
      try {
        await history.save(HistoryEntry(maskedText: masked.text, verdict: verdict));
      } catch (e) {
        debugPrint('History not saved: $e'); // The verdict matters more.
      }
      _set(CheckState(status: CheckStatus.done, verdict: verdict));
    } catch (e) {
      // ApiException, or an answer that does not match the contract.
      debugPrint('Check failed: $e');
      _set(const CheckState(status: CheckStatus.failed, failure: CheckFailure.serverUnreachable));
    }
  }

  Future<void> retry() async {
    final message = _lastMessage;
    if (message != null) {
      await startCheck(message, sourceApp: _lastSourceApp, replyLanguage: _lastReplyLanguage);
    }
  }

  void reset() => _set(const CheckState());

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _set(CheckState state) {
    _state = state;
    if (!_disposed) notifyListeners(); // The screen may be closed mid-check.
  }
}
