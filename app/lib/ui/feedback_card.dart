import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import 'theme.dart';

/// SD6: rate the verdict (1 to 5 stars, optional comment) or report the message as a scam.
/// The masked text is sent only with a report, after the user has read what will be sent.
class FeedbackCard extends StatefulWidget {
  const FeedbackCard({super.key, required this.verdict, required this.api, this.maskedText});

  final Verdict verdict;
  final ApiClient api;
  final String? maskedText;

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
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
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await widget.api.sendFeedback(feedback);
      return true;
    } catch (e) {
      debugPrint('Feedback not sent: $e');
      messenger.showSnackBar(SnackBar(content: Text(s.feedbackError)));
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
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.reportScam),
        content: Text(s.reportExplain),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(
            key: const Key('confirmReport'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.report),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _send(UserFeedback(
      verdictId: widget.verdict.id,
      rating: _rating == 0 ? null : _rating,
      reportedAsScam: true,
      maskedText: widget.maskedText,
    ));
    if (ok && mounted) setState(() => _reported = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_rated)
              _Thanks(s.feedbackThanks)
            else ...[
              Text(s.feedbackQuestion,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (var n = 1; n <= 5; n++)
                    IconButton(
                      key: Key('star-$n'),
                      tooltip: s.starsLabel(n),
                      onPressed: _sending ? null : () => setState(() => _rating = n),
                      icon: Icon(n <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Pg.indigo, size: 32),
                    ),
                ],
              ),
              if (_rating > 0) ...[
                TextField(
                  key: const Key('feedbackComment'),
                  controller: _comment,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: s.commentHint),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    key: const Key('sendFeedback'),
                    style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
                    onPressed: _sending ? null : _sendRating,
                    child: Text(s.send),
                  ),
                ),
              ],
            ],
            const Divider(height: 28),
            if (_reported)
              _Thanks(s.reportThanks)
            else
              TextButton.icon(
                key: const Key('reportScam'),
                onPressed: _sending ? null : _report,
                icon: const Icon(Icons.flag_outlined, color: Pg.fraudulent),
                label: Text(s.reportScam, style: const TextStyle(color: Pg.fraudulent)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.check_circle, color: Pg.safe),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      );
}
