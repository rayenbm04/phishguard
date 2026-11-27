import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../l10n/strings.dart';
import '../services/api_client.dart';
import '../services/history_repository.dart';
import 'check_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HistoryEntry> _history = const [];
  bool _readingImage = false;

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

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    _loadHistory();
  }

  Future<void> _openCheck({String text = '', bool fromScreenshot = false}) => _push(
        CheckScreen(services: widget.services, initialText: text, fromScreenshot: fromScreenshot),
      );

  Future<void> _pasteAndCheck() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    await _openCheck(text: data?.text ?? '');
  }

  /// SD3: pick a screenshot, read its text on the phone, let the user confirm it.
  Future<void> _checkScreenshot() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reader = widget.services.screenshots;
    try {
      final path = await reader.pickImage();
      if (path == null) return; // Cancelled.
      setState(() => _readingImage = true);
      final text = await reader.readText(path);
      if (!mounted) return;
      setState(() => _readingImage = false);
      if (text.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(s.noTextInImage)));
        return;
      }
      await _openCheck(text: text, fromScreenshot: true);
    } catch (e) {
      debugPrint('Screenshot not read: $e');
      if (mounted) setState(() => _readingImage = false);
      messenger.showSnackBar(SnackBar(content: Text(s.imageError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Pg.indigo, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('PhishGuard',
                      style: text.headlineSmall
                          ?.copyWith(color: Pg.indigo, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  key: const Key('settingsButton'),
                  tooltip: s.settings,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _push(SettingsScreen(services: widget.services)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.homeHeadline,
                style: text.headlineMedium
                    ?.copyWith(color: Pg.ink, fontWeight: FontWeight.w700, height: 1.15)),
            const SizedBox(height: 8),
            Text(s.homeSubtitle, style: text.bodyLarge?.copyWith(color: Pg.inkSoft)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pasteAndCheck,
              icon: const Icon(Icons.content_paste),
              label: Text(s.pasteAndCheck),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openCheck(),
              icon: const Icon(Icons.edit_outlined),
              label: Text(s.typeMessage),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('screenshotButton'),
              onPressed: _readingImage ? null : _checkScreenshot,
              icon: _readingImage
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.image_search_outlined),
              label: Text(_readingImage ? s.readingImage : s.checkScreenshot),
            ),
            const SizedBox(height: 16),
            _ShareTip(text: s.shareTip),
            const SizedBox(height: 28),
            Text(s.recentChecks, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_history.isEmpty)
              Text(s.historyEmpty, style: text.bodyMedium?.copyWith(color: Pg.inkSoft))
            else
              for (final entry in _history.take(10))
                _HistoryTile(entry: entry, api: widget.services.api),
          ],
        ),
      ),
    );
  }
}

class _ShareTip extends StatelessWidget {
  const _ShareTip({required this.text});

  final String text;

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
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.api});

  final HistoryEntry entry;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final level = entry.verdict.level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(level.icon, color: level.color),
          title: Text(entry.maskedText, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${S.of(context).levelLabel(level)} · ${shortDate(entry.verdict.checkedAt)}'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              verdict: entry.verdict,
              fromHistory: true,
              maskedText: entry.maskedText,
              api: api,
            ),
          )),
        ),
      ),
    );
  }
}
