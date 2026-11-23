import 'package:flutter/material.dart';

import '../models/models.dart';
import 'theme.dart';

/// The verdict, its top reasons and what to do now (end of SD1).
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.verdict, this.fromHistory = false});

  final Verdict verdict;
  final bool fromHistory;

  @override
  Widget build(BuildContext context) {
    final level = verdict.level;
    final text = Theme.of(context).textTheme;
    final reasons = [...verdict.reasons]..sort((a, b) => a.rank.compareTo(b.rank));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _VerdictBanner(verdict: verdict),
            const SizedBox(height: 24),
            Text('Why', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final reason in reasons) _ReasonTile(reason: reason, color: level.color),
            const SizedBox(height: 20),
            Text('What to do now',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final advice in verdict.advice) _AdviceTile(advice: advice),
            const SizedBox(height: 12),
            Text('Checked on ${shortDate(verdict.checkedAt)}',
                style: text.bodySmall?.copyWith(color: Pg.inkSoft)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(fromHistory ? 'Back' : 'Check another message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final level = verdict.level;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Verdict: ${level.label}, risk ${verdict.riskScore} out of 100',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: level.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(level.icon, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(level.label,
                      style: text.headlineMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${verdict.riskScore}',
                        style: text.headlineSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    Text('risk / 100',
                        style: text.labelSmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(verdict.summary,
                style: text.bodyLarge?.copyWith(color: Colors.white, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.reason, required this.color});

  final Reason reason;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (reason.evidenceDetail != null) reason.evidenceDetail!,
      'Source: ${reason.evidenceSource}',
      if (reason.checkedDate != null) 'Checked on ${shortDate(reason.checkedDate!)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text('${reason.rank}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
          title: Text(reason.text),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in details)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(line, style: const TextStyle(color: Pg.inkSoft)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  const _AdviceTile({required this.advice});

  final Advice advice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle_outline, color: Pg.indigo),
          title: Text(advice.action),
          subtitle: advice.officialContact == null
              ? null
              : Text('Official contact: ${advice.officialContact}'),
        ),
      ),
    );
  }
}
