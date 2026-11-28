import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Motion policy of the whole app. Decorative motion is off when the phone asks
/// for it (Remove animations) or when easy-read mode is on.
class AppMotion extends InheritedWidget {
  const AppMotion({super.key, required this.reduced, required super.child});

  final bool reduced;

  static bool reducedOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppMotion>();
    return (scope?.reduced ?? false) || MediaQuery.maybeDisableAnimationsOf(context) == true;
  }

  @override
  bool updateShouldNotify(AppMotion oldWidget) => reduced != oldWidget.reduced;
}

/// Durations and curves used everywhere, so motion feels like one system.
abstract final class AppDurations {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}

extension EntranceMotion on Widget {
  /// Fades and lifts the widget in once, staggered by [index].
  /// Used for the first appearance of a screen's content, not on every rebuild.
  Widget entrance(BuildContext context, {int index = 0, double offset = 0.06}) {
    if (AppMotion.reducedOf(context)) return this;
    return animate(delay: Duration(milliseconds: 40 + 55 * index))
        .fadeIn(duration: AppDurations.medium, curve: AppDurations.enter)
        .slideY(begin: offset, end: 0, duration: AppDurations.slow, curve: AppDurations.enter);
  }
}
