import 'package:phishguard/core/models/models.dart';

/// Hides personal data on the phone, before anything is sent to the server.
///
/// Masked: bank card / account numbers, Tunisian phone numbers and CIN numbers.
/// Links are left untouched: they are the main clue the server needs.
class PersonalDataMasker {
  const PersonalDataMasker();

  static const cardTag = '[CARD]';
  static const accountTag = '[ACCOUNT]';
  static const phoneTag = '[PHONE]';
  static const cinTag = '[CIN]';

  static final _link = RegExp(
    r'(?:https?://|www\.)\S+|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:tn|com|net|org|info|xyz|top|online|site|ly|me|io|co)(?:/\S*)?',
    caseSensitive: false,
  );

  // Order matters: long numbers first, then phones, then CIN.
  static final _rules = <(RegExp, String)>[
    // RIB / IBAN-like: 20 digits or more (spaces or dashes allowed).
    (RegExp(r'(?<![\d\[])(?:TN\d{2}[ -]?)?(?:\d[ -]?){19,29}\d(?!\d)'), accountTag),
    // Phone with +216 / 00216 (before cards: 00216 + 8 digits is 13 digits long).
    (RegExp(r'(?<!\d)(?:\+|00)216[ .-]?[2-9]\d[ .-]?\d{3}[ .-]?\d{3}(?!\d)'), phoneTag),
    // Bank card: 13 to 19 digits.
    (RegExp(r'(?<!\d)(?:\d[ -]?){12,18}\d(?!\d)'), cardTag),
    // Tunisian phone, with or without +216 / 00216, 8 digits starting with 2-9.
    (RegExp(r'(?<!\d)(?:(?:\+|00)216[ .-]?)?[2-9]\d[ .-]?\d{3}[ .-]?\d{3}(?!\d)'), phoneTag),
    // CIN: 8 digits starting with 0 or 1.
    (RegExp(r'(?<!\d)[01]\d{7}(?!\d)'), cinTag),
  ];

  static final _arabic = RegExp(r'[؀-ۿ]');
  static final _french = RegExp(
    r"[éèêàçù]|\b(?:le|la|les|votre|vous|est|une|des|pour|compte|colis|cliquez)\b",
    caseSensitive: false,
  );

  /// Returns the masked text, the number of hidden items and the detected language.
  MaskedMessage mask(String text) {
    final buffer = StringBuffer();
    var count = 0;
    var last = 0;
    for (final link in _link.allMatches(text)) {
      final (masked, n) = _maskPlain(text.substring(last, link.start));
      buffer
        ..write(masked)
        ..write(link.group(0));
      count += n;
      last = link.end;
    }
    final (masked, n) = _maskPlain(text.substring(last));
    buffer.write(masked);
    count += n;
    return MaskedMessage(
      text: buffer.toString(),
      maskedItems: count,
      language: detectLanguage(text),
    );
  }

  /// Number of items [mask] would hide (used for the live privacy note).
  int countItems(String text) => mask(text).maskedItems;

  Language detectLanguage(String text) {
    if (_arabic.hasMatch(text)) return Language.arabic;
    if (_french.hasMatch(text)) return Language.french;
    return Language.english;
  }

  (String, int) _maskPlain(String segment) {
    var out = segment;
    var count = 0;
    for (final (pattern, tag) in _rules) {
      out = out.replaceAllMapped(pattern, (_) {
        count++;
        return tag;
      });
    }
    return (out, count);
  }
}
