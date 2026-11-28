import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an official contact given by the server (a website or a phone number).
/// Links found inside the checked message are never opened by the app.
class LinkOpener {
  const LinkOpener();

  /// The URI to open for [contact], or null if it is neither a link nor a number.
  static Uri? uriOf(String contact) {
    final value = contact.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.tryParse(value);
    }
    if (value.startsWith('www.')) return Uri.tryParse('https://$value');
    final digits = value.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (RegExp(r'^\+?\d{3,15}$').hasMatch(digits)) return Uri(scheme: 'tel', path: digits);
    return null;
  }

  static bool isPhone(String contact) => uriOf(contact)?.scheme == 'tel';

  /// True if another app opened the contact.
  Future<bool> open(String contact) async {
    final uri = uriOf(contact);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  Future<void> copy(String contact) => Clipboard.setData(ClipboardData(text: contact.trim()));
}
