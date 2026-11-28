import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/core/models/models.dart';

/// The verdict as a shape, so it reads without colour too:
/// an octagon (stop) for a scam, a diamond (warning) for suspicious,
/// a circle for safe, a rounded square for unsure.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.level, this.size = 56, this.semanticLabel});

  final VerdictLevel level;
  final double size;
  final String? semanticLabel;

  static IconData iconOf(VerdictLevel level) => switch (level) {
        VerdictLevel.fraudulent => Icons.front_hand_rounded,
        VerdictLevel.suspicious => Icons.priority_high_rounded,
        VerdictLevel.safe => Icons.check_rounded,
        VerdictLevel.unsure => Icons.question_mark_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final tone = VerdictColors.of(context).tone(level);
    // The diamond's inscribed square is smaller: give its icon less room.
    final iconScale = level == VerdictLevel.suspicious ? 0.38 : 0.46;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BadgePainter(level: level, color: tone.accent),
          child: Center(
            child: Icon(iconOf(level), size: size * iconScale, color: tone.onAccent),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter({required this.level, required this.color});

  final VerdictLevel level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final rect = Offset.zero & size;
    switch (level) {
      case VerdictLevel.safe:
        canvas.drawOval(rect, paint);
      case VerdictLevel.fraudulent:
        canvas.drawPath(_rounded(_polygon(size, 8, math.pi / 8), size.width * 0.05), paint);
      case VerdictLevel.suspicious:
        canvas.drawPath(_rounded(_polygon(size, 4, 0), size.width * 0.06), paint);
      case VerdictLevel.unsure:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(size.width * 0.06), Radius.circular(size.width * 0.24)),
          paint,
        );
    }
  }

  /// Corners of a regular polygon inscribed in [size], first corner at [start].
  static List<Offset> _polygon(Size size, int sides, double start) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    return [
      for (var i = 0; i < sides; i++)
        center +
            Offset(
              r * math.cos(start + 2 * math.pi * i / sides - math.pi / 2),
              r * math.sin(start + 2 * math.pi * i / sides - math.pi / 2),
            ),
    ];
  }

  /// A closed path through [points] with softened corners.
  static Path _rounded(List<Offset> points, double radius) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final prev = points[(i - 1 + points.length) % points.length];
      final curr = points[i];
      final next = points[(i + 1) % points.length];
      final a = curr + _toward(curr, prev, radius);
      final b = curr + _toward(curr, next, radius);
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, b.dx, b.dy);
    }
    return path..close();
  }

  static Offset _toward(Offset from, Offset to, double distance) {
    final d = to - from;
    final length = d.distance;
    return length == 0 ? Offset.zero : d / length * distance;
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.level != level || old.color != color;
}
