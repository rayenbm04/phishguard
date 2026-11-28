import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/widgets/motion.dart';

/// The risk score as a number and a bar, filled up to the score.
class RiskMeter extends StatelessWidget {
  const RiskMeter({
    super.key,
    required this.score,
    required this.level,
    required this.label,
    this.compact = false,
  });

  final int score;
  final VerdictLevel level;

  /// "Risk score" in the interface language.
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = VerdictColors.of(context).tone(level);
    final value = score.clamp(0, 100) / 100;
    final reduced = AppMotion.reducedOf(context);

    if (compact) {
      return Semantics(
        label: '$label $score / 100',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 44, child: _Bar(value: value, color: tone.accent, height: 6, animate: false)),
            const SizedBox(width: 8),
            Text('$score',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tone.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
      );
    }

    return Semantics(
      label: '$label: $score / 100',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduced ? score.toDouble() : 0, end: score.toDouble()),
                duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '${v.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: tone.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(' / 100', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          _Bar(value: value, color: tone.accent, height: 10, animate: !reduced),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.color,
    required this.height,
    required this.animate,
  });

  final double value;
  final Color color;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: scheme.surfaceContainerHighest)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: animate ? 0 : value, end: value),
                duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * v,
                  child: ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
