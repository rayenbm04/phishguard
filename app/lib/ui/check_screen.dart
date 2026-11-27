import 'package:flutter/material.dart';

import '../app.dart';
import '../controllers/check_controller.dart';
import '../l10n/strings.dart';
import '../services/personal_data_masker.dart';
import 'result_screen.dart';
import 'theme.dart';

/// Shows the message to check (shared, pasted, typed or read from a screenshot) and runs the check.
class CheckScreen extends StatefulWidget {
  const CheckScreen({
    super.key,
    required this.services,
    this.initialText = '',
    this.sourceApp,
    this.fromShare = false,
    this.fromScreenshot = false,
  });

  final AppServices services;
  final String initialText;
  final String? sourceApp;
  final bool fromShare;
  final bool fromScreenshot;

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  static const _masker = PersonalDataMasker();

  late final TextEditingController _text =
      TextEditingController(text: widget.initialText)..addListener(_onTextChanged);
  late final CheckController _controller = CheckController(
    api: widget.services.api,
    connectivity: widget.services.connectivity,
    history: widget.services.history,
  )..addListener(_onStateChanged);

  int _hiddenItems = 0;

  @override
  void initState() {
    super.initState();
    _hiddenItems = _masker.countItems(widget.initialText);
  }

  void _onTextChanged() {
    final n = _masker.countItems(_text.text);
    if (n != _hiddenItems) setState(() => _hiddenItems = n);
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _controller.state;
    if (state.status == CheckStatus.done && state.verdict != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ResultScreen(verdict: state.verdict!),
      ));
    } else {
      setState(() {});
    }
  }

  void _check() {
    FocusScope.of(context).unfocus();
    _controller.startCheck(_text.text, sourceApp: widget.sourceApp);
  }

  @override
  void dispose() {
    _controller.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final busy = state.status == CheckStatus.analysing;
    final text = Theme.of(context).textTheme;
    final s = S.of(context);

    String? origin;
    if (widget.fromScreenshot) {
      origin = s.textFromScreenshot;
    } else if (widget.fromShare) {
      origin = widget.sourceApp == null ? s.sharedWithApp : s.sharedFrom(widget.sourceApp!);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.checkTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (origin != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(origin, style: text.labelLarge?.copyWith(color: Pg.inkSoft)),
              ),
            TextField(
              key: const Key('messageField'),
              controller: _text,
              enabled: !busy,
              minLines: 5,
              maxLines: 12,
              maxLength: 5000,
              decoration: InputDecoration(hintText: s.messageHint),
            ),
            const SizedBox(height: 4),
            _PrivacyNote(
              text: _hiddenItems == 0 ? s.privacyNoteNone : s.privacyNoteCount(_hiddenItems),
            ),
            const SizedBox(height: 20),
            if (state.status == CheckStatus.failed && state.failure != null)
              _FailureBox(failure: state.failure!, onRetry: busy ? null : _check),
            FilledButton(
              key: const Key('checkButton'),
              onPressed: busy ? null : _check,
              child: busy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(s.checking),
                      ],
                    )
                  : Text(s.checkButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 18, color: Pg.safe),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Pg.inkSoft)),
        ),
      ],
    );
  }
}

class _FailureBox extends StatelessWidget {
  const _FailureBox({required this.failure, required this.onRetry});

  final CheckFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (title, body, icon) = switch (failure) {
      CheckFailure.emptyMessage => (s.errEmptyTitle, s.errEmptyBody, Icons.edit_note),
      CheckFailure.offline => (s.errOfflineTitle, s.errOfflineBody, Icons.wifi_off_rounded),
      CheckFailure.serverUnreachable => (s.errServerTitle, s.errServerBody, Icons.cloud_off),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        key: Key('failure-${failure.name}'),
        color: Pg.suspicious.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Pg.suspicious),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(body),
                    if (failure != CheckFailure.emptyMessage)
                      TextButton(onPressed: onRetry, child: Text(s.tryAgain)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
