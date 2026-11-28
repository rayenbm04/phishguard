import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/services/link_opener.dart';
import 'package:phishguard/core/utils/formatters.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/masked_text.dart';
import 'package:phishguard/core/widgets/motion.dart';
import 'package:phishguard/core/widgets/risk_meter.dart';
import 'package:phishguard/core/widgets/verdict_badge.dart';

/// The verdict: shape, name, score and the server's summary, on the verdict's tint.
class VerdictHeader extends StatelessWidget {
  const VerdictHeader({super.key, required this.verdict, this.fromHistory = false});

  final Verdict verdict;
  final bool fromHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final tone = VerdictColors.of(context).tone(verdict.level);
    final reduced = AppMotion.reducedOf(context);

    Widget badge = VerdictBadge(level: verdict.level, size: 68);
    if (!reduced) {
      badge = badge
          .animate()
          .scale(begin: const Offset(0.6, 0.6), duration: 480.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms);
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${l.levelLabel(verdict.level)}. ${l.riskScore} ${verdict.riskScore} / 100.',
      child: Container(
        key: Key('verdict-${verdict.level.code}'),
        padding: const EdgeInsets.all(AppSpace.xl - 4),
        decoration: BoxDecoration(
          color: tone.container,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: tone.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                badge,
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.levelLabel(verdict.level),
                          style: theme.textTheme.headlineLarge?.copyWith(color: tone.text)),
                      const SizedBox(height: 2),
                      Text(l.levelHeadline(verdict.level), style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            RiskMeter(score: verdict.riskScore, level: verdict.level, label: l.riskScore),
            const SizedBox(height: AppSpace.lg),
            Text(verdict.summary, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpace.md),
            Text(
              fromHistory
                  ? l.checkedOnFromHistory(formatMoment(context, verdict.checkedAt))
                  : l.checkedOn(formatMoment(context, verdict.checkedAt)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// "What to do now": the actions in order, with the official contact when the
/// server gives one. Only that contact can be opened from the app.
class AdviceSection extends ConsumerWidget {
  const AdviceSection({super.key, required this.advice, required this.level});

  final List<Advice> advice;
  final VerdictLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final tone = VerdictColors.of(context).tone(level);

    if (advice.isEmpty) return Text(l.noAdvice, style: theme.textTheme.bodyMedium);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in advice.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpace.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? tone.accent : scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: i == 0 ? tone.onAccent : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            item.action,
                            style: i == 0 ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (item.officialContact != null) ...[
                          const SizedBox(height: AppSpace.sm),
                          _OfficialContact(contact: item.officialContact!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfficialContact extends ConsumerWidget {
  const _OfficialContact({required this.contact});

  final String contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final opener = ref.read(linkOpenerProvider);
    final phone = LinkOpener.isPhone(contact);
    final canOpen = LinkOpener.uriOf(contact) != null;
    final label = contact.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), '');

    Future<void> copy() async {
      final messenger = ScaffoldMessenger.of(context);
      await opener.copy(contact);
      messenger.showSnackBar(SnackBar(content: Text(l.contactCopied)));
    }

    Future<void> open() async {
      final messenger = ScaffoldMessenger.of(context);
      final opened = await opener.open(contact);
      if (!opened) {
        await opener.copy(contact);
        messenger.showSnackBar(SnackBar(content: Text(l.contactCopied)));
      }
    }

    return Semantics(
      hint: l.officialContactHint,
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            key: Key('contact-$contact'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: canOpen ? open : copy,
            onLongPress: copy,
            icon: Icon(phone ? Icons.call_rounded : Icons.verified_outlined, size: 18),
            label: Text(l.officialContact(label), overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            tooltip: l.copy,
            onPressed: copy,
            icon: const Icon(Icons.content_copy_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

/// One reason behind the verdict. Tap to see the evidence that supports it.
class ReasonCard extends StatefulWidget {
  const ReasonCard({super.key, required this.reason, required this.level, this.initiallyOpen = false});

  final Reason reason;
  final VerdictLevel level;
  final bool initiallyOpen;

  @override
  State<ReasonCard> createState() => _ReasonCardState();
}

class _ReasonCardState extends State<ReasonCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final reason = widget.reason;
    final tone = VerdictColors.of(context).tone(widget.level);
    final checked = reason.checkedDate;

    return Card(
      child: InkWell(
        key: Key('reason-${reason.rank}'),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsetsDirectional.only(end: AppSpace.md, top: 2),
                    decoration: BoxDecoration(
                      color: tone.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reason.text, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(l.source(reason.evidenceSource), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppDurations.medium,
                    child: Icon(Icons.expand_more_rounded,
                        semanticLabel: _open ? l.hideEvidence : l.showEvidence,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              AnimatedSize(
                duration: AppDurations.medium,
                curve: AppDurations.enter,
                alignment: AlignmentDirectional.topStart,
                child: !_open
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(start: AppSpace.lg, top: AppSpace.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpace.md),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.evidence, style: theme.textTheme.labelMedium),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                reason.evidenceDetail ?? l.noEvidenceDetail,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (checked != null) ...[
                                const SizedBox(height: AppSpace.sm),
                                Text(l.checkedOn(formatMoment(context, checked)),
                                    style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The message as it was sent, numbers hidden. Long messages fold.
class OriginalMessage extends StatefulWidget {
  const OriginalMessage({super.key, required this.maskedText, this.sourceApp});

  final String maskedText;
  final String? sourceApp;

  @override
  State<OriginalMessage> createState() => _OriginalMessageState();
}

class _OriginalMessageState extends State<OriginalMessage> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final long = widget.maskedText.length > 220 || '\n'.allMatches(widget.maskedText).length > 4;
    final source = sourceAppName(widget.sourceApp);
    final hidden = RegExp(r'\[(PHONE|CARD|ACCOUNT|CIN)\]').allMatches(widget.maskedText).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (source.isNotEmpty) ...[
              Text(l.sharedFrom(source), style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpace.sm),
            ],
            AnimatedSize(
              duration: AppDurations.medium,
              alignment: AlignmentDirectional.topStart,
              child: MaskedText(
                widget.maskedText,
                style: theme.textTheme.bodyMedium,
                maxLines: long && !_all ? 5 : null,
                overflow: long && !_all ? TextOverflow.fade : null,
              ),
            ),
            if (long)
              TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? l.showLess : l.showAll),
              ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    hidden > 0 ? l.hiddenInMessage(hidden) : l.nothingHidden,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
