import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// The server could not give an answer (timeout, network error or bad status).
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// Talks to the PhishGuard server. Only masked text is ever sent.
class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  /// Set with: flutter run --dart-define=API_URL=http://192.168.1.10:8000
  /// 10.0.2.2 is the PC as seen from the Android emulator.
  static const defaultBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  static const appVersion = '1.0.0';

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Future<Verdict> analyse(
    MaskedMessage message, {
    String? sourceApp,
    Language? replyLanguage,
  }) async {
    final request = AnalyseRequest(
      message: message,
      sourceApp: sourceApp,
      appVersion: appVersion,
      replyLanguage: replyLanguage,
    );
    final body = await _post('/analyse', request.toJson(), expected: 200);
    return Verdict.fromJson(body);
  }

  Future<void> sendFeedback(UserFeedback feedback) async {
    await _post('/feedback', feedback.toJson(), expected: 201);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> json, {
    required int expected,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(json),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException('timeout');
    } catch (e) {
      throw ApiException('network error: $e');
    }
    if (response.statusCode != expected) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('bad response: $e');
    }
  }
}
