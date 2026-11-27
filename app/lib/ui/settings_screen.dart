import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/strings.dart';
import '../services/api_client.dart';

/// Language, history and privacy.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  Future<void> _clearHistory(BuildContext context) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.clearHistoryQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.clear)),
        ],
      ),
    );
    if (ok != true) return;
    await services.history.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.historyCleared)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = services.settings;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Header(s.languageLabel),
            for (final l in S.supported)
              ListTile(
                key: Key('settings-language-${l.code}'),
                title: Text(S.languageName(l)),
                trailing: settings.language == l
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                selected: settings.language == l,
                onTap: () => settings.setLanguage(l),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(s.clearHistory),
              onTap: () => _clearHistory(context),
            ),
            const Divider(),
            _Header(s.privacy),
            for (final promise in s.privacyPromises)
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(promise, style: text.bodyMedium),
              ),
            const Divider(),
            ListTile(
              title: Text(s.version),
              trailing: const Text(ApiClient.appVersion),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
      );
}
