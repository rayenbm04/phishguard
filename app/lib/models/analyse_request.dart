import 'enums.dart';
import 'masked_message.dart';

/// Body of POST /analyse. Only the masked message ever leaves the phone.
class AnalyseRequest {
  const AnalyseRequest({
    required this.message,
    this.sourceApp,
    required this.appVersion,
    this.replyLanguage,
  });

  final MaskedMessage message;
  final String? sourceApp;
  final String appVersion;

  /// Language of the app: the explanation is written in it.
  final Language? replyLanguage;

  factory AnalyseRequest.fromJson(Map<String, dynamic> json) => AnalyseRequest(
        message: MaskedMessage.fromJson(json['message'] as Map<String, dynamic>),
        sourceApp: json['sourceApp'] as String?,
        appVersion: json['appVersion'] as String,
        replyLanguage: json['replyLanguage'] == null
            ? null
            : Language.fromJson(json['replyLanguage'] as String),
      );

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'sourceApp': sourceApp,
        'appVersion': appVersion,
        'replyLanguage': replyLanguage?.toJson(),
      };
}
