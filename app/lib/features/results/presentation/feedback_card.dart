import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/app/theme/app_colors.dart';
import 'package:phishguard/app/theme/app_theme.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/providers.dart';
import 'package:phishguard/core/utils/l10n.dart';
import 'package:phishguard/core/widgets/masked_text.dart';

/// SD6: rate the verdict (1 to 5 stars, optional comment) or report the message as a scam.
/// The masked text is sent only with a report, after the user has read what will be sent.
class FeedbackCard extends ConsumerStatefulWidget {
  const FeedbackCard({super.key, required this.verdict, this.maskedText});

  final Verdict verdict;
  final String? maskedText;

  @override
  ConsumerState<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends ConsumerState<FeedbackCard> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  bool _rated = false;
  bool _reported = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<bool> _send(UserFeedback feedback) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).sendFeedback(feedback);
      return true;
    } catch (e) {
      debugPrint('Feedback not sent: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.feedbackError)));
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendRating() async {
    final comment = _comment.text.trim();
    final ok = await _send(UserFeedback(
      verdictId: widget.verdict.id,
      rating: _rating,
      comment: comment.isEmpty ? null : comment,
    ));
    if (ok && mounted) setState(() => _rated = true);
  }

  Future<void> _report() async {
    final l = context.l10n;
    final masked = widget.maskedText;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(Icons.flag_outlined, color: VerdictColors.of(context).fraudulent.text),
          title: Text(l.reportScam),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.reportExplain),
                if (masked != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(l.reportWhatIsSent, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: MaskedText(masked, style: theme.textTheme.bodySmall, maxLines: 8,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('confirmReport'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.report),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final ok = await _send(UserFeedback(
      verdictId: widget.verdict.id,
      rating: _rating == 0 ? null : _rating,
      reportedAsScam: true,
      maskedText: masked,
    ));
    if (ok && mounted) setState(() => _reported = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final danger = VerdictColors.of(context).fraudulent.text;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _rated
                  ? _Thanks(key: const ValueKey('rated'), message: l.feedbackThanks)
                  : Column(
                      key: const ValueKey('rating'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.feedbackQuestion, style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          children: [
                            for (var n = 1; n <= 5; n++)
                              IconButton(
                                key: Key('star-$n'),
                                tooltip: l.starsLabel(n),
                                onPressed: _sending ? null : () => setState(() => _rating = n),
                                icon: Icon(
                                  n <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: n <= _rating ? scheme.primary : scheme.onSurfaceVariant,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          alignment: AlignmentDirectional.topStart,
                          child: _rating == 0
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: AppSpace.sm),
                                    TextField(
                                      key: const Key('feedbackComment'),
                                      controller: _comment,
                                      maxLength: 500,
                                      maxLines: 2,
                                      decoration: AppInputs.decoration(context, hint: l.commentHint),
                                    ),
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: FilledButton(
                                        key: const Key('sendFeedback'),
                                        onPressed: _sending ? null : _sendRating,
                                        child: Text(l.send),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Divider(),
            ),
            if (_reported)
              _Thanks(message: l.reportThanks)
            else
              TextButton.icon(
                key: const Key('reportScam'),
                onPressed: _sending ? null : _report,
                style: TextButton.styleFrom(foregroundColor: danger),
                icon: const Icon(Icons.flag_outlined),
                label: Text(l.reportScam),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.check_circle_rounded, color: VerdictColors.of(context).safe.accent),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}
