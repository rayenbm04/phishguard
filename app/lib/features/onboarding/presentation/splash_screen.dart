import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/settings/presentation/settings_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1100);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(
      AppMotion.reducedOf(context) ? const Duration(milliseconds: 300) : SplashScreen.duration,
      _next,
    );
  }

  void _next() {
    if (!mounted) return;
    final done = ref.read(settingsProvider).setupDone;
    context.go(done ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = AppMotion.reducedOf(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? theme.colorScheme.surface : AppColors.navy;

    Widget mark = const BrandMark(size: 84, color: AppColors.primaryDark, onColor: AppColors.navy);
    Widget words = Column(
      children: [
        Text('PhishGuard',
            style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          context.l10n.splashTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFB9C0DA)),
        ),
      ],
    );
    if (!reduced) {
      mark = mark
          .animate()
          .scale(begin: const Offset(0.82, 0.82), duration: 520.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 300.ms);
      words = words.animate(delay: 220.ms).fadeIn(duration: 360.ms).slideY(begin: 0.25, end: 0);
    }

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [mark, const SizedBox(height: 24), words],
          ),
        ),
      ),
    );
  }
}
