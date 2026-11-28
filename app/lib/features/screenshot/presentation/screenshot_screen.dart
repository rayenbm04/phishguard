import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/screenshot/presentation/screenshot_controller.dart';

/// SD3: choose a screenshot, read its text on the phone, let the user check
/// and correct it, and only then start the check.
class ScreenshotScreen extends ConsumerStatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  ConsumerState<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends ConsumerState<ScreenshotScreen> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Opening this screen means "pick a screenshot": open the gallery at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(screenshotProvider.notifier).pick();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _check() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    context.pushReplacement(AppRoutes.analysis, extra: CheckRequest(text: text, fromScreenshot: true));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(screenshotProvider);
    ref.listen<ScreenshotState>(screenshotProvider, (previous, next) {
      if (next.phase == ScreenshotPhase.found && previous?.phase != ScreenshotPhase.found) {
        _text.text = next.text;
        setState(() {});
      }
    });
    final pick = ref.read(screenshotProvider.notifier).pick;

    final Widget body = switch (state.phase) {
      ScreenshotPhase.idle || ScreenshotPhase.picking => _Intro(
          key: const ValueKey('intro'),
          busy: state.phase == ScreenshotPhase.picking,
          onPick: pick,
        ),
      ScreenshotPhase.reading => _Reading(key: const ValueKey('reading'), imagePath: state.imagePath),
      ScreenshotPhase.found => _Found(
          key: const ValueKey('found'),
          imagePath: state.imagePath,
          controller: _text,
          onChanged: () => setState(() {}),
          onCheck: _check,
          onPickAnother: pick,
        ),
      ScreenshotPhase.noText => _Problem(
          key: const ValueKey('noText'),
          imagePath: state.imagePath,
          icon: Icons.text_fields_rounded,
          title: l.noTextTitle,
          message: l.noTextInImage,
          onPickAnother: pick,
        ),
      ScreenshotPhase.error => _Problem(
          key: const ValueKey('error'),
          imagePath: state.imagePath,
          icon: Icons.broken_image_outlined,
          title: l.imageErrorTitle,
          message: l.imageError,
          onPickAnother: pick,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.screenshotTitle)),
      body: SafeArea(child: AnimatedSwitcher(duration: AppDurations.medium, child: body)),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({super.key, required this.busy, required this.onPick});

  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        EmptyState(
          icon: Icons.add_photo_alternate_outlined,
          title: l.screenshotIntroTitle,
          message: l.screenshotIntroBody,
          action: FilledButton.icon(
            key: const Key('pickScreenshot'),
            onPressed: busy ? null : onPick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l.chooseScreenshot),
          ),
        ),
        InfoLine(icon: Icons.translate_rounded, text: l.screenshotLatinOnly),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.imagePath, this.height = 220});

  final String? imagePath;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = imagePath;
    return Semantics(
      image: true,
      label: context.l10n.screenshotPreviewLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: height,
          color: scheme.surfaceContainerHigh,
          child: path == null
              ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant, size: 40)
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) =>
                      Center(child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant, size: 40)),
                ),
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({super.key, required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        _Preview(imagePath: imagePath),
        const SizedBox(height: AppSpace.xl),
        const LinearProgressIndicator(minHeight: 4),
        const SizedBox(height: AppSpace.md),
        Text(l.readingImage, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.xs),
        Text(l.readingImageBody, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _Found extends ConsumerWidget {
  const _Found({
    super.key,
    required this.imagePath,
    required this.controller,
    required this.onChanged,
    required this.onCheck,
    required this.onPickAnother,
  });

  final String? imagePath;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onCheck;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final text = controller.text;
    final hidden = text.trim().isEmpty ? 0 : ref.watch(maskerProvider).countItems(text);

    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        _Preview(imagePath: imagePath, height: 140),
        const SizedBox(height: AppSpace.lg),
        Text(l.textFromScreenshot, style: theme.textTheme.titleMedium).entrance(context),
        const SizedBox(height: AppSpace.sm),
        TextField(
          key: const Key('screenshotText'),
          controller: controller,
          onChanged: (_) => onChanged(),
          minLines: 4,
          maxLines: 12,
          style: theme.textTheme.bodyLarge,
          decoration: AppInputs.decoration(context),
        ).entrance(context, index: 1),
        const SizedBox(height: AppSpace.md),
        InfoLine(
          icon: Icons.lock_outline_rounded,
          text: hidden > 0 ? l.privacyNoteCount(hidden) : l.privacyNoteNone,
        ),
        const SizedBox(height: AppSpace.xl),
        FilledButton.icon(
          key: const Key('checkScreenshotText'),
          onPressed: text.trim().isEmpty ? null : onCheck,
          icon: const Icon(Icons.shield_outlined),
          label: Text(l.checkThisText),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(onPressed: onPickAnother, child: Text(l.chooseAnother)),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    super.key,
    required this.imagePath,
    required this.icon,
    required this.title,
    required this.message,
    required this.onPickAnother,
  });

  final String? imagePath;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        if (imagePath != null) _Preview(imagePath: imagePath, height: 140),
        EmptyState(icon: icon, title: title, message: message, compact: true),
        FilledButton.icon(
          key: const Key('pickAnother'),
          onPressed: onPickAnother,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l.chooseAnother),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(
          key: const Key('typeInstead'),
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l.typeInstead),
        ),
      ],
    );
  }
}
