/// Languages of the interface and of the explanation.
enum Language {
  french('fr'),
  arabic('ar'),
  english('en');

  const Language(this.code);
  final String code;

  static Language fromJson(String code) =>
      Language.values.firstWhere((l) => l.code == code,
          orElse: () => throw FormatException('Unknown language: $code'));

  String toJson() => code;
}

/// The four possible verdicts. UNSURE is used whenever evidence is missing.
enum VerdictLevel {
  fraudulent('FRAUDULENT'),
  suspicious('SUSPICIOUS'),
  safe('SAFE'),
  unsure('UNSURE');

  const VerdictLevel(this.code);
  final String code;

  static VerdictLevel fromJson(String code) =>
      VerdictLevel.values.firstWhere((v) => v.code == code,
          orElse: () => throw FormatException('Unknown verdict level: $code'));

  String toJson() => code;
}
