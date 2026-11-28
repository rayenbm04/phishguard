/// One reason behind a verdict, with the evidence that supports it.
class Reason {
  const Reason({
    required this.rank,
    required this.text,
    required this.evidenceSource,
    this.evidenceDetail,
    this.checkedDate,
  });

  final int rank;
  final String text;
  final String evidenceSource;
  final String? evidenceDetail;
  final DateTime? checkedDate;

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
        rank: json['rank'] as int,
        text: json['text'] as String,
        evidenceSource: json['evidenceSource'] as String,
        evidenceDetail: json['evidenceDetail'] as String?,
        checkedDate: json['checkedDate'] == null
            ? null
            : DateTime.parse(json['checkedDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'text': text,
        'evidenceSource': evidenceSource,
        'evidenceDetail': evidenceDetail,
        'checkedDate': checkedDate?.toUtc().toIso8601String(),
      };
}
