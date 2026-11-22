import 'advice.dart';
import 'enums.dart';
import 'reason.dart';

/// The answer of POST /analyse.
class Verdict {
  const Verdict({
    required this.id,
    required this.level,
    required this.riskScore,
    required this.summary,
    required this.checkedAt,
    required this.reasons,
    required this.advice,
  });

  final String id;
  final VerdictLevel level;
  final int riskScore;
  final String summary;
  final DateTime checkedAt;
  final List<Reason> reasons;
  final List<Advice> advice;

  factory Verdict.fromJson(Map<String, dynamic> json) => Verdict(
        id: json['id'] as String,
        level: VerdictLevel.fromJson(json['level'] as String),
        riskScore: json['riskScore'] as int,
        summary: json['summary'] as String,
        checkedAt: DateTime.parse(json['checkedAt'] as String),
        reasons: (json['reasons'] as List<dynamic>)
            .map((r) => Reason.fromJson(r as Map<String, dynamic>))
            .toList(),
        advice: (json['advice'] as List<dynamic>)
            .map((a) => Advice.fromJson(a as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level.toJson(),
        'riskScore': riskScore,
        'summary': summary,
        'checkedAt': checkedAt.toUtc().toIso8601String(),
        'reasons': reasons.map((r) => r.toJson()).toList(),
        'advice': advice.map((a) => a.toJson()).toList(),
      };
}
