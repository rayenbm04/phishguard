import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../services/history_repository.dart';
import 'check_screen.dart';
import 'result_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HistoryEntry> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await widget.services.history.all();
      if (mounted) setState(() => _history = entries);
    } catch (e) {
      debugPrint('History not loaded: $e');
    }
  }

  Future<void> _openCheck({String text = ''}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CheckScreen(services: widget.services, initialText: text),
    ));
    _loadHistory();
  }

  Future<void> _pasteAndCheck() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    await _openCheck(text: data?.text ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Pg.indigo, size: 30),
                const SizedBox(width: 10),
                Text('PhishGuard',
                    style: text.headlineSmall?.copyWith(
                        color: Pg.indigo, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Got a strange message?',
                style: text.headlineMedium?.copyWith(
                    color: Pg.ink, fontWeight: FontWeight.w700, height: 1.15)),
            const SizedBox(height: 8),
            Text(
              'Get a second opinion before you click, pay or call back.',
              style: text.bodyLarge?.copyWith(color: Pg.inkSoft),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pasteAndCheck,
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste and analyse'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openCheck(),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Type a message or link'),
            ),
            const SizedBox(height: 16),
            const _ShareTip(),
            const SizedBox(height: 28),
            Text('Recent checks',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_history.isEmpty)
              Text('Your checks will appear here. They stay on this phone.',
                  style: text.bodyMedium?.copyWith(color: Pg.inkSoft))
            else
              for (final entry in _history.take(10)) _HistoryTile(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _ShareTip extends StatelessWidget {
  const _ShareTip();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.ios_share, color: Pg.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Faster: in WhatsApp, SMS or Gmail, long-press the message, '
                'tap Share, then choose PhishGuard.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final level = entry.verdict.level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(level.icon, color: level.color),
          title: Text(entry.maskedText, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${level.label} · ${shortDate(entry.verdict.checkedAt)}'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ResultScreen(verdict: entry.verdict, fromHistory: true),
          )),
        ),
      ),
    );
  }
}
