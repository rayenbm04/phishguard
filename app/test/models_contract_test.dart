import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phishguard/core/models/models.dart';

/// Reads the shared examples in ../contracts (flutter test runs from app/).
Map<String, dynamic> load(String name) =>
    jsonDecode(File('../contracts/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('AnalyseRequest example parses and keeps every key', () {
    final json = load('analyse_request.example.json');
    final request = AnalyseRequest.fromJson(json);
    expect(request.message.language, Language.french);
    expect(request.toJson().keys.toSet(), json.keys.toSet());
    expect(request.toJson()['message'], json['message']);
  });

  test('Verdict example parses and round-trips', () {
    final json = load('verdict.example.json');
    final verdict = Verdict.fromJson(json);
    expect(verdict.level, VerdictLevel.fraudulent);
    expect(verdict.reasons, hasLength(2));
    expect(verdict.reasons.first.checkedDate, DateTime.utc(2026, 11, 22, 12));
    expect(verdict.toJson().keys.toSet(), json.keys.toSet());
    final again = Verdict.fromJson(verdict.toJson());
    expect(jsonEncode(again.toJson()), jsonEncode(verdict.toJson()));
  });

  test('UserFeedback example parses and keeps every key', () {
    final json = load('feedback.example.json');
    final feedback = UserFeedback.fromJson(json);
    expect(feedback.reportedAsScam, isTrue);
    expect(feedback.toJson(), json);
  });

  test('maskedText is refused when the message is not reported', () {
    expect(
      () => UserFeedback(verdictId: 'x', rating: 3, maskedText: 'hello'),
      throwsArgumentError,
    );
  });

  test('feedback needs a rating or a report', () {
    expect(() => UserFeedback(verdictId: 'x'), throwsArgumentError);
    expect(UserFeedback(verdictId: 'x', reportedAsScam: true).rating, isNull);
  });
}
