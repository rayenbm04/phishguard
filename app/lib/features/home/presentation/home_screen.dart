import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/utils/formatters.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/features/analysis/domain/analysis_state.dart';
import 'package:phishguard/features/history/presentation/history_controller.dart';
import 'package:phishguard/features/history/presentation/history_tile.dart';
import 'package:phishguard/features/home/presentation/draft_controller.dart';
import 'package:phishguard/features/results/presentation/result_screen.dart';

/// Home: one field to paste or type the message, two ways to fill it
/// (paste, screenshot), the Check button, and the last checks.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _text;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(draftProvider).text);
    _focus.addListener(() => setState(() {})); // The field's frame follows the focus.
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    String? text;
    try {
      text = await ref.read(clipboardProvider).read();
    } catch (_) {
      text = null;
    }
    if (!mounted) return;
    if (text == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.nothingToPaste)));
      return;
    }
    ref.read(draftProvider.notifier).replace(text);
  }

  void _check() {
    final draft = ref.read(draftProvider);
    if (draft.text.trim().isEmpty) return;
    _focus.unfocus();
    context.push(AppRoutes.analysis, extra: CheckRequest(text: draft.text, sourceApp: draft.sourceApp));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final draft = ref.watch(draftProvider);
    final history = ref.watch(historyProvider);
    // Riverpod 3: value keeps the last list while the history reloads.
    final entries = history.value;

    // Text replaced from outside the field (share, paste): show it.
    ref.listen<Draft>(draftProvider, (previous, next) {
      if (previous?.revision != next.revision && _text.text != next.text) {
        _text.value = TextEditingValue(
          text: next.text,
          selection: TextSelection.collapsed(offset: next.text.length),
        );
      }
    });

    final hasText = draft.text.trim().isNotEmpty;
    final hidden = hasText ? ref.watch(maskerProvider).countItems(draft.text) : 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 0),
              sliver: SliverList.list(children: [
                Row(
                  children: [
                    const BrandMark(size: 30),
                    const SizedBox(width: AppSpace.sm),
                    Text('PhishGuard', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text(l.homeHeadline, style: theme.textTheme.headlineMedium).entrance(context),
                const SizedBox(height: AppSpace.xs),
                Text(l.homeSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant))
                    .entrance(context, index: 1),
                const SizedBox(height: AppSpace.lg),
                _Composer(
                  controller: _text,
                  focusNode: _focus,
                  draft: draft,
                  onChanged: ref.read(draftProvider.notifier).edit,
                  onPaste: _paste,
                  onScreenshot: () => context.push(AppRoutes.screenshot),
                  onClear: () {
                    ref.read(draftProvider.notifier).clear();
                    _focus.requestFocus();
                  },
                ).entrance(context, index: 2),
                const SizedBox(height: AppSpace.md),
                InfoLine(
                  icon: Icons.lock_outline_rounded,
                  text: hidden > 0 ? l.privacyNoteCount(hidden) : l.privacyNoteNone,
                ),
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('checkButton'),
                    onPressed: hasText ? _check : null,
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(l.checkButton),
                  ),
                ),
                SectionHeader(
                  l.recentChecks,
                  action: entries == null || entries.isEmpty
                      ? null
                      : TextButton(
                          key: const Key('seeAllHistory'),
                          onPressed: () => context.go(AppRoutes.history),
                          child: Text(l.seeAll),
                        ),
                ),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
              sliver: SliverToBoxAdapter(
                child: entries == null
                    ? (history.hasError ? const SizedBox.shrink() : const HistorySkeleton())
                    : entries.isEmpty
                        ? _FirstUseHint()
                        : Column(
                            children: [
                              for (final entry in entries.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                                  child: HistoryTile(
                                    entry: entry,
                                    showDay: true,
                                    onTap: () => context.push(
                                      AppRoutes.result,
                                      extra: ResultArgs(
                                        verdict: entry.verdict,
                                        maskedText: entry.maskedText,
                                        sourceApp: entry.sourceApp,
                                        fromHistory: true,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The message field with its tools. A shared text shows where it came from.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.draft,
    required this.onChanged,
    required this.onPaste,
    required this.onScreenshot,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Draft draft;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final VoidCallback onScreenshot;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final hasText = draft.text.isNotEmpty;
    final source = sourceAppName(draft.sourceApp);

    return AnimatedContainer(
      duration: AppDurations.medium,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: focusNode.hasFocus ? scheme.primary : scheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.shared)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  key: const Key('sharedChip'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_rounded, size: 14, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        source.isEmpty ? l.sharedWithApp : l.sharedFrom(source),
                        style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          TextField(
            key: const Key('messageField'),
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            minLines: 4,
            maxLines: 9,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: l.messageHint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
            ),
          ),
          Divider(height: 1, indent: AppSpace.lg, endIndent: AppSpace.lg, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    children: [
                      TextButton.icon(
                        key: const Key('pasteButton'),
                        onPressed: onPaste,
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                        label: Text(l.paste),
                      ),
                      TextButton.icon(
                        key: const Key('screenshotButton'),
                        onPressed: onScreenshot,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                        label: Text(l.screenshot),
                      ),
                    ],
                  ),
                ),
                if (hasText)
                  IconButton(
                    key: const Key('clearDraft'),
                    tooltip: l.clearText,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown until the first check: the fastest way to use the app.
class _FirstUseHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.historyEmptyHome, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.md),
          InfoLine(icon: Icons.share_rounded, text: l.shareTip, color: scheme.onSurface),
        ],
      ),
    );
  }
}
