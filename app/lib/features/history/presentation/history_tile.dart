import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/utils/formatters.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/masked_text.dart';
import 'package:phishguard/core/widgets/risk_meter.dart';
import 'package:phishguard/core/widgets/verdict_badge.dart';
import 'package:phishguard/features/history/data/history_repository.dart';

/// One past check: shape badge, verdict, time, a line of the message, score.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, required this.onTap, this.showDay = false});

  final HistoryEntry entry;
  final VoidCallback onTap;

  /// Show the day as well as the time (home screen); the history screen groups by day.
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final verdict = entry.verdict;
    final tone = VerdictColors.of(context).tone(verdict.level);
    final when = showDay ? formatMoment(context, verdict.checkedAt) : formatTime(context, verdict.checkedAt);
    final source = sourceAppName(entry.sourceApp);

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.lg, AppSpace.md),
          child: Row(
            children: [
              VerdictBadge(level: verdict.level, size: 40),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l.levelLabel(verdict.level),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(color: tone.text),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            source.isEmpty ? when : '$when · $source',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MaskedText.plain(context, entry.maskedText).replaceAll('\n', ' '),
                      textDirection: directionOf(entry.maskedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              RiskMeter(
                score: verdict.riskScore,
                level: verdict.level,
                label: l.riskScore,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
