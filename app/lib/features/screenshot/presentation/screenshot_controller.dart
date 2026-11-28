import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/core/providers.dart';

enum ScreenshotPhase { idle, picking, reading, found, noText, error }

@immutable
class ScreenshotState {
  const ScreenshotState({this.phase = ScreenshotPhase.idle, this.imagePath, this.text = ''});

  final ScreenshotPhase phase;
  final String? imagePath;

  /// Text read on the phone (ML Kit). The image itself is never sent.
  final String text;
}

final screenshotProvider =
    NotifierProvider.autoDispose<ScreenshotController, ScreenshotState>(ScreenshotController.new);

class ScreenshotController extends Notifier<ScreenshotState> {
  @override
  ScreenshotState build() => const ScreenshotState();

  /// Opens the gallery, then reads the text of the chosen image.
  Future<void> pick() async {
    if (state.phase == ScreenshotPhase.picking || state.phase == ScreenshotPhase.reading) return;
    final previous = state;
    state = ScreenshotState(phase: ScreenshotPhase.picking, imagePath: previous.imagePath, text: previous.text);
    final reader = ref.read(screenshotReaderProvider);
    String? path;
    try {
      path = await reader.pickImage();
    } catch (e) {
      debugPrint('Image not picked: $e');
      if (ref.mounted) state = const ScreenshotState(phase: ScreenshotPhase.error);
      return;
    }
    if (!ref.mounted) return;
    if (path == null) {
      // Cancelled: back to where the user was.
      state = previous.phase == ScreenshotPhase.picking ? const ScreenshotState() : previous;
      return;
    }
    state = ScreenshotState(phase: ScreenshotPhase.reading, imagePath: path);
    try {
      final text = await reader.readText(path);
      if (!ref.mounted) return;
      state = ScreenshotState(
        phase: text.trim().isEmpty ? ScreenshotPhase.noText : ScreenshotPhase.found,
        imagePath: path,
        text: text.trim(),
      );
    } catch (e) {
      debugPrint('Image not read: $e');
      if (ref.mounted) state = ScreenshotState(phase: ScreenshotPhase.error, imagePath: path);
    }
  }
}
