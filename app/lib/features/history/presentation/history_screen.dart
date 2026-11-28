import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:phishguard/app/router.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/utils/formatters.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/common.dart';
import 'package:phishguard/core/widgets/verdict_badge.dart';
import 'package:phishguard/features/history/data/history_repository.dart';
import 'package:phishguard/features/history/presentation/history_controller.dart';
import 'package:phishguard/features/history/presentation/history_tile.dart';
import 'package:phishguard/features/results/presentation/result_screen.dart';

/// Asks before clearing; returns true if the history was cleared.
Future<bool> confirmClearHistory(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: Text(l.clearHistory),
      content: Text(l.clearHistoryQuestion),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          key: const Key('confirmClear'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.clear),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(historyProvider.notifier).clear();
  messenger.showSnackBar(SnackBar(content: Text(l.historyCleared)));
  return true;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  String _query = '';
  VerdictLevel? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HistoryEntry> _apply(List<HistoryEntry> all) {
    final q = _query.trim().toLowerCase();
    return [
      for (final e in all)
        if ((_filter == null || e.verdict.level == _filter) &&
            (q.isEmpty ||
                e.maskedText.toLowerCase().contains(q) ||
                e.verdict.summary.toLowerCase().contains(q) ||
                sourceAppName(e.sourceApp).toLowerCase().contains(q)))
          e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final history = ref.watch(historyProvider);
    final all = history.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if (all != null && all.isNotEmpty)
            IconButton(
              key: const Key('clearHistory'),
              tooltip: l.clearHistory,
              onPressed: () => confirmClearHistory(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: all == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpace.page),
              child: HistorySkeleton(count: 5),
            )
          : all.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(AppSpace.page),
                  children: [
                    EmptyState(
                      icon: Icons.history_rounded,
                      title: l.historyEmptyTitle,
                      message: l.historyEmpty,
                      action: FilledButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: Text(l.checkAMessage),
                      ),
                    ),
                  ],
                )
              : _buildList(context, theme, l, all),
    );
  }

  Widget _buildList(BuildContext context, ThemeData theme, AppLocalizations l, List<HistoryEntry> all) {
    final shown = _apply(all);
    final counts = <VerdictLevel, int>{};
    for (final e in all) {
      counts[e.verdict.level] = (counts[e.verdict.level] ?? 0) + 1;
    }

    // Group by day, newest first (the list is already newest first).
    final groups = <String, List<HistoryEntry>>{};
    for (final e in shown) {
      groups.putIfAbsent(formatDay(context, e.verdict.checkedAt), () => []).add(e);
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, 0),
          sliver: SliverList.list(children: [
            TextField(
              key: const Key('historySearch'),
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: AppInputs.decoration(
                context,
                hint: l.searchHistory,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clearText,
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        icon: const Icon(Icons.close_rounded),
                      ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    key: const Key('filter-all'),
                    label: l.filterAll(all.length),
                    selected: _filter == null,
                    onSelected: () => setState(() => _filter = null),
                  ),
                  for (final level in VerdictLevel.values)
                    if ((counts[level] ?? 0) > 0)
                      _FilterChip(
                        key: Key('filter-${level.code}'),
                        level: level,
                        label: '${l.levelLabel(level)} ${counts[level]}',
                        selected: _filter == level,
                        onSelected: () => setState(() => _filter = _filter == level ? null : level),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ]),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              compact: true,
              icon: Icons.search_off_rounded,
              title: l.noMatchTitle,
              message: l.noMatchBody,
            ),
          ),
        for (final MapEntry(key: day, value: entries) in groups.entries)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            sliver: SliverList.list(children: [
              SectionHeader(day,
                  padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm)),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: HistoryTile(
                    entry: entry,
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
            ]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xl)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.level,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final VerdictLevel? level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
        avatar: level == null ? null : VerdictBadge(level: level!, size: 18),
        label: Text(label),
      ),
    );
  }
}
