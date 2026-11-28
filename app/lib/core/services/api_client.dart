import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:phishguard/core/models/models.dart';

/// Why the server gave no usable answer.
enum ApiFailure {
  /// No answer within the time limit (8 s).
  timeout,

  /// The server could not be reached (wrong address, server stopped, no route).
  unreachable,

  /// The server answered with an error status (4xx / 5xx).
  serverError,

  /// The answer does not match the contract.
  badResponse,
}

class ApiException implements Exception {
  const ApiException(this.failure, [this.detail]);

  final ApiFailure failure;
  final String? detail;

  @override
  String toString() => 'ApiException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Talks to the PhishGuard server. Only the two real endpoints are used:
/// POST /analyse and POST /feedback. Only masked text is ever sent.
class ApiClient {
  ApiClient({
    Dio? dio,
    String? baseUrl,
    this.timeout = const Duration(seconds: 8),
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? defaultBaseUrl,
              connectTimeout: timeout,
              sendTimeout: timeout,
              receiveTimeout: timeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.plain,
            ));

  /// Set with: flutter run --dart-define=API_URL=http://192.168.1.10:8000
  /// 10.0.2.2 is the PC as seen from the Android emulator.
  static const defaultBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  static const appVersion = '1.0.0';

  final Dio _dio;

  /// Overall limit of one call; the server answers within 7.3 s.
  final Duration timeout;

  Dio get dio => _dio;

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
    try {
      return Verdict.fromJson(body);
    } catch (e) {
      throw ApiException(ApiFailure.badResponse, '$e');
    }
  }

  Future<void> sendFeedback(UserFeedback feedback) async {
    await _post('/feedback', feedback.toJson(), expected: 201, decode: false);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> json, {
    required int expected,
    bool decode = true,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio
          .post<dynamic>(path, data: json, options: Options(validateStatus: (_) => true))
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } on DioException catch (e) {
      throw ApiException(_failureOf(e), e.message);
    } catch (e) {
      throw ApiException(ApiFailure.unreachable, '$e');
    }

    if (response.statusCode != expected) {
      throw ApiException(ApiFailure.serverError, 'HTTP ${response.statusCode}');
    }
    if (!decode) return const {};
    try {
      final data = response.data;
      final decoded = data is String ? jsonDecode(data) : data;
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      throw ApiException(ApiFailure.badResponse, '$e');
    }
  }

  static ApiFailure _failureOf(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          ApiFailure.timeout,
        DioExceptionType.badResponse => ApiFailure.serverError,
        _ => ApiFailure.unreachable,
      };
}
