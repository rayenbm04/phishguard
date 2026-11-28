import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/masked_text.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/analysis/presentation/analysis_controller.dart';
import 'package:phishguard/features/results/presentation/result_screen.dart';

/// The check in progress: the masked text that is sent, then four steps.
/// The first step (hiding numbers, finding clues) is done on the phone; the
/// others run on the server, so the screen moves through them while waiting
/// and completes the last one only when the verdict has arrived.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key, required this.request});

  final CheckRequest request;

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  static const _stepPace = Duration(milliseconds: 1100);

  Timer? _pace;
  int _serverStep = 0; // How many server steps are shown as done while waiting.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    _serverStep = 0;
    _pace?.cancel();
    _pace = Timer.periodic(_stepPace, (_) {
      if (!mounted) return;
      if (ref.read(analysisProvider).phase == AnalysisPhase.waiting && _serverStep < 2) {
        setState(() => _serverStep++);
      }
    });
    ref
        .read(analysisProvider.notifier)
        .start(widget.request, replyLanguage: context.appLanguage);
  }

  void _onState(AnalysisState? previous, AnalysisState next) {
    if (next.phase == AnalysisPhase.failed || next.phase == AnalysisPhase.done) {
      _pace?.cancel();
    }
    if (next.phase == AnalysisPhase.done && previous?.phase != AnalysisPhase.done && !_leaving) {
      _leaving = true;
      final verdict = next.verdict!;
      final masked = next.masked!;
      // Let the last tick be seen, unless motion is reduced.
      final pause = AppMotion.reducedOf(context) ? Duration.zero : const Duration(milliseconds: 450);
      Future<void>.delayed(pause, () {
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.result,
          extra: ResultArgs(
            verdict: verdict,
            maskedText: masked.text,
            sourceApp: widget.request.sourceApp,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pace?.cancel();
    super.dispose();
  }

  /// Index of the step in progress (4 = all done).
  int _activeStep(AnalysisState state) => switch (state.phase) {
        AnalysisPhase.idle || AnalysisPhase.preparing => 0,
        AnalysisPhase.waiting => 1 + _serverStep,
        AnalysisPhase.done => 4,
        AnalysisPhase.failed => -1,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(analysisProvider);
    ref.listen<AnalysisState>(analysisProvider, _onState);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.phase == AnalysisPhase.failed ? l.analysisFailedTitle : l.analysisTitle),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          child: state.phase == AnalysisPhase.failed
              ? _FailurePanel(
                  key: const ValueKey('failure'),
                  failure: state.failure ?? AnalysisFailure.unreachable,
                  onRetry: () {
                    _start();
                  },
                  onEdit: () => context.pop(),
                )
              : _Progress(
                  key: const ValueKey('progress'),
                  state: state,
                  active: _activeStep(state),
                ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({super.key, required this.state, required this.active});

  final AnalysisState state;
  final int active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final masked = state.masked;

    final steps = [
      (AnalysisStep.extractClues, l.stepClues, l.stepCluesBody),
      (AnalysisStep.checkLinks, l.stepLinks, l.stepLinksBody),
      (AnalysisStep.compareScams, l.stepScams, l.stepScamsBody),
      (AnalysisStep.decideVerdict, l.stepVerdict, l.stepVerdictBody),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
      children: [
        // What leaves the phone, exactly.
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.whatIsSent, style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpace.sm),
              if (masked == null)
                const LinearProgressIndicator(minHeight: 2)
              else ...[
                MaskedText(masked.text,
                    style: theme.textTheme.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        masked.maskedItems > 0 ? l.hiddenInMessage(masked.maskedItems) : l.nothingHidden,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).entrance(context),
        const SizedBox(height: AppSpace.xl),
        Semantics(
          liveRegion: true,
          label: active >= 0 && active < steps.length ? steps[active].$2 : null,
          child: Column(
            children: [
              for (final (i, (step, title, body)) in steps.indexed)
                _StepRow(
                  key: Key('step-${step.name}'),
                  title: title,
                  body: body,
                  status: i < active
                      ? _StepStatus.done
                      : i == active
                          ? _StepStatus.active
                          : _StepStatus.pending,
                  last: i == steps.length - 1,
                ).entrance(context, index: 1 + i),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(l.analysisWaitNote, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

enum _StepStatus { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.title,
    required this.body,
    required this.status,
    required this.last,
  });

  final String title;
  final String body;
  final _StepStatus status;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = status == _StepStatus.done;
    final active = status == _StepStatus.active;

    final Widget indicator = switch (status) {
      _StepStatus.done => Container(
          key: const ValueKey('done'),
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
        ),
      _StepStatus.active => SizedBox(
          key: const ValueKey('active'),
          width: 28,
          height: 28,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CircularProgressIndicator(strokeWidth: 2.6, color: scheme.primary),
          ),
        ),
      _StepStatus.pending => Container(
          key: const ValueKey('pending'),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 2),
          ),
        ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AnimatedSwitcher(duration: AppDurations.fast, child: indicator),
              if (!last)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.medium,
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: last ? 0 : AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AppDurations.fast,
                    style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                      color: status == _StepStatus.pending ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                    child: Text(title),
                  ),
                  if (active || done)
                    Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({super.key, required this.failure, required this.onRetry, required this.onEdit});

  final AnalysisFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final warn = VerdictColors.of(context).suspicious;

    final (icon, title, body) = switch (failure) {
      AnalysisFailure.offline => (Icons.wifi_off_rounded, l.errOfflineTitle, l.errOfflineBody),
      AnalysisFailure.timeout => (Icons.hourglass_bottom_rounded, l.errTimeoutTitle, l.errTimeoutBody),
      AnalysisFailure.emptyMessage => (Icons.edit_note_rounded, l.errEmptyTitle, l.errEmptyBody),
      AnalysisFailure.unreachable ||
      AnalysisFailure.serverError =>
        (Icons.cloud_off_rounded, l.errServerTitle, l.errServerBody),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xl, AppSpace.page, AppSpace.xl),
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: warn.container, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 32, color: warn.text),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(title, key: Key('failure-${failure.name}'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(body, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (failure != AnalysisFailure.emptyMessage) ...[
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.front_hand_outlined, size: 20, color: theme.colorScheme.onSurface),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(l.meanwhileAdvice, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        if (failure != AnalysisFailure.emptyMessage)
          FilledButton.icon(
            key: const Key('retryButton'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.tryAgain),
          ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(
          key: const Key('editMessage'),
          onPressed: onEdit,
          child: Text(l.editMessage),
        ),
      ],
    );
  }
}
