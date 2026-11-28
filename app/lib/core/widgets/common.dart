import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/widgets/motion.dart';

/// A heading for a group of content, with an optional action at the end.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.padding});

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Placeholder block shown while content loads.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = AppRadius.sm});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (AppMotion.reducedOf(context)) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1400.ms, color: scheme.surfaceContainerLowest.withValues(alpha: 0.6));
  }
}

/// Skeleton of a list of checks (home and history).
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                children: [
                  const SkeletonBox(height: 40, width: 40, radius: 12),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(height: 14, width: 120),
                        const SizedBox(height: 8),
                        SkeletonBox(height: 12, width: i.isEven ? 220 : 170),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// An empty screen or list: what it is for and what to do.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? AppSpace.lg : AppSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 68,
            height: compact ? 52 : 68,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(compact ? 16 : 22),
            ),
            child: Icon(icon, size: compact ? 26 : 32, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (action != null) ...[const SizedBox(height: AppSpace.lg), action!],
        ],
      ),
    );
  }
}

/// A short line with an icon: privacy notes, hints, small warnings.
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: tint),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: tint))),
      ],
    );
  }
}

/// PhishGuard's mark: a shield whose inner line is a tick.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.color, this.onColor});

  final double size;
  final Color? color;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _ShieldPainter(color ?? scheme.primary, onColor ?? scheme.onPrimary),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color, this.onColor);

  final Color color;
  final Color onColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..cubicTo(w * 0.66, h * 0.13, w * 0.8, h * 0.16, w * 0.92, h * 0.17)
      ..cubicTo(w * 0.92, h * 0.55, w * 0.8, h * 0.8, w * 0.5, h * 0.96)
      ..cubicTo(w * 0.2, h * 0.8, w * 0.08, h * 0.55, w * 0.08, h * 0.17)
      ..cubicTo(w * 0.2, h * 0.16, w * 0.34, h * 0.13, w * 0.5, h * 0.04)
      ..close();
    canvas.drawPath(shield, Paint()..color = color);
    final tick = Path()
      ..moveTo(w * 0.31, h * 0.5)
      ..lineTo(w * 0.45, h * 0.63)
      ..lineTo(w * 0.70, h * 0.37);
    canvas.drawPath(
      tick,
      Paint()
        ..color = onColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color || old.onColor != onColor;
}
