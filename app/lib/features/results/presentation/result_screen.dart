import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/home/presentation/draft_controller.dart';
import 'package:phishguard/features/results/presentation/feedback_card.dart';
import 'package:phishguard/features/results/presentation/result_widgets.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

/// What the result screen shows: a fresh verdict or one from the history.
@immutable
class ResultArgs {
  const ResultArgs({
    required this.verdict,
    required this.maskedText,
    this.sourceApp,
    this.fromHistory = false,
  });

  final Verdict verdict;
  final String maskedText;
  final String? sourceApp;
  final bool fromHistory;
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.args});

  final ResultArgs args;

  void _checkAnother(BuildContext context, WidgetRef ref) {
    ref.read(draftProvider.notifier).clear();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final verdict = args.verdict;
    final easyRead = ref.watch(settingsProvider.select((s) => s.easyRead));
    final reasons = [...verdict.reasons]..sort((a, b) => a.rank.compareTo(b.rank));

    var i = 0;
    Widget enter(Widget child) => child.entrance(context, index: i++);

    return Scaffold(
      appBar: AppBar(title: Text(args.fromHistory ? l.pastCheck : l.resultTitle)),
      body: ListView(
        key: const Key('resultList'),
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
        children: [
          enter(VerdictHeader(verdict: verdict, fromHistory: args.fromHistory)),
          SectionHeader(l.whatToDo),
          enter(AdviceSection(advice: verdict.advice, level: verdict.level)),
          if (reasons.isNotEmpty) ...[
            SectionHeader(l.why),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: enter(ReasonCard(reason: reason, level: verdict.level, initiallyOpen: easyRead)),
              ),
          ],
          SectionHeader(l.originalMessage),
          OriginalMessage(maskedText: args.maskedText, sourceApp: args.sourceApp),
          const SizedBox(height: AppSpace.xl),
          FeedbackCard(verdict: verdict, maskedText: args.maskedText),
          const SizedBox(height: AppSpace.xl),
          FilledButton.icon(
            key: const Key('checkAnother'),
            onPressed: () => _checkAnother(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.checkAnother),
          ),
        ],
      ),
    );
  }
}
