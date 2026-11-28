import 'package:flutter/foundation.dart';

import 'package:phishguard/core/models/models.dart';

/// What the user asked to check. Created only when the user taps a Check button.
@immutable
class CheckRequest {
  const CheckRequest({required this.text, this.sourceApp, this.fromScreenshot = false});

  final String text;
  final String? sourceApp;
  final bool fromScreenshot;
}

/// The four steps shown while a message is checked. The server runs them
/// itself; the app shows where the check stands.
enum AnalysisStep { extractClues, checkLinks, compareScams, decideVerdict }

enum AnalysisPhase { idle, preparing, waiting, done, failed }

/// Why a check gave no verdict, to show the right message.
enum AnalysisFailure { emptyMessage, offline, timeout, unreachable, serverError }

@immutable
class AnalysisState {
  const AnalysisState({
    this.phase = AnalysisPhase.idle,
    this.masked,
    this.verdict,
    this.failure,
  });

  final AnalysisPhase phase;

  /// The text as it was sent (personal numbers replaced by tags).
  final MaskedMessage? masked;
  final Verdict? verdict;
  final AnalysisFailure? failure;

  bool get isRunning => phase == AnalysisPhase.preparing || phase == AnalysisPhase.waiting;
}
