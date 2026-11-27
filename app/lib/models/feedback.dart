/// Body of POST /feedback ("Feedback" in the UML; renamed because Flutter already
/// has a Feedback class). maskedText is only sent when the user reports a scam.
class UserFeedback {
  UserFeedback({
    required this.verdictId,
    this.rating,
    this.reportedAsScam = false,
    this.maskedText,
    this.comment,
  }) {
    if (maskedText != null && !reportedAsScam) {
      throw ArgumentError('maskedText is only allowed when reportedAsScam is true');
    }
    if (rating == null && !reportedAsScam) {
      throw ArgumentError('send a rating, a scam report, or both');
    }
  }

  final String verdictId;
  /// 1 to 5 stars; optional when the user only reports a scam.
  final int? rating;
  final bool reportedAsScam;
  final String? maskedText;
  final String? comment;

  factory UserFeedback.fromJson(Map<String, dynamic> json) => UserFeedback(
        verdictId: json['verdictId'] as String,
        rating: json['rating'] as int?,
        reportedAsScam: json['reportedAsScam'] as bool? ?? false,
        maskedText: json['maskedText'] as String?,
        comment: json['comment'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'verdictId': verdictId,
        'rating': rating,
        'reportedAsScam': reportedAsScam,
        'maskedText': maskedText,
        'comment': comment,
      };
}
