import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishguard/core/services/api_client.dart';
import 'package:phishguard/core/services/connectivity_service.dart';
import 'package:phishguard/core/services/link_opener.dart';
import 'package:phishguard/core/services/personal_data_masker.dart';
import 'package:phishguard/core/services/screenshot_reader.dart';
import 'package:phishguard/core/services/share_receiver.dart';

/// Loaded once in main() before the first frame, then injected here.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main() / tests'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final connectivityProvider = Provider<ConnectivityService>((ref) => const ConnectivityService());

final maskerProvider = Provider<PersonalDataMasker>((ref) => const PersonalDataMasker());

final screenshotReaderProvider = Provider<ScreenshotReader>((ref) => const ScreenshotReader());

final linkOpenerProvider = Provider<LinkOpener>((ref) => const LinkOpener());

final clipboardProvider = Provider<ClipboardReader>((ref) => const ClipboardReader());

final shareReceiverProvider = Provider<ShareReceiver>((ref) {
  final receiver = ShareReceiver();
  ref.onDispose(receiver.dispose);
  return receiver;
});

/// Reads the text the user copied (Paste button).
class ClipboardReader {
  const ClipboardReader();

  Future<String?> read() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
