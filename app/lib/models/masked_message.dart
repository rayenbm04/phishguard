import 'enums.dart';

/// A message after personal data (phone, card, ID numbers) was masked on the phone.
class MaskedMessage {
  const MaskedMessage({
    required this.text,
    required this.maskedItems,
    required this.language,
  });

  final String text;
  final int maskedItems;
  final Language language;

  factory MaskedMessage.fromJson(Map<String, dynamic> json) => MaskedMessage(
        text: json['text'] as String,
        maskedItems: json['maskedItems'] as int,
        language: Language.fromJson(json['language'] as String),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'maskedItems': maskedItems,
        'language': language.toJson(),
      };
}
