import 'masked_message.dart';

/// Body of POST /analyse. Only the masked message ever leaves the phone.
class AnalyseRequest {
  const AnalyseRequest({
    required this.message,
    this.sourceApp,
    required this.appVersion,
  });

  final MaskedMessage message;
  final String? sourceApp;
  final String appVersion;

  factory AnalyseRequest.fromJson(Map<String, dynamic> json) => AnalyseRequest(
        message: MaskedMessage.fromJson(json['message'] as Map<String, dynamic>),
        sourceApp: json['sourceApp'] as String?,
        appVersion: json['appVersion'] as String,
      );

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'sourceApp': sourceApp,
        'appVersion': appVersion,
      };
}
