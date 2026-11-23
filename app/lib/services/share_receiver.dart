import 'dart:async';

import 'package:flutter/services.dart';

/// A text shared to PhishGuard from another app (WhatsApp, SMS, Gmail...).
class SharedText {
  const SharedText({required this.text, this.sourceApp});
  final String text;
  final String? sourceApp;
}

/// Receives text from the Android share menu (see MainActivity.kt).
class ShareReceiver {
  ShareReceiver({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('phishguard/share') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final shared = _parse(call.arguments);
        if (shared != null) _controller.add(shared);
      }
    });
  }

  final MethodChannel _channel;
  final _controller = StreamController<SharedText>.broadcast();

  /// Texts shared while the app is already open.
  Stream<SharedText> get stream => _controller.stream;

  /// The text that opened the app, if it was opened from the share menu.
  Future<SharedText?> initial() async {
    try {
      return _parse(await _channel.invokeMethod<Object?>('getInitialSharedText'));
    } on MissingPluginException {
      return null; // Tests, iOS, desktop: no share menu yet.
    } on PlatformException {
      return null;
    }
  }

  SharedText? _parse(Object? args) {
    if (args is! Map) return null;
    final text = args['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final source = args['sourceApp'];
    return SharedText(text: text, sourceApp: source is String ? source : null);
  }

  void dispose() => _controller.close();
}
